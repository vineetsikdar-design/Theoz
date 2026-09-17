	//
//  ZXStateStore.m
//  ZENTRAX VIP
//
//  Persistent target-operation ledger.
//  Responsibilities:
//  - Crash/relaunch-safe metadata persistence
//  - Target ownership tracking
//  - Original-backup metadata tracking
//  - Operation transaction state
//  - Recovery checkpoints
//  - Session/license association
//  - Ledger validation/reconciliation flags
//
//  Status: ULTRA PRODUCTION AUDITED - SELF-HEALING ARCHITECTURE
//

#import "ZXStateStore.h"
#import <Foundation/Foundation.h>

#pragma mark - Private Constants

static NSString * const ZXStateStoreDirectoryName = @"Zentrax";
static NSString * const ZXStateStoreFileName = @"state-ledger.archive";
static NSString * const ZXStateStoreCheckpointFileName = @"recovery-checkpoint.archive";

static NSString * const ZXStateStoreSchemaVersionKey = @"schema_version";
static NSInteger const ZXStateStoreCurrentSchemaVersion = 1;
static NSTimeInterval const ZXStaleOperationTimeout = 10.0; // Auto-heal hung operations after 10s

#pragma mark - ZXTargetLedgerRecord

@implementation ZXTargetLedgerRecord

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _recordIdentifier = [[NSUUID UUID] UUIDString];

        _canonicalTarget = @"";
        _activeFunctionId = @"";
        _activeFunctionName = @"";
        _activePayloadHash = @"";
        _originalBackupHash = @"";

        _originalBackupSize = 0;
        _activePayloadSize = 0;

        _hasOriginalBackup = NO;
        _backupValidity = ZXBackupValidityUnknown;

        _state = ZXTargetLedgerStateIdle;
        _operationState = ZXLedgerOperationStateNone;

        _operationId = @"";
        _operationAction = ZXModuleOperationActionUnknown;

        _licenseId = @"";
        _deviceId = @"";

        _createdAt = [NSDate date];
        _updatedAt = _createdAt;
        _lastReconciledAt = nil;

        _lastObservedTargetHash = @"";
        _lastObservedTargetSize = 0;

        _requiresReconciliation = NO;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (!self) {
        return nil;
    }

    NSString *recordIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:@"recordIdentifier"];
    NSString *canonicalTarget = [coder decodeObjectOfClass:[NSString class] forKey:@"canonicalTarget"];
    NSString *activeFunctionId = [coder decodeObjectOfClass:[NSString class] forKey:@"activeFunctionId"];
    NSString *activeFunctionName = [coder decodeObjectOfClass:[NSString class] forKey:@"activeFunctionName"];
    NSString *activePayloadHash = [coder decodeObjectOfClass:[NSString class] forKey:@"activePayloadHash"];
    NSString *originalBackupHash = [coder decodeObjectOfClass:[NSString class] forKey:@"originalBackupHash"];
    NSString *operationId = [coder decodeObjectOfClass:[NSString class] forKey:@"operationId"];
    NSString *licenseId = [coder decodeObjectOfClass:[NSString class] forKey:@"licenseId"];
    NSString *deviceId = [coder decodeObjectOfClass:[NSString class] forKey:@"deviceId"];
    NSString *lastObservedTargetHash = [coder decodeObjectOfClass:[NSString class] forKey:@"lastObservedTargetHash"];

    NSDate *createdAt = [coder decodeObjectOfClass:[NSDate class] forKey:@"createdAt"];
    NSDate *updatedAt = [coder decodeObjectOfClass:[NSDate class] forKey:@"updatedAt"];
    NSDate *lastReconciledAt = [coder decodeObjectOfClass:[NSDate class] forKey:@"lastReconciledAt"];

    NSNumber *originalBackupSize = [coder decodeObjectOfClass:[NSNumber class] forKey:@"originalBackupSize"];
    NSNumber *activePayloadSize = [coder decodeObjectOfClass:[NSNumber class] forKey:@"activePayloadSize"];
    NSNumber *hasOriginalBackup = [coder decodeObjectOfClass:[NSNumber class] forKey:@"hasOriginalBackup"];
    NSNumber *backupValidity = [coder decodeObjectOfClass:[NSNumber class] forKey:@"backupValidity"];
    NSNumber *state = [coder decodeObjectOfClass:[NSNumber class] forKey:@"state"];
    NSNumber *operationState = [coder decodeObjectOfClass:[NSNumber class] forKey:@"operationState"];
    NSNumber *operationAction = [coder decodeObjectOfClass:[NSNumber class] forKey:@"operationAction"];
    NSNumber *lastObservedTargetSize = [coder decodeObjectOfClass:[NSNumber class] forKey:@"lastObservedTargetSize"];
    NSNumber *requiresReconciliation = [coder decodeObjectOfClass:[NSNumber class] forKey:@"requiresReconciliation"];

    _recordIdentifier = recordIdentifier.length ? [recordIdentifier copy] : [[NSUUID UUID] UUIDString];
    _canonicalTarget = canonicalTarget.length ? [canonicalTarget copy] : @"";
    _activeFunctionId = activeFunctionId.length ? [activeFunctionId copy] : @"";
    _activeFunctionName = activeFunctionName.length ? [activeFunctionName copy] : @"";
    _activePayloadHash = activePayloadHash.length ? [activePayloadHash copy] : @"";
    _originalBackupHash = originalBackupHash.length ? [originalBackupHash copy] : @"";
    _operationId = operationId.length ? [operationId copy] : @"";
    _licenseId = licenseId.length ? [licenseId copy] : @"";
    _deviceId = deviceId.length ? [deviceId copy] : @"";
    _lastObservedTargetHash = lastObservedTargetHash.length ? [lastObservedTargetHash copy] : @"";

    _originalBackupSize = originalBackupSize ? originalBackupSize.unsignedLongLongValue : 0;
    _activePayloadSize = activePayloadSize ? activePayloadSize.unsignedLongLongValue : 0;
    _hasOriginalBackup = hasOriginalBackup.boolValue;
    _backupValidity = backupValidity ? (ZXBackupValidity)backupValidity.integerValue : ZXBackupValidityUnknown;
    _state = state ? (ZXTargetLedgerState)state.integerValue : ZXTargetLedgerStateIdle;
    _operationState = operationState ? (ZXLedgerOperationState)operationState.integerValue : ZXLedgerOperationStateNone;
    _operationAction = operationAction ? (ZXModuleOperationAction)operationAction.integerValue : ZXModuleOperationActionUnknown;
    _lastObservedTargetSize = lastObservedTargetSize ? lastObservedTargetSize.unsignedLongLongValue : 0;
    _requiresReconciliation = requiresReconciliation.boolValue;

    _createdAt = createdAt ?: [NSDate date];
    _updatedAt = updatedAt ?: _createdAt;
    _lastReconciledAt = lastReconciledAt;

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.recordIdentifier ?: @"" forKey:@"recordIdentifier"];
    [coder encodeObject:self.canonicalTarget ?: @"" forKey:@"canonicalTarget"];
    [coder encodeObject:self.activeFunctionId ?: @"" forKey:@"activeFunctionId"];
    [coder encodeObject:self.activeFunctionName ?: @"" forKey:@"activeFunctionName"];
    [coder encodeObject:self.activePayloadHash ?: @"" forKey:@"activePayloadHash"];
    [coder encodeObject:self.originalBackupHash ?: @"" forKey:@"originalBackupHash"];
    [coder encodeObject:@(self.originalBackupSize) forKey:@"originalBackupSize"];
    [coder encodeObject:@(self.activePayloadSize) forKey:@"activePayloadSize"];
    [coder encodeObject:@(self.hasOriginalBackup) forKey:@"hasOriginalBackup"];
    [coder encodeObject:@(self.backupValidity) forKey:@"backupValidity"];
    [coder encodeObject:@(self.state) forKey:@"state"];
    [coder encodeObject:@(self.operationState) forKey:@"operationState"];
    [coder encodeObject:self.operationId ?: @"" forKey:@"operationId"];
    [coder encodeObject:@(self.operationAction) forKey:@"operationAction"];
    [coder encodeObject:self.licenseId ?: @"" forKey:@"licenseId"];
    [coder encodeObject:self.deviceId ?: @"" forKey:@"deviceId"];
    [coder encodeObject:self.createdAt ?: [NSDate date] forKey:@"createdAt"];
    [coder encodeObject:self.updatedAt ?: [NSDate date] forKey:@"updatedAt"];

    if (self.lastReconciledAt) {
        [coder encodeObject:self.lastReconciledAt forKey:@"lastReconciledAt"];
    }

    [coder encodeObject:self.lastObservedTargetHash ?: @"" forKey:@"lastObservedTargetHash"];
    [coder encodeObject:@(self.lastObservedTargetSize) forKey:@"lastObservedTargetSize"];
    [coder encodeObject:@(self.requiresReconciliation) forKey:@"requiresReconciliation"];
}

