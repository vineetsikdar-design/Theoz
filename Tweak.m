//
//  Tweak.m
//  Zentrax VIP - Core System Hooks & Execution Bridge
//
//  Created by Zentrax Team.
//  Status: PRODUCTION READY
//

@import UIKit;
#import <objc/runtime.h>
#import <objc/message.h>
#import <xpc/xpc.h>
#import <CommonCrypto/CommonDigest.h>

#include <errno.h>
#include <dirent.h>
#include <fcntl.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <dlfcn.h>

// --- ZENTRAX IMPORTS ---
#import "MCMFilzaIntegration.h"
#import "ZentraxUI.h"
#import "ZentraxNetworkManager.h"

#pragma mark - ================= ROOT HELPER HOOKS =================

static BOOL hook_isRootHelperAvailable(id self, SEL _cmd) { return NO; }
static int hook_spawnRootHelper(id self, SEL _cmd) { return 0; }
static int hook_spawnRootHelperIfNeeds(id self, SEL _cmd) { return 0; }
static int hook_respawnRootHelper(id self, SEL _cmd) { return 0; }
static void hook_tryLoadFilzaHelper(id self, SEL _cmd) {}
static void hook_createHelperConnectionIfNeeds(id self, SEL _cmd) {}

static int hook_spawnRoot_args_pid(id self, SEL _cmd, id path, id args, int *pid) {
    if (pid) *pid = 0;
    return -1;
}
static id hook_sendObjectWithReplySync(id self, SEL _cmd, id msg) { return (id)xpc_null_create(); }
static id hook_sendObjectWithReplySync_fd(id self, SEL _cmd, id msg, int *fd) {
    if (fd) *fd = -1;
    return (id)xpc_null_create();
}
static id hook_sendObjectWithReplySync_fd_logintty(id self, SEL _cmd, id msg, int *fd, BOOL logintty) {
    if (fd) *fd = -1;
    return (id)xpc_null_create();
}
static void hook_sendObjectNoReply(id self, SEL _cmd, id msg) {}
static void hook_sendObjectWithReplyAsync(id self, SEL _cmd, id msg, id queue, id completion) {
    if (completion) { void (^block)(id) = completion; block(nil); }
}

#pragma mark - ================= PATH RESOLUTION UTILITIES =================

static NSString *findBundlePath(NSString *bundleId) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *appsDir = @"/var/containers/Bundle/Application";
    for (NSString *uuid in [fm contentsOfDirectoryAtPath:appsDir error:nil]) {
        NSString *uuidPath = [appsDir stringByAppendingPathComponent:uuid];
        for (NSString *item in [fm contentsOfDirectoryAtPath:uuidPath error:nil]) {
            if (![item hasSuffix:@".app"]) continue;
            NSString *appPath = [uuidPath stringByAppendingPathComponent:item];
            NSString *plist = [appPath stringByAppendingPathComponent:@"Info.plist"];
            NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:plist];
            if ([info[@"CFBundleIdentifier"] isEqualToString:bundleId]) return appPath;
        }
    }
    return nil;
}

static NSString *findDataContainer(NSString *bundleId) {
    NSString *error = nil;
    NSString *path = MCMFilzaDataContainerPath(bundleId, &error);
    if (!path) NSLog(@"[Zentrax VIP] Dynamic Container Lookup Failed for id=%@ detail=%@", bundleId, error);
    return path;
}

static NSString *computeSHA256OfData(NSData *data) {
    if (!data) return nil;
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    if (CC_SHA256([data bytes], (CC_LONG)[data length], hash)) {
        NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [output appendFormat:@"%02x", hash[i]];
        }
        return output;
    }
    return nil;
}

#pragma mark - ================= APPS MANAGER HOOKS =================

static IMP orig_allApplications = NULL;
static id hook_allApplications(id self, SEL _cmd) {
    NSArray *origResult = ((id(*)(id,SEL))orig_allApplications)(self, _cmd);
    if (origResult && origResult.count > 0) return origResult;
    return [NSMutableArray array];
}

