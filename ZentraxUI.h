//
//  ZentraxUI.h
//  Zentrax VIP - Flagship Premium UI Layer
//
//  Architecture: Server-authoritative UI / Network-driven state
//  Status: FINAL CONTRACT
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ZentraxUI;

typedef NS_ENUM(NSInteger, ZXAuthError) {
    ZXAuthErrorNone = 0,
    ZXAuthErrorInvalidKey,
    ZXAuthErrorExpiredKey,
    ZXAuthErrorRevokedKey,
    ZXAuthErrorDeviceLimit,
    ZXAuthErrorInvalidSession,
    ZXAuthErrorConnection,
    ZXAuthErrorServer,
    ZXAuthErrorMaintenance,
    ZXAuthErrorVersionMismatch,
    ZXAuthErrorCompatibility,
    ZXAuthErrorRateLimited,
    ZXAuthErrorInvalidResponse
};

typedef NS_ENUM(NSInteger, ZXStartupState) {
    ZXStartupStateUnknown = 0,
    ZXStartupStateBootstrapping,
    ZXStartupStateReady,
    ZXStartupStateMaintenance,
    ZXStartupStateVersionMismatch,
    ZXStartupStateIncompatible,
    ZXStartupStateConnectionError
};

typedef NS_ENUM(NSInteger, ZXLicenseUIStatus) {
    ZXLicenseUIStatusUnknown = 0,
    ZXLicenseUIStatusUnactivated,
    ZXLicenseUIStatusActive,
    ZXLicenseUIStatusExpired,
    ZXLicenseUIStatusRevoked,
    ZXLicenseUIStatusDisabled
};

typedef NS_ENUM(NSInteger, ZXSafeModeState) {
    ZXSafeModeStateOff = 0,
    ZXSafeModeStateLocked,
    ZXSafeModeStateUnlocked
};

typedef NS_ENUM(NSInteger, ZXDeviceCompatibilityUIStatus) {
    ZXDeviceCompatibilityUIStatusUnknown = 0,
    ZXDeviceCompatibilityUIStatusSupported,
    ZXDeviceCompatibilityUIStatusUnsupported
};

@protocol ZentraxUIDelegate <NSObject>
@optional

#pragma mark - Authentication / Session

- (void)zentraxDidRequestAuthenticationWithKey:(NSString *)key
                                    completion:(void (^)(BOOL success,
                                                         ZXAuthError errorType,
                                                         NSString * _Nullable errorMsg))completion;

- (void)zentraxDidRequestSessionVerificationWithCompletion:(void (^)(BOOL isValid))completion;

- (void)zentraxDidRequestLogoutWithCompletion:(void (^)(void))completion;

#pragma mark - Module Operations

- (void)zentraxDidRequestModuleToggle:(NSString *)moduleId
                                state:(BOOL)isOn
                           completion:(void (^)(BOOL success,
                                                NSString * _Nullable errorMsg))completion;

- (void)zentraxDidRequestFunctionOperation:(NSString *)functionId
                                   action:(BOOL)isOn
                               completion:(void (^)(BOOL success,
                                                    NSString * _Nullable errorMsg))completion;

#pragma mark - Settings / Security

- (void)zentraxDidRequestSafeModeChange:(BOOL)enabled
                              completion:(void (^)(BOOL success,
                                                   NSString * _Nullable errorMsg))completion;

- (void)zentraxDidRequestCompatibilityRecheckWithCompletion:(void (^)(BOOL success,
                                                                        NSDictionary * _Nullable compatibility,
                                                                        NSString * _Nullable errorMsg))completion;


@end

@interface ZentraxUI : UIViewController

@property (nonatomic, weak, nullable) id<ZentraxUIDelegate> delegate;

#pragma mark - Lifecycle / Bootstrap

- (void)startZentraxUI;
- (void)beginBootstrap;
- (void)handleBootstrapState:(ZXStartupState)state
                     message:(NSString * _Nullable)message;
- (void)showStartupState:(ZXStartupState)state
                 message:(NSString * _Nullable)message;
- (void)showLoginScreen;
- (void)showDashboard;
- (void)showMaintenanceScreenWithMessage:(NSString *)message;
- (void)showUpdateRequiredScreenWithMessage:(NSString *)message;
- (void)showConnectionErrorScreenWithMessage:(NSString *)message;
- (void)showCompatibilityScreenWithData:(NSDictionary *)compatibility;

#pragma mark - Global UI / Overlays

- (void)showGlobalLoadingState:(NSString *)message;
- (void)updateGlobalLoadingMessage:(NSString *)message;
- (void)hideGlobalLoadingState;

- (void)showGlobalErrorWithTitle:(NSString *)title
                         message:(NSString *)message;

- (void)showNetworkError;
- (void)showServerError;
- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds;
- (void)showSuccessMessage:(NSString *)title
                   message:(NSString *)message;

- (void)showToast:(NSString *)message;
- (void)showToast:(NSString *)message
          success:(BOOL)success;

#pragma mark - Dynamic Dashboard

/// Backend-driven hierarchy. UI must not hard-code the available function list.
- (void)updateDashboardWithModules:(NSArray<NSDictionary *> *)modules;

/// Accepts the complete server dashboard/configuration payload.
- (void)updateDashboardWithConfiguration:(NSDictionary *)configuration;

/// Updates license/subscription information supplied by the server.
- (void)updateSubscriptionState:(NSDictionary *)subData;

/// Updates one function's authoritative state.
- (void)updateFunctionState:(NSString *)functionId
                      state:(BOOL)isOn;

/// Updates multiple function states.
- (void)updateFunctionStates:(NSDictionary<NSString *, NSNumber *> *)states;

/// Updates server-controlled banners/notices.
- (void)updateServerBanner:(NSDictionary * _Nullable)banner;

/// Updates server time data used by the UI countdown.
- (void)updateServerTime:(NSDate *)serverDate;

#pragma mark - License / Countdown

- (void)updateLicenseStatus:(ZXLicenseUIStatus)status
                activatedAt:(NSDate * _Nullable)activatedAt
                  expiresAt:(NSDate * _Nullable)expiresAt
                  isPermanent:(BOOL)isPermanent;

- (void)startLicenseCountdown;
- (void)stopLicenseCountdown;
- (void)refreshLicenseCountdown;

#pragma mark - Device Compatibility

- (void)updateDeviceCompatibility:(NSDictionary *)compatibility;
- (void)showDeviceCompatibilityDetails;
- (void)requestDeviceCompatibilityRecheck;

#pragma mark - Safe UI Mode

- (void)updateSafeModeState:(ZXSafeModeState)state;
- (void)showSafeModeLockScreen;
- (void)showSafeModeSettings;
- (void)lockSafeMode;
- (void)unlockSafeMode;

#pragma mark - Settings

- (void)showSettings;
- (void)showSettingsSection:(NSString * _Nullable)sectionIdentifier;


#pragma mark - Navigation / State

- (void)resetToStartup;
- (void)dismissPresentedUI;
- (BOOL)isShowingLogin;
- (BOOL)isShowingDashboard;
- (BOOL)isShowingSafeModeLock;

@end

NS_ASSUME_NONNULL_END