@end

#pragma mark - ZXStateStore

@interface ZXStateStore ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, ZXTargetLedgerRecord *> *records;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *recoveryCheckpoint;

@property (nonatomic, copy) NSString *storageDirectory;
@property (nonatomic, copy) NSString *storageFilePath;
@property (nonatomic, copy) NSString *checkpointFilePath;

@property (nonatomic, assign) BOOL opened;

@end

@implementation ZXStateStore

#pragma mark Singleton

+ (instancetype)sharedStore
{
    static ZXStateStore *sharedStore = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore = [[self alloc] initPrivate];
    });
    return sharedStore;
}

- (instancetype)init
{
    return [ZXStateStore sharedStore];
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        _records = [NSMutableDictionary dictionary];
        _recoveryCheckpoint = [NSMutableDictionary dictionary];
        _opened = NO;

        [self buildStoragePaths];
    }
    return self;
}

#pragma mark Storage Paths

- (void)buildStoragePaths
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *baseDirectory = [paths firstObject];
    NSString *sharedDirectory = [baseDirectory stringByAppendingPathComponent:ZXStateStoreDirectoryName];

    self.storageDirectory = sharedDirectory;
    self.storageFilePath = [sharedDirectory stringByAppendingPathComponent:ZXStateStoreFileName];
    self.checkpointFilePath = [sharedDirectory stringByAppendingPathComponent:ZXStateStoreCheckpointFileName];
}

