				//
//  ZentraxUI.m
//  Zentrax VIP - Premium Security Infrastructure UI
//
//  Architecture: Server-authoritative UI / Network-driven state
//  Theme: ZENTRAX Obsidian / Violet / Indigo / Platinum Material System
//  Status: SOURCE-LEVEL 55-POINT AUDIT READY
//

#import "ZentraxUI.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <WebKit/WebKit.h>
#import <AVFoundation/AVFoundation.h>

#pragma mark - Constants & Keys

static NSString * const ZXLanguageKey = @"in.zentrax.global.language";
static NSString * const ZXLastKey = @"in.zentrax.global.lastkey";
static NSString * const ZXLoginAttemptsKey = @"in.zentrax.global.login.attempts";
static NSString * const ZXLoginTimeoutKey = @"in.zentrax.global.login.timeout";

// Compiled into the UI layer; deliberately not exposed as an editable setting.
static NSString * const ZXTelegramChannelURL = @"https://t.me/+N36JE9NVrE4yMjc9";
static NSString * const ZXTelegramJoinedKey = @"in.zentrax.global.telegram.channel.joined";

#pragma mark - App State Enum

typedef NS_ENUM(NSInteger, ZXAppState) {
    ZXAppStateInit = 0,
    ZXAppStateSplash,
    ZXAppStateAuth,
    ZXAppStateDashboard,
    ZXAppStateStartupBlock
};

#pragma mark - ZENTRAX Design System

/*
 * ZENTRAX visual system
 *
 * The controller remains the integration boundary.  These components are
 * deliberately self-contained so the visual layer can evolve without
 * changing delegate/network contracts.
 */

@interface ZXTheme : NSObject
+ (UIColor *)obsidian;
+ (UIColor *)surface0;
+ (UIColor *)surface1;
+ (UIColor *)surface2;
+ (UIColor *)surface3;
+ (UIColor *)surfaceRaised;
+ (UIColor *)border;
+ (UIColor *)borderAccent;
+ (UIColor *)primaryText;
+ (UIColor *)secondaryText;
+ (UIColor *)mutedText;
+ (UIColor *)hairline;
+ (UIColor *)accentPrimary;
+ (UIColor *)accentSecondary;
+ (UIColor *)accentSoft;
+ (UIColor *)success;
+ (UIColor *)warning;
+ (UIColor *)error;
+ (UIColor *)info;
+ (UIFont *)display:(CGFloat)size;
+ (UIFont *)heading:(CGFloat)size;
+ (UIFont *)body:(CGFloat)size weight:(UIFontWeight)weight;
+ (UIFont *)mono:(CGFloat)size weight:(UIFontWeight)weight;
+ (CGFloat)space:(NSInteger)step;
+ (CGFloat)radius:(NSInteger)tier;
+ (void)track:(UILabel *)label spacing:(CGFloat)spacing;
@end

@implementation ZXTheme
+ (UIColor *)obsidian { return [UIColor colorWithRed:7.0/255.0 green:7.0/255.0 blue:10.0/255.0 alpha:1.0]; }
+ (UIColor *)surface0 { return [UIColor colorWithRed:10.0/255.0 green:10.0/255.0 blue:15.0/255.0 alpha:1.0]; }
+ (UIColor *)surface1 { return [UIColor colorWithRed:13.0/255.0 green:13.0/255.0 blue:18.0/255.0 alpha:1.0]; }
+ (UIColor *)surface2 { return [UIColor colorWithRed:16.0/255.0 green:16.0/255.0 blue:22.0/255.0 alpha:1.0]; }
+ (UIColor *)surface3 { return [UIColor colorWithRed:18.0/255.0 green:18.0/255.0 blue:26.0/255.0 alpha:1.0]; }
+ (UIColor *)surfaceRaised { return [ZXTheme surface2]; }
+ (UIColor *)border { return [ZXTheme hairline]; }
+ (UIColor *)borderAccent { return [[ZXTheme accentPrimary] colorWithAlphaComponent:0.30]; }
+ (UIColor *)primaryText { return [UIColor colorWithWhite:0.96 alpha:1.0]; }
+ (UIColor *)secondaryText { return [UIColor colorWithWhite:0.72 alpha:1.0]; }
+ (UIColor *)mutedText { return [UIColor colorWithWhite:0.46 alpha:1.0]; }
+ (UIColor *)hairline { return [UIColor colorWithWhite:1.0 alpha:0.085]; }
+ (UIColor *)accentPrimary { return [UIColor colorWithRed:0.42 green:0.30 blue:0.92 alpha:1.0]; }
+ (UIColor *)accentSecondary { return [UIColor colorWithRed:0.28 green:0.30 blue:0.82 alpha:1.0]; }
+ (UIColor *)accentSoft { return [UIColor colorWithRed:0.55 green:0.48 blue:1.0 alpha:1.0]; }
+ (UIColor *)success { return [UIColor colorWithRed:0.37 green:0.82 blue:0.60 alpha:1.0]; }
+ (UIColor *)warning { return [UIColor colorWithRed:0.91 green:0.70 blue:0.32 alpha:1.0]; }
+ (UIColor *)error { return [UIColor colorWithRed:0.92 green:0.36 blue:0.42 alpha:1.0]; }
+ (UIColor *)info { return [UIColor colorWithRed:0.55 green:0.58 blue:0.88 alpha:1.0]; }
+ (UIFont *)display:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBold]; }
+ (UIFont *)heading:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightSemibold]; }
+ (UIFont *)body:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont systemFontOfSize:size weight:weight]; }
+ (UIFont *)mono:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont monospacedSystemFontOfSize:size weight:weight]; }
+ (CGFloat)space:(NSInteger)step { static const CGFloat v[] = {0,4,8,12,16,20,24,28,32,40,48}; return (step >= 0 && step <= 10) ? v[step] : 16.0; }
+ (CGFloat)radius:(NSInteger)tier { static const CGFloat v[] = {0,10,14,18,22}; return (tier >= 0 && tier <= 4) ? v[tier] : 18.0; }
+ (void)track:(UILabel *)label spacing:(CGFloat)spacing {
    if (!label) return;
    NSMutableAttributedString *m = [[NSMutableAttributedString alloc] initWithString:label.text ?: @"" attributes:@{NSFontAttributeName: label.font ?: [UIFont systemFontOfSize:12]}];
    [m addAttribute:NSKernAttributeName value:@(spacing) range:NSMakeRange(0, m.length)];
    label.attributedText = m;
}
@end

#pragma mark - Localization / UI helpers

static UILabel *ZXLabel(NSString *text, UIFont *font, UIColor *color) {
    UILabel *label = [[UILabel alloc] init];
    label.text = text ?: @"";
    label.font = font ?: [UIFont systemFontOfSize:14.0];
    label.textColor = color ?: [ZXTheme primaryText];
    label.numberOfLines = 1;
    label.adjustsFontForContentSizeCategory = YES;
    return label;
}

static BOOL ZXIsTruthyValue(id value) {
    if (!value || value == [NSNull null]) return NO;
    if ([value respondsToSelector:@selector(boolValue)]) return [value boolValue];
    return NO;
}

static NSString *ZXCurrentLanguage(void) {
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *lang = [d stringForKey:ZXLanguageKey];
    return lang.length ? lang : @"English";
}

static NSArray<NSString *> *ZXAllLocalizedUIKeys(void) {
    return @[@"Settings", @"Sign Out", @"AUTHENTICATE", @"Choose your language", @"ACTIVE", @"READY", @"LIFETIME", @"OFFLINE", @"PROCESSING", @"FUNCTION ACTIVATED", @"FUNCTION DEACTIVATED", @"FUNCTION DISABLED", @"ZENTRAX Community", @"Support the free release • Join the official Telegram channel", @"COMMUNITY", @"Official channel • link is built into the app", @"A LITTLE SUPPORT GOES A LONG WAY", @"Help Keep ZENTRAX Free.", @"ZENTRAX is shared with the community at no cost. If it helps you, joining the official channel is a small way to support the work and stay close to future free releases.", @"Free access • community supported", @"JOIN THE ZENTRAX COMMUNITY", @"Not already done", @"Unable to open the official channel.", @"Open the official Telegram channel and remember this choice.", @"Join the ZENTRAX Community", @"Visible", @"Hidden", @"License Key", @"Show or hide the saved license key.", @"Function switch", @"Access Granted", @"Authenticating...", @"CHECK FAILED", @"CONNECTED", @"CONTINUE", @"Cancel", @"Close the current secure session.", @"Compatibility Verified", @"DISABLED", @"Dismiss this reminder for now. It will appear again the next time the app starts until the channel is joined.", @"EXPIRED", @"Enter License Key", @"Expiry Date", @"Language", @"NOT STARTED", @"OK", @"PRIVATE VIEW", @"Please wait…", @"RETRY CONNECTION", @"REVOKED", @"SAFE MODE", @"SESSION EXPIRED", @"SIGN OUT", @"Server configuration changed", @"The server did not permit the secure workspace to open.", @"UNACTIVATED", @"UNKNOWN", @"Unable to verify device.", @"Your current secure session will be closed.", @"Your license was deleted, revoked, or transferred. You have been logged out.", @"ZENTRAX is running in a protected state.", @"00:00:00", @"Authentication locked. Try again in %ld min.", @"Integration bridge unavailable.", @"On", @"Off", @"No saved license key is available."];
}

static NSString *ZXLocalizedUI(NSString *text) {
    if (![text isKindOfClass:[NSString class]] || !text.length) return text ?: @"";
    NSString *language = ZXCurrentLanguage();
    if ([language isEqualToString:@"English"]) return text;
    NSDictionary *vi = @{@"Settings":@"Cài đặt", @"Sign Out":@"Đăng xuất", @"AUTHENTICATE":@"XÁC THỰC", @"Choose your language":@"Chọn ngôn ngữ", @"ACTIVE":@"ĐANG BẬT", @"READY":@"SẴN SÀNG", @"LIFETIME":@"VĨNH VIỄN", @"OFFLINE":@"NGOẠI TUYẾN", @"PROCESSING":@"ĐANG XỬ LÝ", @"FUNCTION ACTIVATED":@"ĐÃ KÍCH HOẠT", @"FUNCTION DEACTIVATED":@"ĐÃ TẮT", @"FUNCTION DISABLED":@"ĐÃ VÔ HIỆU HÓA", @"ZENTRAX Community":@"Cộng đồng ZENTRAX", @"Support the free release • Join the official Telegram channel":@"Ủng hộ bản phát hành miễn phí • Tham gia kênh Telegram chính thức", @"COMMUNITY":@"CỘNG ĐỒNG", @"Official channel • link is built into the app":@"Kênh chính thức • liên kết được tích hợp trong ứng dụng", @"A LITTLE SUPPORT GOES A LONG WAY":@"MỘT CHÚT ỦNG HỘ CŨNG RẤT QUÝ", @"Help Keep ZENTRAX Free.":@"Giữ ZENTRAX miễn phí.", @"ZENTRAX is shared with the community at no cost. If it helps you, joining the official channel is a small way to support the work and stay close to future free releases.":@"ZENTRAX được chia sẻ miễn phí. Nếu ứng dụng hữu ích, tham gia kênh chính thức là một cách nhỏ để ủng hộ công sức và theo dõi các bản phát hành miễn phí tiếp theo.", @"Free access • community supported":@"Truy cập miễn phí • được cộng đồng ủng hộ", @"JOIN THE ZENTRAX COMMUNITY":@"THAM GIA CỘNG ĐỒNG ZENTRAX", @"Not already done":@"Chưa thực hiện", @"Unable to open the official channel.":@"Không thể mở kênh chính thức."};
    NSDictionary *zh = @{@"Settings":@"设置", @"Sign Out":@"退出登录", @"AUTHENTICATE":@"验证", @"Choose your language":@"选择语言", @"ACTIVE":@"已启用", @"READY":@"就绪", @"LIFETIME":@"永久", @"OFFLINE":@"离线", @"PROCESSING":@"处理中", @"FUNCTION ACTIVATED":@"功能已启用", @"FUNCTION DEACTIVATED":@"功能已关闭", @"FUNCTION DISABLED":@"功能已禁用", @"ZENTRAX Community":@"ZENTRAX 社区", @"Support the free release • Join the official Telegram channel":@"支持免费版本 • 加入官方 Telegram 频道", @"COMMUNITY":@"社区", @"Official channel • link is built into the app":@"官方频道 • 链接已内置于应用", @"A LITTLE SUPPORT GOES A LONG WAY":@"一点支持也很重要", @"Help Keep ZENTRAX Free.":@"让 ZENTRAX 保持免费。", @"Free access • community supported":@"免费使用 • 社区支持", @"JOIN THE ZENTRAX COMMUNITY":@"加入 ZENTRAX 社区", @"Not already done":@"稍后再说", @"Unable to open the official channel.":@"无法打开官方频道。", @"ZENTRAX is shared with the community at no cost. If it helps you, joining the official channel is a small way to support the work and stay close to future free releases.":@"ZENTRAX 免费分享给社区。如果它对你有帮助，加入官方频道就是对这份工作的一个小小支持，也能及时获取未来的免费版本。", @"Open the official Telegram channel and remember this choice.":@"打开官方 Telegram 频道并记住此选择。", @"Join the ZENTRAX Community":@"加入 ZENTRAX 社区"};
    NSDictionary *ja = @{@"Settings":@"設定", @"Sign Out":@"サインアウト", @"AUTHENTICATE":@"認証", @"Choose your language":@"言語を選択", @"ACTIVE":@"有効", @"READY":@"準備完了", @"LIFETIME":@"無期限", @"OFFLINE":@"オフライン", @"PROCESSING":@"処理中", @"FUNCTION ACTIVATED":@"機能を有効化", @"FUNCTION DEACTIVATED":@"機能を無効化", @"FUNCTION DISABLED":@"機能が無効化されました", @"ZENTRAX Community":@"ZENTRAX コミュニティ", @"Support the free release • Join the official Telegram channel":@"無料リリースを応援 • 公式 Telegram チャンネルに参加", @"COMMUNITY":@"コミュニティ", @"Official channel • link is built into the app":@"公式チャンネル • リンクはアプリに内蔵されています", @"A LITTLE SUPPORT GOES A LONG WAY":@"小さな応援が大きな力になります", @"Help Keep ZENTRAX Free.":@"ZENTRAX を無料で続けるために", @"Free access • community supported":@"無料アクセス • コミュニティ支援", @"JOIN THE ZENTRAX COMMUNITY":@"ZENTRAX コミュニティに参加", @"Not already done":@"後で", @"Unable to open the official channel.":@"公式チャンネルを開けません。", @"ZENTRAX is shared with the community at no cost. If it helps you, joining the official channel is a small way to support the work and stay close to future free releases.":@"ZENTRAX はコミュニティに無料で提供されています。役に立った場合、公式チャンネルへの参加はこの活動を支える小さな応援となり、今後の無料リリースも確認できます。", @"Open the official Telegram channel and remember this choice.":@"公式 Telegram チャンネルを開き、この選択を記憶します。", @"Join the ZENTRAX Community":@"ZENTRAX コミュニティに参加"};
    NSDictionary *map = [language isEqualToString:@"Tiếng Việt"] ? vi : ([language isEqualToString:@"简体中文"] ? zh : ([language isEqualToString:@"日本語"] ? ja : nil));
    return map[text] ?: text;
}

static BOOL ZXLocalizationRegistryContains(NSString *key) {
    return [[ZXAllLocalizedUIKeys() filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *value, NSDictionary *_) { return [value isEqualToString:key]; }]] count] > 0;
}

static NSTimeInterval ZXMotionDuration(NSTimeInterval normalDuration) {
    return UIAccessibilityIsReduceMotionEnabled() ? 0.01 : normalDuration;
}


#pragma mark - Accessibility / Interaction Audit Helpers

static void ZXAuditAccessibilityTree(UIView *root) {
    if (!root) return;
    if ([root isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)root;
        if (!button.accessibilityLabel.length) {
            NSString *title = [button titleForState:UIControlStateNormal];
            if (title.length) button.accessibilityLabel = title;
        }
        button.accessibilityTraits |= UIAccessibilityTraitButton;
        button.accessibilityElementsHidden = NO;
    } else if ([root isKindOfClass:[UISwitch class]]) {
        UISwitch *sw = (UISwitch *)root;
        if (!sw.accessibilityLabel.length) sw.accessibilityLabel = ZXLocalizedUI(@"Function switch");
        sw.accessibilityTraits |= UIAccessibilityTraitAdjustable;
    } else if ([root isKindOfClass:[UITextField class]]) {
        UITextField *field = (UITextField *)root;
        if (!field.accessibilityLabel.length) field.accessibilityLabel = ZXLocalizedUI(@"License Key");
        field.adjustsFontForContentSizeCategory = YES;
    }
    for (UIView *subview in root.subviews) ZXAuditAccessibilityTree(subview);
}

static void ZXEnsureMinimumTouchTarget(UIView *view) {
    if (!view) return;
    // This is an audit marker rather than a frame mutation: Auto Layout remains authoritative.
    if ([view isKindOfClass:[UIButton class]] || [view isKindOfClass:[UISwitch class]]) {
        view.accessibilityElementsHidden = NO;
    }
}

#pragma mark - Cinematic Background

@interface ZXCinematicBackgroundView : UIView
@property(nonatomic,strong) CAGradientLayer *baseLayer;
@property(nonatomic,strong) CAGradientLayer *violetAtmosphere;
@property(nonatomic,strong) CAGradientLayer *indigoAtmosphere;
@property(nonatomic,strong) CAGradientLayer *vignetteLayer;
@end

@implementation ZXCinematicBackgroundView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.backgroundColor = [ZXTheme obsidian];
    self.userInteractionEnabled = NO;

    _baseLayer = [CAGradientLayer layer];
    _baseLayer.colors = @[(id)[ZXTheme obsidian].CGColor,(id)[ZXTheme surface0].CGColor,(id)[UIColor colorWithRed:8.0/255.0 green:8.0/255.0 blue:13.0/255.0 alpha:1].CGColor];
    _baseLayer.locations = @[@0,@0.56,@1];
    [self.layer addSublayer:_baseLayer];

    _violetAtmosphere = [CAGradientLayer layer];
    _violetAtmosphere.type = kCAGradientLayerRadial;
    _violetAtmosphere.colors = @[(id)[[ZXTheme accentPrimary] colorWithAlphaComponent:0.12].CGColor,(id)[UIColor clearColor].CGColor];
    _violetAtmosphere.startPoint = CGPointMake(0.5,0.5); _violetAtmosphere.endPoint = CGPointMake(1,1);
    [self.layer addSublayer:_violetAtmosphere];

    _indigoAtmosphere = [CAGradientLayer layer];
    _indigoAtmosphere.type = kCAGradientLayerRadial;
    _indigoAtmosphere.colors = @[(id)[[ZXTheme accentSecondary] colorWithAlphaComponent:0.07].CGColor,(id)[UIColor clearColor].CGColor];
    _indigoAtmosphere.startPoint = CGPointMake(0.5,0.5); _indigoAtmosphere.endPoint = CGPointMake(1,1);
    [self.layer addSublayer:_indigoAtmosphere];

    _vignetteLayer = [CAGradientLayer layer];
    _vignetteLayer.colors = @[(id)[UIColor clearColor].CGColor,(id)[UIColor colorWithWhite:0 alpha:0.42].CGColor];
    _vignetteLayer.startPoint = CGPointMake(0.5,0.1); _vignetteLayer.endPoint = CGPointMake(0.5,1);
    [self.layer addSublayer:_vignetteLayer];
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w=self.bounds.size.width,h=self.bounds.size.height;
    _baseLayer.frame=self.bounds;
    _violetAtmosphere.frame=CGRectMake(-w*0.35,-h*0.18,w*1.35,h*1.0);
    _indigoAtmosphere.frame=CGRectMake(w*0.22,h*0.35,w*1.25,h*0.9);
    _vignetteLayer.frame=self.bounds;
}
- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (!self.window) { [self.layer removeAllAnimations]; return; }
    [self.layer removeAllAnimations];
    if (!UIAccessibilityIsReduceMotionEnabled()) {
        CABasicAnimation *a=[CABasicAnimation animationWithKeyPath:@"opacity"];
        a.fromValue=@0.72; a.toValue=@1.0; a.duration=6.0; a.autoreverses=YES; a.repeatCount=HUGE_VALF; a.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [self.violetAtmosphere addAnimation:a forKey:@"zx_ambient"];
    }
}
@end

