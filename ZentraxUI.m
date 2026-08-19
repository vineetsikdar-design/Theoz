//
//  ZentraxUI.m
//  Zentrax VIP - Premium Execution Node UI
//
//  Created by Zentrax Team.
//  Environment: Deep Space Blue / Glassmorphism
//  Status: PRODUCTION READY (Strictly Dynamic Data)
//

#import "ZentraxUI.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - ================= GLOBAL DESIGN SYSTEM =================

@interface ZXTheme : NSObject
+ (UIColor *)bgDeepSpace;
+ (UIColor *)bgCardInner;
+ (UIColor *)bgCardOuter;
+ (UIColor *)borderSubtle;
+ (UIColor *)borderActive;
+ (UIColor *)accentCyan;
+ (UIColor *)accentNeonBlue;
+ (UIColor *)textPrimary;
+ (UIColor *)textSecondary;
+ (UIColor *)textMuted;
+ (UIColor *)statusSuccess;
+ (UIColor *)statusWarning;
+ (UIColor *)statusError;

+ (UIFont *)fontDisplay:(CGFloat)size;
+ (UIFont *)fontHeading:(CGFloat)size;
+ (UIFont *)fontBody:(CGFloat)size weight:(UIFontWeight)weight;
+ (UIFont *)fontMono:(CGFloat)size weight:(UIFontWeight)weight;

+ (void)applyPremiumGlassmorphismToView:(UIView *)view cornerRadius:(CGFloat)radius;
+ (void)applyTextTracking:(UILabel *)label spacing:(CGFloat)spacing;
+ (CAGradientLayer *)electricGradient;
@end

@implementation ZXTheme

// Multi-layer Deep Blue Environment
+ (UIColor *)bgDeepSpace { return [UIColor colorWithRed:0.02 green:0.03 blue:0.06 alpha:1.0]; }
+ (UIColor *)bgCardOuter { return [UIColor colorWithRed:0.06 green:0.08 blue:0.14 alpha:0.45]; }
+ (UIColor *)bgCardInner { return [UIColor colorWithRed:0.08 green:0.11 blue:0.18 alpha:0.60]; }
+ (UIColor *)borderSubtle { return [UIColor colorWithWhite:1.0 alpha:0.05]; }
+ (UIColor *)borderActive { return [UIColor colorWithWhite:1.0 alpha:0.15]; }

// Precision Lighting
+ (UIColor *)accentCyan { return [UIColor colorWithRed:0.0 green:0.85 blue:1.0 alpha:1.0]; }
+ (UIColor *)accentNeonBlue { return [UIColor colorWithRed:0.15 green:0.35 blue:1.0 alpha:1.0]; }

// Hierarchy Typography Colors
+ (UIColor *)textPrimary { return [UIColor colorWithWhite:0.98 alpha:1.0]; }
+ (UIColor *)textSecondary { return [UIColor colorWithWhite:0.70 alpha:1.0]; }
+ (UIColor *)textMuted { return [UIColor colorWithWhite:0.45 alpha:1.0]; }

// Status
+ (UIColor *)statusSuccess { return [UIColor colorWithRed:0.15 green:0.85 blue:0.55 alpha:1.0]; }
+ (UIColor *)statusWarning { return [UIColor colorWithRed:0.96 green:0.65 blue:0.14 alpha:1.0]; }
+ (UIColor *)statusError { return [UIColor colorWithRed:1.0 green:0.25 blue:0.35 alpha:1.0]; }

// Cinematic Typography
+ (UIFont *)fontDisplay:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBlack]; }
+ (UIFont *)fontHeading:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBold]; }
+ (UIFont *)fontBody:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont systemFontOfSize:size weight:weight]; }
+ (UIFont *)fontMono:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont monospacedSystemFontOfSize:size weight:weight]; }

// Solves the letterSpacing crash
+ (void)applyTextTracking:(UILabel *)label spacing:(CGFloat)spacing {
    if (!label.text) return;
    NSDictionary *attrs = @{NSKernAttributeName: @(spacing)};
    label.attributedText = [[NSAttributedString alloc] initWithString:label.text attributes:attrs];
}

// Advanced Multi-Layer Glass
+ (void)applyPremiumGlassmorphismToView:(UIView *)view cornerRadius:(CGFloat)radius {
    view.backgroundColor = [self bgCardOuter];
    view.layer.cornerRadius = radius;
    view.layer.borderWidth = 0.5;
    view.layer.borderColor = [self borderSubtle].CGColor;
    
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:blur];
    effectView.frame = view.bounds;
    effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    effectView.layer.cornerRadius = radius;
    effectView.clipsToBounds = YES;
    effectView.alpha = 0.95; // Deep blur
    [view insertSubview:effectView atIndex:0];
    
    // Inner Glow Layer
    UIView *innerGlow = [[UIView alloc] initWithFrame:view.bounds];
    innerGlow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    innerGlow.layer.cornerRadius = radius;
    innerGlow.layer.borderWidth = 1.0;
    innerGlow.layer.borderColor = [self borderActive].CGColor;
    innerGlow.alpha = 0.3;
    [view insertSubview:innerGlow aboveSubview:effectView];
}

