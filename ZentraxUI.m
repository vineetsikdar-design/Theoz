//
//  ZentraxUI.m
//  Zentrax VIP - Premium Execution Node UI
//
//  Created by Zentrax Team.
//  Architecture: Ultra-Premium SaaS Layer
//  Status: PRODUCTION READY
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
+ (UIColor *)accentViolet;
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

+ (UIColor *)bgDeepSpace { return [UIColor colorWithRed:0.02 green:0.03 blue:0.06 alpha:1.0]; }
+ (UIColor *)bgCardOuter { return [UIColor colorWithRed:0.06 green:0.08 blue:0.14 alpha:0.45]; }
+ (UIColor *)bgCardInner { return [UIColor colorWithRed:0.08 green:0.11 blue:0.18 alpha:0.60]; }
+ (UIColor *)borderSubtle { return [UIColor colorWithWhite:1.0 alpha:0.05]; }
+ (UIColor *)borderActive { return [UIColor colorWithWhite:1.0 alpha:0.15]; }

+ (UIColor *)accentCyan { return [UIColor colorWithRed:0.0 green:0.85 blue:1.0 alpha:1.0]; }
+ (UIColor *)accentNeonBlue { return [UIColor colorWithRed:0.15 green:0.35 blue:1.0 alpha:1.0]; }
+ (UIColor *)accentViolet { return [UIColor colorWithRed:0.55 green:0.0 blue:1.0 alpha:1.0]; }

+ (UIColor *)textPrimary { return [UIColor colorWithWhite:0.98 alpha:1.0]; }
+ (UIColor *)textSecondary { return [UIColor colorWithWhite:0.70 alpha:1.0]; }
+ (UIColor *)textMuted { return [UIColor colorWithWhite:0.45 alpha:1.0]; }

+ (UIColor *)statusSuccess { return [UIColor colorWithRed:0.15 green:0.85 blue:0.55 alpha:1.0]; }
+ (UIColor *)statusWarning { return [UIColor colorWithRed:0.96 green:0.65 blue:0.14 alpha:1.0]; }
+ (UIColor *)statusError { return [UIColor colorWithRed:1.0 green:0.25 blue:0.35 alpha:1.0]; }

+ (UIFont *)fontDisplay:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBlack]; }
+ (UIFont *)fontHeading:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBold]; }
+ (UIFont *)fontBody:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont systemFontOfSize:size weight:weight]; }
+ (UIFont *)fontMono:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont monospacedSystemFontOfSize:size weight:weight]; }

+ (void)applyTextTracking:(UILabel *)label spacing:(CGFloat)spacing {
    if (!label.text) return;
    NSDictionary *attrs = @{NSKernAttributeName: @(spacing)};
    label.attributedText = [[NSAttributedString alloc] initWithString:label.text attributes:attrs];
}

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
    effectView.alpha = 0.95;
    [view insertSubview:effectView atIndex:0];
    
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
        self.layer.cornerRadius = 14;
        self.titleLabel.font = [ZXTheme fontHeading:15];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        _bgView = [[UIView alloc] init];
        _bgView.layer.cornerRadius = 14;
        _bgView.clipsToBounds = YES;
        _bgView.userInteractionEnabled = NO;
        _bgView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_bgView];
        
        _gradientLayer = [ZXTheme electricGradient];
        [_bgView.layer insertSublayer:_gradientLayer atIndex:0];
        
        self.layer.shadowColor = [ZXTheme accentNeonBlue].CGColor;
        self.layer.shadowOpacity = 0.35;
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
        self.transform = CGAffineTransformMakeScale(0.96, 0.96);
        self.layer.shadowOpacity = 0.6;
        self.layer.shadowRadius = 8;
        self.bgView.alpha = 0.85;
    } completion:nil];
}

- (void)touchUp {
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.transform = CGAffineTransformIdentity;
        self.layer.shadowOpacity = 0.35;
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
        self.bgView.alpha = 0.7;
    } else {
        [self setTitle:self.originalTitle forState:UIControlStateNormal];
        [self.spinner stopAnimating];
        self.bgView.alpha = 1.0;
    }
}
@end

@interface ZXTextField : UIView <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UILabel *floatingLabel;
@property (nonatomic, strong) UIButton *pasteButton;
@property (nonatomic, strong) UIView *highlightBorder;
@property (nonatomic, strong) UIImageView *iconView;

@property (nonatomic, strong) NSLayoutConstraint *labelCenterConstraint;
@property (nonatomic, strong) NSLayoutConstraint *labelTopConstraint;
@end

