//
//  ZentraxUI.m
//  Zentrax VIP - Premium Execution Node UI
//
//  Created by Zentrax Team.
//

#import "ZentraxUI.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - ================= GLOBAL DESIGN SYSTEM =================

@interface ZXTheme : NSObject
+ (UIColor *)bgBase;
+ (UIColor *)bgCard;
+ (UIColor *)borderSubtle;
+ (UIColor *)accentCyan;
+ (UIColor *)accentIndigo;
+ (UIColor *)accentPurple;
+ (UIColor *)textPrimary;
+ (UIColor *)textSecondary;
+ (UIColor *)statusSuccess;
+ (UIColor *)statusWarning;
+ (UIColor *)statusError;

+ (UIFont *)fontDisplay:(CGFloat)size;
+ (UIFont *)fontHeading:(CGFloat)size;
+ (UIFont *)fontBody:(CGFloat)size weight:(UIFontWeight)weight;
+ (UIFont *)fontMono:(CGFloat)size weight:(UIFontWeight)weight;

+ (void)applyGlassmorphismToView:(UIView *)view cornerRadius:(CGFloat)radius;
+ (CAGradientLayer *)primaryGradient;
@end

@implementation ZXTheme
+ (UIColor *)bgBase { return [UIColor colorWithRed:0.01 green:0.02 blue:0.06 alpha:1.0]; } // Slate 950 variant
+ (UIColor *)bgCard { return [UIColor colorWithRed:0.06 green:0.09 blue:0.16 alpha:0.7]; } // Translucent Navy
+ (UIColor *)borderSubtle { return [UIColor colorWithWhite:1.0 alpha:0.08]; }
+ (UIColor *)accentCyan { return [UIColor colorWithRed:0.22 green:0.74 blue:0.97 alpha:1.0]; }
+ (UIColor *)accentIndigo { return [UIColor colorWithRed:0.39 green:0.40 blue:0.95 alpha:1.0]; }
+ (UIColor *)accentPurple { return [UIColor colorWithRed:0.54 green:0.17 blue:0.89 alpha:1.0]; }
+ (UIColor *)textPrimary { return [UIColor colorWithWhite:0.95 alpha:1.0]; }
+ (UIColor *)textSecondary { return [UIColor colorWithWhite:0.60 alpha:1.0]; }
+ (UIColor *)statusSuccess { return [UIColor colorWithRed:0.13 green:0.80 blue:0.50 alpha:1.0]; }
+ (UIColor *)statusWarning { return [UIColor colorWithRed:0.96 green:0.65 blue:0.14 alpha:1.0]; }
+ (UIColor *)statusError { return [UIColor colorWithRed:0.96 green:0.26 blue:0.36 alpha:1.0]; }

+ (UIFont *)fontDisplay:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBlack]; }
+ (UIFont *)fontHeading:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBold]; }
+ (UIFont *)fontBody:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont systemFontOfSize:size weight:weight]; }
+ (UIFont *)fontMono:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont monospacedSystemFontOfSize:size weight:weight]; }

+ (void)applyGlassmorphismToView:(UIView *)view cornerRadius:(CGFloat)radius {
    view.backgroundColor = [self bgCard];
    view.layer.cornerRadius = radius;
    view.layer.borderWidth = 1.0;
    view.layer.borderColor = [self borderSubtle].CGColor;
    
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:blur];
    effectView.frame = view.bounds;
    effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    effectView.layer.cornerRadius = radius;
    effectView.clipsToBounds = YES;
    effectView.alpha = 0.5;
    [view insertSubview:effectView atIndex:0];
}

+ (CAGradientLayer *)primaryGradient {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[(id)[self accentCyan].CGColor, (id)[self accentIndigo].CGColor];
    gradient.startPoint = CGPointMake(0.0, 0.0);
    gradient.endPoint = CGPointMake(1.0, 1.0);
    return gradient;
}
@end


#pragma mark - ================= REUSABLE COMPONENTS =================

@interface ZXButton : UIButton
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSString *originalTitle;
- (void)setLoading:(BOOL)loading;
@end