+ (CAGradientLayer *)electricGradient {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[(id)[self accentNeonBlue].CGColor, (id)[self accentCyan].CGColor];
    gradient.startPoint = CGPointMake(0.0, 0.5);
    gradient.endPoint = CGPointMake(1.0, 0.5);
    return gradient;
}
@end


#pragma mark - ================= PREMIUM COMPONENTS =================

// MARK: 1. ZXButton
@interface ZXButton : UIButton
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSString *originalTitle;
@property (nonatomic, strong) UIView *bgView;
- (void)setLoading:(BOOL)loading;
@end

@implementation ZXButton
- (instancetype)init {
    if (self = [super init]) {
        self.layer.cornerRadius = 16;
        self.titleLabel.font = [ZXTheme fontHeading:15];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        _bgView = [[UIView alloc] init];
        _bgView.layer.cornerRadius = 16;
        _bgView.clipsToBounds = YES;
        _bgView.userInteractionEnabled = NO;
        _bgView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_bgView];
        
        _gradientLayer = [ZXTheme electricGradient];
        [_bgView.layer insertSublayer:_gradientLayer atIndex:0];
        
        // Premium localized bloom
        self.layer.shadowColor = [ZXTheme accentNeonBlue].CGColor;
        self.layer.shadowOpacity = 0.3;
        self.layer.shadowRadius = 12;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        _spinner.color = [UIColor whiteColor];
        _spinner.hidesWhenStopped = YES;
        _spinner.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_spinner];
        
        [NSLayoutConstraint activateConstraints:@[
            [_bgView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_bgView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_bgView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_bgView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [_spinner.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [_spinner.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
        ]];
        
        [self bringSubviewToFront:self.titleLabel];
        
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
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid];
    [haptic impactOccurred];
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformMakeScale(0.95, 0.95);
        self.layer.shadowOpacity = 0.6;
        self.layer.shadowRadius = 8;
        self.bgView.alpha = 0.8;
    } completion:nil];
}

- (void)touchUp {
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.transform = CGAffineTransformIdentity;
        self.layer.shadowOpacity = 0.3;
        self.layer.shadowRadius = 12;
        self.bgView.alpha = 1.0;
    } completion:nil];
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

// MARK: 2. ZXTextField
@interface ZXTextField : UIView <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *visibilityButton;
@property (nonatomic, strong) UIView *highlightBorder;
@end

@implementation ZXTextField
- (instancetype)init {
    if (self = [super init]) {
        [ZXTheme applyPremiumGlassmorphismToView:self cornerRadius:16];
        
        _highlightBorder = [[UIView alloc] init];
        _highlightBorder.layer.cornerRadius = 16;
        _highlightBorder.layer.borderWidth = 1.5;
        _highlightBorder.layer.borderColor = [ZXTheme accentCyan].CGColor;
        _highlightBorder.alpha = 0;
        _highlightBorder.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_highlightBorder];
        
        UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.shield.fill"]];
        icon.tintColor = [ZXTheme textMuted];
        icon.contentMode = UIViewContentModeScaleAspectFit;
        icon.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:icon];
        
        _textField = [[UITextField alloc] init];
        _textField.textColor = [ZXTheme textPrimary];
        _textField.font = [ZXTheme fontMono:15 weight:UIFontWeightBold];
        _textField.secureTextEntry = YES;
        _textField.delegate = self;
        _textField.translatesAutoresizingMaskIntoConstraints = NO;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        NSAttributedString *ph = [[NSAttributedString alloc] initWithString:@"ENTER LICENCE TOKEN" attributes:@{
            NSForegroundColorAttributeName: [ZXTheme textMuted],
            NSKernAttributeName: @(1.5)
        }];
        _textField.attributedPlaceholder = ph;
        [self addSubview:_textField];
        
        _visibilityButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_visibilityButton setImage:[UIImage systemImageNamed:@"eye.slash.fill"] forState:UIControlStateNormal];
        _visibilityButton.tintColor = [ZXTheme textMuted];
        _visibilityButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_visibilityButton addTarget:self action:@selector(toggleVisibility) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_visibilityButton];
        
        [NSLayoutConstraint activateConstraints:@[
            [_highlightBorder.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_highlightBorder.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_highlightBorder.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_highlightBorder.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            
            [icon.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20],
            [icon.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [icon.widthAnchor constraintEqualToConstant:18],
            [icon.heightAnchor constraintEqualToConstant:18],
            
            [_textField.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:16],
            [_textField.trailingAnchor constraintEqualToAnchor:_visibilityButton.leadingAnchor constant:-12],
            [_textField.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_textField.heightAnchor constraintEqualToAnchor:self.heightAnchor],
            
            [_visibilityButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20],
            [_visibilityButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_visibilityButton.widthAnchor constraintEqualToConstant:24],
            [_visibilityButton.heightAnchor constraintEqualToConstant:24]
        ]];
    }
    return self;
}

