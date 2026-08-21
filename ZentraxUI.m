//
//  ZentraxUI.m
//  Zentrax VIP - Premium Execution Node UI
//
//  Created by Zentrax Team.
//  Architecture: Ultra-Premium SaaS Vault Layer
//  Status: PRODUCTION READY
//

#import "ZentraxUI.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>

#pragma mark - ================= VAULT DESIGN SYSTEM =================

@interface ZXTheme : NSObject

+ (UIColor *)bgDeepSpace;
+ (UIColor *)bgCardOuter;
+ (UIColor *)bgCardInner;
+ (UIColor *)borderSubtle;
+ (UIColor *)borderActive;

+ (UIColor *)accentPurple;
+ (UIColor *)accentBlue;
+ (UIColor *)accentCyan;

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

+ (CAGradientLayer *)vaultGradient;
+ (void)applyTextTracking:(UILabel *)label spacing:(CGFloat)spacing;

@end

@implementation ZXTheme

// Deep dark navy/purple background matching the web UI
+ (UIColor *)bgDeepSpace { return [UIColor colorWithRed:0.04 green:0.03 blue:0.08 alpha:1.0]; }
// Elevated cards
+ (UIColor *)bgCardOuter { return [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:0.95]; }
// Inner fields
+ (UIColor *)bgCardInner { return [UIColor colorWithRed:0.05 green:0.05 blue:0.08 alpha:1.0]; }

+ (UIColor *)borderSubtle { return [UIColor colorWithRed:0.20 green:0.18 blue:0.30 alpha:0.6]; }
+ (UIColor *)borderActive { return [self accentPurple]; }

// Exact Premium Zentrax Branding Colors
+ (UIColor *)accentPurple { return [UIColor colorWithRed:0.55 green:0.15 blue:1.0 alpha:1.0]; } // #8C26FF
+ (UIColor *)accentBlue { return [UIColor colorWithRed:0.23 green:0.51 blue:0.96 alpha:1.0]; }   // #3B82F6
+ (UIColor *)accentCyan { return [UIColor colorWithRed:0.0 green:0.85 blue:1.0 alpha:1.0]; }     // #00D8FF

+ (UIColor *)textPrimary { return [UIColor colorWithWhite:0.98 alpha:1.0]; }
+ (UIColor *)textSecondary { return [UIColor colorWithWhite:0.75 alpha:1.0]; }
+ (UIColor *)textMuted { return [UIColor colorWithRed:0.45 green:0.45 blue:0.55 alpha:1.0]; }

+ (UIColor *)statusSuccess { return [UIColor colorWithRed:0.10 green:0.80 blue:0.55 alpha:1.0]; }
+ (UIColor *)statusWarning { return [UIColor colorWithRed:0.96 green:0.65 blue:0.14 alpha:1.0]; }
+ (UIColor *)statusError { return [UIColor colorWithRed:1.0 green:0.25 blue:0.35 alpha:1.0]; }

+ (UIFont *)fontDisplay:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBlack]; }
+ (UIFont *)fontHeading:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBold]; }
+ (UIFont *)fontBody:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont systemFontOfSize:size weight:weight]; }
+ (UIFont *)fontMono:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont monospacedSystemFontOfSize:size weight:weight]; }

+ (CAGradientLayer *)vaultGradient {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[(id)[self accentPurple].CGColor, (id)[self accentBlue].CGColor];
    gradient.startPoint = CGPointMake(0.0, 0.5);
    gradient.endPoint = CGPointMake(1.0, 0.5);
    return gradient;
}

+ (void)applyTextTracking:(UILabel *)label spacing:(CGFloat)spacing {
    if (!label.text) return;
    NSDictionary *attrs = @{NSKernAttributeName: @(spacing)};
    label.attributedText = [[NSAttributedString alloc] initWithString:label.text attributes:attrs];
}

@end

#pragma mark - ================= PREMIUM COMPONENTS =================

@interface ZXVaultButton : UIButton
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSString *originalTitle;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIImageView *arrowIcon;
- (void)setLoading:(BOOL)loading;
@end

@implementation ZXVaultButton

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
        
        _gradientLayer = [ZXTheme vaultGradient];
        [_bgView.layer insertSublayer:_gradientLayer atIndex:0];
        
        // Subtle outer glow
        self.layer.shadowColor = [ZXTheme accentPurple].CGColor;
        self.layer.shadowOpacity = 0.4;
        self.layer.shadowRadius = 12;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        _spinner.color = [UIColor whiteColor];
        _spinner.hidesWhenStopped = YES;
        _spinner.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_spinner];
        
        _arrowIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"arrow.right"]];
        _arrowIcon.tintColor = [UIColor whiteColor];
        _arrowIcon.contentMode = UIViewContentModeScaleAspectFit;
        _arrowIcon.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_arrowIcon];
        
        [NSLayoutConstraint activateConstraints:@[
            [_bgView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_bgView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_bgView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_bgView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            
            [_spinner.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [_spinner.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            
            [_arrowIcon.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20],
            [_arrowIcon.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_arrowIcon.widthAnchor constraintEqualToConstant:16],
            [_arrowIcon.heightAnchor constraintEqualToConstant:16]
        ]];
        
        [self bringSubviewToFront:self.titleLabel];
        
        [self addTarget:self action:@selector(touchDown) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.bgView.bounds;
}

- (void)touchDown {
    if (!self.userInteractionEnabled) return;
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid];
    [haptic impactOccurred];
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformMakeScale(0.96, 0.96);
        self.layer.shadowOpacity = 0.8;
        self.layer.shadowRadius = 8;
    } completion:nil];
}

- (void)touchUp {
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.transform = CGAffineTransformIdentity;
        self.layer.shadowOpacity = 0.4;
        self.layer.shadowRadius = 12;
    } completion:nil];
}

