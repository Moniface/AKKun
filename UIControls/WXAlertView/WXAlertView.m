//
//  WXAlertView.m
//  Messenger
//
//  Created by 慕桥(黄玉坤) on 13-8-6.
//
//

#import "WXAlertView.h"
#import <QuartzCore/QuartzCore.h>

#define kComBtnTitleFont                 [UIFont systemFontOfSize:13.0]
#define kAlertContainerViewBorderWidth      3.0f

typedef void (^WXAlertViewClickActionBlock)(NSUInteger buttonIndex);

@interface WXAlertHeaderView : UIView <WXAlertViewHeaderView>

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) NSString *text;

@end

@interface WXAlertTrunkView : UIView <WXAlertViewTrunkView>
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UILabel *textLabel;
@end

@interface WXAlertTailView : UIView <WXAlertViewTailView>

//@property (nonatomic, strong) NSString *text;
//@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) NSArray *otherButtons;
@property (nonatomic, strong) NSMutableArray *allSeparatorLines;
@property (nonatomic, strong) UIView *buttonsContainerView;
@property (unsafe_unretained, nonatomic, readonly) NSArray *allButtons;

@end

@interface WXAlertView ()

@property (nonatomic, strong) UIView<WXAlertViewHeaderView> *headerView;
@property (nonatomic, strong) UIView<WXAlertViewTailView> *tailView;
@property (nonatomic, strong) UIWindow *overlayWindow;
@property (nonatomic, assign) WXAlertViewMaskType maskType;
@property (nonatomic, strong) UIImageView *alertContainerView;
@property (nonatomic, strong) UIView *clickBlockerView;
@property (nonatomic, strong) NSArray *allButtons;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, copy, readwrite) WXAlertViewClickActionBlock clickAction;

@end

@implementation WXAlertView

#pragma mark - NSObject Methods

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
		self.alpha = 0;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.clickBlockerView = [[UIView alloc] initWithFrame:frame];
        _clickBlockerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _clickBlockerView.userInteractionEnabled = NO;
        [self addSubview:_clickBlockerView];
        
        [self.headerView addObserver:self forKeyPath:@"frame" options:0 context:nil];
        [self.tailView addObserver:self forKeyPath:@"frame" options:0 context:nil];
    }
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ((object == self.headerView || object == self.tailView || object == self.trunkView)
        && [keyPath isEqualToString:@"frame"])
    {
        [self centerAlertContainer];
    }
}

- (void)setHeaderView:(UIView<WXAlertViewHeaderView> *)newHeaderView
{
    if ( _headerView && _headerView == newHeaderView) return;
    
    [_headerView removeObserver:self forKeyPath:@"frame"];
    RELEASE_SAFELY(_headerView);
    
    _headerView = newHeaderView;
    [_headerView addObserver:self forKeyPath:@"frame" options:0 context:nil];
}

- (void)setTrunkView:(UIView/*<WXAlertViewTrunkView>*/ *)newTrunkView
{
    if ( _trunkView && _trunkView == newTrunkView) return;
    
    [_trunkView removeObserver:self forKeyPath:@"frame"];
    RELEASE_SAFELY(_trunkView);
    
    _trunkView = newTrunkView;
    [_trunkView addObserver:self forKeyPath:@"frame" options:0 context:nil];
}

- (void)dealloc
{
    [self.headerView removeObserver:self forKeyPath:@"frame"];
    [self.tailView removeObserver:self forKeyPath:@"frame"];
    [self.trunkView removeObserver:self forKeyPath:@"frame"];
}

