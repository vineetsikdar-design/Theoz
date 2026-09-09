//
//  ZentraxUI.m
//  Zentrax VIP - Premium Security Infrastructure UI
//
//  Architecture: Server-authoritative UI / Network-driven state
//  Theme: Cinematic Obsidian & Indigo (Ultra-Premium Redesign)
//  Status: PRODUCTION AUDITED - ZERO LOGIC REGRESSION
//

#import "ZentraxUI.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark - Constants & Keys

static NSString * const ZXSafeModeEnabledKey = @"in.zentrax.global.safemode.enabled";
static NSString * const ZXSafeModePasscodeAccount = @"in.zentrax.global.safemode.pin";
static NSString * const ZXLanguageKey = @"in.zentrax.global.language";
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

#pragma mark - Cinematic Background Environment

@interface ZXCinematicBackgroundView : UIView
@property (nonatomic, strong) CAGradientLayer *baseGradient;
@property (nonatomic, strong) CAGradientLayer *radialGlow;
@end

@implementation ZXCinematicBackgroundView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.02 green:0.02 blue:0.04 alpha:1.0]; // Deep Obsidian

        _baseGradient = [CAGradientLayer layer];
        _baseGradient.colors = @[
            (id)[UIColor colorWithRed:0.02 green:0.02 blue:0.04 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.04 green:0.05 blue:0.08 alpha:1.0].CGColor // Midnight Navy
        ];
        _baseGradient.startPoint = CGPointMake(0.5, 0.0);
        _baseGradient.endPoint = CGPointMake(0.5, 1.0);
        [self.layer addSublayer:_baseGradient];

        _radialGlow = [CAGradientLayer layer];
        _radialGlow.type = kCAGradientLayerRadial;
        _radialGlow.colors = @[
            (id)[UIColor colorWithRed:0.38 green:0.40 blue:0.95 alpha:0.08].CGColor, // Indigo Glow
            (id)[UIColor colorWithRed:0.02 green:0.02 blue:0.04 alpha:0.0].CGColor
        ];
        _radialGlow.startPoint = CGPointMake(0.5, 0.5);
        _radialGlow.endPoint = CGPointMake(1.0, 1.0);
        [self.layer addSublayer:_radialGlow];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _baseGradient.frame = self.bounds;
    // Position radial glow at top center
    _radialGlow.frame = CGRectMake(-self.bounds.size.width/2, -self.bounds.size.height/3, self.bounds.size.width*2, self.bounds.size.height);
}
@end

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
        @"Sign Out": @"Đăng xuất", @"AUTHENTICATE": @"XÁC THỰC",
        @"Enter Passcode": @"Nhập mật mã", @"Choose your language": @"Chọn ngôn ngữ",
        @"ACTIVE":@"ĐANG BẬT", @"READY":@"SẴN SÀNG"
    };
    NSDictionary *zh = @{
        @"Settings": @"设置", @"Safe UI Mode": @"安全界面模式",
        @"Sign Out": @"退出登录", @"AUTHENTICATE": @"验证",
        @"Enter Passcode": @"输入密码", @"Choose your language": @"选择语言",
        @"ACTIVE":@"已启用", @"READY":@"就绪"
    };

    if ([language isEqualToString:@"Tiếng Việt"]) return vi[text] ?: text;
    if ([language isEqualToString:@"简体中文"]) return zh[text] ?: text;
    
    return text;
}

#pragma mark - Theme Engine (Premium System)

@interface ZXTheme : NSObject
+ (UIColor *)surface; + (UIColor *)surfaceRaised; + (UIColor *)border; + (UIColor *)borderAccent;
+ (UIColor *)primaryText; + (UIColor *)secondaryText; + (UIColor *)mutedText; 
+ (UIColor *)accentPrimary; + (UIColor *)accentSecondary;
+ (UIColor *)success; + (UIColor *)warning; + (UIColor *)error;
+ (UIFont *)display:(CGFloat)size; + (UIFont *)heading:(CGFloat)size; + (UIFont *)body:(CGFloat)size weight:(UIFontWeight)weight; + (UIFont *)mono:(CGFloat)size weight:(UIFontWeight)weight;
+ (void)track:(UILabel *)label spacing:(CGFloat)spacing;
+ (void)styleCard:(UIView *)view;
@end

@implementation ZXTheme

+ (UIColor *)surface { return [UIColor colorWithRed:0.06 green:0.07 blue:0.10 alpha:1.0]; } // #0F111A
+ (UIColor *)surfaceRaised { return [UIColor colorWithRed:0.09 green:0.10 blue:0.14 alpha:1.0]; } // #171A24
+ (UIColor *)border { return [UIColor colorWithRed:0.16 green:0.17 blue:0.22 alpha:1.0]; } // #292B38
+ (UIColor *)borderAccent { return [UIColor colorWithRed:0.38 green:0.40 blue:0.95 alpha:0.4]; } // Soft Indigo

+ (UIColor *)primaryText { return [UIColor colorWithWhite:0.98 alpha:1.0]; }
+ (UIColor *)secondaryText { return [UIColor colorWithWhite:0.65 alpha:1.0]; }
+ (UIColor *)mutedText { return [UIColor colorWithWhite:0.45 alpha:1.0]; }

+ (UIColor *)accentPrimary { return [UIColor colorWithRed:0.49 green:0.27 blue:0.93 alpha:1.0]; } // Rich Purple #7C45EE
+ (UIColor *)accentSecondary { return [UIColor colorWithRed:0.38 green:0.40 blue:0.95 alpha:1.0]; } // Indigo #6166F2

+ (UIColor *)success { return [UIColor colorWithRed:0.15 green:0.80 blue:0.55 alpha:1.0]; } // Mint Green
+ (UIColor *)warning { return [UIColor colorWithRed:0.95 green:0.65 blue:0.20 alpha:1.0]; } // Amber
+ (UIColor *)error { return [UIColor colorWithRed:0.98 green:0.25 blue:0.35 alpha:1.0]; } // Rose Red

+ (UIFont *)display:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightHeavy]; }
+ (UIFont *)heading:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightSemibold]; }
+ (UIFont *)body:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont systemFontOfSize:size weight:weight]; }
+ (UIFont *)mono:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont monospacedSystemFontOfSize:size weight:weight]; }

+ (void)track:(UILabel *)label spacing:(CGFloat)spacing {
    if (!label.text.length) return;
    label.attributedText = [[NSAttributedString alloc] initWithString:label.text attributes:@{NSKernAttributeName:@(spacing)}];
}

+ (void)styleCard:(UIView *)view {
    view.backgroundColor = [self surface];
    view.layer.cornerRadius = 14.0;
    view.layer.borderWidth = 1.0;
    view.layer.borderColor = [self border].CGColor;
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOpacity = 0.25;
    view.layer.shadowRadius = 12;
    view.layer.shadowOffset = CGSizeMake(0, 6);
}

@end

#pragma mark - Premium Components

@interface ZXPremiumButton : UIButton
@property(nonatomic,strong) CAGradientLayer *gradientLayer;
@property(nonatomic,strong) UIActivityIndicatorView *spinner;
@property(nonatomic,strong) NSString *savedTitle;
- (void)setLoading:(BOOL)loading;
@end