- (void)setLoading:(BOOL)loading {
    self.userInteractionEnabled = !loading;
    if (loading) {
        self.originalTitle = [self titleForState:UIControlStateNormal];
        [self setTitle:@"" forState:UIControlStateNormal];
        self.arrowIcon.alpha = 0;
        [self.spinner startAnimating];
        self.bgView.alpha = 0.8;
    } else {
        [self setTitle:self.originalTitle forState:UIControlStateNormal];
        self.arrowIcon.alpha = 1;
        [self.spinner stopAnimating];
        self.bgView.alpha = 1.0;
    }
}
@end

@interface ZXVaultField : UIView <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UILabel *topLabel;
@property (nonatomic, strong) UIButton *pasteButton;
@property (nonatomic, strong) UIView *inputContainer;
@property (nonatomic, strong) UIImageView *iconView;
@end

@implementation ZXVaultField

- (instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
        
        _topLabel = [[UILabel alloc] init];
        _topLabel.text = @"Master License Key";
        _topLabel.textColor = [ZXTheme textPrimary];
        _topLabel.font = [ZXTheme fontHeading:13];
        _topLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_topLabel];
        
        _inputContainer = [[UIView alloc] init];
        _inputContainer.backgroundColor = [ZXTheme bgCardInner];
        _inputContainer.layer.cornerRadius = 12;
        _inputContainer.layer.borderWidth = 1.0;
        _inputContainer.layer.borderColor = [ZXTheme borderSubtle].CGColor;
        _inputContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_inputContainer];
        
        _iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"shield.keyhole.fill"]];
        _iconView.tintColor = [ZXTheme textMuted];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.translatesAutoresizingMaskIntoConstraints = NO;
        [_inputContainer addSubview:_iconView];
        
        _textField = [[UITextField alloc] init];
        _textField.textColor = [ZXTheme textPrimary];
        _textField.font = [ZXTheme fontMono:15 weight:UIFontWeightSemibold];
        _textField.secureTextEntry = YES;
        _textField.delegate = self;
        _textField.translatesAutoresizingMaskIntoConstraints = NO;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textField.returnKeyType = UIReturnKeyDone;
        _textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"ZTX-XXXX-XXXX-XXXX" attributes:@{NSForegroundColorAttributeName: [ZXTheme textMuted]}];
        [_inputContainer addSubview:_textField];
        
        _pasteButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_pasteButton setTitle:@"Paste" forState:UIControlStateNormal];
        _pasteButton.titleLabel.font = [ZXTheme fontHeading:13];
        _pasteButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        _pasteButton.layer.cornerRadius = 8;
        [_pasteButton setTitleColor:[ZXTheme textPrimary] forState:UIControlStateNormal];
        _pasteButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_pasteButton addTarget:self action:@selector(pasteKeyTapped) forControlEvents:UIControlEventTouchUpInside];
        [_inputContainer addSubview:_pasteButton];
        
        [NSLayoutConstraint activateConstraints:@[
            [_topLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_topLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:4],
            
            [_inputContainer.topAnchor constraintEqualToAnchor:_topLabel.bottomAnchor constant:8],
            [_inputContainer.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_inputContainer.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_inputContainer.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [_inputContainer.heightAnchor constraintEqualToConstant:56],
            
            [_iconView.leadingAnchor constraintEqualToAnchor:_inputContainer.leadingAnchor constant:16],
            [_iconView.centerYAnchor constraintEqualToAnchor:_inputContainer.centerYAnchor],
            [_iconView.widthAnchor constraintEqualToConstant:18],
            [_iconView.heightAnchor constraintEqualToConstant:18],
            
            [_pasteButton.trailingAnchor constraintEqualToAnchor:_inputContainer.trailingAnchor constant:-12],
            [_pasteButton.centerYAnchor constraintEqualToAnchor:_inputContainer.centerYAnchor],
            [_pasteButton.heightAnchor constraintEqualToConstant:32],
            [_pasteButton.widthAnchor constraintEqualToConstant:64],
            
            [_textField.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor constant:12],
            [_textField.trailingAnchor constraintEqualToAnchor:_pasteButton.leadingAnchor constant:-12],
            [_textField.centerYAnchor constraintEqualToAnchor:_inputContainer.centerYAnchor],
            [_textField.heightAnchor constraintEqualToConstant:40]
        ]];
    }
    return self;
}

