//
//  ZentraxUI.m
//  Zentrax VIP - Premium Security Infrastructure UI
//
//  Architecture: Server-authoritative UI / Network-driven state
//  Status: PRODUCTION AUDITED
//

#import "ZentraxUI.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <objc/message.h>

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
    label.font = font ?: [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
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
        @"Enter Passcode": @"Nhập mật mã", @"Create Passcode": @"Tạo mật mã",
        @"Create a 6-digit private passcode": @"Tạo mật mã riêng gồm 6 chữ số",
        @"Confirm Passcode": @"Xác nhận mật mã", @"Enter the same 6-digit passcode again": @"Nhập lại mật mã 6 chữ số",
        @"Choose your language": @"Chọn ngôn ngữ", @"You can change this anytime from Settings.": @"Bạn có thể thay đổi bất cứ lúc nào trong Cài đặt.",
        @"WELCOME TO ZENTRAX": @"CHÀO MỪNG ĐẾN VỚI ZENTRAX",
        @"PREMIUM THEMES": @"CHỦ ĐỀ CAO CẤP", @"DONE": @"XONG", @"RECHECK": @"KIỂM TRA LẠI",
        @"UNAVAILABLE": @"KHÔNG KHẢ DỤNG", @"DISMISS": @"ĐÓNG", @"RETRY": @"THỬ LẠI",
        @"Close screen sharing app": @"Đóng ứng dụng chia sẻ màn hình",
        @"Screen sharing apps can be used by fraudsters to record your screen and steal your wallet information": @"Ứng dụng chia sẻ màn hình có thể bị kẻ gian sử dụng để ghi lại màn hình và đánh cắp thông tin ví của bạn",
        @"AUTHENTICATE": @"XÁC THỰC", @"SECURE OPERATION": @"THAO TÁC BẢO MẬT", @"Please wait…": @"Vui lòng chờ…",
        @"Awaiting verification": @"Đang chờ xác minh", @"NOT VERIFIED": @"CHƯA XÁC MINH", @"SUPPORTED": @"HỖ TRỢ", @"UNSUPPORTED": @"KHÔNG HỖ TRỢ",
        @"ACTIVE":@"ĐANG BẬT", @"READY":@"SẴN SÀNG", @"UNACTIVATED":@"CHƯA KÍCH HOẠT", @"EXPIRED":@"ĐÃ HẾT HẠN", @"REVOKED":@"ĐÃ THU HỒI", @"DISABLED":@"ĐÃ TẮT", @"UNKNOWN":@"KHÔNG XÁC ĐỊNH", @"PROCESSING":@"ĐANG XỬ LÝ", @"PERMANENT":@"VĨNH VIỄN", @"NOT STARTED":@"CHƯA BẮT ĐẦU", @"● SECURE":@"● BẢO MẬT", @"● OFFLINE":@"● NGOẠI TUYẾN"
    };
    NSDictionary *zh = @{
        @"Settings": @"设置", @"Safe UI Mode": @"安全界面模式",
        @"Protected lock screen is enabled": @"受保护的锁定屏幕已启用", @"Add a private six-digit lock screen": @"添加私密六位锁屏",
        @"DEVICE STATUS": @"设备状态", @"PREFERENCES": @"偏好设置", @"ACCOUNT": @"账户",
        @"Language": @"语言", @"Appearance": @"外观", @"Sign Out": @"退出登录",
        @"Close the current secure session": @"关闭当前安全会话", @"LICENSE CONTROL": @"许可证控制",
        @"SECURE FUNCTIONS": @"安全功能", @"Secure node connected.": @"安全节点已连接。",
        @"Awaiting first activation": @"等待首次激活", @"Lifetime server entitlement": @"服务器永久授权",
        @"No functions available": @"暂无可用功能",
        @"Your server configuration will appear here when functions are assigned to this license.": @"为此许可证分配功能后，服务器配置将显示在这里。",
        @"Enter Passcode": @"输入密码", @"Create Passcode": @"创建密码", @"Create a 6-digit private passcode": @"创建六位私密密码",
        @"Confirm Passcode": @"确认密码", @"Enter the same 6-digit passcode again": @"再次输入相同的六位密码",
        @"Choose your language": @"选择语言",
        @"You can change this anytime from Settings.": @"你可以随时在设置中更改。", @"WELCOME TO ZENTRAX": @"欢迎使用 ZENTRAX",
        @"PREMIUM THEMES": @"高级主题", @"DONE": @"完成", @"RECHECK": @"重新检查", @"UNAVAILABLE": @"不可用",
        @"DISMISS": @"关闭", @"RETRY": @"重试", @"Close screen sharing app": @"关闭屏幕共享应用",
        @"Screen sharing apps can be used by fraudsters to record your screen and steal your wallet information": @"屏幕共享应用可能被诈骗者用来录制屏幕并窃取钱包信息",
        @"AUTHENTICATE": @"验证", @"SECURE OPERATION": @"安全操作", @"Please wait…": @"请稍候…",
        @"Awaiting verification": @"等待验证", @"NOT VERIFIED": @"未验证", @"SUPPORTED": @"支持", @"UNSUPPORTED": @"不支持",
        @"ACTIVE":@"已启用", @"READY":@"就绪", @"UNACTIVATED":@"未激活", @"EXPIRED":@"已过期", @"REVOKED":@"已撤销", @"DISABLED":@"已禁用", @"UNKNOWN":@"未知", @"PROCESSING":@"处理中", @"PERMANENT":@"永久", @"NOT STARTED":@"未开始", @"● SECURE":@"● 安全", @"● OFFLINE":@"● 离线"
    };

    NSDictionary *ja = @{
        @"Settings": @"設定", @"Safe UI Mode": @"セーフUIモード", @"Language": @"言語", @"Sign Out": @"ログアウト", @"PREFERENCES": @"環境設定", @"ACCOUNT": @"アカウント", @"DEVICE": @"デバイス", @"SECURITY": @"セキュリティ", @"LICENSE": @"ライセンス", @"ACTIVE": @"有効", @"READY": @"準備完了", @"EXPIRED": @"期限切れ", @"UNSUPPORTED": @"非対応", @"SUPPORTED": @"対応", @"RECHECK": @"再確認", @"CANCEL": @"キャンセル", @"CONTINUE": @"続行", @"DISMISS": @"閉じる", @"RETRY": @"再試行", @"Welcome back": @"おかえりなさい", @"License Key": @"ライセンスキー", @"Enter your license key to continue.": @"ライセンスキーを入力して続行してください。", @"Congratulations — your device is compatible.": @"おめでとうございます。このデバイスは対応しています。", @"This device is not supported.": @"このデバイスは対応していません。", @"Language updated": @"言語を更新しました", @"SERVER VERIFIED": @"サーバー確認済み"
    };
    NSDictionary *commonVI=@{@"Welcome back":@"Chào mừng trở lại",@"License Key":@"Khóa giấy phép",@"Enter your license key to continue.":@"Nhập khóa giấy phép để tiếp tục.",@"Congratulations — your device is compatible.":@"Chúc mừng — thiết bị của bạn tương thích.",@"This device is not supported.":@"Thiết bị này không được hỗ trợ.",@"Language updated":@"Đã cập nhật ngôn ngữ",@"CANCEL":@"HỦY"};
    NSDictionary *extraVI=@{
        @"CONTINUE":@"TIẾP TỤC", @"DEVICE":@"THIẾT BỊ", @"SECURITY":@"BẢO MẬT", @"LICENSE":@"GIẤY PHÉP", @"English":@"English", @"SECURE FUNCTIONS":@"CHỨC NĂNG BẢO MẬT", @"PREFERENCES":@"TÙY CHỌN", @"Connecting…":@"Đang kết nối…", @"Connecting to secure server":@"Đang kết nối máy chủ bảo mật", @"AUTHENTICATING":@"ĐANG XÁC THỰC", @"CHECKING DEVICE":@"ĐANG KIỂM TRA THIẾT BỊ", @"Compatibility Verified":@"Đã xác minh tương thích", @"CHECK FAILED":@"KIỂM TRA THẤT BẠI", @"Unable to verify device.":@"Không thể xác minh thiết bị.", @"CANCEL":@"HỦY", @"Disable Safe UI":@"Tắt Safe UI", @"Enter passcode to disable":@"Nhập mật mã để tắt", @"Safe UI Mode enabled":@"Đã bật Safe UI", @"Safe UI Mode disabled":@"Đã tắt Safe UI", @"Passcodes do not match. Try again.":@"Mật mã không khớp. Hãy thử lại."
    };
    NSDictionary *extraZH=@{
        @"CONTINUE":@"继续", @"DEVICE":@"设备", @"SECURITY":@"安全", @"LICENSE":@"许可证", @"SECURE FUNCTIONS":@"安全功能", @"PREFERENCES":@"偏好设置", @"Connecting…":@"正在连接…", @"Connecting to secure server":@"正在连接安全服务器", @"AUTHENTICATING":@"正在验证", @"CHECKING DEVICE":@"正在检查设备", @"Compatibility Verified":@"兼容性已验证", @"CHECK FAILED":@"检查失败", @"Unable to verify device.":@"无法验证设备。", @"CANCEL":@"取消", @"Disable Safe UI":@"关闭安全界面", @"Enter passcode to disable":@"输入密码以关闭", @"Safe UI Mode enabled":@"安全界面模式已启用", @"Safe UI Mode disabled":@"安全界面模式已关闭", @"Passcodes do not match. Try again.":@"密码不匹配，请重试。"
    };
    NSDictionary *extraJA=@{
        @"CONTINUE":@"続行", @"DEVICE":@"デバイス", @"SECURITY":@"セキュリティ", @"LICENSE":@"ライセンス", @"SECURE FUNCTIONS":@"セキュア機能", @"PREFERENCES":@"環境設定", @"Connecting…":@"接続中…", @"Connecting to secure server":@"安全サーバーに接続中", @"AUTHENTICATING":@"認証中", @"CHECKING DEVICE":@"デバイス確認中", @"Compatibility Verified":@"互換性を確認しました", @"CHECK FAILED":@"確認に失敗しました", @"Unable to verify device.":@"デバイスを確認できません。", @"Disable Safe UI":@"Safe UIを無効化", @"Enter passcode to disable":@"無効化するにはパスコードを入力", @"Safe UI Mode enabled":@"Safe UIを有効にしました", @"Safe UI Mode disabled":@"Safe UIを無効にしました", @"Passcodes do not match. Try again.":@"パスコードが一致しません。もう一度お試しください。"
    };
    NSDictionary *commonZH=@{@"Welcome back":@"欢迎回来",@"License Key":@"许可证密钥",@"Enter your license key to continue.":@"请输入许可证密钥继续。",@"Congratulations — your device is compatible.":@"恭喜，您的设备兼容。",@"This device is not supported.":@"此设备不受支持。",@"Language updated":@"语言已更新",@"CANCEL":@"取消"};
    if ([language isEqualToString:@"Tiếng Việt"]) return vi[text] ?: commonVI[text] ?: extraVI[text] ?: text;
    if ([language isEqualToString:@"简体中文"]) return zh[text] ?: commonZH[text] ?: extraZH[text] ?: text;
    if ([language isEqualToString:@"日本語"]) return ja[text] ?: extraJA[text] ?: text;
    return text;
}

#pragma mark - Theme Engine

@interface ZXTheme : NSObject
+ (NSString *)currentTheme;
+ (BOOL)isLightMode;
+ (UIColor *)background; + (UIColor *)surface; + (UIColor *)surfaceRaised; + (UIColor *)surfaceInset; + (UIColor *)border; + (UIColor *)borderStrong;
+ (UIColor *)primaryText; + (UIColor *)secondaryText; + (UIColor *)mutedText; + (UIColor *)accent;
+ (UIColor *)success; + (UIColor *)warning; + (UIColor *)error;
+ (UIFont *)display:(CGFloat)size; + (UIFont *)heading:(CGFloat)size; + (UIFont *)body:(CGFloat)size weight:(UIFontWeight)weight; + (UIFont *)mono:(CGFloat)size weight:(UIFontWeight)weight;
+ (void)track:(UILabel *)label spacing:(CGFloat)spacing;
+ (CGFloat)cardRadius;
+ (CGFloat)borderWidth;
+ (void)styleCard:(UIView *)view;
@end

@implementation ZXTheme

+ (NSString *)currentTheme {
    // ZENTRAX ships one deliberate visual language: Obsidian.
    // The legacy preference key is intentionally left untouched for compatibility
    // with older builds, but the UI no longer exposes a theme selector.
    return @"Obsidian";
}

+ (BOOL)isLightMode {
    return [[self currentTheme] isEqualToString:@"Arctic"];
}

+ (UIColor *)background {
    return [UIColor colorWithRed:0.012 green:0.008 blue:0.025 alpha:1.0];
}


+ (UIColor *)surface {
    return [UIColor colorWithRed:0.040 green:0.024 blue:0.075 alpha:1.0];
}


+ (UIColor *)surfaceRaised {
    return [UIColor colorWithRed:0.075 green:0.045 blue:0.130 alpha:1.0];
}


+ (UIColor *)surfaceInset {
    return [UIColor colorWithRed:0.018 green:0.012 blue:0.040 alpha:1.0];
}


+ (UIColor *)border {
    return [UIColor colorWithRed:0.34 green:0.22 blue:0.58 alpha:0.42];
}


+ (UIColor *)borderStrong {
    return [UIColor colorWithRed:0.60 green:0.42 blue:0.95 alpha:0.72];
}


+ (UIColor *)primaryText {
    return [UIColor colorWithRed:0.97 green:0.96 blue:1.00 alpha:1.0];
}


+ (UIColor *)secondaryText {
    return [UIColor colorWithRed:0.70 green:0.67 blue:0.79 alpha:1.0];
}


+ (UIColor *)mutedText {
    return [UIColor colorWithRed:0.43 green:0.39 blue:0.53 alpha:1.0];
}


+ (UIColor *)accent {
    return [UIColor colorWithRed:0.68 green:0.42 blue:1.00 alpha:1.0];
}


+ (UIColor *)success { return [UIColor colorWithRed:0.20 green:0.80 blue:0.40 alpha:1.0]; } 
+ (UIColor *)warning { return [UIColor colorWithRed:0.95 green:0.65 blue:0.20 alpha:1.0]; }
+ (UIColor *)error { return [UIColor colorWithRed:0.90 green:0.30 blue:0.30 alpha:1.0]; }

+ (UIFont *)display:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightHeavy]; }
+ (UIFont *)heading:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightSemibold]; }
+ (UIFont *)body:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont systemFontOfSize:size weight:weight]; }
+ (UIFont *)mono:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont monospacedSystemFontOfSize:size weight:weight]; }

+ (void)track:(UILabel *)label spacing:(CGFloat)spacing {
    if (!label.text.length) return;
    label.attributedText = [[NSAttributedString alloc] initWithString:label.text attributes:@{NSKernAttributeName:@(spacing)}];
}

+ (CGFloat)cardRadius {
    return 22.0;
}


+ (CGFloat)borderWidth {
    NSString *t = [self currentTheme];
    if ([t isEqualToString:@"Arctic"]) return 0.0;
    return 1.0;
}

+ (void)styleCard:(UIView *)view {
    view.backgroundColor = [self surface];
    view.layer.cornerRadius = [self cardRadius];
    view.layer.borderWidth = 1.0;
    view.layer.borderColor = [self border].CGColor;
    view.layer.shadowColor = [UIColor colorWithRed:0.28 green:0.12 blue:0.55 alpha:1].CGColor;
    view.layer.shadowOpacity = 0.18;
    view.layer.shadowRadius = 26;
    view.layer.shadowOffset = CGSizeMake(0, 14);
}


@end


#pragma mark - ZENTRAX Premium Backdrop

@interface ZXPremiumBackdrop : UIView
@property(nonatomic,strong) CAGradientLayer *gradientLayer;
@property(nonatomic,strong) CAShapeLayer *gridLayer;
@property(nonatomic,strong) CAShapeLayer *glowLayer;
@end