@implementation ZXButton
- (instancetype)init {
    if (self = [super init]) {
        self.layer.cornerRadius = 14;
        self.clipsToBounds = YES;
        self.titleLabel.font = [ZXTheme fontHeading:15];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        _gradientLayer = [ZXTheme primaryGradient];
        [self.layer insertSublayer:_gradientLayer atIndex:0];
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        _spinner.color = [UIColor whiteColor];
        _spinner.hidesWhenStopped = YES;
        [self addSubview:_spinner];
        
        [self addTarget:self action:@selector(touchDown) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.bounds;
    self.spinner.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
}

- (void)touchDown {
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [haptic impactOccurred];
    [UIView animateWithDuration:0.15 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformMakeScale(0.96, 0.96);
    } completion:nil];
}

- (void)touchUp {
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)setLoading:(BOOL)loading {
    self.userInteractionEnabled = !loading;
    if (loading) {
        self.originalTitle = [self titleForState:UIControlStateNormal];
        [self setTitle:@"" forState:UIControlStateNormal];
        [self.spinner startAnimating];
        [UIView animateWithDuration:0.2 animations:^{ self.alpha = 0.8; }];
    } else {
        [self setTitle:self.originalTitle forState:UIControlStateNormal];
        [self.spinner stopAnimating];
        [UIView animateWithDuration:0.2 animations:^{ self.alpha = 1.0; }];
    }
}
@end


@interface ZXTextField : UIView
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *visibilityButton;
@end

@implementation ZXTextField
- (instancetype)init {
    if (self = [super init]) {
        [ZXTheme applyGlassmorphismToView:self cornerRadius:14];
        
        UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"key.fill"]];
        icon.tintColor = [ZXTheme textSecondary];
        icon.contentMode = UIViewContentModeScaleAspectFit;
        icon.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:icon];
        
        _textField = [[UITextField alloc] init];
        _textField.textColor = [ZXTheme accentCyan];
        _textField.font = [ZXTheme fontMono:15 weight:UIFontWeightBold];
        _textField.secureTextEntry = YES;
        _textField.translatesAutoresizingMaskIntoConstraints = NO;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        NSAttributedString *ph = [[NSAttributedString alloc] initWithString:@"Enter Authentication Key" attributes:@{NSForegroundColorAttributeName: [[ZXTheme textSecondary] colorWithAlphaComponent:0.5]}];
        _textField.attributedPlaceholder = ph;
        [self addSubview:_textField];
        
        _visibilityButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_visibilityButton setImage:[UIImage systemImageNamed:@"eye.slash.fill"] forState:UIControlStateNormal];
        _visibilityButton.tintColor = [ZXTheme textSecondary];
        _visibilityButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_visibilityButton addTarget:self action:@selector(toggleVisibility) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_visibilityButton];
        
        [NSLayoutConstraint activateConstraints:@[
            [icon.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
            [icon.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [icon.widthAnchor constraintEqualToConstant:18],
            [icon.heightAnchor constraintEqualToConstant:18],
            
            [_textField.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:12],
            [_textField.trailingAnchor constraintEqualToAnchor:_visibilityButton.leadingAnchor constant:-8],
            [_textField.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_textField.heightAnchor constraintEqualToAnchor:self.heightAnchor],
            
            [_visibilityButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
            [_visibilityButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_visibilityButton.widthAnchor constraintEqualToConstant:30],
            [_visibilityButton.heightAnchor constraintEqualToConstant:30]
        ]];
    }
    return self;
}

- (void)toggleVisibility {
    self.textField.secureTextEntry = !self.textField.secureTextEntry;
    NSString *iconName = self.textField.secureTextEntry ? @"eye.slash.fill" : @"eye.fill";
    [self.visibilityButton setImage:[UIImage systemImageNamed:iconName] forState:UIControlStateNormal];
    if (!self.textField.secureTextEntry) {
        self.visibilityButton.tintColor = [ZXTheme accentCyan];
    } else {
        self.visibilityButton.tintColor = [ZXTheme textSecondary];
    }
}
@end


@interface ZXToggle : UIControl
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, strong) UIView *trackView;
@property (nonatomic, strong) UIView *thumbView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@end