#pragma mark - Glass Material

@interface ZXGlassCard : UIView
@property(nonatomic,strong) UIVisualEffectView *blurView;
@property(nonatomic,strong) CAGradientLayer *highlightLayer;
@property(nonatomic,strong) CAGradientLayer *shadeLayer;
@property(nonatomic,assign) BOOL emphasized;
- (void)setEmphasized:(BOOL)emphasized animated:(BOOL)animated;
@end

@implementation ZXGlassCard
- (instancetype)init {
    self=[super initWithFrame:CGRectZero];
    if (!self) return nil;
    self.backgroundColor=[UIColor clearColor];
    self.translatesAutoresizingMaskIntoConstraints=NO;
    self.layer.shadowColor=[UIColor blackColor].CGColor;
    self.layer.shadowOpacity=0.24;
    self.layer.shadowRadius=22;
    self.layer.shadowOffset=CGSizeMake(0,10);

    _blurView=[[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark]];
    _blurView.translatesAutoresizingMaskIntoConstraints=NO;
    _blurView.userInteractionEnabled=YES;
    _blurView.contentView.userInteractionEnabled=YES;
    _blurView.layer.cornerRadius=[ZXTheme radius:4];
    _blurView.layer.cornerCurve=kCACornerCurveContinuous;
    _blurView.layer.borderWidth=1.0;
    _blurView.layer.borderColor=[ZXTheme hairline].CGColor;
    _blurView.clipsToBounds=YES;
    [super addSubview:_blurView];

    _highlightLayer=[CAGradientLayer layer];
    _highlightLayer.colors=@[(id)[UIColor colorWithWhite:1 alpha:0.065].CGColor,(id)[UIColor clearColor].CGColor];
    _highlightLayer.startPoint=CGPointMake(0.0,0.0); _highlightLayer.endPoint=CGPointMake(0.85,0.65);
    [_blurView.contentView.layer addSublayer:_highlightLayer];

    _shadeLayer=[CAGradientLayer layer];
    _shadeLayer.colors=@[(id)[UIColor clearColor].CGColor,(id)[UIColor colorWithWhite:0 alpha:0.16].CGColor];
    _shadeLayer.startPoint=CGPointMake(0.5,0.0); _shadeLayer.endPoint=CGPointMake(0.5,1.0);
    [_blurView.contentView.layer addSublayer:_shadeLayer];

    [NSLayoutConstraint activateConstraints:@[[_blurView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],[_blurView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],[_blurView.topAnchor constraintEqualToAnchor:self.topAnchor],[_blurView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]]];
    return self;
}
- (void)addSubview:(UIView *)view { if (view==_blurView) [super addSubview:view]; else [_blurView.contentView addSubview:view]; }
- (void)layoutSubviews { [super layoutSubviews]; _highlightLayer.frame=_blurView.contentView.bounds; _shadeLayer.frame=_blurView.contentView.bounds; }
- (void)setEmphasized:(BOOL)emphasized animated:(BOOL)animated {
    _emphasized=emphasized;
    void (^changes)(void)=^{
        self.blurView.layer.borderColor=(emphasized ? [[ZXTheme accentPrimary] colorWithAlphaComponent:0.30] : [ZXTheme hairline]).CGColor;
        self.layer.shadowOpacity=emphasized ? 0.31 : 0.24;
        self.layer.shadowColor=(emphasized ? [ZXTheme accentPrimary] : [UIColor blackColor]).CGColor;
        self.highlightLayer.opacity=emphasized ? 1.15 : 1.0;
    };
    if (animated) [UIView animateWithDuration:ZXMotionDuration(0.24) delay:0 options:UIViewAnimationOptionCurveEaseOut animations:changes completion:nil]; else changes();
}
@end

#pragma mark - Premium Switch

@interface ZXPremiumSwitch : UIControl
@property(nonatomic,assign,getter=isOn) BOOL on;
@property(nonatomic,strong) UIView *track;
@property(nonatomic,strong) UIView *thumb;
@property(nonatomic,strong) CAGradientLayer *trackGradient;
@property(nonatomic,strong) CAGradientLayer *sheenLayer;
@property(nonatomic,strong) CALayer *innerGlow;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end

@implementation ZXPremiumSwitch
- (instancetype)init {
    self=[super initWithFrame:CGRectZero]; if(!self)return nil;
    self.translatesAutoresizingMaskIntoConstraints=NO;
    self.accessibilityTraits=UIAccessibilityTraitAdjustable;
    self.isAccessibilityElement=YES;
    self.accessibilityLabel=ZXLocalizedUI(@"Function switch");

    _track=[[UIView alloc] initWithFrame:CGRectZero];
    _track.translatesAutoresizingMaskIntoConstraints=NO;
    _track.layer.cornerRadius=17;
    _track.layer.cornerCurve=kCACornerCurveContinuous;
    _track.layer.borderWidth=1;
    _track.layer.borderColor=[ZXTheme hairline].CGColor;
    _track.clipsToBounds=YES;
    [self addSubview:_track];

    _trackGradient=[CAGradientLayer layer];
    _trackGradient.startPoint=CGPointMake(0,0.5);
    _trackGradient.endPoint=CGPointMake(1,0.5);
    [_track.layer addSublayer:_trackGradient];

    _sheenLayer=[CAGradientLayer layer];
    _sheenLayer.startPoint=CGPointMake(0,0);
    _sheenLayer.endPoint=CGPointMake(1,1);
    [_track.layer addSublayer:_sheenLayer];

    _innerGlow=[CALayer layer];
    _innerGlow.cornerRadius=17;
    _innerGlow.borderWidth=1;
    [_track.layer addSublayer:_innerGlow];

    _thumb=[[UIView alloc] initWithFrame:CGRectZero];
    _thumb.translatesAutoresizingMaskIntoConstraints=NO;
    _thumb.backgroundColor=[UIColor colorWithWhite:0.96 alpha:1];
    _thumb.layer.cornerRadius=13;
    _thumb.layer.cornerCurve=kCACornerCurveContinuous;
    _thumb.layer.shadowColor=[UIColor blackColor].CGColor;
    _thumb.layer.shadowOpacity=0.30;
    _thumb.layer.shadowRadius=5;
    _thumb.layer.shadowOffset=CGSizeMake(0,2);
    [_track addSubview:_thumb];

    [NSLayoutConstraint activateConstraints:@[
        [self.widthAnchor constraintEqualToConstant:62],
        [self.heightAnchor constraintEqualToConstant:36],
        [_track.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_track.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_track.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_track.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_thumb.widthAnchor constraintEqualToConstant:26],
        [_thumb.heightAnchor constraintEqualToConstant:26],
        [_thumb.centerYAnchor constraintEqualToAnchor:_track.centerYAnchor]
    ]];
    self.userInteractionEnabled=YES;
    [self addTarget:self action:@selector(zx_touchDown) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(zx_touchUp:) forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(zx_touchCancel:) forControlEvents:UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    [self setOn:NO animated:NO];
    return self;
}
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect expanded=CGRectInset(self.bounds,-10.0,-10.0);
    return CGRectContainsPoint(expanded, point);
}
- (void)zx_touchDown {
    if(!self.enabled || !self.userInteractionEnabled) return;
    [UIView animateWithDuration:ZXMotionDuration(0.08) animations:^{ self.transform=CGAffineTransformMakeScale(0.94,0.94); }];
}
- (void)zx_touchUp:(id)sender {
    if(!self.enabled || !self.userInteractionEnabled) return;
    [UIView animateWithDuration:ZXMotionDuration(0.12) animations:^{ self.transform=CGAffineTransformIdentity; }];
    BOOL requested=!self.isOn;
    [self setOn:requested animated:YES];
    UISelectionFeedbackGenerator *feedback=[UISelectionFeedbackGenerator new];
    [feedback prepare]; [feedback selectionChanged];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
- (void)zx_touchCancel:(id)sender {
    if(!self.enabled) return;
    [UIView animateWithDuration:ZXMotionDuration(0.12) animations:^{ self.transform=CGAffineTransformIdentity; }];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _trackGradient.frame=_track.bounds;
    _trackGradient.cornerRadius=_track.bounds.size.height/2.0;
    _sheenLayer.frame=_track.bounds;
    _sheenLayer.cornerRadius=_track.bounds.size.height/2.0;
    _innerGlow.frame=_track.bounds;
    _innerGlow.cornerRadius=_track.bounds.size.height/2.0;
    _thumb.layer.shadowPath=[UIBezierPath bezierPathWithRoundedRect:_thumb.bounds cornerRadius:_thumb.layer.cornerRadius].CGPath;
}
- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _on=on;
    UIColor *violet=[ZXTheme accentPrimary];
    UIColor *indigo=[ZXTheme accentSecondary];
    _trackGradient.colors=on ? @[(id)[violet colorWithAlphaComponent:0.78].CGColor,(id)[indigo colorWithAlphaComponent:0.62].CGColor] : @[(id)[UIColor colorWithWhite:1 alpha:0.10].CGColor,(id)[UIColor colorWithWhite:1 alpha:0.055].CGColor];
    _sheenLayer.colors=on ? @[(id)[UIColor colorWithWhite:1 alpha:0.20].CGColor,(id)[UIColor clearColor].CGColor] : @[(id)[UIColor colorWithWhite:1 alpha:0.055].CGColor,(id)[UIColor clearColor].CGColor];
    _innerGlow.borderColor=(on ? [UIColor colorWithWhite:1 alpha:0.20] : [UIColor colorWithWhite:1 alpha:0.045]).CGColor;
    _track.layer.borderColor=(on ? [[ZXTheme accentSoft] colorWithAlphaComponent:0.42] : [ZXTheme hairline]).CGColor;
    CGFloat travel=13.0;
    void (^changes)(void)=^{
        self.thumb.transform=CGAffineTransformMakeTranslation(on?travel:-travel,0);
        self.thumb.layer.shadowOpacity=on?0.46:0.25;
        self.thumb.backgroundColor=on?[UIColor colorWithWhite:0.99 alpha:1]:[UIColor colorWithWhite:0.94 alpha:1];
    };
    if(animated)[UIView animateWithDuration:ZXMotionDuration(0.26) delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0.15 options:UIViewAnimationOptionAllowUserInteraction animations:changes completion:nil]; else changes();
    self.accessibilityValue=ZXLocalizedUI(on?@"On":@"Off");
    self.accessibilityTraits=UIAccessibilityTraitAdjustable | (on?UIAccessibilityTraitSelected:0);
}
- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    CGFloat scale=highlighted?0.94:1.0;
    [UIView animateWithDuration:ZXMotionDuration(0.10) animations:^{ self.transform=CGAffineTransformMakeScale(scale,scale); }];
}
@end

#pragma mark - Premium Button

@interface ZXPremiumButton : UIButton
@property(nonatomic,strong) CAGradientLayer *materialLayer;
@property(nonatomic,strong) CAGradientLayer *specularLayer;
@property(nonatomic,strong) UIActivityIndicatorView *spinner;
@property(nonatomic,strong) NSString *savedTitle;
@property(nonatomic,assign) BOOL loading;
- (void)setLoading:(BOOL)loading;
@end

@implementation ZXPremiumButton
- (instancetype)init {
    self=[super initWithFrame:CGRectZero]; if(!self)return nil;
    self.translatesAutoresizingMaskIntoConstraints=NO;
    self.layer.cornerRadius=[ZXTheme radius:3]; self.layer.cornerCurve=kCACornerCurveContinuous;
    self.layer.borderWidth=1.0; self.layer.borderColor=[[ZXTheme accentPrimary] colorWithAlphaComponent:0.34].CGColor;
    self.titleLabel.font=[ZXTheme heading:15];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.78] forState:UIControlStateHighlighted];
    self.accessibilityTraits=UIAccessibilityTraitButton;

    _materialLayer=[CAGradientLayer layer];
    _materialLayer.colors=@[(id)[UIColor colorWithRed:0.18 green:0.15 blue:0.32 alpha:0.98].CGColor,(id)[UIColor colorWithRed:0.12 green:0.11 blue:0.22 alpha:0.98].CGColor];
    _materialLayer.startPoint=CGPointMake(0,0); _materialLayer.endPoint=CGPointMake(1,1); _materialLayer.cornerRadius=[ZXTheme radius:3];
    [self.layer insertSublayer:_materialLayer atIndex:0];
    _specularLayer=[CAGradientLayer layer];
    _specularLayer.colors=@[(id)[UIColor colorWithWhite:1 alpha:0.08].CGColor,(id)[UIColor clearColor].CGColor];
    _specularLayer.startPoint=CGPointMake(0,0); _specularLayer.endPoint=CGPointMake(1,0.7); _specularLayer.cornerRadius=[ZXTheme radius:3];
    [self.layer insertSublayer:_specularLayer above:_materialLayer];
    self.layer.shadowColor=[ZXTheme accentPrimary].CGColor; self.layer.shadowOpacity=0.16; self.layer.shadowRadius=14; self.layer.shadowOffset=CGSizeMake(0,7);

    _spinner=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    _spinner.color=[UIColor whiteColor]; _spinner.hidesWhenStopped=YES; _spinner.translatesAutoresizingMaskIntoConstraints=NO;
    [self addSubview:_spinner]; [NSLayoutConstraint activateConstraints:@[[_spinner.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],[_spinner.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]]];
    [self addTarget:self action:@selector(zx_down) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(zx_up) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    return self;
}
- (void)layoutSubviews { [super layoutSubviews]; _materialLayer.frame=self.bounds; _specularLayer.frame=self.bounds; }
- (void)zx_down { if(self.loading)return; [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred]; [UIView animateWithDuration:ZXMotionDuration(0.10) animations:^{self.transform=CGAffineTransformMakeScale(0.985,0.985); self.layer.shadowOpacity=0.10;}]; }
- (void)zx_up { if(self.loading)return; [UIView animateWithDuration:ZXMotionDuration(0.32) delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0.2 options:UIViewAnimationOptionAllowUserInteraction animations:^{self.transform=CGAffineTransformIdentity; self.layer.shadowOpacity=0.16;} completion:nil]; }
// Legacy selector compatibility: existing callers may still target the original touch selectors.
- (void)zxTouchDown { [self zx_down]; }
- (void)zxTouchUp { [self zx_up]; }
- (void)setLoading:(BOOL)loading {
    _loading=loading; self.userInteractionEnabled=!loading;
    if(loading){ self.savedTitle=[self titleForState:UIControlStateNormal]; [self setTitle:@"" forState:UIControlStateNormal]; [_spinner startAnimating]; }
    else { [self setTitle:self.savedTitle ?: @"" forState:UIControlStateNormal]; [_spinner stopAnimating]; }
}
@end

#pragma mark - Premium Field

@interface ZXPremiumField : UIView <UITextFieldDelegate>
@property(nonatomic,strong) UITextField *textField;
@property(nonatomic,strong) UIVisualEffectView *blurContainer;
@property(nonatomic,strong) UIButton *clearBtn;
@property(nonatomic,strong) UIImageView *iconView;
@end

@implementation ZXPremiumField
- (instancetype)init {
    self=[super initWithFrame:CGRectZero]; if(!self)return nil;
    self.translatesAutoresizingMaskIntoConstraints=NO;
    _blurContainer=[[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark]];
    _blurContainer.translatesAutoresizingMaskIntoConstraints=NO; _blurContainer.layer.cornerRadius=[ZXTheme radius:3]; _blurContainer.layer.cornerCurve=kCACornerCurveContinuous; _blurContainer.layer.borderWidth=1; _blurContainer.layer.borderColor=[ZXTheme hairline].CGColor; _blurContainer.clipsToBounds=YES; [self addSubview:_blurContainer];
    _iconView=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"key.horizontal"]]; _iconView.tintColor=[ZXTheme mutedText]; _iconView.translatesAutoresizingMaskIntoConstraints=NO; [_blurContainer.contentView addSubview:_iconView];
    _textField=[[UITextField alloc] init]; _textField.textColor=[ZXTheme primaryText]; _textField.font=[ZXTheme mono:15 weight:UIFontWeightMedium]; _textField.delegate=self; _textField.autocorrectionType=UITextAutocorrectionTypeNo; _textField.autocapitalizationType=UITextAutocapitalizationTypeNone; _textField.returnKeyType=UIReturnKeyDone; _textField.adjustsFontForContentSizeCategory=YES; _textField.attributedPlaceholder=[[NSAttributedString alloc] initWithString:ZXLocalizedUI(@"Enter License Key") attributes:@{NSForegroundColorAttributeName:[ZXTheme mutedText]}]; _textField.translatesAutoresizingMaskIntoConstraints=NO; [_textField addTarget:self action:@selector(textChanged) forControlEvents:UIControlEventEditingChanged]; [_blurContainer.contentView addSubview:_textField];
    _clearBtn=[UIButton buttonWithType:UIButtonTypeSystem]; [_clearBtn setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal]; _clearBtn.tintColor=[ZXTheme mutedText]; _clearBtn.translatesAutoresizingMaskIntoConstraints=NO; _clearBtn.hidden=YES; [_clearBtn addTarget:self action:@selector(clearText) forControlEvents:UIControlEventTouchUpInside]; [_blurContainer.contentView addSubview:_clearBtn];
    [NSLayoutConstraint activateConstraints:@[
        [_blurContainer.topAnchor constraintEqualToAnchor:self.topAnchor],[_blurContainer.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],[_blurContainer.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],[_blurContainer.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],[_blurContainer.heightAnchor constraintEqualToConstant:60],
        [_iconView.leadingAnchor constraintEqualToAnchor:_blurContainer.contentView.leadingAnchor constant:18],[_iconView.centerYAnchor constraintEqualToAnchor:_blurContainer.contentView.centerYAnchor],[_iconView.widthAnchor constraintEqualToConstant:18],[_iconView.heightAnchor constraintEqualToConstant:18],
        [_clearBtn.trailingAnchor constraintEqualToAnchor:_blurContainer.contentView.trailingAnchor constant:-12],[_clearBtn.centerYAnchor constraintEqualToAnchor:_blurContainer.contentView.centerYAnchor],[_clearBtn.widthAnchor constraintEqualToConstant:34],[_clearBtn.heightAnchor constraintEqualToConstant:34],
        [_textField.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor constant:12],[_textField.trailingAnchor constraintEqualToAnchor:_clearBtn.leadingAnchor constant:-4],[_textField.topAnchor constraintEqualToAnchor:_blurContainer.contentView.topAnchor constant:4],[_textField.bottomAnchor constraintEqualToAnchor:_blurContainer.contentView.bottomAnchor constant:-4]
    ]];
    return self;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField { _blurContainer.layer.borderColor=[[ZXTheme accentPrimary] colorWithAlphaComponent:0.42].CGColor; _iconView.tintColor=[ZXTheme accentSoft]; [UIView animateWithDuration:ZXMotionDuration(0.2) animations:^{self.transform=CGAffineTransformMakeScale(1.006,1.006);}]; }