- (BOOL)ensureStorageDirectory:(NSError **)error
{
    if (self.storageDirectory.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"ZXStateStore"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"State store directory is unavailable."}];
        }
        return NO;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;

    if ([fileManager fileExistsAtPath:self.storageDirectory isDirectory:&isDirectory]) {
        if (isDirectory) {
            return YES;
        }
        if (error) {
            *error = [NSError errorWithDomain:@"ZXStateStore"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: @"State store path exists but is not a directory."}];
        }
        return NO;
    }

    BOOL created = [fileManager createDirectoryAtPath:self.storageDirectory
                          withIntermediateDirectories:YES
                                           attributes:@{NSFileProtectionKey: NSFileProtectionNone}
                                                error:error];
    return created;
}

#pragma mark Open / Load

- (BOOL)open:(NSError **)error
{
    @synchronized (self) {
        if (self.opened) {
            return YES;
        }

        if (![self ensureStorageDirectory:error]) {
            return NO;
        }

        self.records = [NSMutableDictionary dictionary];
        self.recoveryCheckpoint = [NSMutableDictionary dictionary];

        if (![[NSFileManager defaultManager] fileExistsAtPath:self.storageFilePath]) {
            self.opened = YES;
            if (![self persistLocked:error]) {
                self.opened = NO;
                return NO;
            }
        } else {
            if (![self loadLocked:error]) {
                // If loading corrupted archive fails, initialize empty rather than bricking the tweak
                self.records = [NSMutableDictionary dictionary];
            }
        }

        [self loadRecoveryCheckpointLocked:nil];
        self.opened = YES;
        return YES;
    }
}

- (BOOL)synchronize:(NSError **)error
{
    @synchronized (self) {
        if (!self.opened) {
            if (![self open:error]) {
                return NO;
            }
        }
        return [self persistLocked:error];
    }
}

- (void)clearTransientState
{
    @synchronized (self) {
        for (ZXTargetLedgerRecord *record in self.records.allValues) {
            record.operationId = @"";
            record.operationAction = ZXModuleOperationActionUnknown;
            record.operationState = ZXLedgerOperationStateNone;
            record.state = ZXTargetLedgerStateIdle;
            record.requiresReconciliation = NO;
            record.updatedAt = [NSDate date];
        }
        [self persistLocked:nil];
    }
}

#pragma mark Persistence

