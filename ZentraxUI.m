//
//  ZentraxUI.m
//  Zentrax VIP - Premium Execution Node UI
//
//  Created by Zentrax Team.
//  Architecture: Ultra-Premium Vault Layer (Final Production)
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

+ (UIColor *)bgDeepSpace { return [UIColor colorWithRed:0.04 green:0.03 blue:0.06 alpha:1.0]; }
+ (UIColor *)bgCardOuter { return [UIColor colorWithRed:0.09 green:0.08 blue:0.12 alpha:0.85]; }
+ (UIColor *)bgCardInner { return [UIColor colorWithRed:0.12 green:0.11 blue:0.16 alpha:1.0]; }

+ (UIColor *)borderSubtle { return [UIColor colorWithRed:0.25 green:0.20 blue:0.35 alpha:0.5]; }
+ (UIColor *)borderActive { return [self accentPurple]; }

+ (UIColor *)accentPurple { return [UIColor colorWithRed:0.60 green:0.20 blue:1.0 alpha:1.0]; }
+ (UIColor *)accentBlue { return [UIColor colorWithRed:0.23 green:0.51 blue:0.96 alpha:1.0]; }
+ (UIColor *)accentCyan { return [UIColor colorWithRed:0.0 green:0.90 blue:1.0 alpha:1.0]; }

+ (UIColor *)textPrimary { return [UIColor colorWithWhite:1.0 alpha:1.0]; }
+ (UIColor *)textSecondary { return [UIColor colorWithWhite:0.80 alpha:1.0]; }
+ (UIColor *)textMuted { return [UIColor colorWithWhite:0.55 alpha:1.0]; }

+ (UIColor *)statusSuccess { return [UIColor colorWithRed:0.15 green:0.85 blue:0.60 alpha:1.0]; }
+ (UIColor *)statusWarning { return [UIColor colorWithRed:0.96 green:0.65 blue:0.14 alpha:1.0]; }
+ (UIColor *)statusError { return [UIColor colorWithRed:1.0 green:0.30 blue:0.40 alpha:1.0]; }

+ (UIFont *)fontDisplay:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBlack]; }
+ (UIFont *)fontHeading:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBold]; }
+ (UIFont *)fontBody:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont systemFontOfSize:size weight:weight]; }
+ (UIFont *)fontMono:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont monospacedSystemFontOfSize:size weight:weight]; }

+ (CAGradientLayer *)vaultGradient {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[(id)[self accentPurple].CGColor, (id)[self accentCyan].CGColor];
    gradient.startPoint = CGPointMake(0.0, 0.0);
    gradient.endPoint = CGPointMake(1.0, 1.0);
    return gradient;
}

+ (void)applyTextTracking:(UILabel *)label spacing:(CGFloat)spacing {
    if (!label.text) return;
    NSDictionary *attrs = @{NSKernAttributeName: @(spacing)};
    label.attributedText = [[NSAttributedString alloc] initWithString:label.text attributes:attrs];
}

@end

#pragma mark - ================= PREMIUM COMPONENTS =================

@interface ZXButton : UIButton
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSString *originalTitle;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIImageView *arrowIcon;
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
        
        _gradientLayer = [ZXTheme vaultGradient];
        [_bgView.layer insertSublayer:_gradientLayer atIndex:0];
        
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
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid] impactOccurred];
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

@interface ZXTextField : UIView <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UILabel *topLabel;
@property (nonatomic, strong) UIButton *pasteButton;
@property (nonatomic, strong) UIView *inputContainer;
@property (nonatomic, strong) UIImageView *iconView;
@end