- (void)textFieldDidEndEditing:(UITextField *)textField { _blurContainer.layer.borderColor=[ZXTheme hairline].CGColor; _iconView.tintColor=[ZXTheme mutedText]; [UIView animateWithDuration:ZXMotionDuration(0.2) animations:^{self.transform=CGAffineTransformIdentity;}]; }
- (BOOL)textFieldShouldReturn:(UITextField *)textField { [textField resignFirstResponder]; return YES; }
- (void)textChanged { _clearBtn.hidden=(_textField.text.length==0); }
- (void)clearText { _textField.text=@""; _clearBtn.hidden=YES; [_textField sendActionsForControlEvents:UIControlEventEditingChanged]; }
@end

static const void *ZXConfirmationBackdropKey = &ZXConfirmationBackdropKey;
static const void *ZXConfirmationCompletionKey = &ZXConfirmationCompletionKey;

#pragma mark - Main Controller

@interface ZentraxUI () <UITextFieldDelegate>
@property(nonatomic,strong) ZXCinematicBackgroundView *backgroundEnvironment;
@property(nonatomic,assign) ZXAppState currentState;
@property(nonatomic,assign) ZXStartupState startupState;
@property(nonatomic,assign) BOOL hasStarted;

@property(nonatomic,assign) BOOL settingsVisible;
@property(nonatomic,assign) BOOL settingsKeyRevealed;

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
@property(nonatomic,strong) NSMutableDictionary<NSString *, NSNumber *> *functionProcessing;
@property(nonatomic,strong) NSMutableDictionary<NSString *, NSUUID *> *functionOperationTokens;
@property(nonatomic,strong) UIView *safeModeOverlay;
@property(nonatomic,strong) UIView *privacyOverlay;
@property(nonatomic,assign) BOOL safeModeLocked;
@property(nonatomic,assign) BOOL privacyCaptureProtected;
@property(nonatomic,strong) UIView *transientFeedbackView;
@property(nonatomic,strong) NSLayoutConstraint *authBottomConstraint;

// Spotify presentation layer (kept completely separate from the existing ZENTRAX UI).
@property(nonatomic,strong) WKWebView *spotifyWebView;
@property(nonatomic,strong) UIRefreshControl *spotifyRefreshControl;
@property(nonatomic,strong) UIView *spotifySplashView;
@property(nonatomic,strong) UITapGestureRecognizer *spotifySecretGesture;
@property(nonatomic,strong) NSTimer *spotifySplashTimer;
@property(nonatomic,assign) BOOL spotifyModeActive;
@property(nonatomic,assign) BOOL spotifyExperienceStarted;
@property(nonatomic,assign) BOOL spotifyInitialLoadFinished;

@property(nonatomic,strong) UIView *splashContainer;
@property(nonatomic,strong) UIView *authContainer;
@property(nonatomic,strong) UIView *dashboardContainer;
@property(nonatomic,strong) UIView *settingsContainer;
@property(nonatomic,strong) UIView *startupBlockContainer;
@property(nonatomic,strong) UIView *globalLoadingOverlay;
@property(nonatomic,strong) UIView *toastView;
@property(nonatomic,strong) UIView *telegramSupportPromptView;
@property(nonatomic,assign) BOOL telegramPromptPresentedThisSession;

@property(nonatomic,strong) UILabel *splashStatus;
@property(nonatomic,strong) UILabel *splashProgressLabel;
@property(nonatomic,strong) UIImageView *splashLogo;
@property(nonatomic,assign) CGFloat currentSplashProgress;
@property(nonatomic,strong) NSTimer *splashAnimationTimer;
@property(nonatomic,copy) void (^pendingSplashCompletion)(void);

@property(nonatomic,strong) ZXPremiumField *keyInput;
@property(nonatomic,strong) ZXPremiumButton *loginBtn;
@property(nonatomic,strong) UILabel *authStatus;
@property(nonatomic,strong) UIScrollView *authScroll;

@property(nonatomic,strong) UILabel *countdownLabel;
@property(nonatomic,strong) UILabel *licenseStatusLabel;
@property(nonatomic,strong) UILabel *settingsKeyLabel;
@property(nonatomic,strong) UIButton *settingsKeyEyeButton;
@property(nonatomic,strong) UILabel *settingsExpiryLabel;
@property(nonatomic,strong) UILabel *connectionLabel;
@property(nonatomic,strong) UIView *connectionDot;
@property(nonatomic,strong) UIStackView *modulesStack;
@property(nonatomic,strong) UIScrollView *modulesScroll;
@property(nonatomic,strong) UIView *emptyState;
@property(nonatomic,strong) ZXGlassCard *licenseCard;

@property(nonatomic,strong) UIScrollView *settingsScroll;
@property(nonatomic,strong) UIStackView *settingsStack;

@property(nonatomic,strong) UILabel *startupBlockTitle;
@property(nonatomic,strong) UILabel *startupBlockMessage;
@property(nonatomic,strong) UIButton *startupBlockAction;
@property(nonatomic,assign) ZXStartupState blockedState;

@property(nonatomic,strong) UIActivityIndicatorView *globalSpinner;
@property(nonatomic,strong) UILabel *globalLoadingTitle;
@property(nonatomic,strong) UILabel *globalLoadingDetail;

- (UIImage *)preferredLogoImage;
- (void)toggleSettingsKey:(UIButton *)sender;
- (void)setupSpotifyExperience;
- (void)startSpotifyExperience;
- (void)showSpotifyWebView;
- (void)showZentraxFromSecretGesture:(UITapGestureRecognizer *)gesture;
- (void)exitZentraxUI;
- (void)handleSpotifyRefresh:(UIRefreshControl *)sender;
- (void)finishSpotifySplash;
- (UIImage *)hostApplicationIconImage;
- (void)rebuildAllContainers;
- (void)styleSecondaryButton:(UIButton *)button;
- (void)applyFunctionVisualState:(NSString *)fid state:(BOOL)isOn animated:(BOOL)animated;
- (void)forceDisableToggleForFunctionId:(NSString *)functionId;
- (void)scheduleTelegramSupportPrompt;
- (void)presentTelegramSupportPromptIfNeeded;
- (void)dismissTelegramSupportPrompt:(BOOL)markJoined;
- (void)openZentraxTelegramChannel;
- (void)showTelegramChannelFromSettings;
- (void)dismissTelegramPromptFromBackdrop:(UIControl *)sender;
- (void)showFunctionFeedbackForFunctionId:(NSString *)fid title:(NSString *)title detail:(NSString *)detail kind:(NSString *)kind;
- (NSString *)functionTargetSignatureForDefinition:(NSDictionary *)definition;
- (NSArray<NSString *> *)conflictingFunctionIdsForFunctionId:(NSString *)functionId;
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
        _functionProcessing = [NSMutableDictionary dictionary];
        _functionOperationTokens = [NSMutableDictionary dictionary];
        _safeModeLocked = NO;
        _privacyCaptureProtected = NO;
        _licenseStatus = ZXLicenseUIStatusUnknown;
        _startupState = ZXStartupStateUnknown;
        _spotifyModeActive = NO;
        _spotifyExperienceStarted = NO;
        _spotifyInitialLoadFinished = NO;
    }
    return self;
}

- (void)dealloc {
    [_licenseTimer invalidate];
    [_heartbeatTimer invalidate];
    [_splashAnimationTimer invalidate];
    [_spotifySplashTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _backgroundEnvironment = [[ZXCinematicBackgroundView alloc] initWithFrame:self.view.bounds];
    _backgroundEnvironment.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_backgroundEnvironment];
    
    self.view.tintColor = [ZXTheme accentPrimary];
    self.currentState = ZXAppStateInit;
    self.telegramPromptPresentedThisSession = NO;

    [self rebuildAllContainers];

    // Build the Spotify host surface before viewDidAppear can start the
    // launch experience. Without this, the Spotify presentation objects are
    // nil and the controller remains on its background layer.
    [self setupSpotifyExperience];
    [self setAllPrimaryContainersHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zx_autoDisabledNotification:) name:@"ZXFunctionAutoDisabledNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zx_accessibilitySettingsChanged:) name:UIAccessibilityReduceMotionStatusDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zx_accessibilitySettingsChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    ZXAuditAccessibilityTree(self.view);
}

- (void)zx_accessibilitySettingsChanged:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        ZXAuditAccessibilityTree(self.view);
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    });
}

- (void)rebuildAllContainers {
    NSDictionary *savedDashboard = self.dashboardConfiguration;
    NSDictionary *savedFunctionStates = [self.functionStates copy];
    BOOL wasSettings = self.settingsVisible;
    BOOL wasDashboard = (self.currentState == ZXAppStateDashboard);
    BOOL wasAuth = (self.currentState == ZXAppStateAuth);

    [self.splashContainer removeFromSuperview];
    [self.authContainer removeFromSuperview];
    [self.dashboardContainer removeFromSuperview];
    [self.settingsContainer removeFromSuperview];
    [self.startupBlockContainer removeFromSuperview];
    [self.globalLoadingOverlay removeFromSuperview];

    [self setupSplash];
    [self setupAuth];
    [self setupDashboard];
    [self setupSettingsScreen];
    [self setupStartupBlock];
    [self setupGlobalLoading];
    [self setAllPrimaryContainersHidden:YES];

    if (savedDashboard.count) {
        [self updateDashboardWithConfiguration:savedDashboard];
        [self updateFunctionStates:savedFunctionStates];
    }
    if (wasSettings) {
        [self setupSettingsScreen];
        [self transitionToPrimaryContainer:self.settingsContainer];
    } else if (wasDashboard) {
        [self showDashboard];
    } else if (wasAuth) {
        [self showLoginScreen];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    ZXAuditAccessibilityTree(self.view);

    if (!self.hasStarted) {
        self.hasStarted = YES;
        [self startSpotifyExperience];
    }
}

- (void)startZentraxUI {
    // Kept for compatibility with existing callers. The normal launch path
    // deliberately does not enter the ZENTRAX bootstrap/UI.
    [self startSpotifyExperience];
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
}

- (void)transitionToPrimaryContainer:(UIView *)target {
    if (!target) return;
    NSArray *containers=@[self.splashContainer ?: [UIView new],self.authContainer ?: [UIView new],self.dashboardContainer ?: [UIView new],self.settingsContainer ?: [UIView new],self.startupBlockContainer ?: [UIView new]];
    for (UIView *container in containers) {
        if (container != target) {
            container.hidden=YES;
            container.alpha=1.0;
            container.transform=CGAffineTransformIdentity;
        }
    }
    target.hidden=NO;
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    target.alpha=0.0;
    target.transform=CGAffineTransformMakeTranslation(0,15.0);
    [UIView animateWithDuration:ZXMotionDuration(0.40) delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseOut animations:^{
        target.alpha=1.0;
        target.transform=CGAffineTransformIdentity;
    } completion:nil];
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


#pragma mark - Spotify Host Experience

- (void)setupSpotifyExperience {
    if (self.spotifyWebView) return;

    self.spotifyModeActive = NO;
    self.spotifyExperienceStarted = NO;
    self.spotifyInitialLoadFinished = NO;

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.allowsInlineMediaPlayback = YES;
    configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    configuration.allowsPictureInPictureMediaPlayback = YES;
    configuration.applicationNameForUserAgent = @"Version/18.6 Mobile/15E148 Safari/604.1";
    configuration.websiteDataStore = [WKWebsiteDataStore defaultDataStore];

    WKUserContentController *userContentController = [[WKUserContentController alloc] init];

    // Keep the hosted page visually app-like, prevent page-level pinch zoom,
    // and suppress browser-style selection/callout behavior.
    NSString *interactionScript =
    @"(function(){"
     "var s=document.createElement('style');"
     "s.innerHTML='html,body,*{-webkit-touch-callout:none!important;-webkit-user-select:none!important;user-select:none!important;}';"
     "(document.head||document.documentElement).appendChild(s);"
     "var m=document.querySelector('meta[name=\"viewport\"]');"
     "if(!m){m=document.createElement('meta');m.name='viewport';document.head.appendChild(m);}"
     "m.setAttribute('content','width=device-width,initial-scale=1,maximum-scale=1,minimum-scale=1,user-scalable=no,viewport-fit=cover');"
     "document.documentElement.style.webkitTouchCallout='none';"
     "document.documentElement.style.touchAction='pan-y';"
     "})();";
    WKUserScript *script = [[WKUserScript alloc] initWithSource:interactionScript
                                                    injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                 forMainFrameOnly:NO];
    [userContentController addUserScript:script];
    configuration.userContentController = userContentController;

    self.spotifyWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    // Present the page as iPhone Safari rather than a generic embedded WebView.
    // This can improve compatibility with sites that gate media features by
    // browser capability; Spotify may still enforce its own playback policy.
    self.spotifyWebView.customUserAgent = @"Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1";
    self.spotifyWebView.translatesAutoresizingMaskIntoConstraints = NO;
    self.spotifyWebView.navigationDelegate = self;
    self.spotifyWebView.UIDelegate = self;
    self.spotifyWebView.opaque = YES;
    self.spotifyWebView.backgroundColor = [UIColor colorWithWhite:0.070588 alpha:1.0];
    self.spotifyWebView.scrollView.backgroundColor = self.spotifyWebView.backgroundColor;
    self.spotifyWebView.scrollView.alwaysBounceVertical = YES;
    self.spotifyWebView.scrollView.alwaysBounceHorizontal = NO;
    self.spotifyWebView.scrollView.directionalLockEnabled = YES;
    self.spotifyWebView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.spotifyWebView.allowsBackForwardNavigationGestures = NO;
    self.spotifyWebView.allowsLinkPreview = NO;
    self.spotifyWebView.scrollView.pinchGestureRecognizer.enabled = NO;
    self.spotifyWebView.scrollView.minimumZoomScale = 1.0;
    self.spotifyWebView.scrollView.maximumZoomScale = 1.0;
    self.spotifyWebView.scrollView.bouncesZoom = NO;
    [self.view addSubview:self.spotifyWebView];

    [NSLayoutConstraint activateConstraints:@[
        [self.spotifyWebView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.spotifyWebView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.spotifyWebView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.spotifyWebView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];

    self.spotifyRefreshControl = [[UIRefreshControl alloc] init];
    self.spotifyRefreshControl.tintColor = [ZXTheme secondaryText];
    [self.spotifyRefreshControl addTarget:self
                                   action:@selector(handleSpotifyRefresh:)
                         forControlEvents:UIControlEventValueChanged];
    [self.spotifyWebView.scrollView addSubview:self.spotifyRefreshControl];

    // Three simultaneous fingers, three consecutive taps. No normal one-
    // or two-finger interaction can enter the ZENTRAX surface.
    self.spotifySecretGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(showZentraxFromSecretGesture:)];
    self.spotifySecretGesture.numberOfTouchesRequired = 3;
    self.spotifySecretGesture.numberOfTapsRequired = 3;
    self.spotifySecretGesture.cancelsTouchesInView = NO;
    self.spotifySecretGesture.delaysTouchesBegan = NO;
    self.spotifySecretGesture.delaysTouchesEnded = NO;
    [self.view addGestureRecognizer:self.spotifySecretGesture];

    self.spotifySplashView = [[UIView alloc] initWithFrame:CGRectZero];
    self.spotifySplashView.translatesAutoresizingMaskIntoConstraints = NO;
    self.spotifySplashView.backgroundColor = self.spotifyWebView.backgroundColor;
    self.spotifySplashView.alpha = 1.0;
    [self.view addSubview:self.spotifySplashView];

    UIImage *hostIcon = [self hostApplicationIconImage];
    UIImageView *iconView = [[UIImageView alloc] initWithImage:hostIcon];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.clipsToBounds = YES;
    iconView.layer.cornerRadius = 18.0;
    [self.spotifySplashView addSubview:iconView];

    [NSLayoutConstraint activateConstraints:@[
        [self.spotifySplashView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.spotifySplashView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.spotifySplashView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.spotifySplashView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [iconView.centerXAnchor constraintEqualToAnchor:self.spotifySplashView.centerXAnchor],
        [iconView.centerYAnchor constraintEqualToAnchor:self.spotifySplashView.centerYAnchor],
        [iconView.widthAnchor constraintEqualToConstant:112.0],
        [iconView.heightAnchor constraintEqualToConstant:112.0]
    ]];

    // Give WebKit a normal playback-capable app audio session. Spotify still
    // controls whether a given account/browser session is allowed to stream.
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback
                          mode:AVAudioSessionModeDefault
                       options:AVAudioSessionCategoryOptionAllowAirPlay | AVAudioSessionCategoryOptionAllowBluetoothA2DP
                         error:nil];
    [audioSession setActive:YES error:nil];

    NSURL *url = [NSURL URLWithString:@"https://open.spotify.com/track/412poAqbwD8OC0dYD1nBkV"];
    if (url) {
        [self.spotifyWebView loadRequest:[NSURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:30.0]];
    }
}

- (UIImage *)hostApplicationIconImage {
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = bundle.infoDictionary ?: @{};

    NSMutableArray<NSString *> *candidates = [NSMutableArray array];

    NSDictionary *icons = info[@"CFBundleIcons"];
    NSArray *primaryFiles = [icons[@"CFBundlePrimaryIcon"] objectForKey:@"CFBundleIconFiles"];
    if ([primaryFiles isKindOfClass:[NSArray class]]) {
        for (id value in primaryFiles) {
            if ([value isKindOfClass:[NSString class]] && [(NSString *)value length]) {
                [candidates addObject:value];
            }
        }
    }

    NSArray *legacyFiles = info[@"CFBundleIconFiles"];
    if ([legacyFiles isKindOfClass:[NSArray class]]) {
        for (id value in legacyFiles) {
            if ([value isKindOfClass:[NSString class]] && [(NSString *)value length] &&
                ![candidates containsObject:value]) {
                [candidates addObject:value];
            }
        }
    }

    for (NSString *name in candidates) {
        UIImage *image = [UIImage imageNamed:name];
        if (image) return image;
        image = [UIImage imageNamed:[name stringByDeletingPathExtension]];
        if (image) return image;
    }

    // Last-resort compatibility fallback: this is only used when the host
    // bundle does not expose an icon filename in its Info.plist.
    return [self preferredLogoImage];
}

- (void)startSpotifyExperience {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.spotifyExperienceStarted) return;
        self.spotifyExperienceStarted = YES;
        self.spotifyModeActive = NO;

        [self.spotifySplashTimer invalidate];
        self.spotifySplashTimer = nil;

        [self setAllPrimaryContainersHidden:YES];
        self.safeModeOverlay.hidden = YES;
        self.privacyOverlay.hidden = YES;
        self.spotifyWebView.hidden = NO;
        self.spotifySplashView.hidden = NO;
        self.spotifySplashView.alpha = 1.0;

        // The page begins loading underneath the splash so the first visible
        // frame after the 1.55 s launch surface is as close to immediate as
        // the network allows.
        if (!self.spotifyWebView.URL) {
            NSURL *url = [NSURL URLWithString:@"https://open.spotify.com/track/412poAqbwD8OC0dYD1nBkV"];
            if (url) [self.spotifyWebView loadRequest:[NSURLRequest requestWithURL:url]];
        }

        self.spotifySplashTimer =
            [NSTimer scheduledTimerWithTimeInterval:1.55
                                             target:self
                                           selector:@selector(finishSpotifySplash)
                                           userInfo:nil
                                            repeats:NO];
    });
}

- (void)finishSpotifySplash {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.spotifyModeActive) return;

        [UIView animateWithDuration:0.32
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState |
                                    UIViewAnimationOptionAllowUserInteraction |
                                    UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.spotifySplashView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.spotifySplashView.hidden = YES;
            self.spotifySplashView.alpha = 1.0;
        }];
    });
}