- (void)pasteKeyTapped {
    NSString *pb = [[UIPasteboard generalPasteboard].string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (pb.length > 0) {
        self.textField.text = pb;
        [self.textField sendActionsForControlEvents:UIControlEventEditingChanged];
        UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [haptic impactOccurred];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.3 animations:^{
        self.inputContainer.layer.borderColor = [ZXTheme accentPurple].CGColor;
        self.iconView.tintColor = [ZXTheme accentPurple];
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.3 animations:^{
        self.inputContainer.layer.borderColor = [ZXTheme borderSubtle].CGColor;
        self.iconView.tintColor = [ZXTheme textMuted];
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end

@interface ZXVaultToggle : UIControl
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, strong) NSString *moduleId; 
@property (nonatomic, strong) UIView *trackView;
@property (nonatomic, strong) UIView *thumbView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSLayoutConstraint *thumbLeadingConstraint;
@end

@implementation ZXVaultToggle

- (instancetype)init {
    if (self = [super init]) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        [NSLayoutConstraint activateConstraints:@[
            [self.widthAnchor constraintEqualToConstant:50],
            [self.heightAnchor constraintEqualToConstant:28]
        ]];
        
        _trackView = [[UIView alloc] init];
        _trackView.backgroundColor = [ZXTheme bgCardInner];
        _trackView.layer.cornerRadius = 14;
        _trackView.layer.borderWidth = 1.0;
        _trackView.layer.borderColor = [ZXTheme borderSubtle].CGColor;
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
        _spinner.userInteractionEnabled = NO;
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
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
        [self addGestureRecognizer:tap];
        
        [self updateStateAnimated:NO];
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return CGRectContainsPoint(CGRectInset(self.bounds, -15, -15), point);
}

- (void)handleTap {
    if (!self.userInteractionEnabled) return;
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [haptic impactOccurred];
    
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
            self.trackView.layer.borderColor = [ZXTheme accentCyan].CGColor;
            self.trackView.backgroundColor = [[ZXTheme accentCyan] colorWithAlphaComponent:0.15];
            self.thumbView.backgroundColor = [ZXTheme accentCyan];
            self.thumbView.layer.shadowColor = [ZXTheme accentCyan].CGColor;
            self.thumbView.layer.shadowOpacity = 0.8;
            self.thumbView.layer.shadowRadius = 6;
        } else {
            self.trackView.layer.borderColor = [ZXTheme borderSubtle].CGColor;
            self.trackView.backgroundColor = [ZXTheme bgCardInner];
            self.thumbView.backgroundColor = [ZXTheme textMuted];
            self.thumbView.layer.shadowOpacity = 0.0;
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.4 options:UIViewAnimationOptionCurveEaseInOut animations:stateUpdates completion:nil];
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

#pragma mark - ================= MODAL MANAGER =================

@interface ZXModalManager : NSObject
+ (void)showModalWithIcon:(NSString *)iconName iconTint:(UIColor *)tint title:(NSString *)title message:(NSString *)msg actionTitle:(NSString *)actTitle inView:(UIView *)parentView;
@end

@implementation ZXModalManager

+ (void)showModalWithIcon:(NSString *)iconName iconTint:(UIColor *)tint title:(NSString *)title message:(NSString *)msg actionTitle:(NSString *)actTitle inView:(UIView *)parentView {
    
    UIView *overlay = [[UIView alloc] initWithFrame:parentView.bounds];
    overlay.tag = 100100;
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    overlay.alpha = 0;
    [parentView addSubview:overlay];
    
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [ZXTheme bgCardOuter];
    card.layer.cornerRadius = 24;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [ZXTheme borderSubtle].CGColor;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [overlay addSubview:card];
    
    card.layer.shadowColor = tint.CGColor;
    card.layer.shadowOpacity = 0.15;
    card.layer.shadowRadius = 40;
    card.layer.shadowOffset = CGSizeMake(0, 15);
    
    UIView *iconContainer = [[UIView alloc] init];
    iconContainer.backgroundColor = [tint colorWithAlphaComponent:0.1];
    iconContainer.layer.cornerRadius = 30;
    iconContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:iconContainer];
    
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    iconView.tintColor = tint;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [iconContainer addSubview:iconView];
    
    UILabel *titleLbl = [[UILabel alloc] init];
    titleLbl.text = [title uppercaseString];
    titleLbl.textColor = [ZXTheme textPrimary];
    titleLbl.font = [ZXTheme fontDisplay:16];
    [ZXTheme applyTextTracking:titleLbl spacing:1.0];
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
    
    ZXVaultButton *btn = [[ZXVaultButton alloc] init];
    [btn setTitle:actTitle forState:UIControlStateNormal];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:btn];
    
    [NSLayoutConstraint activateConstraints:@[
        [card.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
        [card.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [card.widthAnchor constraintEqualToConstant:320],
        
        [iconContainer.topAnchor constraintEqualToAnchor:card.topAnchor constant:32],
        [iconContainer.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [iconContainer.widthAnchor constraintEqualToConstant:60],
        [iconContainer.heightAnchor constraintEqualToConstant:60],
        
        [iconView.centerXAnchor constraintEqualToAnchor:iconContainer.centerXAnchor],
        [iconView.centerYAnchor constraintEqualToAnchor:iconContainer.centerYAnchor],
        [iconView.widthAnchor constraintEqualToConstant:28],
        [iconView.heightAnchor constraintEqualToConstant:28],
        
        [titleLbl.topAnchor constraintEqualToAnchor:iconContainer.bottomAnchor constant:20],
        [titleLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [titleLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        
        [msgLbl.topAnchor constraintEqualToAnchor:titleLbl.bottomAnchor constant:8],
        [msgLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [msgLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        
        [btn.topAnchor constraintEqualToAnchor:msgLbl.bottomAnchor constant:32],
        [btn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [btn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        [btn.heightAnchor constraintEqualToConstant:54],
        [btn.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-24]
    ]];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissOverlay:)];
    [btn addTarget:self action:@selector(dismissBtnTapped:) forControlEvents:UIControlEventTouchUpInside];
    [overlay addGestureRecognizer:tap];
    
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
    [haptic impactOccurred];
    
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        overlay.alpha = 1.0;
        card.transform = CGAffineTransformIdentity;
    } completion:nil];
}

+ (void)dismissOverlay:(UITapGestureRecognizer *)sender {
    if (sender.view.tag == 100100) {
        [self animateDismiss:sender.view];
    }
}

+ (void)dismissBtnTapped:(UIButton *)btn {
    UIView *card = btn.superview;
    UIView *overlay = card.superview;
    if (overlay.tag == 100100) {
        [self animateDismiss:overlay];
    }
}

+ (void)animateDismiss:(UIView *)overlay {
    [UIView animateWithDuration:0.25 animations:^{
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
@property (nonatomic, strong) UIImageView *splashShield;
@property (nonatomic, strong) UIView *scannerLine;

// Auth elements
@property (nonatomic, strong) ZXVaultField *keyInput;
@property (nonatomic, strong) ZXVaultButton *loginBtn;
@property (nonatomic, strong) UITapGestureRecognizer *dismissTap;

// Dashboard elements
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *expiryLabel;
@property (nonatomic, strong) UIScrollView *modulesScrollView;
@property (nonatomic, strong) UIStackView *modulesStackView; 
@property (nonatomic, strong) UIView *emptyStateView;

// Heartbeat
@property (nonatomic, strong) NSTimer *heartbeatTimer;

@end

@implementation ZentraxUI

- (void)dealloc {
    [_heartbeatTimer invalidate];
    _heartbeatTimer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [ZXTheme bgDeepSpace];
    self.currentState = ZXAppStateInit;
    
    self.dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    self.dismissTap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:self.dismissTap];
    
    [self setupVaultAmbientBackground];
    
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
    [self stopHeartbeatMonitor];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - Keyboard Handling
- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect kbFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGRect btnRect = [self.authContainer convertRect:self.loginBtn.frame toView:self.view];
    CGFloat overlap = CGRectGetMaxY(btnRect) - kbFrame.origin.y;
    
    if (overlap > 0) {
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            weakSelf.authContainer.transform = CGAffineTransformMakeTranslation(0, -(overlap + 30));
        } completion:nil];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.authContainer.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)setupVaultAmbientBackground {
    // Elegant Web-like Grid
    UIImageView *grid = [[UIImageView alloc] initWithFrame:self.view.bounds];
    grid.image = [self createGridImage];
    grid.alpha = 0.25;
    grid.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:grid];
    
    // Soft Purple Glow Top Right
    UIView *topGlow = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 200, -100, 400, 400)];
    topGlow.backgroundColor = [[ZXTheme accentPurple] colorWithAlphaComponent:0.15];
    topGlow.layer.cornerRadius = 200;
    topGlow.layer.shadowColor = [ZXTheme accentPurple].CGColor;
    topGlow.layer.shadowRadius = 100;
    topGlow.layer.shadowOpacity = 1.0;
    [self.view addSubview:topGlow];
    
    // Soft Blue Glow Bottom Left
    UIView *bottomGlow = [[UIView alloc] initWithFrame:CGRectMake(-150, self.view.bounds.size.height - 200, 400, 400)];
    bottomGlow.backgroundColor = [[ZXTheme accentBlue] colorWithAlphaComponent:0.1];
    bottomGlow.layer.cornerRadius = 200;
    bottomGlow.layer.shadowColor = [ZXTheme accentBlue].CGColor;
    bottomGlow.layer.shadowRadius = 120;
    bottomGlow.layer.shadowOpacity = 1.0;
    [self.view addSubview:bottomGlow];
    
    [UIView animateWithDuration:15.0 delay:0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut animations:^{
        topGlow.transform = CGAffineTransformMakeTranslation(-50, 50);
        bottomGlow.transform = CGAffineTransformMakeTranslation(50, -50);
    } completion:nil];
}

- (UIImage *)createGridImage {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:0.5 green:0.3 blue:0.8 alpha:0.1].CGColor);
    CGContextSetLineWidth(context, 1.0);
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, 40, 0);
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, 0, 40);
    CGContextStrokePath(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeTile];
}

#pragma mark - State Machine & Heartbeat Protection
- (void)transitionToState:(ZXAppState)newState {
    if (self.currentState == newState) return;
    self.currentState = newState;
    self.dismissTap.enabled = (newState != ZXAppStateDashboard);
    
    if (newState == ZXAppStateDashboard) {
        [self startHeartbeatMonitor];
    } else {
        [self stopHeartbeatMonitor];
    }
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.splashContainer.alpha = (newState == ZXAppStateSplash) ? 1.0 : 0.0;
        weakSelf.authContainer.alpha = (newState == ZXAppStateAuth) ? 1.0 : 0.0;
        weakSelf.verificationContainer.alpha = (newState == ZXAppStateVerifying) ? 1.0 : 0.0;
        weakSelf.dashboardContainer.alpha = (newState == ZXAppStateDashboard) ? 1.0 : 0.0;
    } completion:nil];
}