#pragma mark - UIView Methods

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    switch (self.maskType)
    {
        case WXAlertViewMaskTypeBlack:
        {
            [[UIColor colorWithWhite:0 alpha:0.5] set];
            CGContextFillRect(context, self.bounds);
            break;
        }
        case WXAlertViewMaskTypeWhite:
        {
            [[UIColor colorWithWhite:1.0 alpha:0.5] set];
            CGContextFillRect(context, self.bounds);
            break;
        }
        case WXAlertViewMaskTypeGradient:
        {
            size_t locationsCount = 2;
            CGFloat locations[2] = {0.0f, 1.0f};
            CGFloat colors[8] = {0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.75f};
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, locationsCount);
            CGColorSpaceRelease(colorSpace);
            
            CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
            float radius = MIN(self.bounds.size.width , self.bounds.size.height) ;
            CGContextDrawRadialGradient (context, gradient, center, 0, center, radius, kCGGradientDrawsAfterEndLocation);
            CGGradientRelease(gradient);
            
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - Static Methods

+ (void)dismissAllAlertView
{
    WXAlertView *topAlertView = [[self alertViewsList] lastObject];
    if ( topAlertView == nil ) return;
    
    [[self alertViewsList] removeAllObjects];
    [[self alertViewsList] addObject:topAlertView];
    
    [self popTopAlertView];
}

- (void)showWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle
{
    [self showWithTitle:title message:message delegate:nil clickAction:nil maskType:WXAlertViewMaskTypeBlack userInfo:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
}

- (void)showWithTitle:(NSString *)title message:(NSString *)message clickAction:(void (^)(NSUInteger))clickAction maskType:(WXAlertViewMaskType)maskType userInfo:(NSDictionary *)userInfo cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles
{
    [self showWithTitle:title message:message delegate:nil clickAction:clickAction maskType:maskType userInfo:userInfo cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles];
}

- (void)showWithTitle:(NSString *)title message:(NSString *)message delegate:(id<WXAlertViewDelegate>)delegate maskType:(WXAlertViewMaskType)maskType userInfo:(NSDictionary *)userInfo cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles
{
    [self showWithTitle:title message:message delegate:delegate clickAction:nil maskType:maskType userInfo:userInfo cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles];
}

- (void)showWithTitle:(NSString *)title trunkView:(UIView *)trunk delegate:(id<WXAlertViewDelegate>)delegate maskType:(WXAlertViewMaskType)maskType userInfo:(NSDictionary *)userInfo
    cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles
{
    [self showWithTitle:title trunkView:trunk delegate:delegate clickAction:nil maskType:maskType userInfo:userInfo cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles];
}

- (void)showWithTitle:(NSString *)title trunkView:(UIView *)trunk clickAction:(void (^)(NSUInteger buttonIndex))clickAction maskType:(WXAlertViewMaskType)maskType
             userInfo:(NSDictionary *)userInfo cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles
{
    [self showWithTitle:title trunkView:trunk delegate:nil clickAction:clickAction maskType:maskType userInfo:userInfo cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles];
}

- (void)dismiss
{
    [self dismissAnimated:YES completion:nil];
}

- (void)changeAlertOffset:(NSInteger)offset
{
    CGRect frame = self.alertContainerView.frame;
    frame.origin.y += offset;
    self.alertContainerView.frame = frame;
}

#pragma mark - Object Lifecycle

- (void)showWithTitle:(NSString *)title message:(NSString *)message delegate:(id<WXAlertViewDelegate>)delegate clickAction:(void (^)(NSUInteger buttonIndex))clickAction maskType:(WXAlertViewMaskType)maskType userInfo:(NSDictionary *)userInfo cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles
{
    UIView<WXAlertViewTrunkView> *trunkView = nil;
    if ( message.length > 0 )
    {
        WXAlertTrunkView *textView = [[WXAlertTrunkView alloc] initWithFrame:(CGRect){0.0,50,300,0}];
        [textView setText:message];
        trunkView = textView;
    }
    
    [self showWithTitle:title trunkView:trunkView delegate:delegate clickAction:clickAction maskType:maskType userInfo:userInfo cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles];
}

- (void)showWithTitle:(NSString *)title trunkView:(UIView *)trunk delegate:(id<WXAlertViewDelegate>)delegate clickAction:(void (^)(NSUInteger buttonIndex))clickAction maskType:(WXAlertViewMaskType)maskType userInfo:(NSDictionary *)userInfo cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles
{
    [self setFrame:[[UIScreen mainScreen] bounds]];
    
    if( !self.superview )
    {
        [self.overlayWindow addSubview:self];
    }
    
    self.maskType = maskType;
    self.delegate = delegate;
    self.userInfo = userInfo;
    self.clickAction = clickAction;
    
    UIView<WXAlertViewHeaderView> *headerView = nil;//self.headerView;
    UIView<WXAlertViewTailView> *tailView = self.tailView;
    UIView/*<WXAlertViewTailView>*/ *trunkView = trunk;
    
    if (/*!headerView ||*/ !tailView)
    {
        // NSLog(@"You must override the headerView and tailView getters.");
        return;
    }
    
    if ( title.length > 0 )
    {
        headerView = [[WXAlertHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 30.0)];
        [headerView setText:title];
        
        self.headerView = headerView;
        
        
        [self.alertContainerView addSubview:headerView];
    }
    else
    {
        self.headerView = nil;
    }
    
    // 默认最后一个按钮是green style，其他按钮都是gray style
    UIButton *cancelButton = nil;
    if( cancelButtonTitle != nil )
    {
        if( [otherButtonTitles count] > 0 )
            cancelButton = [self grayStyleButton];
        else
            cancelButton = [self greenStyleButton];
        
        self.cancelButton = cancelButton;
    }
    
    if (cancelButton)
    {
        [cancelButton setTitle:cancelButtonTitle forState:UIControlStateNormal];
        [tailView setCancelButton:cancelButton];
    }
    
    NSMutableArray *otherButtons = [[NSMutableArray alloc] init];
    
    NSUInteger count = [otherButtonTitles count];
    [otherButtonTitles enumerateObjectsUsingBlock:^(NSString *atitle, NSUInteger idx, BOOL *stop) {
        UIButton *button = nil;
        if( idx >= count - 1 )
            button = [self greenStyleButton];
        else
            button = [self grayStyleButton];
        [button setTitle:atitle forState:UIControlStateNormal];
        [otherButtons addObject:button];
    }];
    
    if (otherButtons.count)
    {
        [tailView setOtherButtons:otherButtons];
    }
    
    self.allButtons = otherButtons ? otherButtons:@[];
    
    if (cancelButton)
    {
        self.allButtons = [self.allButtons arrayByAddingObject:cancelButton];
    }
    
    [self.allButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        [button addTarget:self action:@selector(alertButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }];
    
    [self.alertContainerView addSubview:tailView];
    
    if ( trunkView )
    {
        self.trunkView = trunkView;
        [self.alertContainerView addSubview:trunkView];
    }
    else
    {
        self.trunkView = nil;
    }
    
    [[self class] pushAlertView:self];
}

- (void)showAlertViewAnimated
{
    [self centerAlertContainer];
    [self.overlayWindow setHidden:NO];
    
    if ( ![[[[self class] alertViewsList] lastObject] isEqual:self] )
    {
        return;     /// 非顶部AlertView说明有新的AlertView压栈
    }
    
    if( self.alpha != 1.0 )
    {
        self.alertContainerView.transform = CGAffineTransformScale(self.alertContainerView.transform, 1.3, 1.3);
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.alertContainerView.transform = CGAffineTransformScale(self.alertContainerView.transform, 1/1.3, 1/1.3);
            self.alpha = 1;
        } completion:^(BOOL finished) {
            
        }];
    }
    
    [self setNeedsDisplay];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(BOOL))completion
{
    WXAlertView *topAlertView = [[[self class] alertViewsList] lastObject];
    if ( [self isEqual:topAlertView] )
    {
        [[self class] popTopAlertView];
    }
    else
    {
        [[[self class] alertViewsList] removeObject:self];
    }
}

#pragma mark - Private methods

- (void)alertButtonPressed:(UIButton *)sender
{
    __block NSUInteger index = WXAlertViewCancelButtonIndex;
    
    if (sender != self.cancelButton) {
        
        [self.allButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
            if (button == sender) { index = idx; *stop = YES; }
        }];
        
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(alertView:didSelectButtonAtIndex:)])
    {
        [self.delegate alertView:self didSelectButtonAtIndex:index];
    }
    
    if (self.clickAction) self.clickAction(index);
    
    [self dismissAnimated:YES completion:nil];
}