@implementation ZXTextField
- (instancetype)init {
    if (self = [super init]) {
        [ZXTheme applyPremiumGlassmorphismToView:self cornerRadius:14];
        
        _highlightBorder = [[UIView alloc] init];
        _highlightBorder.layer.cornerRadius = 14;
        _highlightBorder.layer.borderWidth = 1.5;
        _highlightBorder.layer.borderColor = [ZXTheme accentCyan].CGColor;
        _highlightBorder.alpha = 0;
        _highlightBorder.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_highlightBorder];
        
        _iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"key.fill"]];
        _iconView.tintColor = [ZXTheme textMuted];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_iconView];
        
        _floatingLabel = [[UILabel alloc] init];
        _floatingLabel.text = @"Enter Your Licence Key";
        _floatingLabel.textColor = [ZXTheme textMuted];
        _floatingLabel.font = [ZXTheme fontBody:15 weight:UIFontWeightMedium];
        _floatingLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_floatingLabel];
        
        _textField = [[UITextField alloc] init];
        _textField.textColor = [ZXTheme textPrimary];
        _textField.font = [ZXTheme fontMono:16 weight:UIFontWeightBold];
        _textField.secureTextEntry = YES;
        _textField.delegate = self;
        _textField.translatesAutoresizingMaskIntoConstraints = NO;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textField.returnKeyType = UIReturnKeyDone;
        [_textField addTarget:self action:@selector(textDidChange) forControlEvents:UIControlEventEditingChanged];
        [self addSubview:_textField];
        
        _pasteButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_pasteButton setTitle:@"PASTE" forState:UIControlStateNormal];
        _pasteButton.titleLabel.font = [ZXTheme fontHeading:12];
        _pasteButton.backgroundColor = [ZXTheme bgCardInner];
        _pasteButton.layer.cornerRadius = 8;
        _pasteButton.layer.borderWidth = 0.5;
        _pasteButton.layer.borderColor = [ZXTheme borderActive].CGColor;
        [_pasteButton setTitleColor:[ZXTheme textPrimary] forState:UIControlStateNormal];
        _pasteButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_pasteButton addTarget:self action:@selector(pasteKeyTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_pasteButton];
        
        _labelCenterConstraint = [_floatingLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor];
        _labelTopConstraint = [_floatingLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:8];
        
        [NSLayoutConstraint activateConstraints:@[
            [_highlightBorder.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_highlightBorder.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_highlightBorder.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_highlightBorder.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            
            [_iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
            [_iconView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_iconView.widthAnchor constraintEqualToConstant:20],
            [_iconView.heightAnchor constraintEqualToConstant:20],
            
            [_floatingLabel.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor constant:12],
            _labelCenterConstraint, // Active by default
            
            [_textField.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor constant:12],
            [_textField.trailingAnchor constraintEqualToAnchor:_pasteButton.leadingAnchor constant:-12],
            [_textField.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8],
            [_textField.topAnchor constraintEqualToAnchor:self.topAnchor constant:20],
            
            [_pasteButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],
            [_pasteButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_pasteButton.heightAnchor constraintEqualToConstant:28],
            [_pasteButton.widthAnchor constraintEqualToConstant:60]
        ]];
    }
    return self;
}

- (void)updateFloatingLabelStateAnimated:(BOOL)animated {
    BOOL shouldFloat = (self.textField.isFirstResponder || self.textField.text.length > 0);
    
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self applyLabelState:shouldFloat];
            [self layoutIfNeeded];
        } completion:nil];
    } else {
        [self applyLabelState:shouldFloat];
    }
}

- (void)applyLabelState:(BOOL)shouldFloat {
    if (shouldFloat) {
        self.labelCenterConstraint.active = NO;
        self.labelTopConstraint.active = YES;
        self.floatingLabel.font = [ZXTheme fontBody:11 weight:UIFontWeightBold];
        self.floatingLabel.textColor = [ZXTheme accentCyan];
        self.iconView.tintColor = [ZXTheme accentCyan];
    } else {
        self.labelTopConstraint.active = NO;
        self.labelCenterConstraint.active = YES;
        self.floatingLabel.font = [ZXTheme fontBody:15 weight:UIFontWeightMedium];
        self.floatingLabel.textColor = [ZXTheme textMuted];
        self.iconView.tintColor = [ZXTheme textMuted];
    }
}

