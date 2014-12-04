//
//  UIScrollView+Drag2Refresh.m
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 14-4-16.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import "UIScrollView+Drag2Refresh.h"
#import <QuartzCore/QuartzCore.h>
#import "RotationIndicatorView.h"

//fequal() and fequalzro() from http://stackoverflow.com/a/1614761/184130
#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

//#define kColorSlipHeadRefresh   [UIColor colorWithRed:119/225.f green:119/225.f blue:119/225.f alpha:1.0];

static CGFloat const Drag2RefreshViewHeight = 40;

@interface Drag2RefreshView ()

@property (nonatomic, copy) void (^drag2RefreshActionHandler)(void);

@property (nonatomic, strong) NSMutableArray *title4State;
@property (nonatomic, strong) NSMutableArray *subtitle4State;
@property (nonatomic, strong) NSMutableArray *viewForState;

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic, readwrite) CGFloat originalBottomInset;

@property (nonatomic, assign) BOOL wasTriggeredByUser;
@property (nonatomic, assign) BOOL showsPullToRefresh;
@property (nonatomic, assign) BOOL showsDateLabel;
@property (nonatomic, assign) BOOL isObserving;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForLoading;
- (void)setScrollViewContentInset:(UIEdgeInsets)insets;

@end

#pragma mark - UIScrollView (Drag2Refresh)
#import <objc/runtime.h>

static char UIScrollViewPullToRefreshView;
static char UIScrollViewPullToRefreshViewTop;

@implementation UIScrollView (Drag2Refresh)
@dynamic btmDrag2RefreshView, topDrag2RefreshView;

- (void)addDrag2RefreshWithActionHandler:(void (^)(void))actionHandler
                                 position:(Drag2RefreshPosition)position
{
    if ( position == Drag2RefreshPositionTop )
    {
        if( !self.topDrag2RefreshView )
        {
            CGRect viewFrame = CGRectMake(0, -Drag2RefreshViewHeight,
                                          self.frame.size.width, Drag2RefreshViewHeight);
            Drag2RefreshView *view = [[Drag2RefreshView alloc] initWithFrame:viewFrame];
            view.drag2RefreshActionHandler = actionHandler;
            view.scrollView = self;
            [self addSubview:view];
            
            view.originalTopInset = self.contentInset.top;
            view.originalBottomInset = self.contentInset.bottom;
            view.position = position;
            
            self.topDrag2RefreshView = view;
            [self showsPullToRefresh:YES position:position];
        }
    }
    else
    {
        if( !self.btmDrag2RefreshView )
        {
            CGRect viewFrame = CGRectMake(0, self.contentSize.height,
                                          self.frame.size.width, Drag2RefreshViewHeight);
            
            Drag2RefreshView *view = [[Drag2RefreshView alloc] initWithFrame:viewFrame];
            view.drag2RefreshActionHandler = actionHandler;
            view.scrollView = self;
            [self addSubview:view];
            
            view.originalTopInset = self.contentInset.top;
            view.originalBottomInset = self.contentInset.bottom;
            view.position = position;
            
            self.btmDrag2RefreshView = view;
            
            [self showsPullToRefresh:YES position:position];
            [view setTitle:@"上拉加载更多..." forState:Drag2RefreshStateStopped];
        }
    }
}

- (void)triggerPullToRefreshWithPosition:(Drag2RefreshPosition)position
{
    if ( position == Drag2RefreshPositionTop )
    {
        self.topDrag2RefreshView.state = Drag2RefreshStateTriggered;
        [self.topDrag2RefreshView startAnimating];
    }
    else
    {
        self.btmDrag2RefreshView.state = Drag2RefreshStateTriggered;
        [self.btmDrag2RefreshView startAnimating];
    }
}

#pragma mark - getter & setter
- (void)setTopDrag2RefreshView:(Drag2RefreshView *)drag2RefreshViewTop
{
    [self willChangeValueForKey:@"Drag2RefreshViewTop"];
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshViewTop,
                             drag2RefreshViewTop, OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"Drag2RefreshViewTop"];
}

- (Drag2RefreshView *)topDrag2RefreshView
{
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshViewTop);
}

- (void)setBtmDrag2RefreshView:(Drag2RefreshView *)drag2RefreshView
{
    [self willChangeValueForKey:@"Drag2RefreshView"];
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshView,
                             drag2RefreshView, OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"Drag2RefreshView"];
}

- (Drag2RefreshView *)btmDrag2RefreshView
{
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
}

