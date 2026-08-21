//
//  ZentraxUI.m
//  Zentrax VIP - Ultra Premium Panel UI
//
//  Created by Zentrax Team.
//  Status: FINAL PRODUCTION READY (Grid UI + Typewriter Splash + Fixed Compile)
//

#import "ZentraxUI.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>

#pragma mark - ================= PREMIUM THEME & COLORS =================

@interface ZXTheme : NSObject
+ (UIColor *)bgBaseDark;
+ (UIColor *)bgCardGlass;
+ (UIColor *)bgInputDark;
+ (UIColor *)gridLineColor;
+ (UIColor *)borderSubtle;
+ (UIColor *)accentPrimary;   // Deep Purple
+ (UIColor *)accentSecondary; // Neon Blue/Cyan
+ (UIColor *)textPrimary;
+ (UIColor *)textSecondary;
+ (UIColor *)textMuted;
+ (UIColor *)statusSuccess;
+ (UIColor *)statusError;
+ (UIFont *)fontDisplay:(CGFloat)size;
+ (UIFont *)fontHeading:(CGFloat)size;
+ (UIFont *)fontBody:(CGFloat)size weight:(UIFontWeight)weight;
+ (UIFont *)fontMono:(CGFloat)size weight:(UIFontWeight)weight;
+ (CAGradientLayer *)primaryGradient;
+ (void)applyTextTracking:(UILabel *)label spacing:(CGFloat)spacing;
@end

@implementation ZXTheme
+ (UIColor *)bgBaseDark { return [UIColor colorWithRed:0.04 green:0.02 blue:0.08 alpha:1.0]; } // #0A0514
+ (UIColor *)bgCardGlass { return [UIColor colorWithRed:0.12 green:0.08 blue:0.18 alpha:0.65]; }
+ (UIColor *)bgInputDark { return [UIColor colorWithRed:0.08 green:0.05 blue:0.12 alpha:0.9]; }
+ (UIColor *)gridLineColor { return [UIColor colorWithRed:0.3 green:0.2 blue:0.5 alpha:0.15]; }
+ (UIColor *)borderSubtle { return [UIColor colorWithRed:0.35 green:0.20 blue:0.55 alpha:0.4]; }
+ (UIColor *)accentPrimary { return [UIColor colorWithRed:0.55 green:0.15 blue:0.95 alpha:1.0]; } // Purple
+ (UIColor *)accentSecondary { return [UIColor colorWithRed:0.10 green:0.60 blue:1.0 alpha:1.0]; } // Blue
+ (UIColor *)textPrimary { return [UIColor whiteColor]; }
+ (UIColor *)textSecondary { return [UIColor colorWithWhite:0.75 alpha:1.0]; }
+ (UIColor *)textMuted { return [UIColor colorWithWhite:0.50 alpha:1.0]; }
+ (UIColor *)statusSuccess { return [UIColor colorWithRed:0.15 green:0.85 blue:0.55 alpha:1.0]; }
+ (UIColor *)statusError { return [UIColor colorWithRed:1.0 green:0.25 blue:0.40 alpha:1.0]; }

+ (UIFont *)fontDisplay:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBlack]; }
+ (UIFont *)fontHeading:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBold]; }
+ (UIFont *)fontBody:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont systemFontOfSize:size weight:weight]; }
+ (UIFont *)fontMono:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont monospacedSystemFontOfSize:size weight:weight]; }

+ (CAGradientLayer *)primaryGradient {
    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.colors = @[(id)[self accentPrimary].CGColor, (id)[self accentSecondary].CGColor];
    layer.startPoint = CGPointMake(0.0, 0.5);
    layer.endPoint = CGPointMake(1.0, 0.5);
    return layer;
}

// Fixed: Missing implementation added here
+ (void)applyTextTracking:(UILabel *)label spacing:(CGFloat)spacing {
    if (!label || !label.text) return;
    NSDictionary *attrs = @{NSKernAttributeName: @(spacing)};
    label.attributedText = [[NSAttributedString alloc] initWithString:label.text attributes:attrs];
}
@end

#pragma mark - ================= ANIMATED GRID BACKGROUND =================

@interface ZXGridBackgroundView : UIView
@property (nonatomic, strong) CAGradientLayer *movingGlow;
@end

@implementation ZXGridBackgroundView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [ZXTheme bgBaseDark];
        
        _movingGlow = [CAGradientLayer layer];
        _movingGlow.type = kCAGradientLayerRadial;
        _movingGlow.colors = @[(id)[[ZXTheme accentPrimary] colorWithAlphaComponent:0.3].CGColor, (id)[UIColor clearColor].CGColor];
        _movingGlow.startPoint = CGPointMake(0.5, 0.5);
        _movingGlow.endPoint = CGPointMake(1.0, 1.0);
        _movingGlow.frame = CGRectMake(-100, -100, 500, 500);
        [self.layer addSublayer:_movingGlow];
        
        [self startGlowAnimation];
    }
    return self;
}