@implementation ZXPremiumBackdrop

- (instancetype)initWithFrame:(CGRect)frame {
    self=[super initWithFrame:frame];
    if(!self) return nil;
    self.userInteractionEnabled=NO;
    self.backgroundColor=[UIColor colorWithRed:0.008 green:0.005 blue:0.018 alpha:1];

    _gradientLayer=[CAGradientLayer layer];
    _gradientLayer.colors=@[
        (id)[UIColor colorWithRed:0.015 green:0.008 blue:0.038 alpha:1].CGColor,
        (id)[UIColor colorWithRed:0.055 green:0.018 blue:0.105 alpha:1].CGColor,
        (id)[UIColor colorWithRed:0.012 green:0.006 blue:0.028 alpha:1].CGColor
    ];
    _gradientLayer.locations=@[@0.0,@0.52,@1.0];
    [self.layer addSublayer:_gradientLayer];

    _gridLayer=[CAShapeLayer layer];
    _gridLayer.strokeColor=[UIColor colorWithRed:0.55 green:0.30 blue:0.92 alpha:0.085].CGColor;
    _gridLayer.fillColor=[UIColor clearColor].CGColor;
    _gridLayer.lineWidth=0.55;
    [self.layer addSublayer:_gridLayer];

    _glowLayer=[CAShapeLayer layer];
    _glowLayer.fillColor=[UIColor colorWithRed:0.48 green:0.20 blue:0.92 alpha:0.10].CGColor;
    _glowLayer.shadowColor=[UIColor colorWithRed:0.62 green:0.34 blue:1 alpha:1].CGColor;
    _glowLayer.shadowOpacity=0.32;
    _glowLayer.shadowRadius=90;
    _glowLayer.shadowOffset=CGSizeZero;
    [self.layer addSublayer:_glowLayer];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _gradientLayer.frame=self.bounds;
    _gridLayer.frame=self.bounds;
    _glowLayer.frame=self.bounds;

    UIBezierPath *grid=[UIBezierPath bezierPath];
    CGFloat step=30.0;
    for(CGFloat x=0;x<=CGRectGetWidth(self.bounds)+step;x+=step){
        [grid moveToPoint:CGPointMake(x,0)];
        [grid addLineToPoint:CGPointMake(x,CGRectGetHeight(self.bounds))];
    }
    for(CGFloat y=0;y<=CGRectGetHeight(self.bounds)+step;y+=step){
        [grid moveToPoint:CGPointMake(0,y)];
        [grid addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds),y)];
    }
    _gridLayer.path=grid.CGPath;

    UIBezierPath *glow=[UIBezierPath bezierPathWithOvalInRect:CGRectMake(CGRectGetMidX(self.bounds)-150, -95, 300, 300)];
    _glowLayer.path=glow.CGPath;
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
    self.backgroundColor = [UIColor colorWithRed:0.69 green:0.43 blue:1.0 alpha:1];
    self.layer.cornerRadius = 15.0;
    self.clipsToBounds = NO;
    self.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightHeavy];
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor = 0.78;
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:1].CGColor;
    self.layer.shadowOpacity = 0.34;
    self.layer.shadowRadius = 18.0;
    self.layer.shadowOffset = CGSizeMake(0, 10);

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    _spinner.color = [UIColor whiteColor];
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
    [UIView animateWithDuration:0.12 animations:^{
        self.transform = CGAffineTransformMakeScale(0.975, 0.975);
        self.alpha = 0.92;
    }];
}
- (void)zxTouchUp {
    [UIView animateWithDuration:0.38 delay:0 usingSpringWithDamping:0.72 initialSpringVelocity:0.18 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.transform = CGAffineTransformIdentity;
        self.alpha = 1.0;
    } completion:nil];
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
@property(nonatomic,strong) UIButton *eyeButton;
@property(nonatomic,strong) UIButton *clearButton;
@property(nonatomic,strong) UILabel *caption;
@end

@implementation ZXPremiumField
- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;

    _caption = ZXLabel(ZXLocalizedUI(@"LICENSE KEY"), [UIFont systemFontOfSize:10 weight:UIFontWeightHeavy], [ZXTheme mutedText]);
    [ZXTheme track:_caption spacing:1.5];
    _caption.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_caption];

    _container = [[UIView alloc] init];
    _container.backgroundColor = [UIColor colorWithRed:.018 green:.009 blue:.035 alpha:.98];
    _container.layer.cornerRadius = 16.0;
    _container.layer.borderWidth = 1.0;
    _container.layer.borderColor = [UIColor colorWithRed:.30 green:.20 blue:.44 alpha:.8].CGColor;
    _container.layer.shadowColor = [UIColor blackColor].CGColor;
    _container.layer.shadowOpacity = 0.34;
    _container.layer.shadowRadius = 20;
    _container.layer.shadowOffset = CGSizeMake(0, 10);
    _container.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_container];

    UIView *accent = [[UIView alloc] init];
    accent.backgroundColor = [UIColor colorWithWhite:1 alpha:0.035];
    accent.layer.cornerRadius = 1;
    accent.translatesAutoresizingMaskIntoConstraints = NO;
    [_container addSubview:accent];

    _textField = [[UITextField alloc] init];
    _textField.textColor = [ZXTheme primaryText];
    _textField.font = [UIFont monospacedSystemFontOfSize:15 weight:UIFontWeightMedium];
    _textField.secureTextEntry = YES;
    _textField.delegate = self;
    _textField.autocorrectionType = UITextAutocorrectionTypeNo;
    _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _textField.spellCheckingType = UITextSpellCheckingTypeNo;
    _textField.returnKeyType = UIReturnKeyDone;
    _textField.clearButtonMode = UITextFieldViewModeNever;
    _textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"ZTX-••••-••••-••••" attributes:@{
        NSForegroundColorAttributeName:[UIColor colorWithWhite:0.34 alpha:1]
    }];
    _textField.translatesAutoresizingMaskIntoConstraints = NO;
    [_textField addTarget:self action:@selector(zxTextChanged:) forControlEvents:UIControlEventEditingChanged];
    [_container addSubview:_textField];

    _eyeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_eyeButton setImage:[UIImage systemImageNamed:@"eye.slash.fill"] forState:UIControlStateNormal];
    _eyeButton.tintColor = [UIColor colorWithWhite:0.52 alpha:1];
    _eyeButton.accessibilityLabel = @"Show license key";
    _eyeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_eyeButton addTarget:self action:@selector(toggleVisibility) forControlEvents:UIControlEventTouchUpInside];
    [_container addSubview:_eyeButton];

    _clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_clearButton setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    _clearButton.tintColor = [UIColor colorWithWhite:0.40 alpha:1];
    _clearButton.alpha = 0;
    _clearButton.transform = CGAffineTransformMakeScale(.8,.8);
    _clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_clearButton addTarget:self action:@selector(clearText) forControlEvents:UIControlEventTouchUpInside];
    [_container addSubview:_clearButton];

    [NSLayoutConstraint activateConstraints:@[
        [_caption.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_caption.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:4],
        [_container.topAnchor constraintEqualToAnchor:_caption.bottomAnchor constant:9],
        [_container.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_container.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_container.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_container.heightAnchor constraintEqualToConstant:60],
        [accent.leadingAnchor constraintEqualToAnchor:_container.leadingAnchor constant:1],
        [accent.trailingAnchor constraintEqualToAnchor:_container.trailingAnchor constant:-1],
        [accent.topAnchor constraintEqualToAnchor:_container.topAnchor constant:1],
        [accent.heightAnchor constraintEqualToConstant:1],
        [_textField.leadingAnchor constraintEqualToAnchor:_container.leadingAnchor constant:17],
        [_textField.centerYAnchor constraintEqualToAnchor:_container.centerYAnchor],
        [_textField.trailingAnchor constraintEqualToAnchor:_clearButton.leadingAnchor constant:-8],
        [_eyeButton.trailingAnchor constraintEqualToAnchor:_container.trailingAnchor constant:-12],
        [_eyeButton.centerYAnchor constraintEqualToAnchor:_container.centerYAnchor],
        [_eyeButton.widthAnchor constraintEqualToConstant:34],
        [_eyeButton.heightAnchor constraintEqualToConstant:34],
        [_clearButton.trailingAnchor constraintEqualToAnchor:_eyeButton.leadingAnchor constant:-2],
        [_clearButton.centerYAnchor constraintEqualToAnchor:_container.centerYAnchor],
        [_clearButton.widthAnchor constraintEqualToConstant:28],
        [_clearButton.heightAnchor constraintEqualToConstant:28]
    ]];
    return self;
}
- (void)zxTextChanged:(UITextField *)field {
    BOOL visible = field.text.length > 0;
    [UIView animateWithDuration:0.16 animations:^{
        self.clearButton.alpha = visible ? 1 : 0;
        self.clearButton.transform = visible ? CGAffineTransformIdentity : CGAffineTransformMakeScale(.8,.8);
    }];
}
- (void)clearText {
    self.textField.text = @"";
    [self zxTextChanged:self.textField];
    [self.textField sendActionsForControlEvents:UIControlEventEditingChanged];
    [self.textField becomeFirstResponder];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
}
- (void)toggleVisibility {
    self.textField.secureTextEntry = !self.textField.secureTextEntry;
    NSString *symbol = self.textField.secureTextEntry ? @"eye.slash.fill" : @"eye.fill";
    [self.eyeButton setImage:[UIImage systemImageNamed:symbol] forState:UIControlStateNormal];
    self.eyeButton.accessibilityLabel = self.textField.secureTextEntry ? @"Show license key" : @"Hide license key";
    [self.textField becomeFirstResponder];
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.22 animations:^{
        self.container.layer.borderColor = [UIColor colorWithRed:.70 green:.46 blue:1 alpha:.78].CGColor;
        self.container.layer.shadowColor = [UIColor colorWithRed:.55 green:.28 blue:1 alpha:1].CGColor;
        self.container.layer.shadowOpacity = 0.28;
        self.container.layer.shadowRadius = 24;
    }];
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.22 animations:^{
        self.container.layer.borderColor = [UIColor colorWithRed:.30 green:.20 blue:.44 alpha:.8].CGColor;
        self.container.layer.shadowColor = [UIColor blackColor].CGColor;
        self.container.layer.shadowOpacity = 0.34;
        self.container.layer.shadowRadius = 20;
    }];
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
@property(nonatomic,strong) UIVisualEffectView *privacyOverlay;
@property(nonatomic,strong) UIView *globalLoadingOverlay;
@property(nonatomic,strong) UIView *toastView;

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
@property(nonatomic,strong) UIView *premiumModalView;
@property(nonatomic,strong) UIView *premiumModalCard;


- (UIImage *)preferredLogoImage;
- (void)toggleDashboardKey;
- (void)rebuildAllContainers;
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

    [self rebuildAllContainers];

    [self registerPrivacyObservers];
    [self applyInitialSafeModeState];
    [self setAllPrimaryContainersHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)rebuildAllContainers {
    NSDictionary *preservedDashboardConfiguration = self.dashboardConfiguration;
    NSDictionary *preservedFunctionStates = [self.functionStates copy];

    [self.splashContainer removeFromSuperview];
    [self.authContainer removeFromSuperview];
    [self.dashboardContainer removeFromSuperview];
    [self.settingsContainer removeFromSuperview];
    [self.startupBlockContainer removeFromSuperview];
    [self.safeLockContainer removeFromSuperview];
    [self.globalLoadingOverlay removeFromSuperview];
    [self.privacyOverlay removeFromSuperview];

    self.view.backgroundColor = [ZXTheme background];
    
    [self setupSplash];
    [self setupAuth];
    [self setupDashboard];
    if ([preservedFunctionStates isKindOfClass:[NSDictionary class]]) [self.functionStates addEntriesFromDictionary:preservedFunctionStates];
    if ([preservedDashboardConfiguration isKindOfClass:[NSDictionary class]] && preservedDashboardConfiguration.count) {
        [self updateDashboardWithConfiguration:preservedDashboardConfiguration];
    }
    [self setupSettingsScreen];
    [self setupStartupBlock];
    [self setupSafeModeLock];
    [self setupGlobalLoading];
    
    [self setAllPrimaryContainersHidden:YES];
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
    return [ZXTheme isLightMode] ? UIStatusBarStyleDarkContent : UIStatusBarStyleLightContent;
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
    [ZXTheme styleCard:v];
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


- (UIView *)premiumZentraxMark:(CGFloat)size {
    UIView *wrap=[[UIView alloc] init];
    wrap.translatesAutoresizingMaskIntoConstraints=NO;
    wrap.backgroundColor=[UIColor colorWithRed:.055 green:.025 blue:.11 alpha:.96];
    wrap.layer.cornerRadius=size*.28;
    wrap.layer.borderWidth=1;
    wrap.layer.borderColor=[UIColor colorWithRed:.62 green:.40 blue:1 alpha:.34].CGColor;
    wrap.layer.shadowColor=[UIColor colorWithRed:.48 green:.22 blue:1 alpha:1].CGColor;
    wrap.layer.shadowOpacity=.28;
    wrap.layer.shadowRadius=size*.30;
    wrap.layer.shadowOffset=CGSizeZero;
    CAGradientLayer *g=[CAGradientLayer layer];
    g.colors=@[(id)[UIColor colorWithRed:.38 green:.17 blue:.72 alpha:.20].CGColor,(id)[UIColor colorWithRed:.75 green:.43 blue:1 alpha:.10].CGColor];
    g.startPoint=CGPointMake(0,0); g.endPoint=CGPointMake(1,1); g.cornerRadius=size*.28; g.frame=CGRectMake(0,0,size,size);
    [wrap.layer addSublayer:g];
    UILabel *z=[[UILabel alloc] init];
    z.text=@"Z"; z.textAlignment=NSTextAlignmentCenter;
    z.font=[UIFont systemFontOfSize:size*.46 weight:UIFontWeightBlack];
    z.textColor=[UIColor colorWithRed:.91 green:.84 blue:1 alpha:1];
    z.translatesAutoresizingMaskIntoConstraints=NO; [wrap addSubview:z];
    [NSLayoutConstraint activateConstraints:@[
        [z.centerXAnchor constraintEqualToAnchor:wrap.centerXAnchor],
        [z.centerYAnchor constraintEqualToAnchor:wrap.centerYAnchor constant:-1],
        [z.leadingAnchor constraintGreaterThanOrEqualToAnchor:wrap.leadingAnchor],
        [z.trailingAnchor constraintLessThanOrEqualToAnchor:wrap.trailingAnchor]
    ]];
    return wrap;
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
    button.backgroundColor = [UIColor colorWithRed:.075 green:.038 blue:.13 alpha:1];
    button.layer.cornerRadius = 14.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [UIColor colorWithRed:.56 green:.36 blue:.86 alpha:.24].CGColor;
    button.layer.shadowColor = [UIColor colorWithRed:.40 green:.16 blue:.76 alpha:1].CGColor;
    button.layer.shadowOpacity = .16;
    button.layer.shadowRadius = 16;
    button.layer.shadowOffset = CGSizeMake(0,8);
    button.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBlack];
    [button setTitleColor:[UIColor colorWithRed:.82 green:.74 blue:.96 alpha:1] forState:UIControlStateNormal];
}

#pragma mark - Splash

