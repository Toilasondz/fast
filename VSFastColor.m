// VSFastColor.m — Ultra Safe Tweak Entry Point
#import <UIKit/UIKit.h>
#import "VSColorTurboEngine.h"
#import "VSFastColorOverlay.h"

__attribute__((constructor))
static void VSFastColorInit(void) {
    @autoreleasepool {
        NSLog(@"[VSFastColor] Injected into process. Setting up safe hooks...");

        // 1. Initialize method swizzles (default state is OFF, zero interference with launch)
        [[VSColorTurboEngine sharedEngine] startHooks];

        // 2. Attach UI safely after UIApplication is fully running and active
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                              object:nil
                                                               queue:[NSOperationQueue mainQueue]
                                                          usingBlock:^(NSNotification * _Nonnull note) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [VSFastColorOverlay installSafely];
                });
            }];

            // Fallback: in case app became active before this block runs
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [VSFastColorOverlay installSafely];
            });
        });
    }
}