@implementation ZXTextField
- (instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
        
        _topLabel = [[UILabel alloc] init];
        _topLabel.text = @"MASTER LICENSE KEY";
        _topLabel.textColor = [ZXTheme textMuted];
        _topLabel.font = [ZXTheme fontMono:11 weight:UIFontWeightBold];
        [ZXTheme applyTextTracking:_topLabel spacing:1.5];
        _topLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_topLabel];
        
        _inputContainer = [[UIView alloc] init];
        _inputContainer.backgroundColor = [ZXTheme bgCardOuter];
        _inputContainer.layer.cornerRadius = 14;
        _inputContainer.layer.borderWidth = 1.0;
        _inputContainer.layer.borderColor = [ZXTheme borderSubtle].CGColor;
        _inputContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_inputContainer];
        
        _iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"key.fill"]];
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
        [_pasteButton setTitle:@"PASTE" forState:UIControlStateNormal];
        _pasteButton.titleLabel.font = [ZXTheme fontHeading:12];
        _pasteButton.backgroundColor = [ZXTheme bgCardInner];
        _pasteButton.layer.cornerRadius = 8;
        _pasteButton.layer.borderWidth = 1.0;
        _pasteButton.layer.borderColor = [ZXTheme borderSubtle].CGColor;
        [_pasteButton setTitleColor:[ZXTheme accentCyan] forState:UIControlStateNormal];
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
            [_inputContainer.heightAnchor constraintEqualToConstant:60],
            
            [_iconView.leadingAnchor constraintEqualToAnchor:_inputContainer.leadingAnchor constant:16],
            [_iconView.centerYAnchor constraintEqualToAnchor:_inputContainer.centerYAnchor],
            [_iconView.widthAnchor constraintEqualToConstant:18],
            [_iconView.heightAnchor constraintEqualToConstant:18],
            
            [_pasteButton.trailingAnchor constraintEqualToAnchor:_inputContainer.trailingAnchor constant:-12],
            [_pasteButton.centerYAnchor constraintEqualToAnchor:_inputContainer.centerYAnchor],
            [_pasteButton.heightAnchor constraintEqualToConstant:32],
            [_pasteButton.widthAnchor constraintEqualToConstant:65],
            
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
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    }
}
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.3 animations:^{
        self.inputContainer.layer.borderColor = [ZXTheme accentCyan].CGColor;
        self.iconView.tintColor = [ZXTheme accentCyan];
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
            [self.widthAnchor constraintEqualToConstant:54],
            [self.heightAnchor constraintEqualToConstant:30]
        ]];
        
        _trackView = [[UIView alloc] init];
        _trackView.backgroundColor = [ZXTheme bgCardInner];
        _trackView.layer.cornerRadius = 15;
        _trackView.layer.borderWidth = 1.5;
        _trackView.layer.borderColor = [ZXTheme borderSubtle].CGColor;
        _trackView.userInteractionEnabled = NO;
        _trackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_trackView];
        
        _thumbView = [[UIView alloc] init];
        _thumbView.backgroundColor = [ZXTheme textMuted];
        _thumbView.layer.cornerRadius = 11;
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
            [_thumbView.widthAnchor constraintEqualToConstant:22],
            [_thumbView.heightAnchor constraintEqualToConstant:22],
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
    self.thumbLeadingConstraint.constant = self.isOn ? 28 : 4;
    void (^stateUpdates)(void) = ^{
        [self layoutIfNeeded];
        if (self.isOn) {
            self.trackView.layer.borderColor = [ZXTheme accentCyan].CGColor;
            self.trackView.backgroundColor = [[ZXTheme accentCyan] colorWithAlphaComponent:0.2];
            self.thumbView.backgroundColor = [ZXTheme accentCyan];
            self.thumbView.layer.shadowColor = [ZXTheme accentCyan].CGColor;
            self.thumbView.layer.shadowOpacity = 1.0;
            self.thumbView.layer.shadowRadius = 8;
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
    
    ZXButton *btn = [[ZXButton alloc] init];
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
    
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred];
    
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        overlay.alpha = 1.0;
        card.transform = CGAffineTransformIdentity;
    } completion:nil];
}
+ (void)dismissOverlay:(UITapGestureRecognizer *)sender {
    if (sender.view.tag == 100100) [self animateDismiss:sender.view];
}
+ (void)dismissBtnTapped:(UIButton *)btn {
    UIView *card = btn.superview;
    UIView *overlay = card.superview;
    if (overlay.tag == 100100) [self animateDismiss:overlay];
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

// Background
@property (nonatomic, strong) UIView *liveBackgroundView;
@property (nonatomic, strong) CAGradientLayer *movingGlow1;
@property (nonatomic, strong) CAGradientLayer *movingGlow2;

// Splash elements
@property (nonatomic, strong) UIImageView *splashLogo;
@property (nonatomic, strong) UILabel *splashTitle;

// Auth elements
@property (nonatomic, strong) ZXTextField *keyInput;
@property (nonatomic, strong) ZXButton *loginBtn;
@property (nonatomic, strong) UITapGestureRecognizer *dismissTap;

// Dashboard elements
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *expiryLabel;
@property (nonatomic, strong) UIScrollView *modulesScrollView;
@property (nonatomic, strong) UIStackView *modulesStackView; 
@property (nonatomic, strong) UIView *emptyStateView;

// Heartbeat & Cache
@property (nonatomic, strong) NSTimer *heartbeatTimer;
@property (nonatomic, strong) NSArray *cachedModulesState;

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
    
    [self setupLiveBackground];
    
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
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.authContainer.transform = CGAffineTransformMakeTranslation(0, -(overlap + 30));
        } completion:nil];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.authContainer.transform = CGAffineTransformIdentity;
    } completion:nil];
}