- (void)installPremiumBackdropOnContainer:(UIView *)container {
    for (UIView *v in [container.subviews copy]) {
        if ([v isKindOfClass:[ZXPremiumBackdrop class]]) { [v removeFromSuperview]; break; }
    }
    ZXPremiumBackdrop *backdrop=[[ZXPremiumBackdrop alloc] initWithFrame:CGRectZero];
    backdrop.translatesAutoresizingMaskIntoConstraints=NO;
    [container insertSubview:backdrop atIndex:0];
    [NSLayoutConstraint activateConstraints:@[
        [backdrop.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [backdrop.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [backdrop.topAnchor constraintEqualToAnchor:container.topAnchor],
        [backdrop.bottomAnchor constraintEqualToAnchor:container.bottomAnchor]
    ]];
}

- (void)setupSplash {
    _splashContainer=[[UIView alloc] init];
    _splashContainer.translatesAutoresizingMaskIntoConstraints=NO;
    _splashContainer.backgroundColor=[UIColor colorWithRed:.012 green:.006 blue:.026 alpha:1];
    [self.view addSubview:_splashContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_splashContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_splashContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_splashContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_splashContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    [self installPremiumBackdropOnContainer:_splashContainer];

    UIView *halo=[[UIView alloc] init]; halo.translatesAutoresizingMaskIntoConstraints=NO;
    halo.backgroundColor=[UIColor colorWithRed:.30 green:.10 blue:.72 alpha:.10];
    halo.layer.cornerRadius=120; halo.layer.shadowColor=[UIColor colorWithRed:.58 green:.25 blue:1 alpha:1].CGColor;
    halo.layer.shadowOpacity=.28; halo.layer.shadowRadius=80; halo.layer.shadowOffset=CGSizeZero;
    [_splashContainer addSubview:halo];

    UIView *ring=[[UIView alloc] init]; ring.translatesAutoresizingMaskIntoConstraints=NO;
    ring.backgroundColor=[UIColor colorWithRed:.045 green:.018 blue:.085 alpha:.88]; ring.layer.cornerRadius=72;
    ring.layer.borderWidth=1.2; ring.layer.borderColor=[UIColor colorWithRed:.70 green:.45 blue:1 alpha:.42].CGColor;
    ring.layer.shadowColor=[UIColor colorWithRed:.55 green:.22 blue:1 alpha:1].CGColor; ring.layer.shadowOpacity=.32; ring.layer.shadowRadius=32; ring.layer.shadowOffset=CGSizeZero;
    [_splashContainer addSubview:ring];

    UILabel *z=[self label:@"Z" size:62 weight:UIFontWeightBlack color:[UIColor colorWithRed:.88 green:.80 blue:1 alpha:1]];
    z.textAlignment=NSTextAlignmentCenter; z.translatesAutoresizingMaskIntoConstraints=NO; [ring addSubview:z];
    UILabel *eyebrow=[self label:@"ZENTRAX // PRIVATE INFRASTRUCTURE" size:8 weight:UIFontWeightBlack color:[UIColor colorWithRed:.68 green:.53 blue:.91 alpha:1]];
    eyebrow.textAlignment=NSTextAlignmentCenter; [ZXTheme track:eyebrow spacing:2.1]; eyebrow.translatesAutoresizingMaskIntoConstraints=NO; [_splashContainer addSubview:eyebrow];
    UILabel *brand=[self label:@"ZENTRAX" size:39 weight:UIFontWeightBlack color:[UIColor whiteColor]];
    brand.textAlignment=NSTextAlignmentCenter; [ZXTheme track:brand spacing:7.0]; brand.translatesAutoresizingMaskIntoConstraints=NO; [_splashContainer addSubview:brand];
    UILabel *tag=[self label:@"SECURE  ·  PRIVATE  ·  BUILT DIFFERENT" size:8 weight:UIFontWeightHeavy color:[UIColor colorWithRed:.62 green:.52 blue:.75 alpha:1]];
    tag.textAlignment=NSTextAlignmentCenter; [ZXTheme track:tag spacing:1.8]; tag.translatesAutoresizingMaskIntoConstraints=NO; [_splashContainer addSubview:tag];

    UIView *track=[[UIView alloc] init]; track.translatesAutoresizingMaskIntoConstraints=NO; track.backgroundColor=[UIColor colorWithWhite:1 alpha:.075]; track.layer.cornerRadius=2; [_splashContainer addSubview:track];
    UIView *fill=[[UIView alloc] init]; fill.translatesAutoresizingMaskIntoConstraints=NO; fill.backgroundColor=[ZXTheme accent]; fill.layer.cornerRadius=2; [_splashContainer addSubview:fill];
    _splashStatus=[self label:@"CONNECTING" size:8 weight:UIFontWeightBlack color:[UIColor colorWithRed:.79 green:.68 blue:1 alpha:1]]; _splashStatus.textAlignment=NSTextAlignmentCenter; [ZXTheme track:_splashStatus spacing:1.9]; _splashStatus.translatesAutoresizingMaskIntoConstraints=NO; [_splashContainer addSubview:_splashStatus];
    _splashDetail=[self label:@"Reaching secure node" size:10 weight:UIFontWeightRegular color:[UIColor colorWithWhite:.42 alpha:1]]; _splashDetail.textAlignment=NSTextAlignmentCenter; _splashDetail.translatesAutoresizingMaskIntoConstraints=NO; [_splashContainer addSubview:_splashDetail];

    [NSLayoutConstraint activateConstraints:@[
        [halo.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor], [halo.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor constant:-75], [halo.widthAnchor constraintEqualToConstant:240], [halo.heightAnchor constraintEqualToConstant:240],
        [ring.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor], [ring.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor constant:-72], [ring.widthAnchor constraintEqualToConstant:144], [ring.heightAnchor constraintEqualToConstant:144],
        [z.centerXAnchor constraintEqualToAnchor:ring.centerXAnchor], [z.centerYAnchor constraintEqualToAnchor:ring.centerYAnchor constant:-2], [z.leadingAnchor constraintEqualToAnchor:ring.leadingAnchor constant:10], [z.trailingAnchor constraintEqualToAnchor:ring.trailingAnchor constant:-10],
        [eyebrow.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor], [eyebrow.bottomAnchor constraintEqualToAnchor:ring.topAnchor constant:-20],
        [brand.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor], [brand.topAnchor constraintEqualToAnchor:ring.bottomAnchor constant:24],
        [tag.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor], [tag.topAnchor constraintEqualToAnchor:brand.bottomAnchor constant:7],
        [track.leadingAnchor constraintEqualToAnchor:_splashContainer.leadingAnchor constant:74], [track.trailingAnchor constraintEqualToAnchor:_splashContainer.trailingAnchor constant:-74], [track.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor], [track.topAnchor constraintEqualToAnchor:tag.bottomAnchor constant:34], [track.heightAnchor constraintEqualToConstant:3],
        [fill.leadingAnchor constraintEqualToAnchor:track.leadingAnchor], [fill.topAnchor constraintEqualToAnchor:track.topAnchor], [fill.bottomAnchor constraintEqualToAnchor:track.bottomAnchor], [fill.widthAnchor constraintEqualToConstant:3],
        [_splashStatus.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor], [_splashStatus.topAnchor constraintEqualToAnchor:track.bottomAnchor constant:16],
        [_splashDetail.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor], [_splashDetail.topAnchor constraintEqualToAnchor:_splashStatus.bottomAnchor constant:5]
    ]];
    halo.alpha=0; ring.alpha=0; brand.alpha=0; eyebrow.alpha=0; tag.alpha=0; track.alpha=0; _splashStatus.alpha=0; _splashDetail.alpha=0;
    ring.transform=CGAffineTransformMakeScale(.82,.82);
    [UIView animateWithDuration:.75 delay:0 usingSpringWithDamping:.80 initialSpringVelocity:.10 options:UIViewAnimationOptionAllowUserInteraction animations:^{ halo.alpha=1; ring.alpha=1; ring.transform=CGAffineTransformIdentity; eyebrow.alpha=1; } completion:nil];
    [UIView animateWithDuration:.55 delay:.18 options:UIViewAnimationOptionCurveEaseOut animations:^{ brand.alpha=1; tag.alpha=1; track.alpha=1; self.splashStatus.alpha=1; self.splashDetail.alpha=1; } completion:nil];
    [UIView animateWithDuration:1.45 delay:.28 options:UIViewAnimationOptionCurveEaseInOut animations:^{ fill.transform=CGAffineTransformMakeScale(100,1); } completion:nil];
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
    _authContainer=[[UIView alloc] init]; _authContainer.translatesAutoresizingMaskIntoConstraints=NO; _authContainer.backgroundColor=[ZXTheme background]; [self.view addSubview:_authContainer];
    [NSLayoutConstraint activateConstraints:@[[_authContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],[_authContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],[_authContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],[_authContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]]];
    [self installPremiumBackdropOnContainer:_authContainer];
    _authScroll=[[UIScrollView alloc] init]; _authScroll.showsVerticalScrollIndicator=NO; _authScroll.keyboardDismissMode=UIScrollViewKeyboardDismissModeInteractive; _authScroll.translatesAutoresizingMaskIntoConstraints=NO; [_authContainer addSubview:_authScroll];
    UIView *content=[[UIView alloc] init]; content.translatesAutoresizingMaskIntoConstraints=NO; [_authScroll addSubview:content];
    [NSLayoutConstraint activateConstraints:[[_authScroll.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor],[_authScroll.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor],[_authScroll.topAnchor constraintEqualToAnchor:_authContainer.topAnchor],[_authScroll.bottomAnchor constraintEqualToAnchor:_authContainer.bottomAnchor],[content.leadingAnchor constraintEqualToAnchor:_authScroll.contentLayoutGuide.leadingAnchor],[content.trailingAnchor constraintEqualToAnchor:_authScroll.contentLayoutGuide.trailingAnchor],[content.topAnchor constraintEqualToAnchor:_authScroll.contentLayoutGuide.topAnchor],[content.bottomAnchor constraintEqualToAnchor:_authScroll.contentLayoutGuide.bottomAnchor],[content.widthAnchor constraintEqualToAnchor:_authScroll.frameLayoutGuide.widthAnchor]]];

    UIView *mark=[self premiumZentraxMark:70]; [content addSubview:mark];
    UILabel *brand=[self label:@"ZENTRAX" size:31 weight:UIFontWeightBlack color:[UIColor whiteColor]]; brand.textAlignment=NSTextAlignmentCenter; [ZXTheme track:brand spacing:5.2]; brand.translatesAutoresizingMaskIntoConstraints=NO; [content addSubview:brand];
    UILabel *caption=[self label:@"LICENSE ACCESS" size:8 weight:UIFontWeightBlack color:[UIColor colorWithRed:.67 green:.53 blue:.90 alpha:1]]; caption.textAlignment=NSTextAlignmentCenter; [ZXTheme track:caption spacing:2.0]; caption.translatesAutoresizingMaskIntoConstraints=NO; [content addSubview:caption];

    UIView *hero=[self card]; hero.backgroundColor=[UIColor colorWithRed:.025 green:.010 blue:.060 alpha:.985]; hero.layer.cornerRadius=28; hero.layer.borderColor=[UIColor colorWithRed:.58 green:.37 blue:1 alpha:.30].CGColor; hero.layer.shadowColor=[UIColor colorWithRed:.46 green:.18 blue:1 alpha:1].CGColor; hero.layer.shadowOpacity=.30; hero.layer.shadowRadius=38; hero.layer.shadowOffset=CGSizeMake(0,20); [content addSubview:hero];
    UILabel *small=[self label:@"WELCOME BACK" size:8 weight:UIFontWeightBlack color:[UIColor colorWithRed:.70 green:.57 blue:.94 alpha:1]]; [ZXTheme track:small spacing:2.0]; small.textAlignment=NSTextAlignmentCenter; small.translatesAutoresizingMaskIntoConstraints=NO; [hero addSubview:small];
    UILabel *title=[self label:@"Sign in" size:29 weight:UIFontWeightBlack color:[UIColor whiteColor]]; title.textAlignment=NSTextAlignmentCenter; title.translatesAutoresizingMaskIntoConstraints=NO; [hero addSubview:title];
    UILabel *subtitle=[self label:@"Enter your license key to continue." size:12 weight:UIFontWeightRegular color:[UIColor colorWithWhite:.49 alpha:1]]; subtitle.textAlignment=NSTextAlignmentCenter; subtitle.translatesAutoresizingMaskIntoConstraints=NO; [hero addSubview:subtitle];
    _keyInput=[[ZXPremiumField alloc] init]; _keyInput.translatesAutoresizingMaskIntoConstraints=NO; [hero addSubview:_keyInput];
    _loginBtn=[[ZXPremiumButton alloc] init]; [_loginBtn setTitle:ZXLocalizedUI(@"CONTINUE") forState:UIControlStateNormal]; _loginBtn.translatesAutoresizingMaskIntoConstraints=NO; [_loginBtn addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside]; [hero addSubview:_loginBtn];
    UIView *verified=[[UIView alloc] init]; verified.backgroundColor=[UIColor colorWithRed:.20 green:.08 blue:.34 alpha:.42]; verified.layer.cornerRadius=14; verified.layer.borderWidth=1; verified.layer.borderColor=[UIColor colorWithRed:.66 green:.45 blue:1 alpha:.18].CGColor; verified.translatesAutoresizingMaskIntoConstraints=NO; [hero addSubview:verified];
    UIImageView *shield=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.shield.fill"]]; shield.tintColor=[UIColor colorWithRed:.75 green:.64 blue:1 alpha:1]; shield.translatesAutoresizingMaskIntoConstraints=NO; [verified addSubview:shield];
    UILabel *vtxt=[self label:@"SERVER VERIFIED" size:8 weight:UIFontWeightBlack color:[UIColor colorWithRed:.79 green:.70 blue:1 alpha:1]]; [ZXTheme track:vtxt spacing:1.2]; vtxt.translatesAutoresizingMaskIntoConstraints=NO; [verified addSubview:vtxt];
    _authStatus=[self label:@"" size:10 weight:UIFontWeightMedium color:[UIColor colorWithWhite:.47 alpha:1]]; _authStatus.textAlignment=NSTextAlignmentCenter; _authStatus.numberOfLines=2; _authStatus.translatesAutoresizingMaskIntoConstraints=NO; [hero addSubview:_authStatus];

    [NSLayoutConstraint activateConstraints:@[
        [mark.topAnchor constraintEqualToAnchor:content.topAnchor constant:34],[mark.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],[mark.widthAnchor constraintEqualToConstant:70],[mark.heightAnchor constraintEqualToConstant:70],
        [brand.topAnchor constraintEqualToAnchor:mark.bottomAnchor constant:12],[brand.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],
        [caption.topAnchor constraintEqualToAnchor:brand.bottomAnchor constant:4],[caption.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],
        [hero.topAnchor constraintEqualToAnchor:caption.bottomAnchor constant:20],[hero.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:18],[hero.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-18],
        [small.topAnchor constraintEqualToAnchor:hero.topAnchor constant:23],[small.centerXAnchor constraintEqualToAnchor:hero.centerXAnchor],
        [title.topAnchor constraintEqualToAnchor:small.bottomAnchor constant:6],[title.centerXAnchor constraintEqualToAnchor:hero.centerXAnchor],
        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:5],[subtitle.leadingAnchor constraintEqualToAnchor:hero.leadingAnchor constant:20],[subtitle.trailingAnchor constraintEqualToAnchor:hero.trailingAnchor constant:-20],
        [_keyInput.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:20],[_keyInput.leadingAnchor constraintEqualToAnchor:hero.leadingAnchor constant:20],[_keyInput.trailingAnchor constraintEqualToAnchor:hero.trailingAnchor constant:-20],
        [_loginBtn.topAnchor constraintEqualToAnchor:_keyInput.bottomAnchor constant:12],[_loginBtn.leadingAnchor constraintEqualToAnchor:hero.leadingAnchor constant:20],[_loginBtn.trailingAnchor constraintEqualToAnchor:hero.trailingAnchor constant:-20],[_loginBtn.heightAnchor constraintEqualToConstant:52],
        [verified.topAnchor constraintEqualToAnchor:_loginBtn.bottomAnchor constant:14],[verified.centerXAnchor constraintEqualToAnchor:hero.centerXAnchor],[verified.heightAnchor constraintEqualToConstant:31],[verified.widthAnchor constraintEqualToConstant:154],
        [shield.leadingAnchor constraintEqualToAnchor:verified.leadingAnchor constant:10],[shield.centerYAnchor constraintEqualToAnchor:verified.centerYAnchor],[shield.widthAnchor constraintEqualToConstant:14],[shield.heightAnchor constraintEqualToConstant:14],
        [vtxt.leadingAnchor constraintEqualToAnchor:shield.trailingAnchor constant:6],[vtxt.trailingAnchor constraintEqualToAnchor:verified.trailingAnchor constant:-8],[vtxt.centerYAnchor constraintEqualToAnchor:verified.centerYAnchor],
        [_authStatus.topAnchor constraintEqualToAnchor:verified.bottomAnchor constant:10],[_authStatus.leadingAnchor constraintEqualToAnchor:hero.leadingAnchor constant:20],[_authStatus.trailingAnchor constraintEqualToAnchor:hero.trailingAnchor constant:-20],[_authStatus.bottomAnchor constraintEqualToAnchor:hero.bottomAnchor constant:-20],
        [content.bottomAnchor constraintGreaterThanOrEqualToAnchor:hero.bottomAnchor constant:34]
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
    [self.view endEditing:YES]; 
    [self.keyInput.textField resignFirstResponder];
    
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
                    self.authStatus.text = ZXLocalizedUI(@"Access granted.");
                    [self syncCompatibilityAfterSuccessfulLogin];
                    [self showDashboard];
                } else {
                    [self presentAuthError:errorType message:errorMsg];
                }
            });
        }];
    } else {
        Class mgrCls = NSClassFromString(@"ZentraxNetworkManager");
        if (mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
            id manager = ((id (*)(id, SEL))objc_msgSend)((id)mgrCls, NSSelectorFromString(@"sharedManager"));
            SEL authSel = NSSelectorFromString(@"authenticateWithKey:completion:");
            if ([manager respondsToSelector:authSel]) {
                void (^netCompletion)(BOOL, NSDictionary *, NSInteger, NSString *) = ^(BOOL success, NSDictionary *res, NSInteger errType, NSString *errMsg) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        __strong typeof(weakSelf) self = weakSelf;
                        if (!self) return;
                        [self hideGlobalLoadingState];
                        [self.loginBtn setLoading:NO];
                        if (success) {
                            self.authStatus.textColor = [ZXTheme success];
                            self.authStatus.text = ZXLocalizedUI(@"Access granted.");
                            [self syncCompatibilityAfterSuccessfulLogin];
                            [self showDashboard];
                        } else {
                            [self presentAuthError:(ZXAuthError)errType message:errMsg];
                        }
                    });
                };
                ((void (*)(id, SEL, id, id))objc_msgSend)(manager, authSel, key, netCompletion);
            }
        }
    }
}