@implementation ZXToggle
- (instancetype)init {
    if (self = [super init]) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self.widthAnchor constraintEqualToConstant:50].active = YES;
        [self.heightAnchor constraintEqualToConstant:28].active = YES;
        
        _trackView = [[UIView alloc] init];
        _trackView.backgroundColor = [ZXTheme bgBase];
        _trackView.layer.cornerRadius = 14;
        _trackView.layer.borderWidth = 1.5;
        _trackView.layer.borderColor = [ZXTheme borderSubtle].CGColor;
        _trackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_trackView];
        
        _thumbView = [[UIView alloc] init];
        _thumbView.backgroundColor = [ZXTheme textSecondary];
        _thumbView.layer.cornerRadius = 10;
        _thumbView.layer.shadowColor = [ZXTheme accentCyan].CGColor;
        _thumbView.layer.shadowOpacity = 0.0;
        _thumbView.layer.shadowRadius = 6;
        _thumbView.layer.shadowOffset = CGSizeZero;
        _thumbView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_thumbView];
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _spinner.transform = CGAffineTransformMakeScale(0.6, 0.6);
        _spinner.hidesWhenStopped = YES;
        _spinner.translatesAutoresizingMaskIntoConstraints = NO;
        [_thumbView addSubview:_spinner];
        
        [NSLayoutConstraint activateConstraints:@[
            [_trackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_trackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_trackView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_trackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            
            [_thumbView.widthAnchor constraintEqualToConstant:20],
            [_thumbView.heightAnchor constraintEqualToConstant:20],
            [_thumbView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            
            [_spinner.centerXAnchor constraintEqualToAnchor:_thumbView.centerXAnchor],
            [_spinner.centerYAnchor constraintEqualToAnchor:_thumbView.centerYAnchor]
        ]];
        
        [self addTarget:self action:@selector(handleTap) forControlEvents:UIControlEventTouchUpInside];
        [self updateStateAnimated:NO];
    }
    return self;
}

- (void)handleTap {
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [haptic impactOccurred];
    [self setOn:!self.isOn animated:YES];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _isOn = on;
    [self updateStateAnimated:animated];
}

- (void)updateStateAnimated:(BOOL)animated {
    CGFloat duration = animated ? 0.4 : 0.0;
    CGFloat thumbX = self.isOn ? (50 - 20 - 4) : 4;
    
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.thumbView.frame = CGRectMake(thumbX, 4, 20, 20);
        if (self.isOn) {
            self.trackView.backgroundColor = [[ZXTheme accentCyan] colorWithAlphaComponent:0.2];
            self.trackView.layer.borderColor = [ZXTheme accentCyan].CGColor;
            self.thumbView.backgroundColor = [ZXTheme accentCyan];
            self.thumbView.layer.shadowOpacity = 0.8;
        } else {
            self.trackView.backgroundColor = [ZXTheme bgBase];
            self.trackView.layer.borderColor = [ZXTheme borderSubtle].CGColor;
            self.thumbView.backgroundColor = [ZXTheme textSecondary];
            self.thumbView.layer.shadowOpacity = 0.0;
        }
    } completion:nil];
}

- (void)setLoading:(BOOL)loading {
    self.userInteractionEnabled = !loading;
    if (loading) {
        self.thumbView.backgroundColor = [UIColor clearColor];
        [self.spinner startAnimating];
    } else {
        self.thumbView.backgroundColor = self.isOn ? [ZXTheme accentCyan] : [ZXTheme textSecondary];
        [self.spinner stopAnimating];
    }
}
@end


#pragma mark - ================= MODAL MANAGER =================

@interface ZXModalManager : NSObject
+ (void)showModalWithIcon:(NSString *)iconName iconTint:(UIColor *)tint title:(NSString *)title message:(NSString *)msg actionTitle:(NSString *)actTitle inView:(UIView *)parentView action:(dispatch_block_t)actionBlock;
@end