#pragma mark - Live Animated Background
- (void)setupLiveBackground {
    _liveBackgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    _liveBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:_liveBackgroundView atIndex:0];
    
    _movingGlow1 = [CAGradientLayer layer];
    _movingGlow1.colors = @[(id)[[ZXTheme accentPurple] colorWithAlphaComponent:0.25].CGColor, (id)[UIColor clearColor].CGColor];
    _movingGlow1.type = kCAGradientLayerRadial;
    _movingGlow1.startPoint = CGPointMake(0.5, 0.5);
    _movingGlow1.endPoint = CGPointMake(1.0, 1.0);
    _movingGlow1.frame = CGRectMake(-100, -100, 450, 450);
    [_liveBackgroundView.layer addSublayer:_movingGlow1];
    
    _movingGlow2 = [CAGradientLayer layer];
    _movingGlow2.colors = @[(id)[[ZXTheme accentCyan] colorWithAlphaComponent:0.15].CGColor, (id)[UIColor clearColor].CGColor];
    _movingGlow2.type = kCAGradientLayerRadial;
    _movingGlow2.startPoint = CGPointMake(0.5, 0.5);
    _movingGlow2.endPoint = CGPointMake(1.0, 1.0);
    _movingGlow2.frame = CGRectMake(self.view.bounds.size.width - 200, self.view.bounds.size.height - 300, 450, 450);
    [_liveBackgroundView.layer addSublayer:_movingGlow2];
    
    [UIView animateWithDuration:10.0 delay:0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut animations:^{
        self.movingGlow1.transform = CATransform3DMakeTranslation(150, 250, 0);
        self.movingGlow2.transform = CATransform3DMakeTranslation(-150, -250, 0);
    } completion:nil];
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
        self.cachedModulesState = nil; 
    }
    
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.splashContainer.alpha = (newState == ZXAppStateSplash) ? 1.0 : 0.0;
        self.authContainer.alpha = (newState == ZXAppStateAuth) ? 1.0 : 0.0;
        self.verificationContainer.alpha = (newState == ZXAppStateVerifying) ? 1.0 : 0.0;
        self.dashboardContainer.alpha = (newState == ZXAppStateDashboard) ? 1.0 : 0.0;
    } completion:nil];
}

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
                if (!isValid) {
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
                        [self handleRevokedSessionEnvironment];
                    }
                }
            });
        }];
    }
}

- (void)handleRevokedSessionEnvironment {
    [self stopHeartbeatMonitor];
    
    for (UIView *card in self.modulesStackView.arrangedSubviews) {
        for (UIView *sub in card.subviews) {
            if ([sub isKindOfClass:[ZXToggle class]]) {
                ZXToggle *toggle = (ZXToggle *)sub;
                toggle.userInteractionEnabled = NO;
                [toggle setOn:NO animated:YES];
            }
        }
    }
    
    [self showGlobalErrorWithTitle:@"ACCESS REVOKED" message:@"Your license has been disabled or expired by the administrator."];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) {
            [self.delegate zentraxDidRequestLogoutWithCompletion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.keyInput.textField.text = @"";
                    [self transitionToState:ZXAppStateAuth];
                });
            }];
        } else {
            [self transitionToState:ZXAppStateAuth];
        }
    });
}