- (void)startGlowAnimation {
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform.translation"];
    anim.toValue = [NSValue valueWithCGSize:CGSizeMake(self.bounds.size.width, self.bounds.size.height * 0.5)];
    anim.duration = 15.0;
    anim.autoreverses = YES;
    anim.repeatCount = HUGE_VALF;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_movingGlow addAnimation:anim forKey:@"movement"];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, [ZXTheme gridLineColor].CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    CGFloat gridSize = 45.0;
    
    for (CGFloat x = 0; x < rect.size.width; x += gridSize) {
        CGContextMoveToPoint(ctx, x, 0);
        CGContextAddLineToPoint(ctx, x, rect.size.height);
    }
    for (CGFloat y = 0; y < rect.size.height; y += gridSize) {
        CGContextMoveToPoint(ctx, 0, y);
        CGContextAddLineToPoint(ctx, rect.size.width, y);
    }
    CGContextStrokePath(ctx);
}
@end

#pragma mark - ================= PREMIUM UI COMPONENTS =================

@interface ZXButton : UIButton
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSString *originalTitle;
- (void)setLoading:(BOOL)loading;
@end

@implementation ZXButton
- (instancetype)init {
    if (self = [super init]) {
        self.layer.cornerRadius = 10;
        self.clipsToBounds = YES;
        self.titleLabel.font = [ZXTheme fontHeading:16];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        _gradientLayer = [ZXTheme primaryGradient];
        [self.layer insertSublayer:_gradientLayer atIndex:0];
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        _spinner.color = [UIColor whiteColor];
        _spinner.hidesWhenStopped = YES;
        _spinner.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_spinner];
        
        [NSLayoutConstraint activateConstraints:@[
            [_spinner.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [_spinner.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
        ]];
        
        [self addTarget:self action:@selector(touchDown) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.bounds;
}
- (void)touchDown {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [UIView animateWithDuration:0.1 animations:^{ self.transform = CGAffineTransformMakeScale(0.96, 0.96); }];
}
- (void)touchUp {
    [UIView animateWithDuration:0.3 animations:^{ self.transform = CGAffineTransformIdentity; }];
}
- (void)setLoading:(BOOL)loading {
    self.userInteractionEnabled = !loading;
    if (loading) {
        self.originalTitle = [self titleForState:UIControlStateNormal];
        [self setTitle:@"" forState:UIControlStateNormal];
        [self.spinner startAnimating];
    } else {
        [self setTitle:self.originalTitle forState:UIControlStateNormal];
        [self.spinner stopAnimating];
    }
}
@end

@interface ZXTextField : UIView <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIView *inputContainer;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@end

@implementation ZXTextField
- (instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
        
        UILabel *topLabel = [[UILabel alloc] init];
        topLabel.text = @"LICENSE KEY";
        topLabel.textColor = [ZXTheme textSecondary];
        topLabel.font = [ZXTheme fontHeading:12];
        topLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:topLabel];
        
        _inputContainer = [[UIView alloc] init];
        _inputContainer.layer.cornerRadius = 10;
        _inputContainer.layer.borderWidth = 1.0;
        _inputContainer.layer.borderColor = [ZXTheme borderSubtle].CGColor;
        _inputContainer.clipsToBounds = YES;
        _inputContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_inputContainer];
        
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        _blurView.translatesAutoresizingMaskIntoConstraints = NO;
        [_inputContainer addSubview:_blurView];
        
        UIView *overlay = [[UIView alloc] init];
        overlay.backgroundColor = [ZXTheme bgInputDark];
        overlay.translatesAutoresizingMaskIntoConstraints = NO;
        [_inputContainer addSubview:overlay];
        
        UIImageView *iconView = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"key.horizontal.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        iconView.tintColor = [ZXTheme textMuted];
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        iconView.translatesAutoresizingMaskIntoConstraints = NO;
        [_inputContainer addSubview:iconView];
        
        _textField = [[UITextField alloc] init];
        _textField.textColor = [ZXTheme textPrimary];
        _textField.font = [ZXTheme fontMono:15 weight:UIFontWeightMedium];
        _textField.secureTextEntry = YES;
        _textField.delegate = self;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Enter your license" attributes:@{NSForegroundColorAttributeName: [ZXTheme textMuted]}];
        _textField.translatesAutoresizingMaskIntoConstraints = NO;
        [_inputContainer addSubview:_textField];
        
        [NSLayoutConstraint activateConstraints:@[
            [topLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
            [topLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:4],
            
            [_inputContainer.topAnchor constraintEqualToAnchor:topLabel.bottomAnchor constant:8],
            [_inputContainer.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_inputContainer.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_inputContainer.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [_inputContainer.heightAnchor constraintEqualToConstant:55],
            
            [_blurView.topAnchor constraintEqualToAnchor:_inputContainer.topAnchor],
            [_blurView.bottomAnchor constraintEqualToAnchor:_inputContainer.bottomAnchor],
            [_blurView.leadingAnchor constraintEqualToAnchor:_inputContainer.leadingAnchor],
            [_blurView.trailingAnchor constraintEqualToAnchor:_inputContainer.trailingAnchor],
            
            [overlay.topAnchor constraintEqualToAnchor:_inputContainer.topAnchor],
            [overlay.bottomAnchor constraintEqualToAnchor:_inputContainer.bottomAnchor],
            [overlay.leadingAnchor constraintEqualToAnchor:_inputContainer.leadingAnchor],
            [overlay.trailingAnchor constraintEqualToAnchor:_inputContainer.trailingAnchor],
            
            [iconView.leadingAnchor constraintEqualToAnchor:_inputContainer.leadingAnchor constant:16],
            [iconView.centerYAnchor constraintEqualToAnchor:_inputContainer.centerYAnchor],
            [iconView.widthAnchor constraintEqualToConstant:20],
            [iconView.heightAnchor constraintEqualToConstant:20],
            
            [_textField.leadingAnchor constraintEqualToAnchor:iconView.trailingAnchor constant:12],
            [_textField.trailingAnchor constraintEqualToAnchor:_inputContainer.trailingAnchor constant:-16],
            [_textField.centerYAnchor constraintEqualToAnchor:_inputContainer.centerYAnchor],
            [_textField.heightAnchor constraintEqualToConstant:40]
        ]];
    }
    return self;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.3 animations:^{
        self.inputContainer.layer.borderColor = [ZXTheme accentPrimary].CGColor;
    }];
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.3 animations:^{
        self.inputContainer.layer.borderColor = [ZXTheme borderSubtle].CGColor;
    }];
}
@end

