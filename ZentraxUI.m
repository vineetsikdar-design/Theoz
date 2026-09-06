//
//  ZentraxUI.m
//  Zentrax VIP - Premium Security Infrastructure UI
//
//  Architecture: Server-authoritative UI / Network-driven state
//  Status: FINAL CONTRACT
//

#import "ZentraxUI.h"
#import "ZentraxNetworkManager.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - Constants & Keys

static NSString * const ZXSafeModeEnabledKey = @"in.zentrax.global.safemode.enabled";
static NSString * const ZXSafeModePasscodeAccount = @"in.zentrax.global.safemode.pin";
static NSString * const ZXLanguageKey = @"in.zentrax.global.language";
static NSString * const ZXThemeKey = @"in.zentrax.global.theme";
static NSString * const ZXLastKey = @"in.zentrax.global.lastkey";
static NSInteger const ZXMaxPINAttempts = 5;

#pragma mark - App State Enum

typedef NS_ENUM(NSInteger, ZXAppState) {
    ZXAppStateInit = 0,
    ZXAppStateSplash,
    ZXAppStateAuth,
    ZXAppStateDashboard,
    ZXAppStateStartupBlock
};

#pragma mark - Safe UI Helpers

static UILabel *ZXLabel(NSString *text, UIFont *font, UIColor *color) {
    UILabel *label = [[UILabel alloc] init];
    label.text = text ?: @"";
    label.font = font ?: [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    label.textColor = color ?: [UIColor whiteColor];
    label.numberOfLines = 1;
    label.userInteractionEnabled = NO;
    return label;
}

static BOOL ZXIsTruthyValue(id value) {
    if (!value || value == [NSNull null]) return NO;
    if ([value isKindOfClass:[NSNumber class]]) return [value boolValue];
    if ([value isKindOfClass:[NSString class]]) {
        NSString *s = [(NSString *)value lowercaseString];
        if ([s isEqualToString:@"1"] || [s isEqualToString:@"true"] || [s isEqualToString:@"yes"] || [s isEqualToString:@"on"] || [s isEqualToString:@"active"] || [s isEqualToString:@"enabled"]) return YES;
    }
    return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : NO;
}

static NSString *ZXSafeString(id value, NSString *fallback) {
    if (!value || value == [NSNull null] || ![value isKindOfClass:[NSString class]]) return fallback;
    NSString *str = (NSString *)value;
    if (str.length == 0 || [str isEqualToString:@"<null>"] || [str isEqualToString:@"null"]) return fallback;
    return str;
}

#pragma mark - Localization

static NSString *ZXCurrentLanguage(void) {
    NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *language = [globalDefaults stringForKey:ZXLanguageKey];
    return language.length ? language : @"English";
}

static NSString *ZXLocalizedUI(NSString *text) {
    if (![text isKindOfClass:[NSString class]] || !text.length) return text ?: @"";
    NSString *language = ZXCurrentLanguage();
    if ([language isEqualToString:@"English"]) return text;

    NSDictionary *vi = @{
        @"Settings": @"Cài đặt", @"Safe UI Mode": @"Chế độ UI an toàn",
        @"Protected lock screen is enabled": @"Màn hình khóa bảo vệ đang bật",
        @"Add a private six-digit lock screen": @"Thêm màn hình khóa riêng 6 chữ số",
        @"DEVICE STATUS": @"TRẠNG THÁI THIẾT BỊ", @"PREFERENCES": @"TÙY CHỌN",
        @"ACCOUNT": @"TÀI KHOẢN", @"Language": @"Ngôn ngữ", @"Appearance": @"Giao diện",
        @"Sign Out": @"Đăng xuất", @"Close the current secure session": @"Đóng phiên bảo mật hiện tại",
        @"LICENSE CONTROL": @"QUẢN LÝ GIẤY PHÉP", @"SECURE FUNCTIONS": @"CHỨC NĂNG BẢO MẬT",
        @"Secure node connected.": @"Nút bảo mật đã kết nối.", @"Awaiting first activation": @"Đang chờ kích hoạt lần đầu",
        @"Lifetime server entitlement": @"Quyền sử dụng vĩnh viễn từ máy chủ",
        @"No functions available": @"Không có chức năng khả dụng",
        @"Your server configuration will appear here when functions are assigned to this license.": @"Cấu hình máy chủ sẽ xuất hiện ở đây khi chức năng được gán cho giấy phép này.",
        @"Enter passcode": @"Nhập mật mã", @"Create Passcode": @"Tạo mật mã",
        @"Create a 6-digit private passcode": @"Tạo mật mã riêng gồm 6 chữ số",
        @"Confirm Passcode": @"Xác nhận mật mã", @"Enter the same 6-digit passcode again": @"Nhập lại mật mã 6 chữ số",
        @"Private space unlocked": @"Không gian riêng đã mở khóa",
        @"Choose your language": @"Chọn ngôn ngữ", @"You can change this anytime from Settings.": @"Bạn có thể thay đổi bất cứ lúc nào trong Cài đặt.",
        @"WELCOME TO ZENTRAX": @"CHÀO MỪNG ĐẾN VỚI ZENTRAX",
        @"PREMIUM THEMES": @"CHỦ ĐỀ CAO CẤP", @"DONE": @"XONG", @"RECHECK": @"KIỂM TRA LẠI",
        @"UNAVAILABLE": @"KHÔNG KHẢ DỤNG", @"DISMISS": @"ĐÓNG", @"RETRY": @"THỬ LẠI",
        @"Close screen sharing app": @"Đóng ứng dụng chia sẻ màn hình",
        @"Screen sharing apps can be used by fraudsters to record your screen and steal your wallet information": @"Ứng dụng chia sẻ màn hình có thể bị kẻ gian sử dụng để ghi lại màn hình và đánh cắp thông tin ví của bạn",
        @"AUTHENTICATE": @"XÁC THỰC", @"SECURE OPERATION": @"THAO TÁC BẢO MẬT", @"Please wait…": @"Vui lòng chờ…",
        @"Awaiting verification": @"Đang chờ xác minh", @"NOT VERIFIED": @"CHƯA XÁC MINH", @"SUPPORTED": @"HỖ TRỢ", @"UNSUPPORTED": @"KHÔNG HỖ TRỢ"
    };
    NSDictionary *zh = @{
        @"Settings": @"设置", @"Safe UI Mode": @"安全界面模式",
        @"Protected lock screen is enabled": @"受保护的锁定屏幕已启用", @"Add a private六位锁屏": @"添加私密六位锁屏",
        @"DEVICE STATUS": @"设备状态", @"PREFERENCES": @"偏好设置", @"ACCOUNT": @"账户",
        @"Language": @"语言", @"Appearance": @"外观", @"Sign Out": @"退出登录",
        @"Close the current secure session": @"关闭当前安全会话", @"LICENSE CONTROL": @"许可证控制",
        @"SECURE FUNCTIONS": @"安全功能", @"Secure node connected.": @"安全节点已连接。",
        @"Awaiting first activation": @"等待首次激活", @"Lifetime server entitlement": @"服务器永久授权",
        @"No functions available": @"暂无可用功能",
        @"Your server configuration will appear here when functions are assigned to this license.": @"为此许可证分配功能后，服务器配置将显示在这里。",
        @"Enter passcode": @"输入密码", @"Create Passcode": @"创建密码", @"Create a 6-digit private passcode": @"创建六位私密密码",
        @"Confirm Passcode": @"确认密码", @"Enter the same 6-digit passcode again": @"再次输入相同的六位密码",
        @"Private space unlocked": @"私密空间已解锁", @"Choose your language": @"选择语言",
        @"You can change this anytime from Settings.": @"你可以随时在设置中更改。", @"WELCOME TO ZENTRAX": @"欢迎使用 ZENTRAX",
        @"PREMIUM THEMES": @"高级主题", @"DONE": @"完成", @"RECHECK": @"重新检查", @"UNAVAILABLE": @"不可用",
        @"DISMISS": @"关闭", @"RETRY": @"重试", @"Close screen sharing app": @"关闭屏幕共享应用",
        @"Screen sharing apps can be used by fraudsters to record your screen and steal your wallet information": @"屏幕共享应用可能被诈骗者用来录制屏幕并窃取钱包信息",
        @"AUTHENTICATE": @"验证", @"SECURE OPERATION": @"安全操作", @"Please wait…": @"请稍候…",
        @"Awaiting verification": @"等待验证", @"NOT VERIFIED": @"未验证", @"SUPPORTED": @"支持", @"UNSUPPORTED": @"不支持"
    };
    NSString *localized = [language isEqualToString:@"Tiếng Việt"] ? vi[text] : ([language isEqualToString:@"简体中文"] ? zh[text] : nil);
    if (!localized.length) {
        NSDictionary *commonVI=@{ @"ACTIVE":@"ĐANG BẬT", @"READY":@"SẴN SÀNG", @"UNACTIVATED":@"CHƯA KÍCH HOẠT", @"EXPIRED":@"ĐÃ HẾT HẠN", @"REVOKED":@"ĐÃ THU HỒI", @"DISABLED":@"ĐÃ TẮT", @"UNKNOWN":@"KHÔNG XÁC ĐỊNH", @"PROCESSING":@"ĐANG XỬ LÝ", @"PERMANENT":@"VĨNH VIỄN", @"NOT STARTED":@"CHƯA BẮT ĐẦU", @"● SECURE":@"● BẢO MẬT", @"● OFFLINE":@"● NGOẠI TUYẾN" };
        NSDictionary *commonZH=@{ @"ACTIVE":@"已启用", @"READY":@"就绪", @"UNACTIVATED":@"未激活", @"EXPIRED":@"已过期", @"REVOKED":@"已撤销", @"DISABLED":@"已禁用", @"UNKNOWN":@"未知", @"PROCESSING":@"处理中", @"PERMANENT":@"永久", @"NOT STARTED":@"未开始", @"● SECURE":@"● 安全", @"● OFFLINE":@"● 离线" };
        localized = [language isEqualToString:@"Tiếng Việt"] ? commonVI[text] : ([language isEqualToString:@"简体中文"] ? commonZH[text] : nil);
    }
    return localized.length ? localized : text;
}

#pragma mark - Theme Engine

@interface ZXTheme : NSObject
+ (NSString *)currentTheme;
+ (UIColor *)background; + (UIColor *)surface; + (UIColor *)surfaceRaised; + (UIColor *)surfaceInset; + (UIColor *)border; + (UIColor *)borderStrong;
+ (UIColor *)primaryText; + (UIColor *)secondaryText; + (UIColor *)mutedText; + (UIColor *)accent;
+ (UIColor *)success; + (UIColor *)warning; + (UIColor *)error;
+ (UIFont *)display:(CGFloat)size; + (UIFont *)heading:(CGFloat)size; + (UIFont *)body:(CGFloat)size weight:(UIFontWeight)weight; + (UIFont *)mono:(CGFloat)size weight:(UIFontWeight)weight;
+ (void)track:(UILabel *)label spacing:(CGFloat)spacing; + (void)styleCard:(UIView *)view radius:(CGFloat)radius;
@end

@implementation ZXTheme
+ (NSString *)currentTheme {
    NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    return [globalDefaults stringForKey:ZXThemeKey] ?: @"Obsidian Black";
}
+ (UIColor *)background { return [UIColor blackColor]; } 
+ (UIColor *)surface {
    NSString *t = [self currentTheme];
    if ([t isEqualToString:@"Carbon Silver"]) return [UIColor colorWithWhite:0.06 alpha:1.0];
    if ([t isEqualToString:@"Midnight Graphite"]) return [UIColor colorWithRed:0.04 green:0.04 blue:0.05 alpha:1.0];
    if ([t isEqualToString:@"Stealth Mono"]) return [UIColor colorWithWhite:0.02 alpha:1.0];
    return [UIColor colorWithWhite:0.04 alpha:1.0]; 
}
+ (UIColor *)surfaceRaised {
    NSString *t = [self currentTheme];
    if ([t isEqualToString:@"Carbon Silver"]) return [UIColor colorWithWhite:0.09 alpha:1.0];
    if ([t isEqualToString:@"Midnight Graphite"]) return [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:1.0];
    if ([t isEqualToString:@"Stealth Mono"]) return [UIColor colorWithWhite:0.04 alpha:1.0];
    return [UIColor colorWithWhite:0.06 alpha:1.0];
}
+ (UIColor *)surfaceInset { return [UIColor colorWithWhite:0.01 alpha:1.0]; }
+ (UIColor *)border {
    NSString *t = [self currentTheme];
    if ([t isEqualToString:@"Carbon Silver"]) return [UIColor colorWithWhite:0.18 alpha:1.0];
    if ([t isEqualToString:@"Midnight Graphite"]) return [UIColor colorWithRed:0.12 green:0.12 blue:0.15 alpha:1.0];
    if ([t isEqualToString:@"Stealth Mono"]) return [UIColor colorWithWhite:0.12 alpha:1.0];
    return [UIColor colorWithWhite:0.14 alpha:1.0];
}
+ (UIColor *)borderStrong { return [UIColor colorWithWhite:0.35 alpha:1.0]; }
+ (UIColor *)primaryText { return [UIColor whiteColor]; }
+ (UIColor *)secondaryText { return [UIColor colorWithWhite:0.65 alpha:1.0]; }
+ (UIColor *)mutedText { return [UIColor colorWithWhite:0.45 alpha:1.0]; }
+ (UIColor *)accent { return [UIColor whiteColor]; } 
+ (UIColor *)success { return [UIColor colorWithWhite:0.95 alpha:1.0]; } 
+ (UIColor *)warning { return [UIColor colorWithWhite:0.75 alpha:1.0]; }
+ (UIColor *)error { return [UIColor colorWithRed:0.9 green:0.3 blue:0.3 alpha:1.0]; }

+ (UIFont *)display:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightHeavy]; }
+ (UIFont *)heading:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightSemibold]; }
+ (UIFont *)body:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont systemFontOfSize:size weight:weight]; }
+ (UIFont *)mono:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont monospacedSystemFontOfSize:size weight:weight]; }

