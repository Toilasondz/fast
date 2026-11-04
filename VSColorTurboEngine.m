// VSColorTurboEngine.m — Safe Turbo Engine for VideoStar
#import "VSColorTurboEngine.h"
#import <objc/runtime.h>

@implementation VSColorTurboEngine

+ (instancetype)sharedEngine {
    static VSColorTurboEngine *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[VSColorTurboEngine alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isTurboEnabled = NO; // DEFAULT OFF AT LAUNCH — Prevents any startup crashes!
        _speedMultiplier = 25.0;
    }
    return self;
}

- (void)startHooks {
    static dispatch_once_t hookToken;
    dispatch_once(&hookToken, ^{
        // 1. Swizzle UIView class methods
        Class uiViewMeta = object_getClass((id)[UIView class]);
        
        SEL s1 = @selector(animateWithDuration:animations:completion:);
        SEL s1New = @selector(vs_animateWithDuration:animations:completion:);
        Method m1 = class_getClassMethod([UIView class], s1);
        Method m1New = class_getClassMethod([UIView class], s1New);
        if (m1 && m1New) {
            method_exchangeImplementations(m1, m1New);
        }

        SEL s2 = @selector(animateWithDuration:animations:);
        SEL s2New = @selector(vs_animateWithDuration:animations:);
        Method m2 = class_getClassMethod([UIView class], s2);
        Method m2New = class_getClassMethod([UIView class], s2New);
        if (m2 && m2New) {
            method_exchangeImplementations(m2, m2New);
        }

        // 2. Swizzle NSThread sleep
        Class nsThreadMeta = object_getClass((id)[NSThread class]);
        SEL sSleep = @selector(sleepForTimeInterval:);
        SEL sSleepNew = @selector(vs_sleepForTimeInterval:);
        Method mSleep = class_getClassMethod([NSThread class], sSleep);
        Method mSleepNew = class_getClassMethod([NSThread class], sSleepNew);
        if (mSleep && mSleepNew) {
            method_exchangeImplementations(mSleep, mSleepNew);
        }

        NSLog(@"[VSFastColor] Hooks initialized cleanly without side-effects.");
    });
}

@end

#pragma mark — Safe Swizzled Categories

@implementation UIView (VSFastColorTurbo)

+ (void)vs_animateWithDuration:(NSTimeInterval)duration
                    animations:(void (^)(void))animations
                    completion:(void (^ _Nullable)(BOOL finished))completion {
    if ([VSColorTurboEngine sharedEngine].isTurboEnabled) {
        NSTimeInterval fast = duration > 0 ? (duration / [VSColorTurboEngine sharedEngine].speedMultiplier) : 0;
        if (fast > 0.05) fast = 0.02;
        [self vs_animateWithDuration:fast animations:animations completion:completion];
    } else {
        [self vs_animateWithDuration:duration animations:animations completion:completion];
    }
}

+ (void)vs_animateWithDuration:(NSTimeInterval)duration
                    animations:(void (^)(void))animations {
    if ([VSColorTurboEngine sharedEngine].isTurboEnabled) {
        NSTimeInterval fast = duration > 0 ? (duration / [VSColorTurboEngine sharedEngine].speedMultiplier) : 0;
        if (fast > 0.05) fast = 0.02;
        [self vs_animateWithDuration:fast animations:animations];
    } else {
        [self vs_animateWithDuration:duration animations:animations];
    }
}

@end

@implementation NSThread (VSFastColorTurbo)

+ (void)vs_sleepForTimeInterval:(NSTimeInterval)ti {
    if ([VSColorTurboEngine sharedEngine].isTurboEnabled) {
        NSTimeInterval fast = ti / 50.0;
        if (fast > 0.001) {
            [self vs_sleepForTimeInterval:fast];
        }
    } else {
        [self vs_sleepForTimeInterval:ti];
    }
}

@end