#pragma mark - Premium Splash Sequence
- (void)setupSplash {
    _splashContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_splashContainer];
    
    _splashLogo = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"bolt.shield.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    _splashLogo.tintColor = [ZXTheme accentCyan];
    _splashLogo.contentMode = UIViewContentModeScaleAspectFit;
    _splashLogo.translatesAutoresizingMaskIntoConstraints = NO;
    _splashLogo.layer.shadowColor = [ZXTheme accentCyan].CGColor;
    _splashLogo.layer.shadowRadius = 25;
    _splashLogo.layer.shadowOpacity = 1.0;
    [_splashContainer addSubview:_splashLogo];
    
    _splashTitle = [[UILabel alloc] init];
    _splashTitle.text = @"ZENTRAX";
    _splashTitle.textColor = [UIColor whiteColor];
    _splashTitle.font = [ZXTheme fontDisplay:32];
    [ZXTheme applyTextTracking:_splashTitle spacing:6.0];
    _splashTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_splashTitle];
    
    UILabel *sub = [[UILabel alloc] init];
    sub.text = @"PREMIUM PANEL";
    sub.textColor = [ZXTheme accentPurple];
    sub.font = [ZXTheme fontHeading:13];
    [ZXTheme applyTextTracking:sub spacing:2.0];
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:sub];
    
    [NSLayoutConstraint activateConstraints:@[
        [_splashLogo.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [_splashLogo.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor constant:-40],
        [_splashLogo.widthAnchor constraintEqualToConstant:70],
        [_splashLogo.heightAnchor constraintEqualToConstant:80],
        
        [_splashTitle.topAnchor constraintEqualToAnchor:_splashLogo.bottomAnchor constant:24],
        [_splashTitle.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        
        [sub.topAnchor constraintEqualToAnchor:_splashTitle.bottomAnchor constant:8],
        [sub.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor]
    ]];
}

- (void)runDeterministicLaunchSequence {
    self.currentState = ZXAppStateSplash;
    self.splashContainer.alpha = 1.0;
    
    // Smooth intro animation instead of generic pulse
    self.splashLogo.transform = CGAffineTransformMakeScale(0.5, 0.5);
    self.splashLogo.alpha = 0;
    self.splashTitle.transform = CGAffineTransformMakeTranslation(0, 20);
    self.splashTitle.alpha = 0;
    
    [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.splashLogo.transform = CGAffineTransformIdentity;
        self.splashLogo.alpha = 1.0;
        self.splashTitle.transform = CGAffineTransformIdentity;
        self.splashTitle.alpha = 1.0;
    } completion:nil];
    
    NSTimeInterval sequenceStartTime = CACurrentMediaTime();
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) {
        [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL isValid) {
            NSTimeInterval elapsed = CACurrentMediaTime() - sequenceStartTime;
            NSTimeInterval remainingDelay = MAX(0.0, 2.5 - elapsed);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, remainingDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self.splashLogo.layer removeAllAnimations];
                if (isValid) {
                    [self transitionToState:ZXAppStateDashboard];
                    [self showPremiumToast:@"Session Restored" success:YES];
                } else {
                    [self transitionToState:ZXAppStateAuth];
                }
            });
        }];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self.splashLogo.layer removeAllAnimations];
            [self transitionToState:ZXAppStateAuth];
        });
    }
}