- (void)startHeartbeatMonitor {
    [self stopHeartbeatMonitor];
    // Background validation loop
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
        __weak typeof(self) weakSelf = self;
        [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL isValid) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                
                if (!isValid) {
                    // Check if token was purged natively (indicating explicit revocation/expiration)
                    BOOL sessionRemainsActive = YES;
                    Class networkManagerClass = NSClassFromString(@"ZentraxNetworkManager");
                    if (networkManagerClass) {
                        id sharedInst = [networkManagerClass performSelector:NSSelectorFromString(@"sharedManager")];
                        if (sharedInst) {
                            SEL checkSel = NSSelectorFromString(@"hasActiveSession");
                            if ([sharedInst respondsToSelector:checkSel]) {
                                sessionRemainsActive = ((BOOL (*)(id, SEL))[(id)sharedInst methodForSelector:checkSel])(sharedInst, checkSel);
                            }
                        }
                    }
                    
                    if (!sessionRemainsActive) {
                        [strongSelf handleRevokedSessionEnvironment];
                    }
                }
            });
        }];
    }
}

// Auto-Logout and Module Kill-Switch
- (void)handleRevokedSessionEnvironment {
    [self stopHeartbeatMonitor];
    
    // Kill visually active modules
    for (UIView *card in self.modulesStackView.arrangedSubviews) {
        ZXVaultToggle *toggle = [self findToggleInCard:card];
        if (toggle) {
            toggle.userInteractionEnabled = NO;
            [toggle setOn:NO animated:YES];
        }
    }
    
    [self showGlobalErrorWithTitle:@"ACCESS REVOKED" message:@"Your license has been disabled or expired by the administrator."];
    
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        if ([strongSelf.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) {
            [strongSelf.delegate zentraxDidRequestLogoutWithCompletion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    strongSelf.keyInput.textField.text = @"";
                    [strongSelf transitionToState:ZXAppStateAuth];
                });
            }];
        } else {
            [strongSelf transitionToState:ZXAppStateAuth];
        }
    });
}