static IMP orig_setAppProxy = NULL;
static void hook_setAppProxy(id self, SEL _cmd, id proxy) {
    ((void(*)(id,SEL,id))orig_setAppProxy)(self, _cmd, proxy);
    NSString *bundleId = [self performSelector:NSSelectorFromString(@"bundleId")];
    if (!bundleId) return;

    NSString *bundlePath = nil;
    NSString *currentFilePath = [self performSelector:NSSelectorFromString(@"filePath")];

    if (!currentFilePath || currentFilePath.length == 0) {
        NSURL *bundleURL = [proxy performSelector:@selector(bundleURL)];
        if (bundleURL) bundlePath = [bundleURL path];
        if (!bundlePath) bundlePath = findBundlePath(bundleId);
        if (bundlePath) {
            ((void(*)(id,SEL,id))objc_msgSend)(self, NSSelectorFromString(@"setFilePath:"), bundlePath);
        }
    } else {
        bundlePath = currentFilePath;
    }

    NSString *docPath = ((id(*)(id,SEL))objc_msgSend)(self, NSSelectorFromString(@"documentPath"));
    if (!docPath) {
        NSURL *dataURL = [proxy performSelector:@selector(dataContainerURL)];
        if (dataURL) docPath = [dataURL path];
        if (!docPath) docPath = findDataContainer(bundleId);
        if (docPath) {
            ((void(*)(id,SEL,id))objc_msgSend)(self, NSSelectorFromString(@"setDocumentPath:"), docPath);
        }
    }
}

#pragma mark - ================= INTEGRITY BYPASS HOOKS =================

static IMP orig_showAlert = NULL;
static id hook_showAlertWithTitle(id self, SEL _cmd, id title, id text, id cancelButton, id otherButtons, id completion) {
    NSString *textStr = text;
    if ([textStr isKindOfClass:[NSString class]]) {
        if ([textStr containsString:@"binary was modified"] ||
            [textStr containsString:@"reinstall Filza"]) {
            NSLog(@"[Zentrax VIP] Suppressed integrity alert");
            return nil;
        }
    }
    return ((id(*)(id,SEL,id,id,id,id,id))orig_showAlert)(self, _cmd, title, text, cancelButton, otherButtons, completion);
}

static IMP orig_activationViewDidLoad = NULL;
static void hook_activationViewDidLoad(id self, SEL _cmd) {
    ((void(*)(id,SEL))orig_activationViewDidLoad)(self, _cmd);
    dispatch_async(dispatch_get_main_queue(), ^{
        ((void(*)(id,SEL,BOOL,id))objc_msgSend)(self,
            NSSelectorFromString(@"dismissViewControllerAnimated:completion:"), NO, nil);
    });
}

#pragma mark - ================= ZENTRAX VIP EXECUTION BRIDGE =================

@interface ZXCoreBridge : NSObject <ZentraxUIDelegate>
@property (nonatomic, weak) ZentraxUI *uiController;
@property (nonatomic, strong) dispatch_queue_t moduleExecutionQueue;
+ (instancetype)sharedBridge;
@end

@implementation ZXCoreBridge