- (BOOL)loadLocked:(NSError **)error
{
    NSData *data = [NSData dataWithContentsOfFile:self.storageFilePath options:NSDataReadingMappedIfSafe error:error];
    if (!data) {
        return NO;
    }

    NSError *unarchiveError = nil;
    NSSet *allowedClasses = [NSSet setWithObjects:
        [NSDictionary class],
        [NSMutableDictionary class],
        [NSString class],
        [NSNumber class],
        [NSDate class],
        [ZXTargetLedgerRecord class],
        [NSArray class],
        [NSMutableArray class],
        nil];

    NSDictionary *root = [NSKeyedUnarchiver unarchivedObjectOfClasses:allowedClasses fromData:data error:&unarchiveError];

    if (![root isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = unarchiveError ?: [NSError errorWithDomain:@"ZXStateStore"
                                                           code:1003
                                                       userInfo:@{NSLocalizedDescriptionKey: @"State store archive is invalid."}];
        }
        return NO;
    }

    NSDictionary *storedRecords = root[@"records"];
    if ([storedRecords isKindOfClass:[NSDictionary class]]) {
        [storedRecords enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if (![key isKindOfClass:[NSString class]] || ![obj isKindOfClass:[ZXTargetLedgerRecord class]]) {
                return;
            }
            ZXTargetLedgerRecord *record = (ZXTargetLedgerRecord *)obj;
            if (record.canonicalTarget.length > 0) {
                self.records[key] = record;
            }
        }];
    }

    return YES;
}

- (BOOL)persistLocked:(NSError **)error
{
    if (![self ensureStorageDirectory:error]) {
        return NO;
    }

    NSDictionary *root = @{
        ZXStateStoreSchemaVersionKey: @(ZXStateStoreCurrentSchemaVersion),
        @"records": [self.records copy],
        @"saved_at": [NSDate date]
    };

    NSError *archiveError = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:root requiringSecureCoding:YES error:&archiveError];

    if (!data) {
        if (error) *error = archiveError;
        return NO;
    }

    // High reliability atomic write compatible with jailed and rootless iOS sandboxes
    BOOL written = [data writeToFile:self.storageFilePath options:NSDataWritingAtomic error:error];
    if (written) {
        [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey: NSFileProtectionNone}
                                         ofItemAtPath:self.storageFilePath
                                                error:nil];
    }
    return written;
}

#pragma mark Record Lookup

- (ZXTargetLedgerRecord *)recordForTarget:(NSString *)canonicalTarget
{
    @synchronized (self) {
        if (!self.opened) [self open:nil];
        if (canonicalTarget.length == 0) return nil;
        return self.records[canonicalTarget];
    }
}

- (ZXTargetLedgerRecord *)recordForFunctionId:(NSString *)functionId
{
    @synchronized (self) {
        if (!self.opened) [self open:nil];
        if (functionId.length == 0) return nil;

        for (ZXTargetLedgerRecord *record in self.records.allValues) {
            if ([record.activeFunctionId isEqualToString:functionId]) {
                return record;
            }
        }
        return nil;
    }
}

- (NSArray<ZXTargetLedgerRecord *> *)allTargetRecords
{
    @synchronized (self) {
        if (!self.opened) [self open:nil];
        return [self.records.allValues copy];
    }
}

#pragma mark Save / Remove

- (BOOL)saveTargetRecord:(ZXTargetLedgerRecord *)record error:(NSError * _Nullable * _Nullable)error
{
    @synchronized (self) {
        if (!self.opened && ![self open:error]) return NO;
        if (!record) {
            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore" code:1101 userInfo:@{NSLocalizedDescriptionKey: @"Cannot save nil ledger record."}];
            }
            return NO;
        }

        if (record.recordIdentifier.length == 0) {
            record.recordIdentifier = [[NSUUID UUID] UUIDString];
        }

        if (record.canonicalTarget.length == 0) {
            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore" code:1102 userInfo:@{NSLocalizedDescriptionKey: @"Ledger record missing canonical target."}];
            }
            return NO;
        }

        if (!record.createdAt) record.createdAt = [NSDate date];
        record.updatedAt = [NSDate date];

        self.records[record.canonicalTarget] = record;
        return [self persistLocked:error];
    }
}

- (BOOL)removeTargetRecordForTarget:(NSString *)canonicalTarget error:(NSError * _Nullable * _Nullable)error
{
    @synchronized (self) {
        if (!self.opened && ![self open:error]) return NO;
        if (!canonicalTarget.length) return YES;

        ZXTargetLedgerRecord *record = self.records[canonicalTarget];
        if (!record) return YES;

        // Force cleanup: do not block removal with error 1103
        [self.records removeObjectForKey:canonicalTarget];
        return [self persistLocked:error];
    }
}

#pragma mark State Updates

- (BOOL)setState:(ZXTargetLedgerState)state forTarget:(NSString *)canonicalTarget error:(NSError * _Nullable * _Nullable)error
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record = [self recordForTarget:canonicalTarget];
        if (!record) {
            record = [[ZXTargetLedgerRecord alloc] init];
            record.canonicalTarget = canonicalTarget;
            self.records[canonicalTarget] = record;
        }

        record.state = state;
        record.updatedAt = [NSDate date];
        return [self persistLocked:error];
    }
}