#pragma mark - Premium Splash Sequence
- (void)setupSplash {
    _splashContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_splashContainer];
    
    UIView *iconBg = [[UIView alloc] init];
    iconBg.backgroundColor = [[ZXTheme accentPurple] colorWithAlphaComponent:0.15];
    iconBg.layer.cornerRadius = 45;
    iconBg.layer.shadowColor = [ZXTheme accentPurple].CGColor;
    iconBg.layer.shadowRadius = 20;
    iconBg.layer.shadowOpacity = 0.8;
    iconBg.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:iconBg];
    
    _splashShield = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"shield.lefthalf.filled"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    _splashShield.tintColor = [ZXTheme accentPurple];
    _splashShield.contentMode = UIViewContentModeScaleAspectFit;
    _splashShield.translatesAutoresizingMaskIntoConstraints = NO;
    [iconBg addSubview:_splashShield];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"ZENTRAX";
    title.textColor = [UIColor whiteColor];
    title.font = [ZXTheme fontDisplay:26];
    [ZXTheme applyTextTracking:title spacing:4.0];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:title];
    
    UIView *badge = [[UIView alloc] init];
    badge.backgroundColor = [[ZXTheme accentBlue] colorWithAlphaComponent:0.15];
    badge.layer.cornerRadius = 12;
    badge.layer.borderWidth = 1.0;
    badge.layer.borderColor = [ZXTheme accentBlue].CGColor;
    badge.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:badge];
    
    UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(10, 9, 6, 6)];
    dot.backgroundColor = [ZXTheme accentBlue];
    dot.layer.cornerRadius = 3;
    [badge addSubview:dot];
    
    UILabel *sub = [[UILabel alloc] initWithFrame:CGRectMake(22, 0, 150, 24)];
    sub.text = @"Zentrax License Center";
    sub.textColor = [ZXTheme accentBlue];
    sub.font = [ZXTheme fontHeading:11];
    [badge addSubview:sub];
    
    [NSLayoutConstraint activateConstraints:@[
        [iconBg.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [iconBg.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor constant:-60],
        [iconBg.widthAnchor constraintEqualToConstant:90],
        [iconBg.heightAnchor constraintEqualToConstant:90],
        
        [_splashShield.centerXAnchor constraintEqualToAnchor:iconBg.centerXAnchor],
        [_splashShield.centerYAnchor constraintEqualToAnchor:iconBg.centerYAnchor],
        [_splashShield.widthAnchor constraintEqualToConstant:40],
        [_splashShield.heightAnchor constraintEqualToConstant:45],
        
        [title.topAnchor constraintEqualToAnchor:iconBg.bottomAnchor constant:24],
        [title.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        
        [badge.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:12],
        [badge.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [badge.widthAnchor constraintEqualToConstant:180],
        [badge.heightAnchor constraintEqualToConstant:24]
    ]];
}

- (void)runDeterministicLaunchSequence {
    self.currentState = ZXAppStateSplash;
    self.splashContainer.alpha = 1.0;
    
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.toValue = @1.05;
    pulse.duration = 1.0;
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    [self.splashShield.layer addAnimation:pulse forKey:@"pulse"];
    
    NSTimeInterval sequenceStartTime = CACurrentMediaTime();
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) {
        [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL isValid) {
            NSTimeInterval elapsed = CACurrentMediaTime() - sequenceStartTime;
            NSTimeInterval remainingDelay = MAX(0.0, 2.0 - elapsed);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, remainingDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self.splashShield.layer removeAllAnimations];
                if (isValid) {
                    [self transitionToState:ZXAppStateDashboard];
                    [self showVaultToast:@"Session Synced" isError:NO];
                } else {
                    [self transitionToState:ZXAppStateAuth];
                }
            });
        }];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self.splashShield.layer removeAllAnimations];
            [self transitionToState:ZXAppStateAuth];
        });
    }
}

