//
//  ZentraxNetworkManager.m
//  Zentrax VIP - Premium Execution Node
//
//  Created by Zentrax Team.
//

#import "ZentraxNetworkManager.h"
#import <CommonCrypto/CommonCryptor.h>
#import <UIKit/UIKit.h>

// ==========================================
// 🔐 SERVER CONFIGURATIONS
// ==========================================
#define BASE_URL @"https://zentrax.in/api/"
#define SECRET_KEY @"ZENTRAX_32_CHAR_SECRET_KEY_12345" // Must be exactly 32 chars for AES-256
#define SECRET_IV  @"ZENTRAX_16_IV_89"                 // Must be exactly 16 chars

@interface ZentraxNetworkManager () <NSURLSessionDelegate>
@property (nonatomic, strong) NSURLSession *secureSession;
@end

@implementation ZentraxNetworkManager

+ (instancetype)sharedManager {
    static ZentraxNetworkManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialize NSURLSession with Ephemeral config (no caching) and self as delegate for SSL Pinning
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        config.timeoutIntervalForRequest = 15.0; // 15 seconds timeout
        self.secureSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return self;
}

#pragma mark - ================= DEVICE FINGERPRINTING =================

- (NSString *)getHardwareID {
    // Generate or retrieve a persistent UUID for device binding
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *hwid = [defaults stringForKey:@"Zentrax_HWID"];
    if (!hwid) {
        hwid = [[UIDevice currentDevice] identifierForVendor].UUIDString;
        [defaults setObject:hwid forKey:@"Zentrax_HWID"];
        [defaults synchronize];
    }
    return hwid;
}

#pragma mark - ================= AES-256 ENCRYPTION / DECRYPTION =================

