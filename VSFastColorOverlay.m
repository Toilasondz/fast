// VSFastColorOverlay.m — Ultra Safe Floating Turbo Toggle
#import "VSFastColorOverlay.h"
#import "VSColorTurboEngine.h"

static NSString *const kOverlayPosXKey = @"VSFastColorOverlayX";
static NSString *const kOverlayPosYKey = @"VSFastColorOverlayY";

@interface VSFastColorOverlay ()
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *indicatorDot;
@property (nonatomic, assign) CGPoint lastPanPosition;
@end

@implementation VSFastColorOverlay

+ (instancetype)sharedOverlay {
    static VSFastColorOverlay *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[VSFastColorOverlay alloc] initWithFrame:CGRectMake(20, 110, 156, 40)];
    });
    return instance;
}

+ (void)installSafely {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *targetWindow = nil;
        
        // Find key window or the first active window
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *winScene = (UIWindowScene *)scene;
                    for (UIWindow *w in winScene.windows) {
                        if (w.isKeyWindow || w.windowLevel == UIWindowLevelNormal) {
                            targetWindow = w;
                            break;
                        }
                    }
                    if (targetWindow) break;
                }
            }
        }
        
        if (!targetWindow) {
            targetWindow = [UIApplication sharedApplication].keyWindow;
        }
        if (!targetWindow && [UIApplication sharedApplication].windows.count > 0) {
            targetWindow = [UIApplication sharedApplication].windows.firstObject;
        }

        if (targetWindow) {
            VSFastColorOverlay *overlay = [VSFastColorOverlay sharedOverlay];
            if (overlay.superview != targetWindow) {
                [overlay removeFromSuperview];
                [targetWindow addSubview:overlay];
                [targetWindow bringSubviewToFront:overlay];
                [overlay updateAppearance];
                NSLog(@"[VSFastColor] Attached overlay button safely to main window!");
            }
        } else {
            // Retry after 1 second if window is not ready yet
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self installSafely];
            });
        }
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = frame.size.height / 2.0;
        self.clipsToBounds = NO;
        self.userInteractionEnabled = YES;
        
        // Shadow
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.50;
        self.layer.shadowRadius = 8.0;
        self.layer.shadowOffset = CGSizeMake(0, 4);

        // Blur background
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        _blurView.frame = self.bounds;
        _blurView.layer.cornerRadius = frame.size.height / 2.0;
        _blurView.clipsToBounds = YES;
        _blurView.layer.borderWidth = 1.0;
        _blurView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.20].CGColor;
        _blurView.userInteractionEnabled = NO;
        [self addSubview:_blurView];

        // Status Indicator Dot
        _indicatorDot = [[UIView alloc] initWithFrame:CGRectMake(12, (frame.size.height - 10) / 2.0, 10, 10)];
        _indicatorDot.layer.cornerRadius = 5.0;
        _indicatorDot.clipsToBounds = YES;
        _indicatorDot.userInteractionEnabled = NO;
        [self addSubview:_indicatorDot];

        // Label
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(28, 0, frame.size.width - 34, frame.size.height)];
        _titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.userInteractionEnabled = NO;
        [self addSubview:_titleLabel];

        // Restore position
        [self _restoreSavedPosition];

        // Gestures
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tap];

        [tap requireGestureRecognizerToFail:pan];

        [self updateAppearance];
    }
    return self;
}

- (void)updateAppearance {
    BOOL isTurbo = [VSColorTurboEngine sharedEngine].isTurboEnabled;

    if (isTurbo) {
        self.indicatorDot.backgroundColor = [UIColor colorWithRed:0.20 green:0.88 blue:0.45 alpha:1.0]; // Bright Green
        self.indicatorDot.layer.shadowColor = [UIColor colorWithRed:0.20 green:0.88 blue:0.45 alpha:1.0].CGColor;
        self.indicatorDot.layer.shadowOpacity = 0.8;
        self.indicatorDot.layer.shadowRadius = 4.0;
        
        self.titleLabel.text = @"⚡ Nh\u1EADp M\u00E0u: B\u1EACT";
        self.titleLabel.textColor = [UIColor whiteColor];
        self.blurView.layer.borderColor = [UIColor colorWithRed:0.20 green:0.88 blue:0.45 alpha:0.50].CGColor;
    } else {
        self.indicatorDot.backgroundColor = [UIColor colorWithWhite:0.55 alpha:1.0]; // Gray
        self.indicatorDot.layer.shadowOpacity = 0.0;
        
        self.titleLabel.text = @"⚡ Nh\u1EADp M\u00E0u: T\u1EAET";
        self.titleLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];
        self.blurView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.15].CGColor;
    }
}