+ (void)track:(UILabel *)label spacing:(CGFloat)spacing {
    if (!label.text.length) return;
    label.attributedText = [[NSAttributedString alloc] initWithString:label.text attributes:@{NSKernAttributeName:@(spacing)}];
}
+ (void)styleCard:(UIView *)view radius:(CGFloat)radius {
    view.backgroundColor = [self surface];
    view.layer.cornerRadius = radius;
    view.layer.borderWidth = 1;
    view.layer.borderColor = [self border].CGColor;
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOpacity = 0.40;
    view.layer.shadowRadius = 24;
    view.layer.shadowOffset = CGSizeMake(0,10);
}
@end

#pragma mark - Premium Components

@interface ZXPremiumButton : UIButton
@property(nonatomic,strong) UIActivityIndicatorView *spinner;
@property(nonatomic,strong) NSString *savedTitle;
- (void)setLoading:(BOOL)loading;
@end

@implementation ZXPremiumButton
- (instancetype)init {
    self=[super initWithFrame:CGRectZero];
    if (!self) return nil;
    self.backgroundColor = [ZXTheme accent];
    self.layer.cornerRadius = 14.0;
    self.clipsToBounds = NO;
    self.titleLabel.font = [ZXTheme heading:14];
    [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    self.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.layer.shadowOpacity = 0.15;
    self.layer.shadowRadius = 12.0;
    self.layer.shadowOffset = CGSizeMake(0, 4);

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    _spinner.color = [UIColor blackColor];
    _spinner.hidesWhenStopped = YES;
    _spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_spinner];
    [NSLayoutConstraint activateConstraints:@[
        [_spinner.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_spinner.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
    ]];
    [self addTarget:self action:@selector(zxTouchDown) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(zxTouchUp) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    return self;
}
- (void)zxTouchDown {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [UIView animateWithDuration:0.1 animations:^{ self.transform = CGAffineTransformMakeScale(0.97, 0.97); self.alpha = 0.9; }];
}
- (void)zxTouchUp {
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.2 options:UIViewAnimationOptionAllowUserInteraction animations:^{ self.transform = CGAffineTransformIdentity; self.alpha = 1.0; } completion:nil];
}
- (void)setLoading:(BOOL)loading {
    self.userInteractionEnabled = !loading;
    if (loading) {
        self.savedTitle = [self titleForState:UIControlStateNormal];
        [self setTitle:@"" forState:UIControlStateNormal];
        [_spinner startAnimating];
    } else {
        [self setTitle:self.savedTitle ?: @"" forState:UIControlStateNormal];
        [_spinner stopAnimating];
    }
}
@end

@interface ZXPremiumField : UIView <UITextFieldDelegate>
@property(nonatomic,strong) UITextField *textField;
@property(nonatomic,strong) UIView *container;
@end

@implementation ZXPremiumField
- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;
    
    UILabel *caption = ZXLabel(@"LICENSE KEY", [ZXTheme body:10 weight:UIFontWeightBold], [ZXTheme mutedText]);
    [ZXTheme track:caption spacing:1.5];
    caption.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:caption];

    _container = [[UIView alloc] init];
    _container.backgroundColor = [ZXTheme surfaceInset];
    _container.layer.cornerRadius = 12;
    _container.layer.borderWidth = 1;
    _container.layer.borderColor = [ZXTheme border].CGColor;
    _container.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_container];

    _textField = [[UITextField alloc] init];
    _textField.textColor = [ZXTheme primaryText];
    _textField.font = [ZXTheme mono:14 weight:UIFontWeightMedium];
    _textField.secureTextEntry = YES;
    _textField.delegate = self;
    _textField.autocorrectionType = UITextAutocorrectionTypeNo;
    _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _textField.returnKeyType = UIReturnKeyDone;
    _textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"ZTX-••••-••••-••••" attributes:@{NSForegroundColorAttributeName:[ZXTheme mutedText]}];
    _textField.translatesAutoresizingMaskIntoConstraints = NO;
    [_container addSubview:_textField];

    [NSLayoutConstraint activateConstraints:@[
        [caption.topAnchor constraintEqualToAnchor:self.topAnchor],
        [caption.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:4],
        [_container.topAnchor constraintEqualToAnchor:caption.bottomAnchor constant:8],
        [_container.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_container.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_container.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_container.heightAnchor constraintEqualToConstant:54],
        [_textField.leadingAnchor constraintEqualToAnchor:_container.leadingAnchor constant:16],
        [_textField.trailingAnchor constraintEqualToAnchor:_container.trailingAnchor constant:-16],
        [_textField.centerYAnchor constraintEqualToAnchor:_container.centerYAnchor]
    ]];
    return self;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.2 animations:^{ self.container.layer.borderColor = [ZXTheme borderStrong].CGColor; }];
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.2 animations:^{ self.container.layer.borderColor = [ZXTheme border].CGColor; }];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end

#pragma mark - Main Controller

@interface ZentraxUI () <UITextFieldDelegate>
@property(nonatomic,assign) ZXAppState currentState;
@property(nonatomic,assign) ZXStartupState startupState;
@property(nonatomic,assign) BOOL hasStarted;
@property(nonatomic,assign) BOOL safeModeEnabled;
@property(nonatomic,assign) ZXSafeModeState safeModeState;
@property(nonatomic,assign) BOOL privacyOverlayPresented;
@property(nonatomic,assign) BOOL keyRevealed;
@property(nonatomic,assign) BOOL settingsVisible;
@property(nonatomic,assign) BOOL licensePermanent;
@property(nonatomic,assign) ZXLicenseUIStatus licenseStatus;
@property(nonatomic,strong) NSDate *serverDate;
@property(nonatomic,strong) NSDate *activatedAt;
@property(nonatomic,strong) NSDate *expiresAt;
@property(nonatomic,strong) NSTimer *licenseTimer;
@property(nonatomic,strong) NSTimer *heartbeatTimer;
@property(nonatomic,copy) NSString *serverBannerMessage;
@property(nonatomic,strong) NSDictionary *compatibilityData;
@property(nonatomic,strong) NSDictionary *dashboardConfiguration;
@property(nonatomic,strong) NSMutableDictionary<NSString *, NSNumber *> *functionStates;
@property(nonatomic,strong) NSMutableDictionary<NSString *, UIView *> *functionCards;
@property(nonatomic,strong) NSMutableDictionary<NSString *, UIControl *> *functionControls;
@property(nonatomic,strong) NSMutableDictionary<NSString *, NSDictionary *> *functionDefinitions;
@property(nonatomic,strong) NSMutableDictionary<NSString *, UILabel *> *functionStateLabels;

@property(nonatomic,strong) UIView *splashContainer;
@property(nonatomic,strong) UIView *authContainer;
@property(nonatomic,strong) UIView *dashboardContainer;
@property(nonatomic,strong) UIView *settingsContainer;
@property(nonatomic,strong) UIView *startupBlockContainer;
@property(nonatomic,strong) UIView *safeLockContainer;
@property(nonatomic,strong) UIView *privacyOverlay;
@property(nonatomic,strong) UIView *globalLoadingOverlay;
@property(nonatomic,strong) UIView *toastView;
@property(nonatomic,strong) UIView *languageOverlay;

@property(nonatomic,strong) UILabel *splashStatus;
@property(nonatomic,strong) UILabel *splashDetail;

@property(nonatomic,strong) ZXPremiumField *keyInput;
@property(nonatomic,strong) ZXPremiumButton *loginBtn;
@property(nonatomic,strong) UILabel *authStatus;
@property(nonatomic,strong) UIScrollView *authScroll;

@property(nonatomic,strong) UILabel *licenseStatusLabel;
@property(nonatomic,strong) UILabel *expiryLabel;
@property(nonatomic,strong) UILabel *countdownLabel;
@property(nonatomic,strong) UILabel *keyRevealLabel;
@property(nonatomic,strong) UIButton *keyEyeButton;
@property(nonatomic,strong) UILabel *connectionLabel;
@property(nonatomic,strong) UIStackView *modulesStack;
@property(nonatomic,strong) UIScrollView *modulesScroll;
@property(nonatomic,strong) UIView *emptyState;
@property(nonatomic,strong) UIView *serverBannerView;
@property(nonatomic,strong) UIView *licenseCard;

@property(nonatomic,strong) UIScrollView *settingsScroll;
@property(nonatomic,strong) UIStackView *settingsStack;

@property(nonatomic,strong) UILabel *startupBlockTitle;
@property(nonatomic,strong) UILabel *startupBlockMessage;
@property(nonatomic,strong) UIButton *startupBlockAction;
@property(nonatomic,assign) ZXStartupState blockedState;

@property(nonatomic,strong) UILabel *safeLockTitle;
@property(nonatomic,strong) UILabel *safeLockSubtitle;
@property(nonatomic,strong) UIStackView *pinBoxes;
@property(nonatomic,strong) NSMutableString *enteredPIN;
@property(nonatomic,strong) UITextField *safePINInput;
@property(nonatomic,strong) UIButton *safeLockBackButton;
@property(nonatomic,strong) UILabel *safePinError;
@property(nonatomic,assign) BOOL safeModeCreatingPasscode;
@property(nonatomic,assign) BOOL safeModeDisabling;
@property(nonatomic,copy) NSString *pendingSafeModePasscode;
@property(nonatomic,assign) NSInteger safeModeAttemptsRemaining;

@property(nonatomic,strong) UIActivityIndicatorView *globalSpinner;
@property(nonatomic,strong) UILabel *globalLoadingTitle;
@property(nonatomic,strong) UILabel *globalLoadingDetail;

- (UIImage *)preferredLogoImage;
@end

@implementation ZentraxUI

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _functionStates = [NSMutableDictionary dictionary];
        _functionCards = [NSMutableDictionary dictionary];
        _functionControls = [NSMutableDictionary dictionary];
        _functionDefinitions = [NSMutableDictionary dictionary];
        _functionStateLabels = [NSMutableDictionary dictionary];
        _enteredPIN = [NSMutableString string];
        _safeModeAttemptsRemaining = ZXMaxPINAttempts;
        _licenseStatus = ZXLicenseUIStatusUnknown;
        _startupState = ZXStartupStateUnknown;
    }
    return self;
}

- (void)dealloc {
    [_licenseTimer invalidate];
    [_heartbeatTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [ZXTheme background];
    self.view.tintColor = [ZXTheme primaryText];
    self.view.opaque = YES;
    self.currentState = ZXAppStateInit;

    [self setupSplash];
    [self setupAuth];
    [self setupDashboard];
    [self setupSettingsScreen];
    [self setupStartupBlock];
    [self setupSafeModeLock];
    [self setupGlobalLoading];

    [self registerPrivacyObservers];
    [self applyInitialSafeModeState];
    [self setAllPrimaryContainersHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.hasStarted) {
        self.hasStarted = YES;
        [self startZentraxUI];
    }
    [self updatePrivacyCaptureState];
}

- (void)startZentraxUI {
    if (self.safeModeEnabled) {
        [self updateSafeModeState:ZXSafeModeStateLocked];
        [self showSafeModeLockScreen];
        return;
    }
    [self beginBootstrap];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Setup: Common

- (void)setAllPrimaryContainersHidden:(BOOL)hidden {
    self.splashContainer.hidden = hidden;
    self.authContainer.hidden = hidden;
    self.dashboardContainer.hidden = hidden;
    self.settingsContainer.hidden = hidden;
    self.startupBlockContainer.hidden = hidden;
    self.safeLockContainer.hidden = hidden;
}

- (void)transitionToPrimaryContainer:(UIView *)target {
    if (!target) return;
    NSArray *containers=@[self.splashContainer ?: [UIView new],self.authContainer ?: [UIView new],self.dashboardContainer ?: [UIView new],self.settingsContainer ?: [UIView new],self.startupBlockContainer ?: [UIView new],self.safeLockContainer ?: [UIView new]];
    for (UIView *container in containers) {
        if (container != target) { container.hidden = YES; container.alpha = 1.0; container.transform = CGAffineTransformIdentity; }
    }
    target.hidden = NO;
    target.alpha = 0.0;
    target.transform = CGAffineTransformMakeTranslation(0, 10.0);
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0.1 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction animations:^{
        target.alpha = 1.0;
        target.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (UIView *)card {
    UIView *v = [[UIView alloc] init];
    [ZXTheme styleCard:v radius:18.0];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    return v;
}

- (UILabel *)label:(NSString *)text size:(CGFloat)size weight:(UIFontWeight)weight color:(UIColor *)color {
    UILabel *l = [[UILabel alloc] init];
    l.text = ZXLocalizedUI(text);
    l.font = [ZXTheme body:size weight:weight];
    l.textColor = color;
    l.numberOfLines = 0;
    return l;
}

- (UIButton *)iconButton:(NSString *)symbol size:(CGFloat)size {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *image = [UIImage systemImageNamed:symbol];
    [b setImage:image forState:UIControlStateNormal];
    b.tintColor = [ZXTheme primaryText];
    b.imageView.contentMode = UIViewContentModeScaleAspectFit;
    b.translatesAutoresizingMaskIntoConstraints = NO;
    [b.widthAnchor constraintEqualToConstant:size].active = YES;
    [b.heightAnchor constraintEqualToConstant:size].active = YES;
    return b;
}

- (void)styleSecondaryButton:(UIButton *)button {
    button.backgroundColor = [ZXTheme surfaceRaised];
    button.layer.cornerRadius = 12.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [ZXTheme border].CGColor;
    button.titleLabel.font = [ZXTheme heading:13];
    [button setTitleColor:[ZXTheme primaryText] forState:UIControlStateNormal];
}

#pragma mark - Splash

- (void)setupSplash {
    _splashContainer = [[UIView alloc] init];
    _splashContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_splashContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_splashContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_splashContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_splashContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_splashContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UIImageView *logo = [[UIImageView alloc] initWithImage:[self preferredLogoImage]];
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.layer.cornerRadius = 28;
    logo.clipsToBounds = YES;
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:logo];

    UILabel *brand = [self label:@"ZENTRAX" size:24 weight:UIFontWeightBlack color:[ZXTheme primaryText]];
    [ZXTheme track:brand spacing:5.0];
    brand.textAlignment = NSTextAlignmentCenter;
    brand.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:brand];

    _splashStatus = [self label:@"INITIALIZING" size:10 weight:UIFontWeightBold color:[ZXTheme secondaryText]];
    [ZXTheme track:_splashStatus spacing:2.0];
    _splashStatus.textAlignment = NSTextAlignmentCenter;
    _splashStatus.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_splashStatus];

    _splashDetail = [self label:@"Secure environment load" size:11 weight:UIFontWeightRegular color:[ZXTheme mutedText]];
    _splashDetail.textAlignment = NSTextAlignmentCenter;
    _splashDetail.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_splashDetail];

    [NSLayoutConstraint activateConstraints:@[
        [logo.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [logo.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor constant:-60],
        [logo.widthAnchor constraintEqualToConstant:76],
        [logo.heightAnchor constraintEqualToConstant:76],
        [brand.topAnchor constraintEqualToAnchor:logo.bottomAnchor constant:24],
        [brand.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [_splashStatus.topAnchor constraintEqualToAnchor:brand.bottomAnchor constant:12],
        [_splashStatus.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [_splashDetail.topAnchor constraintEqualToAnchor:_splashStatus.bottomAnchor constant:6],
        [_splashDetail.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor]
    ]];
}

- (void)runPremiumSplashCompletion:(void (^)(void))completion {
    NSArray *steps = @[
        @[@"CONNECTING", @"Reaching secure node"],
        @[@"VERIFYING", @"Checking server policy"],
        @[@"READY", @"Finalizing interface"]
    ];
    [self runPremiumSplashStep:0 steps:steps completion:completion];
}

- (void)runPremiumSplashStep:(NSInteger)index steps:(NSArray *)steps completion:(void (^)(void))completion {
    if (index >= steps.count) {
        if (completion) completion();
        return;
    }
    NSArray *step = steps[index];
    self.splashStatus.text = ZXLocalizedUI(step[0]);
    self.splashDetail.text = ZXLocalizedUI(step[1]);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self runPremiumSplashStep:index + 1 steps:steps completion:completion];
    });
}