@interface ZXToggle : UIControl
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, strong) NSString *moduleId;
@property (nonatomic, strong) UIView *trackView;
@property (nonatomic, strong) UIView *thumbView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSLayoutConstraint *thumbLeadingConstraint;
@end

@implementation ZXToggle
- (instancetype)init {
    if (self = [super init]) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [self.widthAnchor constraintEqualToConstant:50],
            [self.heightAnchor constraintEqualToConstant:28]
        ]];
        
        _trackView = [[UIView alloc] init];
        _trackView.layer.cornerRadius = 14;
        _trackView.layer.borderWidth = 1.0;
        _trackView.layer.borderColor = [ZXTheme borderSubtle].CGColor;
        _trackView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
        _trackView.userInteractionEnabled = NO;
        _trackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_trackView];
        
        _thumbView = [[UIView alloc] init];
        _thumbView.backgroundColor = [ZXTheme textMuted];
        _thumbView.layer.cornerRadius = 10;
        _thumbView.userInteractionEnabled = NO;
        _thumbView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_thumbView];
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        _spinner.transform = CGAffineTransformMakeScale(0.6, 0.6);
        _spinner.hidesWhenStopped = YES;
        _spinner.translatesAutoresizingMaskIntoConstraints = NO;
        [_thumbView addSubview:_spinner];
        
        _thumbLeadingConstraint = [_thumbView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:4];
        
        [NSLayoutConstraint activateConstraints:@[
            [_trackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_trackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_trackView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_trackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            
            [_thumbView.widthAnchor constraintEqualToConstant:20],
            [_thumbView.heightAnchor constraintEqualToConstant:20],
            [_thumbView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            _thumbLeadingConstraint,
            
            [_spinner.centerXAnchor constraintEqualToAnchor:_thumbView.centerXAnchor],
            [_spinner.centerYAnchor constraintEqualToAnchor:_thumbView.centerYAnchor]
        ]];
        
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)]];
        [self updateStateAnimated:NO];
    }
    return self;
}
- (void)handleTap {
    if (!self.userInteractionEnabled) return;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    [self setOn:!self.isOn animated:YES];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _isOn = on;
    [self updateStateAnimated:animated];
}
- (void)updateStateAnimated:(BOOL)animated {
    self.thumbLeadingConstraint.constant = self.isOn ? 26 : 4;
    void (^stateUpdates)(void) = ^{
        [self layoutIfNeeded];
        if (self.isOn) {
            self.trackView.layer.borderColor = [ZXTheme accentSecondary].CGColor;
            self.trackView.backgroundColor = [[ZXTheme accentSecondary] colorWithAlphaComponent:0.2];
            self.thumbView.backgroundColor = [ZXTheme accentSecondary];
            self.thumbView.layer.shadowColor = [ZXTheme accentSecondary].CGColor;
            self.thumbView.layer.shadowOpacity = 0.8;
            self.thumbView.layer.shadowRadius = 5;
        } else {
            self.trackView.layer.borderColor = [ZXTheme borderSubtle].CGColor;
            self.trackView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
            self.thumbView.backgroundColor = [ZXTheme textMuted];
            self.thumbView.layer.shadowOpacity = 0.0;
        }
    };
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:stateUpdates completion:nil];
    } else {
        stateUpdates();
    }
}
- (void)setLoading:(BOOL)loading {
    self.userInteractionEnabled = !loading;
    if (loading) {
        self.thumbView.backgroundColor = [UIColor clearColor];
        self.thumbView.layer.shadowOpacity = 0.0;
        [self.spinner startAnimating];
    } else {
        [self.spinner stopAnimating];
        [self updateStateAnimated:YES];
    }
}
@end

#pragma mark - ================= MODAL & TOAST MANAGER =================

@interface ZXModalManager : NSObject
+ (void)showModalWithIcon:(NSString *)iconName iconTint:(UIColor *)tint title:(NSString *)title message:(NSString *)msg actionTitle:(NSString *)actTitle inView:(UIView *)parentView;
@end

