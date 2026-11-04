// VSColorTurboEngine.h — Safe Turbo Engine for VideoStar
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VSColorTurboEngine : NSObject

@property (nonatomic, assign) BOOL isTurboEnabled;
@property (nonatomic, assign) CGFloat speedMultiplier;

+ (instancetype)sharedEngine;
- (void)startHooks;

@end

NS_ASSUME_NONNULL_END