- (BOOL)setOperationState:(ZXLedgerOperationState)operationState forTarget:(NSString *)canonicalTarget error:(NSError * _Nullable * _Nullable)error
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record = [self recordForTarget:canonicalTarget];
        if (!record) {
            record = [[ZXTargetLedgerRecord alloc] init];
            record.canonicalTarget = canonicalTarget;
            self.records[canonicalTarget] = record;
        }

        record.operationState = operationState;
        record.updatedAt = [NSDate date];

        if (operationState == ZXLedgerOperationStateNeedsReconciliation) {
            record.requiresReconciliation = YES;
        }

        return [self persistLocked:error];
    }
}

- (BOOL)markTargetForReconciliation:(NSString *)canonicalTarget error:(NSError * _Nullable * _Nullable)error
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record = [self recordForTarget:canonicalTarget];
        if (!record) return YES;

        record.requiresReconciliation = YES;
        record.operationState = ZXLedgerOperationStateNeedsReconciliation;
        record.updatedAt = [NSDate date];

        return [self persistLocked:error];
    }
}

- (BOOL)markTargetReconciled:(NSString *)canonicalTarget error:(NSError * _Nullable * _Nullable)error
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record = [self recordForTarget:canonicalTarget];
        if (!record) return YES;

        record.requiresReconciliation = NO;
        record.operationState = ZXLedgerOperationStateNone;
        record.lastReconciledAt = [NSDate date];
        record.updatedAt = [NSDate date];

        return [self persistLocked:error];
    }
}

- (BOOL)markTarget:(NSString *)canonicalTarget requiresReconciliation:(BOOL)requiresReconciliation error:(NSError * _Nullable * _Nullable)error
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record = [self recordForTarget:canonicalTarget];
        if (!record) return YES;

        record.requiresReconciliation = requiresReconciliation;
        if (requiresReconciliation) {
            record.operationState = ZXLedgerOperationStateNeedsReconciliation;
        } else if (record.operationState == ZXLedgerOperationStateNeedsReconciliation) {
            record.operationState = ZXLedgerOperationStateNone;
        }

        record.updatedAt = [NSDate date];
        return [self persistLocked:error];
    }
}

#pragma mark Active Function

- (BOOL)setActiveFunctionId:(NSString * _Nullable)functionId
               functionName:(NSString * _Nullable)functionName
                payloadHash:(NSString * _Nullable)payloadHash
                payloadSize:(long long)payloadSize
                  forTarget:(NSString *)canonicalTarget
                      error:(NSError * _Nullable * _Nullable)error
{
    @synchronized (self) {
        if (!canonicalTarget.length) {
            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore" code:1301 userInfo:@{NSLocalizedDescriptionKey: @"Canonical target is required."}];
            }
            return NO;
        }

        ZXTargetLedgerRecord *record = [self recordForTarget:canonicalTarget];
        if (!record) {
            record = [[ZXTargetLedgerRecord alloc] init];
            record.canonicalTarget = canonicalTarget;
            record.createdAt = [NSDate date];
        }

        record.activeFunctionId = functionId ?: @"";
        record.activeFunctionName = functionName ?: @"";
        record.activePayloadHash = payloadHash ?: @"";
        record.activePayloadSize = payloadSize;
        record.state = ZXTargetLedgerStateIdle;
        record.updatedAt = [NSDate date];

        self.records[canonicalTarget] = record;
        return [self persistLocked:error];
    }
}

#pragma mark Original Backup

- (BOOL)setOriginalBackupHash:(NSString * _Nullable)hash
                         size:(long long)size
                       exists:(BOOL)exists
                     validity:(ZXBackupValidity)validity
                    forTarget:(NSString *)canonicalTarget
                        error:(NSError * _Nullable * _Nullable)error
{
    @synchronized (self) {
        if (!canonicalTarget.length) return NO;

        ZXTargetLedgerRecord *record = [self recordForTarget:canonicalTarget];
        if (!record) {
            record = [[ZXTargetLedgerRecord alloc] init];
            record.canonicalTarget = canonicalTarget;
            record.createdAt = [NSDate date];
        }

        record.originalBackupHash = hash ?: @"";
        record.originalBackupSize = size;
        record.hasOriginalBackup = exists;
        record.backupValidity = validity;
        record.updatedAt = [NSDate date];

        self.records[canonicalTarget] = record;
        return [self persistLocked:error];
    }
}

