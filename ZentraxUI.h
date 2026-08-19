//
//  ZentraxUI.h
//  Zentrax VIP - Premium Execution Node UI
//
//  Created by Zentrax Team.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Delegate protocol for backend integration
@protocol ZentraxUIDelegate <NSObject>
@optional
- (void)zentraxDidRequestAuthenticationWithKey:(NSString *)key completion:(void(^)(BOOL success, NSString * _Nullable errorMsg))completion;
- (void)zentraxDidRequestModuleToggle:(NSString *)moduleId state:(BOOL)isOn completion:(void(^)(BOOL success, NSString * _Nullable errorMsg))completion;
- (void)zentraxDidRequestLogoutWithCompletion:(void(^)(void))completion;
@end

@interface ZentraxUI : UIViewController

@property (nonatomic, weak) id<ZentraxUIDelegate> delegate;

// Public API to update UI state from the backend
- (void)showGlobalLoadingState:(NSString *)message;
- (void)hideGlobalLoadingState;

- (void)showNetworkError;
- (void)showServerError;
- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds;
- (void)showSuccessMessage:(NSString *)title message:(NSString *)message;

// Data Injection
- (void)updateDashboardWithModules:(NSArray<NSDictionary *> *)modules;
- (void)updateSubscriptionState:(NSDictionary *)subData;

@end

NS_ASSUME_NONNULL_END