@implementation ZXModalManager
+ (void)showModalWithIcon:(NSString *)iconName iconTint:(UIColor *)tint title:(NSString *)title message:(NSString *)msg actionTitle:(NSString *)actTitle inView:(UIView *)parentView {
    UIView *overlay = [[UIView alloc] initWithFrame:parentView.bounds];
    overlay.tag = 100100;
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    overlay.alpha = 0;
    [parentView addSubview:overlay];
    
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [ZXTheme bgInputDark];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [ZXTheme borderSubtle].CGColor;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [overlay addSubview:card];
    
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    iconView.tintColor = tint;
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:iconView];
    
    UILabel *titleLbl = [[UILabel alloc] init];
    titleLbl.text = title;
    titleLbl.textColor = [ZXTheme textPrimary];
    titleLbl.font = [ZXTheme fontHeading:18];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    titleLbl.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:titleLbl];
    
    UILabel *msgLbl = [[UILabel alloc] init];
    msgLbl.text = msg;
    msgLbl.textColor = [ZXTheme textSecondary];
    msgLbl.font = [ZXTheme fontBody:14 weight:UIFontWeightRegular];
    msgLbl.textAlignment = NSTextAlignmentCenter;
    msgLbl.numberOfLines = 0;
    msgLbl.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:msgLbl];
    
    ZXButton *btn = [[ZXButton alloc] init];
    [btn setTitle:actTitle forState:UIControlStateNormal];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:btn];
    
    [NSLayoutConstraint activateConstraints:@[
        [card.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
        [card.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [card.widthAnchor constraintEqualToConstant:300],
        
        [iconView.topAnchor constraintEqualToAnchor:card.topAnchor constant:24],
        [iconView.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [iconView.widthAnchor constraintEqualToConstant:36],
        [iconView.heightAnchor constraintEqualToConstant:36],
        
        [titleLbl.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:16],
        [titleLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [titleLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        
        [msgLbl.topAnchor constraintEqualToAnchor:titleLbl.bottomAnchor constant:8],
        [msgLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [msgLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        
        [btn.topAnchor constraintEqualToAnchor:msgLbl.bottomAnchor constant:24],
        [btn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [btn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [btn.heightAnchor constraintEqualToConstant:50],
        [btn.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20]
    ]];
    
    [btn addTarget:self action:@selector(dismissBtnTapped:) forControlEvents:UIControlEventTouchUpInside];
    [UIView animateWithDuration:0.3 animations:^{
        overlay.alpha = 1.0;
        card.transform = CGAffineTransformIdentity;
    }];
}
+ (void)dismissBtnTapped:(UIButton *)btn {
    UIView *card = btn.superview;
    UIView *overlay = card.superview;
    [UIView animateWithDuration:0.2 animations:^{
        overlay.alpha = 0;
        card.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished) {
        [overlay removeFromSuperview];
    }];
}
@end

#pragma mark - ================= MAIN VIEW CONTROLLER =================

typedef NS_ENUM(NSInteger, ZXAppState) {
    ZXAppStateInit,
    ZXAppStateSplash,
    ZXAppStateAuth,
    ZXAppStateDashboard
};

@interface ZentraxUI ()
@property (nonatomic, assign) BOOL hasCompletedInitialPresentation;
@property (nonatomic, assign) ZXAppState currentState;

@property (nonatomic, strong) ZXGridBackgroundView *gridBackground;
@property (nonatomic, strong) UIView *splashContainer;
@property (nonatomic, strong) UIView *authContainer;
@property (nonatomic, strong) UIView *dashboardContainer;

// Splash
@property (nonatomic, strong) UILabel *typewriterLabel;
@property (nonatomic, strong) NSTimer *typewriterTimer;

// Auth
@property (nonatomic, strong) ZXTextField *keyInput;
@property (nonatomic, strong) ZXButton *loginBtn;
@property (nonatomic, strong) UITapGestureRecognizer *dismissTap;

// Dashboard
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *expiryLabel;
@property (nonatomic, strong) UIStackView *modulesStackView;
@property (nonatomic, strong) UIView *emptyStateView;

// System
@property (nonatomic, strong) NSTimer *heartbeatTimer;
@property (nonatomic, strong) NSArray *cachedModulesState;
@end

@implementation ZentraxUI

- (void)dealloc {
    [_heartbeatTimer invalidate];
    [_typewriterTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [ZXTheme bgBaseDark];
    self.currentState = ZXAppStateInit;
    
    self.dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    self.dismissTap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:self.dismissTap];
    
    // 1. Setup Universal Grid Background
    _gridBackground = [[ZXGridBackgroundView alloc] initWithFrame:self.view.bounds];
    _gridBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_gridBackground];
    
    // 2. Setup Flow Containers
    [self setupSplash];
    [self setupAuth];
    [self setupDashboard];
    
    self.splashContainer.alpha = 0;
    self.authContainer.alpha = 0;
    self.dashboardContainer.alpha = 0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    if (!self.hasCompletedInitialPresentation) {
        self.hasCompletedInitialPresentation = YES;
        [self runTypewriterSplash];
    }
}

- (void)dismissKeyboard { [self.view endEditing:YES]; }

#pragma mark - Keyboard Offset
- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect kbFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect btnRect = [self.authContainer convertRect:self.loginBtn.frame toView:self.view];
    CGFloat overlap = CGRectGetMaxY(btnRect) - kbFrame.origin.y;
    if (overlap > 0) {
        [UIView animateWithDuration:duration animations:^{
            self.authContainer.transform = CGAffineTransformMakeTranslation(0, -(overlap + 20));
        }];
    }
}
- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration animations:^{
        self.authContainer.transform = CGAffineTransformIdentity;
    }];
}

#pragma mark - Smooth State Transitions
- (void)transitionToState:(ZXAppState)newState {
    if (self.currentState == newState) return;
    self.currentState = newState;
    self.dismissTap.enabled = (newState != ZXAppStateDashboard);
    
    if (newState == ZXAppStateDashboard) {
        [self startHeartbeatMonitor];
    } else {
        [self stopHeartbeatMonitor];
        self.cachedModulesState = nil;
    }
    
    // Beautiful Fade Transition over the grid
    [UIView animateWithDuration:0.6 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.splashContainer.alpha = (newState == ZXAppStateSplash) ? 1.0 : 0.0;
        self.authContainer.alpha = (newState == ZXAppStateAuth) ? 1.0 : 0.0;
        self.dashboardContainer.alpha = (newState == ZXAppStateDashboard) ? 1.0 : 0.0;
        
        if (newState == ZXAppStateDashboard) {
            self.dashboardContainer.transform = CGAffineTransformIdentity;
        } else if (newState == ZXAppStateAuth) {
            self.dashboardContainer.transform = CGAffineTransformMakeScale(0.95, 0.95); // Parallax effect
        }
    } completion:nil];
}

#pragma mark - 1. Typewriter Splash Screen
- (void)setupSplash {
    _splashContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_splashContainer];
    
    _typewriterLabel = [[UILabel alloc] init];
    _typewriterLabel.textColor = [UIColor whiteColor];
    _typewriterLabel.font = [ZXTheme fontMono:22 weight:UIFontWeightBold];
    _typewriterLabel.textAlignment = NSTextAlignmentCenter;
    _typewriterLabel.numberOfLines = 0;
    _typewriterLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_typewriterLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [_typewriterLabel.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [_typewriterLabel.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor]
    ]];
}

- (void)runTypewriterSplash {
    self.currentState = ZXAppStateSplash;
    self.splashContainer.alpha = 1.0;
    self.typewriterLabel.text = @"";
    
    NSString *fullText = @"Welcome To ZentraxPanel";
    __block int index = 0;
    
    _typewriterTimer = [NSTimer scheduledTimerWithTimeInterval:0.08 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (index < fullText.length) {
            self.typewriterLabel.text = [fullText substringToIndex:index + 1];
            index++;
        } else {
            [timer invalidate];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self transitionToState:ZXAppStateAuth];
            });
        }
    }];
}