- (void)toggleVisibility {
    self.textField.secureTextEntry = !self.textField.secureTextEntry;
    NSString *iconName = self.textField.secureTextEntry ? @"eye.slash.fill" : @"eye.fill";
    [self.visibilityButton setImage:[UIImage systemImageNamed:iconName] forState:UIControlStateNormal];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.visibilityButton.tintColor = self.textField.secureTextEntry ? [ZXTheme textMuted] : [ZXTheme accentCyan];
    }];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.3 animations:^{
        self.highlightBorder.alpha = 1.0;
        self.layer.shadowColor = [ZXTheme accentCyan].CGColor;
        self.layer.shadowOpacity = 0.2;
        self.layer.shadowRadius = 15;
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.3 animations:^{
        self.highlightBorder.alpha = 0.0;
        self.layer.shadowOpacity = 0.0;
    }];
}
@end


// MARK: 3. ZXToggle (Precision Hardware Switch - With Network Binding)
@interface ZXToggle : UIControl
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, strong) NSString *moduleId; // CRITICAL FIX: To securely hold actual server module name
@property (nonatomic, strong) UIView *trackView;
@property (nonatomic, strong) UIView *thumbView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@end

@implementation ZXToggle
- (instancetype)init {
    if (self = [super init]) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self.widthAnchor constraintEqualToConstant:54].active = YES;
        [self.heightAnchor constraintEqualToConstant:30].active = YES;
        
        _trackView = [[UIView alloc] init];
        _trackView.backgroundColor = [ZXTheme bgCardInner];
        _trackView.layer.cornerRadius = 15;
        _trackView.layer.borderWidth = 1.0;
        _trackView.layer.borderColor = [ZXTheme borderSubtle].CGColor;
        _trackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_trackView];
        
        _thumbView = [[UIView alloc] init];
        _thumbView.backgroundColor = [ZXTheme textMuted];
        _thumbView.layer.cornerRadius = 11;
        _thumbView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_thumbView];
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        _spinner.transform = CGAffineTransformMakeScale(0.6, 0.6);
        _spinner.hidesWhenStopped = YES;
        _spinner.translatesAutoresizingMaskIntoConstraints = NO;
        [_thumbView addSubview:_spinner];
        
        [NSLayoutConstraint activateConstraints:@[
            [_trackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_trackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_trackView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_trackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            
            [_thumbView.widthAnchor constraintEqualToConstant:22],
            [_thumbView.heightAnchor constraintEqualToConstant:22],
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
    CGFloat thumbX = self.isOn ? (54 - 22 - 4) : 4;
    
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.65 initialSpringVelocity:0.4 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.thumbView.frame = CGRectMake(thumbX, 4, 22, 22);
        if (self.isOn) {
            self.trackView.layer.borderColor = [ZXTheme accentCyan].CGColor;
            self.thumbView.backgroundColor = [ZXTheme accentCyan];
            self.thumbView.layer.shadowColor = [ZXTheme accentCyan].CGColor;
            self.thumbView.layer.shadowOpacity = 0.8;
            self.thumbView.layer.shadowRadius = 8;
            self.thumbView.layer.shadowOffset = CGSizeZero;
        } else {
            self.trackView.layer.borderColor = [ZXTheme borderSubtle].CGColor;
            self.thumbView.backgroundColor = [ZXTheme textMuted];
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
        self.thumbView.backgroundColor = self.isOn ? [ZXTheme accentCyan] : [ZXTheme textMuted];
        [self.spinner stopAnimating];
    }
}
@end


#pragma mark - ================= MODAL MANAGER =================

@interface ZXModalManager : NSObject
+ (void)showModalWithIcon:(NSString *)iconName iconTint:(UIColor *)tint title:(NSString *)title message:(NSString *)msg actionTitle:(NSString *)actTitle inView:(UIView *)parentView;
@end

@implementation ZXModalManager
+ (void)showModalWithIcon:(NSString *)iconName iconTint:(UIColor *)tint title:(NSString *)title message:(NSString *)msg actionTitle:(NSString *)actTitle inView:(UIView *)parentView {
    
    UIView *overlay = [[UIView alloc] initWithFrame:parentView.bounds];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.alpha = 0;
    [parentView addSubview:overlay];
    
    UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    blur.frame = overlay.bounds;
    blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [overlay addSubview:blur];
    
    UIView *card = [[UIView alloc] init];
    [ZXTheme applyPremiumGlassmorphismToView:card cornerRadius:24];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.transform = CGAffineTransformMakeScale(0.85, 0.85);
    [overlay addSubview:card];
    
    // Deep shadow for floating effect
    card.layer.shadowColor = tint.CGColor;
    card.layer.shadowOpacity = 0.15;
    card.layer.shadowRadius = 40;
    card.layer.shadowOffset = CGSizeMake(0, 20);
    
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    iconView.tintColor = tint;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.layer.shadowColor = tint.CGColor;
    iconView.layer.shadowOpacity = 0.5;
    iconView.layer.shadowRadius = 15;
    [card addSubview:iconView];
    
    UILabel *titleLbl = [[UILabel alloc] init];
    titleLbl.text = [title uppercaseString];
    titleLbl.textColor = [ZXTheme textPrimary];
    titleLbl.font = [ZXTheme fontHeading:16];
    [ZXTheme applyTextTracking:titleLbl spacing:2.0];
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
        [card.widthAnchor constraintEqualToConstant:320],
        
        [iconView.topAnchor constraintEqualToAnchor:card.topAnchor constant:32],
        [iconView.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [iconView.widthAnchor constraintEqualToConstant:48],
        [iconView.heightAnchor constraintEqualToConstant:48],
        
        [titleLbl.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:24],
        [titleLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [titleLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        
        [msgLbl.topAnchor constraintEqualToAnchor:titleLbl.bottomAnchor constant:12],
        [msgLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [msgLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        
        [btn.topAnchor constraintEqualToAnchor:msgLbl.bottomAnchor constant:32],
        [btn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [btn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        [btn.heightAnchor constraintEqualToConstant:54],
        [btn.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-24]
    ]];
    
    // Add dismiss action
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissOverlay:)];
    [btn addTarget:self action:@selector(dismissBtnTapped:) forControlEvents:UIControlEventTouchUpInside];
    [overlay addGestureRecognizer:tap];
    
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
    [haptic impactOccurred];
    
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        overlay.alpha = 1.0;
        card.transform = CGAffineTransformIdentity;
    } completion:nil];
}

+ (void)dismissOverlay:(UITapGestureRecognizer *)sender {
    [self animateDismiss:sender.view];
}

+ (void)dismissBtnTapped:(UIButton *)btn {
    [self animateDismiss:btn.superview.superview];
}

+ (void)animateDismiss:(UIView *)overlay {
    [UIView animateWithDuration:0.3 animations:^{
        overlay.alpha = 0;
        overlay.subviews.lastObject.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished) {
        [overlay removeFromSuperview];
    }];
}

@end


#pragma mark - ================= MAIN VIEW CONTROLLER =================

@interface ZentraxUI ()

// Flow Containers
@property (nonatomic, strong) UIView *splashContainer;
@property (nonatomic, strong) UIView *authContainer;
@property (nonatomic, strong) UIView *dashboardContainer;

// Splash elements
@property (nonatomic, strong) UIView *progressTrack;
@property (nonatomic, strong) UIView *progressFill;

// Auth elements
@property (nonatomic, strong) ZXTextField *keyInput;
@property (nonatomic, strong) ZXButton *loginBtn;

// Dashboard elements
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *expiryLabel;
@property (nonatomic, strong) UIScrollView *modulesScrollView;
@property (nonatomic, strong) UIActivityIndicatorView *dashboardSpinner;
@property (nonatomic, strong) UILabel *emptyStateLabel;

// Rate limiting state
@property (nonatomic, strong) NSMutableDictionary *toggleTimestamps;

@end

@implementation ZentraxUI

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [ZXTheme bgDeepSpace];
    self.toggleTimestamps = [NSMutableDictionary dictionary];
    
    [self setupCinematicAmbientBackground];
    
    [self setupSplash];
    [self setupAuth];
    [self setupDashboard];
    
    self.authContainer.alpha = 0;
    self.dashboardContainer.alpha = 0;
    
    [self runSplashSequence];
}

- (void)setupCinematicAmbientBackground {
    // Top Right Deep Blue Glow
    UIView *topGlow = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 200, -150, 500, 500)];
    topGlow.backgroundColor = [[ZXTheme accentNeonBlue] colorWithAlphaComponent:0.08];
    topGlow.layer.cornerRadius = 250;
    topGlow.layer.shadowColor = [ZXTheme accentNeonBlue].CGColor;
    topGlow.layer.shadowRadius = 150;
    topGlow.layer.shadowOpacity = 1.0;
    [self.view addSubview:topGlow];
    
    // Bottom Left Cyan Glow
    UIView *bottomGlow = [[UIView alloc] initWithFrame:CGRectMake(-150, self.view.bounds.size.height - 250, 400, 400)];
    bottomGlow.backgroundColor = [[ZXTheme accentCyan] colorWithAlphaComponent:0.05];
    bottomGlow.layer.cornerRadius = 200;
    bottomGlow.layer.shadowColor = [ZXTheme accentCyan].CGColor;
    bottomGlow.layer.shadowRadius = 150;
    bottomGlow.layer.shadowOpacity = 1.0;
    [self.view addSubview:bottomGlow];
    
    // Cinematic Slow Breathing Animation
    [UIView animateWithDuration:12.0 delay:0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut animations:^{
        topGlow.transform = CGAffineTransformMakeTranslation(-60, 80);
        bottomGlow.transform = CGAffineTransformMakeTranslation(80, -60);
    } completion:nil];
}