- (void)pasteKeyTapped {
    NSString *pb = [[UIPasteboard generalPasteboard].string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (pb.length > 0) {
        self.textField.text = pb;
        [self updateFloatingLabelStateAnimated:YES];
        UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [haptic impactOccurred];
    }
}

- (void)textDidChange {
    [self updateFloatingLabelStateAnimated:YES];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self updateFloatingLabelStateAnimated:YES];
    [UIView animateWithDuration:0.3 animations:^{
        self.highlightBorder.alpha = 1.0;
        self.layer.shadowColor = [ZXTheme accentCyan].CGColor;
        self.layer.shadowOpacity = 0.2;
        self.layer.shadowRadius = 15;
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self updateFloatingLabelStateAnimated:YES];
    [UIView animateWithDuration:0.3 animations:^{
        self.highlightBorder.alpha = 0.0;
        self.layer.shadowOpacity = 0.0;
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end

@interface ZXToggle : UIControl
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, strong) NSString *moduleId; 
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
        _trackView.backgroundColor = [ZXTheme bgCardInner];
        _trackView.layer.cornerRadius = 14;
        _trackView.layer.borderWidth = 1.0;
        _trackView.layer.borderColor = [ZXTheme borderSubtle].CGColor;
        _trackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_trackView];
        
        _thumbView = [[UIView alloc] init];
        _thumbView.backgroundColor = [ZXTheme textMuted];
        _thumbView.layer.cornerRadius = 10;
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
    // Prevent interaction while loading
    if (!self.userInteractionEnabled) return;
    
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
    CGFloat duration = animated ? 0.35 : 0.0;
    CGFloat thumbX = self.isOn ? (50 - 20 - 4) : 4;
    
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.4 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.thumbView.frame = CGRectMake(thumbX, 4, 20, 20);
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
    self.userInteractionEnabled = !loading; // Strictly block multiple rapid taps
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
    [ZXTheme applyTextTracking:titleLbl spacing:1.5];
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
        [card.widthAnchor constraintEqualToConstant:310],
        
        [iconView.topAnchor constraintEqualToAnchor:card.topAnchor constant:32],
        [iconView.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [iconView.widthAnchor constraintEqualToConstant:48],
        [iconView.heightAnchor constraintEqualToConstant:48],
        
        [titleLbl.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:20],
        [titleLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [titleLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        
        [msgLbl.topAnchor constraintEqualToAnchor:titleLbl.bottomAnchor constant:10],
        [msgLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [msgLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        
        [btn.topAnchor constraintEqualToAnchor:msgLbl.bottomAnchor constant:32],
        [btn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [btn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        [btn.heightAnchor constraintEqualToConstant:50],
        [btn.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-24]
    ]];
    
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

typedef NS_ENUM(NSInteger, ZXAppState) {
    ZXAppStateInit,
    ZXAppStateSplash,
    ZXAppStateAuth,
    ZXAppStateVerifying,
    ZXAppStateDashboard
};

@interface ZentraxUI ()
@property (nonatomic, assign) BOOL hasCompletedInitialPresentation;
@property (nonatomic, assign) ZXAppState currentState;

// Flow Containers
@property (nonatomic, strong) UIView *splashContainer;
@property (nonatomic, strong) UIView *authContainer;
@property (nonatomic, strong) UIView *verificationContainer;
@property (nonatomic, strong) UIView *dashboardContainer;

// Splash elements
@property (nonatomic, strong) UIView *progressTrack;
@property (nonatomic, strong) UIView *progressFill;

// Auth elements
@property (nonatomic, strong) ZXTextField *keyInput;
@property (nonatomic, strong) ZXButton *loginBtn;

// Verification elements
@property (nonatomic, strong) UILabel *verificationStepLabel;
@property (nonatomic, strong) UIActivityIndicatorView *verificationSpinner;

// Dashboard elements
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *expiryLabel;
@property (nonatomic, strong) UIScrollView *modulesScrollView;
@property (nonatomic, strong) UIStackView *modulesStackView; // AutoLayout container for cards
@property (nonatomic, strong) UIView *emptyStateView;

@end

@implementation ZentraxUI

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [ZXTheme bgDeepSpace];
    self.currentState = ZXAppStateInit;
    
    UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    dismissTap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:dismissTap];
    
    [self setupCinematicAmbientBackground];
    
    [self setupSplash];
    [self setupAuth];
    [self setupVerification];
    [self setupDashboard];
    
    self.splashContainer.alpha = 0;
    self.authContainer.alpha = 0;
    self.verificationContainer.alpha = 0;
    self.dashboardContainer.alpha = 0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    if (!self.hasCompletedInitialPresentation) {
        self.hasCompletedInitialPresentation = YES;
        [self runDeterministicLaunchSequence];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - Keyboard Handling
- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    CGRect kbFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGRect btnRect = [self.authContainer convertRect:self.loginBtn.frame toView:self.view];
    CGFloat btnBottom = CGRectGetMaxY(btnRect);
    CGFloat kbTop = kbFrame.origin.y;
    
    CGFloat overlap = btnBottom - kbTop;
    if (overlap > 0) {
        CGFloat shift = overlap + 20; 
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.authContainer.transform = CGAffineTransformMakeTranslation(0, -shift);
        } completion:nil];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.authContainer.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)setupCinematicAmbientBackground {
    UIView *topGlow = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 200, -150, 500, 500)];
    topGlow.backgroundColor = [[ZXTheme accentViolet] colorWithAlphaComponent:0.07];
    topGlow.layer.cornerRadius = 250;
    topGlow.layer.shadowColor = [ZXTheme accentViolet].CGColor;
    topGlow.layer.shadowRadius = 150;
    topGlow.layer.shadowOpacity = 1.0;
    [self.view addSubview:topGlow];
    
    UIView *bottomGlow = [[UIView alloc] initWithFrame:CGRectMake(-150, self.view.bounds.size.height - 250, 400, 400)];
    bottomGlow.backgroundColor = [[ZXTheme accentCyan] colorWithAlphaComponent:0.05];
    bottomGlow.layer.cornerRadius = 200;
    bottomGlow.layer.shadowColor = [ZXTheme accentCyan].CGColor;
    bottomGlow.layer.shadowRadius = 150;
    bottomGlow.layer.shadowOpacity = 1.0;
    [self.view addSubview:bottomGlow];
    
    [UIView animateWithDuration:15.0 delay:0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut animations:^{
        topGlow.transform = CGAffineTransformMakeTranslation(-80, 100);
        bottomGlow.transform = CGAffineTransformMakeTranslation(100, -80);
    } completion:nil];
}

#pragma mark - State Machine
- (void)transitionToState:(ZXAppState)newState {
    self.currentState = newState;
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.splashContainer.alpha = (newState == ZXAppStateSplash) ? 1.0 : 0.0;
        self.authContainer.alpha = (newState == ZXAppStateAuth) ? 1.0 : 0.0;
        self.verificationContainer.alpha = (newState == ZXAppStateVerifying) ? 1.0 : 0.0;
        self.dashboardContainer.alpha = (newState == ZXAppStateDashboard) ? 1.0 : 0.0;
    } completion:nil];
}

#pragma mark - Launch Sequencer & Restore
- (void)runDeterministicLaunchSequence {
    self.currentState = ZXAppStateSplash;
    self.splashContainer.alpha = 1.0;
    self.authContainer.alpha = 0.0;
    self.verificationContainer.alpha = 0.0;
    self.dashboardContainer.alpha = 0.0;
    
    NSTimeInterval sequenceStartTime = CACurrentMediaTime();
    
    [UIView animateWithDuration:1.5 delay:0.3 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.progressFill.frame = CGRectMake(0, 0, (self.view.bounds.size.width - 160) * 0.85, 3);
    } completion:nil];
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) {
        [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL isValid) {
            
            NSTimeInterval elapsed = CACurrentMediaTime() - sequenceStartTime;
            NSTimeInterval remainingDelay = MAX(0.0, 1.8 - elapsed);
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, remainingDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.4 animations:^{
                    self.progressFill.frame = CGRectMake(0, 0, self.view.bounds.size.width - 160, 3);
                } completion:^(BOOL finished) {
                    if (isValid) {
                        [self executeSessionRestoreAnimation];
                    } else {
                        [self transitionToState:ZXAppStateAuth];
                    }
                }];
            });
        }];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self transitionToState:ZXAppStateAuth];
        });
    }
}