#pragma mark - 2. Premium Login / Auth Page
- (void)setupAuth {
    _authContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_authContainer];
    
    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:card];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"ZENTRAX VIP";
    title.textColor = [ZXTheme textPrimary];
    title.font = [ZXTheme fontHeading:28];
    title.textAlignment = NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:title];
    
    UILabel *sub = [[UILabel alloc] init];
    sub.text = @"PREMIUM PANEL LOGIN";
    sub.textColor = [ZXTheme textMuted];
    sub.font = [ZXTheme fontHeading:12];
    [ZXTheme applyTextTracking:sub spacing:1.5];
    sub.textAlignment = NSTextAlignmentCenter;
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:sub];
    
    _keyInput = [[ZXTextField alloc] init];
    _keyInput.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_keyInput];
    
    _loginBtn = [[ZXButton alloc] init];
    [_loginBtn setTitle:@"Verify!" forState:UIControlStateNormal];
    [_loginBtn addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside];
    _loginBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_loginBtn];
    
    [NSLayoutConstraint activateConstraints:@[
        [card.centerYAnchor constraintEqualToAnchor:_authContainer.centerYAnchor constant:-30],
        [card.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:30],
        [card.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-30],
        
        [title.topAnchor constraintEqualToAnchor:card.topAnchor],
        [title.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        
        [sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
        [sub.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        
        [_keyInput.topAnchor constraintEqualToAnchor:sub.bottomAnchor constant:45],
        [_keyInput.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [_keyInput.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [_keyInput.heightAnchor constraintEqualToConstant:85],
        
        [_loginBtn.topAnchor constraintEqualToAnchor:_keyInput.bottomAnchor constant:30],
        [_loginBtn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [_loginBtn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [_loginBtn.heightAnchor constraintEqualToConstant:54],
        [_loginBtn.bottomAnchor constraintEqualToAnchor:card.bottomAnchor]
    ]];
}

- (void)handleLogin {
    [self dismissKeyboard];
    NSString *key = [self.keyInput.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (key.length == 0) {
        [self showToast:@"License key is required" success:NO];
        return;
    }
    
    [self.loginBtn setLoading:YES];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(zentraxDidRequestAuthenticationWithKey:completion:)]) {
            [self.delegate zentraxDidRequestAuthenticationWithKey:key completion:^(BOOL success, ZXAuthError errorType, NSString *errorMsg) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.loginBtn setLoading:NO];
                    if (success) {
                        [self showToast:@"Key Valid! Logging in..." success:YES];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                            [self transitionToState:ZXAppStateDashboard];
                        });
                    } else {
                        [self showGlobalErrorWithTitle:@"Verification Failed" message:errorMsg ?: @"Invalid License Key provided."];
                    }
                });
            }];
        }
    });
}