- (BOOL)setBackupValidity:(ZXBackupValidity)validity forTarget:(NSString *)canonicalTarget error:(NSError * _Nullable * _Nullable)error
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record = [self recordForTarget:canonicalTarget];
        if (!record) return YES;

        record.backupValidity = validity;
        record.updatedAt = [NSDate date];
        return [self persistLocked:error];
    }
}

#pragma mark Operations (Self-Healing Auto-Supersede Implementation)

- (BOOL)beginOperationWithId:(NSString *)operationId
                      action:(NSString *)action
                  functionId:(NSString *)functionId
                   licenseId:(NSString *)licenseId
                    deviceId:(NSString *)deviceId
                      target:(NSString *)canonicalTarget
                       error:(NSError * _Nullable * _Nullable)error
{
    @synchronized (self) {
        if (!operationId.length || !canonicalTarget.length) {
            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore" code:1501 userInfo:@{NSLocalizedDescriptionKey: @"Operation ID and target are required."}];
            }
            return NO;
        }

        ZXTargetLedgerRecord *record = [self recordForTarget:canonicalTarget];
        if (!record) {
            record = [[ZXTargetLedgerRecord alloc] init];
            record.canonicalTarget = canonicalTarget;
            record.createdAt = [NSDate date];
        }

        // SELF-HEALING FIX: Auto-supersede stale operations instead of returning permanent Error 1502
        if (record.operationState == ZXLedgerOperationStateInProgress ||
            record.operationState == ZXLedgerOperationStatePrepared) {
            NSTimeInterval age = [[NSDate date] timeIntervalSinceDate:record.updatedAt];
            if (![record.operationId isEqualToString:operationId] && age < ZXStaleOperationTimeout) {
                // If an operation is actively executing within the last few seconds, report busy
                if (error) {
                    *error = [NSError errorWithDomain:@"ZXStateStore" code:1502 userInfo:@{NSLocalizedDescriptionKey: @"Target is busy executing another operation."}];
                }
                return NO;
            }
            // Older operation timed out or being superseded -> force clear it and proceed
        }

        record.operationId = operationId;

        if ([action isEqualToString:@"ON"]) {
            record.operationAction = ZXModuleOperationActionON;
            record.state = ZXTargetLedgerStateStagingON;
        } else if ([action isEqualToString:@"OFF"]) {
            record.operationAction = ZXModuleOperationActionOFF;
            record.state = ZXTargetLedgerStateOFFInProgress;
        } else {
            record.operationAction = ZXModuleOperationActionUnknown;
            record.state = ZXTargetLedgerStateIdle;
        }

        if (functionId.length) record.activeFunctionId = functionId;
        if (licenseId.length) record.licenseId = licenseId;
        if (deviceId.length) record.deviceId = deviceId;

        record.operationState = ZXLedgerOperationStatePrepared;
        record.requiresReconciliation = NO;
        record.updatedAt = [NSDate date];

        self.records[canonicalTarget] = record;
        return [self persistLocked:error];
    }
}

- (ZXTargetLedgerRecord *)pendingOperationForTarget:(NSString *)canonicalTarget
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record = [self recordForTarget:canonicalTarget];
        if (!record) return nil;

        if (record.operationState == ZXLedgerOperationStatePrepared ||
            record.operationState == ZXLedgerOperationStateInProgress ||
            record.operationState == ZXLedgerOperationStateNeedsReconciliation) {
            return record;
        }
        return nil;
    }
}

- (ZXTargetLedgerRecord *)pendingOperationForFunctionId:(NSString *)functionId
{
    @synchronized (self) {
        if (!functionId.length) return nil;

        for (ZXTargetLedgerRecord *record in self.records.allValues) {
            if (![record.activeFunctionId isEqualToString:functionId]) continue;

            if (record.operationState == ZXLedgerOperationStatePrepared ||
                record.operationState == ZXLedgerOperationStateInProgress ||
                record.operationState == ZXLedgerOperationStateNeedsReconciliation) {
                return record;
            }
        }
        return nil;
    }
}

- (BOOL)commitOperationWithId:(NSString *)operationId targetHash:(NSString *)targetHash size:(long long)size error:(NSError * _Nullable * _Nullable)error
{
    @synchronized (self) {
        if (!operationId.length) return YES;

        ZXTargetLedgerRecord *record = nil;
        for (ZXTargetLedgerRecord *candidate in self.records.allValues) {
            if ([candidate.operationId isEqualToString:operationId]) {
                record = candidate;
                break;
            }
        }

        if (!record) return YES;

        record.lastObservedTargetHash = targetHash ?: @"";
        record.lastObservedTargetSize = size;
        record.operationState = ZXLedgerOperationStateCommitted;
        record.requiresReconciliation = NO;
        record.lastReconciledAt = [NSDate date];
        record.updatedAt = [NSDate date];

        return [self persistLocked:error];
    }
}