- (void)executeSessionRestoreAnimation {
    [self transitionToState:ZXAppStateVerifying];
    self.verificationStepLabel.text = @"SESSION RESTORED";
    self.verificationStepLabel.textColor = [ZXTheme statusSuccess];
    [self.verificationSpinner stopAnimating];
    
    UIImageView *check = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.circle.fill"]];
    check.tintColor = [ZXTheme statusSuccess];
    check.frame = CGRectMake(0, 0, 50, 50);
    check.center = self.verificationSpinner.center;
    check.transform = CGAffineTransformMakeScale(0.1, 0.1);
    [self.verificationContainer addSubview:check];
    
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred];
    
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:0 animations:^{
        check.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [check removeFromSuperview];
            self.verificationStepLabel.textColor = [ZXTheme accentCyan];
            [self.verificationSpinner startAnimating];
            [self transitionToState:ZXAppStateDashboard]; 
        });
    }];
}

#pragma mark - Splash View
- (void)setupSplash {
    _splashContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_splashContainer];
    
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"bolt.shield.fill"]];
    logo.tintColor = [ZXTheme accentCyan];
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.layer.shadowColor = [ZXTheme accentCyan].CGColor;
    logo.layer.shadowRadius = 30;
    logo.layer.shadowOpacity = 0.8;
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:logo];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"ZENTRAX VIP";
    title.textColor = [ZXTheme textPrimary];
    title.font = [ZXTheme fontDisplay:22];
    [ZXTheme applyTextTracking:title spacing:8.0];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:title];
    
    UILabel *sub = [[UILabel alloc] init];
    sub.text = @"SECURE INITIALIZATION";
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

#pragma mark - Auth Flow
- (void)setupAuth {
    _authContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_authContainer];
    
    UILabel *headerSub = [[UILabel alloc] init];
    headerSub.text = @"ZENTRAX VIP";
    headerSub.textColor = [ZXTheme accentCyan];
    headerSub.font = [ZXTheme fontMono:11 weight:UIFontWeightBold];
    [ZXTheme applyTextTracking:headerSub spacing:3.0];
    headerSub.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:headerSub];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"Secure Access";
    title.textColor = [ZXTheme textPrimary];
    title.font = [ZXTheme fontDisplay:32];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:title];
    
    UILabel *desc = [[UILabel alloc] init];
    desc.text = @"Provide your license key to verify your premium ZENTRAX VIP access.";
    desc.textColor = [ZXTheme textSecondary];
    desc.font = [ZXTheme fontBody:14 weight:UIFontWeightRegular];
    desc.numberOfLines = 0;
    desc.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:desc];
    
    _keyInput = [[ZXTextField alloc] init];
    _keyInput.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:_keyInput];
    
    _loginBtn = [[ZXButton alloc] init];
    [_loginBtn setTitle:@"VERIFY LICENSE" forState:UIControlStateNormal];
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
        [_loginBtn.heightAnchor constraintEqualToConstant:56],
    ]];
}