- (void)syncCompatibilityAfterSuccessfulLogin {
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestCompatibilityRecheckWithCompletion:)]) {
        [self.delegate zentraxDidRequestCompatibilityRecheckWithCompletion:^(BOOL success, NSDictionary *compatibility, NSString *errorMsg) {
            if (success && [compatibility isKindOfClass:[NSDictionary class]]) {
                dispatch_async(dispatch_get_main_queue(), ^{ [self updateDeviceCompatibility:compatibility]; });
            }
        }];
        return;
    }
    Class mgrCls=NSClassFromString(@"ZentraxNetworkManager");
    if (mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
        id manager=((id(*)(id,SEL))objc_msgSend)((id)mgrCls,NSSelectorFromString(@"sharedManager"));
        SEL sel=NSSelectorFromString(@"requestDeviceCompatibilityRecheckWithCompletion:");
        if ([manager respondsToSelector:sel]) {
            void (^completion)(BOOL,NSDictionary *,NSString *)=^(BOOL success,NSDictionary *compatibility,NSString *errorMsg){ if(success && [compatibility isKindOfClass:[NSDictionary class]]) dispatch_async(dispatch_get_main_queue(), ^{ [self updateDeviceCompatibility:compatibility]; }); };
            ((void(*)(id,SEL,id))objc_msgSend)(manager,sel,completion);
        }
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
    if(_dashboardContainer) [_dashboardContainer removeFromSuperview];
    _dashboardContainer=[[UIView alloc] init];
    _dashboardContainer.translatesAutoresizingMaskIntoConstraints=NO;
    _dashboardContainer.backgroundColor=[ZXTheme background];
    [self.view addSubview:_dashboardContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_dashboardContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_dashboardContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_dashboardContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_dashboardContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    [self installPremiumBackdropOnContainer:_dashboardContainer];

    UIView *header=[[UIView alloc] init]; header.translatesAutoresizingMaskIntoConstraints=NO; [_dashboardContainer addSubview:header];

    UIImageView *logo=[[UIImageView alloc] initWithImage:[self preferredLogoImage]];
    logo.contentMode=UIViewContentModeScaleAspectFit; logo.translatesAutoresizingMaskIntoConstraints=NO; [header addSubview:logo];

    UILabel *brand=[self label:@"ZENTRAX" size:17 weight:UIFontWeightBlack color:[UIColor whiteColor]];
    [ZXTheme track:brand spacing:2.0]; brand.translatesAutoresizingMaskIntoConstraints=NO; [header addSubview:brand];

    _connectionLabel=[self label:@"● SECURE" size:8 weight:UIFontWeightBlack color:[ZXTheme success]];
    [ZXTheme track:_connectionLabel spacing:1.1]; _connectionLabel.textAlignment=NSTextAlignmentRight; _connectionLabel.translatesAutoresizingMaskIntoConstraints=NO; [header addSubview:_connectionLabel];

    UIButton *settingsBtn=[self iconButton:@"gearshape.fill" size:32];
    settingsBtn.tintColor=[UIColor colorWithRed:.72 green:.58 blue:1 alpha:1];
    [settingsBtn addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside]; [header addSubview:settingsBtn];

    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:20],
        [header.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-20],
        [header.topAnchor constraintEqualToAnchor:_dashboardContainer.safeAreaLayoutGuide.topAnchor constant:12],
        [header.heightAnchor constraintEqualToConstant:44],
        [logo.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],[logo.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [logo.widthAnchor constraintEqualToConstant:30],[logo.heightAnchor constraintEqualToConstant:30],
        [brand.leadingAnchor constraintEqualToAnchor:logo.trailingAnchor constant:9],[brand.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [settingsBtn.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],[settingsBtn.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [_connectionLabel.trailingAnchor constraintEqualToAnchor:settingsBtn.leadingAnchor constant:-11],[_connectionLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor]
    ]];

    _licenseCard=[self card];
    _licenseCard.backgroundColor=[UIColor colorWithRed:.045 green:.022 blue:.085 alpha:.97];
    _licenseCard.layer.cornerRadius=25; _licenseCard.layer.borderColor=[UIColor colorWithRed:.56 green:.34 blue:.90 alpha:.24].CGColor;
    _licenseCard.layer.shadowColor=[UIColor colorWithRed:.40 green:.18 blue:.78 alpha:1].CGColor; _licenseCard.layer.shadowOpacity=.22; _licenseCard.layer.shadowRadius=32; _licenseCard.layer.shadowOffset=CGSizeMake(0,18);
    [_dashboardContainer addSubview:_licenseCard];

    UILabel *cap=[self label:@"LICENSE" size:8 weight:UIFontWeightBlack color:[UIColor colorWithRed:.65 green:.51 blue:.85 alpha:1]];
    [ZXTheme track:cap spacing:1.7]; cap.translatesAutoresizingMaskIntoConstraints=NO; [_licenseCard addSubview:cap];

    _licenseStatusLabel=[self label:@"UNACTIVATED" size:9 weight:UIFontWeightBlack color:[ZXTheme warning]];
    [ZXTheme track:_licenseStatusLabel spacing:1.0]; _licenseStatusLabel.translatesAutoresizingMaskIntoConstraints=NO; [_licenseCard addSubview:_licenseStatusLabel];

    _countdownLabel=[self label:@"—" size:27 weight:UIFontWeightBlack color:[UIColor whiteColor]];
    _countdownLabel.translatesAutoresizingMaskIntoConstraints=NO; [_licenseCard addSubview:_countdownLabel];

    _expiryLabel=[self label:@"Awaiting first activation" size:11 weight:UIFontWeightMedium color:[UIColor colorWithWhite:.48 alpha:1]];
    _expiryLabel.translatesAutoresizingMaskIntoConstraints=NO; [_licenseCard addSubview:_expiryLabel];

    _keyRevealLabel=[self label:@"•••• •••• ••••" size:11 weight:UIFontWeightMedium color:[UIColor colorWithWhite:.48 alpha:1]];
    _keyRevealLabel.translatesAutoresizingMaskIntoConstraints=NO; [_licenseCard addSubview:_keyRevealLabel];

    _keyEyeButton=[self iconButton:@"eye.slash.fill" size:27]; _keyEyeButton.tintColor=[UIColor colorWithRed:.72 green:.57 blue:.98 alpha:1];
    [_keyEyeButton addTarget:self action:@selector(toggleDashboardKey) forControlEvents:UIControlEventTouchUpInside]; [_licenseCard addSubview:_keyEyeButton];

    [NSLayoutConstraint activateConstraints:@[
        [_licenseCard.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:18],
        [_licenseCard.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-18],
        [_licenseCard.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:18],
        [_licenseCard.heightAnchor constraintEqualToConstant:134],
        [cap.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:20],[cap.topAnchor constraintEqualToAnchor:_licenseCard.topAnchor constant:18],
        [_licenseStatusLabel.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor constant:-20],[_licenseStatusLabel.centerYAnchor constraintEqualToAnchor:cap.centerYAnchor],
        [_countdownLabel.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:20],[_countdownLabel.topAnchor constraintEqualToAnchor:cap.bottomAnchor constant:10],
        [_expiryLabel.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:20],[_expiryLabel.topAnchor constraintEqualToAnchor:_countdownLabel.bottomAnchor constant:2],
        [_expiryLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_licenseCard.trailingAnchor constant:-20],
        [_keyRevealLabel.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:20],[_keyRevealLabel.bottomAnchor constraintEqualToAnchor:_licenseCard.bottomAnchor constant:-15],
        [_keyRevealLabel.trailingAnchor constraintEqualToAnchor:_keyEyeButton.leadingAnchor constant:-6],
        [_keyEyeButton.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor constant:-13],[_keyEyeButton.centerYAnchor constraintEqualToAnchor:_keyRevealLabel.centerYAnchor]
    ]];

    UILabel *section=[self label:@"SECURE FUNCTIONS" size:9 weight:UIFontWeightBlack color:[UIColor colorWithRed:.64 green:.50 blue:.82 alpha:1]];
    [ZXTheme track:section spacing:1.7]; section.translatesAutoresizingMaskIntoConstraints=NO; [_dashboardContainer addSubview:section];

    _modulesScroll=[[UIScrollView alloc] init];
    _modulesScroll.showsVerticalScrollIndicator=NO; _modulesScroll.alwaysBounceVertical=YES; _modulesScroll.translatesAutoresizingMaskIntoConstraints=NO; [_dashboardContainer addSubview:_modulesScroll];

    _modulesStack=[[UIStackView alloc] init];
    _modulesStack.axis=UILayoutConstraintAxisVertical; _modulesStack.spacing=10; _modulesStack.translatesAutoresizingMaskIntoConstraints=NO; [_modulesScroll addSubview:_modulesStack];

    [NSLayoutConstraint activateConstraints:@[
        [section.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:22],
        [section.topAnchor constraintEqualToAnchor:_licenseCard.bottomAnchor constant:22],
        [section.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-22],
        [_modulesScroll.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:18],
        [_modulesScroll.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-18],
        [_modulesScroll.topAnchor constraintEqualToAnchor:section.bottomAnchor constant:10],
        [_modulesScroll.bottomAnchor constraintEqualToAnchor:_dashboardContainer.bottomAnchor],
        [_modulesStack.leadingAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.leadingAnchor],
        [_modulesStack.trailingAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.trailingAnchor],
        [_modulesStack.topAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.topAnchor constant:3],
        [_modulesStack.bottomAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.bottomAnchor constant:-34],
        [_modulesStack.widthAnchor constraintEqualToAnchor:_modulesScroll.frameLayoutGuide.widthAnchor]
    ]];
    [self createEmptyStateView];
}


- (void)toggleDashboardKey {
    self.keyRevealed = !self.keyRevealed;
    NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *key = [globalDefaults stringForKey:ZXLastKey];
    self.keyRevealLabel.text = self.keyRevealed && key.length ? key : @"•••• •••• ••••";
    [self.keyEyeButton setImage:[UIImage systemImageNamed:self.keyRevealed ? @"eye.fill" : @"eye.slash.fill"] forState:UIControlStateNormal];
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
        [_emptyState.heightAnchor constraintEqualToConstant:90],
        [title.centerYAnchor constraintEqualToAnchor:_emptyState.centerYAnchor constant:-8],
        [title.leadingAnchor constraintEqualToAnchor:_emptyState.leadingAnchor constant:20],
        [title.trailingAnchor constraintEqualToAnchor:_emptyState.trailingAnchor constant:-20],
        [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4],
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
            UIView *categoryCard = [[UIView alloc] init];
            categoryCard.translatesAutoresizingMaskIntoConstraints = NO;
            categoryCard.backgroundColor = [UIColor colorWithWhite:.045 alpha:.88];
            categoryCard.layer.cornerRadius = 13;
            categoryCard.layer.borderWidth = 1;
            categoryCard.layer.borderColor = [UIColor colorWithWhite:1 alpha:.065].CGColor;

            UIImageView *categoryIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"square.grid.2x2.fill"]];
            categoryIcon.tintColor = [UIColor colorWithWhite:.72 alpha:1];
            categoryIcon.translatesAutoresizingMaskIntoConstraints=NO;
            [categoryCard addSubview:categoryIcon];

            UILabel *cat=[self label:categoryName size:11 weight:UIFontWeightBlack color:[UIColor colorWithWhite:.83 alpha:1]];
            [ZXTheme track:cat spacing:1.3];
            cat.translatesAutoresizingMaskIntoConstraints=NO;
            [categoryCard addSubview:cat];

            UILabel *count=[self label:[NSString stringWithFormat:@"%lu MODULES",(unsigned long)functions.count] size:8 weight:UIFontWeightHeavy color:[UIColor colorWithWhite:.34 alpha:1]];
            [ZXTheme track:count spacing:1.0];
            count.translatesAutoresizingMaskIntoConstraints=NO;
            [categoryCard addSubview:count];

            [NSLayoutConstraint activateConstraints:@[
                [categoryCard.heightAnchor constraintEqualToConstant:46],
                [categoryIcon.leadingAnchor constraintEqualToAnchor:categoryCard.leadingAnchor constant:14],
                [categoryIcon.centerYAnchor constraintEqualToAnchor:categoryCard.centerYAnchor],
                [categoryIcon.widthAnchor constraintEqualToConstant:17],[categoryIcon.heightAnchor constraintEqualToConstant:17],
                [cat.leadingAnchor constraintEqualToAnchor:categoryIcon.trailingAnchor constant:9],
                [cat.centerYAnchor constraintEqualToAnchor:categoryCard.centerYAnchor],
                [count.trailingAnchor constraintEqualToAnchor:categoryCard.trailingAnchor constant:-14],
                [count.centerYAnchor constraintEqualToAnchor:categoryCard.centerYAnchor]
            ]];
            [_modulesStack addArrangedSubview:categoryCard];
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
}