#pragma mark - Vault Auth Flow
- (void)setupAuth {
    _authContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_authContainer];
    
    UIView *centerWrapper = [[UIView alloc] init];
    centerWrapper.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:centerWrapper];
    
    UIImageView *icon = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"lock.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    icon.tintColor = [ZXTheme accentCyan];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.layer.shadowColor = [ZXTheme accentCyan].CGColor;
    icon.layer.shadowOpacity = 0.5;
    icon.layer.shadowRadius = 10;
    [centerWrapper addSubview:icon];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"Zentrax Authentication";
    title.textColor = [UIColor whiteColor];
    title.font = [ZXTheme fontDisplay:26];
    title.textAlignment = NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [centerWrapper addSubview:title];
    
    UILabel *desc = [[UILabel alloc] init];
    desc.text = @"Securely activate your panel access.";
    desc.textColor = [ZXTheme textSecondary];
    desc.font = [ZXTheme fontBody:14 weight:UIFontWeightRegular];
    desc.textAlignment = NSTextAlignmentCenter;
    desc.translatesAutoresizingMaskIntoConstraints = NO;
    [centerWrapper addSubview:desc];
    
    // The original ZXTextField component, completely retained but layout centered
    _keyInput = [[ZXTextField alloc] init];
    _keyInput.translatesAutoresizingMaskIntoConstraints = NO;
    [centerWrapper addSubview:_keyInput];
    
    _loginBtn = [[ZXButton alloc] init];
    [_loginBtn setTitle:@"Login" forState:UIControlStateNormal];
    [_loginBtn addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside];
    _loginBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [centerWrapper addSubview:_loginBtn];
    
    [NSLayoutConstraint activateConstraints:@[
        [centerWrapper.centerYAnchor constraintEqualToAnchor:_authContainer.centerYAnchor constant:-30],
        [centerWrapper.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:24],
        [centerWrapper.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-24],
        
        [icon.topAnchor constraintEqualToAnchor:centerWrapper.topAnchor],
        [icon.centerXAnchor constraintEqualToAnchor:centerWrapper.centerXAnchor],
        [icon.widthAnchor constraintEqualToConstant:35],
        [icon.heightAnchor constraintEqualToConstant:40],
        
        [title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:16],
        [title.leadingAnchor constraintEqualToAnchor:centerWrapper.leadingAnchor],
        [title.trailingAnchor constraintEqualToAnchor:centerWrapper.trailingAnchor],
        
        [desc.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
        [desc.leadingAnchor constraintEqualToAnchor:centerWrapper.leadingAnchor],
        [desc.trailingAnchor constraintEqualToAnchor:centerWrapper.trailingAnchor],
        
        [_keyInput.topAnchor constraintEqualToAnchor:desc.bottomAnchor constant:32],
        [_keyInput.leadingAnchor constraintEqualToAnchor:centerWrapper.leadingAnchor],
        [_keyInput.trailingAnchor constraintEqualToAnchor:centerWrapper.trailingAnchor],
        [_keyInput.heightAnchor constraintEqualToConstant:80],
        
        [_loginBtn.topAnchor constraintEqualToAnchor:_keyInput.bottomAnchor constant:24],
        [_loginBtn.leadingAnchor constraintEqualToAnchor:centerWrapper.leadingAnchor],
        [_loginBtn.trailingAnchor constraintEqualToAnchor:centerWrapper.trailingAnchor],
        [_loginBtn.heightAnchor constraintEqualToConstant:54],
        [_loginBtn.bottomAnchor constraintEqualToAnchor:centerWrapper.bottomAnchor]
    ]];
}

- (void)handleLogin {
    [self dismissKeyboard];
    NSString *key = [self.keyInput.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (key.length == 0) {
        [self showPremiumToast:@"License key cannot be empty" success:NO];
        return;
    }
    if (!self.loginBtn.userInteractionEnabled) return;
    
    [self.loginBtn setLoading:YES];
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestAuthenticationWithKey:completion:)]) {
        [self.delegate zentraxDidRequestAuthenticationWithKey:key completion:^(BOOL success, ZXAuthError errorType, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.loginBtn setLoading:NO];
                if (success) {
                    [self transitionToState:ZXAppStateDashboard];
                    [self showPremiumToast:@"Login Successful" success:YES];
                } else {
                    [self showGlobalErrorWithTitle:@"ACTIVATION FAILED" message:errorMsg ?: @"Key rejected by server node."];
                }
            });
        }];
    }
}

// Keeping Original Stub
- (void)setupVerification {}

