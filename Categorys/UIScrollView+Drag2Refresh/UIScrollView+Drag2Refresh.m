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

static CGFloat const SVPullToRefreshViewHeight = 40;

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

#pragma mark - UIScrollView (SVPullToRefresh)
#import <objc/runtime.h>

static char UIScrollViewPullToRefreshView;
static char UIScrollViewPullToRefreshViewTop;

@implementation UIScrollView (Drag2Refresh)
@dynamic btmDrag2RefreshView, topDrag2RefreshView;

- (void)addDragToRefreshWithActionHandler:(void (^)(void))actionHandler
                                 position:(DragToRefreshPosition)position
{
    if ( position == DragToRefreshPositionTop )
    {
        if( !self.topDrag2RefreshView )
        {
            CGRect viewFrame = CGRectMake(0, -SVPullToRefreshViewHeight,
                                          self.width, SVPullToRefreshViewHeight);
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
                                          self.width, SVPullToRefreshViewHeight);
            
            Drag2RefreshView *view = [[Drag2RefreshView alloc] initWithFrame:viewFrame];
            view.drag2RefreshActionHandler = actionHandler;
            view.scrollView = self;
            [self addSubview:view];
            
            view.originalTopInset = self.contentInset.top;
            view.originalBottomInset = self.contentInset.bottom;
            view.position = position;
            
            self.btmDrag2RefreshView = view;
            
            [self showsPullToRefresh:YES position:position];
            [view setTitle:@"上拉加载更多..." forState:DragToRefreshStateStopped];
        }
    }
}

- (void)triggerPullToRefreshWithPosition:(DragToRefreshPosition)position
{
    if ( position == DragToRefreshPositionTop )
    {
        self.topDrag2RefreshView.state = DragToRefreshStateTriggered;
        [self.topDrag2RefreshView startAnimating];
    }
    else
    {
        self.btmDrag2RefreshView.state = DragToRefreshStateTriggered;
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

- (void)showsPullToRefresh:(BOOL)showsPullToRefresh position:(DragToRefreshPosition)position;
{
    Drag2RefreshView *drag2RefreshView = self.topDrag2RefreshView;
    if ( position == DragToRefreshPositionBottom )
    {
        drag2RefreshView = self.btmDrag2RefreshView;
    }
    
    drag2RefreshView.hidden = !showsPullToRefresh;
    
    if( !showsPullToRefresh )
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
            
            BOOL isTopPos = drag2RefreshView.position == DragToRefreshPositionTop;
            CGFloat yOrigin = isTopPos ? -SVPullToRefreshViewHeight:self.contentSize.height;
            drag2RefreshView.frame = CGRectMake(0, yOrigin, self.bounds.size.width, SVPullToRefreshViewHeight);
        }
    }
}

- (void)lockPullToRefresh:(BOOL)lock position:(DragToRefreshPosition)position
{
    Drag2RefreshView *drag2RefreshView = self.topDrag2RefreshView;
    if ( position == DragToRefreshPositionBottom )
    {
        drag2RefreshView = self.btmDrag2RefreshView;
    }
    
    drag2RefreshView.state = lock ? DragToRefreshStateLocked:DragToRefreshStateStopped;
}

@end

#pragma mark - SVPullToRefresh
@implementation Drag2RefreshView

#pragma mark - life cycle