- (UIView *)functionCardForDefinition:(NSDictionary *)definition functionId:(NSString *)fid isOn:(BOOL)on {
    UIView *card=[self card]; card.backgroundColor=[UIColor colorWithRed:.025 green:.012 blue:.058 alpha:.985]; card.layer.cornerRadius=22;
    card.layer.borderColor=(on ? [UIColor colorWithRed:.69 green:.45 blue:1 alpha:.44] : [UIColor colorWithWhite:1 alpha:.075]).CGColor;
    card.layer.shadowColor=[UIColor colorWithRed:.42 green:.16 blue:.92 alpha:1].CGColor; card.layer.shadowOpacity=on?.25:.12; card.layer.shadowRadius=24; card.layer.shadowOffset=CGSizeMake(0,12);
    UIView *rail=[[UIView alloc] init]; rail.translatesAutoresizingMaskIntoConstraints=NO; rail.backgroundColor=on?[ZXTheme accent]:[UIColor colorWithWhite:.18 alpha:1]; rail.layer.cornerRadius=2; [card addSubview:rail];
    UIView *iconPlate=[[UIView alloc] init]; iconPlate.translatesAutoresizingMaskIntoConstraints=NO; iconPlate.backgroundColor=on?[UIColor colorWithRed:.25 green:.10 blue:.48 alpha:.70]:[UIColor colorWithWhite:.065 alpha:1]; iconPlate.layer.cornerRadius=16; iconPlate.layer.borderWidth=1; iconPlate.layer.borderColor=(on?[UIColor colorWithRed:.72 green:.49 blue:1 alpha:.32]:[UIColor colorWithWhite:1 alpha:.07]).CGColor; [card addSubview:iconPlate];
    UIImageView *icon=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:(on?@"bolt.shield.fill":@"shield.lefthalf.filled")]]; icon.tintColor=on?[UIColor colorWithRed:.86 green:.77 blue:1 alpha:1]:[UIColor colorWithWhite:.52 alpha:1]; icon.translatesAutoresizingMaskIntoConstraints=NO; [iconPlate addSubview:icon];
    NSString *name=[NSString stringWithFormat:@"%@",definition[@"name"]?:definition[@"title"]?:fid];
    UILabel *title=[self label:name size:15 weight:UIFontWeightBlack color:[UIColor whiteColor]]; title.numberOfLines=2; title.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:title];
    NSString *description=[NSString stringWithFormat:@"%@",definition[@"description"]?:@"Server-managed function"]; UILabel *detail=[self label:description size:10 weight:UIFontWeightRegular color:[UIColor colorWithWhite:.46 alpha:1]]; detail.numberOfLines=2; detail.lineBreakMode=NSLineBreakByTruncatingTail; detail.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:detail];
    UILabel *state=[self label:on?@"ACTIVE":@"READY" size:8 weight:UIFontWeightBlack color:on?[UIColor colorWithRed:.73 green:.59 blue:1 alpha:1]:[UIColor colorWithWhite:.39 alpha:1]]; [ZXTheme track:state spacing:1.2]; state.textAlignment=NSTextAlignmentRight; state.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:state]; self.functionStateLabels[fid]=state;
    UISwitch *toggle=[[UISwitch alloc] init]; toggle.onTintColor=[ZXTheme accent]; toggle.thumbTintColor=[UIColor whiteColor]; toggle.tintColor=[UIColor colorWithWhite:.17 alpha:1]; toggle.on=on; toggle.translatesAutoresizingMaskIntoConstraints=NO; [toggle addTarget:self action:@selector(functionToggleChanged:) forControlEvents:UIControlEventValueChanged]; [card addSubview:toggle]; self.functionControls[fid]=toggle;
    [NSLayoutConstraint activateConstraints:@[
        [card.heightAnchor constraintGreaterThanOrEqualToConstant:112],
        [rail.leadingAnchor constraintEqualToAnchor:card.leadingAnchor], [rail.topAnchor constraintEqualToAnchor:card.topAnchor constant:17], [rail.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-17], [rail.widthAnchor constraintEqualToConstant:3],
        [iconPlate.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16], [iconPlate.topAnchor constraintEqualToAnchor:card.topAnchor constant:17], [iconPlate.widthAnchor constraintEqualToConstant:46], [iconPlate.heightAnchor constraintEqualToConstant:46],
        [icon.centerXAnchor constraintEqualToAnchor:iconPlate.centerXAnchor], [icon.centerYAnchor constraintEqualToAnchor:iconPlate.centerYAnchor], [icon.widthAnchor constraintEqualToConstant:22], [icon.heightAnchor constraintEqualToConstant:22],
        [state.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-17], [state.topAnchor constraintEqualToAnchor:card.topAnchor constant:17], [state.leadingAnchor constraintGreaterThanOrEqualToAnchor:title.trailingAnchor constant:7],
        [title.leadingAnchor constraintEqualToAnchor:iconPlate.trailingAnchor constant:13], [title.topAnchor constraintEqualToAnchor:card.topAnchor constant:17], [title.trailingAnchor constraintLessThanOrEqualToAnchor:card.trailingAnchor constant:-70],
        [detail.leadingAnchor constraintEqualToAnchor:title.leadingAnchor], [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4], [detail.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],
        [toggle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16], [toggle.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14]
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
                if (msg.length > 0) {
                    [self showGlobalErrorWithTitle:ZXLocalizedUI(@"OPERATION FAILED") message:msg];
                }
            }
        });
    };

    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestFunctionOperation:action:completion:)]) {
        [self.delegate zentraxDidRequestFunctionOperation:fid action:requested completion:finish];
    } else if ([self.delegate respondsToSelector:@selector(zentraxDidRequestModuleToggle:state:completion:)]) {
        [self.delegate zentraxDidRequestModuleToggle:fid state:requested completion:finish];
    } else {
        Class mgrCls = NSClassFromString(@"ZentraxNetworkManager");
        if (mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
            id manager = ((id (*)(id, SEL))objc_msgSend)((id)mgrCls, NSSelectorFromString(@"sharedManager"));
            SEL operSel = NSSelectorFromString(@"performModuleOperationWithFunctionId:action:completion:");
            if ([manager respondsToSelector:operSel]) {
                void (^netCompletion)(BOOL, NSDictionary *, NSString *) = ^(BOOL succ, NSDictionary *res, NSString *err) { finish(succ, err); };
                ((void (*)(id, SEL, id, NSInteger, id))objc_msgSend)(manager, operSel, fid, requested ? 2 : 1, netCompletion);
            } else {
                finish(NO, @"Function operation bridge is unavailable.");
            }
        } else {
            finish(NO, @"Function operation bridge is unavailable.");
        }
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
    // Basic banner handling preserved
}

#pragma mark - Subscription / Time

- (void)updateSubscriptionState:(NSDictionary *)subData {
    if (![subData isKindOfClass:[NSDictionary class]]) return;
    NSString *statusRaw = subData[@"status"];
    
    // Strict guard to prevent valid permanent license from reverting to unactivated due to sparse heartbeat payload
    if (!statusRaw && self.licenseStatus == ZXLicenseUIStatusActive) return;
    
    NSString *status = [[NSString stringWithFormat:@"%@", (statusRaw ?: @"unknown")] lowercaseString];
    
    ZXLicenseUIStatus uiStatus = ZXLicenseUIStatusUnknown;
    if ([status isEqualToString:@"unactivated"]) uiStatus = ZXLicenseUIStatusUnactivated;
    else if ([status isEqualToString:@"active"]) uiStatus = ZXLicenseUIStatusActive;
    else if ([status isEqualToString:@"expired"]) uiStatus = ZXLicenseUIStatusExpired;
    else if ([status isEqualToString:@"revoked"]) uiStatus = ZXLicenseUIStatusRevoked;
    else if ([status isEqualToString:@"disabled"]) uiStatus = ZXLicenseUIStatusDisabled;

    NSDate *activated = [self dateFromServerValue:subData[@"activated_at"]];
    NSDate *expires = [self dateFromServerValue:subData[@"expires_at"]];
    BOOL permanent = [subData[@"is_permanent"] boolValue];
    
    // If we already know the license is permanent, do not let an omitted 'is_permanent' flag downgrade it.
    if (subData[@"is_permanent"] == nil && self.licensePermanent) permanent = YES;
    
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
        [self stopLicenseCountdown];
    } else if (expiresAt) {
        [self startLicenseCountdown];
        [self refreshLicenseCountdown];
    } else if (status == ZXLicenseUIStatusUnactivated) {
        _countdownLabel.text = ZXLocalizedUI(@"NOT STARTED");
        _expiryLabel.text = ZXLocalizedUI(@"Awaiting first activation");
        [self stopLicenseCountdown];
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
    _startupBlockContainer=[[UIView alloc] init];
    _startupBlockContainer.translatesAutoresizingMaskIntoConstraints=NO;
    _startupBlockContainer.backgroundColor=[ZXTheme background];
    [self.view addSubview:_startupBlockContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_startupBlockContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_startupBlockContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_startupBlockContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_startupBlockContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    [self installPremiumBackdropOnContainer:_startupBlockContainer];

    UIView *card=[self card];
    card.backgroundColor=[UIColor colorWithRed:.035 green:.018 blue:.068 alpha:.98];
    card.layer.cornerRadius=28; card.layer.borderColor=[UIColor colorWithRed:.57 green:.36 blue:.92 alpha:.26].CGColor;
    card.layer.shadowColor=[UIColor colorWithRed:.40 green:.16 blue:.78 alpha:1].CGColor; card.layer.shadowOpacity=.28; card.layer.shadowRadius=40; card.layer.shadowOffset=CGSizeMake(0,22);
    [_startupBlockContainer addSubview:card];

    UIView *plate=[[UIView alloc] init];
    plate.backgroundColor=[UIColor colorWithRed:.24 green:.10 blue:.43 alpha:.76]; plate.layer.cornerRadius=28;
    plate.layer.borderWidth=1; plate.layer.borderColor=[UIColor colorWithRed:.70 green:.46 blue:1 alpha:.25].CGColor; plate.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:plate];

    UIImageView *icon=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.shield.fill"]];
    icon.tintColor=[UIColor colorWithRed:.83 green:.71 blue:1 alpha:1]; icon.contentMode=UIViewContentModeScaleAspectFit; icon.translatesAutoresizingMaskIntoConstraints=NO; [plate addSubview:icon];

    _startupBlockTitle=[self label:@"SECURITY GATE" size:22 weight:UIFontWeightBlack color:[UIColor whiteColor]];
    _startupBlockTitle.textAlignment=NSTextAlignmentCenter; _startupBlockTitle.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:_startupBlockTitle];

    _startupBlockMessage=[self label:@"" size:12 weight:UIFontWeightRegular color:[UIColor colorWithWhite:.54 alpha:1]];
    _startupBlockMessage.textAlignment=NSTextAlignmentCenter; _startupBlockMessage.numberOfLines=0; _startupBlockMessage.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:_startupBlockMessage];

    _startupBlockAction=[UIButton buttonWithType:UIButtonTypeSystem];
    [self styleSecondaryButton:_startupBlockAction];
    [_startupBlockAction setTitle:ZXLocalizedUI(@"RETRY") forState:UIControlStateNormal];
    _startupBlockAction.translatesAutoresizingMaskIntoConstraints=NO; [_startupBlockAction addTarget:self action:@selector(startupBlockRetry) forControlEvents:UIControlEventTouchUpInside]; [card addSubview:_startupBlockAction];

    [NSLayoutConstraint activateConstraints:@[
        [card.leadingAnchor constraintGreaterThanOrEqualToAnchor:_startupBlockContainer.leadingAnchor constant:20],
        [card.trailingAnchor constraintLessThanOrEqualToAnchor:_startupBlockContainer.trailingAnchor constant:-20],
        [card.centerXAnchor constraintEqualToAnchor:_startupBlockContainer.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:_startupBlockContainer.centerYAnchor],
        [card.widthAnchor constraintLessThanOrEqualToConstant:390],
        [card.widthAnchor constraintGreaterThanOrEqualToConstant:280],
        [plate.topAnchor constraintEqualToAnchor:card.topAnchor constant:28],[plate.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [plate.widthAnchor constraintEqualToConstant:56],[plate.heightAnchor constraintEqualToConstant:56],
        [icon.centerXAnchor constraintEqualToAnchor:plate.centerXAnchor],[icon.centerYAnchor constraintEqualToAnchor:plate.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:25],[icon.heightAnchor constraintEqualToConstant:25],
        [_startupBlockTitle.topAnchor constraintEqualToAnchor:plate.bottomAnchor constant:16],
        [_startupBlockTitle.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],[_startupBlockTitle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [_startupBlockMessage.topAnchor constraintEqualToAnchor:_startupBlockTitle.bottomAnchor constant:8],
        [_startupBlockMessage.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],[_startupBlockMessage.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        [_startupBlockAction.topAnchor constraintEqualToAnchor:_startupBlockMessage.bottomAnchor constant:20],
        [_startupBlockAction.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22],[_startupBlockAction.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-22],
        [_startupBlockAction.heightAnchor constraintEqualToConstant:50],[_startupBlockAction.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-22]
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
            Class mgrCls = NSClassFromString(@"ZentraxNetworkManager");
            if (mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
                id manager = ((id (*)(id, SEL))objc_msgSend)((id)mgrCls, NSSelectorFromString(@"sharedManager"));
                SEL verifySel = NSSelectorFromString(@"verifySessionWithCompletion:");
                if ([manager respondsToSelector:verifySel]) {
                    void (^netCompletion)(BOOL, NSDictionary *, NSInteger, NSString *) = ^(BOOL valid, NSDictionary *res, NSInteger errType, NSString *errMsg) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (valid) [self showDashboard]; else [self showLoginScreen];
                        });
                    };
                    ((void (*)(id, SEL, id))objc_msgSend)(manager, verifySel, netCompletion);
                } else [self showLoginScreen];
            } else [self showLoginScreen];
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
    if (self.safeModeEnabled && self.safeModeState != ZXSafeModeStateUnlocked) { [self showSafeModeLockScreen]; return; }
    self.startupState = ZXStartupStateBootstrapping;
    [self showStartupState:ZXStartupStateBootstrapping message:nil];

    Class cls = NSClassFromString(@"ZentraxNetworkManager");
    if (!cls || ![cls respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
        [self handleBootstrapState:ZXStartupStateReady message:nil];
        return;
    }
    id manager = ((id (*)(id, SEL))objc_msgSend)((id)cls, NSSelectorFromString(@"sharedManager"));
    SEL bootstrap = NSSelectorFromString(@"bootstrapWithCompletion:");
    if (!manager || ![manager respondsToSelector:bootstrap]) {
        [self handleBootstrapState:ZXStartupStateReady message:nil];
        return;
    }
    __weak typeof(self) weakSelf = self;
    
    void (^completion)(BOOL, NSDictionary *, NSInteger, NSInteger, NSString *) = ^(BOOL success, NSDictionary *response, NSInteger bootstrapState, NSInteger errorType, NSString *errorMsg) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        ZXStartupState state = ZXStartupStateConnectionError;
        switch (bootstrapState) {
            case 1: state = ZXStartupStateReady; break;
            case 2: state = ZXStartupStateMaintenance; break;
            case 3: state = ZXStartupStateVersionMismatch; break;
            case 4: state = ZXStartupStateIncompatible; break;
            case 5: state = ZXStartupStateConnectionError; break;
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
    };
    
    ((void(*)(id, SEL, id))objc_msgSend)(manager, bootstrap, completion);
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
    if (![self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) {
        Class mgrCls = NSClassFromString(@"ZentraxNetworkManager");
        if (mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
            id manager = ((id (*)(id, SEL))objc_msgSend)((id)mgrCls, NSSelectorFromString(@"sharedManager"));
            SEL verifySel = NSSelectorFromString(@"verifySessionWithCompletion:");
            if ([manager respondsToSelector:verifySel]) {
                __weak typeof(self) weakSelf = self;
                void (^netCompletion)(BOOL, NSDictionary *, NSInteger, NSString *) = ^(BOOL valid, NSDictionary *res, NSInteger errType, NSString *errMsg) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        __strong typeof(weakSelf) self = weakSelf; if (!self) return;
                        if (!valid) [self handleRevokedSessionEnvironment];
                        else { 
                            self.connectionLabel.text = ZXLocalizedUI(@"● SECURE"); 
                            self.connectionLabel.textColor = [ZXTheme success]; 
                            if (res[@"license"]) [self updateSubscriptionState:res[@"license"]];
                        }
                    });
                };
                ((void (*)(id, SEL, id))objc_msgSend)(manager, verifySel, netCompletion);
            }
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL valid) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf; if (!self) return;
            if (!valid) [self handleRevokedSessionEnvironment];
            else { self.connectionLabel.text = ZXLocalizedUI(@"● SECURE"); self.connectionLabel.textColor = [ZXTheme success]; }
        });
    }];
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
        Class mgrCls = NSClassFromString(@"ZentraxNetworkManager");
        if (mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
            id manager = ((id (*)(id, SEL))objc_msgSend)((id)mgrCls, NSSelectorFromString(@"sharedManager"));
            SEL outSel = NSSelectorFromString(@"logout");
            if ([manager respondsToSelector:outSel]) {
                ((void (*)(id, SEL))objc_msgSend)(manager, outSel);
            }
        }
        NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
        [globalDefaults removeObjectForKey:ZXLastKey];
        [globalDefaults synchronize];
        [self showLoginScreen];
    }
}

