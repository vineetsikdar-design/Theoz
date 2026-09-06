    //
//  ZentraxNetworkManager.h
//  Zentrax VIP - Premium Execution Node
//
//  Production network/session/configuration layer.
//

#import <Foundation/Foundation.h>
#import "ZXStateStore.h"

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

+ (instancetype)sharedManager;

- (BOOL)isRequestInFlight;

- (void)bootstrapWithCompletion:(ZXBootstrapCompletion)completion;

- (void)bootstrapWithPhaseHandler:(ZXAuthenticationPhaseHandler _Nullable)phaseHandler
                       completion:(ZXBootstrapCompletion)completion;

- (void)authenticateWithKey:(NSString *)key
                 completion:(ZXNetworkCompletion)completion;

- (void)authenticateWithKey:(NSString *)key
               phaseHandler:(ZXAuthenticationPhaseHandler _Nullable)phaseHandler
                 completion:(ZXNetworkCompletion)completion;

- (NSString * _Nullable)rememberedLicenseKey;

- (NSDictionary * _Nullable)cachedConfiguration;

- (void)loadConfigurationWithCompletion:(ZXNetworkCompletion)completion;

- (void)toggleModule:(NSString *)moduleName
               state:(BOOL)isOn
          completion:(ZXModuleCompletion)completion;

- (void)performModuleOperationWithFunctionId:(NSString *)functionId
                                       action:(ZXModuleOperationAction)action
                                  completion:(ZXModuleCompletion)completion;

- (void)syncModuleState:(NSString *)moduleName
                  state:(BOOL)isOn
            operationId:(NSString *)operationId
             completion:(ZXModuleSyncCompletion)completion;

- (void)syncModuleStateForFunctionId:(NSString *)functionId
                               state:(BOOL)isOn
                         operationId:(NSString *)operationId
                          completion:(ZXModuleSyncCompletion)completion;

- (void)getFunctionStatus:(NSString *)functionId
               completion:(ZXNetworkCompletion)completion;

- (void)getFunctionStatusesWithCompletion:(ZXNetworkCompletion)completion;

- (void)verifySessionWithCompletion:(ZXSessionCompletion)completion;

- (void)sendHeartbeatWithCompletion:(ZXSessionCompletion)completion;

- (BOOL)hasActiveSession;

- (BOOL)isSessionLocallyUsable;

- (void)logout;

- (NSDictionary *)deviceInformation;

- (void)checkDeviceCompatibilityWithCompletion:(ZXCompatibilityCompletion)completion;

- (NSDictionary * _Nullable)cachedCompatibilityData;

- (void)resetCompatibilityState;

- (void)cancelAllRequests;

@end

NS_ASSUME_NONNULL_END