+ (instancetype)sharedBridge {
    static ZXCoreBridge *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ZXCoreBridge alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Dedicated serial queue to prevent rapid concurrent filesystem overwrites
        _moduleExecutionQueue = dispatch_queue_create("in.zentrax.execution.queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

// Map NetworkManager errors exactly to UI AuthErrors
- (ZXAuthError)mapNetworkErrorToAuthError:(ZXNetworkErrorType)networkError {
    switch (networkError) {
        case ZXNetworkErrorNone: return ZXAuthErrorNone;
        case ZXNetworkErrorInvalidKey: return ZXAuthErrorInvalidKey;
        case ZXNetworkErrorExpiredKey: return ZXAuthErrorExpiredKey;
        case ZXNetworkErrorRevokedKey: return ZXAuthErrorRevokedKey;
        case ZXNetworkErrorDeviceLimit: return ZXAuthErrorDeviceLimit;
        case ZXNetworkErrorInvalidSession: return ZXAuthErrorInvalidSession;
        case ZXNetworkErrorConnection: return ZXAuthErrorConnection;
        case ZXNetworkErrorServer: return ZXAuthErrorServer;
        default: return ZXAuthErrorServer;
    }
}

// 1. Authentication Bridge
- (void)zentraxDidRequestAuthenticationWithKey:(NSString *)key completion:(void(^)(BOOL success, ZXAuthError errorType, NSString * _Nullable errorMsg))completion {
    [[ZentraxNetworkManager sharedManager] authenticateWithKey:key completion:^(BOOL success, NSDictionary * _Nullable responseData, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg) {
        
        ZXAuthError mappedError = [self mapNetworkErrorToAuthError:errorType];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success && responseData) {
                NSArray *modules = responseData[@"modules"];
                if (modules && [modules isKindOfClass:[NSArray class]]) {
                    [self.uiController updateDashboardWithModules:modules];
                }
                NSDictionary *subscription = responseData[@"subscription"];
                if (subscription && [subscription isKindOfClass:[NSDictionary class]]) {
                    [self.uiController updateSubscriptionState:subscription];
                }
                completion(YES, ZXAuthErrorNone, nil);
            } else {
                completion(NO, mappedError, errorMsg ?: @"Authentication failed.");
            }
        });
    }];
}

// 2. Session Verification Bridge (Restores Dashboard Data)
- (void)zentraxDidRequestSessionVerificationWithCompletion:(void(^)(BOOL isValid))completion {
    if (![[ZentraxNetworkManager sharedManager] hasActiveSession]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(NO);
        });
        return;
    }
    
    [[ZentraxNetworkManager sharedManager] verifySessionWithCompletion:^(BOOL isValid, NSDictionary * _Nullable responseData, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isValid && responseData) {
                NSArray *modules = responseData[@"modules"];
                if (modules && [modules isKindOfClass:[NSArray class]]) {
                    [self.uiController updateDashboardWithModules:modules];
                }
                NSDictionary *subscription = responseData[@"subscription"];
                if (subscription && [subscription isKindOfClass:[NSDictionary class]]) {
                    [self.uiController updateSubscriptionState:subscription];
                }
                completion(YES);
            } else {
                // Network Manager auto-purges token on auth invalidation. Pass NO to return to login.
                completion(NO);
            }
        });
    }];
}