#pragma mark - Premium Vault Dashboard
- (void)setupDashboard {
    _dashboardContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_dashboardContainer];
    
    UIView *navBar = [[UIView alloc] init];
    navBar.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:navBar];
    
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.text = @"ZENTRAX DASHBOARD";
    navTitle.textColor = [UIColor whiteColor];
    navTitle.font = [ZXTheme fontDisplay:18];
    [ZXTheme applyTextTracking:navTitle spacing:2.0];
    navTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [navBar addSubview:navTitle];
    
    UIButton *logoutBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [logoutBtn setImage:[[UIImage systemImageNamed:@"rectangle.portrait.and.arrow.right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    logoutBtn.tintColor = [ZXTheme textMuted];
    logoutBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [logoutBtn addTarget:self action:@selector(handleLogout) forControlEvents:UIControlEventTouchUpInside];
    [navBar addSubview:logoutBtn];
    
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
    _statusLabel.text = @"Active";
    _statusLabel.textColor = [ZXTheme statusSuccess];
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
        
        [navTitle.centerXAnchor constraintEqualToAnchor:navBar.centerXAnchor],
        [navTitle.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],
        
        [logoutBtn.trailingAnchor constraintEqualToAnchor:navBar.trailingAnchor],
        [logoutBtn.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],
        [logoutBtn.widthAnchor constraintEqualToConstant:32],
        [logoutBtn.heightAnchor constraintEqualToConstant:32],
        
        [statusCard.topAnchor constraintEqualToAnchor:navBar.bottomAnchor constant:24],
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
        if (!modules || modules.count == 0) {
            if (![self.modulesStackView.arrangedSubviews containsObject:self.emptyStateView]) {
                for (UIView *v in self.modulesStackView.arrangedSubviews) [v removeFromSuperview];
                [self.modulesStackView addArrangedSubview:self.emptyStateView];
                self.emptyStateView.alpha = 0;
                [UIView animateWithDuration:0.5 animations:^{ self.emptyStateView.alpha = 1; }];
            }
            return;
        }
        
        // Silent Refresh Logic to avoid UI blinking
        BOOL needsRebuild = NO;
        if (!self.cachedModulesState || self.cachedModulesState.count != modules.count) {
            needsRebuild = YES;
        } else {
            // Check if names changed
            for (int i = 0; i < modules.count; i++) {
                if (![modules[i][@"name"] isEqualToString:self.cachedModulesState[i][@"name"]]) {
                    needsRebuild = YES;
                    break;
                }
            }
        }
        
        self.cachedModulesState = modules;
        
        if (needsRebuild) {
            for (UIView *view in self.modulesStackView.arrangedSubviews) {
                [self.modulesStackView removeArrangedSubview:view];
                [view removeFromSuperview];
            }
            
            for (NSDictionary *mod in modules) {
                NSString *moduleName = mod[@"name"] ?: @"UNKNOWN";
                NSString *moduleDesc = mod[@"desc"] ?: mod[@"description"] ?: @"";
                BOOL isModOn = [mod[@"current_state"] isEqualToString:@"ON"];
                
                UIView *card = [[UIView alloc] init];
                card.backgroundColor = [ZXTheme bgCardOuter];
                card.layer.cornerRadius = 16;
                card.layer.borderWidth = 1.0;
                card.layer.borderColor = [ZXTheme borderSubtle].CGColor;
                card.translatesAutoresizingMaskIntoConstraints = NO;
                
                UILabel *t = [[UILabel alloc] init];
                t.text = moduleName;
                t.textColor = [UIColor whiteColor];
                t.font = [ZXTheme fontHeading:16];
                t.translatesAutoresizingMaskIntoConstraints = NO;
                [card addSubview:t];
                
                // Premium Tag for Description
                UIView *descTag = [[UIView alloc] init];
                descTag.backgroundColor = [ZXTheme bgCardInner];
                descTag.layer.cornerRadius = 6;
                descTag.translatesAutoresizingMaskIntoConstraints = NO;
                [card addSubview:descTag];
                
                UILabel *desc = [[UILabel alloc] init];
                desc.text = [moduleDesc uppercaseString];
                desc.textColor = [ZXTheme textSecondary];
                desc.font = [ZXTheme fontMono:10 weight:UIFontWeightSemibold];
                desc.translatesAutoresizingMaskIntoConstraints = NO;
                [descTag addSubview:desc];
                
                ZXToggle *toggle = [[ZXToggle alloc] init];
                toggle.moduleId = moduleName; 
                [toggle setOn:isModOn animated:NO]; 
                [toggle addTarget:self action:@selector(moduleToggled:) forControlEvents:UIControlEventValueChanged];
                [card addSubview:toggle];
                
                [NSLayoutConstraint activateConstraints:@[
                    [toggle.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
                    [toggle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
                    
                    [t.topAnchor constraintEqualToAnchor:card.topAnchor constant:18],
                    [t.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
                    [t.trailingAnchor constraintLessThanOrEqualToAnchor:toggle.leadingAnchor constant:-16],
                    
                    [descTag.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:8],
                    [descTag.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
                    [descTag.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18],
                    
                    [desc.topAnchor constraintEqualToAnchor:descTag.topAnchor constant:4],
                    [desc.bottomAnchor constraintEqualToAnchor:descTag.bottomAnchor constant:-4],
                    [desc.leadingAnchor constraintEqualToAnchor:descTag.leadingAnchor constant:8],
                    [desc.trailingAnchor constraintEqualToAnchor:descTag.trailingAnchor constant:-8],
                ]];
                
                [self.modulesStackView addArrangedSubview:card];
                card.alpha = 0;
                card.transform = CGAffineTransformMakeTranslation(0, 20);
                [UIView animateWithDuration:0.4 delay:([modules indexOfObject:mod] * 0.05) usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    card.alpha = 1;
                    card.transform = CGAffineTransformIdentity;
                } completion:nil];
            }
        } else {
            // SILENT UPDATE: Update toggles without recreating views
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

// Keeping original subscription update implementation exactly intact
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
                    NSString *toastMsg = requestedState ? @"Feature Activated" : @"Feature Deactivated";
                    [self showPremiumToast:toastMsg success:YES];
                    self.cachedModulesState = nil; // Clear cache to allow heartbeat to pull fresh accurate state
                } else {
                    [sender setOn:!requestedState animated:YES];
                    [self showGlobalErrorWithTitle:@"Injection Failed" message:errorMsg ?: @"Failed to inject execution payload safely."];
                }
            });
        }];
    }
}