- (void)handleLogin {
    [self dismissKeyboard];
    
    NSString *key = self.keyInput.textField.text;
    if (key.length == 0) {
        [self showGlobalErrorWithTitle:@"Validation Error" message:@"You must enter a valid license key to proceed."];
        return;
    }
    
    [self.loginBtn setLoading:YES];
    [self transitionToState:ZXAppStateVerifying];
    
    self.verificationStepLabel.text = @"SECURE CONNECTION";
    self.verificationStepLabel.textColor = [ZXTheme accentCyan];
    [self.verificationSpinner startAnimating];
    
    NSArray *steps = @[@"VERIFYING LICENSE", @"VALIDATING HARDWARE", @"FINALIZING SESSION"];
    for (int i = 0; i < steps.count; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (0.5 * (i + 1)) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (self.currentState == ZXAppStateVerifying) {
                self.verificationStepLabel.text = steps[i];
            }
        });
    }
    
    NSTimeInterval startTime = CACurrentMediaTime();
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestAuthenticationWithKey:completion:)]) {
        [self.delegate zentraxDidRequestAuthenticationWithKey:key completion:^(BOOL success, ZXAuthError errorType, NSString *errorMsg) {
            
            NSTimeInterval elapsed = CACurrentMediaTime() - startTime;
            NSTimeInterval remainingDelay = MAX(0.0, 2.0 - elapsed);
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, remainingDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self.loginBtn setLoading:NO];
                if (success) {
                    [self executeSuccessAnimation];
                } else {
                    [self transitionToState:ZXAppStateAuth];
                    
                    // Strict mapping to visually premium error UI
                    switch (errorType) {
                        case ZXAuthErrorExpiredKey:
                            [ZXModalManager showModalWithIcon:@"clock.fill" iconTint:[ZXTheme statusWarning] title:@"License Expired" message:@"This license has expired and can no longer be used." actionTitle:@"TRY ANOTHER KEY" inView:self.view];
                            break;
                        case ZXAuthErrorRevokedKey:
                            [ZXModalManager showModalWithIcon:@"xmark.shield.fill" iconTint:[ZXTheme statusError] title:@"License Revoked" message:@"Access suspended by the administrator." actionTitle:@"DISMISS" inView:self.view];
                            break;
                        case ZXAuthErrorDeviceLimit:
                            [ZXModalManager showModalWithIcon:@"iphone.slash" iconTint:[ZXTheme statusWarning] title:@"Device Limit Reached" message:@"Maximum devices reached for this key. Reset required." actionTitle:@"DISMISS" inView:self.view];
                            break;
                        case ZXAuthErrorInvalidKey:
                            [ZXModalManager showModalWithIcon:@"key.fill" iconTint:[ZXTheme statusError] title:@"Invalid License Key" message:@"The license key does not exist in the database." actionTitle:@"DISMISS" inView:self.view];
                            break;
                        case ZXAuthErrorConnection:
                            [ZXModalManager showModalWithIcon:@"wifi.slash" iconTint:[ZXTheme statusError] title:@"Connection Problem" message:@"We couldn't reach the Zentrax verification service." actionTitle:@"RETRY" inView:self.view];
                            break;
                        case ZXAuthErrorServer:
                            [ZXModalManager showModalWithIcon:@"server.rack" iconTint:[ZXTheme statusError] title:@"Server Error" message:@"The Zentrax server responded with an unexpected status." actionTitle:@"DISMISS" inView:self.view];
                            break;
                        case ZXAuthErrorInvalidSession:
                            [ZXModalManager showModalWithIcon:@"lock.slash.fill" iconTint:[ZXTheme statusWarning] title:@"Session Invalid" message:@"Your secure session has expired or is invalid." actionTitle:@"DISMISS" inView:self.view];
                            break;
                        default:
                            [ZXModalManager showModalWithIcon:@"exclamationmark.triangle.fill" iconTint:[ZXTheme statusError] title:@"Authentication Failed" message:errorMsg ?: @"An unknown error occurred." actionTitle:@"DISMISS" inView:self.view];
                            break;
                    }
                }
            });
        }];
    } else {
        [self.loginBtn setLoading:NO];
        [self transitionToState:ZXAppStateAuth];
        [self showGlobalErrorWithTitle:@"Configuration Error" message:@"Authentication delegate is unavailable."];
    }
}

- (void)executeSuccessAnimation {
    self.verificationStepLabel.text = @"LICENSE VERIFIED";
    self.verificationStepLabel.textColor = [ZXTheme statusSuccess];
    [self.verificationSpinner stopAnimating];
    
    UIImageView *check = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.circle.fill"]];
    check.tintColor = [ZXTheme statusSuccess];
    check.frame = CGRectMake(0, 0, 50, 50);
    check.center = self.verificationSpinner.center;
    check.transform = CGAffineTransformMakeScale(0.1, 0.1);
    [self.verificationContainer addSubview:check];
    
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred];
    
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:0 animations:^{
        check.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [check removeFromSuperview];
            self.verificationStepLabel.textColor = [ZXTheme accentCyan];
            [self.verificationSpinner startAnimating];
            [self transitionToState:ZXAppStateDashboard];
        });
    }];
}

#pragma mark - Verification Screen
- (void)setupVerification {
    _verificationContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_verificationContainer];
    
    _verificationSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _verificationSpinner.color = [ZXTheme accentCyan];
    _verificationSpinner.center = CGPointMake(self.view.center.x, self.view.center.y - 20);
    [_verificationContainer addSubview:_verificationSpinner];
    
    _verificationStepLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.view.center.y + 30, self.view.bounds.size.width - 40, 20)];
    _verificationStepLabel.textColor = [ZXTheme accentCyan];
    _verificationStepLabel.font = [ZXTheme fontMono:12 weight:UIFontWeightBold];
    _verificationStepLabel.textAlignment = NSTextAlignmentCenter;
    [ZXTheme applyTextTracking:_verificationStepLabel spacing:2.0];
    [_verificationContainer addSubview:_verificationStepLabel];
}