// 3. Module Execution & Secure 2-Step File Replacement Bridge
- (void)zentraxDidRequestModuleToggle:(NSString *)moduleId state:(BOOL)isOn completion:(void(^)(BOOL success, NSString * _Nullable errorMsg))completion {
    
    // Step 1: Fetch payload and operation identifier
    [[ZentraxNetworkManager sharedManager] toggleModule:moduleId state:isOn completion:^(BOOL fetchSuccess, NSDictionary * _Nullable modulePayload, NSString * _Nullable fetchErrorMsg) {
        
        if (!fetchSuccess || !modulePayload) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, fetchErrorMsg ?: @"Failed to securely fetch payload from server.");
            });
            return;
        }
        
        // Execute filesystem operations on serial background queue
        dispatch_async(self.moduleExecutionQueue, ^{
            
            NSString *base64Data = modulePayload[@"file_data"];
            NSString *bundleId = modulePayload[@"bundle_id"];
            NSString *relativePath = modulePayload[@"relative_path"];
            NSString *targetFilename = modulePayload[@"target_filename"];
            NSString *operationId = modulePayload[@"operation_id"];
            
            if (!base64Data || !bundleId || !relativePath || !targetFilename || !operationId) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, @"Invalid module contract configuration received from server.");
                });
                return;
            }
            
            // Path traversal and absolute path injection prevention
            if ([relativePath containsString:@"../"] || [relativePath containsString:@"..\\"] || [relativePath hasPrefix:@"/"] ||
                [targetFilename containsString:@"/"] || [targetFilename containsString:@"\\"] || [targetFilename containsString:@".."]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, @"Security Violation: Malformed target path parameters.");
                });
                return;
            }
            
            NSData *fileData = [[NSData alloc] initWithBase64EncodedString:base64Data options:NSDataBase64DecodingIgnoreUnknownCharacters];
            if (!fileData || fileData.length == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, @"Corrupted file payload data or decode failure.");
                });
                return;
            }
            
            NSString *expectedHash = computeSHA256OfData(fileData);
            
            // Resolve Target App Container
            NSString *dataContainer = findDataContainer(bundleId);
            if (!dataContainer) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, [NSString stringWithFormat:@"Target app container (%@) not found or inaccessible.", bundleId]);
                });
                return;
            }
            
            // Construct exact local target resolution
            NSString *directoryPath = [dataContainer stringByAppendingPathComponent:relativePath];
            NSString *finalTargetPath = [directoryPath stringByAppendingPathComponent:targetFilename];
            
            NSFileManager *fm = [NSFileManager defaultManager];
            NSError *fsError = nil;
            
            if (![fm fileExistsAtPath:directoryPath]) {
                [fm createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&fsError];
                if (fsError) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(NO, @"Failed to prepare secure target directory.");
                    });
                    return;
                }
            }
            
            // Perform Atomic Local File Replacement
            BOOL written = [fileData writeToFile:finalTargetPath options:NSDataWritingAtomic error:&fsError];
            
            if (!written) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, fsError.localizedDescription ?: @"Atomic file write execution failed.");
                });
                return;
            }
            
            // Perform Local Verification
            if (![fm fileExistsAtPath:finalTargetPath]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, @"Verification failed: File missing after write.");
                });
                return;
            }
            
            NSData *writtenData = [NSData dataWithContentsOfFile:finalTargetPath];
            if (!writtenData || writtenData.length != fileData.length) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, @"Verification failed: File size mismatch after write.");
                });
                return;
            }
            
            NSString *writtenHash = computeSHA256OfData(writtenData);
            if (![writtenHash isEqualToString:expectedHash]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, @"Verification failed: SHA-256 integrity mismatch on disk.");
                });
                return;
            }
            
            // Step 2: Local write successful, execute Sync State with server operation_id
            [[ZentraxNetworkManager sharedManager] syncModuleState:moduleId state:isOn operationId:operationId completion:^(BOOL syncSuccess, NSString * _Nullable syncErrorMsg) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (syncSuccess) {
                        completion(YES, nil); // Perfect Execution
                    } else {
                        // Server state failed to commit, despite local success.
                        // UI must receive NO so it rolls back toggle visually to avoid desync.
                        completion(NO, syncErrorMsg ?: @"Failed to commit server state sync.");
                    }
                });
            }];
        });
    }];
}

// 4. Logout Bridge
- (void)zentraxDidRequestLogoutWithCompletion:(void(^)(void))completion {
    [[ZentraxNetworkManager sharedManager] logout];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) completion();
    });
}

@end

#pragma mark - ================= UI HIJACK BOOTLOADER =================

static IMP orig_UIWindow_makeKeyAndVisible = NULL;
static void hook_UIWindow_makeKeyAndVisible(UIWindow *self, SEL _cmd) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MCMFilzaStart();
        Class ZentraxUIClass = NSClassFromString(@"ZentraxUI");
        if (ZentraxUIClass) {
            ZentraxUI *zentraxVC = [[ZentraxUIClass alloc] init];
            ZXCoreBridge *bridge = [ZXCoreBridge sharedBridge];
            bridge.uiController = zentraxVC;
            zentraxVC.delegate = bridge;
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:zentraxVC];
            navController.navigationBarHidden = YES;
            self.rootViewController = navController;
        }
    });
    ((void(*)(id, SEL))orig_UIWindow_makeKeyAndVisible)(self, _cmd);
}

#pragma mark - ================= HOOK INSTALLATION =================