- (void)showSpotifyWebView {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.spotifyModeActive = NO;
        self.settingsVisible = NO;
        [self stopHeartbeatMonitor];
        [self stopLicenseCountdown];

        [self setAllPrimaryContainersHidden:YES];
        self.safeModeOverlay.hidden = YES;
        self.privacyOverlay.hidden = YES;
        self.spotifyWebView.hidden = NO;
        self.spotifySplashView.hidden = YES;
        self.spotifySplashView.alpha = 1.0;

        [self.view bringSubviewToFront:self.spotifyWebView];
        [self.view bringSubviewToFront:self.spotifySplashView];

        if (!self.spotifyWebView.URL) {
            NSURL *url = [NSURL URLWithString:@"https://open.spotify.com/track/412poAqbwD8OC0dYD1nBkV"];
            if (url) [self.spotifyWebView loadRequest:[NSURLRequest requestWithURL:url]];
        }
    });
}

- (void)showZentraxFromSecretGesture:(UITapGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateRecognized) return;
    if (self.spotifyModeActive) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.spotifyModeActive = YES;
        [self.spotifySplashTimer invalidate];
        self.spotifySplashTimer = nil;

        self.spotifySplashView.hidden = YES;
        self.spotifySplashView.alpha = 1.0;
        self.spotifyWebView.hidden = YES;

        [self stopHeartbeatMonitor];
        [self stopLicenseCountdown];
        self.safeModeOverlay.hidden = YES;
        self.privacyOverlay.hidden = YES;
        self.settingsVisible = NO;

        [self setAllPrimaryContainersHidden:YES];

        // The existing ZENTRAX authentication screen is reused unchanged.
        // No bootstrap splash is shown for the secret entry path.
        [self showLoginScreen];
        [self.view bringSubviewToFront:self.authContainer];
    });
}

- (void)exitZentraxUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.spotifySplashTimer invalidate];
        self.spotifySplashTimer = nil;

        self.spotifyModeActive = NO;
        self.settingsVisible = NO;

        [self stopHeartbeatMonitor];
        [self stopLicenseCountdown];

        self.safeModeLocked = NO;
        self.safeModeOverlay.hidden = YES;
        self.privacyOverlay.hidden = YES;

        [self setAllPrimaryContainersHidden:YES];
        [self showSpotifyWebView];
    });
}

- (void)handleSpotifyRefresh:(UIRefreshControl *)sender {
    if (self.spotifyModeActive) {
        [sender endRefreshing];
        return;
    }

    [self.spotifyWebView reload];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (sender.isRefreshing) [sender endRefreshing];
    });
}

#pragma mark - WKWebView Delegates

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    // Keep Spotify navigation inside the embedded app surface. This also
    // handles target=_blank links without unexpectedly launching Safari.
    if (!navigationAction.targetFrame) {
        [webView loadRequest:navigationAction.request];
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (WKWebView *)webView:(WKWebView *)webView
createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
forNavigationAction:(WKNavigationAction *)navigationAction
windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (!navigationAction.targetFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView
didFinishNavigation:(WKNavigation *)navigation {
    self.spotifyInitialLoadFinished = YES;
    if (self.spotifyRefreshControl.isRefreshing) {
        [self.spotifyRefreshControl endRefreshing];
    }
}

- (void)webView:(WKWebView *)webView
didFailNavigation:(WKNavigation *)navigation
      withError:(NSError *)error {
    if (self.spotifyRefreshControl.isRefreshing) {
        [self.spotifyRefreshControl endRefreshing];
    }
}

- (void)webView:(WKWebView *)webView
didFailProvisionalNavigation:(WKNavigation *)navigation
      withError:(NSError *)error {
    if (self.spotifyRefreshControl.isRefreshing) {
        [self.spotifyRefreshControl endRefreshing];
    }
}

// Returning nil disables the native iOS context menu/preview on long press.
- (UIContextMenuConfiguration *)webView:(WKWebView *)webView
contextMenuConfigurationForElement:(WKContextMenuElementInfo *)elementInfo
                        completionHandler:(void (^)(UIContextMenuConfiguration * _Nullable configuration))completionHandler API_AVAILABLE(ios(13.0)) {
    if (completionHandler) completionHandler(nil);
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

    UIView *logoWrapper = [[UIView alloc] init];
    logoWrapper.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:logoWrapper];

    _splashLogo = [[UIImageView alloc] initWithImage:[self preferredLogoImage]];
    _splashLogo.contentMode = UIViewContentModeScaleAspectFit;
    _splashLogo.layer.cornerRadius = 32;
    _splashLogo.clipsToBounds = YES;
    _splashLogo.translatesAutoresizingMaskIntoConstraints = NO;
    [logoWrapper addSubview:_splashLogo];

    UILabel *brand = [self label:@"ZENTRAX" size:42 weight:UIFontWeightHeavy color:[ZXTheme primaryText]];
    [ZXTheme track:brand spacing:5.0];
    brand.textAlignment = NSTextAlignmentCenter;
    brand.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:brand];

    _splashStatus = [self label:@"INITIALIZING" size:12 weight:UIFontWeightBold color:[ZXTheme accentPrimary]];
    [ZXTheme track:_splashStatus spacing:2.5];
    _splashStatus.textAlignment = NSTextAlignmentCenter;
    _splashStatus.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_splashStatus];
    
    _splashProgressLabel = [self label:@"0%" size:16 weight:UIFontWeightBold color:[ZXTheme primaryText]];
    _splashProgressLabel.font = [ZXTheme mono:16 weight:UIFontWeightBold];
    _splashProgressLabel.textAlignment = NSTextAlignmentCenter;
    _splashProgressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_splashProgressLabel];

    [NSLayoutConstraint activateConstraints:@[
        [logoWrapper.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [logoWrapper.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor constant:-80],
        [logoWrapper.widthAnchor constraintEqualToConstant:96],
        [logoWrapper.heightAnchor constraintEqualToConstant:96],
        
        [_splashLogo.leadingAnchor constraintEqualToAnchor:logoWrapper.leadingAnchor],
        [_splashLogo.trailingAnchor constraintEqualToAnchor:logoWrapper.trailingAnchor],
        [_splashLogo.topAnchor constraintEqualToAnchor:logoWrapper.topAnchor],
        [_splashLogo.bottomAnchor constraintEqualToAnchor:logoWrapper.bottomAnchor],
        
        [brand.topAnchor constraintEqualToAnchor:logoWrapper.bottomAnchor constant:32],
        [brand.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        
        [_splashProgressLabel.bottomAnchor constraintEqualToAnchor:_splashContainer.safeAreaLayoutGuide.bottomAnchor constant:-50],
        [_splashProgressLabel.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        
        [_splashStatus.bottomAnchor constraintEqualToAnchor:_splashProgressLabel.topAnchor constant:-10],
        [_splashStatus.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor]
    ]];
}

- (void)runPremiumSplashCompletion:(void (^)(void))completion {
    self.pendingSplashCompletion = completion;
    self.currentSplashProgress = 0.0;
    self.splashAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(tickSplashAnimation:) userInfo:nil repeats:YES];
}

- (void)tickSplashAnimation:(NSTimer *)timer {
    self.currentSplashProgress += 1.5;
    if(self.currentSplashProgress > 100.0) self.currentSplashProgress = 100.0;
    self.splashProgressLabel.text = [NSString stringWithFormat:@"%d%%", (int)self.currentSplashProgress];
    
    if (self.currentSplashProgress >= 100.0) {
        [self.splashAnimationTimer invalidate];
        self.splashAnimationTimer = nil;
        if (self.pendingSplashCompletion) {
            self.pendingSplashCompletion();
            self.pendingSplashCompletion = nil;
        }
    }
}

#pragma mark - Authentication (Elegant & Timeout Protected)

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
        [content.widthAnchor constraintEqualToAnchor:_authScroll.frameLayoutGuide.widthAnchor],
        [content.heightAnchor constraintEqualToAnchor:_authScroll.frameLayoutGuide.heightAnchor]
    ]];

    UIImageView *logo = [[UIImageView alloc] initWithImage:[self preferredLogoImage]];
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.layer.cornerRadius = 22;
    logo.clipsToBounds = YES;
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:logo];

    UILabel *title = [self label:@"SECURE ACCESS" size:24 weight:UIFontWeightHeavy color:[ZXTheme primaryText]];
    [ZXTheme track:title spacing:1.5];
    title.textAlignment = NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:title];

    UILabel *subtitle = [self label:@"Enter your infrastructure license key." size:14 weight:UIFontWeightMedium color:[ZXTheme secondaryText]];
    subtitle.textAlignment = NSTextAlignmentCenter;
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:subtitle];

    _keyInput = [[ZXPremiumField alloc] init];
    _keyInput.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:_keyInput];

    _loginBtn = [[ZXPremiumButton alloc] init];
    [_loginBtn setTitle:ZXLocalizedUI(@"CONTINUE") forState:UIControlStateNormal];
    _loginBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_loginBtn addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:_loginBtn];

    _authStatus = [self label:@"" size:14 weight:UIFontWeightMedium color:[ZXTheme mutedText]];
    _authStatus.textAlignment = NSTextAlignmentCenter;
    _authStatus.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:_authStatus];

    [NSLayoutConstraint activateConstraints:@[
        [logo.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],
        [logo.centerYAnchor constraintEqualToAnchor:content.centerYAnchor constant:-140],
        [logo.widthAnchor constraintEqualToConstant:76],
        [logo.heightAnchor constraintEqualToConstant:76],
        
        [title.topAnchor constraintEqualToAnchor:logo.bottomAnchor constant:28],
        [title.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],
        
        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
        [subtitle.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],
        
        [_keyInput.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:45],
        [_keyInput.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:32],
        [_keyInput.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-32],
        
        [_loginBtn.topAnchor constraintEqualToAnchor:_keyInput.bottomAnchor constant:28],
        [_loginBtn.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:32],
        [_loginBtn.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-32],
        [_loginBtn.heightAnchor constraintEqualToConstant:60],
        
        [_authStatus.topAnchor constraintEqualToAnchor:_loginBtn.bottomAnchor constant:24],
        [_authStatus.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:24],
        [_authStatus.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-24]
    ]];
}