#pragma mark - Authentication

- (void)setupAuth {
    _authContainer = [[UIView alloc] init];
    _authContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_authContainer];
    
    _authScroll = [[UIScrollView alloc] init];
    _authScroll.alwaysBounceVertical = YES;
    _authScroll.showsVerticalScrollIndicator = NO;
    _authScroll.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    _authScroll.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:_authScroll];

    UIView *content = [[UIView alloc] init];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [_authScroll addSubview:content];

    [NSLayoutConstraint activateConstraints:@[
        [_authContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_authContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_authContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_authContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [_authScroll.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor],
        [_authScroll.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor],
        [_authScroll.topAnchor constraintEqualToAnchor:_authContainer.topAnchor],
        [_authScroll.bottomAnchor constraintEqualToAnchor:_authContainer.bottomAnchor],
        [content.leadingAnchor constraintEqualToAnchor:_authScroll.contentLayoutGuide.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:_authScroll.contentLayoutGuide.trailingAnchor],
        [content.topAnchor constraintEqualToAnchor:_authScroll.contentLayoutGuide.topAnchor],
        [content.bottomAnchor constraintEqualToAnchor:_authScroll.contentLayoutGuide.bottomAnchor],
        [content.widthAnchor constraintEqualToAnchor:_authScroll.frameLayoutGuide.widthAnchor]
    ]];

    UIImageView *logo = [[UIImageView alloc] initWithImage:[self preferredLogoImage]];
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.layer.cornerRadius = 20;
    logo.clipsToBounds = YES;
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:logo];

    UILabel *title = [self label:@"Authenticate" size:28 weight:UIFontWeightHeavy color:[ZXTheme primaryText]];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:title];

    UILabel *subtitle = [self label:@"Enter your secure license key to access the workspace." size:14 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:subtitle];

    _keyInput = [[ZXPremiumField alloc] init];
    _keyInput.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:_keyInput];

    _loginBtn = [[ZXPremiumButton alloc] init];
    [_loginBtn setTitle:ZXLocalizedUI(@"AUTHENTICATE") forState:UIControlStateNormal];
    _loginBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_loginBtn addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:_loginBtn];

    _authStatus = [self label:@"" size:12 weight:UIFontWeightMedium color:[ZXTheme mutedText]];
    _authStatus.textAlignment = NSTextAlignmentCenter;
    _authStatus.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:_authStatus];

    [NSLayoutConstraint activateConstraints:@[
        [logo.topAnchor constraintEqualToAnchor:content.topAnchor constant:100],
        [logo.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:30],
        [logo.widthAnchor constraintEqualToConstant:56],
        [logo.heightAnchor constraintEqualToConstant:56],
        [title.topAnchor constraintEqualToAnchor:logo.bottomAnchor constant:24],
        [title.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:30],
        [title.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-30],
        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
        [subtitle.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:30],
        [subtitle.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-30],
        [_keyInput.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:36],
        [_keyInput.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:30],
        [_keyInput.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-30],
        [_loginBtn.topAnchor constraintEqualToAnchor:_keyInput.bottomAnchor constant:24],
        [_loginBtn.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:30],
        [_loginBtn.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-30],
        [_loginBtn.heightAnchor constraintEqualToConstant:54],
        [_authStatus.topAnchor constraintEqualToAnchor:_loginBtn.bottomAnchor constant:20],
        [_authStatus.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:30],
        [_authStatus.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-30],
        [_authStatus.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-40]
    ]];
}

- (void)keyboardWillShow:(NSNotification *)note {
    CGSize kbSize = [[note.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.authScroll.contentInset = contentInsets;
    self.authScroll.scrollIndicatorInsets = contentInsets;
}
- (void)keyboardWillHide:(NSNotification *)note {
    self.authScroll.contentInset = UIEdgeInsetsZero;
    self.authScroll.scrollIndicatorInsets = UIEdgeInsetsZero;
}

- (void)handleLogin {
    NSString *key = [_keyInput.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!key.length) {
        [self showToast:@"Enter your license key." success:NO];
        return;
    }
    
    NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    [globalDefaults setObject:key forKey:ZXLastKey];
    [globalDefaults synchronize];

    [_loginBtn setLoading:YES];
    _authStatus.textColor = [ZXTheme secondaryText];
    _authStatus.text = ZXLocalizedUI(@"Connecting…");
    [self showGlobalLoadingState:@"AUTHENTICATING"];
    [self updateGlobalLoadingMessage:@"Connecting to secure server"];

    __weak typeof(self) weakSelf = self;
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestAuthenticationWithKey:completion:)]) {
        [self.delegate zentraxDidRequestAuthenticationWithKey:key completion:^(BOOL success, ZXAuthError errorType, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) return;
                [self hideGlobalLoadingState];
                [self.loginBtn setLoading:NO];
                if (success) {
                    self.authStatus.textColor = [ZXTheme success];
                    self.authStatus.text = ZXLocalizedUI(@"Access granted • Loading secure workspace");
                    [self showDashboard];
                } else {
                    [self presentAuthError:errorType message:errorMsg];
                }
            });
        }];
    } else {
        [[ZentraxNetworkManager sharedManager] authenticateWithKey:key completion:^(BOOL success, NSDictionary * _Nullable responseData, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) return;
                [self hideGlobalLoadingState];
                [self.loginBtn setLoading:NO];
                if (success) {
                    self.authStatus.textColor = [ZXTheme success];
                    self.authStatus.text = ZXLocalizedUI(@"Access granted • Loading secure workspace");
                    [self showDashboard];
                } else {
                    [self presentAuthError:(ZXAuthError)errorType message:errorMsg];
                }
            });
        }];
    }
}

- (void)presentAuthError:(ZXAuthError)errorType message:(NSString *)message {
    NSString *title = @"ACCESS DENIED";
    NSString *fallback = message.length ? message : @"The server rejected this authentication request.";
    switch (errorType) {
        case ZXAuthErrorConnection: title = @"CONNECTION ERROR"; break;
        case ZXAuthErrorServer: title = @"SERVER ERROR"; break;
        case ZXAuthErrorMaintenance: title = @"MAINTENANCE"; break;
        case ZXAuthErrorVersionMismatch: title = @"UPDATE REQUIRED"; break;
        case ZXAuthErrorCompatibility: title = @"DEVICE UNSUPPORTED"; break;
        case ZXAuthErrorRateLimited: title = @"TOO MANY REQUESTS"; break;
        case ZXAuthErrorExpiredKey: title = @"LICENSE EXPIRED"; break;
        case ZXAuthErrorRevokedKey: title = @"ACCESS REVOKED"; break;
        case ZXAuthErrorDeviceLimit: title = @"DEVICE LIMIT"; break;
        default: break;
    }
    _authStatus.textColor = [ZXTheme error];
    _authStatus.text = fallback;
    [self showGlobalErrorWithTitle:title message:fallback];
}

#pragma mark - Dashboard

