//
//  ZentraxUI.h
//  Zentrax VIP - Premium Execution Node UI
//
//  Created by Zentrax Team.
//  Architecture: Ultra-Premium SaaS Layer
//  Status: PRODUCTION READY
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZXAuthError) {
    ZXAuthErrorNone,
    ZXAuthErrorInvalid,
    ZXAuthErrorExpired,
    ZXAuthErrorConnection,
    ZXAuthErrorServer
};

/// Delegate protocol for backend network integration
@protocol ZentraxUIDelegate <NSObject>
@optional
/// Fired when the user attempts to log in
- (void)zentraxDidRequestAuthenticationWithKey:(NSString *)key completion:(void(^)(BOOL success, ZXAuthError errorType, NSString * _Nullable errorMsg))completion;

/// Fired when a module switch is toggled
- (void)zentraxDidRequestModuleToggle:(NSString *)moduleId state:(BOOL)isOn completion:(void(^)(BOOL success, NSString * _Nullable errorMsg))completion;

/// Fired if a logout action is triggered
- (void)zentraxDidRequestLogoutWithCompletion:(void(^)(void))completion;

/// Silently verifies the existing Keychain session on app launch
- (void)zentraxDidRequestSessionVerificationWithCompletion:(void(^)(BOOL isValid))completion;
@end

@interface ZentraxUI : UIViewController

/// Set this delegate to your ZentraxNetworkManager to handle server requests
@property (nonatomic, weak) id<ZentraxUIDelegate> delegate;

// MARK: - Global UI Overlays
- (void)showGlobalLoadingState:(NSString *)message;
- (void)hideGlobalLoadingState;

// MARK: - Error & Success Handling Modals
- (void)showNetworkError;
- (void)showServerError;
- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds;
- (void)showSuccessMessage:(NSString *)title message:(NSString *)message;
- (void)showGlobalErrorWithTitle:(NSString *)title message:(NSString *)msg;

// MARK: - Dynamic Data Injection
/// Passes the array of module dictionaries received from the PHP backend to build the list
- (void)updateDashboardWithModules:(NSArray<NSDictionary *> *)modules;

/// Updates the session details (e.g., expiry date, license status) on the dashboard
- (void)updateSubscriptionState:(NSDictionary *)subData;

@end

NS_ASSUME_NONNULL_END