- (void)centerAlertContainer
{    
    if (/*!self.headerView || */!self.tailView) return;
    
    CGFloat maxWidth = CGRectGetWidth(self.tailView.frame);
    if ( self.headerView ) { maxWidth =  MAX(maxWidth, CGRectGetWidth(self.headerView.frame)); }
    if ( self.trunkView ) { maxWidth = MAX(maxWidth, CGRectGetWidth(self.trunkView.frame)); }
    
    CGFloat x = kAlertContainerViewBorderWidth;
    CGFloat offsetY = kAlertContainerViewBorderWidth + 5;
    
    if ( self.headerView )
    {
        x = floorf((maxWidth - CGRectGetWidth(self.headerView.frame)) * 0.5) + kAlertContainerViewBorderWidth;
        offsetY = floorf(offsetY);
        
        CGRect frame = CGRectMake(x, offsetY,
                                  floorf(CGRectGetWidth(self.headerView.frame)),
                                  floorf(CGRectGetHeight(self.headerView.frame)));
        
        if (!CGRectEqualToRect(self.headerView.frame, frame))
        {
            [self.headerView removeObserver:self forKeyPath:@"frame"];
            [self.headerView setFrame:frame];
            [self.headerView addObserver:self forKeyPath:@"frame" options:0 context:nil];
        }
        
        offsetY += CGRectGetHeight(self.headerView.frame);
    }
    else
    {
        offsetY += 0;  // Top padding
    }
    
    if ( _trunkView )
    {
        x = floorf((maxWidth - CGRectGetWidth(self.trunkView.frame)) * 0.5) + kAlertContainerViewBorderWidth;
        offsetY = floorf(offsetY);
        
        CGRect frame = CGRectMake(x, offsetY,
                                  floorf(CGRectGetWidth(self.trunkView.frame)),
                                  floorf(CGRectGetHeight(self.trunkView.frame)));
        
        if (!CGRectEqualToRect(self.trunkView.frame, frame))
        {
            [self.trunkView removeObserver:self forKeyPath:@"frame"];
            [self.trunkView setFrame:frame];
            [self.trunkView addObserver:self forKeyPath:@"frame" options:0 context:nil];
        }
        
        
        offsetY += CGRectGetHeight(self.trunkView.frame);
        
        offsetY += 5; // 空5个像素
    }
    
    x = floorf((maxWidth - CGRectGetWidth(self.tailView.frame)) * 0.5) + kAlertContainerViewBorderWidth;
    offsetY = floorf(offsetY);
    
    CGRect frame = CGRectMake(x, offsetY,
                              floorf(CGRectGetWidth(self.tailView.frame)),
                              floorf(CGRectGetHeight(self.tailView.frame)));
    
    if (!CGRectEqualToRect(self.tailView.frame, frame))
    {
        [self.tailView removeObserver:self forKeyPath:@"frame"];
        [self.tailView setFrame:frame];
        [self.tailView addObserver:self forKeyPath:@"frame" options:0 context:nil];
    }
    
    CGFloat height = offsetY + CGRectGetHeight(self.tailView.frame);//CGRectGetHeight(self.headerView.frame) + CGRectGetHeight(self.tailView.frame);
    //height += self.trunkView ? CGRectGetHeight(self.trunkView.frame) : 0;
    
    x = floorf((CGRectGetWidth(self.overlayWindow.frame) - maxWidth) * 0.5) + kAlertContainerViewBorderWidth;
    offsetY = floorf((CGRectGetHeight(self.overlayWindow.frame) - height) * 0.5);

    [self.alertContainerView setFrame:CGRectMake(x - kAlertContainerViewBorderWidth, offsetY - kAlertContainerViewBorderWidth, maxWidth + 2*kAlertContainerViewBorderWidth, height + 2*kAlertContainerViewBorderWidth)];
}

