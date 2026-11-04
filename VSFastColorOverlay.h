// VSFastColorOverlay.h — Ultra Safe Floating Turbo Toggle
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VSFastColorOverlay : UIView

+ (instancetype)sharedOverlay;

/// Safely attach to the app's active window
+ (void)installSafely;

/// Update appearance based on state
- (void)updateAppearance;

@end

NS_ASSUME_NONNULL_END