#pragma mark - Splash Flow
- (void)setupSplash {
    _splashContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_splashContainer];
    
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"bolt.shield.fill"]];
    logo.tintColor = [ZXTheme accentCyan];
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.layer.shadowColor = [ZXTheme accentCyan].CGColor;
    logo.layer.shadowRadius = 30;
    logo.layer.shadowOpacity = 0.8;
    logo.layer.shadowOffset = CGSizeZero;
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:logo];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"ZENTRAX PROXY";
    title.textColor = [ZXTheme textPrimary];
    title.font = [ZXTheme fontDisplay:22];
    [ZXTheme applyTextTracking:title spacing:8.0];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:title];
    
    UILabel *sub = [[UILabel alloc] init];
    sub.text = @"SECURE EXECUTION NODE";
    sub.textColor = [ZXTheme textMuted];
    sub.font = [ZXTheme fontMono:10 weight:UIFontWeightBold];
    [ZXTheme applyTextTracking:sub spacing:3.0];
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:sub];
    
    _progressTrack = [[UIView alloc] init];
    _progressTrack.backgroundColor = [ZXTheme borderSubtle];
    _progressTrack.layer.cornerRadius = 1.5;
    _progressTrack.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_progressTrack];
    
    _progressFill = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 3)];
    _progressFill.backgroundColor = [ZXTheme accentCyan];
    _progressFill.layer.cornerRadius = 1.5;
    _progressFill.layer.shadowColor = [ZXTheme accentCyan].CGColor;
    _progressFill.layer.shadowRadius = 8;
    _progressFill.layer.shadowOpacity = 0.8;
    [_progressTrack addSubview:_progressFill];
    
    [NSLayoutConstraint activateConstraints:@[
        [logo.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [logo.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor constant:-70],
        [logo.widthAnchor constraintEqualToConstant:60],
        [logo.heightAnchor constraintEqualToConstant:70],
        
        [title.topAnchor constraintEqualToAnchor:logo.bottomAnchor constant:30],
        [title.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        
        [sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
        [sub.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        
        [_progressTrack.bottomAnchor constraintEqualToAnchor:_splashContainer.safeAreaLayoutGuide.bottomAnchor constant:-80],
        [_progressTrack.leadingAnchor constraintEqualToAnchor:_splashContainer.leadingAnchor constant:80],
        [_progressTrack.trailingAnchor constraintEqualToAnchor:_splashContainer.trailingAnchor constant:-80],
        [_progressTrack.heightAnchor constraintEqualToConstant:3]
    ]];
}

- (void)runSplashSequence {
    [UIView animateWithDuration:1.5 delay:0.3 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.progressFill.frame = CGRectMake(0, 0, (self.view.bounds.size.width - 160) * 0.85, 3);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.4 animations:^{
            self.progressFill.frame = CGRectMake(0, 0, self.view.bounds.size.width - 160, 3);
        } completion:^(BOOL finished) {
            [self transitionToAuth];
        }];
    }];
}

#pragma mark - Auth Flow
- (void)setupAuth {
    _authContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_authContainer];
    
    UILabel *headerSub = [[UILabel alloc] init];
    headerSub.text = @"NODE AUTHORIZATION";
    headerSub.textColor = [ZXTheme accentCyan];
    headerSub.font = [ZXTheme fontMono:11 weight:UIFontWeightBold];
    [ZXTheme applyTextTracking:headerSub spacing:3.0];
    headerSub.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:headerSub];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"Authenticate";
    title.textColor = [ZXTheme textPrimary];
    title.font = [ZXTheme fontDisplay:32];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:title];
    
    UILabel *desc = [[UILabel alloc] init];
    desc.text = @"Provide your master token to establish a secure connection with the execution server.";
    desc.textColor = [ZXTheme textSecondary];
    desc.font = [ZXTheme fontBody:14 weight:UIFontWeightRegular];
    desc.numberOfLines = 0;
    desc.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:desc];
    
    _keyInput = [[ZXTextField alloc] init];
    _keyInput.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:_keyInput];
    
    _loginBtn = [[ZXButton alloc] init];
    [_loginBtn setTitle:@"INITIALIZE NODE" forState:UIControlStateNormal];
    [_loginBtn addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside];
    _loginBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:_loginBtn];
    
    [NSLayoutConstraint activateConstraints:@[
        [headerSub.topAnchor constraintEqualToAnchor:_authContainer.safeAreaLayoutGuide.topAnchor constant:80],
        [headerSub.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:32],
        
        [title.topAnchor constraintEqualToAnchor:headerSub.bottomAnchor constant:8],
        [title.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:32],
        
        [desc.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:16],
        [desc.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:32],
        [desc.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-32],
        
        [_keyInput.topAnchor constraintEqualToAnchor:desc.bottomAnchor constant:48],
        [_keyInput.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:32],
        [_keyInput.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-32],
        [_keyInput.heightAnchor constraintEqualToConstant:60],
        
        [_loginBtn.bottomAnchor constraintEqualToAnchor:_authContainer.safeAreaLayoutGuide.bottomAnchor constant:-40],
        [_loginBtn.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:32],
        [_loginBtn.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-32],
        [_loginBtn.heightAnchor constraintEqualToConstant:60],
    ]];
}