- (void)setupDashboard {
    if (_dashboardContainer) [_dashboardContainer removeFromSuperview];
    
    _dashboardContainer = [[UIView alloc] init];
    _dashboardContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_dashboardContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_dashboardContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_dashboardContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_dashboardContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_dashboardContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UIView *header = [[UIView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:header];

    UIImageView *logo = [[UIImageView alloc] initWithImage:[self preferredLogoImage]];
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.layer.cornerRadius = 10;
    logo.clipsToBounds = YES;
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:logo];

    UILabel *dashTitle = [self label:@"ZENTRAX" size:16 weight:UIFontWeightHeavy color:[ZXTheme primaryText]];
    [ZXTheme track:dashTitle spacing:1.0];
    dashTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:dashTitle];

    _connectionLabel = [self label:@"● SECURE" size:9 weight:UIFontWeightBold color:[ZXTheme success]];
    [ZXTheme track:_connectionLabel spacing:1.0];
    _connectionLabel.textAlignment = NSTextAlignmentRight;
    _connectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:_connectionLabel];

    UIButton *settingsBtn = [self iconButton:@"slider.horizontal.3" size:34];
    [settingsBtn addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:settingsBtn];

    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [header.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [header.topAnchor constraintEqualToAnchor:_dashboardContainer.safeAreaLayoutGuide.topAnchor constant:10],
        [header.heightAnchor constraintEqualToConstant:44],
        [logo.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [logo.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [logo.widthAnchor constraintEqualToConstant:28],
        [logo.heightAnchor constraintEqualToConstant:28],
        [dashTitle.leadingAnchor constraintEqualToAnchor:logo.trailingAnchor constant:10],
        [dashTitle.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [_connectionLabel.trailingAnchor constraintEqualToAnchor:settingsBtn.leadingAnchor constant:-12],
        [_connectionLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [settingsBtn.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],
        [settingsBtn.centerYAnchor constraintEqualToAnchor:header.centerYAnchor]
    ]];

    _licenseCard = [self card];
    [_dashboardContainer addSubview:_licenseCard];
    [NSLayoutConstraint activateConstraints:@[
        [_licenseCard.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [_licenseCard.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [_licenseCard.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:20],
        [_licenseCard.heightAnchor constraintEqualToConstant:140] // Adjusted height
    ]];

    UILabel *licenseCaption = [self label:@"LICENSE CONTROL" size:9 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:licenseCaption spacing:1.5];
    licenseCaption.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:licenseCaption];

    _licenseStatusLabel = [self label:@"UNACTIVATED" size:11 weight:UIFontWeightBold color:[ZXTheme warning]];
    [ZXTheme track:_licenseStatusLabel spacing:1.0];
    _licenseStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:_licenseStatusLabel];

    _countdownLabel = [self label:@"—" size:26 weight:UIFontWeightHeavy color:[ZXTheme primaryText]];
    _countdownLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:_countdownLabel];

    _expiryLabel = [self label:@"Awaiting first activation" size:11 weight:UIFontWeightMedium color:[ZXTheme secondaryText]];
    _expiryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:_expiryLabel];

    [NSLayoutConstraint activateConstraints:@[
        [licenseCaption.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:20],
        [licenseCaption.topAnchor constraintEqualToAnchor:_licenseCard.topAnchor constant:20],
        [_licenseStatusLabel.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor constant:-20],
        [_licenseStatusLabel.centerYAnchor constraintEqualToAnchor:licenseCaption.centerYAnchor],
        [_countdownLabel.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:20],
        [_countdownLabel.topAnchor constraintEqualToAnchor:licenseCaption.bottomAnchor constant:16],
        [_countdownLabel.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor constant:-20],
        [_expiryLabel.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:20],
        [_expiryLabel.topAnchor constraintEqualToAnchor:_countdownLabel.bottomAnchor constant:4],
        [_expiryLabel.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor constant:-20],
    ]];

    UILabel *functionsTitle = [self label:@"SECURE FUNCTIONS" size:10 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:functionsTitle spacing:1.5];
    functionsTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:functionsTitle];

    _modulesScroll = [[UIScrollView alloc] init];
    _modulesScroll.showsVerticalScrollIndicator = NO;
    _modulesScroll.alwaysBounceVertical = YES;
    _modulesScroll.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:_modulesScroll];

    _modulesStack = [[UIStackView alloc] init];
    _modulesStack.axis = UILayoutConstraintAxisVertical;
    _modulesStack.spacing = 14;
    _modulesStack.translatesAutoresizingMaskIntoConstraints = NO;
    [_modulesScroll addSubview:_modulesStack];

    [NSLayoutConstraint activateConstraints:@[
        [functionsTitle.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [functionsTitle.topAnchor constraintEqualToAnchor:_licenseCard.bottomAnchor constant:26],
        [functionsTitle.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [_modulesScroll.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [_modulesScroll.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [_modulesScroll.topAnchor constraintEqualToAnchor:functionsTitle.bottomAnchor constant:12],
        [_modulesScroll.bottomAnchor constraintEqualToAnchor:_dashboardContainer.bottomAnchor],
        [_modulesStack.leadingAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.leadingAnchor],
        [_modulesStack.trailingAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.trailingAnchor],
        [_modulesStack.topAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.topAnchor constant:4],
        [_modulesStack.bottomAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.bottomAnchor constant:-40],
        [_modulesStack.widthAnchor constraintEqualToAnchor:_modulesScroll.frameLayoutGuide.widthAnchor]
    ]];

    [self createEmptyStateView];
    [self applyCurrentLanguageToView:_dashboardContainer];
}

- (void)createEmptyStateView {
    _emptyState = [self card];
    _emptyState.backgroundColor = [UIColor clearColor];
    _emptyState.layer.borderWidth = 1;
    _emptyState.layer.borderColor = [ZXTheme border].CGColor;
    
    UILabel *title = [self label:@"No functions available" size:13 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    title.textAlignment = NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyState addSubview:title];
    UILabel *detail = [self label:@"Server configuration will appear here." size:11 weight:UIFontWeightRegular color:[ZXTheme mutedText]];
    detail.textAlignment = NSTextAlignmentCenter;
    detail.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyState addSubview:detail];
    [NSLayoutConstraint activateConstraints:@[
        [_emptyState.heightAnchor constraintEqualToConstant:100],
        [title.centerYAnchor constraintEqualToAnchor:_emptyState.centerYAnchor constant:-8],
        [title.leadingAnchor constraintEqualToAnchor:_emptyState.leadingAnchor constant:20],
        [title.trailingAnchor constraintEqualToAnchor:_emptyState.trailingAnchor constant:-20],
        [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:6],
        [detail.leadingAnchor constraintEqualToAnchor:_emptyState.leadingAnchor constant:20],
        [detail.trailingAnchor constraintEqualToAnchor:_emptyState.trailingAnchor constant:-20]
    ]];
    [_modulesStack addArrangedSubview:_emptyState];
}

#pragma mark - Dynamic Dashboard Updates

- (void)updateDashboardWithModules:(NSArray<NSDictionary *> *)modules {
    [self updateDashboardWithConfiguration:@{ @"modules": modules ?: @[] }];
}

- (void)updateDashboardWithConfiguration:(NSDictionary *)configuration {
    if (![configuration isKindOfClass:[NSDictionary class]]) configuration=@{};
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self updateDashboardWithConfiguration:configuration]; });
        return;
    }
    
    NSArray *categories = configuration[@"categories"];
    NSArray *modules = configuration[@"modules"] ?: configuration[@"functions"];
    if (![categories isKindOfClass:[NSArray class]] || !categories.count) categories = modules;
    
    // Strict Validation: Don't let an empty heartbeat wipe out existing valid functions
    BOOL incomingHasUsableData = NO;
    for (id rawCategory in ([categories isKindOfClass:[NSArray class]] ? categories : @[])) {
        if (![rawCategory isKindOfClass:[NSDictionary class]]) continue;
        NSArray *functions = rawCategory[@"functions"];
        if ([functions isKindOfClass:[NSArray class]] && functions.count) { incomingHasUsableData = YES; break; }
        if (rawCategory[@"id"] || rawCategory[@"function_id"] || rawCategory[@"name"]) { incomingHasUsableData = YES; break; }
    }
    if (!incomingHasUsableData && self.functionDefinitions.count > 0) return;
    
    self.dashboardConfiguration = configuration ?: @{};

    for (UIView *v in [self.modulesStack.arrangedSubviews copy]) {
        [self.modulesStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    [self.functionCards removeAllObjects];
    [self.functionControls removeAllObjects];
    [self.functionDefinitions removeAllObjects];
    [self.functionStateLabels removeAllObjects];

    BOOL hasFunctions = NO;
    if (![categories isKindOfClass:[NSArray class]]) categories=@[];
    for (id rawCategory in categories) {
        if (![rawCategory isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *category=(NSDictionary *)rawCategory;
        NSArray *functions=category[@"functions"];
        NSString *categoryName=[category[@"name"] isKindOfClass:[NSString class]] ? category[@"name"] : ([category[@"title"] isKindOfClass:[NSString class]] ? category[@"title"] : nil);
        if (![functions isKindOfClass:[NSArray class]]) { functions=@[category]; categoryName=nil; }
        
        if (categoryName.length) {
            UILabel *cat=[self label:categoryName.uppercaseString size:9 weight:UIFontWeightBold color:[ZXTheme mutedText]];
            [ZXTheme track:cat spacing:1.5];
            [_modulesStack addArrangedSubview:cat];
        }
        for (id rawFunction in functions) {
            if (![rawFunction isKindOfClass:[NSDictionary class]]) continue;
            NSDictionary *function=(NSDictionary *)rawFunction;
            id rawID=function[@"id"] ?: function[@"function_id"] ?: function[@"name"];
            if (![rawID isKindOfClass:[NSString class]] && ![rawID isKindOfClass:[NSNumber class]]) continue;
            NSString *fid=[NSString stringWithFormat:@"%@",rawID];
            if (!fid.length) continue;
            
            hasFunctions=YES;
            [self.functionDefinitions setObject:function forKey:fid];
            id serverCurrentState = function[@"current_state"];
            id serverState = function[@"state"];
            BOOL on = NO;
            if (serverCurrentState != nil && serverCurrentState != [NSNull null]) on = ZXIsTruthyValue(serverCurrentState);
            else if (serverState != nil && serverState != [NSNull null]) on = ZXIsTruthyValue(serverState);
            else on = [self.functionStates[fid] boolValue];
            
            self.functionStates[fid]=@(on);
            UIView *card=[self functionCardForDefinition:function functionId:fid isOn:on];
            [_modulesStack addArrangedSubview:card];
            self.functionCards[fid]=card;
        }
    }
    if (!hasFunctions) {
        [self.modulesStack addArrangedSubview:self.emptyState];
    }
    
    [self applyCurrentLanguageToView:self.modulesStack];
}

- (UIView *)functionCardForDefinition:(NSDictionary *)definition functionId:(NSString *)fid isOn:(BOOL)on {
    UIView *card = [self card];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"bolt.shield.fill"]];
    icon.tintColor = on ? [ZXTheme primaryText] : [ZXTheme mutedText];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:icon];

    UILabel *title = [self label:[NSString stringWithFormat:@"%@", definition[@"name"] ?: definition[@"title"] ?: fid]
                              size:14 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    title.numberOfLines = 2;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:title];

    NSString *description = [NSString stringWithFormat:@"%@", definition[@"description"] ?: @"Server-managed secure function"];
    UILabel *detail = [self label:description size:11 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    detail.numberOfLines = 0;
    detail.lineBreakMode = NSLineBreakByWordWrapping;
    detail.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:detail];

    UILabel *stateLabel = [self label:on ? @"ACTIVE" : @"READY"
                               size:9 weight:UIFontWeightBold color:on ? [ZXTheme success] : [ZXTheme mutedText]];
    [ZXTheme track:stateLabel spacing:1.0];
    stateLabel.textAlignment = NSTextAlignmentRight;
    stateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:stateLabel];
    self.functionStateLabels[fid] = stateLabel;

    UISwitch *toggle = [[UISwitch alloc] init];
    toggle.onTintColor = [ZXTheme accent];
    toggle.thumbTintColor = [UIColor blackColor];
    toggle.on = on;
    toggle.translatesAutoresizingMaskIntoConstraints = NO;
    [toggle addTarget:self action:@selector(functionToggleChanged:) forControlEvents:UIControlEventValueChanged];
    [card addSubview:toggle];
    self.functionControls[fid] = toggle;

    [NSLayoutConstraint activateConstraints:@[
        [icon.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [icon.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
        [icon.widthAnchor constraintEqualToConstant:20],
        [icon.heightAnchor constraintEqualToConstant:20],
        
        [stateLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [stateLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
        
        [title.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:12],
        [title.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
        [title.trailingAnchor constraintLessThanOrEqualToAnchor:stateLabel.leadingAnchor constant:-10],
        
        [detail.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:6],
        [detail.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        
        [toggle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [toggle.topAnchor constraintEqualToAnchor:detail.bottomAnchor constant:16],
        [toggle.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20]
    ]];
    return card;
}

- (NSString *)functionIdForControl:(UIControl *)control {
    for (NSString *fid in self.functionControls) {
        if (self.functionControls[fid] == control) return fid;
    }
    return nil;
}

- (void)functionToggleChanged:(UISwitch *)sender {
    NSString *fid = [self functionIdForControl:sender];
    if (!fid.length) return;
    BOOL requested = sender.isOn;
    
    sender.userInteractionEnabled = NO;
    UILabel *state = self.functionStateLabels[fid];
    state.textColor = [ZXTheme warning];
    state.text = ZXLocalizedUI(@"PROCESSING");

    __weak typeof(self) weakSelf = self;
    
    void (^finish)(BOOL, NSString *) = ^(BOOL success, NSString *msg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            sender.userInteractionEnabled = YES;
            
            if (success) {
                self.functionStates[fid] = @(requested);
                state.text = ZXLocalizedUI(requested ? @"ACTIVE" : @"READY");
                state.textColor = requested ? [ZXTheme success] : [ZXTheme mutedText];
                [self showToast:ZXLocalizedUI(requested ? @"Function enabled" : @"Function disabled") success:YES];
            } else {
                sender.on = !requested;
                self.functionStates[fid] = @(!requested);
                state.text = ZXLocalizedUI(!requested ? @"ACTIVE" : @"READY");
                state.textColor = !requested ? [ZXTheme success] : [ZXTheme mutedText];
                [self showGlobalErrorWithTitle:ZXLocalizedUI(@"OPERATION FAILED") message:msg ?: ZXLocalizedUI(@"The server could not complete this operation.")];
            }
        });
    };

    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestFunctionOperation:action:completion:)]) {
        [self.delegate zentraxDidRequestFunctionOperation:fid action:requested completion:finish];
    } else if ([self.delegate respondsToSelector:@selector(zentraxDidRequestModuleToggle:state:completion:)]) {
        [self.delegate zentraxDidRequestModuleToggle:fid state:requested completion:finish];
    } else {
        [[ZentraxNetworkManager sharedManager] performModuleOperationWithFunctionId:fid action:(requested ? 2 : 1) completion:^(BOOL success, NSDictionary * _Nullable modulePayload, NSString * _Nullable errorMsg) {
            finish(success, errorMsg);
        }];
    }
}

- (void)updateFunctionState:(NSString *)functionId state:(BOOL)isOn {
    if (!functionId.length) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.functionStates[functionId] = @(ZXIsTruthyValue(@(isOn)));
        UISwitch *toggle = (UISwitch *)self.functionControls[functionId];
        if ([toggle isKindOfClass:[UISwitch class]]) [toggle setOn:isOn animated:YES];
        UILabel *label = self.functionStateLabels[functionId];
        label.text = ZXLocalizedUI(isOn ? @"ACTIVE" : @"READY");
        label.textColor = isOn ? [ZXTheme success] : [ZXTheme mutedText];
    });
}

- (void)updateFunctionStates:(NSDictionary<NSString *,NSNumber *> *)states {
    if (![states isKindOfClass:[NSDictionary class]]) return;
    for (NSString *fid in states) {
        id value = states[fid];
        if (![value respondsToSelector:@selector(boolValue)]) continue;
        [self updateFunctionState:fid state:[value boolValue]];
    }
}

- (void)updateServerBanner:(NSDictionary *)banner {
    // Basic banner handling
}

#pragma mark - Subscription / Time

- (void)updateSubscriptionState:(NSDictionary *)subData {
    if (![subData isKindOfClass:[NSDictionary class]]) return;
    NSString *status = [[NSString stringWithFormat:@"%@", ([subData[@"status"] isKindOfClass:[NSString class]] ? subData[@"status"] : @"unknown")] lowercaseString];
    
    ZXLicenseUIStatus uiStatus = ZXLicenseUIStatusUnknown;
    if ([status isEqualToString:@"unactivated"]) uiStatus = ZXLicenseUIStatusUnactivated;
    else if ([status isEqualToString:@"active"]) uiStatus = ZXLicenseUIStatusActive;
    else if ([status isEqualToString:@"expired"]) uiStatus = ZXLicenseUIStatusExpired;
    else if ([status isEqualToString:@"revoked"]) uiStatus = ZXLicenseUIStatusRevoked;
    else if ([status isEqualToString:@"disabled"]) uiStatus = ZXLicenseUIStatusDisabled;

    NSDate *activated = [self dateFromServerValue:subData[@"activated_at"]];
    NSDate *expires = [self dateFromServerValue:subData[@"expires_at"]];
    BOOL permanent = [subData[@"is_permanent"] boolValue];
    [self updateLicenseStatus:uiStatus activatedAt:activated expiresAt:expires isPermanent:permanent];
}