- (NSString *)encryptString:(NSString *)plainText {
    NSData *data = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    NSData *keyData = [SECRET_KEY dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = [SECRET_IV dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t outLength;
    NSMutableData *cipherData = [NSMutableData dataWithLength:data.length + kCCBlockSizeAES128];
    
    CCCryptorStatus result = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionPKCS7Padding,
                                     keyData.bytes, keyData.length,
                                     ivData.bytes,
                                     data.bytes, data.length,
                                     cipherData.mutableBytes, cipherData.length,
                                     &outLength);
    
    if (result == kCCSuccess) {
        cipherData.length = outLength;
        return [cipherData base64EncodedStringWithOptions:0];
    }
    return nil;
}

- (NSString *)decryptString:(NSString *)base64CipherText {
    NSData *cipherData = [[NSData alloc] initWithBase64EncodedString:base64CipherText options:0];
    NSData *keyData = [SECRET_KEY dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = [SECRET_IV dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t outLength;
    NSMutableData *plainData = [NSMutableData dataWithLength:cipherData.length + kCCBlockSizeAES128];
    
    CCCryptorStatus result = CCCrypt(kCCDecrypt, kCCAlgorithmAES, kCCOptionPKCS7Padding,
                                     keyData.bytes, keyData.length,
                                     ivData.bytes,
                                     cipherData.bytes, cipherData.length,
                                     plainData.mutableBytes, plainData.length,
                                     &outLength);
    
    if (result == kCCSuccess) {
        plainData.length = outLength;
        return [[NSString alloc] initWithData:plainData encoding:NSUTF8StringEncoding];
    }
    return nil;
}

#pragma mark - ================= SECURE API EXECUTOR =================

- (void)sendSecureRequestToEndpoint:(NSString *)endpoint payload:(NSDictionary *)payloadDict completion:(void(^)(BOOL success, NSDictionary * _Nullable responseData, NSString * _Nullable errorMsg))completion {
    
    // 1. Add Timestamp for Anti-Replay Attack protection
    NSMutableDictionary *securePayload = [payloadDict mutableCopy];
    NSString *timestamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    securePayload[@"timestamp"] = timestamp;
    
    // 2. Convert to JSON and Encrypt
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:securePayload options:0 error:&err];
    if (err) {
        completion(NO, nil, @"Internal Payload Error");
        return;
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *encryptedPayload = [self encryptString:jsonString];
    
    if (!encryptedPayload) {
        completion(NO, nil, @"Encryption Failed");
        return;
    }
    
    // 3. Prepare HTTP Request
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", BASE_URL, endpoint]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSString *postString = [NSString stringWithFormat:@"data=%@", [encryptedPayload stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    request.HTTPBody = [postString dataUsingEncoding:NSUTF8StringEncoding];
    
    // 4. Send Request via Pinned Session
    NSURLSessionDataTask *task = [self.secureSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            completion(NO, nil, @"Connection lost to Master Node.");
            return;
        }
        
        // 5. Decrypt Server Response
        NSString *encryptedResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *decryptedJsonString = [self decryptString:encryptedResponse];
        
        if (!decryptedJsonString) {
            // Fallback: Check if server sent plain text error (e.g., 500 Internal Error)
            completion(NO, nil, @"Malformed response from server.");
            return;
        }
        
        NSData *decryptedData = [decryptedJsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:decryptedData options:0 error:nil];
        
        if (!parsedResponse) {
            completion(NO, nil, @"Data parsing failed.");
            return;
        }
        
        // 6. Handle Zentrax Backend Format
        BOOL status = [parsedResponse[@"status"] isEqualToString:@"success"];
        NSString *message = parsedResponse[@"message"];
        
        completion(status, parsedResponse, message);
    }];
    
    [task resume];
}

#pragma mark - ================= PUBLIC ACTIONS =================

- (void)authenticateWithKey:(NSString *)key completion:(void(^)(BOOL success, NSDictionary * _Nullable responseData, NSString * _Nullable errorMsg))completion {
    NSDictionary *payload = @{
        @"action": @"login",
        @"key": key,
        @"hwid": [self getHardwareID]
    };
    
    [self sendSecureRequestToEndpoint:@"auth.php" payload:payload completion:completion];
}

- (void)toggleModule:(NSString *)moduleName state:(BOOL)isOn completion:(void(^)(BOOL success, NSData * _Nullable fileData, NSString * _Nullable errorMsg))completion {
    NSDictionary *payload = @{
        @"action": @"fetch_module",
        @"module": moduleName,
        @"state": isOn ? @"ON" : @"OFF",
        @"hwid": [self getHardwareID]
    };
    
    [self sendSecureRequestToEndpoint:@"module.php" payload:payload completion:^(BOOL success, NSDictionary *responseData, NSString *errorMsg) {
        if (!success) {
            completion(NO, nil, errorMsg);
            return;
        }
        
        // Handle Base64 Encoded File Data from Server
        NSString *base64File = responseData[@"file_data"];
        if (base64File) {
            NSData *fileData = [[NSData alloc] initWithBase64EncodedString:base64File options:NSDataBase64DecodingIgnoreUnknownCharacters];
            completion(YES, fileData, nil);
        } else {
            completion(NO, nil, @"File payload empty or corrupted.");
        }
    }];
}

- (void)verifySessionWithCompletion:(void(^)(BOOL isValid))completion {
    NSDictionary *payload = @{
        @"action": @"heartbeat",
        @"hwid": [self getHardwareID]
    };
    
    [self sendSecureRequestToEndpoint:@"heartbeat.php" payload:payload completion:^(BOOL success, NSDictionary *responseData, NSString *errorMsg) {
        completion(success);
    }];
}

#pragma mark - ================= SSL PINNING (ANTI-SNIFF) =================

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    // Zentrax SSL Pinning - Blocks Charles Proxy / Burp Suite
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        
        // Option 1: Basic validation (Accepts trusted CAs)
        // SecTrustResultType result;
        // SecTrustEvaluate(serverTrust, &result);
        // if (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified) {
        //     completionHandler(NSURLSessionAuthChallengeUseCredential, [[NSURLCredential alloc] initWithTrust:serverTrust]);
        //     return;
        // }
        
        // Option 2: Strict SSL Pinning (Uncomment and add your actual certificate's public key hash)
        /*
        SecCertificateRef serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
        NSData *serverCertificateData = CFBridgingRelease(SecCertificateCopyData(serverCertificate));
        // Hash the serverCertificateData and compare it against your known Zentrax SSL Hash.
        // If matched -> Allow. If not -> Cancel.
        */
        
        // For development, allowing default trust
        completionHandler(NSURLSessionAuthChallengeUseCredential, [[NSURLCredential alloc] initWithTrust:serverTrust]);
    } else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
}

@end