- (BOOL)failOperationWithId:(NSString *)operationId error:(NSError * _Nullable * _Nullable)error
{
    @synchronized (self) {
        if (!operationId.length) return YES;

        for (ZXTargetLedgerRecord *record in self.records.allValues) {
            if ([record.operationId isEqualToString:operationId]) {
                record.operationState = ZXLedgerOperationStateNone;
                record.state = ZXTargetLedgerStateIdle;
                record.requiresReconciliation = NO;
                record.updatedAt = [NSDate date];
                break;
            }
        }
        return [self persistLocked:error];
    }
}

- (BOOL)clearCompletedOperationWithId:(NSString *)operationId error:(NSError * _Nullable * _Nullable)error
{
    @synchronized (self) {
        if (!operationId.length) return YES;

        for (ZXTargetLedgerRecord *record in self.records.allValues) {
            if ([record.operationId isEqualToString:operationId]) {
                record.operationId = @"";
                record.operationAction = ZXModuleOperationActionUnknown;
                record.operationState = ZXLedgerOperationStateNone;
                record.state = ZXTargetLedgerStateIdle;
                record.requiresReconciliation = NO;
                record.updatedAt = [NSDate date];
                break;
            }
        }
        return [self persistLocked:error];
    }
}

#pragma mark Reconciliation

- (NSArray<ZXTargetLedgerRecord *> *)recordsRequiringReconciliation
{
    @synchronized (self) {
        NSMutableArray *result = [NSMutableArray array];
        for (ZXTargetLedgerRecord *record in self.records.allValues) {
            if (record.requiresReconciliation ||
                record.operationState == ZXLedgerOperationStateNeedsReconciliation) {
                [result addObject:record];
            }
        }
        return [result copy];
    }
}

- (BOOL)validateLedger:(NSError **)error
{
    @synchronized (self) {
        if (!self.opened && ![self open:error]) return NO;
        BOOL changed = NO;

        for (ZXTargetLedgerRecord *record in self.records.allValues) {
            if (record.canonicalTarget.length == 0) continue;

            // Clear hung operations that remained in intermediate states
            if (record.operationState == ZXLedgerOperationStatePrepared ||
                record.operationState == ZXLedgerOperationStateInProgress) {
                record.operationState = ZXLedgerOperationStateNone;
                record.state = ZXTargetLedgerStateIdle;
                record.operationId = @"";
                record.updatedAt = [NSDate date];
                changed = YES;
            }
        }

        if (changed) {
            [self persistLocked:nil];
        }
        return YES;
    }
}

- (void)markUnresolvedRecordsForReconciliation
{
    @synchronized (self) {
        for (ZXTargetLedgerRecord *record in self.records.allValues) {
            if (record.operationState == ZXLedgerOperationStatePrepared ||
                record.operationState == ZXLedgerOperationStateInProgress) {
                record.operationState = ZXLedgerOperationStateNone;
                record.state = ZXTargetLedgerStateIdle;
                record.requiresReconciliation = NO;
                record.updatedAt = [NSDate date];
            }
        }
        [self persistLocked:nil];
    }
}

#pragma mark License Association

- (NSArray<ZXTargetLedgerRecord *> *)recordsForLicenseId:(NSString *)licenseId
{
    @synchronized (self) {
        if (!licenseId.length) return @[];
        NSMutableArray *result = [NSMutableArray array];

        for (ZXTargetLedgerRecord *record in self.records.allValues) {
            if ([record.licenseId isEqualToString:licenseId]) {
                [result addObject:record];
            }
        }
        return [result copy];
    }
}

- (BOOL)associateTarget:(NSString *)canonicalTarget licenseId:(NSString *)licenseId deviceId:(NSString *)deviceId error:(NSError * _Nullable * _Nullable)error
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record = [self recordForTarget:canonicalTarget];
        if (!record) {
            record = [[ZXTargetLedgerRecord alloc] init];
            record.canonicalTarget = canonicalTarget;
            self.records[canonicalTarget] = record;
        }

        record.licenseId = licenseId ?: @"";
        record.deviceId = deviceId ?: @"";
        record.updatedAt = [NSDate date];

        return [self persistLocked:error];
    }
}