- (void)keyboardWillShow:(NSNotification *)note {
    CGSize kbSize = [[note.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    self.authScroll.contentInset = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.authScroll.scrollIndicatorInsets = self.authScroll.contentInset;
}
- (void)keyboardWillHide:(NSNotification *)note {
    self.authScroll.contentInset = UIEdgeInsetsZero;
    self.authScroll.scrollIndicatorInsets = UIEdgeInsetsZero;
}

- (void)handleLogin {
    [self.view endEditing:YES]; 
    
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSDate *timeout = [d objectForKey:ZXLoginTimeoutKey];
    if (timeout && [timeout timeIntervalSinceNow] > 0) {
        NSInteger mins = (NSInteger)ceil([timeout timeIntervalSinceNow] / 60.0);
        self.authStatus.textColor = [ZXTheme error];
        self.authStatus.text = [NSString stringWithFormat:ZXLocalizedUI(@"Authentication locked. Try again in %ld min."), (long)mins];
        [self showToast:self.authStatus.text success:NO];
        [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeError];
        return;
    }
    
    NSString *key = [_keyInput.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!key.length) {
        [self showToast:@"Enter your license key." success:NO];
        return;
    }
    
    [d setObject:key forKey:ZXLastKey];
    [d synchronize];

    [_loginBtn setLoading:YES];
    _authStatus.textColor = [ZXTheme secondaryText];
    _authStatus.text = ZXLocalizedUI(@"Authenticating...");

    __weak typeof(self) weakSelf = self;
    void (^processResult)(BOOL, ZXAuthError, NSString *) = ^(BOOL success, ZXAuthError errorType, NSString *errorMsg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf; if (!self) return;
            [self.loginBtn setLoading:NO];
            
            NSUserDefaults *ud = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
            if (success) {
                [ud removeObjectForKey:ZXLoginAttemptsKey];
                [ud removeObjectForKey:ZXLoginTimeoutKey];
                [ud synchronize];
                
                self.authStatus.textColor = [ZXTheme success];
                self.authStatus.text = ZXLocalizedUI(@"Access Granted");
                [self showDashboard];
            } else {
                NSString *finalErrorMsg = errorMsg; 
                NSInteger attempts = [ud integerForKey:ZXLoginAttemptsKey] + 1;
                [ud setInteger:attempts forKey:ZXLoginAttemptsKey];
                if (attempts >= 5) {
                    [ud setObject:[[NSDate date] dateByAddingTimeInterval:600] forKey:ZXLoginTimeoutKey]; // 10 minutes
                    [ud removeObjectForKey:ZXLoginAttemptsKey];
                    finalErrorMsg = @"Too many failed attempts. You are timed out for 10 minutes.";
                }
                [ud synchronize];
                [self presentAuthError:errorType message:finalErrorMsg];
            }
        });
    };

    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestAuthenticationWithKey:completion:)]) {
        [self.delegate zentraxDidRequestAuthenticationWithKey:key completion:processResult];
    } else {
        Class mgrCls = NSClassFromString(@"ZentraxNetworkManager");
        if (mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
            id manager = ((id (*)(id, SEL))objc_msgSend)((id)mgrCls, NSSelectorFromString(@"sharedManager"));
            SEL authSel = NSSelectorFromString(@"authenticateWithKey:completion:");
            if ([manager respondsToSelector:authSel]) {
                void (^netCompletion)(BOOL, NSDictionary *, NSInteger, NSString *) = ^(BOOL success, NSDictionary *res, NSInteger errType, NSString *errMsg) {
                    processResult(success, (ZXAuthError)errType, errMsg);
                };
                ((void (*)(id, SEL, id, id))objc_msgSend)(manager, authSel, key, netCompletion);
            } else processResult(NO, ZXAuthErrorServer, @"Integration bridge unavailable.");
        } else processResult(NO, ZXAuthErrorServer, @"Integration bridge unavailable.");
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

#pragma mark - Dashboard (Ultra Premium Home)

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

    UILabel *dashTitle = [self label:@"ZENTRAX" size:20 weight:UIFontWeightHeavy color:[ZXTheme primaryText]];
    [ZXTheme track:dashTitle spacing:1.5];
    dashTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:dashTitle];

    _connectionDot = [[UIView alloc] init];
    _connectionDot.backgroundColor = [ZXTheme success];
    _connectionDot.layer.cornerRadius = 3;
    _connectionDot.layer.shadowColor = [ZXTheme success].CGColor;
    _connectionDot.layer.shadowOpacity = 0.8;
    _connectionDot.layer.shadowRadius = 6;
    _connectionDot.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:_connectionDot];

    _connectionLabel = [self label:@"SECURE" size:12 weight:UIFontWeightHeavy color:[ZXTheme primaryText]];
    [ZXTheme track:_connectionLabel spacing:1.5];
    _connectionLabel.textAlignment = NSTextAlignmentRight;
    _connectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:_connectionLabel];

    UIButton *settingsBtn = [self iconButton:@"line.3.horizontal" size:30];
    [settingsBtn addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:settingsBtn];

    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:28],
        [header.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-28],
        [header.topAnchor constraintEqualToAnchor:_dashboardContainer.safeAreaLayoutGuide.topAnchor constant:12],
        [header.heightAnchor constraintEqualToConstant:48],
        
        [logo.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [logo.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [logo.widthAnchor constraintEqualToConstant:32],
        [logo.heightAnchor constraintEqualToConstant:32],
        
        [dashTitle.leadingAnchor constraintEqualToAnchor:logo.trailingAnchor constant:16],
        [dashTitle.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        
        [_connectionLabel.trailingAnchor constraintEqualToAnchor:settingsBtn.leadingAnchor constant:-18],
        [_connectionLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        
        [_connectionDot.trailingAnchor constraintEqualToAnchor:_connectionLabel.leadingAnchor constant:-8],
        [_connectionDot.centerYAnchor constraintEqualToAnchor:_connectionLabel.centerYAnchor],
        [_connectionDot.widthAnchor constraintEqualToConstant:6],
        [_connectionDot.heightAnchor constraintEqualToConstant:6],
        
        [settingsBtn.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],
        [settingsBtn.centerYAnchor constraintEqualToAnchor:header.centerYAnchor]
    ]];

    // Pure Countdown Card (No Key/Exact Date)
    _licenseCard = [[ZXGlassCard alloc] init];
    [_dashboardContainer addSubview:_licenseCard];
    [NSLayoutConstraint activateConstraints:@[
        [_licenseCard.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [_licenseCard.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [_licenseCard.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:30],
        [_licenseCard.heightAnchor constraintEqualToConstant:130]
    ]];

    UILabel *statusHeader = [self label:@"STATUS" size:12 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:statusHeader spacing:2.0];
    statusHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:statusHeader];

    UILabel *licenseContextLabel = [self label:@"PRIVATE ACCESS • SERVER AUTHORITATIVE" size:10 weight:UIFontWeightSemibold color:[ZXTheme mutedText]];
    [ZXTheme track:licenseContextLabel spacing:1.2];
    licenseContextLabel.translatesAutoresizingMaskIntoConstraints = NO;
    licenseContextLabel.accessibilityElementsHidden = YES;
    [_licenseCard addSubview:licenseContextLabel];

    _countdownLabel = [self label:@"—" size:36 weight:UIFontWeightHeavy color:[ZXTheme primaryText]];
    _countdownLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:_countdownLabel];

    _licenseStatusLabel = [self label:@"UNACTIVATED" size:13 weight:UIFontWeightBold color:[ZXTheme warning]];
    [ZXTheme track:_licenseStatusLabel spacing:1.5];
    _licenseStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:_licenseStatusLabel];

    [NSLayoutConstraint activateConstraints:@[
        [statusHeader.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:24],
        [statusHeader.topAnchor constraintEqualToAnchor:_licenseCard.topAnchor constant:24],
        
        [_licenseStatusLabel.leadingAnchor constraintEqualToAnchor:statusHeader.trailingAnchor constant:12],
        [_licenseStatusLabel.centerYAnchor constraintEqualToAnchor:statusHeader.centerYAnchor],
        
        [licenseContextLabel.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:24],
        [licenseContextLabel.topAnchor constraintEqualToAnchor:statusHeader.bottomAnchor constant:8],
        [licenseContextLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_licenseCard.trailingAnchor constant:-24],
        [_countdownLabel.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:24],
        [_countdownLabel.bottomAnchor constraintEqualToAnchor:_licenseCard.bottomAnchor constant:-24],
        [_countdownLabel.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor constant:-24]
    ]];

    _modulesScroll = [[UIScrollView alloc] init];
    _modulesScroll.showsVerticalScrollIndicator = NO;
    _modulesScroll.alwaysBounceVertical = YES;
    _modulesScroll.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:_modulesScroll];

    _modulesStack = [[UIStackView alloc] init];
    _modulesStack.axis = UILayoutConstraintAxisVertical;
    _modulesStack.spacing = 16;
    _modulesStack.translatesAutoresizingMaskIntoConstraints = NO;
    [_modulesScroll addSubview:_modulesStack];

    [NSLayoutConstraint activateConstraints:@[
        [_modulesScroll.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [_modulesScroll.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [_modulesScroll.topAnchor constraintEqualToAnchor:_licenseCard.bottomAnchor constant:32],
        [_modulesScroll.bottomAnchor constraintEqualToAnchor:_dashboardContainer.bottomAnchor],
        
        [_modulesStack.leadingAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.leadingAnchor],
        [_modulesStack.trailingAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.trailingAnchor],
        [_modulesStack.topAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.topAnchor constant:4],
        [_modulesStack.bottomAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.bottomAnchor constant:-40],
        [_modulesStack.widthAnchor constraintEqualToAnchor:_modulesScroll.frameLayoutGuide.widthAnchor]
    ]];

    [self createEmptyStateView];
}

- (void)createEmptyStateView {
    _emptyState = [[ZXGlassCard alloc] init];
    
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"cube.transparent"]];
    icon.tintColor = [ZXTheme mutedText];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyState addSubview:icon];
    
    UILabel *title = [self label:@"No functions assigned" size:16 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    title.textAlignment = NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyState addSubview:title];
    
    UILabel *detail = [self label:@"Server configuration will appear here." size:14 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    detail.textAlignment = NSTextAlignmentCenter;
    detail.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyState addSubview:detail];
    
    [NSLayoutConstraint activateConstraints:@[
        [_emptyState.heightAnchor constraintEqualToConstant:160],
        [icon.centerXAnchor constraintEqualToAnchor:_emptyState.centerXAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:_emptyState.centerYAnchor constant:-20],
        [icon.widthAnchor constraintEqualToConstant:36],
        [icon.heightAnchor constraintEqualToConstant:36],
        [title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:16],
        [title.centerXAnchor constraintEqualToAnchor:_emptyState.centerXAnchor],
        [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:6],
        [detail.centerXAnchor constraintEqualToAnchor:_emptyState.centerXAnchor]
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
            UIView *headerWrapper = [[UIView alloc] init];
            headerWrapper.translatesAutoresizingMaskIntoConstraints = NO;
            
            UIView *glassPill = [[UIView alloc] init];
            glassPill.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
            glassPill.layer.cornerRadius = 12;
            glassPill.layer.borderWidth = 1.0;
            glassPill.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
            glassPill.translatesAutoresizingMaskIntoConstraints = NO;
            [headerWrapper addSubview:glassPill];
            
            UILabel *cat = [self label:categoryName.uppercaseString size:12 weight:UIFontWeightHeavy color:[UIColor whiteColor]];
            [ZXTheme track:cat spacing:2.0];
            cat.translatesAutoresizingMaskIntoConstraints = NO;
            [glassPill addSubview:cat];
            
            [NSLayoutConstraint activateConstraints:@[
                [glassPill.leadingAnchor constraintEqualToAnchor:headerWrapper.leadingAnchor],
                [glassPill.topAnchor constraintEqualToAnchor:headerWrapper.topAnchor constant:12],
                [glassPill.bottomAnchor constraintEqualToAnchor:headerWrapper.bottomAnchor constant:-4],
                
                [cat.leadingAnchor constraintEqualToAnchor:glassPill.leadingAnchor constant:16],
                [cat.trailingAnchor constraintEqualToAnchor:glassPill.trailingAnchor constant:-16],
                [cat.topAnchor constraintEqualToAnchor:glassPill.topAnchor constant:8],
                [cat.bottomAnchor constraintEqualToAnchor:glassPill.bottomAnchor constant:-8]
            ]];
            [_modulesStack addArrangedSubview:headerWrapper];
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

// Ultra Premium Glass Function Card
- (UIView *)functionCardForDefinition:(NSDictionary *)definition functionId:(NSString *)fid isOn:(BOOL)on {
    ZXGlassCard *card = [[ZXGlassCard alloc] init];
    card.userInteractionEnabled=YES;
    card.blurView.userInteractionEnabled=YES;
    card.blurView.contentView.userInteractionEnabled=YES;
    
    card.blurView.layer.borderColor = on ? [ZXTheme borderAccent].CGColor : [ZXTheme border].CGColor;
    card.layer.shadowOpacity = on ? 0.42 : 0.25;
    card.layer.shadowColor = on ? [ZXTheme accentPrimary].CGColor : [UIColor blackColor].CGColor;
    card.highlightLayer.colors = on ? @[(id)[UIColor colorWithWhite:1.0 alpha:0.16].CGColor,(id)[[ZXTheme accentSoft] colorWithAlphaComponent:0.055].CGColor,(id)[UIColor clearColor].CGColor] : @[(id)[UIColor colorWithWhite:1 alpha:0.065].CGColor,(id)[UIColor clearColor].CGColor];
    card.shadeLayer.colors = on ? @[(id)[[ZXTheme accentPrimary] colorWithAlphaComponent:0.035].CGColor,(id)[UIColor colorWithWhite:0 alpha:0.10].CGColor] : @[(id)[UIColor clearColor].CGColor,(id)[UIColor colorWithWhite:0 alpha:0.16].CGColor];

    UIView *iconBg = [[UIView alloc] init];
    iconBg.backgroundColor = on ? [[ZXTheme accentPrimary] colorWithAlphaComponent:0.2] : [UIColor colorWithWhite:1.0 alpha:0.08];
    iconBg.layer.cornerRadius = 14;
    iconBg.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:iconBg];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"bolt.shield.fill"]];
    icon.tintColor = on ? [ZXTheme accentPrimary] : [ZXTheme mutedText];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [iconBg addSubview:icon];

    UILabel *title = [self label:[NSString stringWithFormat:@"%@", definition[@"name"] ?: definition[@"title"] ?: fid]
                              size:17 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    title.numberOfLines = 0; 
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:title];

    UIView *pill = [[UIView alloc] init];
    pill.backgroundColor = on ? [[ZXTheme success] colorWithAlphaComponent:0.15] : [[ZXTheme mutedText] colorWithAlphaComponent:0.1];
    pill.layer.cornerRadius = 6;
    pill.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:pill];

    UILabel *stateLabel = [self label:on ? @"ACTIVE" : @"READY"
                               size:10 weight:UIFontWeightBold color:on ? [ZXTheme success] : [ZXTheme mutedText]];
    [ZXTheme track:stateLabel spacing:1.0];
    stateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [pill addSubview:stateLabel];
    self.functionStateLabels[fid] = stateLabel;

    // Use the native iOS switch for a stable, familiar control. The previous
    // custom switch applied press transforms and could look compressed/jump on tap.
    UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
    toggle.translatesAutoresizingMaskIntoConstraints = NO;
    toggle.on = on;
    toggle.onTintColor = [ZXTheme accentPrimary];
    toggle.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.16];
    toggle.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.055];
    toggle.layer.cornerRadius = 15.5;
    toggle.clipsToBounds = YES;
    toggle.accessibilityLabel = ZXLocalizedUI(@"Function switch");
    toggle.accessibilityValue = ZXLocalizedUI(on ? @"On" : @"Off");
    [toggle addTarget:self action:@selector(functionToggleChanged:) forControlEvents:UIControlEventValueChanged];
    [card addSubview:toggle];
    self.functionControls[fid] = toggle;

    NSString *description = [NSString stringWithFormat:@"%@", definition[@"description"] ?: @"Server-managed secure function."];
    UILabel *detail = [self label:description size:14 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    detail.numberOfLines = 0; 
    detail.lineBreakMode = NSLineBreakByWordWrapping;
    detail.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:detail];

    [NSLayoutConstraint activateConstraints:@[
        [iconBg.leadingAnchor constraintEqualToAnchor:card.blurView.contentView.leadingAnchor constant:20],
        [iconBg.topAnchor constraintEqualToAnchor:card.blurView.contentView.topAnchor constant:20],
        [iconBg.widthAnchor constraintEqualToConstant:44],
        [iconBg.heightAnchor constraintEqualToConstant:44],
        
        [icon.centerXAnchor constraintEqualToAnchor:iconBg.centerXAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:iconBg.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:22],
        [icon.heightAnchor constraintEqualToConstant:22],
        
        [toggle.trailingAnchor constraintEqualToAnchor:card.blurView.contentView.trailingAnchor constant:-20],
        [toggle.topAnchor constraintEqualToAnchor:card.blurView.contentView.topAnchor constant:20],
        [toggle.widthAnchor constraintEqualToConstant:51],
        [toggle.heightAnchor constraintEqualToConstant:31],
        
        [title.leadingAnchor constraintEqualToAnchor:iconBg.trailingAnchor constant:16],
        [title.trailingAnchor constraintLessThanOrEqualToAnchor:toggle.leadingAnchor constant:-16],
        [title.topAnchor constraintEqualToAnchor:card.blurView.contentView.topAnchor constant:20],
        
        [pill.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [pill.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
        
        [stateLabel.leadingAnchor constraintEqualToAnchor:pill.leadingAnchor constant:8],
        [stateLabel.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor constant:-8],
        [stateLabel.topAnchor constraintEqualToAnchor:pill.topAnchor constant:4],
        [stateLabel.bottomAnchor constraintEqualToAnchor:pill.bottomAnchor constant:-4],
        
        [detail.leadingAnchor constraintEqualToAnchor:card.blurView.contentView.leadingAnchor constant:20],
        [detail.trailingAnchor constraintEqualToAnchor:card.blurView.contentView.trailingAnchor constant:-20],
        [detail.topAnchor constraintGreaterThanOrEqualToAnchor:pill.bottomAnchor constant:16],
        [detail.topAnchor constraintGreaterThanOrEqualToAnchor:iconBg.bottomAnchor constant:16],
        [detail.bottomAnchor constraintEqualToAnchor:card.blurView.contentView.bottomAnchor constant:-20]
    ]];
    return card;
}

- (NSString *)functionIdForControl:(UIControl *)control {
    for (NSString *fid in self.functionControls) {
        if (self.functionControls[fid] == control) return fid;
    }
    return nil;
}

- (NSString *)functionTargetSignatureForDefinition:(NSDictionary *)definition {
    if (![definition isKindOfClass:[NSDictionary class]]) return @"";
    NSArray<NSArray<NSString *> *> *aliases=@[
        @[@"target_package",@"targetPackage",@"package_name",@"packageName",@"bundle_id",@"bundleIdentifier",@"targetBundleIdentifier",@"target_package_name",@"package",@"bundle"],
        @[@"target_directory",@"targetDirectory",@"document_directory",@"documentDirectory",@"directory",@"target_dir",@"targetDir",@"target_document_directory",@"targetDocumentDirectory",@"document_directory_path",@"documentDirectoryPath"],
        @[@"target_file_name",@"targetFileName",@"file_name",@"fileName",@"filename",@"target_file",@"targetFile",@"target_filename",@"file",@"fileName"]
    ];
    NSMutableArray<NSString *> *parts=[NSMutableArray arrayWithCapacity:3];
    for(NSArray<NSString *> *keys in aliases){
        id value=nil;
        for(NSString *key in keys){
            id candidate=definition[key];
            if(candidate && candidate!=[NSNull null] && [[candidate description] length]){ value=candidate; break; }
        }
        NSString *normalized=value ? [[value description] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : @"";
        normalized=[normalized stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
        normalized=[normalized lowercaseString];
        [parts addObject:normalized];
    }
    if(!parts[0].length || !parts[1].length || !parts[2].length) return @"";
    return [NSString stringWithFormat:@"%@|%@|%@",parts[0],parts[1],parts[2]];
}

- (NSArray<NSString *> *)conflictingFunctionIdsForFunctionId:(NSString *)functionId {
    NSDictionary *definition=self.functionDefinitions[functionId];
    NSString *signature=[self functionTargetSignatureForDefinition:definition];
    if(!signature.length) return @[];
    NSMutableArray<NSString *> *result=[NSMutableArray array];
    for(NSString *fid in self.functionDefinitions){
        if([fid isEqualToString:functionId]) continue;
        if(![self.functionStates[fid] boolValue]) continue;
        NSString *other=[self functionTargetSignatureForDefinition:self.functionDefinitions[fid]];
        if(other.length && [other isEqualToString:signature]) [result addObject:fid];
    }
    return result;
}

- (void)deactivateConflictingFunctionControlsForFunctionId:(NSString *)functionId {
    NSArray<NSString *> *conflicts=[self conflictingFunctionIdsForFunctionId:functionId];
    for(NSString *otherFID in conflicts){
        [self.functionProcessing removeObjectForKey:otherFID];
        [self.functionOperationTokens removeObjectForKey:otherFID];
        [self applyFunctionVisualState:otherFID state:NO animated:YES];
        UIControl *other=self.functionControls[otherFID];
        other.userInteractionEnabled=NO;
    }
}

- (void)functionToggleChanged:(UIControl *)sender {
    NSString *fid=[self functionIdForControl:sender];
    if(!fid.length) return;
    if([self.functionProcessing[fid] boolValue]) return;
    BOOL requested=([sender isKindOfClass:[UISwitch class]] ? ((UISwitch *)sender).isOn : NO);
    NSArray<NSString *> *conflicts=requested ? [self conflictingFunctionIdsForFunctionId:fid] : @[];
    NSMutableDictionary<NSString *,NSNumber *> *previousConflictStates=[NSMutableDictionary dictionary];
    for(NSString *otherFID in conflicts){
        previousConflictStates[otherFID]=@([self.functionStates[otherFID] boolValue]);
        [self.functionProcessing removeObjectForKey:otherFID];
        [self.functionOperationTokens removeObjectForKey:otherFID];
        [self applyFunctionVisualState:otherFID state:NO animated:YES];
        UIControl *other=self.functionControls[otherFID];
        other.userInteractionEnabled=NO;
    }

    self.functionProcessing[fid]=@YES;
    NSUUID *token=[NSUUID UUID]; self.functionOperationTokens[fid]=token;
    ZXGlassCard *card=(ZXGlassCard *)self.functionCards[fid];
    UILabel *state=self.functionStateLabels[fid];
    UIView *pill=state.superview;
    sender.userInteractionEnabled=NO;
    sender.accessibilityValue=ZXLocalizedUI(@"PROCESSING");
    state.text=ZXLocalizedUI(@"PROCESSING"); state.textColor=[ZXTheme warning];
    pill.backgroundColor=[[ZXTheme warning] colorWithAlphaComponent:0.12];
    [card setEmphasized:YES animated:YES];
    sender.transform=CGAffineTransformIdentity;
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];

    __weak typeof(self) weakSelf=self;
    void (^finish)(BOOL,NSString *)=^(BOOL success,NSString *msg){
        dispatch_async(dispatch_get_main_queue(),^{
            __strong typeof(weakSelf) self=weakSelf; if(!self)return;
            NSUUID *current=self.functionOperationTokens[fid];
            if(!current || ![current isEqual:token]) return;
            [self.functionProcessing removeObjectForKey:fid]; [self.functionOperationTokens removeObjectForKey:fid];
            sender.userInteractionEnabled=YES;
            if(success){
                for(NSString *otherFID in conflicts){ self.functionControls[otherFID].userInteractionEnabled=YES; }
                [self applyFunctionVisualState:fid state:requested animated:YES];
                if(requested && conflicts.count){
                    NSString *name=self.functionDefinitions[fid][@"name"] ?: self.functionDefinitions[fid][@"title"] ?: fid;
                    [self showFunctionFeedbackForFunctionId:fid title:@"FUNCTION ACTIVATED" detail:[NSString stringWithFormat:@"%@\nPrevious matching target released",name] kind:@"success"];
                } else {
                    UINotificationFeedbackGenerator *h=[UINotificationFeedbackGenerator new]; [h notificationOccurred:UINotificationFeedbackTypeSuccess];
                    NSString *name=self.functionDefinitions[fid][@"name"] ?: self.functionDefinitions[fid][@"title"] ?: fid;
                    [self showFunctionFeedbackForFunctionId:fid title:(requested?@"FUNCTION ACTIVATED":@"FUNCTION DEACTIVATED") detail:name kind:@"success"];
                }
            } else {
                for(NSString *otherFID in conflicts){ self.functionControls[otherFID].userInteractionEnabled=YES; }
                [self applyFunctionVisualState:fid state:!requested animated:YES];
                for(NSString *otherFID in previousConflictStates){
                    if([previousConflictStates[otherFID] boolValue]) [self applyFunctionVisualState:otherFID state:YES animated:YES];
                }
                if(msg.length){ UINotificationFeedbackGenerator *h=[UINotificationFeedbackGenerator new]; [h notificationOccurred:UINotificationFeedbackTypeError]; [self showToast:msg success:NO]; }
            }
        });
    };

    if([self.delegate respondsToSelector:@selector(zentraxDidRequestFunctionOperation:action:completion:)]) {
        [self.delegate zentraxDidRequestFunctionOperation:fid action:requested completion:finish];
    } else if([self.delegate respondsToSelector:@selector(zentraxDidRequestModuleToggle:state:completion:)]) {
        [self.delegate zentraxDidRequestModuleToggle:fid state:requested completion:finish];
    } else {
        Class mgrCls=NSClassFromString(@"ZentraxNetworkManager");
        if(mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]){
            id manager=((id (*)(id,SEL))objc_msgSend)((id)mgrCls,NSSelectorFromString(@"sharedManager"));
            SEL operSel=NSSelectorFromString(@"performModuleOperationWithFunctionId:action:completion:");
            if([manager respondsToSelector:operSel]){
                void (^networkCompletion)(BOOL,NSDictionary *,NSString *)=^(BOOL succ,NSDictionary *res,NSString *err){ finish(succ,err); };
                ((void (*)(id,SEL,id,NSInteger,id))objc_msgSend)(manager,operSel,fid,requested?2:1,networkCompletion);
            } else finish(NO,ZXLocalizedUI(@"Integration bridge unavailable."));
        } else finish(NO,ZXLocalizedUI(@"Integration bridge unavailable."));
    }
}

- (void)applyFunctionVisualState:(NSString *)fid state:(BOOL)isOn animated:(BOOL)animated {
    if(!fid.length)return;
    if(![NSThread isMainThread]) {
        __weak typeof(self) weakSelf=self;
        dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf applyFunctionVisualState:fid state:isOn animated:animated]; });
        return;
    }
    self.functionStates[fid]=@(isOn);
    UIControl *control=self.functionControls[fid];
    if([control isKindOfClass:[UISwitch class]]) {
        UISwitch *sw=(UISwitch *)control;
        sw.userInteractionEnabled = ![self.functionProcessing[fid] boolValue];
        sw.accessibilityValue = ZXLocalizedUI(isOn ? @"On" : @"Off");
        if(animated) {
            [sw setOn:isOn animated:YES];
        } else {
            [sw setOn:isOn animated:NO];
        }
    }
    UILabel *label=self.functionStateLabels[fid];
    ZXGlassCard *card=(ZXGlassCard *)self.functionCards[fid];
    if(!label || !card)return;
    UIView *pill=label.superview;
    void (^changes)(void)=^{
        label.text=ZXLocalizedUI(isOn?@"ACTIVE":@"READY");
        label.textColor=isOn?[ZXTheme success]:[ZXTheme mutedText];
        pill.backgroundColor=isOn?[[ZXTheme success] colorWithAlphaComponent:0.11]:[[UIColor whiteColor] colorWithAlphaComponent:0.045];
        [card setEmphasized:isOn animated:NO];
        card.highlightLayer.colors=isOn ? @[(id)[UIColor colorWithWhite:1 alpha:0.16].CGColor,(id)[[ZXTheme accentSoft] colorWithAlphaComponent:0.055].CGColor,(id)[UIColor clearColor].CGColor] : @[(id)[UIColor colorWithWhite:1 alpha:0.065].CGColor,(id)[UIColor clearColor].CGColor];
        card.shadeLayer.colors=isOn ? @[(id)[[ZXTheme accentPrimary] colorWithAlphaComponent:0.035].CGColor,(id)[UIColor colorWithWhite:0 alpha:0.10].CGColor] : @[(id)[UIColor clearColor].CGColor,(id)[UIColor colorWithWhite:0 alpha:0.16].CGColor];
        for(UIView *sub in card.blurView.contentView.subviews){
            if([sub isKindOfClass:[UIImageView class]]) ((UIImageView *)sub).tintColor=isOn?[ZXTheme accentSoft]:[ZXTheme mutedText];
        }
    };
    if(animated)[UIView animateWithDuration:ZXMotionDuration(0.25) delay:0 options:UIViewAnimationOptionCurveEaseOut animations:changes completion:nil]; else changes();
}

- (void)forceDisableToggleForFunctionId:(NSString *)functionId {
    if(!functionId.length)return;
    dispatch_async(dispatch_get_main_queue(),^{
        NSUUID *old=self.functionOperationTokens[functionId];
        if(old)[self.functionOperationTokens removeObjectForKey:functionId];
        [self.functionProcessing removeObjectForKey:functionId];
        UIControl *control=self.functionControls[functionId]; control.userInteractionEnabled=YES;
        [self applyFunctionVisualState:functionId state:NO animated:YES];
        NSString *name=self.functionDefinitions[functionId][@"name"] ?: self.functionDefinitions[functionId][@"title"] ?: functionId;
        [self showFunctionFeedbackForFunctionId:functionId title:@"FUNCTION DISABLED" detail:[NSString stringWithFormat:@"%@\n%@",name,ZXLocalizedUI(@"Server configuration changed")] kind:@"server"];
    });
}