@implementation ZXPremiumButton
- (instancetype)init {
    self=[super initWithFrame:CGRectZero];
    if (!self) return nil;
    
    self.layer.cornerRadius = 12.0;
    self.clipsToBounds = YES;
    self.titleLabel.font = [ZXTheme heading:15];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    _gradientLayer = [CAGradientLayer layer];
    _gradientLayer.colors = @[(id)[ZXTheme accentPrimary].CGColor, (id)[ZXTheme accentSecondary].CGColor];
    _gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    _gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    [self.layer insertSublayer:_gradientLayer atIndex:0];

    // External wrapper logic typically handles shadow, but we can do it here by disabling clipsToBounds
    self.clipsToBounds = NO;
    _gradientLayer.cornerRadius = 12.0;
    _gradientLayer.masksToBounds = YES;
    
    self.layer.shadowColor = [ZXTheme accentPrimary].CGColor;
    self.layer.shadowOpacity = 0.35;
    self.layer.shadowRadius = 10.0;
    self.layer.shadowOffset = CGSizeMake(0, 4);

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
- (void)layoutSubviews {
    [super layoutSubviews];
    _gradientLayer.frame = self.bounds;
}
- (void)zxTouchDown {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{ 
        self.transform = CGAffineTransformMakeScale(0.96, 0.96); 
        self.layer.shadowOpacity = 0.15;
    } completion:nil];
}
- (void)zxTouchUp {
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.4 options:UIViewAnimationOptionAllowUserInteraction animations:^{ 
        self.transform = CGAffineTransformIdentity; 
        self.layer.shadowOpacity = 0.35;
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
@property(nonatomic,strong) UIButton *eyeBtn;
@property(nonatomic,strong) UIButton *clearBtn;
@property(nonatomic,strong) UIImageView *iconView;
@end

@implementation ZXPremiumField
- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;
    
    _container = [[UIView alloc] init];
    _container.backgroundColor = [ZXTheme surfaceRaised];
    _container.layer.cornerRadius = 12.0;
    _container.layer.borderWidth = 1.0;
    _container.layer.borderColor = [ZXTheme border].CGColor;
    _container.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_container];

    _iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"key.fill"]];
    _iconView.tintColor = [ZXTheme mutedText];
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
    _iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [_container addSubview:_iconView];

    _textField = [[UITextField alloc] init];
    _textField.textColor = [ZXTheme primaryText];
    _textField.font = [ZXTheme mono:15 weight:UIFontWeightMedium];
    _textField.secureTextEntry = YES;
    _textField.delegate = self;
    _textField.autocorrectionType = UITextAutocorrectionTypeNo;
    _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _textField.returnKeyType = UIReturnKeyDone;
    _textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Enter License Key" attributes:@{NSForegroundColorAttributeName:[ZXTheme mutedText]}];
    _textField.translatesAutoresizingMaskIntoConstraints = NO;
    [_textField addTarget:self action:@selector(textChanged) forControlEvents:UIControlEventEditingChanged];
    [_container addSubview:_textField];

    _eyeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [_eyeBtn setImage:[UIImage systemImageNamed:@"eye.slash.fill"] forState:UIControlStateNormal];
    _eyeBtn.tintColor = [ZXTheme mutedText];
    _eyeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_eyeBtn addTarget:self action:@selector(toggleEye) forControlEvents:UIControlEventTouchUpInside];
    [_container addSubview:_eyeBtn];

    _clearBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [_clearBtn setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    _clearBtn.tintColor = [ZXTheme mutedText];
    _clearBtn.translatesAutoresizingMaskIntoConstraints = NO;
    _clearBtn.hidden = YES;
    [_clearBtn addTarget:self action:@selector(clearText) forControlEvents:UIControlEventTouchUpInside];
    [_container addSubview:_clearBtn];

    [NSLayoutConstraint activateConstraints:@[
        [_container.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_container.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_container.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_container.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_container.heightAnchor constraintEqualToConstant:54],
        
        [_iconView.leadingAnchor constraintEqualToAnchor:_container.leadingAnchor constant:16],
        [_iconView.centerYAnchor constraintEqualToAnchor:_container.centerYAnchor],
        [_iconView.widthAnchor constraintEqualToConstant:18],
        [_iconView.heightAnchor constraintEqualToConstant:18],

        [_eyeBtn.trailingAnchor constraintEqualToAnchor:_container.trailingAnchor constant:-12],
        [_eyeBtn.centerYAnchor constraintEqualToAnchor:_container.centerYAnchor],
        [_eyeBtn.widthAnchor constraintEqualToConstant:32],
        [_eyeBtn.heightAnchor constraintEqualToConstant:32],

        [_clearBtn.trailingAnchor constraintEqualToAnchor:_eyeBtn.leadingAnchor constant:-4],
        [_clearBtn.centerYAnchor constraintEqualToAnchor:_container.centerYAnchor],
        [_clearBtn.widthAnchor constraintEqualToConstant:32],
        [_clearBtn.heightAnchor constraintEqualToConstant:32],

        [_textField.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor constant:12],
        [_textField.trailingAnchor constraintEqualToAnchor:_clearBtn.leadingAnchor constant:-8],
        [_textField.centerYAnchor constraintEqualToAnchor:_container.centerYAnchor]
    ]];
    return self;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.25 animations:^{
        self.container.layer.borderColor = [ZXTheme accentPrimary].CGColor;
        self.iconView.tintColor = [ZXTheme accentPrimary];
        self.container.layer.shadowColor = [ZXTheme accentPrimary].CGColor;
        self.container.layer.shadowOpacity = 0.2;
        self.container.layer.shadowRadius = 8;
    }];
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.25 animations:^{
        self.container.layer.borderColor = [ZXTheme border].CGColor;
        self.iconView.tintColor = [ZXTheme mutedText];
        self.container.layer.shadowOpacity = 0;
    }];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
- (void)textChanged {
    self.clearBtn.hidden = (self.textField.text.length == 0);
}
- (void)clearText {
    self.textField.text = @"";
    self.clearBtn.hidden = YES;
}
- (void)toggleEye {
    self.textField.secureTextEntry = !self.textField.secureTextEntry;
    NSString *icon = self.textField.secureTextEntry ? @"eye.slash.fill" : @"eye.fill";
    [self.eyeBtn setImage:[UIImage systemImageNamed:icon] forState:UIControlStateNormal];
}
@end

#pragma mark - Main Controller

@interface ZentraxUI () <UITextFieldDelegate>
@property(nonatomic,strong) ZXCinematicBackgroundView *backgroundEnvironment;
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
@property(nonatomic,strong) UIImageView *splashLogo;
@property(nonatomic,strong) CALayer *splashBloomLayer;

@property(nonatomic,strong) ZXPremiumField *keyInput;
@property(nonatomic,strong) ZXPremiumButton *loginBtn;
@property(nonatomic,strong) UILabel *authStatus;
@property(nonatomic,strong) UIScrollView *authScroll;

@property(nonatomic,strong) UILabel *licenseStatusLabel;
@property(nonatomic,strong) UIView *licenseStatusDot;
@property(nonatomic,strong) UILabel *expiryLabel;
@property(nonatomic,strong) UILabel *countdownLabel;
@property(nonatomic,strong) UILabel *keyRevealLabel;
@property(nonatomic,strong) UIButton *keyEyeButton;
@property(nonatomic,strong) UILabel *connectionLabel;
@property(nonatomic,strong) UIView *connectionDot;
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
    
    _backgroundEnvironment = [[ZXCinematicBackgroundView alloc] initWithFrame:self.view.bounds];
    _backgroundEnvironment.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_backgroundEnvironment];
    
    self.view.tintColor = [ZXTheme accentPrimary];
    self.currentState = ZXAppStateInit;

    [self rebuildAllContainers];

    [self registerPrivacyObservers];
    [self applyInitialSafeModeState];
    [self setAllPrimaryContainersHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)rebuildAllContainers {
    [self.splashContainer removeFromSuperview];
    [self.authContainer removeFromSuperview];
    [self.dashboardContainer removeFromSuperview];
    [self.settingsContainer removeFromSuperview];
    [self.startupBlockContainer removeFromSuperview];
    [self.safeLockContainer removeFromSuperview];
    [self.globalLoadingOverlay removeFromSuperview];
    [self.privacyOverlay removeFromSuperview];

    [self setupSplash];
    [self setupAuth];
    [self setupDashboard];
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
        if (container != target) { 
            container.hidden = YES; 
            container.alpha = 1.0; 
            container.transform = CGAffineTransformIdentity; 
        }
    }
    target.hidden = NO;
    target.alpha = 0.0;
    target.transform = CGAffineTransformMakeTranslation(0, 15.0);
    
    // Critical fix: Force layout of the incoming view while it is transparent.
    // This prevents UIStackView inside UIScrollView from collapsing to 0 height.
    [self.view layoutIfNeeded]; 
    
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0.1 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction animations:^{
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
    button.titleLabel.font = [ZXTheme heading:14];
    [button setTitleColor:[ZXTheme primaryText] forState:UIControlStateNormal];
}