- (void)updateLicenseStatus:(ZXLicenseUIStatus)status activatedAt:(NSDate *)activatedAt expiresAt:(NSDate *)expiresAt isPermanent:(BOOL)isPermanent {
    self.licenseStatus = status;
    self.activatedAt = activatedAt;
    self.expiresAt = expiresAt;
    self.licensePermanent = isPermanent;
    
    NSString *text = ZXLocalizedUI(@"UNKNOWN");
    UIColor *color = [ZXTheme mutedText];
    switch (status) {
        case ZXLicenseUIStatusUnactivated: text = ZXLocalizedUI(@"UNACTIVATED"); color = [ZXTheme warning]; break;
        case ZXLicenseUIStatusActive: text = ZXLocalizedUI(@"ACTIVE"); color = [ZXTheme success]; break;
        case ZXLicenseUIStatusExpired: text = ZXLocalizedUI(@"EXPIRED"); color = [ZXTheme error]; break;
        case ZXLicenseUIStatusRevoked: text = ZXLocalizedUI(@"REVOKED"); color = [ZXTheme error]; break;
        case ZXLicenseUIStatusDisabled: text = ZXLocalizedUI(@"DISABLED"); color = [ZXTheme error]; break;
        default: break;
    }
    _licenseStatusLabel.text = text;
    _licenseStatusLabel.textColor = color;
    
    if (isPermanent) {
        _countdownLabel.text = ZXLocalizedUI(@"PERMANENT");
        _expiryLabel.text = ZXLocalizedUI(@"Lifetime server entitlement");
    } else if (expiresAt) {
        [self startLicenseCountdown];
        [self refreshLicenseCountdown];
    } else if (status == ZXLicenseUIStatusUnactivated) {
        _countdownLabel.text = ZXLocalizedUI(@"NOT STARTED");
        _expiryLabel.text = ZXLocalizedUI(@"Awaiting first activation");
    }
}

- (NSDate *)dateFromServerValue:(id)value {
    if ([value isKindOfClass:[NSDate class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
    if (![value isKindOfClass:[NSString class]]) return nil;
    NSString *s = value;
    if (!s.length) return nil;
    NSISO8601DateFormatter *f = [[NSISO8601DateFormatter alloc] init];
    NSDate *d = [f dateFromString:s];
    if (d) return d;
    return nil;
}

- (void)updateServerTime:(NSDate *)serverDate {
    if ([serverDate isKindOfClass:[NSDate class]]) self.serverDate = serverDate;
}

- (NSDate *)estimatedServerNow {
    if (self.serverDate) {
        NSDate *reference = objc_getAssociatedObject(self, @selector(estimatedServerNow));
        if (!reference) {
            reference = [NSDate date];
            objc_setAssociatedObject(self, @selector(estimatedServerNow), reference, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:reference];
        return [self.serverDate dateByAddingTimeInterval:MAX(0, elapsed)];
    }
    return [NSDate date];
}

- (void)startLicenseCountdown {
    [self stopLicenseCountdown];
    if (self.licensePermanent || !self.expiresAt) return;
    self.licenseTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshLicenseCountdown) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.licenseTimer forMode:NSRunLoopCommonModes];
}

- (void)stopLicenseCountdown {
    [self.licenseTimer invalidate];
    self.licenseTimer = nil;
}

- (void)refreshLicenseCountdown {
    if (self.licensePermanent) {
        _countdownLabel.text = ZXLocalizedUI(@"PERMANENT");
        return;
    }
    if (!self.expiresAt) return;
    NSTimeInterval remaining = [self.expiresAt timeIntervalSinceDate:[self estimatedServerNow]];
    if (remaining <= 0) {
        _countdownLabel.text = ZXLocalizedUI(@"00:00:00");
        _expiryLabel.text = ZXLocalizedUI(@"EXPIRED");
        _licenseStatusLabel.text = ZXLocalizedUI(@"EXPIRED");
        _licenseStatusLabel.textColor = [ZXTheme error];
        [self stopLicenseCountdown];
        return;
    }
    NSInteger total = (NSInteger)floor(remaining);
    NSInteger days = total / 86400; total %= 86400;
    NSInteger hours = total / 3600; total %= 3600;
    NSInteger minutes = total / 60; NSInteger seconds = total % 60;
    if (days > 0) _countdownLabel.text = [NSString stringWithFormat:@"%ldd %02ldh %02ldm", (long)days, (long)hours, (long)minutes];
    else _countdownLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
    
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.dateStyle = NSDateFormatterMediumStyle;
    f.timeStyle = NSDateFormatterShortStyle;
    _expiryLabel.text = [NSString stringWithFormat:@"Expires %@", [f stringFromDate:self.expiresAt]];
}

#pragma mark - Startup Block & Bootstrap

- (void)setupStartupBlock {
    _startupBlockContainer = [[UIView alloc] init];
    _startupBlockContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_startupBlockContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_startupBlockContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_startupBlockContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_startupBlockContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_startupBlockContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UIView *card = [self card];
    [_startupBlockContainer addSubview:card];
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.shield.fill"]];
    icon.tintColor = [ZXTheme primaryText];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:icon];
    
    _startupBlockTitle = [self label:@"SECURITY GATE" size:20 weight:UIFontWeightBlack color:[ZXTheme primaryText]];
    _startupBlockTitle.textAlignment = NSTextAlignmentCenter;
    _startupBlockTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_startupBlockTitle];
    
    _startupBlockMessage = [self label:@"" size:13 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    _startupBlockMessage.textAlignment = NSTextAlignmentCenter;
    _startupBlockMessage.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_startupBlockMessage];
    
    _startupBlockAction = [UIButton buttonWithType:UIButtonTypeSystem];
    [self styleSecondaryButton:_startupBlockAction];
    [_startupBlockAction setTitle:ZXLocalizedUI(@"RETRY") forState:UIControlStateNormal];
    _startupBlockAction.translatesAutoresizingMaskIntoConstraints = NO;
    [_startupBlockAction addTarget:self action:@selector(startupBlockRetry) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:_startupBlockAction];
    
    [NSLayoutConstraint activateConstraints:@[
        [card.leadingAnchor constraintEqualToAnchor:_startupBlockContainer.leadingAnchor constant:30],
        [card.trailingAnchor constraintEqualToAnchor:_startupBlockContainer.trailingAnchor constant:-30],
        [card.centerYAnchor constraintEqualToAnchor:_startupBlockContainer.centerYAnchor],
        [icon.topAnchor constraintEqualToAnchor:card.topAnchor constant:30],
        [icon.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [icon.widthAnchor constraintEqualToConstant:40],
        [icon.heightAnchor constraintEqualToConstant:40],
        [_startupBlockTitle.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:20],
        [_startupBlockTitle.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [_startupBlockTitle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [_startupBlockMessage.topAnchor constraintEqualToAnchor:_startupBlockTitle.bottomAnchor constant:12],
        [_startupBlockMessage.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [_startupBlockMessage.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [_startupBlockAction.topAnchor constraintEqualToAnchor:_startupBlockMessage.bottomAnchor constant:24],
        [_startupBlockAction.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [_startupBlockAction.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [_startupBlockAction.heightAnchor constraintEqualToConstant:50],
        [_startupBlockAction.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20]
    ]];
}

- (void)showStartupState:(ZXStartupState)state message:(NSString *)message {
    self.startupState = state;
    if (state == ZXStartupStateReady) return;
    if (state == ZXStartupStateBootstrapping) {
        [self transitionToPrimaryContainer:self.splashContainer];
        return;
    }
    [self transitionToPrimaryContainer:self.startupBlockContainer];
    self.blockedState = state;
    NSString *title = @"SECURITY GATE";
    NSString *action = @"RETRY";
    switch (state) {
        case ZXStartupStateMaintenance: title = @"MAINTENANCE"; action = @"CHECK AGAIN"; break;
        case ZXStartupStateVersionMismatch: title = @"UPDATE REQUIRED"; action = @"CHECK AGAIN"; break;
        case ZXStartupStateIncompatible: title = @"DEVICE UNSUPPORTED"; action = @"RECHECK DEVICE"; break;
        case ZXStartupStateConnectionError: title = @"CONNECTION LOST"; action = @"RETRY"; break;
        default: break;
    }
    _startupBlockTitle.text = ZXLocalizedUI(title);
    _startupBlockMessage.text = message.length ? message : ZXLocalizedUI(@"The server did not permit the secure workspace to open.");
    [_startupBlockAction setTitle:ZXLocalizedUI(action) forState:UIControlStateNormal];
}

- (void)handleBootstrapState:(ZXStartupState)state message:(NSString *)message {
    self.startupState = state;
    if (state == ZXStartupStateReady) {
        [self runPremiumSplashCompletion:^{ [self completeStartupRouting]; }];
    } else {
        [self runPremiumSplashCompletion:^{ [self showStartupState:state message:message]; }];
    }
}

- (void)completeStartupRouting {
    NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *key = [globalDefaults stringForKey:ZXLastKey];
    if (key.length > 0) {
        if ([self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) {
            __weak typeof(self) weakSelf = self;
            [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL valid) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) self = weakSelf; if (!self) return;
                    if (valid) [self showDashboard]; else [self showLoginScreen];
                });
            }];
        } else {
            [[ZentraxNetworkManager sharedManager] verifySessionWithCompletion:^(BOOL valid, NSDictionary * _Nullable responseData, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (valid) [self showDashboard]; else [self showLoginScreen];
                });
            }];
        }
    } else {
        [self showLoginScreen];
    }
}

- (void)startupBlockRetry {
    if (self.blockedState == ZXStartupStateIncompatible) [self requestDeviceCompatibilityRecheck];
    else [self beginBootstrap];
}

- (void)beginBootstrap {
    if (self.safeModeEnabled) { [self showSafeModeLockScreen]; return; }
    self.startupState = ZXStartupStateBootstrapping;
    [self showStartupState:ZXStartupStateBootstrapping message:nil];

    __weak typeof(self) weakSelf = self;
    [[ZentraxNetworkManager sharedManager] bootstrapWithCompletion:^(BOOL success, NSDictionary * _Nullable response, ZXBootstrapState bootstrapState, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        ZXStartupState state = ZXStartupStateConnectionError;
        switch (bootstrapState) {
            case ZXBootstrapStateReady: state = ZXStartupStateReady; break;
            case ZXBootstrapStateMaintenance: state = ZXStartupStateMaintenance; break;
            case ZXBootstrapStateVersionMismatch: state = ZXStartupStateVersionMismatch; break;
            case ZXBootstrapStateIncompatible: state = ZXStartupStateIncompatible; break;
            case ZXBootstrapStateConnectionError: state = ZXStartupStateConnectionError; break;
            default: state = success ? ZXStartupStateReady : ZXStartupStateConnectionError; break;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([response isKindOfClass:[NSDictionary class]] && response.count) {
                id serverTime=response[@"server_time"] ?: response[@"server_iso"];
                if (!serverTime && [response[@"server"] isKindOfClass:[NSDictionary class]]) {
                    serverTime = response[@"server"][@"time"];
                }
                NSDate *d=[self dateFromServerValue:serverTime];
                if (d) [self updateServerTime:d];
                
                NSDictionary *config = response[@"configuration"] ?: response[@"config"];
                if ([config isKindOfClass:[NSDictionary class]]) [self updateDashboardWithConfiguration:config];
                
                NSDictionary *license = response[@"license"];
                if ([license isKindOfClass:[NSDictionary class]]) [self updateSubscriptionState:license];
                
                NSDictionary *compat = response[@"compatibility"];
                if ([compat isKindOfClass:[NSDictionary class]]) [self updateDeviceCompatibility:compat];
            }
            NSString *message=[errorMsg isKindOfClass:[NSString class]] ? errorMsg : nil;
            if (!message.length && [response isKindOfClass:[NSDictionary class]]) {
                id responseMessage=response[@"message"];
                if ([responseMessage isKindOfClass:[NSString class]]) message=responseMessage;
            }
            [self handleBootstrapState:state message:message];
        });
    }];
}

#pragma mark - Heartbeat

- (void)startHeartbeatMonitor {
    [self stopHeartbeatMonitor];
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(heartbeatTick) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.heartbeatTimer forMode:NSRunLoopCommonModes];
    _connectionLabel.text = ZXLocalizedUI(@"● SECURE");
    _connectionLabel.textColor = [ZXTheme success];
}

- (void)stopHeartbeatMonitor { [self.heartbeatTimer invalidate]; self.heartbeatTimer = nil; }

- (void)heartbeatTick {
    if (self.currentState != ZXAppStateDashboard) return;
    __weak typeof(self) weakSelf = self;
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) {
        [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL valid) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf; if (!self) return;
                if (!valid) [self handleRevokedSessionEnvironment];
                else { self.connectionLabel.text = ZXLocalizedUI(@"● SECURE"); self.connectionLabel.textColor = [ZXTheme success]; }
            });
        }];
    } else {
        [[ZentraxNetworkManager sharedManager] verifySessionWithCompletion:^(BOOL valid, NSDictionary * _Nullable responseData, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf; if (!self) return;
                if (!valid) [self handleRevokedSessionEnvironment];
                else { self.connectionLabel.text = ZXLocalizedUI(@"● SECURE"); self.connectionLabel.textColor = [ZXTheme success]; }
            });
        }];
    }
}

- (void)handleRevokedSessionEnvironment {
    [self stopHeartbeatMonitor];
    _connectionLabel.text = ZXLocalizedUI(@"● OFFLINE"); _connectionLabel.textColor = [ZXTheme error];
    for (NSString *fid in self.functionControls) ((UIControl *)self.functionControls[fid]).userInteractionEnabled = NO;
    [self showGlobalErrorWithTitle:ZXLocalizedUI(@"SESSION ENDED") message:ZXLocalizedUI(@"Your secure session is no longer valid. Please authenticate again.")];
    
    __weak typeof(self) weakSelf = self;
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) {
        [self.delegate zentraxDidRequestLogoutWithCompletion:^{ dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf showLoginScreen]; }); }];
    } else {
        [[ZentraxNetworkManager sharedManager] logout];
        NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
        [globalDefaults removeObjectForKey:ZXLastKey];
        [globalDefaults synchronize];
        [self showLoginScreen];
    }
}