#pragma mark - Vault Auth Flow
- (void)setupAuth {
    _authContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_authContainer];
    
    UIView *badge = [[UIView alloc] init];
    badge.backgroundColor = [[ZXTheme accentPurple] colorWithAlphaComponent:0.15];
    badge.layer.cornerRadius = 14;
    badge.layer.borderWidth = 1.0;
    badge.layer.borderColor = [ZXTheme accentPurple].CGColor;
    badge.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:badge];
    
    UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(12, 10, 8, 8)];
    dot.backgroundColor = [ZXTheme accentPurple];
    dot.layer.cornerRadius = 4;
    dot.layer.shadowColor = [ZXTheme accentPurple].CGColor;
    dot.layer.shadowRadius = 5;
    dot.layer.shadowOpacity = 1.0;
    [badge addSubview:dot];
    
    UILabel *headerSub = [[UILabel alloc] initWithFrame:CGRectMake(28, 0, 160, 28)];
    headerSub.text = @"Zentrax License Center";
    headerSub.textColor = [ZXTheme accentPurple];
    headerSub.font = [ZXTheme fontHeading:12];
    [badge addSubview:headerSub];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"Secure Node\nActivation";
    title.textColor = [UIColor whiteColor];
    title.font = [ZXTheme fontDisplay:34];
    title.textAlignment = NSTextAlignmentCenter;
    title.numberOfLines = 2;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:title];
    
    UILabel *desc = [[UILabel alloc] init];
    desc.text = @"Securely activate your license and manage your devices with Zentrax protection.";
    desc.textColor = [ZXTheme textSecondary];
    desc.font = [ZXTheme fontBody:14 weight:UIFontWeightRegular];
    desc.textAlignment = NSTextAlignmentCenter;
    desc.numberOfLines = 0;
    desc.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:desc];
    
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [ZXTheme bgCardOuter];
    card.layer.cornerRadius = 20;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [ZXTheme borderSubtle].CGColor;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:card];
    
    _keyInput = [[ZXVaultField alloc] init];
    _keyInput.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_keyInput];
    
    _loginBtn = [[ZXVaultButton alloc] init];
    [_loginBtn setTitle:@"Authenticate License" forState:UIControlStateNormal];
    [_loginBtn addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside];
    _loginBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_loginBtn];
    
    [NSLayoutConstraint activateConstraints:@[
        [badge.topAnchor constraintEqualToAnchor:_authContainer.safeAreaLayoutGuide.topAnchor constant:40],
        [badge.centerXAnchor constraintEqualToAnchor:_authContainer.centerXAnchor],
        [badge.widthAnchor constraintEqualToConstant:190],
        [badge.heightAnchor constraintEqualToConstant:28],
        
        [title.topAnchor constraintEqualToAnchor:badge.bottomAnchor constant:24],
        [title.centerXAnchor constraintEqualToAnchor:_authContainer.centerXAnchor],
        
        [desc.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:16],
        [desc.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:40],
        [desc.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-40],
        
        [card.topAnchor constraintEqualToAnchor:desc.bottomAnchor constant:40],
        [card.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:24],
        [card.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-24],
        [card.heightAnchor constraintEqualToConstant:200],
        
        [_keyInput.topAnchor constraintEqualToAnchor:card.topAnchor constant:24],
        [_keyInput.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [_keyInput.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [_keyInput.heightAnchor constraintEqualToConstant:80],
        
        [_loginBtn.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-24],
        [_loginBtn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [_loginBtn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [_loginBtn.heightAnchor constraintEqualToConstant:54],
    ]];
}

- (void)handleLogin {
    [self dismissKeyboard];
    NSString *key = [self.keyInput.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (key.length == 0) {
        [self showVaultToast:@"License key cannot be empty" isError:YES];
        return;
    }
    if (!self.loginBtn.userInteractionEnabled) return;
    
    [self.loginBtn setLoading:YES];
    __weak typeof(self) weakSelf = self;
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestAuthenticationWithKey:completion:)]) {
        [self.delegate zentraxDidRequestAuthenticationWithKey:key completion:^(BOOL success, ZXAuthError errorType, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                
                [strongSelf.loginBtn setLoading:NO];
                if (success) {
                    [strongSelf transitionToState:ZXAppStateDashboard];
                    [strongSelf showVaultToast:@"Node Activated" isError:NO];
                    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred];
                } else {
                    [strongSelf showGlobalErrorWithTitle:@"ACTIVATION FAILED" message:errorMsg ?: @"Key rejected by server node."];
                }
            });
        }];
    }
}

- (void)setupVerification {}