#pragma mark - Splash (Cinematic Rebuild)

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

    _splashBloomLayer = [CALayer layer];
    _splashBloomLayer.backgroundColor = [ZXTheme accentPrimary].CGColor;
    _splashBloomLayer.shadowColor = [ZXTheme accentPrimary].CGColor;
    _splashBloomLayer.shadowRadius = 40.0;
    _splashBloomLayer.shadowOpacity = 0.5;
    _splashBloomLayer.cornerRadius = 32.0;
    [logoWrapper.layer addSublayer:_splashBloomLayer];

    _splashLogo = [[UIImageView alloc] initWithImage:[self preferredLogoImage]];
    _splashLogo.contentMode = UIViewContentModeScaleAspectFit;
    _splashLogo.layer.cornerRadius = 24;
    _splashLogo.clipsToBounds = YES;
    _splashLogo.translatesAutoresizingMaskIntoConstraints = NO;
    [logoWrapper addSubview:_splashLogo];

    UILabel *brand = [self label:@"ZENTRAX" size:32 weight:UIFontWeightHeavy color:[ZXTheme primaryText]];
    [ZXTheme track:brand spacing:5.0];
    brand.textAlignment = NSTextAlignmentCenter;
    brand.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:brand];

    _splashStatus = [self label:@"INITIALIZING SECURE NODE" size:11 weight:UIFontWeightBold color:[ZXTheme accentSecondary]];
    [ZXTheme track:_splashStatus spacing:2.5];
    _splashStatus.textAlignment = NSTextAlignmentCenter;
    _splashStatus.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_splashStatus];

    [NSLayoutConstraint activateConstraints:@[
        [logoWrapper.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [logoWrapper.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor constant:-50],
        [logoWrapper.widthAnchor constraintEqualToConstant:72],
        [logoWrapper.heightAnchor constraintEqualToConstant:72],
        
        [_splashLogo.leadingAnchor constraintEqualToAnchor:logoWrapper.leadingAnchor],
        [_splashLogo.trailingAnchor constraintEqualToAnchor:logoWrapper.trailingAnchor],
        [_splashLogo.topAnchor constraintEqualToAnchor:logoWrapper.topAnchor],
        [_splashLogo.bottomAnchor constraintEqualToAnchor:logoWrapper.bottomAnchor],
        
        [brand.topAnchor constraintEqualToAnchor:logoWrapper.bottomAnchor constant:32],
        [brand.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        
        [_splashStatus.bottomAnchor constraintEqualToAnchor:_splashContainer.safeAreaLayoutGuide.bottomAnchor constant:-50],
        [_splashStatus.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor]
    ]];
    
    // Cinematic Animation
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.duration = 1.5;
    pulse.fromValue = @0.97;
    pulse.toValue = @1.03;
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    pulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [logoWrapper.layer addAnimation:pulse forKey:@"pulse"];
    
    CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacity.duration = 1.5;
    opacity.fromValue = @0.5;
    opacity.toValue = @1.0;
    opacity.autoreverses = YES;
    opacity.repeatCount = HUGE_VALF;
    opacity.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_splashBloomLayer addAnimation:opacity forKey:@"opacity"];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (_splashBloomLayer) {
        _splashBloomLayer.frame = _splashLogo.bounds;
    }
}

- (void)runPremiumSplashCompletion:(void (^)(void))completion {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (completion) completion();
    });
}

#pragma mark - Authentication (Elegant, Centered)

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
        [content.heightAnchor constraintEqualToAnchor:_authScroll.frameLayoutGuide.heightAnchor] // Center vertically in scroll
    ]];

    UIImageView *logo = [[UIImageView alloc] initWithImage:[self preferredLogoImage]];
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.layer.cornerRadius = 18;
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
    [_loginBtn setTitle:ZXLocalizedUI(@"AUTHENTICATE") forState:UIControlStateNormal];
    _loginBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_loginBtn addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:_loginBtn];

    _authStatus = [self label:@"" size:13 weight:UIFontWeightMedium color:[ZXTheme mutedText]];
    _authStatus.textAlignment = NSTextAlignmentCenter;
    _authStatus.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:_authStatus];

    [NSLayoutConstraint activateConstraints:@[
        [logo.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],
        [logo.centerYAnchor constraintEqualToAnchor:content.centerYAnchor constant:-130],
        [logo.widthAnchor constraintEqualToConstant:56],
        [logo.heightAnchor constraintEqualToConstant:56],
        
        [title.topAnchor constraintEqualToAnchor:logo.bottomAnchor constant:24],
        [title.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],
        
        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
        [subtitle.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],
        
        [_keyInput.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:40],
        [_keyInput.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:32],
        [_keyInput.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-32],
        
        [_loginBtn.topAnchor constraintEqualToAnchor:_keyInput.bottomAnchor constant:24],
        [_loginBtn.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:32],
        [_loginBtn.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-32],
        [_loginBtn.heightAnchor constraintEqualToConstant:54],
        
        [_authStatus.topAnchor constraintEqualToAnchor:_loginBtn.bottomAnchor constant:24],
        [_authStatus.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:24],
        [_authStatus.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-24]
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
    _authStatus.text = ZXLocalizedUI(@"Authenticating...");

    __weak typeof(self) weakSelf = self;
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestAuthenticationWithKey:completion:)]) {
        [self.delegate zentraxDidRequestAuthenticationWithKey:key completion:^(BOOL success, ZXAuthError errorType, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) return;
                [self.loginBtn setLoading:NO];
                if (success) {
                    self.authStatus.textColor = [ZXTheme success];
                    self.authStatus.text = ZXLocalizedUI(@"Access Granted");
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
                        [self.loginBtn setLoading:NO];
                        if (success) {
                            self.authStatus.textColor = [ZXTheme success];
                            self.authStatus.text = ZXLocalizedUI(@"Access Granted");
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

#pragma mark - Dashboard (Ultra Premium Cards & Dense Hierarchy)

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
    logo.layer.cornerRadius = 6;
    logo.clipsToBounds = YES;
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:logo];

    UILabel *dashTitle = [self label:@"ZENTRAX" size:16 weight:UIFontWeightHeavy color:[ZXTheme primaryText]];
    [ZXTheme track:dashTitle spacing:1.0];
    dashTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:dashTitle];

    _connectionDot = [[UIView alloc] init];
    _connectionDot.backgroundColor = [ZXTheme success];
    _connectionDot.layer.cornerRadius = 3;
    _connectionDot.layer.shadowColor = [ZXTheme success].CGColor;
    _connectionDot.layer.shadowOpacity = 0.8;
    _connectionDot.layer.shadowRadius = 4;
    _connectionDot.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:_connectionDot];

    _connectionLabel = [self label:@"SECURE" size:11 weight:UIFontWeightBold color:[ZXTheme primaryText]];
    [ZXTheme track:_connectionLabel spacing:1.0];
    _connectionLabel.textAlignment = NSTextAlignmentRight;
    _connectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:_connectionLabel];

    UIButton *settingsBtn = [self iconButton:@"line.3.horizontal" size:28];
    [settingsBtn addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:settingsBtn];

    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [header.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [header.topAnchor constraintEqualToAnchor:_dashboardContainer.safeAreaLayoutGuide.topAnchor constant:8],
        [header.heightAnchor constraintEqualToConstant:44],
        
        [logo.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [logo.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [logo.widthAnchor constraintEqualToConstant:24],
        [logo.heightAnchor constraintEqualToConstant:24],
        
        [dashTitle.leadingAnchor constraintEqualToAnchor:logo.trailingAnchor constant:12],
        [dashTitle.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        
        [_connectionLabel.trailingAnchor constraintEqualToAnchor:settingsBtn.leadingAnchor constant:-16],
        [_connectionLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        
        [_connectionDot.trailingAnchor constraintEqualToAnchor:_connectionLabel.leadingAnchor constant:-6],
        [_connectionDot.centerYAnchor constraintEqualToAnchor:_connectionLabel.centerYAnchor],
        [_connectionDot.widthAnchor constraintEqualToConstant:6],
        [_connectionDot.heightAnchor constraintEqualToConstant:6],
        
        [settingsBtn.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],
        [settingsBtn.centerYAnchor constraintEqualToAnchor:header.centerYAnchor]
    ]];

    _licenseCard = [self card];
    [_dashboardContainer addSubview:_licenseCard];
    [NSLayoutConstraint activateConstraints:@[
        [_licenseCard.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [_licenseCard.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [_licenseCard.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:24],
        [_licenseCard.heightAnchor constraintEqualToConstant:140]
    ]];

    UILabel *licenseCaption = [self label:@"LICENSE STATUS" size:11 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:licenseCaption spacing:1.5];
    licenseCaption.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:licenseCaption];

    _licenseStatusDot = [[UIView alloc] init];
    _licenseStatusDot.layer.cornerRadius = 4;
    _licenseStatusDot.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:_licenseStatusDot];

    _licenseStatusLabel = [self label:@"UNACTIVATED" size:11 weight:UIFontWeightBold color:[ZXTheme warning]];
    [ZXTheme track:_licenseStatusLabel spacing:1.0];
    _licenseStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:_licenseStatusLabel];

    _countdownLabel = [self label:@"—" size:28 weight:UIFontWeightHeavy color:[ZXTheme primaryText]];
    _countdownLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:_countdownLabel];

    _expiryLabel = [self label:@"Awaiting first activation" size:13 weight:UIFontWeightMedium color:[ZXTheme secondaryText]];
    _expiryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:_expiryLabel];
    
    UIView *divider = [[UIView alloc] init];
    divider.backgroundColor = [ZXTheme border];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:divider];
    
    _keyRevealLabel = [self label:@"•••• •••• ••••" size:13 weight:UIFontWeightMono color:[ZXTheme secondaryText]];
    _keyRevealLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:_keyRevealLabel];

    _keyEyeButton = [self iconButton:@"eye.slash.fill" size:24];
    _keyEyeButton.tintColor = [ZXTheme mutedText];
    [_keyEyeButton addTarget:self action:@selector(toggleDashboardKey) forControlEvents:UIControlEventTouchUpInside];
    [_licenseCard addSubview:_keyEyeButton];

    [NSLayoutConstraint activateConstraints:@[
        [licenseCaption.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:20],
        [licenseCaption.topAnchor constraintEqualToAnchor:_licenseCard.topAnchor constant:16],
        
        [_licenseStatusLabel.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor constant:-20],
        [_licenseStatusLabel.centerYAnchor constraintEqualToAnchor:licenseCaption.centerYAnchor],
        [_licenseStatusDot.trailingAnchor constraintEqualToAnchor:_licenseStatusLabel.leadingAnchor constant:-6],
        [_licenseStatusDot.centerYAnchor constraintEqualToAnchor:_licenseStatusLabel.centerYAnchor],
        [_licenseStatusDot.widthAnchor constraintEqualToConstant:8],
        [_licenseStatusDot.heightAnchor constraintEqualToConstant:8],
        
        [_countdownLabel.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:20],
        [_countdownLabel.topAnchor constraintEqualToAnchor:licenseCaption.bottomAnchor constant:10],
        [_countdownLabel.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor constant:-20],
        
        [_expiryLabel.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:20],
        [_expiryLabel.topAnchor constraintEqualToAnchor:_countdownLabel.bottomAnchor constant:2],
        [_expiryLabel.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor constant:-20],
        
        [divider.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor],
        [divider.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor],
        [divider.bottomAnchor constraintEqualToAnchor:_licenseCard.bottomAnchor constant:-44],
        [divider.heightAnchor constraintEqualToConstant:1],
        
        [_keyRevealLabel.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:20],
        [_keyRevealLabel.centerYAnchor constraintEqualToAnchor:divider.bottomAnchor constant:22],
        [_keyRevealLabel.trailingAnchor constraintEqualToAnchor:_keyEyeButton.leadingAnchor constant:-8],
        
        [_keyEyeButton.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor constant:-16],
        [_keyEyeButton.centerYAnchor constraintEqualToAnchor:_keyRevealLabel.centerYAnchor]
    ]];

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
        [_modulesScroll.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [_modulesScroll.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [_modulesScroll.topAnchor constraintEqualToAnchor:_licenseCard.bottomAnchor constant:24],
        [_modulesScroll.bottomAnchor constraintEqualToAnchor:_dashboardContainer.bottomAnchor],
        
        [_modulesStack.leadingAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.leadingAnchor],
        [_modulesStack.trailingAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.trailingAnchor],
        [_modulesStack.topAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.topAnchor constant:4],
        [_modulesStack.bottomAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.bottomAnchor constant:-40],
        [_modulesStack.widthAnchor constraintEqualToAnchor:_modulesScroll.frameLayoutGuide.widthAnchor]
    ]];

    [self createEmptyStateView];
}