+ (void)pushAlertView:(WXAlertView *)alertView
{
    WXAlertView *topAlertView = [[self alertViewsList] lastObject];
    [[self alertViewsList] addObject:alertView];
    
    if ( topAlertView == nil )
    {
        [alertView showAlertViewAnimated];
    }
    else
    {
        CGAffineTransform transform = alertView.alertContainerView.transform;
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction animations:^{
            topAlertView.alertContainerView.transform = CGAffineTransformScale(transform, 0.8, 0.8);
            topAlertView.alpha = 0;
        } completion:^(BOOL finished){
            topAlertView.alertContainerView.transform = transform;
            [topAlertView.overlayWindow setHidden:YES];
            [alertView showAlertViewAnimated];
        }];
    }
}

+ (void)popTopAlertView
{
    WXAlertView *topAlertView = [[self alertViewsList] lastObject];
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction animations:^{
        topAlertView.alertContainerView.transform = CGAffineTransformScale(topAlertView.alertContainerView.transform, 0.8, 0.8);
        topAlertView.alpha = 0;
    } completion:^(BOOL finished){
        [[[self class] alertViewsList] removeObject:topAlertView];
        [topAlertView.overlayWindow setHidden:YES];
        [topAlertView removeFromSuperview];
        
        WXAlertView *topAlertViewNow = [[self alertViewsList] lastObject];
        [topAlertViewNow showAlertViewAnimated];
    }];
}