#pragma mark - Premium Vault Dashboard
- (void)setupDashboard {
    _dashboardContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_dashboardContainer];
    
    UIView *navBar = [[UIView alloc] init];
    navBar.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:navBar];
    
    UIImageView *navIcon = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"shield.lefthalf.filled"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    navIcon.tintColor = [ZXTheme accentPurple];
    navIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [navBar addSubview:navIcon];
    
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.text = @"Zentrax";
    navTitle.textColor = [UIColor whiteColor];
    navTitle.font = [ZXTheme fontHeading:20];
    navTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [navBar addSubview:navTitle];
    
    UIButton *logoutBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [logoutBtn setImage:[[UIImage systemImageNamed:@"power"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    logoutBtn.tintColor = [ZXTheme textMuted];
    logoutBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [logoutBtn addTarget:self action:@selector(handleLogout) forControlEvents:UIControlEventTouchUpInside];
    [navBar addSubview:logoutBtn];
    
    // Segmented Vault Area (Visual matching the image)
    UIView *segmentedBg = [[UIView alloc] init];
    segmentedBg.backgroundColor = [ZXTheme bgCardOuter];
    segmentedBg.layer.cornerRadius = 14;
    segmentedBg.layer.borderWidth = 1.0;
    segmentedBg.layer.borderColor = [ZXTheme borderSubtle].CGColor;
    segmentedBg.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:segmentedBg];
    
    UIView *activeSeg = [[UIView alloc] init];
    activeSeg.backgroundColor = [ZXTheme bgCardInner];
    activeSeg.layer.cornerRadius = 10;
    activeSeg.translatesAutoresizingMaskIntoConstraints = NO;
    [segmentedBg addSubview:activeSeg];
    
    UILabel *segLbl = [[UILabel alloc] init];
    segLbl.text = @"My Vault";
    segLbl.textColor = [UIColor whiteColor];
    segLbl.font = [ZXTheme fontHeading:14];
    segLbl.translatesAutoresizingMaskIntoConstraints = NO;
    [activeSeg addSubview:segLbl];
    
    // Status Card
    UIView *statusCard = [[UIView alloc] init];
    statusCard.backgroundColor = [ZXTheme bgCardOuter];
    statusCard.layer.cornerRadius = 16;
    statusCard.layer.borderWidth = 1.0;
    statusCard.layer.borderColor = [ZXTheme borderSubtle].CGColor;
    statusCard.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:statusCard];
    
    UILabel *subTitle = [[UILabel alloc] init];
    subTitle.text = @"LICENSE STATUS";
    subTitle.textColor = [ZXTheme textMuted];
    subTitle.font = [ZXTheme fontHeading:12];
    [ZXTheme applyTextTracking:subTitle spacing:1.0];
    subTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:subTitle];
    
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.text = @"Active Node";
    _statusLabel.textColor = [UIColor whiteColor];
    _statusLabel.font = [ZXTheme fontDisplay:22];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_statusLabel];
    
    _expiryLabel = [[UILabel alloc] init];
    _expiryLabel.text = @"Syncing...";
    _expiryLabel.textColor = [ZXTheme textSecondary];
    _expiryLabel.font = [ZXTheme fontBody:13 weight:UIFontWeightMedium];
    _expiryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_expiryLabel];
    
    _modulesScrollView = [[UIScrollView alloc] init];
    _modulesScrollView.showsVerticalScrollIndicator = NO;
    _modulesScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _modulesScrollView.alwaysBounceVertical = YES;
    [_dashboardContainer addSubview:_modulesScrollView];
    
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
        [navIcon.widthAnchor constraintEqualToConstant:24],
        [navIcon.heightAnchor constraintEqualToConstant:28],
        
        [navTitle.leadingAnchor constraintEqualToAnchor:navIcon.trailingAnchor constant:12],
        [navTitle.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],
        
        [logoutBtn.trailingAnchor constraintEqualToAnchor:navBar.trailingAnchor],
        [logoutBtn.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],
        [logoutBtn.widthAnchor constraintEqualToConstant:32],
        [logoutBtn.heightAnchor constraintEqualToConstant:32],
        
        [segmentedBg.topAnchor constraintEqualToAnchor:navBar.bottomAnchor constant:24],
        [segmentedBg.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [segmentedBg.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [segmentedBg.heightAnchor constraintEqualToConstant:48],
        
        [activeSeg.topAnchor constraintEqualToAnchor:segmentedBg.topAnchor constant:4],
        [activeSeg.leadingAnchor constraintEqualToAnchor:segmentedBg.leadingAnchor constant:4],
        [activeSeg.bottomAnchor constraintEqualToAnchor:segmentedBg.bottomAnchor constant:-4],
        [activeSeg.widthAnchor constraintEqualToAnchor:segmentedBg.widthAnchor multiplier:0.5 constant:-6],
        
        [segLbl.centerXAnchor constraintEqualToAnchor:activeSeg.centerXAnchor],
        [segLbl.centerYAnchor constraintEqualToAnchor:activeSeg.centerYAnchor],
        
        [statusCard.topAnchor constraintEqualToAnchor:segmentedBg.bottomAnchor constant:24],
        [statusCard.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [statusCard.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [statusCard.heightAnchor constraintEqualToConstant:100],
        
        [subTitle.topAnchor constraintEqualToAnchor:statusCard.topAnchor constant:20],
        [subTitle.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:20],
        
        [_statusLabel.topAnchor constraintEqualToAnchor:subTitle.bottomAnchor constant:8],
        [_statusLabel.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:20],
        
        [_expiryLabel.centerYAnchor constraintEqualToAnchor:_statusLabel.centerYAnchor],
        [_expiryLabel.trailingAnchor constraintEqualToAnchor:statusCard.trailingAnchor constant:-20],
        
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
    
    UIImageView *icon = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"shippingbox"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    icon.tintColor = [ZXTheme textMuted];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyStateView addSubview:icon];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"Vault is Empty";
    title.textColor = [UIColor whiteColor];
    title.font = [ZXTheme fontHeading:18];
    title.textAlignment = NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyStateView addSubview:title];
    
    UILabel *sub = [[UILabel alloc] init];
    sub.text = @"No active modules found for this license.";
    sub.textColor = [ZXTheme textSecondary];
    sub.font = [ZXTheme fontBody:14 weight:UIFontWeightRegular];
    sub.textAlignment = NSTextAlignmentCenter;
    sub.numberOfLines = 0;
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyStateView addSubview:sub];
    
    [NSLayoutConstraint activateConstraints:@[
        [_emptyStateView.heightAnchor constraintEqualToConstant:250],
        
        [icon.centerXAnchor constraintEqualToAnchor:_emptyStateView.centerXAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:_emptyStateView.centerYAnchor constant:-40],
        [icon.widthAnchor constraintEqualToConstant:40],
        [icon.heightAnchor constraintEqualToConstant:40],
        
        [title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:20],
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
            [UIView animateWithDuration:0.5 animations:^{ self.emptyStateView.alpha = 1; }];
            return;
        }
        
        UILabel *sectionHeader = [[UILabel alloc] init];
        sectionHeader.text = @"ACTIVE FEATURES";
        sectionHeader.textColor = [ZXTheme textPrimary];
        sectionHeader.font = [ZXTheme fontHeading:14];
        [self.modulesStackView addArrangedSubview:sectionHeader];
        [self.modulesStackView setCustomSpacing:12 afterView:sectionHeader];
        
        for (NSDictionary *mod in modules) {
            NSString *moduleName = mod[@"name"] ?: @"UNKNOWN";
            NSString *moduleDesc = mod[@"desc"] ?: mod[@"description"] ?: @"";
            NSString *currentState = mod[@"current_state"] ?: @"OFF"; 
            BOOL isModOn = [currentState isEqualToString:@"ON"];
            
            UIView *card = [[UIView alloc] init];
            card.backgroundColor = [ZXTheme bgCardOuter];
            card.layer.cornerRadius = 16;
            card.layer.borderWidth = 1.0;
            card.layer.borderColor = [ZXTheme borderSubtle].CGColor;
            card.translatesAutoresizingMaskIntoConstraints = NO;
            
            UILabel *t = [[UILabel alloc] init];
            t.text = moduleName; // Normal casing, not forced uppercase for SaaS look
            t.textColor = [UIColor whiteColor];
            t.font = [ZXTheme fontHeading:16];
            t.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:t];
            
            UILabel *s = [[UILabel alloc] init];
            s.text = moduleDesc;
            s.textColor = [ZXTheme textSecondary];
            s.font = [ZXTheme fontBody:13 weight:UIFontWeightRegular];
            s.numberOfLines = 0;
            s.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:s];
            
            ZXVaultToggle *toggle = [[ZXVaultToggle alloc] init];
            toggle.moduleId = moduleName; 
            [toggle setOn:isModOn animated:NO]; 
            [toggle addTarget:self action:@selector(moduleToggled:) forControlEvents:UIControlEventValueChanged];
            [card addSubview:toggle];
            
            [NSLayoutConstraint activateConstraints:@[
                [toggle.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
                [toggle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
                
                [t.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
                [t.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
                [t.trailingAnchor constraintLessThanOrEqualToAnchor:toggle.leadingAnchor constant:-16],
                
                [s.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:6],
                [s.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
                [s.trailingAnchor constraintLessThanOrEqualToAnchor:toggle.leadingAnchor constant:-16],
                [s.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20]
            ]];
            
            [self.modulesStackView addArrangedSubview:card];
            
            card.alpha = 0;
            card.transform = CGAffineTransformMakeTranslation(0, 20);
            [UIView animateWithDuration:0.4 delay:([modules indexOfObject:mod] * 0.05) usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
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
            self.expiryLabel.text = @"LIFETIME";
        } else if (expiryStr) {
            self.expiryLabel.text = expiryStr;
        } else {
            self.expiryLabel.text = @"--";
        }
        NSString *s = subData[@"status"] ?: @"Active";
        self.statusLabel.text = [s capitalizedString];
        
        if ([s.lowercaseString isEqualToString:@"active"]) {
            self.statusLabel.textColor = [ZXTheme statusSuccess];
        } else {
            self.statusLabel.textColor = [ZXTheme statusWarning];
        }
    });
}

- (ZXVaultToggle *)findToggleInCard:(UIView *)card {
    for (UIView *sub in card.subviews) {
        if ([sub isKindOfClass:[ZXVaultToggle class]]) return (ZXVaultToggle *)sub;
    }
    return nil;
}

- (void)moduleToggled:(ZXVaultToggle *)sender {
    NSString *networkModuleId = sender.moduleId;
    if (!networkModuleId) return;
    
    BOOL requestedState = sender.isOn;
    
    [sender setLoading:YES];
    __weak typeof(self) weakSelf = self;
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestModuleToggle:state:completion:)]) {
        [self.delegate zentraxDidRequestModuleToggle:networkModuleId state:requestedState completion:^(BOOL success, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                
                [sender setLoading:NO];
                
                if (success) {
                    NSString *toastMsg = requestedState ? @"Module Activated" : @"Module Deactivated";
                    [strongSelf showVaultToast:toastMsg isError:NO];
                } else {
                    [sender setOn:!requestedState animated:YES];
                    [strongSelf showGlobalErrorWithTitle:@"Injection Failed" message:errorMsg ?: @"Failed to inject execution payload safely."];
                }
            });
        }];
    }
}