#pragma mark - Settings

- (void)setupSettingsScreen {
    if (_settingsContainer) [_settingsContainer removeFromSuperview];
    
    _settingsContainer = [[UIView alloc] init];
    _settingsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_settingsContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_settingsContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_settingsContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_settingsContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_settingsContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UIView *header = [[UIView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [_settingsContainer addSubview:header];
    
    UIButton *back = [self iconButton:@"chevron.left" size:34];
    [back addTarget:self action:@selector(closeSettings) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:back];
    
    UILabel *settingsTitle = [self label:@"Settings" size:22 weight:UIFontWeightBold color:[ZXTheme primaryText]];
    settingsTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:settingsTitle];
    
    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:_settingsContainer.leadingAnchor constant:20],
        [header.trailingAnchor constraintEqualToAnchor:_settingsContainer.trailingAnchor constant:-20],
        [header.topAnchor constraintEqualToAnchor:_settingsContainer.safeAreaLayoutGuide.topAnchor constant:10],
        [header.heightAnchor constraintEqualToConstant:44],
        [back.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [back.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [settingsTitle.leadingAnchor constraintEqualToAnchor:back.trailingAnchor constant:10],
        [settingsTitle.centerYAnchor constraintEqualToAnchor:header.centerYAnchor]
    ]];

    _settingsScroll = [[UIScrollView alloc] init];
    _settingsScroll.showsVerticalScrollIndicator = NO;
    _settingsScroll.translatesAutoresizingMaskIntoConstraints = NO;
    [_settingsContainer addSubview:_settingsScroll];
    
    _settingsStack = [[UIStackView alloc] init];
    _settingsStack.axis = UILayoutConstraintAxisVertical;
    _settingsStack.spacing = 14;
    _settingsStack.translatesAutoresizingMaskIntoConstraints = NO;
    [_settingsScroll addSubview:_settingsStack];
    
    [NSLayoutConstraint activateConstraints:@[
        [_settingsScroll.leadingAnchor constraintEqualToAnchor:_settingsContainer.leadingAnchor constant:24],
        [_settingsScroll.trailingAnchor constraintEqualToAnchor:_settingsContainer.trailingAnchor constant:-24],
        [_settingsScroll.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:20],
        [_settingsScroll.bottomAnchor constraintEqualToAnchor:_settingsContainer.bottomAnchor],
        [_settingsStack.leadingAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.leadingAnchor],
        [_settingsStack.trailingAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.trailingAnchor],
        [_settingsStack.topAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.topAnchor],
        [_settingsStack.bottomAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.bottomAnchor constant:-40],
        [_settingsStack.widthAnchor constraintEqualToAnchor:_settingsScroll.frameLayoutGuide.widthAnchor]
    ]];
    [self rebuildSettings];
}