- (void)showsPullToRefresh:(BOOL)show position:(Drag2RefreshPosition)position;
{
    Drag2RefreshView *drag2RefreshView = self.topDrag2RefreshView;
    if ( position == Drag2RefreshPositionBottom )
    {
        drag2RefreshView = self.btmDrag2RefreshView;
    }
    
    drag2RefreshView.hidden = !show;
    
    if( !show )
    {
        if ( drag2RefreshView.isObserving )
        {
            [self removeObserver:drag2RefreshView forKeyPath:@"contentOffset"];
            [self removeObserver:drag2RefreshView forKeyPath:@"contentSize"];
            [self removeObserver:drag2RefreshView forKeyPath:@"frame"];
            
            [drag2RefreshView resetScrollViewContentInset];
            drag2RefreshView.isObserving = NO;
        }
    }
    else
    {
        if ( !drag2RefreshView.isObserving )
        {
            [self addObserver:drag2RefreshView forKeyPath:@"contentOffset"
                      options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:drag2RefreshView forKeyPath:@"contentSize"
                      options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:drag2RefreshView forKeyPath:@"frame"
                      options:NSKeyValueObservingOptionNew context:nil];
            
            drag2RefreshView.isObserving = YES;
            
            BOOL isTopPos = drag2RefreshView.position == Drag2RefreshPositionTop;
            CGFloat yOrigin = isTopPos ? -Drag2RefreshViewHeight:self.contentSize.height;
            drag2RefreshView.frame = CGRectMake(0, yOrigin, self.bounds.size.width, Drag2RefreshViewHeight);
        }
    }
}

- (void)lockPullToRefresh:(BOOL)lock position:(Drag2RefreshPosition)position
{
    Drag2RefreshView *drag2RefreshView = self.topDrag2RefreshView;
    if ( position == Drag2RefreshPositionBottom )
    {
        drag2RefreshView = self.btmDrag2RefreshView;
    }
    
    drag2RefreshView.state = lock ? Drag2RefreshStateLocked:Drag2RefreshStateStopped;
}

@end

#pragma mark - Drag2Refresh
@implementation Drag2RefreshView

#pragma mark - life cycle

- (id)initWithFrame:(CGRect)frame
{
    if( self = [super initWithFrame:frame] )
    {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = [UIColor colorWithRed:235/255.f green:235/255.f blue:235/255.f alpha:1.0];
        
        self.state = Drag2RefreshStateStopped;
        
        self.title4State = [NSMutableArray arrayWithObjects:@"下拉加载更多...",
                            @"释放开始加载...",@"加载中...", @"无更多加载", nil];
        
        self.subtitle4State = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
        self.viewForState = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
        self.wasTriggeredByUser = YES;
    }
    
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if ( self.superview && newSuperview == nil )
    {
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (self.isObserving)
        {
            [scrollView removeObserver:self forKeyPath:@"contentOffset"];
            [scrollView removeObserver:self forKeyPath:@"contentSize"];
            [scrollView removeObserver:self forKeyPath:@"frame"];
            self.isObserving = NO;
        }
    }
}

- (void)layoutSubviews
{
    for( UIView *subView in self.viewForState )
    {
        if( ![subView isKindOfClass:[UIView class]] ) continue;
        [subView removeFromSuperview];
    }
    
    UIView *customView = [self.viewForState objectAtIndex:self.state];
    BOOL hasCustomView = [customView isKindOfClass:[UIView class]];

    if( hasCustomView )
    {
        [self addSubview:customView];
        CGPoint origin = CGPointMake(roundf((self.frame.size.width - customView.frame.size.width)/2),
                                     roundf((self.frame.size.height - customView.frame.size.height)/2));
        
        [customView setFrame:CGRectMake(origin.x, origin.y,
                                        customView.frame.size.width,
                                        customView.frame.size.height)];
    }
    else
    {
        [UIView setAnimationsEnabled:NO];
        
        self.titleLabel.text = self.title4State[_state];
        self.titleLabel.hidden = NO;
        
        CGRect labelFrame = _titleLabel.frame;
        labelFrame.size.width = 200;
        labelFrame.origin.x = floorf((self.frame.size.width - _titleLabel.frame.size.width) / 2.f);
        _titleLabel.frame = labelFrame;
        
        switch (self.state)
        {
            case Drag2RefreshStateStopped:
            case Drag2RefreshStateTriggered:
            case Drag2RefreshStateLocked: {
                [self showActivity:NO animated:NO];
            } break;
                
            case Drag2RefreshStateLoading: {
                CGRect rect2Fit = CGRectMake(0, 0, 280, 12);
                CGRect rectFited = [_titleLabel textRectForBounds:rect2Fit limitedToNumberOfLines:1];
                
                CGFloat offsetX = self.frame.size.width -
                _activityIndicatorView.frame.size.width - 12 - rectFited.size.width;
                
                CGRect actFrame = _activityIndicatorView.frame;
                actFrame.origin.x = floorf(offsetX / 2);
                actFrame.origin.y = floorf((self.frame.size.height - actFrame.size.height) / 2.f);
                _activityIndicatorView.frame = actFrame;
                
                CGRect labelFrame = _titleLabel.frame;
                labelFrame.size.width = rectFited.size.width;
                labelFrame.origin.x = CGRectGetMaxX(actFrame) + 12;
                _titleLabel.frame = labelFrame;
                
                [self showActivity:YES animated:YES];
            } break;
        }
        
        [UIView setAnimationsEnabled:YES];
    }
}