#pragma mark - 3. Premium Dashboard (Non-Collapsing Layout)
- (void)setupDashboard {
    _dashboardContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    _dashboardContainer.transform = CGAffineTransformMakeScale(1.05, 1.05); // For intro animation
    [self.view addSubview:_dashboardContainer];
    
    // Header
    UIView *header = [[UIView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:header];
    
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.text = @"ZENTRAX DASHBOARD";
    navTitle.textColor = [UIColor whiteColor];
    navTitle.font = [ZXTheme fontHeading:18];
    [ZXTheme applyTextTracking:navTitle spacing:2.0];
    navTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:navTitle];
    
    UIButton *logoutBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [logoutBtn setImage:[[UIImage systemImageNamed:@"rectangle.portrait.and.arrow.right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    logoutBtn.tintColor = [ZXTheme textMuted];
    logoutBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [logoutBtn addTarget:self action:@selector(handleLogout) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:logoutBtn];
    
    // License Card (Glassmorphism styling)
    UIView *statusCard = [[UIView alloc] init];
    statusCard.backgroundColor = [ZXTheme bgCardGlass];
    statusCard.layer.cornerRadius = 12;
    statusCard.layer.borderWidth = 1.0;
    statusCard.layer.borderColor = [ZXTheme borderSubtle].CGColor;
    statusCard.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    blurView.layer.cornerRadius = 12;
    blurView.clipsToBounds = YES;
    blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard insertSubview:blurView atIndex:0];
    
    [_dashboardContainer addSubview:statusCard];
    
    UILabel *subTitle = [[UILabel alloc] init];
    subTitle.text = @"LICENSE STATUS";
    subTitle.textColor = [ZXTheme textMuted];
    subTitle.font = [ZXTheme fontHeading:11];
    subTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:subTitle];
    
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.text = @"Active";
    _statusLabel.textColor = [ZXTheme statusSuccess];
    _statusLabel.font = [ZXTheme fontHeading:22];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_statusLabel];
    
    _expiryLabel = [[UILabel alloc] init];
    _expiryLabel.text = @"LIFETIME";
    _expiryLabel.textColor = [ZXTheme textSecondary];
    _expiryLabel.font = [ZXTheme fontMono:12 weight:UIFontWeightBold];
    _expiryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_expiryLabel];
    
    // Features Scroll View
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.alwaysBounceVertical = YES;
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:scrollView];
    
    _modulesStackView = [[UIStackView alloc] init];
    _modulesStackView.axis = UILayoutConstraintAxisVertical;
    _modulesStackView.spacing = 16;
    _modulesStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:_modulesStackView];
    
    [self createEmptyStateView];
    
    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:_dashboardContainer.safeAreaLayoutGuide.topAnchor constant:10],
        [header.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [header.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [header.heightAnchor constraintEqualToConstant:44],
        
        [navTitle.centerXAnchor constraintEqualToAnchor:header.centerXAnchor],
        [navTitle.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        
        [logoutBtn.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],
        [logoutBtn.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [logoutBtn.widthAnchor constraintEqualToConstant:32],
        [logoutBtn.heightAnchor constraintEqualToConstant:32],
        
        [statusCard.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:24],
        [statusCard.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [statusCard.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [statusCard.heightAnchor constraintEqualToConstant:85],
        
        [blurView.topAnchor constraintEqualToAnchor:statusCard.topAnchor],
        [blurView.bottomAnchor constraintEqualToAnchor:statusCard.bottomAnchor],
        [blurView.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor],
        [blurView.trailingAnchor constraintEqualToAnchor:statusCard.trailingAnchor],
        
        [subTitle.topAnchor constraintEqualToAnchor:statusCard.topAnchor constant:16],
        [subTitle.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:20],
        
        [_statusLabel.topAnchor constraintEqualToAnchor:subTitle.bottomAnchor constant:6],
        [_statusLabel.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:20],
        
        [_expiryLabel.centerYAnchor constraintEqualToAnchor:_statusLabel.centerYAnchor],
        [_expiryLabel.trailingAnchor constraintEqualToAnchor:statusCard.trailingAnchor constant:-20],
        
        [scrollView.topAnchor constraintEqualToAnchor:statusCard.bottomAnchor constant:24],
        [scrollView.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:_dashboardContainer.bottomAnchor],
        
        [_modulesStackView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor constant:10],
        [_modulesStackView.leadingAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.leadingAnchor constant:24],
        [_modulesStackView.trailingAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.trailingAnchor constant:-24],
        [_modulesStackView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor constant:-40]
    ]];
}

- (void)createEmptyStateView {
    _emptyStateView = [[UIView alloc] init];
    _emptyStateView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"No Active Features";
    title.textColor = [ZXTheme textMuted];
    title.font = [ZXTheme fontHeading:16];
    title.textAlignment = NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyStateView addSubview:title];
    
    [NSLayoutConstraint activateConstraints:@[
        [_emptyStateView.heightAnchor constraintEqualToConstant:200],
        [title.centerXAnchor constraintEqualToAnchor:_emptyStateView.centerXAnchor],
        [title.centerYAnchor constraintEqualToAnchor:_emptyStateView.centerYAnchor]
    ]];
}

- (void)updateDashboardWithModules:(NSArray<NSDictionary *> *)modules {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!modules || modules.count == 0) {
            if (![self.modulesStackView.arrangedSubviews containsObject:self.emptyStateView]) {
                for (UIView *v in self.modulesStackView.arrangedSubviews) [v removeFromSuperview];
                [self.modulesStackView addArrangedSubview:self.emptyStateView];
            }
            return;
        }
        
        BOOL needsRebuild = (!self.cachedModulesState || self.cachedModulesState.count != modules.count);
        self.cachedModulesState = modules;
        
        if (needsRebuild) {
            for (UIView *view in self.modulesStackView.arrangedSubviews) {
                [self.modulesStackView removeArrangedSubview:view];
                [view removeFromSuperview];
            }
            
            for (NSDictionary *mod in modules) {
                NSString *moduleName = mod[@"name"] ?: @"UNKNOWN";
                NSString *moduleDesc = mod[@"desc"] ?: mod[@"description"] ?: @"No description";
                BOOL isModOn = [mod[@"current_state"] isEqualToString:@"ON"];
                
                UIView *card = [[UIView alloc] init];
                card.backgroundColor = [ZXTheme bgCardGlass];
                card.layer.cornerRadius = 12;
                card.layer.borderWidth = 1.0;
                card.layer.borderColor = [ZXTheme borderSubtle].CGColor;
                card.translatesAutoresizingMaskIntoConstraints = NO;
                
                UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
                UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
                blurView.layer.cornerRadius = 12;
                blurView.clipsToBounds = YES;
                blurView.translatesAutoresizingMaskIntoConstraints = NO;
                [card insertSubview:blurView atIndex:0];
                
                UILabel *title = [[UILabel alloc] init];
                title.text = moduleName;
                title.textColor = [UIColor whiteColor];
                title.font = [ZXTheme fontHeading:16];
                title.translatesAutoresizingMaskIntoConstraints = NO;
                [card addSubview:title];
                
                ZXToggle *toggle = [[ZXToggle alloc] init];
                toggle.moduleId = moduleName;
                [toggle setOn:isModOn animated:NO];
                [toggle addTarget:self action:@selector(moduleToggled:) forControlEvents:UIControlEventValueChanged];
                [card addSubview:toggle];
                
                UIView *descBox = [[UIView alloc] init];
                descBox.backgroundColor = [ZXTheme bgInputDark];
                descBox.layer.cornerRadius = 6;
                descBox.translatesAutoresizingMaskIntoConstraints = NO;
                [card addSubview:descBox];
                
                UILabel *desc = [[UILabel alloc] init];
                desc.text = [moduleDesc uppercaseString];
                desc.textColor = [ZXTheme textSecondary];
                desc.font = [ZXTheme fontMono:10 weight:UIFontWeightMedium];
                desc.numberOfLines = 0;
                desc.translatesAutoresizingMaskIntoConstraints = NO;
                [descBox addSubview:desc];
                
                [NSLayoutConstraint activateConstraints:@[
                    [blurView.topAnchor constraintEqualToAnchor:card.topAnchor],
                    [blurView.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],
                    [blurView.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
                    [blurView.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
                    
                    [toggle.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
                    [toggle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
                    
                    [title.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
                    [title.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
                    [title.trailingAnchor constraintLessThanOrEqualToAnchor:toggle.leadingAnchor constant:-12],
                    
                    [descBox.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:10],
                    [descBox.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
                    [descBox.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16],
                    [descBox.trailingAnchor constraintLessThanOrEqualToAnchor:toggle.leadingAnchor constant:-12],
                    
                    [desc.topAnchor constraintEqualToAnchor:descBox.topAnchor constant:6],
                    [desc.bottomAnchor constraintEqualToAnchor:descBox.bottomAnchor constant:-6],
                    [desc.leadingAnchor constraintEqualToAnchor:descBox.leadingAnchor constant:10],
                    [desc.trailingAnchor constraintEqualToAnchor:descBox.trailingAnchor constant:-10]
                ]];
                
                [self.modulesStackView addArrangedSubview:card];
                
                card.alpha = 0;
                card.transform = CGAffineTransformMakeTranslation(0, 15);
                [UIView animateWithDuration:0.4 delay:([modules indexOfObject:mod] * 0.05) options:UIViewAnimationOptionCurveEaseOut animations:^{
                    card.alpha = 1;
                    card.transform = CGAffineTransformIdentity;
                } completion:nil];
            }
        } else {
            int index = 0;
            for (UIView *card in self.modulesStackView.arrangedSubviews) {
                if (card == self.emptyStateView) continue;
                for (UIView *sub in card.subviews) {
                    if ([sub isKindOfClass:[ZXToggle class]]) {
                        ZXToggle *toggle = (ZXToggle *)sub;
                        BOOL isModOn = [modules[index][@"current_state"] isEqualToString:@"ON"];
                        if (toggle.isOn != isModOn) {
                            [toggle setOn:isModOn animated:YES];
                        }
                    }
                }
                index++;
            }
        }
    });
}

- (void)moduleToggled:(ZXToggle *)sender {
    NSString *networkModuleId = sender.moduleId;
    if (!networkModuleId) return;
    BOOL requestedState = sender.isOn;
    [sender setLoading:YES];
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestModuleToggle:state:completion:)]) {
        [self.delegate zentraxDidRequestModuleToggle:networkModuleId state:requestedState completion:^(BOOL success, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setLoading:NO];
                if (success) {
                    [self showToast:requestedState ? @"Feature Activated" : @"Feature Deactivated" success:YES];
                } else {
                    [sender setOn:!requestedState animated:YES];
                    [self showToast:errorMsg ?: @"Action Failed" success:NO];
                }
            });
        }];
    }
}