/// 等待显示的AlertView队列
+ (NSMutableArray *)alertViewsList
{
    static NSMutableArray *alertViews = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        alertViews = [[NSMutableArray alloc] init];
    });
    
    return alertViews;
}

#pragma mark - Getter/Setters

- (UIWindow *)overlayWindow
{
    static UIWindow *overlayWindow = nil;
    if( overlayWindow == nil )
    {
        overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayWindow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        overlayWindow.windowLevel = UIWindowLevelStatusBar - 2;// VOIP -1 不能高于VOIP
        overlayWindow.backgroundColor = [UIColor clearColor];
        overlayWindow.userInteractionEnabled = YES;
    }
    
    return overlayWindow;
}

- (UIView *)alertContainerView
{
    if(_alertContainerView == nil)
    {
        self.alertContainerView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        
        UIViewAutoresizing autoresizingMask = UIViewAutoresizingFlexibleBottomMargin
        | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin
        | UIViewAutoresizingFlexibleLeftMargin;
        
        [_alertContainerView setBackgroundColor:[UIColor clearColor]];
        UIView *backgroudView = [[UIView alloc] initWithFrame:CGRectMake(kAlertContainerViewBorderWidth, kAlertContainerViewBorderWidth, 10 - 2*kAlertContainerViewBorderWidth, 10 - 2*kAlertContainerViewBorderWidth)];
        backgroudView.backgroundColor = [UIColor whiteColor];
        backgroudView.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_alertContainerView addSubview:backgroudView];
        
        _alertContainerView.autoresizingMask = autoresizingMask;
        _alertContainerView.userInteractionEnabled = YES;
        _alertContainerView.layer.borderWidth = kAlertContainerViewBorderWidth;
        _alertContainerView.layer.borderColor = RGBACOLOR(255, 255, 255, 0.2f).CGColor;
        
        [self addSubview:_alertContainerView];
    }
    
    return _alertContainerView;
}

//- (UIView<WXAlertViewHeaderView> *)headerView
//{
//    if (_headerView == nil) {
//        _headerView = [[WXAlertHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 50.0)];
//    }
//    
//    return _headerView;
//}

- (UIView<WXAlertViewTailView> *)tailView
{
    if (_tailView == nil) {
        _tailView = [[WXAlertTailView alloc] initWithFrame:CGRectMake(0.0, 50.0, 300.0, 300.0)];
    }

    return _tailView;
}

- (UIButton *)greenStyleButton
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [btn setFrame:CGRectZero];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn setBackgroundColor:kColorGreenButtonNormalBackground forState:UIControlStateNormal];
    [btn setBackgroundColor:kColorGreenButtonPressedBackground forState:UIControlStateHighlighted];
    [btn.titleLabel setFont:kComBtnTitleFont];

    return btn;
}

- (UIButton *)grayStyleButton
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [btn setFrame:CGRectZero];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn setBackgroundColor:kColorGrayButtonNormalBackground forState:UIControlStateNormal];
    [btn setBackgroundColor:kColorGrayButtonPressedBackground forState:UIControlStateHighlighted];
    [btn.titleLabel setFont:kComBtnTitleFont];
    
    return btn;
}


@end

#pragma mark - WXAlertHeaderView

@implementation WXAlertHeaderView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.font = [UIFont boldSystemFontOfSize:13.0];
        _textLabel.textColor = RGBCOLOR(51, 51, 51);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        _textLabel.textAlignment = UITextAlignmentLeft;