- (void)showFunctionFeedbackForFunctionId:(NSString *)fid title:(NSString *)title detail:(NSString *)detail kind:(NSString *)kind {
    if(!self.view.window)return;
    [self.transientFeedbackView removeFromSuperview]; self.transientFeedbackView=nil;
    UIView *v=[[UIView alloc] initWithFrame:CGRectZero]; v.translatesAutoresizingMaskIntoConstraints=NO; v.backgroundColor=[[ZXTheme surface2] colorWithAlphaComponent:0.96]; v.layer.cornerRadius=18; v.layer.cornerCurve=kCACornerCurveContinuous; v.layer.borderWidth=1; UIColor *edge=[kind isEqualToString:@"server"]?[ZXTheme warning]:[ZXTheme accentPrimary]; v.layer.borderColor=[edge colorWithAlphaComponent:0.30].CGColor; v.layer.shadowColor=[UIColor blackColor].CGColor; v.layer.shadowOpacity=0.28; v.layer.shadowRadius=20; v.layer.shadowOffset=CGSizeMake(0,10);
    UIImageView *icon=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:[kind isEqualToString:@"server"]?@"arrow.triangle.2.circlepath":@"checkmark.circle.fill"]]; icon.tintColor=edge; icon.translatesAutoresizingMaskIntoConstraints=NO;
    UILabel *t=ZXLabel(ZXLocalizedUI(title),[ZXTheme heading:12],edge); [ZXTheme track:t spacing:0.8]; t.translatesAutoresizingMaskIntoConstraints=NO;
    UILabel *d=ZXLabel(ZXLocalizedUI(detail),[ZXTheme body:13 weight:UIFontWeightMedium],[ZXTheme primaryText]); d.numberOfLines=2; d.translatesAutoresizingMaskIntoConstraints=NO;
    [v addSubview:icon]; [v addSubview:t]; [v addSubview:d]; [self.view addSubview:v]; self.transientFeedbackView=v;
    UILayoutGuide *safe=self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[[v.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:20], [v.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20], [v.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor], [v.topAnchor constraintEqualToAnchor:safe.topAnchor constant:14], [icon.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:16], [icon.topAnchor constraintEqualToAnchor:v.topAnchor constant:16], [icon.widthAnchor constraintEqualToConstant:20], [icon.heightAnchor constraintEqualToConstant:20], [t.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:10], [t.trailingAnchor constraintEqualToAnchor:v.trailingAnchor constant:-16], [t.topAnchor constraintEqualToAnchor:v.topAnchor constant:14], [d.leadingAnchor constraintEqualToAnchor:t.leadingAnchor], [d.trailingAnchor constraintEqualToAnchor:t.trailingAnchor], [d.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:3], [d.bottomAnchor constraintEqualToAnchor:v.bottomAnchor constant:-15]]];
    v.transform=CGAffineTransformMakeTranslation(0,-12); v.alpha=0;
    [UIView animateWithDuration:ZXMotionDuration(0.42) delay:0 usingSpringWithDamping:0.84 initialSpringVelocity:0.25 options:UIViewAnimationOptionAllowUserInteraction animations:^{v.transform=CGAffineTransformIdentity;v.alpha=1;} completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(2.4*NSEC_PER_SEC)),dispatch_get_main_queue(),^{ if(self.transientFeedbackView==v){ [UIView animateWithDuration:ZXMotionDuration(0.22) animations:^{v.alpha=0;v.transform=CGAffineTransformMakeTranslation(0,-8);} completion:^(BOOL finished){[v removeFromSuperview];if(self.transientFeedbackView==v)self.transientFeedbackView=nil;}]; }});
}

#pragma mark - Subscription / Time

- (void)updateSubscriptionState:(NSDictionary *)subData {
    if (![subData isKindOfClass:[NSDictionary class]]) return;
    NSString *statusRaw = subData[@"status"];
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
    
    self.licenseStatusLabel.text = text;
    self.licenseStatusLabel.textColor = color;
    
    if (isPermanent) {
        self.countdownLabel.text = ZXLocalizedUI(@"LIFETIME");
        [self stopLicenseCountdown];
    } else if (expiresAt) {
        [self startLicenseCountdown];
        [self refreshLicenseCountdown];
    } else if (status == ZXLicenseUIStatusUnactivated) {
        self.countdownLabel.text = ZXLocalizedUI(@"NOT STARTED");
        [self stopLicenseCountdown];
    }
    if (self.settingsVisible) [self rebuildSettings];
    ZXAuditAccessibilityTree(self.dashboardContainer);
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
    if (self.licensePermanent) return;
    if (!self.expiresAt) return;
    NSTimeInterval remaining = [self.expiresAt timeIntervalSinceDate:[self estimatedServerNow]];
    if (remaining <= 0) {
        self.countdownLabel.text = ZXLocalizedUI(@"00:00:00");
        self.licenseStatusLabel.text = ZXLocalizedUI(@"EXPIRED");
        self.licenseStatusLabel.textColor = [ZXTheme error];
        if (self.settingsVisible && self.settingsExpiryLabel) self.settingsExpiryLabel.text = ZXLocalizedUI(@"EXPIRED");
        [self stopLicenseCountdown];
        return;
    }
    NSInteger total = (NSInteger)floor(remaining);
    NSInteger days = total / 86400; total %= 86400;
    NSInteger hours = total / 3600; total %= 3600;
    NSInteger minutes = total / 60; NSInteger seconds = total % 60;
    
    if (days > 0) self.countdownLabel.text = [NSString stringWithFormat:@"%ldd %02ldh %02ldm", (long)days, (long)hours, (long)minutes];
    else self.countdownLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}

#pragma mark - Startup Block & Bootstrap