- (void)updateSubscriptionState:(NSDictionary *)subData {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *expiryStr = subData[@"expiry"];
        self.expiryLabel.text = [expiryStr isEqualToString:@"Lifetime"] ? @"LIFETIME" : (expiryStr ?: @"--");
        NSString *s = subData[@"status"] ?: @"Active";
        self.statusLabel.text = [s capitalizedString];
        self.statusLabel.textColor = [[s lowercaseString] isEqualToString:@"active"] ? [ZXTheme statusSuccess] : [ZXTheme statusError];
    });
}

#pragma mark - Centered Cool Toast Popup
- (void)showToast:(NSString *)msg success:(BOOL)success {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *v in self.view.subviews) {
            if (v.tag == 887766) [v removeFromSuperview];
        }
        
        UIColor *tint = success ? [ZXTheme accentSecondary] : [ZXTheme statusError];
        CGFloat toastWidth = 260;
        CGFloat toastHeight = 44;
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat topInset = 55;
        
        UIView *toast = [[UIView alloc] initWithFrame:CGRectMake((screenWidth - toastWidth)/2, -60, toastWidth, toastHeight)];
        toast.tag = 887766;
        toast.backgroundColor = [ZXTheme bgInputDark];
        toast.layer.cornerRadius = 22;
        toast.layer.borderWidth = 1.0;
        toast.layer.borderColor = tint.CGColor;
        toast.layer.shadowColor = tint.CGColor;
        toast.layer.shadowOpacity = 0.5;
        toast.layer.shadowRadius = 10;
        
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, toastWidth, toastHeight)];
        lbl.text = msg;
        lbl.textColor = [UIColor whiteColor];
        lbl.font = [ZXTheme fontHeading:13];
        lbl.textAlignment = NSTextAlignmentCenter;
        [toast addSubview:lbl];
        
        [self.view addSubview:toast];
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:success ? UIImpactFeedbackStyleLight : UIImpactFeedbackStyleHeavy] impactOccurred];
        
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.6 options:UIViewAnimationOptionCurveEaseOut animations:^{
            toast.frame = CGRectMake((screenWidth - toastWidth)/2, topInset, toastWidth, toastHeight);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 delay:2.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                toast.frame = CGRectMake((screenWidth - toastWidth)/2, -60, toastWidth, toastHeight);
                toast.alpha = 0;
            } completion:^(BOOL finished) {
                [toast removeFromSuperview];
            }];
        }];
    });
}