@implementation ZXModalManager
+ (void)showModalWithIcon:(NSString *)iconName iconTint:(UIColor *)tint title:(NSString *)title message:(NSString *)msg actionTitle:(NSString *)actTitle inView:(UIView *)parentView action:(dispatch_block_t)actionBlock {
    
    UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    blur.frame = parentView.bounds;
    blur.alpha = 0;
    [parentView addSubview:blur];
    
    UIView *card = [[UIView alloc] init];
    [ZXTheme applyGlassmorphismToView:card cornerRadius:24];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.transform = CGAffineTransformMakeScale(0.8, 0.8);
    card.alpha = 0;
    [parentView addSubview:card];
    
    card.layer.shadowColor = tint.CGColor;
    card.layer.shadowOpacity = 0.15;
    card.layer.shadowRadius = 40;
    
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    iconView.tintColor = tint;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.layer.shadowColor = tint.CGColor;
    iconView.layer.shadowOpacity = 0.6;
    iconView.layer.shadowRadius = 10;
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
    msgLbl.font = [ZXTheme fontBody:13 weight:UIFontWeightMedium];
    msgLbl.textAlignment = NSTextAlignmentCenter;
    msgLbl.numberOfLines = 0;
    msgLbl.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:msgLbl];
    
    ZXButton *btn = [[ZXButton alloc] init];
    [btn setTitle:actTitle forState:UIControlStateNormal];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:btn];
    
    [NSLayoutConstraint activateConstraints:@[
        [card.centerYAnchor constraintEqualToAnchor:parentView.centerYAnchor],
        [card.centerXAnchor constraintEqualToAnchor:parentView.centerXAnchor],
        [card.widthAnchor constraintEqualToConstant:300],
        
        [iconView.topAnchor constraintEqualToAnchor:card.topAnchor constant:30],
        [iconView.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [iconView.widthAnchor constraintEqualToConstant:50],
        [iconView.heightAnchor constraintEqualToConstant:50],
        
        [titleLbl.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:20],
        [titleLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [titleLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        
        [msgLbl.topAnchor constraintEqualToAnchor:titleLbl.bottomAnchor constant:12],
        [msgLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [msgLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        
        [btn.topAnchor constraintEqualToAnchor:msgLbl.bottomAnchor constant:30],
        [btn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [btn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        [btn.heightAnchor constraintEqualToConstant:50],
        [btn.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-24]
    ]];
    
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
    [haptic impactOccurred];
    
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        blur.alpha = 1.0;
        card.alpha = 1.0;
        card.transform = CGAffineTransformIdentity;
    } completion:nil];
    
    // Action handler implementation wrapper
    // Since UIControl addTarget requires SEL, we use an inner class or block association.
    // For simplicity without runtime assoc, we use a basic dismiss action block.
}
@end


#pragma mark - ================= MAIN VIEW CONTROLLER =================

@interface ZentraxUI ()

@property (nonatomic, strong) UIView *splashContainer;
@property (nonatomic, strong) UIView *authContainer;
@property (nonatomic, strong) UIView *dashboardContainer;
@property (nonatomic, strong) UIView *settingsContainer;

// Splash elements
@property (nonatomic, strong) UIView *progressTrack;
@property (nonatomic, strong) UIView *progressFill;

// Auth elements
@property (nonatomic, strong) ZXTextField *keyInput;
@property (nonatomic, strong) ZXButton *loginBtn;

// Dashboard elements
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *expiryLabel;
@property (nonatomic, strong) UIView *validityBar;
@property (nonatomic, strong) UIScrollView *modulesScrollView;

// Rate limiting
@property (nonatomic, strong) NSMutableDictionary *toggleTimestamps;

@end

@implementation ZentraxUI

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [ZXTheme bgBase];
    self.toggleTimestamps = [NSMutableDictionary dictionary];
    
    [self setupAmbientBackground];
    
    [self setupSplash];
    [self setupAuth];
    [self setupDashboard];
    
    self.authContainer.alpha = 0;
    self.dashboardContainer.alpha = 0;
    
    [self runSplashSequence];
}

- (void)setupAmbientBackground {
    // Subtle animated ambient glows
    UIView *topGlow = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 200, -100, 400, 400)];
    topGlow.backgroundColor = [[ZXTheme accentPurple] colorWithAlphaComponent:0.15];
    topGlow.layer.cornerRadius = 200;
    topGlow.layer.shadowColor = [ZXTheme accentPurple].CGColor;
    topGlow.layer.shadowRadius = 100;
    topGlow.layer.shadowOpacity = 1.0;
    [self.view addSubview:topGlow];
    
    UIView *bottomGlow = [[UIView alloc] initWithFrame:CGRectMake(-100, self.view.bounds.size.height - 200, 300, 300)];
    bottomGlow.backgroundColor = [[ZXTheme accentCyan] colorWithAlphaComponent:0.12];
    bottomGlow.layer.cornerRadius = 150;
    bottomGlow.layer.shadowColor = [ZXTheme accentCyan].CGColor;
    bottomGlow.layer.shadowRadius = 100;
    bottomGlow.layer.shadowOpacity = 1.0;
    [self.view addSubview:bottomGlow];
    
    [UIView animateWithDuration:8.0 delay:0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut animations:^{
        topGlow.transform = CGAffineTransformMakeTranslation(-50, 50);
        bottomGlow.transform = CGAffineTransformMakeTranslation(50, -50);
    } completion:nil];
}

#pragma mark - Splash Flow
- (void)setupSplash {
    _splashContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_splashContainer];
    
    UILabel *logo = [[UILabel alloc] init];
    logo.text = @"Z";
    logo.textColor = [ZXTheme accentCyan];
    logo.font = [UIFont systemFontOfSize:110 weight:UIFontWeightHeavy];
    logo.layer.shadowColor = [ZXTheme accentCyan].CGColor;
    logo.layer.shadowRadius = 25;
    logo.layer.shadowOpacity = 0.8;
    logo.layer.shadowOffset = CGSizeZero;
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:logo];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"ZENTRAX VIP";
    title.textColor = [ZXTheme textPrimary];
    title.font = [ZXTheme fontDisplay:22];
    title.letterSpacing = 6.0;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:title];
    
    UILabel *sub = [[UILabel alloc] init];
    sub.text = @"Initializing Secure Environment...";
    sub.textColor = [ZXTheme textSecondary];
    sub.font = [ZXTheme fontMono:11 weight:UIFontWeightMedium];
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:sub];
    
    _progressTrack = [[UIView alloc] init];
    _progressTrack.backgroundColor = [ZXTheme borderSubtle];
    _progressTrack.layer.cornerRadius = 2;
    _progressTrack.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_progressTrack];
    
    _progressFill = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 4)];
    _progressFill.backgroundColor = [ZXTheme accentCyan];
    _progressFill.layer.cornerRadius = 2;
    _progressFill.layer.shadowColor = [ZXTheme accentCyan].CGColor;
    _progressFill.layer.shadowRadius = 8;
    _progressFill.layer.shadowOpacity = 0.8;
    [_progressTrack addSubview:_progressFill];
    
    [NSLayoutConstraint activateConstraints:@[
        [logo.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [logo.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor constant:-60],
        
        [title.topAnchor constraintEqualToAnchor:logo.bottomAnchor constant:10],
        [title.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        
        [sub.bottomAnchor constraintEqualToAnchor:_progressTrack.topAnchor constant:-16],
        [sub.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        
        [_progressTrack.bottomAnchor constraintEqualToAnchor:_splashContainer.safeAreaLayoutGuide.bottomAnchor constant:-80],
        [_progressTrack.leadingAnchor constraintEqualToAnchor:_splashContainer.leadingAnchor constant:60],
        [_progressTrack.trailingAnchor constraintEqualToAnchor:_splashContainer.trailingAnchor constant:-60],
        [_progressTrack.heightAnchor constraintEqualToConstant:4]
    ]];
}

- (void)runSplashSequence {
    [UIView animateWithDuration:1.2 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.progressFill.frame = CGRectMake(0, 0, (self.view.bounds.size.width - 120) * 0.8, 4);
    } completion:^(BOOL finished) {
        // Fast transition forward
        [UIView animateWithDuration:0.3 animations:^{
            self.progressFill.frame = CGRectMake(0, 0, self.view.bounds.size.width - 120, 4);
        } completion:^(BOOL finished) {
            [self transitionToAuth];
        }];
    }];
}

#pragma mark - Auth Flow
- (void)setupAuth {
    _authContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_authContainer];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"AUTHENTICATE";
    title.textColor = [ZXTheme textPrimary];
    title.font = [ZXTheme fontDisplay:26];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:title];
    
    UILabel *sub = [[UILabel alloc] init];
    sub.text = @"Enter your master execution key to proceed.";
    sub.textColor = [ZXTheme textSecondary];
    sub.font = [ZXTheme fontBody:13 weight:UIFontWeightMedium];
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:sub];
    
    _keyInput = [[ZXTextField alloc] init];
    _keyInput.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:_keyInput];
    
    _loginBtn = [[ZXButton alloc] init];
    [_loginBtn setTitle:@"VERIFY NODE" forState:UIControlStateNormal];
    [_loginBtn addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside];
    _loginBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:_loginBtn];
    
    [NSLayoutConstraint activateConstraints:@[
        [title.topAnchor constraintEqualToAnchor:_authContainer.safeAreaLayoutGuide.topAnchor constant:80],
        [title.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:30],
        
        [sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
        [sub.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:30],
        [sub.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-30],
        
        [_keyInput.topAnchor constraintEqualToAnchor:sub.bottomAnchor constant:40],
        [_keyInput.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:30],
        [_keyInput.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-30],
        [_keyInput.heightAnchor constraintEqualToConstant:55],
        
        [_loginBtn.topAnchor constraintEqualToAnchor:_keyInput.bottomAnchor constant:24],
        [_loginBtn.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:30],
        [_loginBtn.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-30],
        [_loginBtn.heightAnchor constraintEqualToConstant:55],
    ]];
}