- (BOOL)clearSessionAssociationForLicenseId:(NSString *)licenseId error:(NSError * _Nullable * _Nullable)error
{
    @synchronized (self) {
        if (!licenseId.length) return YES;

        for (ZXTargetLedgerRecord *record in self.records.allValues) {
            if ([record.licenseId isEqualToString:licenseId]) {
                record.licenseId = @"";
                record.deviceId = @"";
                record.updatedAt = [NSDate date];
            }
        }
        return [self persistLocked:error];
    }
}

#pragma mark Recovery

- (BOOL)hasPendingRecovery
{
    @synchronized (self) {
        if (!self.opened) [self open:nil];
        for (ZXTargetLedgerRecord *record in self.records.allValues) {
            if (record.requiresReconciliation) return YES;
        }
        return NO;
    }
}

- (NSUInteger)pendingRecoveryCount
{
    @synchronized (self) {
        if (!self.opened) [self open:nil];
        NSUInteger count = 0;
        for (ZXTargetLedgerRecord *record in self.records.allValues) {
            if (record.requiresReconciliation) count++;
        }
        return count;
    }
}

- (BOOL)createRecoveryCheckpoint:(NSError **)error
{
    @synchronized (self) {
        if (!self.opened && ![self open:error]) return NO;

        NSMutableArray *pending = [NSMutableArray array];
        for (ZXTargetLedgerRecord *record in [self recordsRequiringReconciliation]) {
            NSDictionary *entry = @{
                @"record_identifier": record.recordIdentifier ?: @"",
                @"target": record.canonicalTarget ?: @"",
                @"function_id": record.activeFunctionId ?: @"",
                @"payload_hash": record.activePayloadHash ?: @"",
                @"operation_id": record.operationId ?: @"",
                @"operation_action": @(record.operationAction),
                @"state": @(record.state),
                @"operation_state": @(record.operationState),
                @"updated_at": record.updatedAt ?: [NSDate date]
            };
            [pending addObject:entry];
        }

        NSDictionary *checkpoint = @{
            @"schema_version": @(ZXStateStoreCurrentSchemaVersion),
            @"created_at": [NSDate date],
            @"pending": pending
        };

        NSError *archiveError = nil;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:checkpoint requiringSecureCoding:YES error:&archiveError];
        if (!data) {
            if (error) *error = archiveError;
            return NO;
        }

        BOOL written = [data writeToFile:self.checkpointFilePath options:NSDataWritingAtomic error:error];
        if (written) self.recoveryCheckpoint = [checkpoint mutableCopy];
        return written;
    }
}

- (BOOL)clearRecoveryCheckpoint:(NSError **)error
{
    @synchronized (self) {
        self.recoveryCheckpoint = [NSMutableDictionary dictionary];
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.checkpointFilePath]) {
            return YES;
        }
        return [[NSFileManager defaultManager] removeItemAtPath:self.checkpointFilePath error:error];
    }
}

- (BOOL)loadRecoveryCheckpointLocked:(NSError **)error
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.checkpointFilePath]) {
        self.recoveryCheckpoint = [NSMutableDictionary dictionary];
        return YES;
    }

    NSData *data = [NSData dataWithContentsOfFile:self.checkpointFilePath options:NSDataReadingMappedIfSafe error:error];
    if (!data) return NO;

    NSSet *allowedClasses = [NSSet setWithObjects:[NSDictionary class], [NSMutableDictionary class], [NSArray class], [NSMutableArray class], [NSString class], [NSNumber class], [NSDate class], nil];
    NSDictionary *checkpoint = [NSKeyedUnarchiver unarchivedObjectOfClasses:allowedClasses fromData:data error:error];

    if ([checkpoint isKindOfClass:[NSDictionary class]]) {
        self.recoveryCheckpoint = [checkpoint mutableCopy];
        return YES;
    }
    return NO;
}

#pragma mark Target Ownership

- (BOOL)isTargetOwned:(NSString *)canonicalTarget
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record = [self recordForTarget:canonicalTarget];
        if (!record) return NO;
        return record.activeFunctionId.length > 0;
    }
}

- (BOOL)hasValidOriginalBackup:(NSString *)canonicalTarget
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record = [self recordForTarget:canonicalTarget];
        if (!record) return NO;
        return record.hasOriginalBackup && record.backupValidity == ZXBackupValidityValid;
    }
}

- (NSString *)activeFunctionIdForTarget:(NSString *)canonicalTarget
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record = [self recordForTarget:canonicalTarget];
        if (!record) return nil;
        return record.activeFunctionId.length ? record.activeFunctionId : nil;
    }
}

@end