- (UIView *)settingsRow:(NSString *)title subtitle:(NSString *)subtitle icon:(NSString *)iconName action:(SEL)action accessory:(UIView *)accessory {
    UIView *row = [self card];
    
    UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:iconName]];
    iv.tintColor = [ZXTheme primaryText];
    iv.translatesAutoresizingMaskIntoConstraints = NO;
    [row addSubview:iv];
    
    UILabel *t = [self label:title size:14 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    t.translatesAutoresizingMaskIntoConstraints = NO;
    [row addSubview:t];
    
    UILabel *s = [self label:subtitle size:11 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    s.numberOfLines = 0;
    s.translatesAutoresizingMaskIntoConstraints = NO;
    [row addSubview:s];
    
    [NSLayoutConstraint activateConstraints:@[
        [row.heightAnchor constraintGreaterThanOrEqualToConstant:76],
        [iv.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:20],
        [iv.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [iv.widthAnchor constraintEqualToConstant:24],
        [iv.heightAnchor constraintEqualToConstant:24],
        [t.leadingAnchor constraintEqualToAnchor:iv.trailingAnchor constant:14],
        [t.topAnchor constraintEqualToAnchor:row.topAnchor constant:18],
        [t.trailingAnchor constraintLessThanOrEqualToAnchor:row.trailingAnchor constant:-65],
        [s.leadingAnchor constraintEqualToAnchor:t.leadingAnchor],
        [s.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:4],
        [s.trailingAnchor constraintLessThanOrEqualToAnchor:row.trailingAnchor constant:-65],
        [s.bottomAnchor constraintLessThanOrEqualToAnchor:row.bottomAnchor constant:-18]
    ]];
    
    if (accessory) {
        accessory.translatesAutoresizingMaskIntoConstraints = NO;
        [row addSubview:accessory];
        [NSLayoutConstraint activateConstraints:@[
            [accessory.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-20],
            [accessory.centerYAnchor constraintEqualToAnchor:row.centerYAnchor]
        ]];
    } else {
        UIImageView *chev = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
        chev.tintColor = [ZXTheme mutedText];
        chev.translatesAutoresizingMaskIntoConstraints = NO;
        [row addSubview:chev];
        [NSLayoutConstraint activateConstraints:@[
            [chev.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-20],
            [chev.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
            [chev.widthAnchor constraintEqualToConstant:14],
            [chev.heightAnchor constraintEqualToConstant:16]
        ]];
    }
    
    if (action) {
        UIButton *hit = [UIButton buttonWithType:UIButtonTypeSystem];
        hit.translatesAutoresizingMaskIntoConstraints = NO;
        [hit addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
        [row addSubview:hit];
        [NSLayoutConstraint activateConstraints:@[
            [hit.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],
            [hit.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],
            [hit.topAnchor constraintEqualToAnchor:row.topAnchor],
            [hit.bottomAnchor constraintEqualToAnchor:row.bottomAnchor]
        ]];
    }
    return row;
}

- (void)rebuildSettings {
    for (UIView *v in [self.settingsStack.arrangedSubviews copy]) {
        [self.settingsStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    
    UILabel *secLabel = [self label:@"SECURITY" size:10 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:secLabel spacing:1.5];
    [self.settingsStack addArrangedSubview:secLabel];
    
    UISwitch *safe = [[UISwitch alloc] init];
    safe.onTintColor = [ZXTheme accent];
    safe.thumbTintColor = [UIColor blackColor];
    safe.on = self.safeModeEnabled;
    [safe addTarget:self action:@selector(safeModeSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.settingsStack addArrangedSubview:[self settingsRow:@"Safe UI Mode" subtitle:safe.isOn ? @"Protected lock screen is enabled" : @"Add a private six-digit lock screen" icon:@"lock.fill" action:nil accessory:safe]];

    UILabel *devLabel = [self label:@"DEVICE" size:10 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:devLabel spacing:1.5];
    [self.settingsStack addArrangedSubview:devLabel];
    
    [self.settingsStack addArrangedSubview:[self buildDeviceCard]];

    UILabel *prefLabel = [self label:@"PREFERENCES" size:10 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:prefLabel spacing:1.5];
    [self.settingsStack addArrangedSubview:prefLabel];
    
    NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *language = [globalDefaults stringForKey:ZXLanguageKey] ?: @"English";
    [self.settingsStack addArrangedSubview:[self settingsRow:@"Language" subtitle:language icon:@"globe" action:@selector(showLanguagePicker) accessory:nil]];
    
    NSString *theme = [ZXTheme currentTheme];
    [self.settingsStack addArrangedSubview:[self settingsRow:@"Appearance" subtitle:[NSString stringWithFormat:@"%@ • Pure black premium interface", theme] icon:@"circle.lefthalf.filled" action:@selector(showThemePicker) accessory:nil]];

    UILabel *accLabel = [self label:@"ACCOUNT" size:10 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:accLabel spacing:1.5];
    [self.settingsStack addArrangedSubview:accLabel];
    [self.settingsStack addArrangedSubview:[self settingsRow:@"Sign Out" subtitle:@"Close the current secure session" icon:@"rectangle.portrait.and.arrow.right" action:@selector(handleLogout) accessory:nil]];
    
    [self applyCurrentLanguageToView:self.settingsStack];
}

- (UIView *)buildDeviceCard {
    UIView *card = [self card];
    
    NSString *device = ZXSafeString(self.compatibilityData[@"device_name"], UIDevice.currentDevice.model);
    NSString *ios = ZXSafeString(self.compatibilityData[@"ios_version"], UIDevice.currentDevice.systemVersion);
    NSString *statusValue = [[NSString stringWithFormat:@"%@", self.compatibilityData[@"status"] ?: @"unknown"] lowercaseString];
    
    BOOL supported = [statusValue isEqualToString:@"supported"] || [statusValue isEqualToString:@"compatible"];
    BOOL unsupported = [statusValue isEqualToString:@"unsupported"];
    NSString *statusText = supported ? @"SUPPORTED" : (unsupported ? @"UNSUPPORTED" : @"AWAITING VERIFICATION");
    UIColor *statusColor = supported ? [ZXTheme success] : (unsupported ? [ZXTheme error] : [ZXTheme warning]);

    UILabel *nameLabel = [self label:device size:16 weight:UIFontWeightBold color:[ZXTheme primaryText]];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:nameLabel];
    
    UILabel *iosLabel = [self label:[NSString stringWithFormat:@"iOS %@", ios] size:12 weight:UIFontWeightMedium color:[ZXTheme secondaryText]];
    iosLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:iosLabel];
    
    UILabel *statusLbl = [self label:statusText size:9 weight:UIFontWeightBold color:statusColor];
    [ZXTheme track:statusLbl spacing:1.0];
    statusLbl.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:statusLbl];
    
    NSString *reason = ZXSafeString(self.compatibilityData[@"reason"], supported ? @"Verified by server" : @"Check device compatibility");
    UILabel *descLabel = [self label:reason size:11 weight:UIFontWeightRegular color:[ZXTheme mutedText]];
    descLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:descLabel];
    
    UIButton *recheck = [UIButton buttonWithType:UIButtonTypeSystem];
    [self styleSecondaryButton:recheck];
    [recheck setTitle:ZXLocalizedUI(@"RECHECK") forState:UIControlStateNormal];
    recheck.translatesAutoresizingMaskIntoConstraints = NO;
    [recheck addTarget:self action:@selector(requestDeviceCompatibilityRecheck) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:recheck];
    
    [NSLayoutConstraint activateConstraints:@[
        [card.heightAnchor constraintGreaterThanOrEqualToConstant:140],
        [nameLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [nameLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
        [iosLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [iosLabel.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:4],
        [statusLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [statusLbl.centerYAnchor constraintEqualToAnchor:nameLabel.centerYAnchor],
        [descLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [descLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [descLabel.topAnchor constraintEqualToAnchor:iosLabel.bottomAnchor constant:12],
        [recheck.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [recheck.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [recheck.topAnchor constraintEqualToAnchor:descLabel.bottomAnchor constant:16],
        [recheck.heightAnchor constraintEqualToConstant:40],
        [recheck.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20]
    ]];
    
    return card;
}

- (void)showSettingsSection:(NSString *)sectionIdentifier {
    [self showSettings];
}

- (void)showSettings {
    if (self.safeModeEnabled && self.safeModeState != ZXSafeModeStateUnlocked) { [self showSafeModeLockScreen]; return; }
    self.settingsVisible = YES;
    [self setupSettingsScreen];
    [self transitionToPrimaryContainer:self.settingsContainer];
}
- (void)closeSettings { self.settingsVisible = NO; [self showDashboard]; }

#pragma mark - Safe UI Mode (Native Numpad)

- (void)applyInitialSafeModeState {
    NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    self.safeModeEnabled = [globalDefaults boolForKey:ZXSafeModeEnabledKey];
    self.safeModeState = self.safeModeEnabled ? ZXSafeModeStateLocked : ZXSafeModeStateOff;
}

- (void)updateSafeModeState:(ZXSafeModeState)state {
    self.safeModeState = state;
    self.safeModeEnabled = (state != ZXSafeModeStateOff);
    NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    [globalDefaults setBool:self.safeModeEnabled forKey:ZXSafeModeEnabledKey];
    [globalDefaults synchronize];
    if (self.settingsVisible) [self rebuildSettings];
}

- (BOOL)saveGlobalPIN:(NSString *)pin {
    NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    [globalDefaults setObject:pin forKey:ZXSafeModePasscodeAccount];
    return [globalDefaults synchronize];
}

- (NSString *)getGlobalPIN {
    NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    return [globalDefaults stringForKey:ZXSafeModePasscodeAccount];
}

- (void)deleteGlobalPIN {
    NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    [globalDefaults removeObjectForKey:ZXSafeModePasscodeAccount];
    [globalDefaults synchronize];
}

- (void)safeModeSwitchChanged:(UISwitch *)sender {
    if (sender.isOn) {
        self.safeModeCreatingPasscode = YES;
        self.pendingSafeModePasscode = nil;
        [self updateSafeModeState:ZXSafeModeStateOff];
        [self showSafeModeLockScreen];
    } else {
        sender.on = YES;
        self.safeModeCreatingPasscode = NO;
        self.safeModeDisabling = YES;
        [self showSafeModeLockScreen];
    }
}

- (void)showSafeModeSettings {
    if (self.safeModeEnabled) { [self showSafeModeLockScreen]; return; }
    self.safeModeCreatingPasscode = YES;
    self.pendingSafeModePasscode = nil;
    [self updateSafeModeState:ZXSafeModeStateOff];
    [self showSafeModeLockScreen];
}

- (void)lockSafeMode {
    if (!self.safeModeEnabled) return;
    [self updateSafeModeState:ZXSafeModeStateLocked];
    [self showSafeModeLockScreen];
}

- (void)unlockSafeMode {
    if (!self.safeModeEnabled) return;
    [self updateSafeModeState:ZXSafeModeStateUnlocked];
}

- (void)setupSafeModeLock {
    _safeLockContainer = [[UIView alloc] init];
    _safeLockContainer.translatesAutoresizingMaskIntoConstraints = NO;
    _safeLockContainer.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_safeLockContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_safeLockContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_safeLockContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_safeLockContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_safeLockContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    _safeLockBackButton = [self iconButton:@"chevron.left" size:34];
    _safeLockBackButton.hidden = YES;
    [_safeLockBackButton addTarget:self action:@selector(cancelSafeModeAction) forControlEvents:UIControlEventTouchUpInside];
    [_safeLockContainer addSubview:_safeLockBackButton];

    _safeLockTitle = [self label:@"Enter Passcode" size:22 weight:UIFontWeightBold color:[ZXTheme primaryText]];
    _safeLockTitle.textAlignment = NSTextAlignmentCenter;
    _safeLockTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [_safeLockContainer addSubview:_safeLockTitle];

    _safeLockSubtitle = [self label:@"Enter your private 6-digit passcode" size:13 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    _safeLockSubtitle.textAlignment = NSTextAlignmentCenter;
    _safeLockSubtitle.translatesAutoresizingMaskIntoConstraints = NO;
    [_safeLockContainer addSubview:_safeLockSubtitle];

    _safePinError = [self label:@"" size:12 weight:UIFontWeightMedium color:[ZXTheme error]];
    _safePinError.textAlignment = NSTextAlignmentCenter;
    _safePinError.translatesAutoresizingMaskIntoConstraints = NO;
    [_safeLockContainer addSubview:_safePinError];

    _pinBoxes = [[UIStackView alloc] init];
    _pinBoxes.axis = UILayoutConstraintAxisHorizontal;
    _pinBoxes.spacing = 16;
    _pinBoxes.distribution = UIStackViewDistributionFillEqually;
    _pinBoxes.translatesAutoresizingMaskIntoConstraints = NO;
    [_safeLockContainer addSubview:_pinBoxes];
    for (NSInteger i = 0; i < 6; i++) {
        UIView *box = [[UIView alloc] init];
        box.layer.cornerRadius = 8;
        box.layer.borderWidth = 1.0;
        box.layer.borderColor = [ZXTheme border].CGColor;
        box.backgroundColor = [ZXTheme surface];
        [_pinBoxes addArrangedSubview:box];
        [box.widthAnchor constraintEqualToConstant:16].active = YES;
        [box.heightAnchor constraintEqualToConstant:16].active = YES;
    }

    _safePINInput = [[UITextField alloc] init];
    _safePINInput.keyboardType = UIKeyboardTypeNumberPad;
    _safePINInput.secureTextEntry = YES;
    _safePINInput.textColor = [UIColor clearColor];
    _safePINInput.tintColor = [UIColor clearColor];
    _safePINInput.backgroundColor = [UIColor clearColor];
    _safePINInput.translatesAutoresizingMaskIntoConstraints = NO;
    [_safePINInput addTarget:self action:@selector(safePINInputChanged:) forControlEvents:UIControlEventEditingChanged];
    [_safeLockContainer addSubview:_safePINInput];

    [NSLayoutConstraint activateConstraints:@[
        [_safeLockBackButton.leadingAnchor constraintEqualToAnchor:_safeLockContainer.leadingAnchor constant:20],
        [_safeLockBackButton.topAnchor constraintEqualToAnchor:_safeLockContainer.safeAreaLayoutGuide.topAnchor constant:10],
        [_safeLockTitle.topAnchor constraintEqualToAnchor:_safeLockContainer.safeAreaLayoutGuide.topAnchor constant:120],
        [_safeLockTitle.leadingAnchor constraintEqualToAnchor:_safeLockContainer.leadingAnchor constant:20],
        [_safeLockTitle.trailingAnchor constraintEqualToAnchor:_safeLockContainer.trailingAnchor constant:-20],
        [_safeLockSubtitle.topAnchor constraintEqualToAnchor:_safeLockTitle.bottomAnchor constant:10],
        [_safeLockSubtitle.leadingAnchor constraintEqualToAnchor:_safeLockContainer.leadingAnchor constant:20],
        [_safeLockSubtitle.trailingAnchor constraintEqualToAnchor:_safeLockContainer.trailingAnchor constant:-20],
        [_safePinError.topAnchor constraintEqualToAnchor:_safeLockSubtitle.bottomAnchor constant:10],
        [_safePinError.leadingAnchor constraintEqualToAnchor:_safeLockContainer.leadingAnchor constant:20],
        [_safePinError.trailingAnchor constraintEqualToAnchor:_safeLockContainer.trailingAnchor constant:-20],
        [_pinBoxes.topAnchor constraintEqualToAnchor:_safePinError.bottomAnchor constant:30],
        [_pinBoxes.centerXAnchor constraintEqualToAnchor:_safeLockContainer.centerXAnchor],
        [_safePINInput.centerXAnchor constraintEqualToAnchor:_safeLockContainer.centerXAnchor],
        [_safePINInput.topAnchor constraintEqualToAnchor:_safeLockContainer.topAnchor],
        [_safePINInput.widthAnchor constraintEqualToConstant:1],
        [_safePINInput.heightAnchor constraintEqualToConstant:1]
    ]];
}

- (void)showSafeModeLockScreen {
    self.enteredPIN.string = @"";
    self.safePINInput.text = @"";
    self.safeModeAttemptsRemaining = ZXMaxPINAttempts;
    self.safePinError.text = @"";
    [self updatePINBoxes];
    
    if (self.safeModeCreatingPasscode) {
        self.safeLockTitle.text = ZXLocalizedUI(@"Create Passcode");
        self.safeLockSubtitle.text = ZXLocalizedUI(@"Create a 6-digit private passcode");
        self.safeLockBackButton.hidden = NO;
    } else if (self.safeModeDisabling) {
        self.safeLockTitle.text = ZXLocalizedUI(@"Disable Safe UI");
        self.safeLockSubtitle.text = ZXLocalizedUI(@"Enter passcode to disable");
        self.safeLockBackButton.hidden = NO;
    } else {
        self.safeLockTitle.text = ZXLocalizedUI(@"Private Space");
        self.safeLockSubtitle.text = ZXLocalizedUI(@"Enter passcode");
        self.safeLockBackButton.hidden = YES;
    }
    
    [self transitionToPrimaryContainer:self.safeLockContainer];
    self.currentState = ZXAppStateStartupBlock;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.safeLockContainer.hidden) {
            [self.safePINInput becomeFirstResponder];
        }
    });
}

- (void)cancelSafeModeAction {
    self.safeModeCreatingPasscode = NO;
    self.safeModeDisabling = NO;
    self.pendingSafeModePasscode = nil;
    [self.safePINInput resignFirstResponder];
    [self showSettings];
}

- (void)safePINInputChanged:(UITextField *)textField {
    NSString *raw = textField.text ?: @"";
    NSMutableString *digits = [NSMutableString stringWithCapacity:6];
    for (NSUInteger i = 0; i < raw.length && digits.length < 6; i++) {
        unichar c = [raw characterAtIndex:i];
        if (c >= '0' && c <= '9') [digits appendFormat:@"%C", c];
    }
    textField.text = digits;
    self.enteredPIN.string = digits;
    [self updatePINBoxes];
    if (digits.length == 6) {
        [self processEnteredPIN];
    }
}

- (void)updatePINBoxes {
    for (NSInteger i=0;i<6;i++) {
        UIView *box = [self.pinBoxes.arrangedSubviews objectAtIndex:i];
        if (i < self.enteredPIN.length) {
            box.backgroundColor = [ZXTheme accent];
            box.layer.borderColor = [ZXTheme accent].CGColor;
        } else {
            box.backgroundColor = [ZXTheme surface];
            box.layer.borderColor = [ZXTheme border].CGColor;
        }
    }
}

- (void)processEnteredPIN {
    if (self.safeModeCreatingPasscode) {
        if (!self.pendingSafeModePasscode.length) {
            self.pendingSafeModePasscode = [self.enteredPIN copy];
            self.enteredPIN.string = @"";
            self.safePINInput.text = @"";
            self.safeLockTitle.text = ZXLocalizedUI(@"Confirm Passcode");
            self.safeLockSubtitle.text = ZXLocalizedUI(@"Enter the same 6-digit passcode again");
            [self updatePINBoxes];
            return;
        }
        if (![self.pendingSafeModePasscode isEqualToString:self.enteredPIN]) {
            self.safePinError.text = ZXLocalizedUI(@"Passcodes do not match. Try again.");
            self.pendingSafeModePasscode = nil;
            self.enteredPIN.string = @"";
            self.safePINInput.text = @"";
            [self updatePINBoxes];
            [self shakePINBoxes];
            return;
        }
        [self saveGlobalPIN:self.enteredPIN];
        self.safeModeCreatingPasscode = NO;
        self.pendingSafeModePasscode = nil;
        [self.safePINInput resignFirstResponder];
        [self updateSafeModeState:ZXSafeModeStateUnlocked];
        [self showToast:ZXLocalizedUI(@"Safe UI Mode enabled") success:YES];
        [self showSettings];
        return;
    }

    NSString *saved = [self getGlobalPIN];
    if (saved.length && [saved isEqualToString:self.enteredPIN]) {
        [self.safePINInput resignFirstResponder];
        if (self.safeModeDisabling) {
            self.safeModeDisabling = NO;
            [self deleteGlobalPIN];
            [self updateSafeModeState:ZXSafeModeStateOff];
            [self showToast:ZXLocalizedUI(@"Safe UI Mode disabled") success:YES];
            [self showSettings];
        } else {
            [self updateSafeModeState:ZXSafeModeStateUnlocked];
            [self showDashboard];
        }
        return;
    }
    
    self.safeModeAttemptsRemaining = MAX(0, self.safeModeAttemptsRemaining - 1);
    self.safePinError.text = self.safeModeAttemptsRemaining > 0 ? [NSString stringWithFormat:@"Incorrect passcode • %ld attempts remaining", (long)self.safeModeAttemptsRemaining] : @"Incorrect passcode";
    self.enteredPIN.string = @"";
    self.safePINInput.text = @"";
    [self updatePINBoxes];
    [self shakePINBoxes];
}

- (void)shakePINBoxes {
    [UIView animateKeyframesWithDuration:0.35 delay:0 options:0 animations:^{
        self.pinBoxes.transform = CGAffineTransformMakeTranslation(-10,0);
        [UIView addKeyframeWithRelativeStartTime:0.20 relativeDuration:0.25 animations:^{ self.pinBoxes.transform = CGAffineTransformMakeTranslation(10,0); }];
        [UIView addKeyframeWithRelativeStartTime:0.45 relativeDuration:0.25 animations:^{ self.pinBoxes.transform = CGAffineTransformIdentity; }];
    } completion:nil];
    [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeError];
}

#pragma mark - Screen Capture Protection

- (void)registerPrivacyObservers {
    NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(updatePrivacyCaptureState) name:UIScreenCapturedDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [nc addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)appWillResignActive:(NSNotification *)note {
    if (self.safeModeEnabled) [self updateSafeModeState:ZXSafeModeStateLocked];
}
- (void)appDidBecomeActive:(NSNotification *)note {
    if (self.safeModeEnabled && self.safeModeState == ZXSafeModeStateLocked && !self.safeLockContainer.hidden) {
        [self.safePINInput becomeFirstResponder];
    }
    [self updatePrivacyCaptureState];
}

- (void)updatePrivacyCaptureState {
    BOOL captured = [UIScreen mainScreen].isCaptured;
    if (captured) [self showPrivacyOverlay];
    else if (!captured && self.privacyOverlayPresented) [self hidePrivacyOverlay];
}

- (void)showPrivacyOverlay {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.privacyOverlay) {
            self.privacyOverlay = [[UIView alloc] initWithFrame:self.view.bounds];
            self.privacyOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.privacyOverlay.backgroundColor = [UIColor blackColor];
            self.privacyOverlay.layer.zPosition = 30000;

            UIImageView *shield = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"eye.slash.fill"]];
            shield.tintColor = [UIColor whiteColor];
            shield.contentMode = UIViewContentModeScaleAspectFit;
            shield.translatesAutoresizingMaskIntoConstraints = NO;
            [self.privacyOverlay addSubview:shield];

            UILabel *title = [self label:@"Close screen sharing app" size:22 weight:UIFontWeightBold color:[UIColor whiteColor]];
            title.textAlignment = NSTextAlignmentCenter;
            title.translatesAutoresizingMaskIntoConstraints = NO;
            [self.privacyOverlay addSubview:title];

            UILabel *message = [self label:@"Screen sharing apps can be used by fraudsters to record your screen and steal your wallet information" size:14 weight:UIFontWeightRegular color:[UIColor lightGrayColor]];
            message.textAlignment = NSTextAlignmentCenter;
            message.numberOfLines = 0;
            message.translatesAutoresizingMaskIntoConstraints = NO;
            [self.privacyOverlay addSubview:message];

            [NSLayoutConstraint activateConstraints:@[
                [shield.centerXAnchor constraintEqualToAnchor:self.privacyOverlay.centerXAnchor],
                [shield.centerYAnchor constraintEqualToAnchor:self.privacyOverlay.centerYAnchor constant:-60],
                [shield.widthAnchor constraintEqualToConstant:48],
                [shield.heightAnchor constraintEqualToConstant:48],
                [title.topAnchor constraintEqualToAnchor:shield.bottomAnchor constant:24],
                [title.leadingAnchor constraintEqualToAnchor:self.privacyOverlay.leadingAnchor constant:30],
                [title.trailingAnchor constraintEqualToAnchor:self.privacyOverlay.trailingAnchor constant:-30],
                [message.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:12],
                [message.leadingAnchor constraintEqualToAnchor:self.privacyOverlay.leadingAnchor constant:40],
                [message.trailingAnchor constraintEqualToAnchor:self.privacyOverlay.trailingAnchor constant:-40]
            ]];
            [self applyCurrentLanguageToView:self.privacyOverlay];
        }
        if (!self.privacyOverlay.superview) [self.view addSubview:self.privacyOverlay];
        self.privacyOverlayPresented = YES;
        self.privacyOverlay.alpha = 1.0;
    });
}
- (void)hidePrivacyOverlay { dispatch_async(dispatch_get_main_queue(), ^{ [UIView animateWithDuration:0.2 animations:^{ self.privacyOverlay.alpha = 0; } completion:^(BOOL f){ [self.privacyOverlay removeFromSuperview]; self.privacyOverlayPresented=NO; }]; }); }

#pragma mark - Language & Theme Pickers

- (void)showLanguagePicker {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:ZXLocalizedUI(@"Choose your language") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *langs = @[@"English", @"Tiếng Việt", @"简体中文"];
    for (NSString *lang in langs) {
        [alert addAction:[UIAlertAction actionWithTitle:lang style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
            [globalDefaults setObject:lang forKey:ZXLanguageKey];
            [globalDefaults synchronize];
            [self applyCurrentLanguageToView:self.view];
            [self rebuildSettings];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:ZXLocalizedUI(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showThemePicker {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:ZXLocalizedUI(@"Appearance") message:ZXLocalizedUI(@"Choose a premium color profile") preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *themes = @[@"Obsidian Black", @"Carbon Silver", @"Midnight Graphite", @"Stealth Mono"];
    for (NSString *theme in themes) {
        [alert addAction:[UIAlertAction actionWithTitle:theme style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
            [globalDefaults setObject:theme forKey:ZXThemeKey];
            [globalDefaults synchronize];
            [self setupSettingsScreen];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:ZXLocalizedUI(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)applyCurrentLanguageToView:(UIView *)view {
    if (!view) return;
    for (UIView *subview in [view.subviews copy]) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            NSString *translated = ZXLocalizedUI(label.text);
            if (translated.length) label.text = translated;
        } else if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            NSString *title = [button titleForState:UIControlStateNormal];
            NSString *translated = ZXLocalizedUI(title);
            if (translated.length) [button setTitle:translated forState:UIControlStateNormal];
        }
        [self applyCurrentLanguageToView:subview];
    }
}

- (void)showDeviceCompatibilityDetails {
    // Info directly visible in card now
}

- (void)requestDeviceCompatibilityRecheck {
    [self showGlobalLoadingState:@"CHECKING DEVICE"];
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestCompatibilityRecheckWithCompletion:)]) {
        __weak typeof(self) weakSelf = self;
        [self.delegate zentraxDidRequestCompatibilityRecheckWithCompletion:^(BOOL success, NSDictionary *compatibility, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf; if (!self) return;
                [self hideGlobalLoadingState];
                if (success) {
                    [self updateDeviceCompatibility:compatibility ?: @{}];
                    [self showToast:ZXLocalizedUI(@"Compatibility Verified") success:YES];
                } else {
                    [self showGlobalErrorWithTitle:ZXLocalizedUI(@"CHECK FAILED") message:errorMsg ?: ZXLocalizedUI(@"Unable to verify device.")];
                }
            });
        }];
    } else {
        [[ZentraxNetworkManager sharedManager] checkDeviceCompatibilityWithCompletion:^(BOOL success, NSDictionary * _Nullable compatibilityData, ZXDeviceCompatibilityStatus status, NSString * _Nullable errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideGlobalLoadingState];
                if (success) {
                    [self updateDeviceCompatibility:compatibilityData ?: @{}];
                    [self showToast:ZXLocalizedUI(@"Compatibility Verified") success:YES];
                } else {
                    [self showGlobalErrorWithTitle:ZXLocalizedUI(@"CHECK FAILED") message:errorMsg ?: ZXLocalizedUI(@"Unable to verify device.")];
                }
            });
        }];
    }
}

- (void)updateDeviceCompatibility:(NSDictionary *)compatibility {
    if (![compatibility isKindOfClass:[NSDictionary class]]) return;
    self.compatibilityData = compatibility;
    if (self.settingsVisible) [self rebuildSettings];
}

- (void)showCompatibilityScreenWithData:(NSDictionary *)compatibility {
    [self updateDeviceCompatibility:compatibility];
    NSString *reason = compatibility[@"reason"] ?: compatibility[@"message"];
    [self showStartupState:ZXStartupStateIncompatible message:reason];
}

#pragma mark - Global Modals & Loading

- (void)setupGlobalLoading {
    _globalLoadingOverlay = [[UIView alloc] initWithFrame:self.view.bounds];
    _globalLoadingOverlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    _globalLoadingOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _globalLoadingOverlay.hidden = YES;
    _globalLoadingOverlay.layer.zPosition = 10000;
    [self.view addSubview:_globalLoadingOverlay];
    
    UIView *card = [self card];
    [_globalLoadingOverlay addSubview:card];
    
    _globalSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _globalSpinner.color = [ZXTheme primaryText];
    _globalSpinner.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_globalSpinner];
    
    _globalLoadingTitle = [self label:@"SECURE OPERATION" size:14 weight:UIFontWeightBold color:[ZXTheme primaryText]];
    _globalLoadingTitle.textAlignment = NSTextAlignmentCenter;
    _globalLoadingTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_globalLoadingTitle];
    
    _globalLoadingDetail = [self label:@"Please wait…" size:11 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    _globalLoadingDetail.textAlignment = NSTextAlignmentCenter;
    _globalLoadingDetail.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_globalLoadingDetail];
    
    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:_globalLoadingOverlay.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:_globalLoadingOverlay.centerYAnchor],
        [card.widthAnchor constraintEqualToConstant:240],
        [card.heightAnchor constraintEqualToConstant:150],
        [_globalSpinner.topAnchor constraintEqualToAnchor:card.topAnchor constant:24],
        [_globalSpinner.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [_globalLoadingTitle.topAnchor constraintEqualToAnchor:_globalSpinner.bottomAnchor constant:20],
        [_globalLoadingTitle.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:10],
        [_globalLoadingTitle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-10],
        [_globalLoadingDetail.topAnchor constraintEqualToAnchor:_globalLoadingTitle.bottomAnchor constant:6],
        [_globalLoadingDetail.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:10],
        [_globalLoadingDetail.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-10]
    ]];
}