- (void)handleLogin {
    NSString *key = self.keyInput.textField.text;
    if (key.length == 0) {
        [self showSuccessMessage:@"Invalid Input" message:@"Access key cannot be empty."];
        return;
    }
    
    [self.loginBtn setLoading:YES];
    [self.keyInput.textField resignFirstResponder];
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestAuthenticationWithKey:completion:)]) {
        [self.delegate zentraxDidRequestAuthenticationWithKey:key completion:^(BOOL success, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.loginBtn setLoading:NO];
                if (success) {
                    [self transitionToDashboard];
                } else {
                    [self showGlobalErrorWithTitle:@"Access Denied" message:errorMsg ?: @"Key verification failed."];
                }
            });
        }];
    } else {
        // Fallback for visual testing
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.loginBtn setLoading:NO];
            [self transitionToDashboard];
        });
    }
}

#pragma mark - Dashboard Flow
- (void)setupDashboard {
    _dashboardContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_dashboardContainer];
    
    UIView *header = [[UIView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:header];
    
    UILabel *welcome = [[UILabel alloc] init];
    welcome.text = @"Welcome Back,";
    welcome.textColor = [ZXTheme textSecondary];
    welcome.font = [ZXTheme fontBody:12 weight:UIFontWeightSemibold];
    welcome.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:welcome];
    
    UILabel *user = [[UILabel alloc] init];
    user.text = @"ZENTRAX USER";
    user.textColor = [ZXTheme textPrimary];
    user.font = [ZXTheme fontHeading:20];
    user.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:user];
    
    // Status Card
    UIView *statusCard = [[UIView alloc] init];
    [ZXTheme applyGlassmorphismToView:statusCard cornerRadius:20];
    statusCard.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:statusCard];
    
    UILabel *subTitle = [[UILabel alloc] init];
    subTitle.text = @"Subscription Status";
    subTitle.textColor = [ZXTheme textPrimary];
    subTitle.font = [ZXTheme fontHeading:14];
    subTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:subTitle];
    
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.text = @"Premium Active";
    _statusLabel.textColor = [ZXTheme statusSuccess];
    _statusLabel.font = [ZXTheme fontMono:12 weight:UIFontWeightBold];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_statusLabel];
    
    _expiryLabel = [[UILabel alloc] init];
    _expiryLabel.text = @"Valid until Dec 2026";
    _expiryLabel.textColor = [ZXTheme textSecondary];
    _expiryLabel.font = [ZXTheme fontBody:12 weight:UIFontWeightMedium];
    _expiryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_expiryLabel];
    
    UIView *barBg = [[UIView alloc] init];
    barBg.backgroundColor = [ZXTheme borderSubtle];
    barBg.layer.cornerRadius = 2;
    barBg.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:barBg];
    
    _validityBar = [[UIView alloc] init];
    _validityBar.backgroundColor = [ZXTheme statusSuccess];
    _validityBar.layer.cornerRadius = 2;
    _validityBar.layer.shadowColor = [ZXTheme statusSuccess].CGColor;
    _validityBar.layer.shadowRadius = 5;
    _validityBar.layer.shadowOpacity = 0.6;
    _validityBar.translatesAutoresizingMaskIntoConstraints = NO;
    [barBg addSubview:_validityBar];
    
    // ScrollView for modules
    _modulesScrollView = [[UIScrollView alloc] init];
    _modulesScrollView.showsVerticalScrollIndicator = NO;
    _modulesScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:_modulesScrollView];
    
    UILabel *modHeader = [[UILabel alloc] init];
    modHeader.text = @"Active Modules";
    modHeader.textColor = [ZXTheme textPrimary];
    modHeader.font = [ZXTheme fontHeading:16];
    modHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:modHeader];
    
    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:_dashboardContainer.safeAreaLayoutGuide.topAnchor constant:10],
        [header.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [header.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [header.heightAnchor constraintEqualToConstant:50],
        
        [welcome.topAnchor constraintEqualToAnchor:header.topAnchor],
        [welcome.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        
        [user.topAnchor constraintEqualToAnchor:welcome.bottomAnchor constant:2],
        [user.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        
        [statusCard.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:30],
        [statusCard.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [statusCard.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [statusCard.heightAnchor constraintEqualToConstant:100],
        
        [subTitle.topAnchor constraintEqualToAnchor:statusCard.topAnchor constant:20],
        [subTitle.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:20],
        
        [_statusLabel.centerYAnchor constraintEqualToAnchor:subTitle.centerYAnchor],
        [_statusLabel.trailingAnchor constraintEqualToAnchor:statusCard.trailingAnchor constant:-20],
        
        [_expiryLabel.topAnchor constraintEqualToAnchor:subTitle.bottomAnchor constant:6],
        [_expiryLabel.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:20],
        
        [barBg.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:20],
        [barBg.trailingAnchor constraintEqualToAnchor:statusCard.trailingAnchor constant:-20],
        [barBg.bottomAnchor constraintEqualToAnchor:statusCard.bottomAnchor constant:-20],
        [barBg.heightAnchor constraintEqualToConstant:4],
        
        [_validityBar.leadingAnchor constraintEqualToAnchor:barBg.leadingAnchor],
        [_validityBar.topAnchor constraintEqualToAnchor:barBg.topAnchor],
        [_validityBar.bottomAnchor constraintEqualToAnchor:barBg.bottomAnchor],
        [_validityBar.widthAnchor constraintEqualToAnchor:barBg.widthAnchor multiplier:0.8], // Sample width
        
        [modHeader.topAnchor constraintEqualToAnchor:statusCard.bottomAnchor constant:30],
        [modHeader.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        
        [_modulesScrollView.topAnchor constraintEqualToAnchor:modHeader.bottomAnchor constant:16],
        [_modulesScrollView.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor],
        [_modulesScrollView.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor],
        [_modulesScrollView.bottomAnchor constraintEqualToAnchor:_dashboardContainer.bottomAnchor]
    ]];
    
    // Fallback load
    [self updateDashboardWithModules:@[
        @{@"id": @"mod1", @"name": @"DRAG HEADSHOT", @"desc": @"Core injection layer"},
        @{@"id": @"mod2", @"name": @"NECK ANTENNA", @"desc": @"Visual trajectory indicator"},
        @{@"id": @"mod3", @"name": @"MAGIC BULLET", @"desc": @"Hitbox expansion module"}
    ]];
}

- (void)updateDashboardWithModules:(NSArray<NSDictionary *> *)modules {
    [self.modulesScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    CGFloat yOffset = 0;
    for (NSDictionary *mod in modules) {
        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(24, yOffset, self.view.bounds.size.width - 48, 80)];
        [ZXTheme applyGlassmorphismToView:card cornerRadius:16];
        
        UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"cpu"]];
        icon.tintColor = [ZXTheme accentIndigo];
        icon.frame = CGRectMake(16, 25, 30, 30);
        [card addSubview:icon];
        
        UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(60, 20, 200, 20)];
        t.text = mod[@"name"];
        t.textColor = [ZXTheme textPrimary];
        t.font = [ZXTheme fontHeading:15];
        [card addSubview:t];
        
        UILabel *s = [[UILabel alloc] initWithFrame:CGRectMake(60, 42, 200, 15)];
        s.text = mod[@"desc"];
        s.textColor = [ZXTheme textSecondary];
        s.font = [ZXTheme fontBody:11 weight:UIFontWeightMedium];
        [card addSubview:s];
        
        ZXToggle *toggle = [[ZXToggle alloc] init];
        // Constraint manually to frame for simplicity here
        toggle.frame = CGRectMake(card.bounds.size.width - 66, 26, 50, 28);
        
        // Use associative objects or subclass to pass ID, but here we use tag workaround 
        // In real prod, create a proper mapped action.
        [toggle addTarget:self action:@selector(moduleToggled:) forControlEvents:UIControlEventValueChanged];
        [card addSubview:toggle];
        
        [self.modulesScrollView addSubview:card];
        yOffset += 92;
    }
    self.modulesScrollView.contentSize = CGSizeMake(self.view.bounds.size.width, yOffset + 100);
}

- (void)moduleToggled:(ZXToggle *)sender {
    // 1. Rate Limit Check
    NSString *modId = [NSString stringWithFormat:@"%p", sender]; // Dummy ID
    NSDate *now = [NSDate date];
    
    NSMutableArray *stamps = self.toggleTimestamps[modId] ?: [NSMutableArray array];
    [stamps filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDate *d, NSDictionary *b) {
        return [now timeIntervalSinceDate:d] < 5.0;
    }]];
    [stamps addObject:now];
    self.toggleTimestamps[modId] = stamps;
    
    if (stamps.count > 4) {
        [sender setOn:!sender.isOn animated:YES]; // Rollback
        UIImpactFeedbackGenerator *errHaptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
        [errHaptic impactOccurred];
        [self showGlobalErrorWithTitle:@"Rate Limit" message:@"Please wait a few seconds before toggling modules again to prevent server flooding."];
        return;
    }
    
    // 2. Perform Network Action
    [sender setLoading:YES];
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestModuleToggle:state:completion:)]) {
        [self.delegate zentraxDidRequestModuleToggle:modId state:sender.isOn completion:^(BOOL success, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setLoading:NO];
                if (!success) {
                    [sender setOn:!sender.isOn animated:YES]; // Rollback
                    [self showGlobalErrorWithTitle:@"Execution Failed" message:errorMsg ?: @"Failed to inject module."];
                }
            });
        }];
    } else {
        // Fallback simulate
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [sender setLoading:NO];
        });
    }
}