#pragma mark - System Handlers & Delegates (Unchanged Flow)
- (void)startHeartbeatMonitor {
    [self stopHeartbeatMonitor];
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(heartbeatTick) userInfo:nil repeats:YES];
}
- (void)stopHeartbeatMonitor {
    if (self.heartbeatTimer) {
        [self.heartbeatTimer invalidate];
        self.heartbeatTimer = nil;
    }
}
- (void)heartbeatTick {
    if (self.currentState != ZXAppStateDashboard) return;
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) {
        [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL isValid) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!isValid) [self handleRevokedSessionEnvironment];
            });
        }];
    }
}
- (void)handleRevokedSessionEnvironment {
    [self stopHeartbeatMonitor];
    [self showGlobalErrorWithTitle:@"ACCESS REVOKED" message:@"Your license has been disabled or expired."];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) {
            [self.delegate zentraxDidRequestLogoutWithCompletion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.keyInput.textField.text = @"";
                    [self transitionToState:ZXAppStateAuth];
                });
            }];
        }
    });
}

- (void)handleLogout {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Disconnect Session?" message:@"Your secure connection will be closed." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Disconnect" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if ([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) {
            [self.delegate zentraxDidRequestLogoutWithCompletion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.keyInput.textField.text = @"";
                    [self transitionToState:ZXAppStateAuth];
                });
            }];
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

// Stubs for protocol adherence
- (void)setupVerification {}
- (void)showGlobalErrorWithTitle:(NSString *)title message:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        [ZXModalManager showModalWithIcon:@"exclamationmark.triangle.fill" iconTint:[ZXTheme statusError] title:title message:msg actionTitle:@"Dismiss" inView:self.view];
    });
}
- (void)showSuccessMessage:(NSString *)title message:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        [ZXModalManager showModalWithIcon:@"checkmark.shield.fill" iconTint:[ZXTheme statusSuccess] title:title message:msg actionTitle:@"Continue" inView:self.view];
    });
}
- (void)showNetworkError { [self showToast:@"Network Connection Lost" success:NO]; }
- (void)showServerError { [self showToast:@"Server Unavailable" success:NO]; }
- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds {
    NSString *msg = [NSString stringWithFormat:@"Request limits reached. Cooldown active for %ld seconds.", (long)seconds];
    dispatch_async(dispatch_get_main_queue(), ^{
        [ZXModalManager showModalWithIcon:@"timer" iconTint:[ZXTheme statusError] title:@"Rate Limited" message:msg actionTitle:@"Understood" inView:self.view];
    });
}
- (void)showGlobalLoadingState:(NSString *)message {}
- (void)hideGlobalLoadingState {}

@end