#pragma clang diagnostic pop
        _textLabel.adjustsFontSizeToFitWidth = YES;
        
        [self addSubview:_textLabel];

    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _textLabel.frame = CGRectMake(10.0, 1.0, CGRectGetWidth(self.frame) - 20.0, CGRectGetHeight(self.frame)-2);
    _backgroundImageView.frame = self.bounds;
}

- (void)setText:(NSString *)text
{
    if (_text != text && [text isEqualToString:_text] == NO) {
        _text = text;
        self.textLabel.text = text;
    }
}


@end

#define TextLabelWidthMax 280
#define TextLabelSidePadding 10

#pragma mark - WXAlertTrunkView
@implementation WXAlertTrunkView
- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.font = [UIFont systemFontOfSize:11.0];
        _textLabel.textColor = RGBCOLOR(51, 51, 51);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        _textLabel.textAlignment = UITextAlignmentLeft;
#pragma clang diagnostic pop
        _textLabel.numberOfLines = 0;
        _textLabel.lineBreakMode = NSLineBreakByWordWrapping;

        [self addSubview:_textLabel];
        
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize textSize = [_text sizeWithFont:_textLabel.font
                        constrainedToSize:CGSizeMake(TextLabelWidthMax, 400.0)
                            lineBreakMode:NSLineBreakByWordWrapping];
    
    [_textLabel setFrame:CGRectMake(TextLabelSidePadding, 5.0, self.width - 2*TextLabelSidePadding, textSize.height)];
    
    CGFloat viewWidth = TextLabelWidthMax + 2*TextLabelSidePadding;
    CGRect newFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
                                 viewWidth, floorf(CGRectGetHeight(_textLabel.frame) + 10));
    
    if ( !CGRectEqualToRect(self.frame, newFrame) )
    {
        [self setFrame:newFrame];
        [self setNeedsLayout];
    }
}

- (void)setText:(NSString *)text
{
    if (![text isEqualToString:_text])
    {
        _text = text;
        self.textLabel.text = text;
        [self setNeedsLayout];
    }
}

@end

#pragma mark - WXAlertTailView

@implementation WXAlertTailView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        _allSeparatorLines = [[NSMutableArray alloc] initWithCapacity:5];

    }
    
    return self;
}

const CGFloat kWXAlertButtonHeight = 30.f;
const CGFloat kWXAlertButtonMarginX = 10.f;
const CGFloat kWXAlertButtonMarginY = 10.f;

- (void)layoutSubviews
{
    
    [super layoutSubviews];
    
//    CGSize textSize = [_text sizeWithFont:_textLabel.font constrainedToSize:CGSizeMake(CGRectGetWidth(self.frame) - 40.0, 400.0) lineBreakMode:NSLineBreakByWordWrapping];
//    
//    [_textLabel setFrame:CGRectMake(20.0, 14.0, textSize.width, textSize.height)];
    
    NSArray *buttons = self.allButtons;
    
    if (buttons && buttons.count)
    {
        __block CGFloat lastButtonMaxY = kWXAlertButtonMarginY;
        __block CGFloat width = kWXAlertButtonMarginX;
        __block CGFloat height = 0.0;
        
        if (buttons.count > 2)
        {
            [buttons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
                
                width = CGRectGetWidth(self.frame) - 2*kWXAlertButtonMarginX;
                height = kWXAlertButtonHeight;
                
                [button setFrame:CGRectMake(0.0, (lastButtonMaxY == 0.0) ? lastButtonMaxY : lastButtonMaxY, width, height)];
                
                lastButtonMaxY = CGRectGetMaxY(button.frame) + kWXAlertButtonMarginY / 2;
                
            }];
        }
        else
        {
            CGFloat buttonSpacing = kWXAlertButtonMarginX / 2;
            width = floorf(((CGRectGetWidth(self.frame) - 2*kWXAlertButtonMarginX) - ((buttons.count - 1) * buttonSpacing))/buttons.count);
            height = kWXAlertButtonHeight;
            
            if ( buttons.count == 2 )
            {
                buttons = [[buttons reverseObjectEnumerator] allObjects];
            }
            
            [buttons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
                
                CGFloat x = (idx == 0) ? 0.0 : (idx * width) + (idx * buttonSpacing);
                
                [button setFrame:CGRectMake(x, kWXAlertButtonMarginY, width, height)];
                
                lastButtonMaxY = CGRectGetMaxY(button.frame);
                
            }];
        }
        
        height = lastButtonMaxY + kWXAlertButtonMarginY;
        [_buttonsContainerView setFrame:CGRectMake(kWXAlertButtonMarginX, 0, CGRectGetWidth(self.frame) - 2*kWXAlertButtonMarginX, height)];
        
    }
    else
    {
        [_buttonsContainerView setFrame:CGRectMake(kWXAlertButtonMarginX, 0, CGRectGetWidth(self.frame) - 2*kWXAlertButtonMarginX, 0.0)];
    }
    