#pragma mark - Dashboard Flow
- (void)setupDashboard {
    _dashboardContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_dashboardContainer];
    
    UIView *navBar = [[UIView alloc] init];
    navBar.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:navBar];
    
    UIImageView *navIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"shield.lefthalf.filled"]];
    navIcon.tintColor = [ZXTheme accentCyan];
    navIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [navBar addSubview:navIcon];
    
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.text = @"ZENTRAX VIP";
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
    
    UIButton *logoutBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [logoutBtn setImage:[UIImage systemImageNamed:@"power"] forState:UIControlStateNormal];
    logoutBtn.tintColor = [ZXTheme textMuted];
    logoutBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [logoutBtn addTarget:self action:@selector(handleLogout) forControlEvents:UIControlEventTouchUpInside];
    [navBar addSubview:logoutBtn];
    
    UIView *statusCard = [[UIView alloc] init];
    [ZXTheme applyPremiumGlassmorphismToView:statusCard cornerRadius:16];
    statusCard.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:statusCard];
    
    UILabel *subTitle = [[UILabel alloc] init];
    subTitle.text = @"SUBSCRIPTION STATUS";
    subTitle.textColor = [ZXTheme textMuted];
    subTitle.font = [ZXTheme fontMono:11 weight:UIFontWeightBold];
    [ZXTheme applyTextTracking:subTitle spacing:1.5];
    subTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:subTitle];
    
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.text = @"Active";
    _statusLabel.textColor = [ZXTheme textPrimary];
    _statusLabel.font = [ZXTheme fontHeading:18];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_statusLabel];
    
    _expiryLabel = [[UILabel alloc] init];
    _expiryLabel.text = @"Validating...";
    _expiryLabel.textColor = [ZXTheme textSecondary];
    _expiryLabel.font = [ZXTheme fontBody:13 weight:UIFontWeightRegular];
    _expiryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_expiryLabel];
    
    UIImageView *cardIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.seal.fill"]];
    cardIcon.tintColor = [ZXTheme statusSuccess];
    cardIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:cardIcon];
    
    _modulesScrollView = [[UIScrollView alloc] init];
    _modulesScrollView.showsVerticalScrollIndicator = NO;
    _modulesScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _modulesScrollView.alwaysBounceVertical = YES;
    [_dashboardContainer addSubview:_modulesScrollView];
    
    // Auto Layout StackView for dynamic scrolling content
    _modulesStackView = [[UIStackView alloc] init];
    _modulesStackView.axis = UILayoutConstraintAxisVertical;
    _modulesStackView.spacing = 16;
    _modulesStackView.alignment = UIStackViewAlignmentFill;
    _modulesStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [_modulesScrollView addSubview:_modulesStackView];
    
    [self createEmptyStateView];
    
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
        
        [statusDot.leadingAnchor constraintEqualToAnchor:navTitle.trailingAnchor constant:8],
        [statusDot.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],
        [statusDot.widthAnchor constraintEqualToConstant:8],
        [statusDot.heightAnchor constraintEqualToConstant:8],
        
        [logoutBtn.trailingAnchor constraintEqualToAnchor:navBar.trailingAnchor],
        [logoutBtn.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],
        [logoutBtn.widthAnchor constraintEqualToConstant:32],
        [logoutBtn.heightAnchor constraintEqualToConstant:32],
        
        [statusCard.topAnchor constraintEqualToAnchor:navBar.bottomAnchor constant:24],
        [statusCard.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [statusCard.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [statusCard.heightAnchor constraintEqualToConstant:100],
        
        [subTitle.topAnchor constraintEqualToAnchor:statusCard.topAnchor constant:20],
        [subTitle.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:24],
        
        [_statusLabel.topAnchor constraintEqualToAnchor:subTitle.bottomAnchor constant:8],
        [_statusLabel.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:24],
        
        [_expiryLabel.topAnchor constraintEqualToAnchor:_statusLabel.bottomAnchor constant:4],
        [_expiryLabel.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:24],
        
        [cardIcon.trailingAnchor constraintEqualToAnchor:statusCard.trailingAnchor constant:-24],
        [cardIcon.centerYAnchor constraintEqualToAnchor:statusCard.centerYAnchor],
        [cardIcon.widthAnchor constraintEqualToConstant:36],
        [cardIcon.heightAnchor constraintEqualToConstant:36],
        
        [_modulesScrollView.topAnchor constraintEqualToAnchor:statusCard.bottomAnchor constant:24],
        [_modulesScrollView.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor],
        [_modulesScrollView.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor],
        [_modulesScrollView.bottomAnchor constraintEqualToAnchor:_dashboardContainer.bottomAnchor],
        
        [_modulesStackView.topAnchor constraintEqualToAnchor:_modulesScrollView.contentLayoutGuide.topAnchor constant:10],
        [_modulesStackView.leadingAnchor constraintEqualToAnchor:_modulesScrollView.frameLayoutGuide.leadingAnchor constant:24],
        [_modulesStackView.trailingAnchor constraintEqualToAnchor:_modulesScrollView.frameLayoutGuide.trailingAnchor constant:-24],
        [_modulesStackView.bottomAnchor constraintEqualToAnchor:_modulesScrollView.contentLayoutGuide.bottomAnchor constant:-40]
    ]];
}