- (void)handleLogin {
    NSString *key = self.keyInput.textField.text;
    if (key.length == 0) {
        [self showGlobalErrorWithTitle:@"Authentication Failed" message:@"You must enter a valid authorization token to proceed."];
        return;
    }
    
    [self.loginBtn setLoading:YES];
    [self.keyInput.textField resignFirstResponder];
    
    // Call the actual delegate to network manager
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestAuthenticationWithKey:completion:)]) {
        [self.delegate zentraxDidRequestAuthenticationWithKey:key completion:^(BOOL success, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.loginBtn setLoading:NO];
                if (success) {
                    [self transitionToDashboard];
                } else {
                    [self showGlobalErrorWithTitle:@"Access Denied" message:errorMsg ?: @"The provided token is invalid or expired."];
                }
            });
        }];
    } else {
        [self.loginBtn setLoading:NO];
        [self transitionToDashboard]; // Only for safe-fail continuity
    }
}

#pragma mark - Dashboard Flow (Zero Hardcoded Data)
- (void)setupDashboard {
    _dashboardContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_dashboardContainer];
    
    // Top Nav Area
    UIView *navBar = [[UIView alloc] init];
    navBar.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:navBar];
    
    UIImageView *navIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"shield.lefthalf.filled"]];
    navIcon.tintColor = [ZXTheme accentCyan];
    navIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [navBar addSubview:navIcon];
    
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.text = @"ZENTRAX PROXY";
    navTitle.textColor = [ZXTheme textPrimary];
    navTitle.font = [ZXTheme fontHeading:15];
    [ZXTheme applyTextTracking:navTitle spacing:2.0];
    navTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [navBar addSubview:navTitle];
    
    UIView *statusDot = [[UIView alloc] init];
    statusDot.backgroundColor = [ZXTheme statusSuccess];
    statusDot.layer.cornerRadius = 4;
    statusDot.layer.shadowColor = [ZXTheme statusSuccess].CGColor;
    statusDot.layer.shadowRadius = 4;
    statusDot.layer.shadowOpacity = 1.0;
    statusDot.translatesAutoresizingMaskIntoConstraints = NO;
    [navBar addSubview:statusDot];
    
    // Subscription Card (Dynamic Content Prepared)
    UIView *statusCard = [[UIView alloc] init];
    [ZXTheme applyPremiumGlassmorphismToView:statusCard cornerRadius:20];
    statusCard.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:statusCard];
    
    UILabel *subTitle = [[UILabel alloc] init];
    subTitle.text = @"ACTIVE SESSION";
    subTitle.textColor = [ZXTheme textMuted];
    subTitle.font = [ZXTheme fontMono:11 weight:UIFontWeightBold];
    [ZXTheme applyTextTracking:subTitle spacing:1.5];
    subTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:subTitle];
    
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.text = @"Awaiting Status..."; // Replaced with actual server data on update
    _statusLabel.textColor = [ZXTheme textPrimary];
    _statusLabel.font = [ZXTheme fontHeading:18];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_statusLabel];
    
    _expiryLabel = [[UILabel alloc] init];
    _expiryLabel.text = @"Authenticating..."; // Replaced with actual server data on update
    _expiryLabel.textColor = [ZXTheme textSecondary];
    _expiryLabel.font = [ZXTheme fontBody:13 weight:UIFontWeightRegular];
    _expiryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_expiryLabel];
    
    UIImageView *cardIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.seal.fill"]];
    cardIcon.tintColor = [ZXTheme statusSuccess];
    cardIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:cardIcon];
    
    // Modules List Area (Empty State Default)
    _modulesScrollView = [[UIScrollView alloc] init];
    _modulesScrollView.showsVerticalScrollIndicator = NO;
    _modulesScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:_modulesScrollView];
    
    _dashboardSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _dashboardSpinner.color = [ZXTheme accentCyan];
    _dashboardSpinner.translatesAutoresizingMaskIntoConstraints = NO;
    [_modulesScrollView addSubview:_dashboardSpinner];
    
    _emptyStateLabel = [[UILabel alloc] init];
    _emptyStateLabel.text = @"Synchronizing with Master Node...";
    _emptyStateLabel.textColor = [ZXTheme textMuted];
    _emptyStateLabel.font = [ZXTheme fontBody:13 weight:UIFontWeightMedium];
    _emptyStateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_modulesScrollView addSubview:_emptyStateLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [navBar.topAnchor constraintEqualToAnchor:_dashboardContainer.safeAreaLayoutGuide.topAnchor constant:10],
        [navBar.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [navBar.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [navBar.heightAnchor constraintEqualToConstant:44],
        
        [navIcon.leadingAnchor constraintEqualToAnchor:navBar.leadingAnchor],
        [navIcon.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],
        [navIcon.widthAnchor constraintEqualToConstant:20],
        [navIcon.heightAnchor constraintEqualToConstant:24],
        
        [navTitle.leadingAnchor constraintEqualToAnchor:navIcon.trailingAnchor constant:12],
        [navTitle.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],
        
        [statusDot.trailingAnchor constraintEqualToAnchor:navBar.trailingAnchor],
        [statusDot.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],
        [statusDot.widthAnchor constraintEqualToConstant:8],
        [statusDot.heightAnchor constraintEqualToConstant:8],
        
        [statusCard.topAnchor constraintEqualToAnchor:navBar.bottomAnchor constant:30],
        [statusCard.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [statusCard.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [statusCard.heightAnchor constraintEqualToConstant:110],
        
        [subTitle.topAnchor constraintEqualToAnchor:statusCard.topAnchor constant:24],
        [subTitle.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:24],
        
        [_statusLabel.topAnchor constraintEqualToAnchor:subTitle.bottomAnchor constant:8],
        [_statusLabel.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:24],
        
        [_expiryLabel.topAnchor constraintEqualToAnchor:_statusLabel.bottomAnchor constant:4],
        [_expiryLabel.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:24],
        
        [cardIcon.trailingAnchor constraintEqualToAnchor:statusCard.trailingAnchor constant:-24],
        [cardIcon.centerYAnchor constraintEqualToAnchor:statusCard.centerYAnchor],
        [cardIcon.widthAnchor constraintEqualToConstant:32],
        [cardIcon.heightAnchor constraintEqualToConstant:32],
        
        [_modulesScrollView.topAnchor constraintEqualToAnchor:statusCard.bottomAnchor constant:24],
        [_modulesScrollView.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor],
        [_modulesScrollView.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor],
        [_modulesScrollView.bottomAnchor constraintEqualToAnchor:_dashboardContainer.bottomAnchor],
        
        [_dashboardSpinner.centerXAnchor constraintEqualToAnchor:_modulesScrollView.centerXAnchor],
        [_dashboardSpinner.topAnchor constraintEqualToAnchor:_modulesScrollView.topAnchor constant:100],
        
        [_emptyStateLabel.centerXAnchor constraintEqualToAnchor:_modulesScrollView.centerXAnchor],
        [_emptyStateLabel.topAnchor constraintEqualToAnchor:_dashboardSpinner.bottomAnchor constant:16]
    ]];
    
    // Note: NO dummy data array is passed here. The UI stays empty and spinning until the server responds.
    [_dashboardSpinner startAnimating];
}

// Strictly populates UI from the Backend Dictionary
- (void)updateDashboardWithModules:(NSArray<NSDictionary *> *)modules {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.dashboardSpinner stopAnimating];
        [self.emptyStateLabel removeFromSuperview];
        [self.modulesScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        if (modules.count == 0) {
            self.emptyStateLabel.text = @"No authorized modules found for this key.";
            [self.modulesScrollView addSubview:self.emptyStateLabel];
            return;
        }
        
        CGFloat yOffset = 10;
        
        UILabel *sectionHeader = [[UILabel alloc] initWithFrame:CGRectMake(24, yOffset, 200, 20)];
        sectionHeader.text = @"✦ EXECUTION NODE";
        sectionHeader.textColor = [ZXTheme accentCyan];
        sectionHeader.font = [ZXTheme fontMono:11 weight:UIFontWeightBold];
        [ZXTheme applyTextTracking:sectionHeader spacing:2.0];
        [self.modulesScrollView addSubview:sectionHeader];
        
        yOffset += 40;
        
        for (NSDictionary *mod in modules) {
            // Safely extract whatever the server gives us
            NSString *moduleName = mod[@"name"] ?: @"UNKNOWN MODULE";
            NSString *moduleDesc = mod[@"desc"] ?: mod[@"description"] ?: @"No description provided.";
            
            UIView *row = [[UIView alloc] initWithFrame:CGRectMake(24, yOffset, self.view.bounds.size.width - 48, 80)];
            
            UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, row.bounds.size.width - 70, 20)];
            t.text = [moduleName uppercaseString];
            t.textColor = [ZXTheme textPrimary];
            t.font = [ZXTheme fontHeading:15];
            [row addSubview:t];
            
            UILabel *s = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, row.bounds.size.width - 70, 16)];
            s.text = [moduleDesc uppercaseString];
            s.textColor = [ZXTheme textMuted];
            s.font = [ZXTheme fontBody:11 weight:UIFontWeightMedium];
            [row addSubview:s];
            
            // The Functional Network Setup
            ZXToggle *toggle = [[ZXToggle alloc] init];
            toggle.frame = CGRectMake(row.bounds.size.width - 52, 22, 52, 28);
            toggle.moduleId = moduleName; // Securely binds the real server module name to the switch
            [toggle addTarget:self action:@selector(moduleToggled:) forControlEvents:UIControlEventValueChanged];
            [row addSubview:toggle];
            
            UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 79, row.bounds.size.width, 0.5)];
            separator.backgroundColor = [ZXTheme borderSubtle];
            [row addSubview:separator];
            
            [self.modulesScrollView addSubview:row];
            yOffset += 80;
        }
        
        self.modulesScrollView.contentSize = CGSizeMake(self.view.bounds.size.width, yOffset + 50);
    });
}