- (void)styleSecondaryButton:(UIButton *)button {
    if (!button) return;

    button.backgroundColor = [[ZXTheme surfaceRaised] colorWithAlphaComponent:0.92];
    button.layer.cornerRadius = 16.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [ZXTheme border].CGColor;
    button.clipsToBounds = YES;

    button.titleLabel.font = [ZXTheme heading:15.0];
    [button setTitleColor:[ZXTheme primaryText] forState:UIControlStateNormal];

    [button setTitleColor:[ZXTheme secondaryText] forState:UIControlStateHighlighted];
}

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

    ZXGlassCard *card = [[ZXGlassCard alloc] init];
    [_startupBlockContainer addSubview:card];
    
    UIView *iconBg = [[UIView alloc] init];
    iconBg.backgroundColor = [[ZXTheme error] colorWithAlphaComponent:0.15];
    iconBg.layer.cornerRadius = 28;
    iconBg.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:iconBg];
    
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"exclamationmark.shield.fill"]];
    icon.tintColor = [ZXTheme error];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [iconBg addSubview:icon];
    
    _startupBlockTitle = [self label:@"ACCESS DENIED" size:22 weight:UIFontWeightHeavy color:[ZXTheme primaryText]];
    _startupBlockTitle.textAlignment = NSTextAlignmentCenter;
    _startupBlockTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_startupBlockTitle];
    
    _startupBlockMessage = [self label:@"" size:15 weight:UIFontWeightMedium color:[ZXTheme secondaryText]];
    _startupBlockMessage.textAlignment = NSTextAlignmentCenter;
    _startupBlockMessage.numberOfLines = 0;
    _startupBlockMessage.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_startupBlockMessage];
    
    _startupBlockAction = [UIButton buttonWithType:UIButtonTypeSystem];
    [self styleSecondaryButton:_startupBlockAction];
    [_startupBlockAction setTitle:ZXLocalizedUI(@"RETRY CONNECTION") forState:UIControlStateNormal];
    _startupBlockAction.translatesAutoresizingMaskIntoConstraints = NO;
    [_startupBlockAction addTarget:self action:@selector(startupBlockRetry) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:_startupBlockAction];
    
    [NSLayoutConstraint activateConstraints:@[
        [card.leadingAnchor constraintEqualToAnchor:_startupBlockContainer.leadingAnchor constant:32],
        [card.trailingAnchor constraintEqualToAnchor:_startupBlockContainer.trailingAnchor constant:-32],
        [card.centerYAnchor constraintEqualToAnchor:_startupBlockContainer.centerYAnchor],
        
        [iconBg.topAnchor constraintEqualToAnchor:card.topAnchor constant:32],
        [iconBg.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [iconBg.widthAnchor constraintEqualToConstant:56],
        [iconBg.heightAnchor constraintEqualToConstant:56],
        
        [icon.centerXAnchor constraintEqualToAnchor:iconBg.centerXAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:iconBg.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:28],
        [icon.heightAnchor constraintEqualToConstant:28],
        
        [_startupBlockTitle.topAnchor constraintEqualToAnchor:iconBg.bottomAnchor constant:24],
        [_startupBlockTitle.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [_startupBlockTitle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        
        [_startupBlockMessage.topAnchor constraintEqualToAnchor:_startupBlockTitle.bottomAnchor constant:12],
        [_startupBlockMessage.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [_startupBlockMessage.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        
        [_startupBlockAction.topAnchor constraintEqualToAnchor:_startupBlockMessage.bottomAnchor constant:32],
        [_startupBlockAction.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [_startupBlockAction.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        [_startupBlockAction.heightAnchor constraintEqualToConstant:56],
        [_startupBlockAction.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-24]
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

#pragma mark - Heartbeat & Session Revocation

- (void)startHeartbeatMonitor {
    [self stopHeartbeatMonitor];
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(heartbeatTick) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.heartbeatTimer forMode:NSRunLoopCommonModes];
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
                        else if (res[@"license"]) [self updateSubscriptionState:res[@"license"]];
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
        });
    }];
}

- (void)handleRevokedSessionEnvironment {
    [self stopHeartbeatMonitor];
    for (NSString *fid in self.functionControls) ((UIControl *)self.functionControls[fid]).userInteractionEnabled = NO;
    
    __weak typeof(self) weakSelf = self;
    [self showCustomConfirmationWithTitle:ZXLocalizedUI(@"SESSION EXPIRED") 
                                  message:ZXLocalizedUI(@"Your license was deleted, revoked, or transferred. You have been logged out.") 
                             confirmTitle:ZXLocalizedUI(@"OK") 
                               completion:^{
        __strong typeof(weakSelf) self = weakSelf; if (!self) return;
        
        if ([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) {
            [self.delegate zentraxDidRequestLogoutWithCompletion:^{ dispatch_async(dispatch_get_main_queue(), ^{ [self showLoginScreen]; }); }];
        } else {
            Class mgrCls = NSClassFromString(@"ZentraxNetworkManager");
            if (mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
                id manager = ((id (*)(id, SEL))objc_msgSend)((id)mgrCls, NSSelectorFromString(@"sharedManager"));
                SEL outSel = NSSelectorFromString(@"logout");
                if ([manager respondsToSelector:outSel]) ((void (*)(id, SEL))objc_msgSend)(manager, outSel);
            }
            NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
            [globalDefaults removeObjectForKey:ZXLastKey];
            [globalDefaults synchronize];
            [self showLoginScreen];
        }
    }];
}

#pragma mark - Settings (License Details Moved Here)

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
    
    UIButton *back = [self iconButton:@"chevron.left" size:28];
    [back addTarget:self action:@selector(closeSettings) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:back];
    
    UILabel *settingsTitle = [self label:@"Settings" size:24 weight:UIFontWeightHeavy color:[ZXTheme primaryText]];
    settingsTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:settingsTitle];
    
    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:_settingsContainer.leadingAnchor constant:24],
        [header.trailingAnchor constraintEqualToAnchor:_settingsContainer.trailingAnchor constant:-24],
        [header.topAnchor constraintEqualToAnchor:_settingsContainer.safeAreaLayoutGuide.topAnchor constant:12],
        [header.heightAnchor constraintEqualToConstant:44],
        
        [back.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [back.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        
        [settingsTitle.leadingAnchor constraintEqualToAnchor:back.trailingAnchor constant:16],
        [settingsTitle.centerYAnchor constraintEqualToAnchor:header.centerYAnchor]
    ]];

    _settingsScroll = [[UIScrollView alloc] init];
    _settingsScroll.showsVerticalScrollIndicator = NO;
    _settingsScroll.translatesAutoresizingMaskIntoConstraints = NO;
    [_settingsContainer addSubview:_settingsScroll];
    
    _settingsStack = [[UIStackView alloc] init];
    _settingsStack.axis = UILayoutConstraintAxisVertical;
    _settingsStack.spacing = 16;
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

- (UIView *)settingsRow:(NSString *)title subtitle:(NSString *)subtitle icon:(NSString *)iconName color:(UIColor *)color action:(SEL)action accessory:(UIView *)accessory {
    ZXGlassCard *row = [[ZXGlassCard alloc] init];
    
    UIView *iconBg = [[UIView alloc] init];
    iconBg.backgroundColor = [color colorWithAlphaComponent:0.15];
    iconBg.layer.cornerRadius = 10;
    iconBg.translatesAutoresizingMaskIntoConstraints = NO;
    [row addSubview:iconBg];
    
    UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:iconName]];
    iv.tintColor = color;
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.translatesAutoresizingMaskIntoConstraints = NO;
    [iconBg addSubview:iv];
    
    UILabel *t = [self label:title size:16 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    t.translatesAutoresizingMaskIntoConstraints = NO;
    [row addSubview:t];
    
    UILabel *s = [self label:subtitle size:14 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    s.numberOfLines = 0;
    s.translatesAutoresizingMaskIntoConstraints = NO;
    // Stable identity for dynamic settings rows; avoids fragile UIFont/object comparisons.
    s.tag = 2401;
    [row addSubview:s];
    
    [NSLayoutConstraint activateConstraints:@[
        [row.heightAnchor constraintGreaterThanOrEqualToConstant:92],
        
        [iconBg.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:20],
        [iconBg.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [iconBg.widthAnchor constraintEqualToConstant:48],
        [iconBg.heightAnchor constraintEqualToConstant:48],
        
        [iv.centerXAnchor constraintEqualToAnchor:iconBg.centerXAnchor],
        [iv.centerYAnchor constraintEqualToAnchor:iconBg.centerYAnchor],
        [iv.widthAnchor constraintEqualToConstant:24],
        [iv.heightAnchor constraintEqualToConstant:24],
        
        [t.leadingAnchor constraintEqualToAnchor:iconBg.trailingAnchor constant:16],
        [t.topAnchor constraintEqualToAnchor:row.topAnchor constant:20],
        [t.trailingAnchor constraintLessThanOrEqualToAnchor:row.trailingAnchor constant:-65],
        
        [s.leadingAnchor constraintEqualToAnchor:t.leadingAnchor],
        [s.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:6],
        [s.trailingAnchor constraintLessThanOrEqualToAnchor:row.trailingAnchor constant:-65],
        [s.bottomAnchor constraintLessThanOrEqualToAnchor:row.bottomAnchor constant:-20]
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
            [chev.widthAnchor constraintEqualToConstant:12],
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
    
    // License Info Segment
    UILabel *licLabel = [self label:@"LICENSE INFO" size:12 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:licLabel spacing:2.0];
    [self.settingsStack addArrangedSubview:licLabel];
    licLabel.translatesAutoresizingMaskIntoConstraints=NO;

    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *currentKey = [d stringForKey:ZXLastKey];

    ZXGlassCard *keyCard=[ZXGlassCard new];
    keyCard.translatesAutoresizingMaskIntoConstraints=NO;
    keyCard.userInteractionEnabled=YES;
    keyCard.blurView.userInteractionEnabled=YES;
    keyCard.blurView.contentView.userInteractionEnabled=YES;
    UIView *keyIconBg=[UIView new]; keyIconBg.translatesAutoresizingMaskIntoConstraints=NO; keyIconBg.backgroundColor=[[ZXTheme accentPrimary] colorWithAlphaComponent:0.15]; keyIconBg.layer.cornerRadius=10; [keyCard addSubview:keyIconBg];
    UIImageView *keyIcon=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"key.fill"]]; keyIcon.translatesAutoresizingMaskIntoConstraints=NO; keyIcon.tintColor=[ZXTheme accentSoft]; [keyIconBg addSubview:keyIcon];
    UILabel *keyTitle=[self label:ZXLocalizedUI(@"License Key") size:16 weight:UIFontWeightSemibold color:[ZXTheme primaryText]]; keyTitle.translatesAutoresizingMaskIntoConstraints=NO; [keyCard addSubview:keyTitle];
    UILabel *keySub=[self label:self.settingsKeyRevealed && currentKey.length ? currentKey : @"•••• •••• ••••" size:14 weight:UIFontWeightMedium color:self.settingsKeyRevealed?[UIColor whiteColor]:[ZXTheme secondaryText]]; keySub.translatesAutoresizingMaskIntoConstraints=NO; keySub.font=[ZXTheme mono:14 weight:UIFontWeightMedium]; keySub.adjustsFontSizeToFitWidth=YES; keySub.minimumScaleFactor=0.58; keySub.numberOfLines=1; self.settingsKeyLabel=keySub; [keyCard addSubview:keySub];
    UIButton *eye=[UIButton buttonWithType:UIButtonTypeSystem];
    eye.translatesAutoresizingMaskIntoConstraints=NO;
    eye.accessibilityLabel=ZXLocalizedUI(@"License Key");
    eye.accessibilityHint=ZXLocalizedUI(@"Show or hide the saved license key.");
    eye.accessibilityTraits=UIAccessibilityTraitButton;
    eye.tintColor=[ZXTheme mutedText];
    eye.contentHorizontalAlignment=UIControlContentHorizontalAlignmentCenter;
    eye.contentVerticalAlignment=UIControlContentVerticalAlignmentCenter;
    eye.adjustsImageWhenHighlighted=NO;
    eye.layer.anchorPoint=CGPointMake(0.5, 0.5);
    eye.imageView.contentMode=UIViewContentModeScaleAspectFit;
    [eye setImage:[UIImage systemImageNamed:self.settingsKeyRevealed?@"eye.fill":@"eye.slash.fill"] forState:UIControlStateNormal];
    [eye addTarget:self action:@selector(toggleSettingsKey:) forControlEvents:UIControlEventTouchUpInside];
    self.settingsKeyEyeButton=eye;
    [keyCard addSubview:eye];
    [NSLayoutConstraint activateConstraints:@[
        [keyCard.heightAnchor constraintGreaterThanOrEqualToConstant:96],
        [keyIconBg.leadingAnchor constraintEqualToAnchor:keyCard.blurView.contentView.leadingAnchor constant:20], [keyIconBg.centerYAnchor constraintEqualToAnchor:keyCard.blurView.contentView.centerYAnchor], [keyIconBg.widthAnchor constraintEqualToConstant:48], [keyIconBg.heightAnchor constraintEqualToConstant:48],
        [keyIcon.centerXAnchor constraintEqualToAnchor:keyIconBg.centerXAnchor], [keyIcon.centerYAnchor constraintEqualToAnchor:keyIconBg.centerYAnchor], [keyIcon.widthAnchor constraintEqualToConstant:24], [keyIcon.heightAnchor constraintEqualToConstant:24],
        [keyTitle.leadingAnchor constraintEqualToAnchor:keyIconBg.trailingAnchor constant:16], [keyTitle.topAnchor constraintEqualToAnchor:keyCard.blurView.contentView.topAnchor constant:20], [keyTitle.trailingAnchor constraintLessThanOrEqualToAnchor:eye.leadingAnchor constant:-10],
        [keySub.leadingAnchor constraintEqualToAnchor:keyTitle.leadingAnchor], [keySub.topAnchor constraintEqualToAnchor:keyTitle.bottomAnchor constant:6], [keySub.trailingAnchor constraintEqualToAnchor:eye.leadingAnchor constant:-10], [keySub.bottomAnchor constraintLessThanOrEqualToAnchor:keyCard.blurView.contentView.bottomAnchor constant:-20],
        [eye.trailingAnchor constraintEqualToAnchor:keyCard.blurView.contentView.trailingAnchor constant:-12], [eye.centerYAnchor constraintEqualToAnchor:keyCard.blurView.contentView.centerYAnchor], [eye.widthAnchor constraintEqualToConstant:48], [eye.heightAnchor constraintEqualToConstant:48]
    ]];
    [self.settingsStack addArrangedSubview:keyCard];

    NSString *expiryStr = @"";
    if (self.licensePermanent) expiryStr = ZXLocalizedUI(@"LIFETIME");
    else if (self.expiresAt) {
        NSDateFormatter *f = [[NSDateFormatter alloc] init];
        f.dateStyle = NSDateFormatterMediumStyle;
        f.timeStyle = NSDateFormatterShortStyle;
        expiryStr = [f stringFromDate:self.expiresAt];
    } else expiryStr = ZXLocalizedUI(@"UNACTIVATED");

    UIView *expRow = [self settingsRow:ZXLocalizedUI(@"Expiry Date") subtitle:expiryStr icon:@"calendar.badge.clock" color:[ZXTheme warning] action:nil accessory:[UIView new]];
    for (UIView *sub in expRow.subviews) {
        if ([sub isKindOfClass:[UILabel class]] && sub.tag == 2401) {
            self.settingsExpiryLabel = (UILabel *)sub;
            self.settingsExpiryLabel.font = [ZXTheme mono:14 weight:UIFontWeightMedium];
        }
    }
    [self.settingsStack addArrangedSubview:expRow];

    // Preferences
    UILabel *prefLabel = [self label:@"PREFERENCES" size:12 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:prefLabel spacing:2.0];
    [self.settingsStack addArrangedSubview:prefLabel];
    prefLabel.translatesAutoresizingMaskIntoConstraints=NO;
    
    NSString *language = [d stringForKey:ZXLanguageKey] ?: @"English";
    [self.settingsStack addArrangedSubview:[self settingsRow:ZXLocalizedUI(@"Language") subtitle:language icon:@"globe" color:[ZXTheme accentSecondary] action:@selector(showLanguagePicker) accessory:nil]];

    UILabel *supportLabel = [self label:@"COMMUNITY" size:12 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:supportLabel spacing:2.0];
    [self.settingsStack addArrangedSubview:supportLabel];
    supportLabel.translatesAutoresizingMaskIntoConstraints=NO;

    UIView *telegramRow = [self settingsRow:ZXLocalizedUI(@"ZENTRAX Community")
                                    subtitle:[NSString stringWithFormat:@"%@\n%@", ZXLocalizedUI(@"Support the free release • Join the official Telegram channel"), ZXTelegramChannelURL]
                                        icon:@"paperplane.fill"
                                       color:[ZXTheme accentPrimary]
                                      action:@selector(showTelegramChannelFromSettings)
                                   accessory:nil];
    telegramRow.accessibilityLabel = ZXLocalizedUI(@"ZENTRAX Community");
    telegramRow.accessibilityHint = ZXLocalizedUI(@"Open the official Telegram channel and remember this choice.");
    telegramRow.isAccessibilityElement = YES;
    [self.settingsStack addArrangedSubview:telegramRow];

    UILabel *linkHint = [self label:ZXLocalizedUI(@"Official channel • link is built into the app") size:11 weight:UIFontWeightMedium color:[ZXTheme mutedText]];
    linkHint.numberOfLines = 0;
    linkHint.textAlignment = NSTextAlignmentLeft;
    linkHint.translatesAutoresizingMaskIntoConstraints = NO;
    [self.settingsStack addArrangedSubview:linkHint];

    UILabel *appLabel = [self label:@"APPLICATION" size:12 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:appLabel spacing:2.0];
    [self.settingsStack addArrangedSubview:appLabel];
    appLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *exitRow = [self settingsRow:@"Exit ZENTRAX UI"
                                subtitle:@"Return to Spotify"
                                    icon:@"arrow.uturn.backward.circle.fill"
                                   color:[ZXTheme accentSoft]
                                  action:@selector(exitZentraxUI)
                               accessory:nil];
    exitRow.accessibilityLabel = @"Exit ZENTRAX UI";
    exitRow.accessibilityHint = @"Return to Spotify.";
    exitRow.isAccessibilityElement = YES;
    [self.settingsStack addArrangedSubview:exitRow];

    UILabel *accLabel = [self label:@"SESSION" size:12 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:accLabel spacing:2.0];
    [self.settingsStack addArrangedSubview:accLabel];
    accLabel.translatesAutoresizingMaskIntoConstraints=NO;
    [self.settingsStack addArrangedSubview:[self settingsRow:ZXLocalizedUI(@"Sign Out") subtitle:ZXLocalizedUI(@"Close the current secure session.") icon:@"rectangle.portrait.and.arrow.right" color:[ZXTheme error] action:@selector(handleLogout) accessory:nil]];
    ZXAuditAccessibilityTree(self.settingsContainer);
}

- (void)toggleSettingsKey:(UIButton *)sender {
    NSUserDefaults *d=[[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *key=[d stringForKey:ZXLastKey];
    if(!key.length){
        self.settingsKeyRevealed=NO;
        [self showToast:ZXLocalizedUI(@"No saved license key is available.") success:NO];
        return;
    }

    self.settingsKeyRevealed=!self.settingsKeyRevealed;

    // Update the existing controls in-place. Do NOT rebuild the settings stack:
    // rebuilding caused the eye control/card to be recreated and visually jump.
    if(self.settingsKeyLabel){
        self.settingsKeyLabel.text=self.settingsKeyRevealed ? key : @"•••• •••• ••••";
        self.settingsKeyLabel.textColor=self.settingsKeyRevealed ? [ZXTheme primaryText] : [ZXTheme secondaryText];
    }
    UIButton *eye=self.settingsKeyEyeButton ?: sender;
    UIImage *image=[UIImage systemImageNamed:self.settingsKeyRevealed ? @"eye.fill" : @"eye.slash.fill"];
    [UIView performWithoutAnimation:^{
        [eye setImage:image forState:UIControlStateNormal];
        eye.tintColor=[ZXTheme mutedText];
        eye.transform=CGAffineTransformIdentity;
    }];
    eye.accessibilityValue=self.settingsKeyRevealed ? ZXLocalizedUI(@"Visible") : ZXLocalizedUI(@"Hidden");
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.settingsKeyLabel);
}


#pragma mark - ZENTRAX Community / Telegram Support

- (void)scheduleTelegramSupportPrompt {
    if (self.telegramPromptPresentedThisSession) return;
    // Launch-scoped reminder: show once per fresh app session. The previous
    // implementation permanently suppressed the prompt after a saved choice.
    dispatch_async(dispatch_get_main_queue(), ^{
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.18 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self || self.telegramPromptPresentedThisSession) return;
            [self presentTelegramSupportPromptIfNeeded];
        });
    });
}

- (void)presentTelegramSupportPromptIfNeeded {
    if (self.telegramSupportPromptView.superview || self.telegramPromptPresentedThisSession) return;
    if (!self.view.window) return;

    self.telegramPromptPresentedThisSession = YES;

    UIView *backdrop = [[UIView alloc] initWithFrame:CGRectZero];
    backdrop.translatesAutoresizingMaskIntoConstraints = NO;
    backdrop.backgroundColor = [UIColor colorWithWhite:0 alpha:0.48];
    backdrop.alpha = 0;
    self.telegramSupportPromptView = backdrop;

    UIControl *outside = [UIControl new];
    outside.translatesAutoresizingMaskIntoConstraints = NO;
    [backdrop addSubview:outside];

    ZXGlassCard *card = [[ZXGlassCard alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [backdrop addSubview:card];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"paperplane.circle.fill"]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.tintColor = [ZXTheme accentSoft];
    icon.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *eyebrow = [self label:ZXLocalizedUI(@"A LITTLE SUPPORT GOES A LONG WAY") size:10 weight:UIFontWeightBold color:[ZXTheme accentSoft]];
    [ZXTheme track:eyebrow spacing:1.0];
    eyebrow.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *title = [self label:ZXLocalizedUI(@"Help Keep ZENTRAX Free.") size:25 weight:UIFontWeightHeavy color:[ZXTheme primaryText]];
    title.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *message = [self label:ZXLocalizedUI(@"ZENTRAX is shared with the community at no cost. If it helps you, joining the official channel is a small way to support the work and stay close to future free releases.") size:14 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    message.numberOfLines = 0;
    message.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *promise = [[UIView alloc] initWithFrame:CGRectZero];
    promise.translatesAutoresizingMaskIntoConstraints = NO;
    promise.backgroundColor = [[ZXTheme accentPrimary] colorWithAlphaComponent:0.075];
    promise.layer.cornerRadius = 12;
    promise.layer.cornerCurve = kCACornerCurveContinuous;
    promise.layer.borderWidth = 1;
    promise.layer.borderColor = [[ZXTheme accentPrimary] colorWithAlphaComponent:0.13].CGColor;

    UIImageView *heart = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"heart.fill"]];
    heart.translatesAutoresizingMaskIntoConstraints = NO;
    heart.tintColor = [ZXTheme accentSoft];
    UILabel *promiseText = [self label:ZXLocalizedUI(@"Free access • community supported") size:12 weight:UIFontWeightSemibold color:[ZXTheme secondaryText]];
    promiseText.translatesAutoresizingMaskIntoConstraints = NO;
    [promise addSubview:heart];
    [promise addSubview:promiseText];

    ZXPremiumButton *join = [ZXPremiumButton new];
    join.translatesAutoresizingMaskIntoConstraints = NO;
    [join setTitle:ZXLocalizedUI(@"JOIN THE ZENTRAX COMMUNITY") forState:UIControlStateNormal];
    join.accessibilityLabel = ZXLocalizedUI(@"Join the ZENTRAX Community");
    join.accessibilityHint = ZXLocalizedUI(@"Open the official Telegram channel and remember this choice.");
    [join addTarget:self action:@selector(openZentraxTelegramChannel) forControlEvents:UIControlEventTouchUpInside];

    UIButton *later = [UIButton buttonWithType:UIButtonTypeSystem];
    later.translatesAutoresizingMaskIntoConstraints = NO;
    [later setTitle:ZXLocalizedUI(@"Not already done") forState:UIControlStateNormal];
    later.titleLabel.font = [ZXTheme body:12 weight:UIFontWeightMedium];
    [later setTitleColor:[ZXTheme mutedText] forState:UIControlStateNormal];
    later.accessibilityLabel = ZXLocalizedUI(@"Not already done");
    later.accessibilityHint = ZXLocalizedUI(@"Dismiss this reminder for now. It will appear again the next time the app starts until the channel is joined.");
    [later addTarget:self action:@selector(dismissTelegramSupportPrompt:) forControlEvents:UIControlEventTouchUpInside];

    [card addSubview:icon];
    [card addSubview:eyebrow];
    [card addSubview:title];
    [card addSubview:message];
    [card addSubview:promise];
    [card addSubview:join];
    [card addSubview:later];
    [self.view addSubview:backdrop];

    [NSLayoutConstraint activateConstraints:@[
        [backdrop.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [backdrop.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [backdrop.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [backdrop.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [outside.leadingAnchor constraintEqualToAnchor:backdrop.leadingAnchor],
        [outside.trailingAnchor constraintEqualToAnchor:backdrop.trailingAnchor],
        [outside.topAnchor constraintEqualToAnchor:backdrop.topAnchor],
        [outside.bottomAnchor constraintEqualToAnchor:backdrop.bottomAnchor],
        [card.leadingAnchor constraintGreaterThanOrEqualToAnchor:backdrop.leadingAnchor constant:24],
        [card.trailingAnchor constraintLessThanOrEqualToAnchor:backdrop.trailingAnchor constant:-24],
        [card.centerXAnchor constraintEqualToAnchor:backdrop.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:backdrop.centerYAnchor],
        [card.widthAnchor constraintLessThanOrEqualToConstant:390],
        [icon.topAnchor constraintEqualToAnchor:card.topAnchor constant:26],
        [icon.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [icon.widthAnchor constraintEqualToConstant:42],
        [icon.heightAnchor constraintEqualToConstant:42],
        [eyebrow.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:18],
        [eyebrow.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:26],
        [eyebrow.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-26],
        [title.topAnchor constraintEqualToAnchor:eyebrow.bottomAnchor constant:7],
        [title.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:26],
        [title.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-26],
        [message.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:10],
        [message.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:26],
        [message.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-26],
        [promise.topAnchor constraintEqualToAnchor:message.bottomAnchor constant:18],
        [promise.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:26],
        [promise.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-26],
        [promise.heightAnchor constraintEqualToConstant:42],
        [heart.leadingAnchor constraintEqualToAnchor:promise.leadingAnchor constant:13],
        [heart.centerYAnchor constraintEqualToAnchor:promise.centerYAnchor],
        [heart.widthAnchor constraintEqualToConstant:16],
        [heart.heightAnchor constraintEqualToConstant:16],
        [promiseText.leadingAnchor constraintEqualToAnchor:heart.trailingAnchor constant:9],
        [promiseText.centerYAnchor constraintEqualToAnchor:promise.centerYAnchor],
        [promiseText.trailingAnchor constraintLessThanOrEqualToAnchor:promise.trailingAnchor constant:-12],
        [join.topAnchor constraintEqualToAnchor:promise.bottomAnchor constant:18],
        [join.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:26],
        [join.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-26],
        [join.heightAnchor constraintEqualToConstant:54],
        [later.topAnchor constraintEqualToAnchor:join.bottomAnchor constant:7],
        [later.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [later.heightAnchor constraintEqualToConstant:34],
        [later.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18]
    ]];

    [outside addTarget:self action:@selector(dismissTelegramPromptFromBackdrop:) forControlEvents:UIControlEventTouchUpInside];

    card.transform = CGAffineTransformMakeScale(0.965, 0.965);
    [UIView animateWithDuration:ZXMotionDuration(0.24) delay:0 usingSpringWithDamping:0.86 initialSpringVelocity:0.25 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        backdrop.alpha = 1;
        card.transform = CGAffineTransformIdentity;
    } completion:nil];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, title);
}

- (void)dismissTelegramPromptFromBackdrop:(UIControl *)sender {
    [self dismissTelegramSupportPrompt:NO];
}

- (void)dismissTelegramSupportPrompt:(BOOL)markJoined {
    UIView *view = self.telegramSupportPromptView;
    if (!view) return;
    if (markJoined) {
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
        [defaults setBool:YES forKey:ZXTelegramJoinedKey];
        [defaults synchronize];
    }
    [UIView animateWithDuration:ZXMotionDuration(0.20) animations:^{
        view.alpha = 0;
        view.transform = CGAffineTransformMakeScale(0.985, 0.985);
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
        if (self.telegramSupportPromptView == view) self.telegramSupportPromptView = nil;
    }];
}

- (void)openZentraxTelegramChannel {
    NSURL *url = [NSURL URLWithString:ZXTelegramChannelURL];
    if (!url) return;
    UIApplication *application = UIApplication.sharedApplication;
    if (![application canOpenURL:url]) {
        [self showToast:ZXLocalizedUI(@"Unable to open the official channel.") success:NO];
        return;
    }
    // The action means the user chose to support the free release; we do not
    // claim that Telegram verified membership. We simply remember the user's choice.
    [application openURL:url options:@{} completionHandler:nil];
    [self dismissTelegramSupportPrompt:YES];
}

- (void)showTelegramChannelFromSettings {
    NSURL *url = [NSURL URLWithString:ZXTelegramChannelURL];
    if (!url) return;
    if (![UIApplication.sharedApplication canOpenURL:url]) {
        [self showToast:ZXLocalizedUI(@"Unable to open the official channel.") success:NO];
        return;
    }
    [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
}

- (void)showSettings {
    self.settingsVisible = YES;
    [self setupSettingsScreen];
    [self transitionToPrimaryContainer:self.settingsContainer];
}
- (void)closeSettings { self.settingsVisible = NO; [self showDashboard]; }

#pragma mark - Safe UI Mode

- (void)applyInitialSafeModeState {
    self.safeModeLocked=NO;
    [self hidePrivacyOverlay];
}

- (void)updateSafeModeState:(ZXSafeModeState)state {
    self.safeModeLocked=(state != ZXSafeModeStateOff);
    if(self.safeModeLocked) [self showSafeModeLockScreen]; else [self showDashboard];
}

- (void)showSafeModeLockScreen {
    dispatch_async(dispatch_get_main_queue(),^{
        [self setAllPrimaryContainersHidden:YES];
        if(!self.safeModeOverlay){
            UIView *v=[[UIView alloc] initWithFrame:CGRectZero]; v.translatesAutoresizingMaskIntoConstraints=NO; v.backgroundColor=[[ZXTheme obsidian] colorWithAlphaComponent:0.98];
            UIImageView *icon=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.shield.fill"]]; icon.tintColor=[ZXTheme accentSoft]; icon.translatesAutoresizingMaskIntoConstraints=NO;
            UILabel *title=ZXLabel(ZXLocalizedUI(@"SAFE MODE"),[ZXTheme display:28],[ZXTheme primaryText]); title.translatesAutoresizingMaskIntoConstraints=NO;
            UILabel *msg=ZXLabel(ZXLocalizedUI(@"ZENTRAX is running in a protected state."),[ZXTheme body:15 weight:UIFontWeightRegular],[ZXTheme secondaryText]); msg.numberOfLines=0; msg.textAlignment=NSTextAlignmentCenter; msg.translatesAutoresizingMaskIntoConstraints=NO;
            [v addSubview:icon];[v addSubview:title];[v addSubview:msg];[self.view addSubview:v]; self.safeModeOverlay=v;
            UILayoutGuide *safe=self.view.safeAreaLayoutGuide;
            [NSLayoutConstraint activateConstraints:@[[v.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],[v.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],[v.topAnchor constraintEqualToAnchor:self.view.topAnchor],[v.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],[icon.centerXAnchor constraintEqualToAnchor:v.centerXAnchor],[icon.topAnchor constraintEqualToAnchor:safe.topAnchor constant:120],[icon.widthAnchor constraintEqualToConstant:52],[icon.heightAnchor constraintEqualToConstant:52],[title.centerXAnchor constraintEqualToAnchor:v.centerXAnchor],[title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:24],[msg.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:40],[msg.trailingAnchor constraintEqualToAnchor:v.trailingAnchor constant:-40],[msg.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:10]]];
        }
        self.safeModeOverlay.hidden=NO;
    });
}

- (void)updatePrivacyCaptureState { if(self.privacyCaptureProtected) [self showPrivacyOverlay]; else [self hidePrivacyOverlay]; }
- (void)showPrivacyOverlay {
    dispatch_async(dispatch_get_main_queue(),^{
        if(!self.privacyOverlay){ UIView *v=[[UIView alloc] initWithFrame:CGRectZero]; v.translatesAutoresizingMaskIntoConstraints=NO; v.backgroundColor=[ZXTheme obsidian]; UILabel *l=ZXLabel(ZXLocalizedUI(@"PRIVATE VIEW"),[ZXTheme heading:14],[ZXTheme secondaryText]); l.translatesAutoresizingMaskIntoConstraints=NO; [v addSubview:l]; [self.view addSubview:v]; self.privacyOverlay=v; [NSLayoutConstraint activateConstraints:@[[v.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],[v.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],[v.topAnchor constraintEqualToAnchor:self.view.topAnchor],[v.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],[l.centerXAnchor constraintEqualToAnchor:v.centerXAnchor],[l.centerYAnchor constraintEqualToAnchor:v.centerYAnchor]]]; } self.privacyOverlay.hidden=NO; });
}
- (void)hidePrivacyOverlay { dispatch_async(dispatch_get_main_queue(),^{ self.privacyOverlay.hidden=YES; }); }

#pragma mark - Language Picker & Rechecks

- (void)showLanguagePicker {
    NSArray *langs=@[@"English",@"Tiếng Việt",@"简体中文",@"日本語"];
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:ZXLocalizedUI(@"Language") message:ZXLocalizedUI(@"Choose your language") preferredStyle:UIAlertControllerStyleActionSheet];
    for(NSString *lang in langs){
        [alert addAction:[UIAlertAction actionWithTitle:lang style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            NSDictionary *oldConfig=self.dashboardConfiguration;
            NSDictionary *oldStates=[self.functionStates copy];
            BOOL dashboard=(self.currentState==ZXAppStateDashboard);
            NSUserDefaults *d=[[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
            [d setObject:lang forKey:ZXLanguageKey];
            [d synchronize];
            [self rebuildAllContainers];
            if(oldConfig.count){ [self updateDashboardWithConfiguration:oldConfig]; [self updateFunctionStates:oldStates]; }
            if(dashboard) [self showDashboard]; else [self showSettings];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:ZXLocalizedUI(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
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
    
    ZXGlassCard *card = [[ZXGlassCard alloc] init];
    card.blurView.layer.borderColor = [[ZXTheme accentPrimary] colorWithAlphaComponent:0.5].CGColor;
    card.layer.shadowColor = [ZXTheme accentPrimary].CGColor;
    card.layer.shadowOpacity = 0.3;
    card.layer.shadowRadius = 24;
    [((UIVisualEffectView *)_globalLoadingOverlay).contentView addSubview:card];
    
    _globalSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _globalSpinner.color = [ZXTheme accentPrimary];
    _globalSpinner.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_globalSpinner];
    
    _globalLoadingTitle = [self label:@"SECURE OPERATION" size:16 weight:UIFontWeightHeavy color:[UIColor whiteColor]];
    _globalLoadingTitle.textAlignment = NSTextAlignmentCenter;
    _globalLoadingTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_globalLoadingTitle];
    
    _globalLoadingDetail = [self label:@"Please wait…" size:14 weight:UIFontWeightMedium color:[ZXTheme secondaryText]];
    _globalLoadingDetail.textAlignment = NSTextAlignmentCenter;
    _globalLoadingDetail.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_globalLoadingDetail];
    
    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:_globalLoadingOverlay.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:_globalLoadingOverlay.centerYAnchor],
        [card.widthAnchor constraintEqualToConstant:290],
        [card.heightAnchor constraintEqualToConstant:170],
        
        [_globalSpinner.topAnchor constraintEqualToAnchor:card.topAnchor constant:36],
        [_globalSpinner.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        
        [_globalLoadingTitle.topAnchor constraintEqualToAnchor:_globalSpinner.bottomAnchor constant:24],
        [_globalLoadingTitle.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [_globalLoadingTitle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        
        [_globalLoadingDetail.topAnchor constraintEqualToAnchor:_globalLoadingTitle.bottomAnchor constant:8],
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
        [UIView animateWithDuration:ZXMotionDuration(0.3) animations:^{ self.globalLoadingOverlay.alpha = 1; }];
    });
}
- (void)updateGlobalLoadingMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{ self.globalLoadingDetail.text = ZXLocalizedUI(message ?: @"Please wait…"); });
}
- (void)hideGlobalLoadingState {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.globalSpinner stopAnimating];
        [UIView animateWithDuration:ZXMotionDuration(0.3) animations:^{ self.globalLoadingOverlay.alpha = 0; } completion:^(BOOL finished){ self.globalLoadingOverlay.hidden = YES; }];
    });
}

- (void)showToast:(NSString *)message success:(BOOL)success {
    if(!message.length || !self.view.window)return;
    dispatch_async(dispatch_get_main_queue(),^{
        [self.transientFeedbackView removeFromSuperview]; self.transientFeedbackView=nil;
        UIView *v=[[UIView alloc] initWithFrame:CGRectZero]; v.translatesAutoresizingMaskIntoConstraints=NO; v.backgroundColor=[[ZXTheme surface2] colorWithAlphaComponent:0.97]; v.layer.cornerRadius=16; v.layer.cornerCurve=kCACornerCurveContinuous; v.layer.borderWidth=1; UIColor *c=success?[ZXTheme success]:[ZXTheme error]; v.layer.borderColor=[c colorWithAlphaComponent:0.28].CGColor; v.layer.shadowColor=[UIColor blackColor].CGColor; v.layer.shadowOpacity=0.25; v.layer.shadowRadius=18; v.layer.shadowOffset=CGSizeMake(0,8);
        UIImageView *i=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:success?@"checkmark.circle.fill":@"exclamationmark.circle.fill"]]; i.tintColor=c; i.translatesAutoresizingMaskIntoConstraints=NO;
        UILabel *l=ZXLabel(ZXLocalizedUI(message),[ZXTheme body:13 weight:UIFontWeightSemibold],[ZXTheme primaryText]); l.numberOfLines=2; l.translatesAutoresizingMaskIntoConstraints=NO;
        [v addSubview:i];[v addSubview:l];[self.view addSubview:v]; self.transientFeedbackView=v;
        UILayoutGuide *safe=self.view.safeAreaLayoutGuide;
        [NSLayoutConstraint activateConstraints:@[[v.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:20],[v.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20],[v.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],[v.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-20],[i.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:15],[i.centerYAnchor constraintEqualToAnchor:v.centerYAnchor],[i.widthAnchor constraintEqualToConstant:20],[i.heightAnchor constraintEqualToConstant:20],[l.leadingAnchor constraintEqualToAnchor:i.trailingAnchor constant:9],[l.trailingAnchor constraintEqualToAnchor:v.trailingAnchor constant:-15],[l.topAnchor constraintEqualToAnchor:v.topAnchor constant:13],[l.bottomAnchor constraintEqualToAnchor:v.bottomAnchor constant:-13]]];
        v.transform=CGAffineTransformMakeTranslation(0,12);v.alpha=0;
        [UIView animateWithDuration:ZXMotionDuration(0.24) delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0.2 options:UIViewAnimationOptionAllowUserInteraction animations:^{v.transform=CGAffineTransformIdentity;v.alpha=1;} completion:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(2.5*NSEC_PER_SEC)),dispatch_get_main_queue(),^{if(self.transientFeedbackView==v){[UIView animateWithDuration:ZXMotionDuration(0.2) animations:^{v.alpha=0;v.transform=CGAffineTransformMakeTranslation(0,8);} completion:^(BOOL done){[v removeFromSuperview];if(self.transientFeedbackView==v)self.transientFeedbackView=nil;}];}});
    });
}

- (void)showCustomConfirmationWithTitle:(NSString *)title message:(NSString *)message confirmTitle:(NSString *)confirmTitle completion:(void (^)(void))completion {
    dispatch_async(dispatch_get_main_queue(),^{
        UIView *backdrop=[[UIView alloc] initWithFrame:CGRectZero]; backdrop.translatesAutoresizingMaskIntoConstraints=NO; backdrop.backgroundColor=[UIColor colorWithWhite:0 alpha:0.54]; backdrop.alpha=0;
        UIControl *dismiss=[UIControl new]; dismiss.translatesAutoresizingMaskIntoConstraints=NO; [backdrop addSubview:dismiss];
        ZXGlassCard *card=[[ZXGlassCard alloc] init]; card.translatesAutoresizingMaskIntoConstraints=NO; [backdrop addSubview:card];
        UIImageView *icon=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"shield.lefthalf.filled"]]; icon.tintColor=[ZXTheme accentSoft]; icon.translatesAutoresizingMaskIntoConstraints=NO;
        UILabel *t=ZXLabel(ZXLocalizedUI(title),[ZXTheme heading:19],[ZXTheme primaryText]); t.translatesAutoresizingMaskIntoConstraints=NO;
        UILabel *m=ZXLabel(ZXLocalizedUI(message),[ZXTheme body:14 weight:UIFontWeightRegular],[ZXTheme secondaryText]); m.numberOfLines=0; m.translatesAutoresizingMaskIntoConstraints=NO;
        ZXPremiumButton *ok=[ZXPremiumButton new]; [ok setTitle:ZXLocalizedUI(confirmTitle ?: @"CONTINUE") forState:UIControlStateNormal]; ok.translatesAutoresizingMaskIntoConstraints=NO;
        UIButton *cancel=[UIButton buttonWithType:UIButtonTypeSystem]; [cancel setTitle:ZXLocalizedUI(@"Cancel") forState:UIControlStateNormal]; cancel.titleLabel.font=[ZXTheme body:14 weight:UIFontWeightSemibold]; [cancel setTitleColor:[ZXTheme secondaryText] forState:UIControlStateNormal]; cancel.translatesAutoresizingMaskIntoConstraints=NO;
        [card addSubview:icon];[card addSubview:t];[card addSubview:m];[card addSubview:ok];[card addSubview:cancel];
        [self.view addSubview:backdrop];
        [NSLayoutConstraint activateConstraints:@[[backdrop.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],[backdrop.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],[backdrop.topAnchor constraintEqualToAnchor:self.view.topAnchor],[backdrop.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],[dismiss.leadingAnchor constraintEqualToAnchor:backdrop.leadingAnchor],[dismiss.trailingAnchor constraintEqualToAnchor:backdrop.trailingAnchor],[dismiss.topAnchor constraintEqualToAnchor:backdrop.topAnchor],[dismiss.bottomAnchor constraintEqualToAnchor:backdrop.bottomAnchor],[card.leadingAnchor constraintGreaterThanOrEqualToAnchor:backdrop.leadingAnchor constant:28],[card.trailingAnchor constraintLessThanOrEqualToAnchor:backdrop.trailingAnchor constant:-28],[card.centerXAnchor constraintEqualToAnchor:backdrop.centerXAnchor],[card.centerYAnchor constraintEqualToAnchor:backdrop.centerYAnchor],[card.widthAnchor constraintLessThanOrEqualToConstant:390],[icon.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22],[icon.topAnchor constraintEqualToAnchor:card.topAnchor constant:22],[icon.widthAnchor constraintEqualToConstant:22],[icon.heightAnchor constraintEqualToConstant:22],[t.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:10],[t.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-22],[t.centerYAnchor constraintEqualToAnchor:icon.centerYAnchor],[m.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22],[m.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-22],[m.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:16],[ok.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22],[ok.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-22],[ok.topAnchor constraintEqualToAnchor:m.bottomAnchor constant:22],[ok.heightAnchor constraintEqualToConstant:52],[cancel.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],[cancel.topAnchor constraintEqualToAnchor:ok.bottomAnchor constant:8],[cancel.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18],[cancel.heightAnchor constraintEqualToConstant:34]]];
        __weak UIView *weakBackdrop=backdrop; [dismiss addTarget:self action:@selector(zx_dismissConfirmation:) forControlEvents:UIControlEventTouchUpInside]; objc_setAssociatedObject(dismiss,@selector(zx_dismissConfirmation:),backdrop,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [cancel addTarget:self action:@selector(zx_dismissConfirmation:) forControlEvents:UIControlEventTouchUpInside]; objc_setAssociatedObject(cancel,@selector(zx_dismissConfirmation:),backdrop,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [ok addTarget:self action:@selector(zx_confirmAction:) forControlEvents:UIControlEventTouchUpInside]; objc_setAssociatedObject(ok,ZXConfirmationBackdropKey,backdrop,OBJC_ASSOCIATION_RETAIN_NONATOMIC); objc_setAssociatedObject(ok,ZXConfirmationCompletionKey,completion,OBJC_ASSOCIATION_COPY_NONATOMIC);
        backdrop.transform=CGAffineTransformMakeScale(0.985,0.985); [UIView animateWithDuration:ZXMotionDuration(0.28) animations:^{backdrop.alpha=1;backdrop.transform=CGAffineTransformIdentity;}];
    });
}
- (void)zx_dismissConfirmation:(UIControl *)sender { UIView *v=objc_getAssociatedObject(sender,@selector(zx_dismissConfirmation:)); [UIView animateWithDuration:ZXMotionDuration(0.18) animations:^{v.alpha=0;} completion:^(BOOL d){[v removeFromSuperview];}]; }
- (void)zx_confirmAction:(UIControl *)sender { UIView *v=objc_getAssociatedObject(sender,ZXConfirmationBackdropKey); void (^completion)(void)=objc_getAssociatedObject(sender,ZXConfirmationCompletionKey); [UIView animateWithDuration:ZXMotionDuration(0.18) animations:^{v.alpha=0;} completion:^(BOOL d){[v removeFromSuperview]; if(completion)completion();}]; }

- (void)showToast:(NSString *)message { [self showToast:message success:YES]; }
- (void)showGlobalErrorWithTitle:(NSString *)title message:(NSString *)message { [self showCustomConfirmationWithTitle:title message:message confirmTitle:@"DISMISS" completion:nil]; }
- (void)showSuccessMessage:(NSString *)title message:(NSString *)message { [self showCustomConfirmationWithTitle:title message:message confirmTitle:@"CONTINUE" completion:nil]; }
- (void)showNetworkError { [self showGlobalErrorWithTitle:@"CONNECTION ERROR" message:@"Network connection lost. Try again when the secure node is reachable."]; }
- (void)showServerError { [self showGlobalErrorWithTitle:@"SERVER ERROR" message:@"The ZENTRAX server could not complete the request."]; }
- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds { [self showGlobalErrorWithTitle:@"RATE LIMITED" message:[NSString stringWithFormat:@"Request limit reached. Try again in %ld seconds.",(long)MAX(0,seconds)]]; }

- (void)showLoginScreen {
    [self transitionToPrimaryContainer:self.authContainer];
    self.currentState = ZXAppStateAuth;
    NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *saved = [globalDefaults stringForKey:ZXLastKey];
    if (saved.length) {
        self.keyInput.textField.text = saved;
        self.keyInput.clearBtn.hidden = NO;
    }
    [self stopHeartbeatMonitor];
    [self scheduleTelegramSupportPrompt];
}

- (void)showDashboard {
    if (self.dashboardConfiguration.count && self.functionDefinitions.count==0) {
        [self updateDashboardWithConfiguration:self.dashboardConfiguration];
    }
    [self transitionToPrimaryContainer:self.dashboardContainer];
    self.currentState = ZXAppStateDashboard;
    [self updateLicenseStatus:self.licenseStatus activatedAt:self.activatedAt expiresAt:self.expiresAt isPermanent:self.licensePermanent];
    [self startHeartbeatMonitor];
    [self scheduleTelegramSupportPrompt];
}

- (void)showMaintenanceScreenWithMessage:(NSString *)message { [self showStartupState:ZXStartupStateMaintenance message:message]; }
- (void)showUpdateRequiredScreenWithMessage:(NSString *)message { [self showStartupState:ZXStartupStateVersionMismatch message:message]; }
- (void)showConnectionErrorScreenWithMessage:(NSString *)message { [self showStartupState:ZXStartupStateConnectionError message:message]; }

- (void)handleLogout {
    __weak typeof(self) weakSelf=self;
    [self showCustomConfirmationWithTitle:ZXLocalizedUI(@"SIGN OUT") message:ZXLocalizedUI(@"Your current secure session will be closed.") confirmTitle:ZXLocalizedUI(@"Sign Out") completion:^{
        __strong typeof(weakSelf) self=weakSelf; if(!self)return;
        Class mgrCls=NSClassFromString(@"ZentraxNetworkManager");
        if(mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]){ id manager=((id (*)(id,SEL))objc_msgSend)((id)mgrCls,NSSelectorFromString(@"sharedManager")); SEL outSel=NSSelectorFromString(@"logout"); if([manager respondsToSelector:outSel])((void (*)(id,SEL))objc_msgSend)(manager,outSel); }
        NSUserDefaults *d=[[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"]; [d removeObjectForKey:ZXLastKey]; [d synchronize];
        if([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]){ [self.delegate zentraxDidRequestLogoutWithCompletion:^{ dispatch_async(dispatch_get_main_queue(),^{[self showLoginScreen];}); }]; } else [self showLoginScreen];
    }];
}

- (UIImage *)preferredLogoImage {
    NSArray *names=@[@"ZentraxLogo",@"AppIcon60x60",@"AppIcon"];
    for (NSString *n in names) { UIImage *i=[UIImage imageNamed:n]; if(i) return i; }
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(120,120),YES,0);
    [[UIColor clearColor] setFill]; UIRectFill(CGRectMake(0,0,120,120));
    [[ZXTheme accentPrimary] setStroke]; UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(24, 24, 72, 72) cornerRadius:18]; path.lineWidth = 6; [path stroke];
    NSDictionary *attrs=@{NSFontAttributeName:[UIFont systemFontOfSize:46 weight:UIFontWeightHeavy],NSForegroundColorAttributeName:[UIColor whiteColor]};
    [@"Z" drawInRect:CGRectMake(44,36,50,60) withAttributes:attrs];
    UIImage *i=UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); return i;
}

