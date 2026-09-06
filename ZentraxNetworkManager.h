    //
//  ZentraxNetworkManager.h
//  Zentrax VIP - Premium Execution Node
//
//  Production network/session/configuration layer.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZXNetworkErrorType) {
    ZXNetworkErrorNone = 0,
    ZXNetworkErrorInvalidKey,
    ZXNetworkErrorExpiredKey,
    ZXNetworkErrorRevokedKey,
    ZXNetworkErrorDeviceLimit,
    ZXNetworkErrorInvalidSession,
    ZXNetworkErrorMaintenance,
    ZXNetworkErrorVersionMismatch,
    ZXNetworkErrorCompatibility,
    ZXNetworkErrorRateLimited,
    ZXNetworkErrorConnection,
    ZXNetworkErrorInvalidResponse,
    ZXNetworkErrorServer
};

typedef NS_ENUM(NSInteger, ZXBootstrapState) {
    ZXBootstrapStateUnknown = 0,
    ZXBootstrapStateReady,
    ZXBootstrapStateMaintenance,
    ZXBootstrapStateVersionMismatch,
    ZXBootstrapStateIncompatible,
    ZXBootstrapStateConnectionError
};

typedef NS_ENUM(NSInteger, ZXAuthenticationPhase) {
    ZXAuthenticationPhaseIdle = 0,
    ZXAuthenticationPhaseConnecting,
    ZXAuthenticationPhaseAuthenticating,
    ZXAuthenticationPhaseVerifyingLicense,
    ZXAuthenticationPhaseSecuringSession,
    ZXAuthenticationPhaseLoadingConfiguration,
    ZXAuthenticationPhaseAccessGranted
};

typedef NS_ENUM(NSInteger, ZXModuleOperationAction) {
    ZXModuleOperationActionUnknown = 0,
    ZXModuleOperationActionOFF,
    ZXModuleOperationActionON
};

typedef NS_ENUM(NSInteger, ZXDeviceCompatibilityStatus) {
    ZXDeviceCompatibilityStatusUnknown = 0,
    ZXDeviceCompatibilityStatusSupported,
    ZXDeviceCompatibilityStatusUnsupported
};

typedef void (^ZXNetworkCompletion)(BOOL success,
                                    NSDictionary * _Nullable responseData,
                                    ZXNetworkErrorType errorType,
                                    NSString * _Nullable errorMsg);

typedef void (^ZXSessionCompletion)(BOOL isValid,
                                    NSDictionary * _Nullable responseData,
                                    ZXNetworkErrorType errorType,
                                    NSString * _Nullable errorMsg);

typedef void (^ZXBootstrapCompletion)(BOOL success,
                                      NSDictionary * _Nullable responseData,
                                      ZXBootstrapState state,
                                      ZXNetworkErrorType errorType,
                                      NSString * _Nullable errorMsg);

typedef void (^ZXAuthenticationPhaseHandler)(ZXAuthenticationPhase phase,
                                              NSString *message);

typedef void (^ZXCompatibilityCompletion)(BOOL success,
                                           NSDictionary * _Nullable compatibilityData,
                                           ZXDeviceCompatibilityStatus status,
                                           NSString * _Nullable errorMsg);

typedef void (^ZXModuleCompletion)(BOOL success,
                                   NSDictionary * _Nullable modulePayload,
                                   NSString * _Nullable errorMsg);

typedef void (^ZXModuleSyncCompletion)(BOOL success,
                                       NSString * _Nullable errorMsg);

@interface ZentraxNetworkManager : NSObject

#pragma mark - Singleton

/// Singleton instance of the network/session manager.
+ (instancetype)sharedManager;

#pragma mark - Request State

/// Returns YES while one or more network requests are currently active.
- (BOOL)isRequestInFlight;

#pragma mark - Bootstrap

/// Performs the unauthenticated server bootstrap flow.
- (void)bootstrapWithCompletion:(ZXBootstrapCompletion)completion;

/// Performs bootstrap while reporting authentication/bootstrap phases.
- (void)bootstrapWithPhaseHandler:(ZXAuthenticationPhaseHandler _Nullable)phaseHandler
                       completion:(ZXBootstrapCompletion)completion;

#pragma mark - Authentication

/// Authenticates the supplied license key and establishes a secure session.
- (void)authenticateWithKey:(NSString *)key
                 completion:(ZXNetworkCompletion)completion;

/// Authenticates while reporting the individual authentication phases.
- (void)authenticateWithKey:(NSString *)key
               phaseHandler:(ZXAuthenticationPhaseHandler _Nullable)phaseHandler
                 completion:(ZXNetworkCompletion)completion;

/// Returns the securely remembered license key, if one exists.
- (NSString * _Nullable)rememberedLicenseKey;

#pragma mark - Configuration

/// Returns the most recently cached server configuration.
- (NSDictionary * _Nullable)cachedConfiguration;

/// Refreshes configuration from the authenticated heartbeat endpoint.
- (void)loadConfigurationWithCompletion:(ZXNetworkCompletion)completion;

#pragma mark - Module Operations

/// Requests the payload/restore contract for a module and requested state.
- (void)toggleModule:(NSString *)moduleName
               state:(BOOL)isOn
          completion:(ZXModuleCompletion)completion;

/// Requests a module/function operation using its function identifier.
- (void)performModuleOperationWithFunctionId:(NSString *)functionId
                                       action:(ZXModuleOperationAction)action
                                  completion:(ZXModuleCompletion)completion;

#pragma mark - Module Synchronization

/// Synchronizes a module state change with the server.
- (void)syncModuleState:(NSString *)moduleName
                  state:(BOOL)isOn
            operationId:(NSString *)operationId
             completion:(ZXModuleSyncCompletion)completion;

/// Synchronizes a function-ID based state change with the server.
- (void)syncModuleStateForFunctionId:(NSString *)functionId
                               state:(BOOL)isOn
                         operationId:(NSString *)operationId
                          completion:(ZXModuleSyncCompletion)completion;

#pragma mark - Function Status / Dashboard

/// Returns the matching function from the current server configuration.
- (void)getFunctionStatus:(NSString *)functionId
               completion:(ZXNetworkCompletion)completion;

/// Returns the complete current function/category configuration.
- (void)getFunctionStatusesWithCompletion:(ZXNetworkCompletion)completion;

#pragma mark - Session / Heartbeat

/// Verifies the current authenticated session.
- (void)verifySessionWithCompletion:(ZXSessionCompletion)completion;

/// Sends an authenticated heartbeat and refreshes server-side state.
- (void)sendHeartbeatWithCompletion:(ZXSessionCompletion)completion;

/// Returns YES when a session token exists in secure storage.
- (BOOL)hasActiveSession;

/// Returns YES when the locally stored session can currently be used.
- (BOOL)isSessionLocallyUsable;

/// Removes the local authentication/session state.
- (void)logout;

#pragma mark - Device Information / Compatibility

/// Returns the current device/app information sent to the server.
- (NSDictionary *)deviceInformation;

/// Performs a live device compatibility check.
- (void)checkDeviceCompatibilityWithCompletion:(ZXCompatibilityCompletion)completion;

/// Returns the most recently cached compatibility response.
- (NSDictionary * _Nullable)cachedCompatibilityData;

/// Clears the cached compatibility state.
- (void)resetCompatibilityState;

#pragma mark - Request Cancellation

/// Cancels all outstanding network requests.
- (void)cancelAllRequests;

@end

NS_ASSUME_NONNULL_END