// Dynamic Subscription Processing
- (void)updateSubscriptionState:(NSDictionary *)subData {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (subData[@"expiry"]) {
            self.expiryLabel.text = [NSString stringWithFormat:@"Expires: %@", subData[@"expiry"]];
        } else {
            self.expiryLabel.text = @"No Expiry Data";
        }
        
        if (subData[@"status"]) {
            self.statusLabel.text = subData[@"status"];
        } else {
            self.statusLabel.text = @"Premium License";
        }
    });
}

// Module Execution Action
- (void)moduleToggled:(ZXToggle *)sender {
    // Uses the actual module name provided by backend payload (e.g. "DRAGHEADSHOT")
    NSString *networkModuleId = sender.moduleId;
    if (!networkModuleId) return;
    
    NSDate *now = [NSDate date];
    
    // Rate Limiting Logic via Dictionary
    NSMutableArray *stamps = self.toggleTimestamps[networkModuleId] ?: [NSMutableArray array];
    [stamps filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDate *d, NSDictionary *b) {
        return [now timeIntervalSinceDate:d] < 5.0; // Rolling 5 sec window
    }]];
    [stamps addObject:now];
    self.toggleTimestamps[networkModuleId] = stamps;
    
    if (stamps.count > 4) {
        [sender setOn:!sender.isOn animated:YES]; // Local visual rollback
        [self showRateLimitErrorWithSecondsRemaining:5];
        return;
    }
    
    [sender setLoading:YES];
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestModuleToggle:state:completion:)]) {
        [self.delegate zentraxDidRequestModuleToggle:networkModuleId state:sender.isOn completion:^(BOOL success, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setLoading:NO];
                if (!success) {
                    [sender setOn:!sender.isOn animated:YES]; // Local visual rollback on server failure
                    [self showGlobalErrorWithTitle:@"Injection Failed" message:errorMsg ?: @"Failed to execute secure payload."];
                }
            });
        }];
    } else {
        // Fallback for safety (should not reach here in production network loop)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [sender setLoading:NO];
        });
    }
}