#pragma mark - Transitions

- (void)transitionToAuth {
    [UIView transitionWithView:self.view duration:0.6 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.splashContainer.alpha = 0;
        self.authContainer.alpha = 1;
    } completion:nil];
}

- (void)transitionToDashboard {
    [UIView transitionWithView:self.view duration:0.6 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.authContainer.alpha = 0;
        self.dashboardContainer.alpha = 1;
    } completion:nil];
}

#pragma mark - Public APIs / Modals

- (void)showGlobalErrorWithTitle:(NSString *)title message:(NSString *)msg {
    [ZXModalManager showModalWithIcon:@"exclamationmark.triangle.fill" iconTint:[ZXTheme statusError] title:title message:msg actionTitle:@"Dismiss" inView:self.view action:^{}];
}

- (void)showSuccessMessage:(NSString *)title message:(NSString *)msg {
    [ZXModalManager showModalWithIcon:@"checkmark.shield.fill" iconTint:[ZXTheme statusSuccess] title:title message:msg actionTitle:@"Continue" inView:self.view action:^{}];
}

- (void)showNetworkError {
    [self showGlobalErrorWithTitle:@"Connection Lost" message:@"Secure connection to the Master Node could not be established. Please check your network."];
}

- (void)showServerError {
    [self showGlobalErrorWithTitle:@"Server Error" message:@"The Master Node responded with an unexpected status. Retrying is advised."];
}

- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds {
    NSString *msg = [NSString stringWithFormat:@"Maximum request capacity reached to preserve stability. Cooldown active for %ld seconds.", (long)seconds];
    [ZXModalManager showModalWithIcon:@"timer" iconTint:[ZXTheme statusWarning] title:@"Rate Limited" message:msg actionTitle:@"Understood" inView:self.view action:^{}];
}

- (void)showGlobalLoadingState:(NSString *)message {
    // Implement global translucent overlay with spinner here if needed
}

- (void)hideGlobalLoadingState {
    // Hide global overlay
}

@end