- (void)createEmptyStateView {
    _emptyStateView = [[UIView alloc] init];
    _emptyStateView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIView *iconContainer = [[UIView alloc] init];
    iconContainer.layer.cornerRadius = 35;
    iconContainer.backgroundColor = [[ZXTheme accentCyan] colorWithAlphaComponent:0.1];
    iconContainer.layer.shadowColor = [ZXTheme accentCyan].CGColor;
    iconContainer.layer.shadowRadius = 20;
    iconContainer.layer.shadowOpacity = 0.5;
    iconContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyStateView addSubview:iconContainer];
    
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"cube.transparent"]];
    icon.tintColor = [ZXTheme accentCyan];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [iconContainer addSubview:icon];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"No Functions Available";
    title.textColor = [ZXTheme textPrimary];
    title.font = [ZXTheme fontHeading:18];
    title.textAlignment = NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyStateView addSubview:title];
    
    UILabel *sub = [[UILabel alloc] init];
    sub.text = @"There are currently no functions available or enabled for your account.";
    sub.textColor = [ZXTheme textSecondary];
    sub.font = [ZXTheme fontBody:14 weight:UIFontWeightRegular];
    sub.textAlignment = NSTextAlignmentCenter;
    sub.numberOfLines = 0;
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyStateView addSubview:sub];
    
    [NSLayoutConstraint activateConstraints:@[
        [_emptyStateView.heightAnchor constraintEqualToConstant:250],
        
        [iconContainer.topAnchor constraintEqualToAnchor:_emptyStateView.topAnchor constant:20],
        [iconContainer.centerXAnchor constraintEqualToAnchor:_emptyStateView.centerXAnchor],
        [iconContainer.widthAnchor constraintEqualToConstant:70],
        [iconContainer.heightAnchor constraintEqualToConstant:70],
        
        [icon.centerXAnchor constraintEqualToAnchor:iconContainer.centerXAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:iconContainer.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:36],
        [icon.heightAnchor constraintEqualToConstant:36],
        
        [title.topAnchor constraintEqualToAnchor:iconContainer.bottomAnchor constant:24],
        [title.leadingAnchor constraintEqualToAnchor:_emptyStateView.leadingAnchor],
        [title.trailingAnchor constraintEqualToAnchor:_emptyStateView.trailingAnchor],
        
        [sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:12],
        [sub.leadingAnchor constraintEqualToAnchor:_emptyStateView.leadingAnchor constant:20],
        [sub.trailingAnchor constraintEqualToAnchor:_emptyStateView.trailingAnchor constant:-20]
    ]];
}