#pragma mark — Gestures

- (void)handleTap:(UITapGestureRecognizer *)tap {
    if (tap.state == UIGestureRecognizerStateRecognized) {
        BOOL newState = ![VSColorTurboEngine sharedEngine].isTurboEnabled;
        [VSColorTurboEngine sharedEngine].isTurboEnabled = newState;
        [self updateAppearance];

        // Haptic feedback
        if (@available(iOS 10.0, *)) {
            UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
            [feedback impactOccurred];
        }

        // Pulse Animation
        [UIView animateWithDuration:0.10 animations:^{
            self.transform = CGAffineTransformMakeScale(1.08, 1.08);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.12 animations:^{
                self.transform = CGAffineTransformIdentity;
            }];
        }];

        NSString *msg = newState ?
            @"⚡ B\u1EADt: Nh\u1EADp m\u00E0u si\u00EAu t\u1ED1c (~5-10s)" :
            @"T\u1EAFt: T\u1ED1c \u0111\u1ED9 m\u1EB7c \u0111\u1ECBnh";
        [self _showToast:msg];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.superview];

    if (pan.state == UIGestureRecognizerStateBegan) {
        self.lastPanPosition = self.center;
    }

    CGPoint proposed = CGPointMake(self.lastPanPosition.x + translation.x,
                                   self.lastPanPosition.y + translation.y);
    CGPoint clamped = [self _clampPosition:proposed];
    self.center = clamped;

    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        [self _savePosition:clamped];
    }
}

#pragma mark — Helpers

- (CGPoint)_clampPosition:(CGPoint)proposed {
    UIView *superv = self.superview;
    CGRect bounds = superv ? superv.bounds : [UIScreen mainScreen].bounds;
    CGFloat halfW = self.bounds.size.width / 2.0;
    CGFloat halfH = self.bounds.size.height / 2.0;
    CGFloat padding = 8.0;

    CGFloat minX = halfW + padding;
    CGFloat maxX = bounds.size.width - halfW - padding;
    CGFloat minY = halfH + padding + 40.0;
    CGFloat maxY = bounds.size.height - halfH - padding - 20.0;

    return CGPointMake(MAX(minX, MIN(maxX, proposed.x)),
                       MAX(minY, MIN(maxY, proposed.y)));
}

- (void)_savePosition:(CGPoint)pos {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setDouble:pos.x forKey:kOverlayPosXKey];
    [ud setDouble:pos.y forKey:kOverlayPosYKey];
    [ud synchronize];
}

- (void)_restoreSavedPosition {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if ([ud objectForKey:kOverlayPosXKey] && [ud objectForKey:kOverlayPosYKey]) {
        CGFloat x = [ud doubleForKey:kOverlayPosXKey];
        CGFloat y = [ud doubleForKey:kOverlayPosYKey];
        self.center = [self _clampPosition:CGPointMake(x, y)];
    }
}

- (void)_showToast:(NSString *)message {
    UIView *parent = self.superview;
    if (!parent) return;

    UILabel *toast = [[UILabel alloc] init];
    toast.text = message;
    toast.textColor = [UIColor whiteColor];
    toast.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    toast.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.85];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.layer.cornerRadius = 13.0;
    toast.clipsToBounds = YES;
    toast.alpha = 0.0;

    CGSize size = [message sizeWithAttributes:@{NSFontAttributeName: toast.font}];
    CGFloat width = MIN(size.width + 24.0, parent.bounds.size.width - 40.0);
    toast.frame = CGRectMake((parent.bounds.size.width - width) / 2.0, self.frame.origin.y + self.frame.size.height + 10.0, width, 28.0);

    [parent addSubview:toast];

    [UIView animateWithDuration:0.20 animations:^{
        toast.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 delay:1.8 options:UIViewAnimationOptionCurveEaseIn animations:^{
            toast.alpha = 0.0;
        } completion:^(BOOL finished) {
            [toast removeFromSuperview];
        }];
    }];
}

@end