#pragma mark - Centered Premium Vault Toast
- (void)showPremiumToast:(NSString *)msg success:(BOOL)success {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *v in self.view.subviews) {
            if (v.tag == 887766) [v removeFromSuperview];
        }
        
        UIColor *tint = success ? [ZXTheme statusSuccess] : [ZXTheme statusError];
        CGFloat toastWidth = 260;
        CGFloat toastHeight = 44;
        
        // Fix for true centering calculation
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat topInset = 45; 
        
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
        }
        if (topInset == 0) topInset = 45;
        
        UIView *toast = [[UIView alloc] initWithFrame:CGRectMake((screenWidth - toastWidth)/2, -60, toastWidth, toastHeight)];
        toast.tag = 887766;
        toast.backgroundColor = [ZXTheme bgCardOuter];
        toast.layer.cornerRadius = 22;
        toast.layer.borderWidth = 1.0;
        toast.layer.borderColor = tint.CGColor;
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
        
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:success ? UIImpactFeedbackStyleLight : UIImpactFeedbackStyleHeavy] impactOccurred];
        
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            toast.frame = CGRectMake((screenWidth - toastWidth)/2, topInset + 10, toastWidth, toastHeight);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 delay:1.8 options:UIViewAnimationOptionCurveEaseIn animations:^{
                toast.frame = CGRectMake((screenWidth - toastWidth)/2, -60, toastWidth, toastHeight);
                toast.alpha = 0;
            } completion:^(BOOL finished) {
                [toast removeFromSuperview];
            }];
        }];
    });
}

#pragma mark - Logout and Original Error Stubs
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

// Completely retaining original error handlers
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
- (void)showNetworkError { [self showPremiumToast:@"Network Connection Lost" success:NO]; }
- (void)showServerError { [self showPremiumToast:@"Server Unavailable" success:NO]; }
- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds {
    NSString *msg = [NSString stringWithFormat:@"Request limits reached. Cooldown active for %ld seconds.", (long)seconds];
    dispatch_async(dispatch_get_main_queue(), ^{
        [ZXModalManager showModalWithIcon:@"timer" iconTint:[ZXTheme statusWarning] title:@"Rate Limited" message:msg actionTitle:@"Understood" inView:self.view];
    });
}
- (void)showGlobalLoadingState:(NSString *)message {}
- (void)hideGlobalLoadingState {}

@end