- (void)updateDashboardWithModules:(NSArray<NSDictionary *> *)modules {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        for (UIView *view in self.modulesStackView.arrangedSubviews) {
            [self.modulesStackView removeArrangedSubview:view];
            [view removeFromSuperview];
        }
        
        if (!modules || modules.count == 0) {
            [self.modulesStackView addArrangedSubview:self.emptyStateView];
            self.emptyStateView.alpha = 0;
            self.emptyStateView.transform = CGAffineTransformMakeScale(0.9, 0.9);
            [UIView animateWithDuration:0.5 delay:0.2 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.emptyStateView.alpha = 1;
                self.emptyStateView.transform = CGAffineTransformIdentity;
            } completion:nil];
            return;
        }
        
        UILabel *sectionHeader = [[UILabel alloc] init];
        sectionHeader.text = @"CONTROL CENTER";
        sectionHeader.textColor = [ZXTheme accentCyan];
        sectionHeader.font = [ZXTheme fontMono:11 weight:UIFontWeightBold];
        [ZXTheme applyTextTracking:sectionHeader spacing:2.0];
        [self.modulesStackView addArrangedSubview:sectionHeader];
        [self.modulesStackView setCustomSpacing:20 afterView:sectionHeader];
        
        for (NSDictionary *mod in modules) {
            NSString *moduleName = mod[@"name"] ?: @"UNKNOWN FEATURE";
            NSString *moduleDesc = mod[@"desc"] ?: mod[@"description"] ?: @"No description provided.";
            NSString *currentState = mod[@"current_state"] ?: @"OFF"; 
            BOOL isModOn = [currentState isEqualToString:@"ON"];
            
            UIView *card = [[UIView alloc] init];
            [ZXTheme applyPremiumGlassmorphismToView:card cornerRadius:16];
            card.translatesAutoresizingMaskIntoConstraints = NO;
            
            UIView *iconContainer = [[UIView alloc] init];
            iconContainer.backgroundColor = [[ZXTheme accentCyan] colorWithAlphaComponent:0.1];
            iconContainer.layer.cornerRadius = 8;
            iconContainer.layer.shadowColor = [ZXTheme accentCyan].CGColor;
            iconContainer.layer.shadowRadius = 8;
            iconContainer.layer.shadowOpacity = 0.3;
            iconContainer.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:iconContainer];
            
            UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"bolt.fill"]];
            icon.tintColor = [ZXTheme accentCyan];
            icon.translatesAutoresizingMaskIntoConstraints = NO;
            [iconContainer addSubview:icon];
            
            UILabel *t = [[UILabel alloc] init];
            t.text = [moduleName uppercaseString];
            t.textColor = [ZXTheme textPrimary];
            t.font = [ZXTheme fontHeading:15];
            t.numberOfLines = 0;
            t.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:t];
            
            ZXToggle *toggle = [[ZXToggle alloc] init];
            toggle.moduleId = moduleName; 
            [toggle setOn:isModOn animated:NO]; 
            [toggle addTarget:self action:@selector(moduleToggled:) forControlEvents:UIControlEventValueChanged];
            [card addSubview:toggle];
            
            UIView *line = [[UIView alloc] init];
            line.backgroundColor = [ZXTheme borderSubtle];
            line.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:line];
            
            UILabel *s = [[UILabel alloc] init];
            s.text = moduleDesc;
            s.textColor = [ZXTheme textSecondary];
            s.font = [ZXTheme fontBody:13 weight:UIFontWeightRegular];
            s.numberOfLines = 0;
            s.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:s];
            
            [NSLayoutConstraint activateConstraints:@[
                [iconContainer.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
                [iconContainer.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
                [iconContainer.widthAnchor constraintEqualToConstant:40],
                [iconContainer.heightAnchor constraintEqualToConstant:40],
                
                [icon.centerXAnchor constraintEqualToAnchor:iconContainer.centerXAnchor],
                [icon.centerYAnchor constraintEqualToAnchor:iconContainer.centerYAnchor],
                [icon.widthAnchor constraintEqualToConstant:20],
                [icon.heightAnchor constraintEqualToConstant:20],
                
                [toggle.centerYAnchor constraintEqualToAnchor:iconContainer.centerYAnchor],
                [toggle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
                
                [t.centerYAnchor constraintEqualToAnchor:iconContainer.centerYAnchor],
                [t.leadingAnchor constraintEqualToAnchor:iconContainer.trailingAnchor constant:16],
                [t.trailingAnchor constraintEqualToAnchor:toggle.leadingAnchor constant:-16],
                
                [line.topAnchor constraintEqualToAnchor:iconContainer.bottomAnchor constant:16],
                [line.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
                [line.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
                [line.heightAnchor constraintEqualToConstant:1],
                
                [s.topAnchor constraintEqualToAnchor:line.bottomAnchor constant:16],
                [s.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
                [s.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
                [s.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20]
            ]];
            
            [self.modulesStackView addArrangedSubview:card];
            
            card.alpha = 0;
            card.transform = CGAffineTransformMakeTranslation(0, 20);
            [UIView animateWithDuration:0.5 delay:([modules indexOfObject:mod] * 0.08) usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                card.alpha = 1;
                card.transform = CGAffineTransformIdentity;
            } completion:nil];
        }
    });
}

- (void)updateSubscriptionState:(NSDictionary *)subData {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *expiryStr = subData[@"expiry"];
        if ([expiryStr isEqualToString:@"Lifetime"]) {
            self.expiryLabel.text = @"Expires: Lifetime Access";
            self.expiryLabel.textColor = [ZXTheme accentCyan];
        } else if (expiryStr) {
            self.expiryLabel.text = [NSString stringWithFormat:@"Expires: %@", expiryStr];
            self.expiryLabel.textColor = [ZXTheme textSecondary];
        } else {
            self.expiryLabel.text = @"No Expiry Data";
        }
        
        self.statusLabel.text = subData[@"status"] ?: @"Active";
    });
}

- (void)moduleToggled:(ZXToggle *)sender {
    NSString *networkModuleId = sender.moduleId;
    if (!networkModuleId) return;
    
    // Lock interaction & show loading state immediately
    [sender setLoading:YES];
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestModuleToggle:state:completion:)]) {
        // Delegate invokes the 2-step process (get_payload -> file write -> sync_state)
        [self.delegate zentraxDidRequestModuleToggle:networkModuleId state:sender.isOn completion:^(BOOL success, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setLoading:NO];
                if (!success) {
                    // Safe Rollback - Visual revert without triggering event again
                    [sender setOn:!sender.isOn animated:YES];
                    [self showGlobalErrorWithTitle:@"Execution Failed" message:errorMsg ?: @"Failed to safely apply the requested modification to the target file."];
                }
            });
        }];
    } else {
        [sender setLoading:NO];
        [sender setOn:!sender.isOn animated:YES]; 
        [self showGlobalErrorWithTitle:@"Bridge Disconnected" message:@"Execution delegate is unavailable. Cannot process action."];
    }
}

#pragma mark - Logout and Errors
- (void)handleLogout {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Disconnect Session?" message:@"Your secured connection will be closed and hardware binding will remain." preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Disconnect" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if ([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) {
            [self.delegate zentraxDidRequestLogoutWithCompletion:^{
                self.keyInput.textField.text = @"";
                [self.keyInput updateFloatingLabelStateAnimated:NO];
                [self transitionToState:ZXAppStateAuth];
            }];
        }
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

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
    [self showGlobalErrorWithTitle:@"CONNECTION ERROR" message:@"Secure connection to the Zentrax VIP network could not be established."];
}

- (void)showServerError {
    [self showGlobalErrorWithTitle:@"Server Error" message:@"The Zentrax server responded with an unexpected status. Please try again."];
}

- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds {
    NSString *msg = [NSString stringWithFormat:@"Request limits reached. Cooldown active for %ld seconds.", (long)seconds];
    [ZXModalManager showModalWithIcon:@"timer" iconTint:[ZXTheme statusWarning] title:@"RATE LIMITED" message:msg actionTitle:@"UNDERSTOOD" inView:self.view];
}

- (void)showGlobalLoadingState:(NSString *)message {}
- (void)hideGlobalLoadingState {}

@end