#pragma mark - Premium Vault Toast
- (void)showVaultToast:(NSString *)msg isError:(BOOL)isError {
    for (UIView *v in self.view.subviews) {
        if (v.tag == 887766) [v removeFromSuperview];
    }
    
    UIColor *tint = isError ? [ZXTheme statusError] : [ZXTheme statusSuccess];
    CGFloat toastWidth = 260;
    CGFloat toastHeight = 44;
    
    CGFloat topInset = 45; // Safe default
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                if (windowScene.activationState == UISceneActivationStateForegroundActive && windowScene.windows.count > 0) {
                    topInset = windowScene.windows.firstObject.safeAreaInsets.top;
                    break;
                }
            }
        }
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        topInset = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets.top;
#pragma clang diagnostic pop
    }
    if (topInset == 0) topInset = 45;
    
    UIView *toast = [[UIView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - toastWidth)/2, -60, toastWidth, toastHeight)];
    toast.tag = 887766;
    toast.backgroundColor = [ZXTheme bgCardOuter];
    toast.layer.cornerRadius = 22;
    toast.layer.borderWidth = 1.0;
    toast.layer.borderColor = [ZXTheme borderSubtle].CGColor;
    toast.layer.shadowColor = [UIColor blackColor].CGColor;
    toast.layer.shadowOpacity = 0.5;
    toast.layer.shadowRadius = 15;
    toast.layer.shadowOffset = CGSizeMake(0, 5);
    
    UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(16, 18, 8, 8)];
    dot.backgroundColor = tint;
    dot.layer.cornerRadius = 4;
    dot.layer.shadowColor = tint.CGColor;
    dot.layer.shadowRadius = 4;
    dot.layer.shadowOpacity = 1.0;
    [toast addSubview:dot];
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(36, 0, toastWidth - 50, toastHeight)];
    lbl.text = msg;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [ZXTheme fontHeading:13];
    [toast addSubview:lbl];
    
    [self.view addSubview:toast];
    
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:isError ? UIImpactFeedbackStyleHeavy : UIImpactFeedbackStyleLight] impactOccurred];
    
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        toast.frame = CGRectMake((self.view.bounds.size.width - toastWidth)/2, topInset + 10, toastWidth, toastHeight);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:1.8 options:UIViewAnimationOptionCurveEaseIn animations:^{
            toast.frame = CGRectMake((self.view.bounds.size.width - toastWidth)/2, -60, toastWidth, toastHeight);
            toast.alpha = 0;
        } completion:^(BOOL finished) {
            [toast removeFromSuperview];
        }];
    }];
}

#pragma mark - Logout and Errors
- (void)handleLogout {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Disconnect Node?" message:@"Your connection will be closed." preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Disconnect" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if ([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) {
            __weak typeof(self) weakSelf = self;
            [self.delegate zentraxDidRequestLogoutWithCompletion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (strongSelf) {
                        strongSelf.keyInput.textField.text = @"";
                        [strongSelf transitionToState:ZXAppStateAuth];
                    }
                });
            }];
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

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
- (void)showNetworkError { [self showVaultToast:@"Network Connection Lost" isError:YES]; }
- (void)showServerError { [self showVaultToast:@"Server Unavailable" isError:YES]; }
- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds {
    NSString *msg = [NSString stringWithFormat:@"Request limits reached. Cooldown active for %ld seconds.", (long)seconds];
    dispatch_async(dispatch_get_main_queue(), ^{
        [ZXModalManager showModalWithIcon:@"timer" iconTint:[ZXTheme statusWarning] title:@"Rate Limited" message:msg actionTitle:@"Understood" inView:self.view];
    });
}
- (void)showGlobalLoadingState:(NSString *)message {}
- (void)hideGlobalLoadingState {}

@end