#pragma mark - Settings

- (void)setupSettingsScreen {
    if(_settingsContainer) [_settingsContainer removeFromSuperview];
    _settingsContainer=[[UIView alloc] init]; _settingsContainer.translatesAutoresizingMaskIntoConstraints=NO; _settingsContainer.backgroundColor=[ZXTheme background]; [self.view addSubview:_settingsContainer];
    [NSLayoutConstraint activateConstraints:@[[_settingsContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],[_settingsContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],[_settingsContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],[_settingsContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]]];
    [self installPremiumBackdropOnContainer:_settingsContainer];
    UIView *header=[[UIView alloc] init]; header.translatesAutoresizingMaskIntoConstraints=NO; [_settingsContainer addSubview:header];
    UIButton *back=[self iconButton:@"chevron.left" size:38]; back.backgroundColor=[UIColor colorWithWhite:1 alpha:.045]; back.layer.cornerRadius=13; back.layer.borderWidth=1; back.layer.borderColor=[UIColor colorWithWhite:1 alpha:.08].CGColor; back.tintColor=[UIColor colorWithRed:.78 green:.64 blue:1 alpha:1]; [back addTarget:self action:@selector(closeSettings) forControlEvents:UIControlEventTouchUpInside]; [header addSubview:back];
    UILabel *title=[self label:@"Settings" size:28 weight:UIFontWeightBlack color:[UIColor whiteColor]]; title.translatesAutoresizingMaskIntoConstraints=NO; [header addSubview:title];
    UILabel *sub=[self label:@"ZENTRAX CONTROL CENTER" size:8 weight:UIFontWeightBlack color:[UIColor colorWithRed:.63 green:.50 blue:.84 alpha:1]]; [ZXTheme track:sub spacing:1.7]; sub.translatesAutoresizingMaskIntoConstraints=NO; [header addSubview:sub];
    [NSLayoutConstraint activateConstraints:@[[header.leadingAnchor constraintEqualToAnchor:_settingsContainer.leadingAnchor constant:18],[header.trailingAnchor constraintEqualToAnchor:_settingsContainer.trailingAnchor constant:-18],[header.topAnchor constraintEqualToAnchor:_settingsContainer.safeAreaLayoutGuide.topAnchor constant:10],[header.heightAnchor constraintEqualToConstant:62],[back.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],[back.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],[title.leadingAnchor constraintEqualToAnchor:back.trailingAnchor constant:12],[title.topAnchor constraintEqualToAnchor:header.topAnchor constant:3],[sub.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],[sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:2]]];
    _settingsScroll=[[UIScrollView alloc] init]; _settingsScroll.showsVerticalScrollIndicator=NO; _settingsScroll.alwaysBounceVertical=YES; _settingsScroll.translatesAutoresizingMaskIntoConstraints=NO; [_settingsContainer addSubview:_settingsScroll];
    _settingsStack=[[UIStackView alloc] init]; _settingsStack.axis=UILayoutConstraintAxisVertical; _settingsStack.spacing=11; _settingsStack.translatesAutoresizingMaskIntoConstraints=NO; [_settingsScroll addSubview:_settingsStack];
    [NSLayoutConstraint activateConstraints:[[_settingsScroll.leadingAnchor constraintEqualToAnchor:_settingsContainer.leadingAnchor constant:18],[_settingsScroll.trailingAnchor constraintEqualToAnchor:_settingsContainer.trailingAnchor constant:-18],[_settingsScroll.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:6],[_settingsScroll.bottomAnchor constraintEqualToAnchor:_settingsContainer.bottomAnchor],[_settingsStack.leadingAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.leadingAnchor],[_settingsStack.trailingAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.trailingAnchor],[_settingsStack.topAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.topAnchor],[_settingsStack.bottomAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.bottomAnchor constant:-28],[_settingsStack.widthAnchor constraintEqualToAnchor:_settingsScroll.frameLayoutGuide.widthAnchor]]];
    [self rebuildSettings];
}


- (UIView *)settingsRow:(NSString *)title subtitle:(NSString *)subtitle icon:(NSString *)iconName action:(SEL)action accessory:(UIView *)accessory {
    UIControl *row=[UIControl new]; row.translatesAutoresizingMaskIntoConstraints=NO; row.backgroundColor=[UIColor colorWithRed:.024 green:.012 blue:.055 alpha:.985]; row.layer.cornerRadius=21; row.layer.borderWidth=1; row.layer.borderColor=[UIColor colorWithRed:.48 green:.29 blue:.80 alpha:.18].CGColor; row.layer.shadowColor=[UIColor colorWithRed:.36 green:.12 blue:.82 alpha:1].CGColor; row.layer.shadowOpacity=.10; row.layer.shadowRadius=18; row.layer.shadowOffset=CGSizeMake(0,9);
    [row addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    UIView *iconPlate=[[UIView alloc] init]; iconPlate.translatesAutoresizingMaskIntoConstraints=NO; iconPlate.backgroundColor=[UIColor colorWithRed:.16 green:.07 blue:.30 alpha:.50]; iconPlate.layer.cornerRadius=15; iconPlate.layer.borderWidth=1; iconPlate.layer.borderColor=[UIColor colorWithRed:.66 green:.43 blue:1 alpha:.18].CGColor; [row addSubview:iconPlate];
    UIImageView *iv=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:iconName]]; iv.tintColor=[UIColor colorWithRed:.76 green:.62 blue:1 alpha:1]; iv.translatesAutoresizingMaskIntoConstraints=NO; [iconPlate addSubview:iv];
    UILabel *t=[self label:title size:14 weight:UIFontWeightBlack color:[UIColor whiteColor]]; t.translatesAutoresizingMaskIntoConstraints=NO; [row addSubview:t];
    UILabel *subl=[self label:subtitle size:10 weight:UIFontWeightRegular color:[UIColor colorWithWhite:.46 alpha:1]]; subl.numberOfLines=2; subl.translatesAutoresizingMaskIntoConstraints=NO; [row addSubview:subl];
    UIImageView *chev=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]]; chev.tintColor=[UIColor colorWithRed:.60 green:.46 blue:.80 alpha:1]; chev.translatesAutoresizingMaskIntoConstraints=NO; [row addSubview:chev];
    [NSLayoutConstraint activateConstraints:@[[row.heightAnchor constraintGreaterThanOrEqualToConstant:82],[iconPlate.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:14],[iconPlate.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],[iconPlate.widthAnchor constraintEqualToConstant:48],[iconPlate.heightAnchor constraintEqualToConstant:48],[iv.centerXAnchor constraintEqualToAnchor:iconPlate.centerXAnchor],[iv.centerYAnchor constraintEqualToAnchor:iconPlate.centerYAnchor],[iv.widthAnchor constraintEqualToConstant:21],[iv.heightAnchor constraintEqualToConstant:21],[t.leadingAnchor constraintEqualToAnchor:iconPlate.trailingAnchor constant:14],[t.topAnchor constraintEqualToAnchor:row.topAnchor constant:17],[t.trailingAnchor constraintLessThanOrEqualToAnchor:chev.leadingAnchor constant:-10],[subl.leadingAnchor constraintEqualToAnchor:t.leadingAnchor],[subl.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:4],[subl.trailingAnchor constraintLessThanOrEqualToAnchor:chev.leadingAnchor constant:-10],[subl.bottomAnchor constraintLessThanOrEqualToAnchor:row.bottomAnchor constant:-15],[chev.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-17],[chev.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],[chev.widthAnchor constraintEqualToConstant:14],[chev.heightAnchor constraintEqualToConstant:18]]];
    if(accessory){ accessory.translatesAutoresizingMaskIntoConstraints=NO; [row addSubview:accessory]; [NSLayoutConstraint activateConstraints:@[[accessory.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-14],[accessory.centerYAnchor constraintEqualToAnchor:row.centerYAnchor]]]; }
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
    
    UIView *safeCard = [self card];
    safeCard.backgroundColor = [UIColor colorWithWhite:.045 alpha:.98];
    safeCard.layer.cornerRadius = 18;
    safeCard.layer.borderColor = [UIColor colorWithWhite:1 alpha:.085].CGColor;

    UIImageView *safeIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.shield.fill"]];
    safeIcon.tintColor = self.safeModeEnabled ? [UIColor whiteColor] : [UIColor colorWithWhite:.55 alpha:1];
    safeIcon.translatesAutoresizingMaskIntoConstraints=NO;
    [safeCard addSubview:safeIcon];

    UILabel *safeTitle=[self label:@"Safe UI Mode" size:15 weight:UIFontWeightBlack color:[UIColor whiteColor]];
    safeTitle.translatesAutoresizingMaskIntoConstraints=NO; [safeCard addSubview:safeTitle];
    UILabel *safeSub=[self label:self.safeModeEnabled ? @"Protected lock screen is enabled" : @"Protect this workspace with a private 6-digit PIN" size:10 weight:UIFontWeightRegular color:[UIColor colorWithWhite:.45 alpha:1]];
    safeSub.numberOfLines=2; safeSub.translatesAutoresizingMaskIntoConstraints=NO; [safeCard addSubview:safeSub];

    UIButton *safeAction=[UIButton buttonWithType:UIButtonTypeSystem];
    safeAction.layer.cornerRadius=11;
    safeAction.layer.borderWidth=1;
    safeAction.layer.borderColor=(self.safeModeEnabled ? [UIColor colorWithWhite:1 alpha:.13] : [UIColor colorWithWhite:1 alpha:.09]).CGColor;
    safeAction.backgroundColor=self.safeModeEnabled ? [UIColor colorWithWhite:1 alpha:.07] : [UIColor colorWithWhite:1 alpha:.045];
    safeAction.titleLabel.font=[UIFont systemFontOfSize:9 weight:UIFontWeightHeavy];
    [safeAction setTitle:self.safeModeEnabled ? @"MANAGE" : @"ENABLE" forState:UIControlStateNormal];
    [safeAction setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [safeAction addTarget:self action:(self.safeModeEnabled ? @selector(manageSafeMode) : @selector(showSafeModeSettings)) forControlEvents:UIControlEventTouchUpInside];
    safeAction.translatesAutoresizingMaskIntoConstraints=NO; [safeCard addSubview:safeAction];

    [NSLayoutConstraint activateConstraints:@[
        [safeCard.heightAnchor constraintGreaterThanOrEqualToConstant:88],
        [safeIcon.leadingAnchor constraintEqualToAnchor:safeCard.leadingAnchor constant:18],
        [safeIcon.centerYAnchor constraintEqualToAnchor:safeCard.centerYAnchor],
        [safeIcon.widthAnchor constraintEqualToConstant:23],[safeIcon.heightAnchor constraintEqualToConstant:23],
        [safeTitle.leadingAnchor constraintEqualToAnchor:safeIcon.trailingAnchor constant:13],
        [safeTitle.topAnchor constraintEqualToAnchor:safeCard.topAnchor constant:18],
        [safeTitle.trailingAnchor constraintLessThanOrEqualToAnchor:safeAction.leadingAnchor constant:-12],
        [safeSub.leadingAnchor constraintEqualToAnchor:safeTitle.leadingAnchor],
        [safeSub.topAnchor constraintEqualToAnchor:safeTitle.bottomAnchor constant:5],
        [safeSub.trailingAnchor constraintLessThanOrEqualToAnchor:safeAction.leadingAnchor constant:-12],
        [safeSub.bottomAnchor constraintLessThanOrEqualToAnchor:safeCard.bottomAnchor constant:-16],
        [safeAction.trailingAnchor constraintEqualToAnchor:safeCard.trailingAnchor constant:-17],
        [safeAction.centerYAnchor constraintEqualToAnchor:safeCard.centerYAnchor],
        [safeAction.widthAnchor constraintGreaterThanOrEqualToConstant:72],
        [safeAction.heightAnchor constraintEqualToConstant:38]
    ]];
    [self.settingsStack addArrangedSubview:safeCard];

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
    

    UILabel *accLabel = [self label:@"ACCOUNT" size:10 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:accLabel spacing:1.5];
    [self.settingsStack addArrangedSubview:accLabel];
    [self.settingsStack addArrangedSubview:[self settingsRow:@"Sign Out" subtitle:@"Close the current secure session" icon:@"rectangle.portrait.and.arrow.right" action:@selector(handleLogout) accessory:nil]];
}

- (UIView *)buildDeviceCard {
    UIView *card=[self card]; card.backgroundColor=[UIColor colorWithRed:.025 green:.012 blue:.058 alpha:.985]; card.layer.cornerRadius=23; card.layer.borderColor=[UIColor colorWithRed:.53 green:.34 blue:.88 alpha:.22].CGColor;
    NSString *device=ZXSafeString(self.compatibilityData[@"device_name"],UIDevice.currentDevice.model); NSString *ios=ZXSafeString(self.compatibilityData[@"ios_version"],UIDevice.currentDevice.systemVersion); NSString *statusValue=[[NSString stringWithFormat:@"%@",self.compatibilityData[@"status"]?:@"unknown"] lowercaseString];
    BOOL supported=[@[@"supported",@"compatible",@"verified",@"ok"] containsObject:statusValue]; BOOL unsupported=[@[@"unsupported",@"incompatible",@"rejected"] containsObject:statusValue];
    UIColor *stateColor=supported?[ZXTheme success]:(unsupported?[ZXTheme error]:[ZXTheme warning]); NSString *stateText=supported?@"VERIFIED":(unsupported?@"NOT SUPPORTED":@"SYNCING");
    UIView *stateDot=[[UIView alloc] init]; stateDot.translatesAutoresizingMaskIntoConstraints=NO; stateDot.backgroundColor=stateColor; stateDot.layer.cornerRadius=4; [card addSubview:stateDot];
    UILabel *state=[self label:stateText size:8 weight:UIFontWeightBlack color:stateColor]; [ZXTheme track:state spacing:1.3]; state.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:state];
    UILabel *deviceLabel=[self label:device size:17 weight:UIFontWeightBlack color:[UIColor whiteColor]]; deviceLabel.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:deviceLabel];
    UILabel *iosLabel=[self label:[NSString stringWithFormat:@"iOS %@",ios] size:10 weight:UIFontWeightMedium color:[ZXTheme secondaryText]]; iosLabel.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:iosLabel];
    UILabel *headline=[self label:supported?@"Congratulations — your device is compatible.":(unsupported?@"This device did not support ZENTRAX.":@"Synchronizing device compatibility…") size:13 weight:UIFontWeightSemibold color:[UIColor whiteColor]]; headline.numberOfLines=2; headline.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:headline];
    UILabel *detail=[self label:supported?@"Verified automatically during secure login.":(unsupported?@"This device cannot use the current workspace.":@"Compatibility will update automatically after login.") size:10 weight:UIFontWeightRegular color:[UIColor colorWithWhite:.46 alpha:1]]; detail.numberOfLines=2; detail.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:detail];
    UIButton *refresh=[UIButton buttonWithType:UIButtonTypeSystem]; [refresh setImage:[UIImage systemImageNamed:@"arrow.clockwise"] forState:UIControlStateNormal]; refresh.tintColor=[UIColor colorWithRed:.80 green:.69 blue:1 alpha:1]; refresh.backgroundColor=[UIColor colorWithRed:.18 green:.075 blue:.34 alpha:.72]; refresh.layer.cornerRadius=16; refresh.layer.borderWidth=1; refresh.layer.borderColor=[UIColor colorWithRed:.68 green:.46 blue:1 alpha:.24].CGColor; refresh.translatesAutoresizingMaskIntoConstraints=NO; [refresh addTarget:self action:@selector(requestDeviceCompatibilityRecheck) forControlEvents:UIControlEventTouchUpInside]; [card addSubview:refresh];
    [NSLayoutConstraint activateConstraints:@[[card.heightAnchor constraintEqualToConstant:156],[deviceLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],[deviceLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:17],[iosLabel.leadingAnchor constraintEqualToAnchor:deviceLabel.leadingAnchor],[iosLabel.topAnchor constraintEqualToAnchor:deviceLabel.bottomAnchor constant:2],[stateDot.trailingAnchor constraintEqualToAnchor:state.leadingAnchor constant:-6],[stateDot.centerYAnchor constraintEqualToAnchor:deviceLabel.centerYAnchor],[stateDot.widthAnchor constraintEqualToConstant:8],[stateDot.heightAnchor constraintEqualToConstant:8],[state.trailingAnchor constraintEqualToAnchor:refresh.leadingAnchor constant:-8],[state.centerYAnchor constraintEqualToAnchor:stateDot.centerYAnchor],[refresh.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-15],[refresh.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],[refresh.widthAnchor constraintEqualToConstant:32],[refresh.heightAnchor constraintEqualToConstant:32],[headline.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],[headline.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],[headline.topAnchor constraintEqualToAnchor:iosLabel.bottomAnchor constant:14],[detail.leadingAnchor constraintEqualToAnchor:headline.leadingAnchor],[detail.trailingAnchor constraintEqualToAnchor:headline.trailingAnchor],[detail.topAnchor constraintEqualToAnchor:headline.bottomAnchor constant:4],[detail.bottomAnchor constraintLessThanOrEqualToAnchor:card.bottomAnchor constant:-15]]];
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