- (id)initWithFrame:(CGRect)frame
{
    if( self = [super initWithFrame:frame] )
    {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = kCOLOR_COM_DEFAULT_BG;
        
        self.state = DragToRefreshStateStopped;
        
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
        CGPoint origin = CGPointMake(roundf((self.width - customView.width)/2),
                                     roundf((self.height-customView.height)/2));
        
        [customView setFrame:CGRectMake(origin.x, origin.y, customView.width, customView.height)];
    }
    else
    {
        [UIView setAnimationsEnabled:NO];
        
        self.titleLabel.text = self.title4State[_state];
        self.titleLabel.width = 200;
        self.titleLabel.centerX = floorf(self.width / 2);
        self.titleLabel.hidden = NO;
        
        switch (self.state)
        {
            case DragToRefreshStateStopped:
            case DragToRefreshStateTriggered:
            case DragToRefreshStateLocked: {
                [self showActivity:NO animated:NO];
                _titleLabel.centerY = floorf(self.height / 2);
            } break;
                
            case DragToRefreshStateLoading: {
                [self showActivity:YES animated:YES];
                
                CGRect rect2Fit = CGRectMake(0, 0, 280, 12);
                CGRect rectFited = [_titleLabel textRectForBounds:rect2Fit limitedToNumberOfLines:1];
                
                CGFloat offsetX = self.width - _activityIndicatorView.width - 12 - rectFited.size.width;
                _activityIndicatorView.left = floorf(offsetX / 2);
                _activityIndicatorView.centerY = floorf(self.height / 2);
                
                _titleLabel.width = rectFited.size.width;
                _titleLabel.left = _activityIndicatorView.right + 12;
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
- (void)setTitle:(NSString *)title forState:(DragToRefreshState)state
{
    if( !title ) { title = @""; }
    
    [self.title4State replaceObjectAtIndex:state withObject:title];
    [self setNeedsLayout];
}

- (void)setSubtitle:(NSString *)subtitle forState:(DragToRefreshState)state
{
    if(!subtitle) { subtitle = @""; }
    [self.subtitle4State replaceObjectAtIndex:state withObject:subtitle];
    [self setNeedsLayout];
}

- (void)setCustomView:(UIView *)view forState:(DragToRefreshState)state
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
        case DragToRefreshPositionTop : {
            currentInsets.top = self.originalTopInset;
        } break;
        case DragToRefreshPositionBottom : {
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
        case DragToRefreshPositionTop : {
            currentInsets.top = MIN(offset, self.originalTopInset + self.bounds.size.height);
        } break;
        case DragToRefreshPositionBottom : {
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
        CGFloat yOrigin = _position==DragToRefreshPositionTop ? -SVPullToRefreshViewHeight:yOrigin4PosBtm;
        self.frame = CGRectMake(0, yOrigin, self.bounds.size.width, SVPullToRefreshViewHeight);
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
    if ( self.state == DragToRefreshStateLocked )
    {
        // Do nothing
    }
    else if( self.state != DragToRefreshStateLoading )
    {
        CGFloat scrollOffsetThreshold = 0;      // 初始化位置偏移
        switch (self.position)
        {
            case DragToRefreshPositionTop : {
                scrollOffsetThreshold = self.frame.origin.y - self.originalTopInset;
            } break;
            case DragToRefreshPositionBottom : {
                scrollOffsetThreshold = MAX(self.scrollView.contentSize.height - self.scrollView.height, 0.0f)
                                        + self.bounds.size.height + self.originalBottomInset;
            } break;
        }
        
        if( self.scrollView.isDragging == NO
           && self.state == DragToRefreshStateTriggered )
        {
            self.state = DragToRefreshStateLoading;
        }
        else
        {
            if ( self.position == DragToRefreshPositionTop )
            {
                if(contentOffset.y < scrollOffsetThreshold
                   && self.scrollView.isDragging
                   && self.state == DragToRefreshStateStopped)
                {
                    self.state = DragToRefreshStateTriggered;
                }
                else if(contentOffset.y >= scrollOffsetThreshold
                        && self.state != DragToRefreshStateStopped)
                {
                    self.state = DragToRefreshStateStopped;
                }
            }
            else
            {
                if(contentOffset.y > scrollOffsetThreshold
                   && self.scrollView.isDragging
                   && self.state == DragToRefreshStateStopped)
                {
                    self.state = DragToRefreshStateTriggered;
                }
                else if(contentOffset.y <= scrollOffsetThreshold
                        && self.state != DragToRefreshStateStopped)
                {
                    self.state = DragToRefreshStateStopped;
                }
            }
        }
    }
    else
    {
        if ( DragToRefreshPositionTop == _position )
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
        case DragToRefreshPositionTop : {
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
            
        case DragToRefreshPositionBottom : {
            if((fequalzero(self.scrollView.contentOffset.y)
                && self.scrollView.contentSize.height < self.scrollView.bounds.size.height)
               || fequal(self.scrollView.contentOffset.y, self.scrollView.contentSize.height - self.scrollView.bounds.size.height)) {
                [self.scrollView setContentOffset:(CGPoint){.y = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height, 0.0f) + self.frame.size.height} animated:YES];
                self.wasTriggeredByUser = NO;
            }
            else
            {
                self.wasTriggeredByUser = YES;
            }
            
        } break;
    }
    
    self.state = DragToRefreshStateLoading;
}

- (void)stopAnimating
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.state = DragToRefreshStateStopped;
        
        switch (self.position)
        {
            case DragToRefreshPositionTop : {
                if(!self.wasTriggeredByUser)
                {
                    CGPoint offsetPoint = CGPointMake(self.scrollView.contentOffset.x,
                                                      - self.originalTopInset);
                    [self.scrollView setContentOffset:offsetPoint animated:YES];
                }
            } break;
                
            case DragToRefreshPositionBottom : {
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
    return self.state == DragToRefreshStateLoading;
}

#pragma mark - getter & getter

- (RotationIndicatorView *)activityIndicatorView
{
    if(!_activityIndicatorView)
    {
        _activityIndicatorView = [[RotationIndicatorView alloc] initWithFrame:CGRectMake(36,15,18,18)];
        [_activityIndicatorView setImage:ImageNamed(@"loading")];
        
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
        _titleLabel.center = CGPointMake(self.width/2, self.height/2);
        
        _titleLabel.font = [UIFont fontWithName:@"Helvetica" size:14.f];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = kColorSlipHeadRefresh;
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
		_subtitleLabel.center = CGPointMake(self.width/2, self.height/2 + 12+8);
        _subtitleLabel.bounds = CGRectMake(0, 0, 200, 40);
        
        _subtitleLabel.font = [UIFont fontWithName:@"Helvetica" size:14.f];
        _subtitleLabel.backgroundColor = [UIColor clearColor];
        _subtitleLabel.textColor = kColorSlipHeadRefresh;
		_subtitleLabel.numberOfLines = 1;
        
        [self addSubview:_subtitleLabel];
    }
    
    return _subtitleLabel;
}

- (UILabel *)dateLabel
{
    return self.showsDateLabel ? self.subtitleLabel : nil;
}

- (void)setState:(DragToRefreshState)newState
{
    if( _state == newState ) return;
    
    DragToRefreshState previousState = _state;
    _state = newState;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    switch (newState)
    {
        case DragToRefreshStateStopped:
        case DragToRefreshStateLocked: {
            [self resetScrollViewContentInset];
        } break;
            
        case DragToRefreshStateTriggered: {
            
        } break;
            
        case DragToRefreshStateLoading: {
            [self setScrollViewContentInsetForLoading];
            
            if(previousState == DragToRefreshStateTriggered
               && self.drag2RefreshActionHandler)
            {
                self.drag2RefreshActionHandler();
            }
        } break;
    }
}

- (void)setPosition:(DragToRefreshPosition)newPosition
{
    _position = newPosition;
    
    if ( _position == DragToRefreshPositionBottom )
    {
        [self setTitle:@"上拉加载更多..." forState:DragToRefreshStateStopped];
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