- (void)showGlobalLoadingState:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.globalLoadingOverlay.hidden = NO;
        self.globalLoadingOverlay.alpha = 0;
        self.globalLoadingTitle.text = ZXLocalizedUI(message.length ? message : @"SECURE OPERATION");
        self.globalLoadingDetail.text = ZXLocalizedUI(@"Please wait…");
        [self.globalSpinner startAnimating];
        [UIView animateWithDuration:0.2 animations:^{ self.globalLoadingOverlay.alpha = 1; }];
    });
}
- (void)updateGlobalLoadingMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{ self.globalLoadingDetail.text = ZXLocalizedUI(message ?: @"Please wait…"); });
}
- (void)hideGlobalLoadingState {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.globalSpinner stopAnimating];
        [UIView animateWithDuration:0.2 animations:^{ self.globalLoadingOverlay.alpha = 0; } completion:^(BOOL finished){ self.globalLoadingOverlay.hidden = YES; }];
    });
}

- (void)showToast:(NSString *)message success:(BOOL)success {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.toastView) [self.toastView removeFromSuperview];
        UIView *toast = [[UIView alloc] init];
        toast.backgroundColor = [ZXTheme surfaceRaised];
        toast.layer.cornerRadius = 12;
        toast.layer.borderWidth = 1;
        toast.layer.borderColor = (success ? [ZXTheme success] : [ZXTheme error]).CGColor;
        toast.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:toast];
        self.toastView = toast;
        
        UILabel *text = [self label:ZXLocalizedUI(message ?: @"") size:12 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
        text.translatesAutoresizingMaskIntoConstraints = NO;
        [toast addSubview:text];
        
        [NSLayoutConstraint activateConstraints:@[
            [toast.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [toast.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
            [toast.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:20],
            [toast.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20],
            [toast.heightAnchor constraintEqualToConstant:46],
            [text.leadingAnchor constraintEqualToAnchor:toast.leadingAnchor constant:16],
            [text.trailingAnchor constraintEqualToAnchor:toast.trailingAnchor constant:-16],
            [text.centerYAnchor constraintEqualToAnchor:toast.centerYAnchor]
        ]];
        
        toast.alpha = 0; toast.transform = CGAffineTransformMakeTranslation(0,-10);
        [UIView animateWithDuration:0.3 animations:^{ toast.alpha=1; toast.transform=CGAffineTransformIdentity; }];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(2.5*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
            if(self.toastView==toast){ [UIView animateWithDuration:0.2 animations:^{ toast.alpha=0; } completion:^(BOOL f){ [toast removeFromSuperview]; self.toastView=nil; }]; }
        });
    });
}

- (void)showCustomConfirmationWithTitle:(NSString *)title message:(NSString *)message confirmTitle:(NSString *)confirmTitle completion:(void (^)(void))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:ZXLocalizedUI(title) message:ZXLocalizedUI(message) preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:ZXLocalizedUI(confirmTitle ?: @"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (completion) completion();
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)showToast:(NSString *)message { [self showToast:message success:YES]; }
- (void)showGlobalErrorWithTitle:(NSString *)title message:(NSString *)message { [self showCustomConfirmationWithTitle:title message:message confirmTitle:@"DISMISS" completion:nil]; }
- (void)showSuccessMessage:(NSString *)title message:(NSString *)message { [self showCustomConfirmationWithTitle:title message:message confirmTitle:@"CONTINUE" completion:nil]; }
- (void)showNetworkError { [self showGlobalErrorWithTitle:@"CONNECTION ERROR" message:@"Network connection lost. Try again when the secure node is reachable."]; }
- (void)showServerError { [self showGlobalErrorWithTitle:@"SERVER ERROR" message:@"The ZENTRAX server could not complete the request."]; }
- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds { [self showGlobalErrorWithTitle:@"RATE LIMITED" message:[NSString stringWithFormat:@"Request limit reached. Try again in %ld seconds.",(long)MAX(0,seconds)]]; }

- (void)showLoginScreen {
    if (self.safeModeEnabled) { [self showSafeModeLockScreen]; return; }
    [self transitionToPrimaryContainer:self.authContainer];
    self.currentState = ZXAppStateAuth;
    NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *saved = [globalDefaults stringForKey:ZXLastKey];
    if (saved.length) self.keyInput.textField.text = saved;
    [self stopHeartbeatMonitor];
}

- (void)showDashboard {
    if (self.safeModeEnabled && self.safeModeState != ZXSafeModeStateUnlocked) { [self showSafeModeLockScreen]; return; }
    [self transitionToPrimaryContainer:self.dashboardContainer];
    self.currentState = ZXAppStateDashboard;
    [self startHeartbeatMonitor];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.currentState != ZXAppStateDashboard) return;
        NSDictionary *config = [[ZentraxNetworkManager sharedManager] cachedConfiguration];
        if (config) [self updateDashboardWithConfiguration:config];
    });
}

- (void)showMaintenanceScreenWithMessage:(NSString *)message { [self showStartupState:ZXStartupStateMaintenance message:message]; }
- (void)showUpdateRequiredScreenWithMessage:(NSString *)message { [self showStartupState:ZXStartupStateVersionMismatch message:message]; }
- (void)showConnectionErrorScreenWithMessage:(NSString *)message { [self showStartupState:ZXStartupStateConnectionError message:message]; }

- (void)handleLogout {
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:ZXLocalizedUI(@"SIGN OUT") message:ZXLocalizedUI(@"Your current secure session will be closed.") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:ZXLocalizedUI(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:ZXLocalizedUI(@"Sign Out") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        __strong typeof(weakSelf) self = weakSelf; if (!self) return;
        
        [[ZentraxNetworkManager sharedManager] logout];
        
        NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
        [globalDefaults removeObjectForKey:ZXLastKey];
        [globalDefaults synchronize];
        
        if ([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) {
            [self.delegate zentraxDidRequestLogoutWithCompletion:^{
                dispatch_async(dispatch_get_main_queue(), ^{ [self showLoginScreen]; });
            }];
        } else {
            [self showLoginScreen];
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIImage *)preferredLogoImage {
    NSArray *names=@[@"ZentraxLogo",@"AppIcon60x60",@"AppIcon"];
    for (NSString *n in names) { UIImage *i=[UIImage imageNamed:n]; if(i) return i; }
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(120,120),YES,0);
    [[UIColor blackColor] setFill]; UIRectFill(CGRectMake(0,0,120,120));
    [[UIColor whiteColor] setStroke]; UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(20, 20, 80, 80) cornerRadius:16]; path.lineWidth = 4; [path stroke];
    NSDictionary *attrs=@{NSFontAttributeName:[UIFont systemFontOfSize:50 weight:UIFontWeightHeavy],NSForegroundColorAttributeName:[UIColor whiteColor]};
    [@"Z" drawInRect:CGRectMake(42,32,50,60) withAttributes:attrs];
    UIImage *i=UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); return i;
}

- (void)resetToStartup { self.hasStarted = NO; self.currentState = ZXAppStateInit; [self stopHeartbeatMonitor]; [self stopLicenseCountdown]; [self beginBootstrap]; }
- (void)dismissPresentedUI { [self dismissViewControllerAnimated:YES completion:nil]; }
- (BOOL)isShowingLogin { return self.currentState == ZXAppStateAuth && !self.authContainer.hidden; }
- (BOOL)isShowingDashboard { return self.currentState == ZXAppStateDashboard && !self.dashboardContainer.hidden; }
- (BOOL)isShowingSafeModeLock { return !self.safeLockContainer.hidden && self.safeModeEnabled; }

@end