- (void)manageSafeMode {
    if (!self.safeModeEnabled) { [self showSafeModeSettings]; return; }
    self.safeModeCreatingPasscode = NO;
    self.safeModeDisabling = YES;
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
    _safeLockContainer=[[UIView alloc] init]; _safeLockContainer.translatesAutoresizingMaskIntoConstraints=NO; _safeLockContainer.backgroundColor=[UIColor colorWithRed:.012 green:.006 blue:.028 alpha:1]; [self.view addSubview:_safeLockContainer];
    [NSLayoutConstraint activateConstraints:[[_safeLockContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],[_safeLockContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],[_safeLockContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],[_safeLockContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]]]; [self installPremiumBackdropOnContainer:_safeLockContainer];
    _safeLockBackButton=[self iconButton:@"xmark" size:38]; _safeLockBackButton.backgroundColor=[UIColor colorWithWhite:1 alpha:.045]; _safeLockBackButton.layer.cornerRadius=13; _safeLockBackButton.layer.borderWidth=1; _safeLockBackButton.layer.borderColor=[UIColor colorWithWhite:1 alpha:.08].CGColor; _safeLockBackButton.tintColor=[UIColor colorWithWhite:.75 alpha:1]; _safeLockBackButton.hidden=YES; [_safeLockBackButton addTarget:self action:@selector(cancelSafeModeAction) forControlEvents:UIControlEventTouchUpInside]; [_safeLockContainer addSubview:_safeLockBackButton];
    UIView *card=[self card]; card.backgroundColor=[UIColor colorWithRed:.020 green:.008 blue:.048 alpha:.985]; card.layer.cornerRadius=30; card.layer.borderColor=[UIColor colorWithRed:.64 green:.40 blue:1 alpha:.34].CGColor; card.layer.shadowColor=[UIColor colorWithRed:.48 green:.18 blue:1 alpha:1].CGColor; card.layer.shadowOpacity=.30; card.layer.shadowRadius=42; card.layer.shadowOffset=CGSizeMake(0,22); card.translatesAutoresizingMaskIntoConstraints=NO; [_safeLockContainer addSubview:card];
    UIView *mark=[self premiumZentraxMark:64]; [card addSubview:mark];
    _safeLockTitle=[self label:@"Enter Passcode" size:29 weight:UIFontWeightBlack color:[UIColor whiteColor]]; _safeLockTitle.textAlignment=NSTextAlignmentCenter; _safeLockTitle.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:_safeLockTitle];
    _safeLockSubtitle=[self label:@"" size:11 weight:UIFontWeightRegular color:[UIColor colorWithWhite:.48 alpha:1]]; _safeLockSubtitle.textAlignment=NSTextAlignmentCenter; _safeLockSubtitle.numberOfLines=2; _safeLockSubtitle.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:_safeLockSubtitle];
    _safePinError=[self label:@"" size:10 weight:UIFontWeightSemibold color:[ZXTheme error]]; _safePinError.textAlignment=NSTextAlignmentCenter; _safePinError.numberOfLines=2; _safePinError.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:_safePinError];
    _pinBoxes=[[UIStackView alloc] init]; _pinBoxes.axis=UILayoutConstraintAxisHorizontal; _pinBoxes.spacing=7; _pinBoxes.distribution=UIStackViewDistributionFillEqually; _pinBoxes.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:_pinBoxes];
    for(NSInteger i=0;i<6;i++){ UIView *box=[[UIView alloc] init]; box.layer.cornerRadius=12; box.layer.borderWidth=1; box.layer.borderColor=[UIColor colorWithRed:.36 green:.25 blue:.53 alpha:.55].CGColor; box.backgroundColor=[UIColor colorWithWhite:.035 alpha:1]; [_pinBoxes addArrangedSubview:box]; [box.heightAnchor constraintEqualToConstant:48].active=YES; }
    _safePINInput=[[UITextField alloc] init]; _safePINInput.keyboardType=UIKeyboardTypeNumberPad; _safePINInput.secureTextEntry=YES; _safePINInput.textColor=[UIColor clearColor]; _safePINInput.tintColor=[UIColor clearColor]; _safePINInput.backgroundColor=[UIColor clearColor]; _safePINInput.translatesAutoresizingMaskIntoConstraints=NO; [_safePINInput addTarget:self action:@selector(safePINInputChanged:) forControlEvents:UIControlEventEditingChanged]; [card addSubview:_safePINInput];
    UILabel *hint=[self label:@"PRIVATE 6-DIGIT ACCESS" size:8 weight:UIFontWeightBlack color:[UIColor colorWithRed:.55 green:.44 blue:.71 alpha:1]]; hint.textAlignment=NSTextAlignmentCenter; [ZXTheme track:hint spacing:1.7]; hint.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:hint];
    [NSLayoutConstraint activateConstraints:[[_safeLockBackButton.leadingAnchor constraintEqualToAnchor:_safeLockContainer.leadingAnchor constant:18],[_safeLockBackButton.topAnchor constraintEqualToAnchor:_safeLockContainer.safeAreaLayoutGuide.topAnchor constant:9],[card.leadingAnchor constraintGreaterThanOrEqualToAnchor:_safeLockContainer.leadingAnchor constant:18],[card.trailingAnchor constraintLessThanOrEqualToAnchor:_safeLockContainer.trailingAnchor constant:-18],[card.centerXAnchor constraintEqualToAnchor:_safeLockContainer.centerXAnchor],[card.centerYAnchor constraintEqualToAnchor:_safeLockContainer.centerYAnchor],[card.widthAnchor constraintLessThanOrEqualToConstant:380],[card.widthAnchor constraintGreaterThanOrEqualToConstant:290],[mark.topAnchor constraintEqualToAnchor:card.topAnchor constant:24],[mark.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],[mark.widthAnchor constraintEqualToConstant:64],[mark.heightAnchor constraintEqualToConstant:64],[_safeLockTitle.topAnchor constraintEqualToAnchor:mark.bottomAnchor constant:14],[_safeLockTitle.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],[_safeLockTitle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],[_safeLockSubtitle.topAnchor constraintEqualToAnchor:_safeLockTitle.bottomAnchor constant:5],[_safeLockSubtitle.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22],[_safeLockSubtitle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-22],[_safePinError.topAnchor constraintEqualToAnchor:_safeLockSubtitle.bottomAnchor constant:5],[_safePinError.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:15],[_safePinError.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-15],[_pinBoxes.topAnchor constraintEqualToAnchor:_safePinError.bottomAnchor constant:13],[_pinBoxes.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22],[_pinBoxes.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-22],[hint.topAnchor constraintEqualToAnchor:_pinBoxes.bottomAnchor constant:12],[hint.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],[hint.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-22],[_safePINInput.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],[_safePINInput.topAnchor constraintEqualToAnchor:card.topAnchor],[_safePINInput.widthAnchor constraintEqualToConstant:1],[_safePINInput.heightAnchor constraintEqualToConstant:1]]];
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
        self.safeLockSubtitle.textColor = [UIColor lightGrayColor];
        self.safeLockBackButton.hidden = NO;
    } else if (self.safeModeDisabling) {
        self.safeLockTitle.text = ZXLocalizedUI(@"Disable Safe UI");
        self.safeLockSubtitle.text = ZXLocalizedUI(@"Enter passcode to disable");
        self.safeLockSubtitle.textColor = [UIColor lightGrayColor];
        self.safeLockBackButton.hidden = NO;
    } else {
        self.safeLockTitle.text = ZXLocalizedUI(@"Enter Passcode");
        self.safeLockSubtitle.text = @"";
        self.safeLockSubtitle.textColor = [UIColor clearColor];
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
            box.backgroundColor = [UIColor whiteColor];
            box.layer.borderColor = [UIColor whiteColor].CGColor;
            box.layer.shadowColor = [UIColor whiteColor].CGColor;
            box.layer.shadowOpacity = .18;
            box.layer.shadowRadius = 9;
            box.layer.shadowOffset = CGSizeZero;
            box.transform = CGAffineTransformMakeScale(1.05,1.05);
        } else {
            box.backgroundColor = [UIColor colorWithWhite:.045 alpha:1];
            box.layer.borderColor = [UIColor colorWithWhite:.19 alpha:1].CGColor;
            box.layer.shadowOpacity = 0;
            box.transform = CGAffineTransformIdentity;
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
            if (self.dashboardConfiguration.count == 0 && self.functionDefinitions.count == 0) {
                [self beginBootstrap];
            } else {
                [self showDashboard];
            }
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
            UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
            self.privacyOverlay = [[UIVisualEffectView alloc] initWithEffect:blur];
            self.privacyOverlay.frame = self.view.bounds;
            self.privacyOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.privacyOverlay.layer.zPosition = 30000;
            
            UIView *content = self.privacyOverlay.contentView;

            UIImageView *shield = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"eye.slash.fill"]];
            shield.tintColor = [UIColor whiteColor];
            shield.contentMode = UIViewContentModeScaleAspectFit;
            shield.translatesAutoresizingMaskIntoConstraints = NO;
            [content addSubview:shield];

            UILabel *title = [self label:@"Close screen sharing app" size:22 weight:UIFontWeightBold color:[UIColor whiteColor]];
            title.textAlignment = NSTextAlignmentCenter;
            title.translatesAutoresizingMaskIntoConstraints = NO;
            [content addSubview:title];

            UILabel *message = [self label:@"Screen sharing apps can be used by fraudsters to record your screen and steal your wallet information" size:15 weight:UIFontWeightMedium color:[UIColor lightGrayColor]];
            message.textAlignment = NSTextAlignmentCenter;
            message.numberOfLines = 0;
            message.translatesAutoresizingMaskIntoConstraints = NO;
            [content addSubview:message];

            [NSLayoutConstraint activateConstraints:@[
                [shield.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],
                [shield.centerYAnchor constraintEqualToAnchor:content.centerYAnchor constant:-80],
                [shield.widthAnchor constraintEqualToConstant:56],
                [shield.heightAnchor constraintEqualToConstant:56],
                [title.topAnchor constraintEqualToAnchor:shield.bottomAnchor constant:24],
                [title.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:30],
                [title.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-30],
                [message.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:16],
                [message.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:40],
                [message.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-40]
            ]];
        }
        if (!self.privacyOverlay.superview) [self.view addSubview:self.privacyOverlay];
        self.privacyOverlayPresented = YES;
        self.privacyOverlay.alpha = 1.0;
    });
}

- (void)hidePrivacyOverlay { 
    dispatch_async(dispatch_get_main_queue(), ^{ 
        [UIView animateWithDuration:0.2 animations:^{ 
            self.privacyOverlay.alpha = 0; 
        } completion:^(BOOL f){ 
            [self.privacyOverlay removeFromSuperview]; 
            self.privacyOverlayPresented=NO; 
        }]; 
    }); 
}

#pragma mark - Language & Theme Pickers

- (void)showLanguagePicker {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.premiumModalView removeFromSuperview]; self.premiumModalView=nil; self.premiumModalCard=nil;
        UIView *host=self.view.window ?: self.view;
        UIView *overlay=[[UIView alloc] initWithFrame:host.bounds]; overlay.translatesAutoresizingMaskIntoConstraints=NO; overlay.backgroundColor=[UIColor colorWithWhite:0 alpha:.76]; overlay.accessibilityViewIsModal=YES; [host addSubview:overlay]; self.premiumModalView=overlay;
        UIVisualEffectView *blur=[[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark]]; blur.translatesAutoresizingMaskIntoConstraints=NO; blur.userInteractionEnabled=NO; [overlay addSubview:blur];
        UIView *card=[self card]; card.backgroundColor=[UIColor colorWithRed:.018 green:.007 blue:.044 alpha:.995]; card.layer.cornerRadius=28; card.layer.borderColor=[UIColor colorWithRed:.67 green:.43 blue:1 alpha:.34].CGColor; card.layer.shadowColor=[UIColor colorWithRed:.46 green:.16 blue:1 alpha:1].CGColor; card.layer.shadowOpacity=.34; card.layer.shadowRadius=45; card.layer.shadowOffset=CGSizeMake(0,22); card.translatesAutoresizingMaskIntoConstraints=NO; [overlay addSubview:card]; self.premiumModalCard=card;
        UIView *mark=[self premiumZentraxMark:48]; [card addSubview:mark];
        UILabel *t=[self label:@"Language" size:21 weight:UIFontWeightBlack color:[UIColor whiteColor]]; t.textAlignment=NSTextAlignmentCenter; t.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:t];
        UILabel *st=[self label:@"Choose your interface language" size:10 weight:UIFontWeightRegular color:[UIColor colorWithWhite:.48 alpha:1]]; st.textAlignment=NSTextAlignmentCenter; st.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:st];
        UIStackView *stack=[[UIStackView alloc] init]; stack.axis=UILayoutConstraintAxisVertical; stack.spacing=8; stack.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:stack];
        NSArray *langs=@[@"English",@"Tiếng Việt",@"简体中文",@"日本語"]; NSString *current=ZXCurrentLanguage();
        for(NSString *langName in langs){
            UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem]; b.accessibilityIdentifier=langName; b.backgroundColor=[langName isEqualToString:current]?[UIColor colorWithRed:.28 green:.12 blue:.54 alpha:.68]:[UIColor colorWithWhite:1 alpha:.045]; b.layer.cornerRadius=14; b.layer.borderWidth=1; b.layer.borderColor=[langName isEqualToString:current]?[UIColor colorWithRed:.75 green:.53 blue:1 alpha:.55].CGColor:[UIColor colorWithWhite:1 alpha:.08].CGColor; b.contentHorizontalAlignment=UIControlContentHorizontalAlignmentLeft; b.contentEdgeInsets=UIEdgeInsetsMake(0,16,0,16); b.titleLabel.font=[UIFont systemFontOfSize:12 weight:UIFontWeightBold]; [b setTitle:langName forState:UIControlStateNormal]; [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; [b addTarget:self action:@selector(zxLanguageChoice:) forControlEvents:UIControlEventTouchUpInside]; [stack addArrangedSubview:b]; [b.heightAnchor constraintEqualToConstant:46].active=YES;
        }
        UIButton *cancel=[UIButton buttonWithType:UIButtonTypeSystem]; cancel.backgroundColor=[UIColor colorWithWhite:1 alpha:.045]; cancel.layer.cornerRadius=14; cancel.layer.borderWidth=1; cancel.layer.borderColor=[UIColor colorWithWhite:1 alpha:.08].CGColor; cancel.titleLabel.font=[UIFont systemFontOfSize:11 weight:UIFontWeightBlack]; [cancel setTitle:ZXLocalizedUI(@"CANCEL") forState:UIControlStateNormal]; [cancel setTitleColor:[UIColor colorWithWhite:.74 alpha:1] forState:UIControlStateNormal]; cancel.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:cancel]; [cancel addTarget:self action:@selector(zxPremiumModalDismiss:) forControlEvents:UIControlEventTouchUpInside];
        [NSLayoutConstraint activateConstraints:@[[blur.leadingAnchor constraintEqualToAnchor:overlay.leadingAnchor],[blur.trailingAnchor constraintEqualToAnchor:overlay.trailingAnchor],[blur.topAnchor constraintEqualToAnchor:overlay.topAnchor],[blur.bottomAnchor constraintEqualToAnchor:overlay.bottomAnchor],[card.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],[card.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],[card.leadingAnchor constraintGreaterThanOrEqualToAnchor:overlay.leadingAnchor constant:22],[card.trailingAnchor constraintLessThanOrEqualToAnchor:overlay.trailingAnchor constant:-22],[card.widthAnchor constraintLessThanOrEqualToConstant:350],[card.widthAnchor constraintGreaterThanOrEqualToConstant:280],[card.topAnchor constraintGreaterThanOrEqualToAnchor:overlay.safeAreaLayoutGuide.topAnchor constant:22],[card.bottomAnchor constraintLessThanOrEqualToAnchor:overlay.safeAreaLayoutGuide.bottomAnchor constant:-22],[mark.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],[mark.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],[mark.widthAnchor constraintEqualToConstant:48],[mark.heightAnchor constraintEqualToConstant:48],[t.topAnchor constraintEqualToAnchor:mark.bottomAnchor constant:11],[t.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],[st.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:4],[st.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],[stack.topAnchor constraintEqualToAnchor:st.bottomAnchor constant:14],[stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],[stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],[cancel.topAnchor constraintEqualToAnchor:stack.bottomAnchor constant:10],[cancel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],[cancel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],[cancel.heightAnchor constraintEqualToConstant:46],[cancel.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18]]];
        overlay.alpha=0; card.transform=CGAffineTransformMakeScale(.92,.92); [UIView animateWithDuration:.38 delay:0 usingSpringWithDamping:.82 initialSpringVelocity:.08 options:UIViewAnimationOptionAllowUserInteraction animations:^{overlay.alpha=1; card.transform=CGAffineTransformIdentity;} completion:nil];
    });
}