- (void)toggleDashboardKey {
    self.keyRevealed = !self.keyRevealed;
    NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *key = [globalDefaults stringForKey:ZXLastKey];
    self.keyRevealLabel.text = self.keyRevealed && key.length ? key : @"•••• •••• ••••";
    self.keyRevealLabel.textColor = self.keyRevealed ? [ZXTheme primaryText] : [ZXTheme secondaryText];
    [self.keyEyeButton setImage:[UIImage systemImageNamed:self.keyRevealed ? @"eye.fill" : @"eye.slash.fill"] forState:UIControlStateNormal];
}

- (void)createEmptyStateView {
    _emptyState = [self card];
    _emptyState.backgroundColor = [UIColor clearColor];
    _emptyState.layer.shadowOpacity = 0;
    
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"cube.transparent"]];
    icon.tintColor = [ZXTheme mutedText];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyState addSubview:icon];
    
    UILabel *title = [self label:@"No functions assigned" size:15 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    title.textAlignment = NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyState addSubview:title];
    
    UILabel *detail = [self label:@"Server configuration will appear here." size:13 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    detail.textAlignment = NSTextAlignmentCenter;
    detail.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyState addSubview:detail];
    
    [NSLayoutConstraint activateConstraints:@[
        [_emptyState.heightAnchor constraintEqualToConstant:140],
        [icon.centerXAnchor constraintEqualToAnchor:_emptyState.centerXAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:_emptyState.centerYAnchor constant:-20],
        [icon.widthAnchor constraintEqualToConstant:32],
        [icon.heightAnchor constraintEqualToConstant:32],
        [title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:12],
        [title.centerXAnchor constraintEqualToAnchor:_emptyState.centerXAnchor],
        [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4],
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
            // Elegant Category Header
            UIView *headerWrapper = [[UIView alloc] init];
            headerWrapper.translatesAutoresizingMaskIntoConstraints = NO;
            
            UILabel *cat = [self label:categoryName.uppercaseString size:11 weight:UIFontWeightBold color:[ZXTheme mutedText]];
            [ZXTheme track:cat spacing:1.5];
            cat.translatesAutoresizingMaskIntoConstraints = NO;
            [headerWrapper addSubview:cat];
            
            [NSLayoutConstraint activateConstraints:@[
                [cat.topAnchor constraintEqualToAnchor:headerWrapper.topAnchor constant:12],
                [cat.bottomAnchor constraintEqualToAnchor:headerWrapper.bottomAnchor constant:-4],
                [cat.leadingAnchor constraintEqualToAnchor:headerWrapper.leadingAnchor constant:4],
                [cat.trailingAnchor constraintEqualToAnchor:headerWrapper.trailingAnchor constant:-4]
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

// Ultra Premium Dense Function Card
- (UIView *)functionCardForDefinition:(NSDictionary *)definition functionId:(NSString *)fid isOn:(BOOL)on {
    UIView *card = [self card];
    
    // Dynamic styling based on state
    card.layer.borderColor = on ? [ZXTheme borderAccent].CGColor : [ZXTheme border].CGColor;
    card.backgroundColor = on ? [ZXTheme surfaceRaised] : [ZXTheme surface];
    card.layer.shadowOpacity = on ? 0.4 : 0.2;
    card.layer.shadowColor = on ? [ZXTheme accentPrimary].CGColor : [UIColor blackColor].CGColor;
    card.layer.shadowRadius = on ? 12 : 8;

    UIView *iconBg = [[UIView alloc] init];
    iconBg.backgroundColor = on ? [[ZXTheme accentPrimary] colorWithAlphaComponent:0.15] : [ZXTheme surfaceRaised];
    iconBg.layer.cornerRadius = 10;
    iconBg.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:iconBg];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"bolt.shield.fill"]];
    icon.tintColor = on ? [ZXTheme accentPrimary] : [ZXTheme mutedText];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [iconBg addSubview:icon];

    UILabel *title = [self label:[NSString stringWithFormat:@"%@", definition[@"name"] ?: definition[@"title"] ?: fid]
                              size:15 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    title.numberOfLines = 1;
    [title setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:title];

    UIView *pill = [[UIView alloc] init];
    pill.backgroundColor = on ? [[ZXTheme success] colorWithAlphaComponent:0.15] : [[ZXTheme mutedText] colorWithAlphaComponent:0.1];
    pill.layer.cornerRadius = 4;
    pill.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:pill];

    UILabel *stateLabel = [self label:on ? @"ACTIVE" : @"READY"
                               size:9 weight:UIFontWeightBold color:on ? [ZXTheme success] : [ZXTheme mutedText]];
    [ZXTheme track:stateLabel spacing:1.0];
    stateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [pill addSubview:stateLabel];
    self.functionStateLabels[fid] = stateLabel;

    UISwitch *toggle = [[UISwitch alloc] init];
    toggle.onTintColor = [ZXTheme accentPrimary];
    toggle.thumbTintColor = [UIColor whiteColor];
    toggle.on = on;
    toggle.translatesAutoresizingMaskIntoConstraints = NO;
    [toggle addTarget:self action:@selector(functionToggleChanged:) forControlEvents:UIControlEventValueChanged];
    [card addSubview:toggle];
    self.functionControls[fid] = toggle;

    NSString *description = [NSString stringWithFormat:@"%@", definition[@"description"] ?: @"Server-managed secure function."];
    UILabel *detail = [self label:description size:13 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    detail.numberOfLines = 0;
    detail.lineBreakMode = NSLineBreakByWordWrapping;
    detail.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:detail];

    [NSLayoutConstraint activateConstraints:@[
        [iconBg.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [iconBg.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [iconBg.widthAnchor constraintEqualToConstant:36],
        [iconBg.heightAnchor constraintEqualToConstant:36],
        
        [icon.centerXAnchor constraintEqualToAnchor:iconBg.centerXAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:iconBg.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:18],
        [icon.heightAnchor constraintEqualToConstant:18],
        
        [toggle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [toggle.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
        
        [pill.leadingAnchor constraintEqualToAnchor:title.trailingAnchor constant:8],
        [pill.centerYAnchor constraintEqualToAnchor:title.centerYAnchor],
        [pill.trailingAnchor constraintLessThanOrEqualToAnchor:toggle.leadingAnchor constant:-12],
        
        [stateLabel.leadingAnchor constraintEqualToAnchor:pill.leadingAnchor constant:6],
        [stateLabel.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor constant:-6],
        [stateLabel.topAnchor constraintEqualToAnchor:pill.topAnchor constant:3],
        [stateLabel.bottomAnchor constraintEqualToAnchor:pill.bottomAnchor constant:-3],
        
        [title.leadingAnchor constraintEqualToAnchor:iconBg.trailingAnchor constant:14],
        [title.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        
        [detail.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4],
        [detail.trailingAnchor constraintEqualToAnchor:toggle.leadingAnchor constant:-12],
        [detail.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16]
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
    UIView *card = self.functionCards[fid];
    UILabel *state = self.functionStateLabels[fid];
    UIView *pill = state.superview;
    
    // Processing UI state
    state.textColor = [ZXTheme warning];
    state.text = ZXLocalizedUI(@"...");
    pill.backgroundColor = [[ZXTheme warning] colorWithAlphaComponent:0.15];

    __weak typeof(self) weakSelf = self;
    
    void (^finish)(BOOL, NSString *) = ^(BOOL success, NSString *msg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            sender.userInteractionEnabled = YES;
            
            BOOL finalState = success ? requested : !requested;
            self.functionStates[fid] = @(finalState);
            sender.on = finalState;
            
            // Reapply visual state
            [UIView animateWithDuration:0.25 animations:^{
                state.text = ZXLocalizedUI(finalState ? @"ACTIVE" : @"READY");
                state.textColor = finalState ? [ZXTheme success] : [ZXTheme mutedText];
                pill.backgroundColor = finalState ? [[ZXTheme success] colorWithAlphaComponent:0.15] : [[ZXTheme mutedText] colorWithAlphaComponent:0.1];
                
                card.layer.borderColor = finalState ? [ZXTheme borderAccent].CGColor : [ZXTheme border].CGColor;
                card.backgroundColor = finalState ? [ZXTheme surfaceRaised] : [ZXTheme surface];
                card.layer.shadowOpacity = finalState ? 0.4 : 0.2;
                card.layer.shadowColor = finalState ? [ZXTheme accentPrimary].CGColor : [UIColor blackColor].CGColor;
                
                // Update icon tint
                for (UIView *sub in card.subviews) {
                    if (sub.bounds.size.width == 36) { // IconBg
                        sub.backgroundColor = finalState ? [[ZXTheme accentPrimary] colorWithAlphaComponent:0.15] : [ZXTheme surfaceRaised];
                        for (UIImageView *iv in sub.subviews) {
                            iv.tintColor = finalState ? [ZXTheme accentPrimary] : [ZXTheme mutedText];
                        }
                    }
                }
            }];
            
            if (!success && msg.length > 0) {
                [self showGlobalErrorWithTitle:ZXLocalizedUI(@"OPERATION FAILED") message:msg];
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
            } else finish(NO, @"Integration bridge unavailable.");
        } else finish(NO, @"Integration bridge unavailable.");
    }
}

#pragma mark - Subscription / Time

- (void)updateSubscriptionState:(NSDictionary *)subData {
    if (![subData isKindOfClass:[NSDictionary class]]) return;
    NSString *statusRaw = subData[@"status"];
    if (!statusRaw && self.licenseStatus == ZXLicenseUIStatusActive) return; // Protect active state from sparse payloads
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
    _licenseStatusLabel.text = text;
    _licenseStatusLabel.textColor = color;
    _licenseStatusDot.backgroundColor = color;
    
    _licenseStatusDot.layer.shadowColor = color.CGColor;
    _licenseStatusDot.layer.shadowOpacity = 0.8;
    _licenseStatusDot.layer.shadowRadius = 4;
    
    if (isPermanent) {
        _countdownLabel.text = ZXLocalizedUI(@"LIFETIME");
        _expiryLabel.text = ZXLocalizedUI(@"Server entitlement is permanent");
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
    if (self.licensePermanent) return;
    if (!self.expiresAt) return;
    NSTimeInterval remaining = [self.expiresAt timeIntervalSinceDate:[self estimatedServerNow]];
    if (remaining <= 0) {
        _countdownLabel.text = ZXLocalizedUI(@"00:00:00");
        _expiryLabel.text = ZXLocalizedUI(@"EXPIRED");
        _licenseStatusLabel.text = ZXLocalizedUI(@"EXPIRED");
        _licenseStatusLabel.textColor = [ZXTheme error];
        _licenseStatusDot.backgroundColor = [ZXTheme error];
        _licenseStatusDot.layer.shadowColor = [ZXTheme error].CGColor;
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
    
    _startupBlockMessage = [self label:@"" size:14 weight:UIFontWeightMedium color:[ZXTheme secondaryText]];
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
        [_startupBlockAction.heightAnchor constraintEqualToConstant:54],
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
    if (self.safeModeEnabled) { [self showSafeModeLockScreen]; return; }
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
    _connectionLabel.text = ZXLocalizedUI(@"SECURE");
    _connectionLabel.textColor = [ZXTheme primaryText];
    _connectionDot.backgroundColor = [ZXTheme success];
    _connectionDot.layer.shadowColor = [ZXTheme success].CGColor;
}
- (void)stopHeartbeatMonitor { [self.heartbeatTimer invalidate]; self.heartbeatTimer = nil; }

- (void)heartbeatTick {
    if (self.currentState != ZXAppStateDashboard) return;
    if (self.safeModeEnabled && self.safeModeState != ZXSafeModeStateUnlocked) return;

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
    _connectionLabel.text = ZXLocalizedUI(@"OFFLINE"); 
    _connectionLabel.textColor = [ZXTheme mutedText];
    _connectionDot.backgroundColor = [ZXTheme error];
    _connectionDot.layer.shadowColor = [ZXTheme error].CGColor;
    
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

#pragma mark - Settings (Native-Level Polish)

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
        [header.topAnchor constraintEqualToAnchor:_settingsContainer.safeAreaLayoutGuide.topAnchor constant:8],
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
        [_settingsScroll.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:24],
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
    UIView *row = [self card];
    row.layer.shadowOpacity = 0.1;
    
    UIView *iconBg = [[UIView alloc] init];
    iconBg.backgroundColor = [color colorWithAlphaComponent:0.15];
    iconBg.layer.cornerRadius = 8;
    iconBg.translatesAutoresizingMaskIntoConstraints = NO;
    [row addSubview:iconBg];
    
    UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:iconName]];
    iv.tintColor = color;
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.translatesAutoresizingMaskIntoConstraints = NO;
    [iconBg addSubview:iv];
    
    UILabel *t = [self label:title size:15 weight:UIFontWeightMedium color:[ZXTheme primaryText]];
    t.translatesAutoresizingMaskIntoConstraints = NO;
    [row addSubview:t];
    
    UILabel *s = [self label:subtitle size:13 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    s.numberOfLines = 0;
    s.translatesAutoresizingMaskIntoConstraints = NO;
    [row addSubview:s];
    
    [NSLayoutConstraint activateConstraints:@[
        [row.heightAnchor constraintGreaterThanOrEqualToConstant:76],
        
        [iconBg.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:16],
        [iconBg.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [iconBg.widthAnchor constraintEqualToConstant:34],
        [iconBg.heightAnchor constraintEqualToConstant:34],
        
        [iv.centerXAnchor constraintEqualToAnchor:iconBg.centerXAnchor],
        [iv.centerYAnchor constraintEqualToAnchor:iconBg.centerYAnchor],
        [iv.widthAnchor constraintEqualToConstant:18],
        [iv.heightAnchor constraintEqualToConstant:18],
        
        [t.leadingAnchor constraintEqualToAnchor:iconBg.trailingAnchor constant:16],
        [t.topAnchor constraintEqualToAnchor:row.topAnchor constant:16],
        [t.trailingAnchor constraintLessThanOrEqualToAnchor:row.trailingAnchor constant:-65],
        
        [s.leadingAnchor constraintEqualToAnchor:t.leadingAnchor],
        [s.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:4],
        [s.trailingAnchor constraintLessThanOrEqualToAnchor:row.trailingAnchor constant:-65],
        [s.bottomAnchor constraintLessThanOrEqualToAnchor:row.bottomAnchor constant:-16]
    ]];
    
    if (accessory) {
        accessory.translatesAutoresizingMaskIntoConstraints = NO;
        [row addSubview:accessory];
        [NSLayoutConstraint activateConstraints:@[
            [accessory.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-16],
            [accessory.centerYAnchor constraintEqualToAnchor:row.centerYAnchor]
        ]];
    } else {
        UIImageView *chev = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
        chev.tintColor = [ZXTheme mutedText];
        chev.translatesAutoresizingMaskIntoConstraints = NO;
        [row addSubview:chev];
        [NSLayoutConstraint activateConstraints:@[
            [chev.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-16],
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
    
    UILabel *secLabel = [self label:@"SECURITY" size:11 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:secLabel spacing:1.5];
    [self.settingsStack addArrangedSubview:secLabel];
    
    UISwitch *safe = [[UISwitch alloc] init];
    safe.onTintColor = [ZXTheme accentPrimary];
    safe.thumbTintColor = [UIColor whiteColor];
    safe.on = self.safeModeEnabled;
    [safe addTarget:self action:@selector(safeModeSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.settingsStack addArrangedSubview:[self settingsRow:@"Safe UI Mode" subtitle:safe.isOn ? @"Protected lock screen is active." : @"Require 6-digit passcode to unlock." icon:@"lock.fill" color:[ZXTheme success] action:nil accessory:safe]];

    UILabel *devLabel = [self label:@"DEVICE ENVIRONMENT" size:11 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:devLabel spacing:1.5];
    [self.settingsStack addArrangedSubview:devLabel];
    
    [self.settingsStack addArrangedSubview:[self buildDeviceCard]];

    UILabel *prefLabel = [self label:@"PREFERENCES" size:11 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:prefLabel spacing:1.5];
    [self.settingsStack addArrangedSubview:prefLabel];
    
    NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *language = [globalDefaults stringForKey:ZXLanguageKey] ?: @"English";
    [self.settingsStack addArrangedSubview:[self settingsRow:@"Language" subtitle:language icon:@"globe" color:[ZXTheme accentSecondary] action:@selector(showLanguagePicker) accessory:nil]];

    UILabel *accLabel = [self label:@"SESSION" size:11 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:accLabel spacing:1.5];
    [self.settingsStack addArrangedSubview:accLabel];
    [self.settingsStack addArrangedSubview:[self settingsRow:@"Sign Out" subtitle:@"Close the current secure session." icon:@"rectangle.portrait.and.arrow.right" color:[ZXTheme error] action:@selector(handleLogout) accessory:nil]];
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

    UILabel *nameLabel = [self label:device size:18 weight:UIFontWeightBold color:[ZXTheme primaryText]];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:nameLabel];
    
    UILabel *iosLabel = [self label:[NSString stringWithFormat:@"iOS %@", ios] size:14 weight:UIFontWeightMedium color:[ZXTheme secondaryText]];
    iosLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:iosLabel];
    
    UIView *pill = [[UIView alloc] init];
    pill.backgroundColor = [statusColor colorWithAlphaComponent:0.15];
    pill.layer.cornerRadius = 4;
    pill.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:pill];

    UILabel *statusLbl = [self label:statusText size:10 weight:UIFontWeightBold color:statusColor];
    [ZXTheme track:statusLbl spacing:1.0];
    statusLbl.translatesAutoresizingMaskIntoConstraints = NO;
    [pill addSubview:statusLbl];
    
    NSString *reason = ZXSafeString(self.compatibilityData[@"reason"], supported ? @"Verified by server" : @"Check device compatibility");
    UILabel *descLabel = [self label:reason size:13 weight:UIFontWeightRegular color:[ZXTheme mutedText]];
    descLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:descLabel];
    
    UIButton *recheck = [UIButton buttonWithType:UIButtonTypeSystem];
    [self styleSecondaryButton:recheck];
    [recheck setTitle:ZXLocalizedUI(@"RECHECK") forState:UIControlStateNormal];
    recheck.translatesAutoresizingMaskIntoConstraints = NO;
    [recheck addTarget:self action:@selector(requestDeviceCompatibilityRecheck) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:recheck];
    
    [NSLayoutConstraint activateConstraints:@[
        [card.heightAnchor constraintGreaterThanOrEqualToConstant:144],
        [nameLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [nameLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
        
        [iosLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [iosLabel.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:4],
        
        [pill.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [pill.centerYAnchor constraintEqualToAnchor:nameLabel.centerYAnchor],
        
        [statusLbl.leadingAnchor constraintEqualToAnchor:pill.leadingAnchor constant:6],
        [statusLbl.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor constant:-6],
        [statusLbl.topAnchor constraintEqualToAnchor:pill.topAnchor constant:4],
        [statusLbl.bottomAnchor constraintEqualToAnchor:pill.bottomAnchor constant:-4],
        
        [descLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [descLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [descLabel.topAnchor constraintEqualToAnchor:iosLabel.bottomAnchor constant:12],
        
        [recheck.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [recheck.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [recheck.topAnchor constraintEqualToAnchor:descLabel.bottomAnchor constant:16],
        [recheck.heightAnchor constraintEqualToConstant:48],
        [recheck.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20]
    ]];
    
    return card;
}

- (void)showSettings {
    if (self.safeModeEnabled && self.safeModeState != ZXSafeModeStateUnlocked) { [self showSafeModeLockScreen]; return; }
    self.settingsVisible = YES;
    [self setupSettingsScreen];
    [self transitionToPrimaryContainer:self.settingsContainer];
}
- (void)closeSettings { self.settingsVisible = NO; [self showDashboard]; }

#pragma mark - Safe UI Mode (Elegant Secure PIN)

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

- (void)setupSafeModeLock {
    _safeLockContainer = [[UIView alloc] init];
    _safeLockContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark];
    UIVisualEffectView *vev = [[UIVisualEffectView alloc] initWithEffect:blur];
    vev.translatesAutoresizingMaskIntoConstraints = NO;
    [_safeLockContainer addSubview:vev];
    
    [self.view addSubview:_safeLockContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_safeLockContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_safeLockContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_safeLockContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_safeLockContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [vev.leadingAnchor constraintEqualToAnchor:_safeLockContainer.leadingAnchor],
        [vev.trailingAnchor constraintEqualToAnchor:_safeLockContainer.trailingAnchor],
        [vev.topAnchor constraintEqualToAnchor:_safeLockContainer.topAnchor],
        [vev.bottomAnchor constraintEqualToAnchor:_safeLockContainer.bottomAnchor]
    ]];

    _safeLockBackButton = [self iconButton:@"chevron.left" size:34];
    _safeLockBackButton.tintColor = [UIColor whiteColor];
    _safeLockBackButton.hidden = YES;
    [_safeLockBackButton addTarget:self action:@selector(cancelSafeModeAction) forControlEvents:UIControlEventTouchUpInside];
    [_safeLockContainer addSubview:_safeLockBackButton];

    UIImageView *lockIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.shield.fill"]];
    lockIcon.tintColor = [ZXTheme primaryText];
    lockIcon.contentMode = UIViewContentModeScaleAspectFit;
    lockIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [_safeLockContainer addSubview:lockIcon];

    _safeLockTitle = [self label:@"ENTER PASSCODE" size:24 weight:UIFontWeightHeavy color:[ZXTheme primaryText]];
    [ZXTheme track:_safeLockTitle spacing:1.5];
    _safeLockTitle.textAlignment = NSTextAlignmentCenter;
    _safeLockTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [_safeLockContainer addSubview:_safeLockTitle];

    _safeLockSubtitle = [self label:@"" size:15 weight:UIFontWeightRegular color:[UIColor clearColor]];
    _safeLockSubtitle.textAlignment = NSTextAlignmentCenter;
    _safeLockSubtitle.translatesAutoresizingMaskIntoConstraints = NO;
    [_safeLockContainer addSubview:_safeLockSubtitle];

    _safePinError = [self label:@"" size:14 weight:UIFontWeightMedium color:[ZXTheme error]];
    _safePinError.textAlignment = NSTextAlignmentCenter;
    _safePinError.translatesAutoresizingMaskIntoConstraints = NO;
    [_safeLockContainer addSubview:_safePinError];

    _pinBoxes = [[UIStackView alloc] init];
    _pinBoxes.axis = UILayoutConstraintAxisHorizontal;
    _pinBoxes.spacing = 24;
    _pinBoxes.distribution = UIStackViewDistributionFillEqually;
    _pinBoxes.translatesAutoresizingMaskIntoConstraints = NO;
    [_safeLockContainer addSubview:_pinBoxes];
    
    for (NSInteger i = 0; i < 6; i++) {
        UIView *box = [[UIView alloc] init];
        box.layer.cornerRadius = 8;
        box.layer.borderWidth = 1.5;
        box.layer.borderColor = [ZXTheme border].CGColor;
        box.backgroundColor = [UIColor clearColor];
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
        [_safeLockBackButton.leadingAnchor constraintEqualToAnchor:_safeLockContainer.leadingAnchor constant:24],
        [_safeLockBackButton.topAnchor constraintEqualToAnchor:_safeLockContainer.safeAreaLayoutGuide.topAnchor constant:16],
        
        [lockIcon.centerXAnchor constraintEqualToAnchor:_safeLockContainer.centerXAnchor],
        [lockIcon.centerYAnchor constraintEqualToAnchor:_safeLockContainer.centerYAnchor constant:-140],
        [lockIcon.widthAnchor constraintEqualToConstant:48],
        [lockIcon.heightAnchor constraintEqualToConstant:48],
        
        [_safeLockTitle.topAnchor constraintEqualToAnchor:lockIcon.bottomAnchor constant:24],
        [_safeLockTitle.leadingAnchor constraintEqualToAnchor:_safeLockContainer.leadingAnchor constant:24],
        [_safeLockTitle.trailingAnchor constraintEqualToAnchor:_safeLockContainer.trailingAnchor constant:-24],
        
        [_safeLockSubtitle.topAnchor constraintEqualToAnchor:_safeLockTitle.bottomAnchor constant:12],
        [_safeLockSubtitle.leadingAnchor constraintEqualToAnchor:_safeLockContainer.leadingAnchor constant:24],
        [_safeLockSubtitle.trailingAnchor constraintEqualToAnchor:_safeLockContainer.trailingAnchor constant:-24],
        
        [_safePinError.topAnchor constraintEqualToAnchor:_safeLockSubtitle.bottomAnchor constant:12],
        [_safePinError.leadingAnchor constraintEqualToAnchor:_safeLockContainer.leadingAnchor constant:24],
        [_safePinError.trailingAnchor constraintEqualToAnchor:_safeLockContainer.trailingAnchor constant:-24],
        
        [_pinBoxes.topAnchor constraintEqualToAnchor:_safePinError.bottomAnchor constant:40],
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
        self.safeLockTitle.text = ZXLocalizedUI(@"CREATE PASSCODE");
        self.safeLockSubtitle.text = ZXLocalizedUI(@"Secure your dashboard with a 6-digit pin.");
        self.safeLockSubtitle.textColor = [ZXTheme secondaryText];
        self.safeLockBackButton.hidden = NO;
    } else if (self.safeModeDisabling) {
        self.safeLockTitle.text = ZXLocalizedUI(@"DISABLE SAFE UI");
        self.safeLockSubtitle.text = ZXLocalizedUI(@"Enter your passcode to verify.");
        self.safeLockSubtitle.textColor = [ZXTheme secondaryText];
        self.safeLockBackButton.hidden = NO;
    } else {
        self.safeLockTitle.text = ZXLocalizedUI(@"SECURE LOCK");
        self.safeLockSubtitle.text = @"";
        self.safeLockSubtitle.textColor = [UIColor clearColor];
        self.safeLockBackButton.hidden = YES;
    }
    
    [self transitionToPrimaryContainer:self.safeLockContainer];
    self.currentState = ZXAppStateStartupBlock;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.safeLockContainer.hidden) [self.safePINInput becomeFirstResponder];
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
    
    if (digits.length > 0) [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    
    if (digits.length == 6) {
        [self processEnteredPIN];
    }
}

- (void)updatePINBoxes {
    for (NSInteger i=0;i<6;i++) {
        UIView *box = [self.pinBoxes.arrangedSubviews objectAtIndex:i];
        if (i < self.enteredPIN.length) {
            box.backgroundColor = [ZXTheme accentPrimary];
            box.layer.borderWidth = 0;
            box.layer.shadowColor = [ZXTheme accentPrimary].CGColor;
            box.layer.shadowOpacity = 0.5;
            box.layer.shadowRadius = 8;
        } else {
            box.backgroundColor = [UIColor clearColor];
            box.layer.borderWidth = 1.5;
            box.layer.borderColor = [ZXTheme border].CGColor;
            box.layer.shadowOpacity = 0;
        }
    }
}

- (void)processEnteredPIN {
    if (self.safeModeCreatingPasscode) {
        if (!self.pendingSafeModePasscode.length) {
            self.pendingSafeModePasscode = [self.enteredPIN copy];
            self.enteredPIN.string = @"";
            self.safePINInput.text = @"";
            self.safeLockTitle.text = ZXLocalizedUI(@"CONFIRM PASSCODE");
            self.safeLockSubtitle.text = ZXLocalizedUI(@"Enter the 6-digit passcode again.");
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
        [self showToast:ZXLocalizedUI(@"Safe UI enabled") success:YES];
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
            [self showToast:ZXLocalizedUI(@"Safe UI disabled") success:YES];
            [self showSettings];
        } else {
            [self updateSafeModeState:ZXSafeModeStateUnlocked];
            [self showDashboard];
        }
        return;
    }
    
    self.safeModeAttemptsRemaining = MAX(0, self.safeModeAttemptsRemaining - 1);
    self.safePinError.text = self.safeModeAttemptsRemaining > 0 ? [NSString stringWithFormat:@"Incorrect passcode • %ld attempts left", (long)self.safeModeAttemptsRemaining] : @"Incorrect passcode";
    self.enteredPIN.string = @"";
    self.safePINInput.text = @"";
    
    for (UIView *box in self.pinBoxes.arrangedSubviews) {
        box.backgroundColor = [ZXTheme error];
        box.layer.borderWidth = 0;
        box.layer.shadowColor = [ZXTheme error].CGColor;
        box.layer.shadowOpacity = 0.5;
    }
    
    [self shakePINBoxes];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updatePINBoxes];
    });
}

- (void)shakePINBoxes {
    [UIView animateKeyframesWithDuration:0.4 delay:0 options:0 animations:^{
        self.pinBoxes.transform = CGAffineTransformMakeTranslation(-12,0);
        [UIView addKeyframeWithRelativeStartTime:0.20 relativeDuration:0.25 animations:^{ self.pinBoxes.transform = CGAffineTransformMakeTranslation(12,0); }];
        [UIView addKeyframeWithRelativeStartTime:0.45 relativeDuration:0.25 animations:^{ self.pinBoxes.transform = CGAffineTransformMakeTranslation(-8,0); }];
        [UIView addKeyframeWithRelativeStartTime:0.70 relativeDuration:0.25 animations:^{ self.pinBoxes.transform = CGAffineTransformIdentity; }];
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
            shield.tintColor = [ZXTheme accentPrimary];
            shield.contentMode = UIViewContentModeScaleAspectFit;
            shield.translatesAutoresizingMaskIntoConstraints = NO;
            [content addSubview:shield];

            UILabel *title = [self label:@"SCREEN RECORDING BLOCKED" size:22 weight:UIFontWeightHeavy color:[UIColor whiteColor]];
            title.textAlignment = NSTextAlignmentCenter;
            title.translatesAutoresizingMaskIntoConstraints = NO;
            [content addSubview:title];

            UILabel *message = [self label:@"Screen sharing apps are restricted in this secure environment. Please stop recording to continue." size:14 weight:UIFontWeightMedium color:[UIColor lightGrayColor]];
            message.textAlignment = NSTextAlignmentCenter;
            message.numberOfLines = 0;
            message.translatesAutoresizingMaskIntoConstraints = NO;
            [content addSubview:message];

            [NSLayoutConstraint activateConstraints:@[
                [shield.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],
                [shield.centerYAnchor constraintEqualToAnchor:content.centerYAnchor constant:-80],
                [shield.widthAnchor constraintEqualToConstant:64],
                [shield.heightAnchor constraintEqualToConstant:64],
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
        [UIView animateWithDuration:0.3 animations:^{ self.privacyOverlay.alpha = 0; } completion:^(BOOL f){ [self.privacyOverlay removeFromSuperview]; self.privacyOverlayPresented=NO; }]; 
    }); 
}

#pragma mark - Language Picker & Rechecks

- (void)showLanguagePicker {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:ZXLocalizedUI(@"Choose your language") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *langs = @[@"English", @"Tiếng Việt", @"简体中文", @"日本語"];
    for (NSString *lang in langs) {
        [alert addAction:[UIAlertAction actionWithTitle:lang style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
            [globalDefaults setObject:lang forKey:ZXLanguageKey];
            [globalDefaults synchronize];
            [self rebuildAllContainers];
            [self transitionToPrimaryContainer:self.settingsContainer];
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
    
    UIView *card = [self card];
    card.layer.borderColor = [[ZXTheme accentPrimary] colorWithAlphaComponent:0.5].CGColor;
    card.layer.shadowColor = [ZXTheme accentPrimary].CGColor;
    card.layer.shadowOpacity = 0.2;
    card.layer.shadowRadius = 24;
    [((UIVisualEffectView *)_globalLoadingOverlay).contentView addSubview:card];
    
    _globalSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _globalSpinner.color = [ZXTheme accentPrimary];
    _globalSpinner.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_globalSpinner];
    
    _globalLoadingTitle = [self label:@"SECURE OPERATION" size:15 weight:UIFontWeightBold color:[UIColor whiteColor]];
    _globalLoadingTitle.textAlignment = NSTextAlignmentCenter;
    _globalLoadingTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_globalLoadingTitle];
    
    _globalLoadingDetail = [self label:@"Please wait…" size:13 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    _globalLoadingDetail.textAlignment = NSTextAlignmentCenter;
    _globalLoadingDetail.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_globalLoadingDetail];
    
    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:_globalLoadingOverlay.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:_globalLoadingOverlay.centerYAnchor],
        [card.widthAnchor constraintEqualToConstant:280],
        [card.heightAnchor constraintEqualToConstant:160],
        
        [_globalSpinner.topAnchor constraintEqualToAnchor:card.topAnchor constant:32],
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
        [UIView animateWithDuration:0.3 animations:^{ self.globalLoadingOverlay.alpha = 1; }];
    });
}
- (void)updateGlobalLoadingMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{ self.globalLoadingDetail.text = ZXLocalizedUI(message ?: @"Please wait…"); });
}
- (void)hideGlobalLoadingState {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.globalSpinner stopAnimating];
        [UIView animateWithDuration:0.3 animations:^{ self.globalLoadingOverlay.alpha = 0; } completion:^(BOOL finished){ self.globalLoadingOverlay.hidden = YES; }];
    });
}

- (void)showToast:(NSString *)message success:(BOOL)success {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.toastView) [self.toastView removeFromSuperview];
        
        UIColor *accent = success ? [ZXTheme success] : [ZXTheme error];
        
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark];
        UIVisualEffectView *toast = [[UIVisualEffectView alloc] initWithEffect:blur];
        toast.layer.cornerRadius = 14;
        toast.layer.borderWidth = 1.0;
        toast.layer.borderColor = [accent colorWithAlphaComponent:0.6].CGColor;
        toast.clipsToBounds = YES;
        toast.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.view addSubview:toast];
        self.toastView = toast;
        
        UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:success ? @"checkmark.circle.fill" : @"exclamationmark.triangle.fill"]];
        icon.tintColor = accent;
        icon.translatesAutoresizingMaskIntoConstraints = NO;
        [toast.contentView addSubview:icon];
        
        UILabel *text = [self label:ZXLocalizedUI(message ?: @"") size:14 weight:UIFontWeightMedium color:[UIColor whiteColor]];
        text.translatesAutoresizingMaskIntoConstraints = NO;
        [toast.contentView addSubview:text];
        
        [NSLayoutConstraint activateConstraints:@[
            [toast.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [toast.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
            [toast.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24],
            [toast.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24],
            [toast.heightAnchor constraintGreaterThanOrEqualToConstant:50],
            
            [icon.leadingAnchor constraintEqualToAnchor:toast.contentView.leadingAnchor constant:20],
            [icon.centerYAnchor constraintEqualToAnchor:toast.contentView.centerYAnchor],
            [icon.widthAnchor constraintEqualToConstant:20],
            [icon.heightAnchor constraintEqualToConstant:20],
            
            [text.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:12],
            [text.trailingAnchor constraintEqualToAnchor:toast.contentView.trailingAnchor constant:-20],
            [text.centerYAnchor constraintEqualToAnchor:toast.contentView.centerYAnchor],
            [text.topAnchor constraintEqualToAnchor:toast.contentView.topAnchor constant:14],
            [text.bottomAnchor constraintEqualToAnchor:toast.contentView.bottomAnchor constant:-14]
        ]];
        
        toast.alpha = 0; toast.transform = CGAffineTransformMakeTranslation(0,-20);
        [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:success ? UINotificationFeedbackTypeSuccess : UINotificationFeedbackTypeError];
        
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.2 options:0 animations:^{ toast.alpha=1; toast.transform=CGAffineTransformIdentity; } completion:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(3.0*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
            if(self.toastView==toast){ [UIView animateWithDuration:0.3 animations:^{ toast.alpha=0; } completion:^(BOOL f){ [toast removeFromSuperview]; self.toastView=nil; }]; }
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
    if (saved.length) {
        self.keyInput.textField.text = saved;
        self.keyInput.clearBtn.hidden = NO;
    }
    [self stopHeartbeatMonitor];
}

- (void)showDashboard {
    if (self.safeModeEnabled && self.safeModeState != ZXSafeModeStateUnlocked) { [self showSafeModeLockScreen]; return; }
    [self transitionToPrimaryContainer:self.dashboardContainer];
    self.currentState = ZXAppStateDashboard;
    
    [self updateLicenseStatus:self.licenseStatus activatedAt:self.activatedAt expiresAt:self.expiresAt isPermanent:self.licensePermanent];
    [self startHeartbeatMonitor];
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
- (BOOL)isShowingSafeModeLock { return !self.safeLockContainer.hidden && self.safeModeEnabled; }

@end