static void installSystemHooks(void) {
    Class rfm = NSClassFromString(@"TGRootFileManager");
    if (rfm) {
        Class meta = object_getClass(rfm);
        class_replaceMethod(meta, NSSelectorFromString(@"isRootHelperAvailable"), (IMP)hook_isRootHelperAvailable, "B@:");
        class_replaceMethod(rfm, NSSelectorFromString(@"spawnRootHelper"), (IMP)hook_spawnRootHelper, "i@:");
        class_replaceMethod(rfm, NSSelectorFromString(@"spawnRootHelperIfNeeds"), (IMP)hook_spawnRootHelperIfNeeds, "i@:");
        class_replaceMethod(rfm, NSSelectorFromString(@"respawnRootHelper"), (IMP)hook_respawnRootHelper, "i@:");
        class_replaceMethod(rfm, NSSelectorFromString(@"tryLoadFilzaHelper"), (IMP)hook_tryLoadFilzaHelper, "v@:");
        class_replaceMethod(rfm, NSSelectorFromString(@"createHelperConnectionIfNeeds"), (IMP)hook_createHelperConnectionIfNeeds, "v@:");
        class_replaceMethod(rfm, NSSelectorFromString(@"spawnRoot:args:pid:"), (IMP)hook_spawnRoot_args_pid, "i@:@@^i");
        class_replaceMethod(rfm, NSSelectorFromString(@"sendObjectWithReplySync:"), (IMP)hook_sendObjectWithReplySync, "@@:@");
        class_replaceMethod(rfm, NSSelectorFromString(@"sendObjectWithReplySync:fileDescriptor:"), (IMP)hook_sendObjectWithReplySync_fd, "@@:@^i");
        class_replaceMethod(rfm, NSSelectorFromString(@"sendObjectWithReplySync:fileDescriptor:logintty:"), (IMP)hook_sendObjectWithReplySync_fd_logintty, "@@:@^iB");
        class_replaceMethod(rfm, NSSelectorFromString(@"sendObjectNoReply:"), (IMP)hook_sendObjectNoReply, "v@:@");
        class_replaceMethod(rfm, NSSelectorFromString(@"sendObjectWithReplyAsync:queue:completion:"), (IMP)hook_sendObjectWithReplyAsync, "v@:@@?");
    }

    Class alertCtrl = NSClassFromString(@"TGAlertController");
    if (alertCtrl) {
        Class alertMeta = object_getClass(alertCtrl);
        Method m = class_getClassMethod(alertCtrl, NSSelectorFromString(@"showAlertWithTitle:text:cancelButton:otherButtons:completion:"));
        if (m) {
            orig_showAlert = method_getImplementation(m);
            class_replaceMethod(alertMeta, NSSelectorFromString(@"showAlertWithTitle:text:cancelButton:otherButtons:completion:"),
                (IMP)hook_showAlertWithTitle, "@@:@@@@@");
        }
    }
    
    Class activationVC = NSClassFromString(@"NewActivationViewController");
    if (activationVC) {
        Method m = class_getInstanceMethod(activationVC, @selector(viewDidLoad));
        if (m) {
            orig_activationViewDidLoad = method_getImplementation(m);
            method_setImplementation(m, (IMP)hook_activationViewDidLoad);
        }
    }

    Class lsWorkspace = NSClassFromString(@"LSApplicationWorkspace");
    if (lsWorkspace) {
        Method m = class_getInstanceMethod(lsWorkspace, NSSelectorFromString(@"allApplications"));
        if (m) { orig_allApplications = method_getImplementation(m); method_setImplementation(m, (IMP)hook_allApplications); }
    }
    Class appItem = NSClassFromString(@"ApplicationItem");
    if (appItem) {
        Method m = class_getInstanceMethod(appItem, NSSelectorFromString(@"setAppProxy:"));
        if (m) { orig_setAppProxy = method_getImplementation(m); method_setImplementation(m, (IMP)hook_setAppProxy); }
    }
    
    Class windowClass = NSClassFromString(@"UIWindow");
    if (windowClass) {
        Method m = class_getInstanceMethod(windowClass, @selector(makeKeyAndVisible));
        if (m) {
            orig_UIWindow_makeKeyAndVisible = method_getImplementation(m);
            method_setImplementation(m, (IMP)hook_UIWindow_makeKeyAndVisible);
        }
    }
}

__attribute__((constructor)) void ZentraxInit(void) {
    installSystemHooks();
}