- (void)zxLanguageChoice:(UIButton *)sender {
    NSString *lang=sender.accessibilityIdentifier.length?sender.accessibilityIdentifier:@"English";
    NSArray *allowed=@[@"English",@"Tiếng Việt",@"简体中文",@"日本語"]; if(![allowed containsObject:lang]) return;
    NSUserDefaults *globalDefaults=[[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"]; [globalDefaults setObject:lang forKey:ZXLanguageKey]; [globalDefaults synchronize];
    [self.premiumModalView removeFromSuperview]; self.premiumModalView=nil; self.premiumModalCard=nil;
    BOOL wasSettings=self.settingsVisible; ZXAppState previousState=self.currentState;
    [self rebuildAllContainers]; self.settingsVisible=wasSettings;
    if(wasSettings) [self transitionToPrimaryContainer:self.settingsContainer];
    else if(previousState==ZXAppStateDashboard) [self transitionToPrimaryContainer:self.dashboardContainer];
    else if(previousState==ZXAppStateAuth) [self transitionToPrimaryContainer:self.authContainer];
    [self showToast:ZXLocalizedUI(@"Language updated") success:YES];
}


- (void)showThemePicker {
    // Intentionally unavailable in the single-theme ZENTRAX visual system.
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
        [self hideGlobalLoadingState];
        [self showGlobalErrorWithTitle:@"UNAVAILABLE" message:@"Compatibility service is not connected."];
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
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    _globalLoadingOverlay = [[UIVisualEffectView alloc] initWithEffect:blur];
    _globalLoadingOverlay.frame = self.view.bounds;
    _globalLoadingOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _globalLoadingOverlay.hidden = YES;
    _globalLoadingOverlay.layer.zPosition = 10000;
    [self.view addSubview:_globalLoadingOverlay];
    
    UIView *card = [self card];
    card.backgroundColor = [UIColor colorWithWhite:0.055 alpha:0.98];
    card.layer.cornerRadius = 22;
    card.layer.borderColor = [UIColor colorWithWhite:1 alpha:.10].CGColor;
    card.layer.shadowOpacity = .55;
    card.layer.shadowRadius = 35;
    card.layer.shadowOffset = CGSizeMake(0,20);
    [((UIVisualEffectView *)_globalLoadingOverlay).contentView addSubview:card];
    
    _globalSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _globalSpinner.color = [UIColor colorWithRed:.74 green:.57 blue:1 alpha:1];
    _globalSpinner.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_globalSpinner];
    
    _globalLoadingTitle = [self label:@"SECURE OPERATION" size:13 weight:UIFontWeightBlack color:[UIColor whiteColor]];
    _globalLoadingTitle.textAlignment = NSTextAlignmentCenter;
    _globalLoadingTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_globalLoadingTitle];
    
    _globalLoadingDetail = [self label:@"Please wait…" size:12 weight:UIFontWeightRegular color:[UIColor lightGrayColor]];
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
        [_globalLoadingTitle.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [_globalLoadingTitle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [_globalLoadingDetail.topAnchor constraintEqualToAnchor:_globalLoadingTitle.bottomAnchor constant:6],
        [_globalLoadingDetail.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [_globalLoadingDetail.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16]
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
        toast.backgroundColor = [UIColor colorWithWhite:.055 alpha:.98];
        toast.layer.cornerRadius = 15;
        toast.layer.borderWidth = 1;
        toast.layer.borderColor = (success ? [ZXTheme success] : [ZXTheme error]).CGColor;
        toast.translatesAutoresizingMaskIntoConstraints = NO;
        
        toast.layer.shadowColor = [UIColor blackColor].CGColor;
        toast.layer.shadowOpacity = [ZXTheme isLightMode] ? 0.05 : 0.2;
        toast.layer.shadowRadius = 8;
        toast.layer.shadowOffset = CGSizeMake(0, 4);

        [self.view addSubview:toast];
        self.toastView = toast;
        
        UILabel *text = [self label:ZXLocalizedUI(message ?: @"") size:13 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
        text.textAlignment = NSTextAlignmentCenter;
        text.translatesAutoresizingMaskIntoConstraints = NO;
        [toast addSubview:text];
        
        [NSLayoutConstraint activateConstraints:@[
            [toast.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [toast.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
            [toast.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24],
            [toast.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24],
            [toast.heightAnchor constraintGreaterThanOrEqualToConstant:48],
            [text.leadingAnchor constraintEqualToAnchor:toast.leadingAnchor constant:20],
            [text.trailingAnchor constraintEqualToAnchor:toast.trailingAnchor constant:-20],
            [text.centerYAnchor constraintEqualToAnchor:toast.centerYAnchor],
            [text.topAnchor constraintEqualToAnchor:toast.topAnchor constant:14],
            [text.bottomAnchor constraintEqualToAnchor:toast.bottomAnchor constant:-14]
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
        [self.premiumModalView removeFromSuperview]; self.premiumModalView=nil; self.premiumModalCard=nil;
        UIView *host=self.view.window ?: self.view;
        UIView *overlay=[[UIView alloc] initWithFrame:host.bounds]; overlay.translatesAutoresizingMaskIntoConstraints=NO; overlay.backgroundColor=[UIColor colorWithWhite:0 alpha:.76]; overlay.accessibilityViewIsModal=YES; [host addSubview:overlay]; self.premiumModalView=overlay;
        UIVisualEffectView *blur=[[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark]]; blur.translatesAutoresizingMaskIntoConstraints=NO; blur.userInteractionEnabled=NO; [overlay addSubview:blur];
        UIView *card=[self card]; card.backgroundColor=[UIColor colorWithRed:.018 green:.007 blue:.044 alpha:.995]; card.layer.cornerRadius=28; card.layer.borderColor=[UIColor colorWithRed:.67 green:.43 blue:1 alpha:.34].CGColor; card.layer.shadowColor=[UIColor colorWithRed:.46 green:.16 blue:1 alpha:1].CGColor; card.layer.shadowOpacity=.34; card.layer.shadowRadius=45; card.layer.shadowOffset=CGSizeMake(0,22); card.translatesAutoresizingMaskIntoConstraints=NO; [overlay addSubview:card]; self.premiumModalCard=card;
        UIView *mark=[self premiumZentraxMark:56]; [card addSubview:mark];
        UILabel *t=[self label:title.length?title:@"ZENTRAX" size:22 weight:UIFontWeightBlack color:[UIColor whiteColor]]; t.textAlignment=NSTextAlignmentCenter; t.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:t];
        UILabel *m=[self label:message?:@"" size:12 weight:UIFontWeightRegular color:[UIColor colorWithWhite:.55 alpha:1]]; m.textAlignment=NSTextAlignmentCenter; m.numberOfLines=0; m.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:m];
        UIButton *confirm=[UIButton buttonWithType:UIButtonTypeSystem]; confirm.backgroundColor=[ZXTheme accent]; confirm.layer.cornerRadius=15; confirm.layer.shadowColor=[UIColor colorWithRed:.45 green:.16 blue:1 alpha:1].CGColor; confirm.layer.shadowOpacity=.25; confirm.layer.shadowRadius=16; confirm.layer.shadowOffset=CGSizeMake(0,8); confirm.titleLabel.font=[UIFont systemFontOfSize:12 weight:UIFontWeightBlack]; [confirm setTitle:ZXLocalizedUI(confirmTitle?:@"CONTINUE") forState:UIControlStateNormal]; [confirm setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; confirm.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:confirm]; [confirm addTarget:self action:@selector(zxPremiumModalConfirm:) forControlEvents:UIControlEventTouchUpInside]; objc_setAssociatedObject(confirm,@selector(zxPremiumModalConfirm:),[completion copy],OBJC_ASSOCIATION_COPY_NONATOMIC);
        UIButton *close=[UIButton buttonWithType:UIButtonTypeSystem]; [close setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal]; close.backgroundColor=[UIColor colorWithWhite:1 alpha:.045]; close.layer.cornerRadius=16; close.layer.borderWidth=1; close.layer.borderColor=[UIColor colorWithWhite:1 alpha:.08].CGColor; close.tintColor=[UIColor colorWithWhite:.65 alpha:1]; close.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:close]; [close addTarget:self action:@selector(zxPremiumModalDismiss:) forControlEvents:UIControlEventTouchUpInside];
        [NSLayoutConstraint activateConstraints:@[[blur.leadingAnchor constraintEqualToAnchor:overlay.leadingAnchor],[blur.trailingAnchor constraintEqualToAnchor:overlay.trailingAnchor],[blur.topAnchor constraintEqualToAnchor:overlay.topAnchor],[blur.bottomAnchor constraintEqualToAnchor:overlay.bottomAnchor],[card.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],[card.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],[card.leadingAnchor constraintGreaterThanOrEqualToAnchor:overlay.leadingAnchor constant:22],[card.trailingAnchor constraintLessThanOrEqualToAnchor:overlay.trailingAnchor constant:-22],[card.widthAnchor constraintLessThanOrEqualToConstant:350],[card.widthAnchor constraintGreaterThanOrEqualToConstant:280],[card.topAnchor constraintGreaterThanOrEqualToAnchor:overlay.safeAreaLayoutGuide.topAnchor constant:24],[card.bottomAnchor constraintLessThanOrEqualToAnchor:overlay.safeAreaLayoutGuide.bottomAnchor constant:-24],[mark.topAnchor constraintEqualToAnchor:card.topAnchor constant:23],[mark.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],[mark.widthAnchor constraintEqualToConstant:56],[mark.heightAnchor constraintEqualToConstant:56],[close.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-12],[close.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],[close.widthAnchor constraintEqualToConstant:32],[close.heightAnchor constraintEqualToConstant:32],[t.topAnchor constraintEqualToAnchor:mark.bottomAnchor constant:13],[t.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],[t.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],[m.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:7],[m.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],[m.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],[confirm.topAnchor constraintEqualToAnchor:m.bottomAnchor constant:20],[confirm.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],[confirm.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],[confirm.heightAnchor constraintEqualToConstant:50],[confirm.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-22]]];
        overlay.alpha=0; card.transform=CGAffineTransformMakeScale(.92,.92); [UIView animateWithDuration:.38 delay:0 usingSpringWithDamping:.82 initialSpringVelocity:.08 options:UIViewAnimationOptionAllowUserInteraction animations:^{overlay.alpha=1; card.transform=CGAffineTransformIdentity;} completion:nil];
    });
}



- (void)zxPremiumModalDismiss:(UIButton *)sender {
    UIView *overlay=self.premiumModalView;
    if(!overlay) return;
    UIView *card=self.premiumModalCard;
    [UIView animateWithDuration:.20 animations:^{ overlay.alpha=0; card.transform=CGAffineTransformMakeScale(.97,.97); } completion:^(BOOL finished){
        [overlay removeFromSuperview];
        if(self.premiumModalView==overlay) self.premiumModalView=nil;
        if(self.premiumModalCard==card) self.premiumModalCard=nil;
    }];
}

- (void)zxPremiumModalConfirm:(UIButton *)sender {
    void (^completion)(void)=objc_getAssociatedObject(sender, @selector(zxPremiumModalConfirm:));
    [self zxPremiumModalDismiss:sender];
    if (completion) completion();
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
    
    // Ensure dashboard reflects known persistent state immediately, protecting against sparse network payloads later
    [self updateLicenseStatus:self.licenseStatus activatedAt:self.activatedAt expiresAt:self.expiresAt isPermanent:self.licensePermanent];
    
    [self startHeartbeatMonitor];
}

- (void)showMaintenanceScreenWithMessage:(NSString *)message { [self showStartupState:ZXStartupStateMaintenance message:message]; }
- (void)showUpdateRequiredScreenWithMessage:(NSString *)message { [self showStartupState:ZXStartupStateVersionMismatch message:message]; }
- (void)showConnectionErrorScreenWithMessage:(NSString *)message { [self showStartupState:ZXStartupStateConnectionError message:message]; }

- (void)handleLogout {
    __weak typeof(self) weakSelf=self;
    [self showCustomConfirmationWithTitle:@"SIGN OUT" message:@"Close the current secure session?" confirmTitle:@"SIGN OUT" completion:^{
        __strong typeof(weakSelf) self=weakSelf; if(!self) return;
        Class mgrCls=NSClassFromString(@"ZentraxNetworkManager");
        if(mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]){
            id manager=((id (*)(id, SEL))objc_msgSend)((id)mgrCls,NSSelectorFromString(@"sharedManager"));
            SEL outSel=NSSelectorFromString(@"logout");
            if([manager respondsToSelector:outSel]) ((void (*)(id, SEL))objc_msgSend)(manager,outSel);
        }
        NSUserDefaults *globalDefaults=[[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
        [globalDefaults removeObjectForKey:ZXLastKey]; [globalDefaults synchronize];
        if([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]){
            [self.delegate zentraxDidRequestLogoutWithCompletion:^{ dispatch_async(dispatch_get_main_queue(),^{ [self showLoginScreen]; }); }];
        } else [self showLoginScreen];
    }];
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