#pragma mark - Transitions
- (void)transitionToAuth {
    [UIView transitionWithView:self.view duration:0.8 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.splashContainer.alpha = 0;
        self.authContainer.alpha = 1;
    } completion:nil];
}

- (void)transitionToDashboard {
    [UIView transitionWithView:self.view duration:0.8 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.authContainer.alpha = 0;
        self.dashboardContainer.alpha = 1;
    } completion:nil];
}

#pragma mark - Public APIs / Modals
- (void)showGlobalErrorWithTitle:(NSString *)title message:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        [ZXModalManager showModalWithIcon:@"xmark.octagon.fill" iconTint:[ZXTheme statusError] title:title message:msg actionTitle:@"DISMISS" inView:self.view];
    });
}

- (void)showSuccessMessage:(NSString *)title message:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        [ZXModalManager showModalWithIcon:@"checkmark.shield.fill" iconTint:[ZXTheme statusSuccess] title:title message:msg actionTitle:@"CONTINUE" inView:self.view];
    });
}

- (void)showNetworkError {
    [self showGlobalErrorWithTitle:@"Connection Lost" message:@"Secure connection to the Master Node could not be established. Verify your network access."];
}

- (void)showServerError {
    [self showGlobalErrorWithTitle:@"Server Error" message:@"The Master Node responded with an unexpected status. Retrying is advised."];
}

- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds {
    NSString *msg = [NSString stringWithFormat:@"Maximum request capacity reached to preserve server stability. Cooldown active for %ld seconds.", (long)seconds];
    [ZXModalManager showModalWithIcon:@"timer" iconTint:[ZXTheme statusWarning] title:@"RATE LIMITED" message:msg actionTitle:@"UNDERSTOOD" inView:self.view];
}

- (void)showGlobalLoadingState:(NSString *)message {}
- (void)hideGlobalLoadingState {}

@end