//    [self _layoutSeparatorLines];
    
    CGRect newFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
                                 self.frame.size.width, CGRectGetHeight(_buttonsContainerView.frame) );
    
    if (!CGRectEqualToRect(self.frame, newFrame))
    {
        [self setFrame:newFrame];
        [self setNeedsLayout];
    }
}

- (UIView *)buttonsContainerView
{
    if (!_buttonsContainerView)
    {
        self.buttonsContainerView = [[UIView alloc] initWithFrame:CGRectZero];
        [_buttonsContainerView setBackgroundColor:[UIColor clearColor]];
        [self addSubview:_buttonsContainerView];
    }
    
    return _buttonsContainerView;
}

- (void)setCancelButton:(UIButton *)cancelButton
{
    if (_cancelButton == cancelButton) return;
    
    if (_cancelButton && _cancelButton.superview) [_cancelButton removeFromSuperview];
    
    RELEASE_SAFELY(_cancelButton);
    _cancelButton = cancelButton;
    
    [self.buttonsContainerView addSubview:_cancelButton];
    
    [self setNeedsLayout];
}

- (void)setOtherButtons:(NSArray *)otherButtons
{
    if ([_otherButtons isEqualToArray:otherButtons]) return;
    
    [_otherButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        [button removeFromSuperview];
    }];
    
    RELEASE_SAFELY(_otherButtons);
    _otherButtons = otherButtons;
    
    [_otherButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        [self.buttonsContainerView addSubview:button];
    }];
    
    [self setNeedsLayout];
}

//- (void)setText:(NSString *)text
//{
//    if (![text isEqualToString:_text])
//    {
//        _text = text;
//        self.textLabel.text = text;
//    }
//}

- (NSArray *)allButtons
{
    NSMutableArray *buttons = [NSMutableArray array];
    
    if (self.otherButtons && self.otherButtons.count) [buttons addObjectsFromArray:_otherButtons];
    if (self.cancelButton) [buttons addObject:self.cancelButton];
    
    return buttons.count ? buttons : nil;
}

- (void)_layoutSeparatorLines
{
    for (UIView *line in self.allSeparatorLines) {
        [line removeFromSuperview];
    }
    
    if (self.allButtons.count == 2) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:ImageNamed(@"pub_list_line")];
        [imageView setFrame:CGRectMake(0, 0, _buttonsContainerView.bounds.size.width, 1)];
        [imageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [_buttonsContainerView addSubview:imageView];
        [self.allSeparatorLines addObject:imageView];
        
        UIImageView *vertical = [[UIImageView alloc] initWithFrame:CGRectMake(_buttonsContainerView.centerX, 1,
                                                                              1, _buttonsContainerView.height)];
        [vertical setImage:ImageNamed(@"pub_list_line_vertical")];
        [vertical setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [_buttonsContainerView addSubview:vertical];
        [self.allSeparatorLines addObject:vertical];
        
    } else {
        for (int i = 0; i<self.allButtons.count; i++) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:ImageNamed(@"pub_list_line")];
            [imageView setFrame:CGRectMake(0, 0+i*kWXAlertButtonHeight, _buttonsContainerView.bounds.size.width, 1)];
            [imageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
            [_buttonsContainerView addSubview:imageView];
            [self.allSeparatorLines addObject:imageView];
        }
    }
}




@end