- (void)showActivity:(BOOL)show animated:(BOOL)animated
{
	self.activityIndicatorView.hidden = !show;
    
    if (animated) {
        [self.activityIndicatorView startAnimating];
    } else {
        [self.activityIndicatorView stopAnimating];
    }
}

#pragma mark - public
- (void)setTitle:(NSString *)title forState:(Drag2RefreshState)state
{
    if( !title ) { title = @""; }
    
    [self.title4State replaceObjectAtIndex:state withObject:title];
    [self setNeedsLayout];
}

- (void)setSubtitle:(NSString *)subtitle forState:(Drag2RefreshState)state
{
    if(!subtitle) { subtitle = @""; }
    [self.subtitle4State replaceObjectAtIndex:state withObject:subtitle];
    [self setNeedsLayout];
}

- (void)setCustomView:(UIView *)view forState:(Drag2RefreshState)state
{
    id viewPlaceholder = view;
    if( !viewPlaceholder ) { viewPlaceholder = @""; }
    
    [self.viewForState replaceObjectAtIndex:state withObject:viewPlaceholder];
    [self setNeedsLayout];
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset
{
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    
    switch (self.position)
    {
        case Drag2RefreshPositionTop : {
            currentInsets.top = self.originalTopInset;
        } break;
        case Drag2RefreshPositionBottom : {
            currentInsets.bottom = self.originalBottomInset;
            currentInsets.top = self.originalTopInset;
        } break;
    }
    
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForLoading
{
    CGFloat offset = MAX(self.scrollView.contentOffset.y * -1, 0);
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    
    switch (self.position)
    {
        case Drag2RefreshPositionTop : {
            currentInsets.top = MIN(offset, self.originalTopInset + self.bounds.size.height);
        } break;
        case Drag2RefreshPositionBottom : {
            currentInsets.bottom = MIN(offset, self.originalBottomInset + self.bounds.size.height);
        } break;
    }
    
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset
{
    UIViewAnimationOptions options = UIViewAnimationOptionAllowUserInteraction
    | UIViewAnimationOptionBeginFromCurrentState;

    [UIView animateWithDuration:0.3 delay:0 options:options animations:^{
        self.scrollView.contentInset = contentInset;
    } completion:NULL];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    [object removeObserver:self forKeyPath:@"contentOffset"];
    [object removeObserver:self forKeyPath:@"contentSize"];
    [object removeObserver:self forKeyPath:@"frame"];
    
    self.isObserving = NO;
    
    if([keyPath isEqualToString:@"contentOffset"])
    {
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    }
    else if([keyPath isEqualToString:@"contentSize"])
    {
        [self layoutSubviews];
        
        CGFloat yOrigin4PosBtm = MAX(self.scrollView.contentSize.height, self.scrollView.bounds.size.height);
        CGFloat yOrigin = _position==Drag2RefreshPositionTop ? -Drag2RefreshViewHeight:yOrigin4PosBtm;
        self.frame = CGRectMake(0, yOrigin, self.bounds.size.width, Drag2RefreshViewHeight);
    }
    else if([keyPath isEqualToString:@"frame"])
    {
        [self layoutSubviews];
    }
    
    [object addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    [object addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
    [object addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    
    self.isObserving = YES;
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset
{
    /// 正在加载中。。。
    if ( self.state == Drag2RefreshStateLocked )
    {
        // Do nothing
    }
    else if( self.state != Drag2RefreshStateLoading )
    {
        CGFloat scrollOffsetThreshold = 0;      // 初始化位置偏移
        
        switch (self.position)
        {
            case Drag2RefreshPositionTop : {
                scrollOffsetThreshold = self.frame.origin.y - self.originalTopInset;
            } break;
            case Drag2RefreshPositionBottom : {
                scrollOffsetThreshold = MAX(self.scrollView.contentSize.height - self.scrollView.frame.size.height, 0.0f)
                                        + self.bounds.size.height + self.originalBottomInset;
            } break;
        }
        
        if( self.scrollView.isDragging == NO
           && self.state == Drag2RefreshStateTriggered )
        {
            self.state = Drag2RefreshStateLoading;
        }
        else
        {
            if ( self.position == Drag2RefreshPositionTop )
            {
                if(contentOffset.y < scrollOffsetThreshold
                   && self.scrollView.isDragging
                   && self.state == Drag2RefreshStateStopped)
                {
                    self.state = Drag2RefreshStateTriggered;
                }
                else if(contentOffset.y >= scrollOffsetThreshold
                        && self.state != Drag2RefreshStateStopped)
                {
                    self.state = Drag2RefreshStateStopped;
                }
            }
            else
            {
                if(contentOffset.y > scrollOffsetThreshold
                   && self.scrollView.isDragging
                   && self.state == Drag2RefreshStateStopped)
                {
                    self.state = Drag2RefreshStateTriggered;
                }
                else if(contentOffset.y <= scrollOffsetThreshold
                        && self.state != Drag2RefreshStateStopped)
                {
                    self.state = Drag2RefreshStateStopped;
                }
            }
        }
    }
    else
    {
        if ( Drag2RefreshPositionTop == _position )
        {
            CGFloat offset = MAX(self.scrollView.contentOffset.y * -1, 0.0f);
            offset = MIN(offset, self.originalTopInset + self.bounds.size.height);
            UIEdgeInsets contentInset = UIEdgeInsetsMake(offset, self.scrollView.contentInset.left,
                                                         self.scrollView.contentInset.bottom,
                                                         self.scrollView.contentInset.right);
            self.scrollView.contentInset = contentInset;
        }
        else
        {
            if (self.scrollView.contentSize.height >= self.scrollView.bounds.size.height)
            {
                CGFloat offset = MAX(self.scrollView.contentSize.height
                                     - self.scrollView.bounds.size.height
                                     + self.bounds.size.height, 0.0f);
                
                offset = MIN(offset, self.originalBottomInset + self.bounds.size.height);
                UIEdgeInsets contentInset = self.scrollView.contentInset;
                self.scrollView.contentInset = UIEdgeInsetsMake(contentInset.top, contentInset.left,
                                                                offset, contentInset.right);
            }
            else if (self.wasTriggeredByUser)
            {
                CGFloat offset = MIN(self.bounds.size.height, self.originalBottomInset + self.bounds.size.height);
                UIEdgeInsets contentInset = UIEdgeInsetsMake(-offset, self.scrollView.contentInset.left,
                                                             self.scrollView.contentInset.bottom,
                                                             self.scrollView.contentInset.right);

                [self setScrollViewContentInset:contentInset];
            }
        }
    }
}

#pragma mark -

- (void)triggerRefresh
{
    [self.scrollView triggerPullToRefreshWithPosition:self.position];
}

- (void)startAnimating
{
    switch (self.position)
    {
        case Drag2RefreshPositionTop : {
            if( fequalzero(self.scrollView.contentOffset.y))
            {
                CGPoint offsetPoint = CGPointMake(self.scrollView.contentOffset.x, -self.frame.size.height);
                [self.scrollView setContentOffset:offsetPoint animated:YES];
                self.wasTriggeredByUser = NO;
            }
            else
            {
                self.wasTriggeredByUser = YES;
            }
        } break;
            
        case Drag2RefreshPositionBottom : {
            if((fequalzero(self.scrollView.contentOffset.y) && self.scrollView.contentSize.height < self.scrollView.bounds.size.height)
               || fequal(self.scrollView.contentOffset.y, self.scrollView.contentSize.height - self.scrollView.bounds.size.height))
            {
                [self.scrollView setContentOffset:(CGPoint){.y = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height, 0.0f) + self.frame.size.height} animated:YES];
                self.wasTriggeredByUser = NO;
            }
            else
            {
                self.wasTriggeredByUser = YES;
            }
            
        } break;
    }
    
    self.state = Drag2RefreshStateLoading;
}

- (void)stopAnimating
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.state = Drag2RefreshStateStopped;
        
        switch (self.position)
        {
            case Drag2RefreshPositionTop : {
                if(!self.wasTriggeredByUser)
                {
                    CGPoint offsetPoint = CGPointMake(self.scrollView.contentOffset.x,
                                                      - self.originalTopInset);
                    [self.scrollView setContentOffset:offsetPoint animated:YES];
                }
            } break;
                
            case Drag2RefreshPositionBottom : {
                if(!self.wasTriggeredByUser)
                {
                    CGPoint offsetPoint = CGPointMake(self.scrollView.contentOffset.x,
                                                      self.scrollView.contentSize.height
                                                      - self.scrollView.bounds.size.height
                                                      + self.originalBottomInset);
                    
                    [self.scrollView setContentOffset:offsetPoint animated:YES];
                }
            } break;
        }
    });
}

- (BOOL)isAnimating
{
    return self.state == Drag2RefreshStateLoading;
}

#pragma mark - getter & getter

- (RotationIndicatorView *)activityIndicatorView
{
    if(!_activityIndicatorView)
    {
        _activityIndicatorView = [[RotationIndicatorView alloc] initWithFrame:CGRectMake(36,15,18,18)];
        [_activityIndicatorView setImage:[UIImage imageNamed:@"loading"]];
        
        [self addSubview:_activityIndicatorView];
		_activityIndicatorView.hidden = YES;
    }
    return _activityIndicatorView;
}

- (UILabel *)titleLabel
{
    if( !_titleLabel )
    {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 16)];
        _titleLabel.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        
        _titleLabel.font = [UIFont fontWithName:@"Helvetica" size:14.f];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
//        _titleLabel.textColor = kColorSlipHeadRefresh;
        _titleLabel.numberOfLines = 1;

        [self addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UILabel *)subtitleLabel
{
    if( !_subtitleLabel )
    {
        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_subtitleLabel.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2 + 12+8);
        _subtitleLabel.bounds = CGRectMake(0, 0, 200, 40);
        
        _subtitleLabel.font = [UIFont fontWithName:@"Helvetica" size:14.f];
        _subtitleLabel.backgroundColor = [UIColor clearColor];
//        _subtitleLabel.textColor = kColorSlipHeadRefresh;
		_subtitleLabel.numberOfLines = 1;
        
        [self addSubview:_subtitleLabel];
    }
    
    return _subtitleLabel;
}

- (UILabel *)dateLabel
{
    return self.showsDateLabel ? self.subtitleLabel : nil;
}

- (void)setState:(Drag2RefreshState)newState
{
    if( _state == newState ) return;
    
    Drag2RefreshState previousState = _state;
    _state = newState;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    switch (newState)
    {
        case Drag2RefreshStateStopped:
        case Drag2RefreshStateLocked: {
            [self resetScrollViewContentInset];
        } break;
            
        case Drag2RefreshStateTriggered: {
            
        } break;
            
        case Drag2RefreshStateLoading: {
            [self setScrollViewContentInsetForLoading];
            
            if(previousState == Drag2RefreshStateTriggered
               && self.drag2RefreshActionHandler)
            {
                self.drag2RefreshActionHandler();
            }
        } break;
    }
}

- (void)setPosition:(Drag2RefreshPosition)newPosition
{
    _position = newPosition;
    
    if ( _position == Drag2RefreshPositionBottom )
    {
        [self setTitle:@"上拉加载更多..." forState:Drag2RefreshStateStopped];
    }
}

- (void)setLastUpdatedDate:(NSDate *)newLastUpdatedDate
{
    _lastUpdatedDate = newLastUpdatedDate;
    
    self.showsDateLabel = YES;
    NSString *timeDesc = newLastUpdatedDate?[self.dateFormatter stringFromDate:newLastUpdatedDate]:@"Never";
    self.dateLabel.text = [NSString stringWithFormat:@"Last Updated: %@", timeDesc];
}

- (void)setDateFormatter:(NSDateFormatter *)newDateFormatter
{
	_dateFormatter = newDateFormatter;
    
    NSString *timeDesc = self.lastUpdatedDate?[newDateFormatter stringFromDate:self.lastUpdatedDate]:@"Never";
    self.dateLabel.text = [NSString stringWithFormat:@"Last Updated: %@", timeDesc];
}

@end