- (void)resetToStartup { self.hasStarted = NO; self.currentState = ZXAppStateInit; [self stopHeartbeatMonitor]; [self stopLicenseCountdown]; [self beginBootstrap]; }
- (void)dismissPresentedUI { [self dismissViewControllerAnimated:YES completion:nil]; }
- (BOOL)isShowingLogin { return self.currentState == ZXAppStateAuth && !self.authContainer.hidden; }
- (BOOL)isShowingDashboard { return self.currentState == ZXAppStateDashboard && !self.dashboardContainer.hidden; }
- (BOOL)isShowingSafeModeLock { return self.safeModeLocked && !self.safeModeOverlay.hidden; }

#pragma mark - Public Methods (From Header)

- (void)updateFunctionState:(NSString *)functionId state:(BOOL)isOn {
    if(!functionId.length)return;
    dispatch_async(dispatch_get_main_queue(),^{ [self.functionProcessing removeObjectForKey:functionId]; [self.functionOperationTokens removeObjectForKey:functionId]; [self applyFunctionVisualState:functionId state:isOn animated:YES]; });
}

- (void)zx_autoDisabledNotification:(NSNotification *)note {
    id fid=note.userInfo[@"functionId"] ?: note.userInfo[@"function_id"] ?: note.object;
    if([fid isKindOfClass:[NSString class]]) [self forceDisableToggleForFunctionId:fid];
}

- (void)updateFunctionStates:(NSDictionary<NSString *, NSNumber *> *)states {
    if (![states isKindOfClass:[NSDictionary class]]) return;
    for (NSString *fid in states) {
        id value = states[fid];
        if (![value respondsToSelector:@selector(boolValue)]) continue;
        [self updateFunctionState:fid state:[value boolValue]];
    }
} 

- (void)updateServerBanner:(NSDictionary *)banner {
    if (![banner isKindOfClass:[NSDictionary class]]) return;
    NSString *message=banner[@"message"] ?: banner[@"text"];
    BOOL visible=ZXIsTruthyValue(banner[@"visible"] ?: @YES);
    if(!visible || !message.length){ [self.connectionLabel setText:ZXLocalizedUI(@"CONNECTED")]; return; }
    dispatch_async(dispatch_get_main_queue(),^{ self.connectionLabel.text=message; self.connectionLabel.textColor=[ZXTheme warning]; });
}
- (void)showDeviceCompatibilityDetails { [self showSettings]; }
- (void)showSafeModeSettings { self.settingsVisible=YES; [self setupSettingsScreen]; [self transitionToPrimaryContainer:self.settingsContainer]; }
- (void)lockSafeMode { self.safeModeLocked=YES; [self showSafeModeLockScreen]; }
- (void)unlockSafeMode { self.safeModeLocked=NO; self.safeModeOverlay.hidden=YES; if(self.currentState==ZXAppStateDashboard)[self showDashboard]; }
- (void)showSettingsSection:(NSString *)sectionIdentifier { [self showSettings]; }

@end
 
