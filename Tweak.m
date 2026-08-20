//
//  ZentraxUI.m
//  Zentrax VIP - Premium Execution Node UI
//
//  Created by Zentrax Team.
//  Architecture: Ultra-Premium SaaS Layer V4
//  Status: PRODUCTION READY
//

#import "ZentraxUI.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - ================= GLOBAL DESIGN SYSTEM =================

@interface ZXTheme : NSObject

+ (UIColor *)bgDeepSpace;
+ (UIColor *)bgCardOuter;
+ (UIColor *)bgCardInner;
+ (UIColor *)borderSubtle;
+ (UIColor *)borderActive;

+ (UIColor *)accentCyan;
+ (UIColor *)accentPurple;

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
+ (CAGradientLayer *)primaryGradient;

@end

@implementation ZXTheme

+ (UIColor *)bgDeepSpace { return [UIColor colorWithRed:0.02 green:0.02 blue:0.04 alpha:1.0]; }
+ (UIColor *)bgCardOuter { return [UIColor colorWithRed:0.06 green:0.07 blue:0.12 alpha:0.65]; }
+ (UIColor *)bgCardInner { return [UIColor colorWithRed:0.08 green:0.10 blue:0.16 alpha:0.80]; }
+ (UIColor *)borderSubtle { return [UIColor colorWithWhite:1.0 alpha:0.08]; }
+ (UIColor *)borderActive { return [UIColor colorWithWhite:1.0 alpha:0.20]; }

+ (UIColor *)accentCyan { return [UIColor colorWithRed:0.0 green:0.85 blue:1.0 alpha:1.0]; }
+ (UIColor *)accentPurple { return [UIColor colorWithRed:0.65 green:0.35 blue:1.0 alpha:1.0]; }

+ (UIColor *)textPrimary { return [UIColor colorWithWhite:0.98 alpha:1.0]; }
+ (UIColor *)textSecondary { return [UIColor colorWithWhite:0.75 alpha:1.0]; }
+ (UIColor *)textMuted { return [UIColor colorWithWhite:0.50 alpha:1.0]; }

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
    for (UIView *sub in view.subviews) {
        if (sub.tag == 998877) {
            [sub removeFromSuperview];
        }
    }
    
    view.backgroundColor = [self bgCardOuter];
    view.layer.cornerRadius = radius;
    view.layer.borderWidth = 1.0;
    view.layer.borderColor = [self borderSubtle].CGColor;
    
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:blur];
    effectView.tag = 998877;
    effectView.frame = view.bounds;
    effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    effectView.layer.cornerRadius = radius;
    effectView.clipsToBounds = YES;
    effectView.alpha = 0.98;
    [view insertSubview:effectView atIndex:0];
}

+ (CAGradientLayer *)primaryGradient {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[(id)[self accentPurple].CGColor, (id)[self accentCyan].CGColor];
    gradient.startPoint = CGPointMake(0.0, 0.0);
    gradient.endPoint = CGPointMake(1.0, 1.0);
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
        self.layer.cornerRadius = 16;
        self.titleLabel.font = [ZXTheme fontHeading:15];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        _bgView = [[UIView alloc] init];
        _bgView.layer.cornerRadius = 16;
        _bgView.clipsToBounds = YES;
        _bgView.userInteractionEnabled = NO;
        _bgView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_bgView];
        
        _gradientLayer = [ZXTheme primaryGradient];
        [_bgView.layer insertSublayer:_gradientLayer atIndex:0];
        
        self.layer.shadowColor = [ZXTheme accentCyan].CGColor;
        self.layer.shadowOpacity = 0.4;
        self.layer.shadowRadius = 15;
        self.layer.shadowOffset = CGSizeMake(0, 5);
        
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
    self.gradientLayer.frame = self.bgView.bounds;
}

- (void)touchDown {
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid];
    [haptic impactOccurred];
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformMakeScale(0.95, 0.95);
        self.layer.shadowOpacity = 0.8;
        self.layer.shadowRadius = 10;
        self.bgView.alpha = 0.9;
    } completion:nil];
}

- (void)touchUp {
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.transform = CGAffineTransformIdentity;
        self.layer.shadowOpacity = 0.4;
        self.layer.shadowRadius = 15;
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
        [ZXTheme applyPremiumGlassmorphismToView:self cornerRadius:16];
        
        _highlightBorder = [[UIView alloc] init];
        _highlightBorder.layer.cornerRadius = 16;
        _highlightBorder.layer.borderWidth = 1.5;
        _highlightBorder.layer.borderColor = [ZXTheme accentCyan].CGColor;
        _highlightBorder.alpha = 0;
        _highlightBorder.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_highlightBorder];
        
        _iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.fill"]];
        _iconView.tintColor = [ZXTheme textMuted];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_iconView];
        
        _floatingLabel = [[UILabel alloc] init];
        _floatingLabel.text = @"Enter Access Protocol Key";
        _floatingLabel.textColor = [ZXTheme textMuted];
        _floatingLabel.font = [ZXTheme fontBody:14 weight:UIFontWeightMedium];
        _floatingLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_floatingLabel];
        
        _textField = [[UITextField alloc] init];
        _textField.textColor = [ZXTheme textPrimary];
        _textField.font = [ZXTheme fontMono:15 weight:UIFontWeightBold];
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
        _pasteButton.titleLabel.font = [ZXTheme fontHeading:11];
        _pasteButton.backgroundColor = [ZXTheme bgCardInner];
        _pasteButton.layer.cornerRadius = 8;
        _pasteButton.layer.borderWidth = 1.0;
        _pasteButton.layer.borderColor = [ZXTheme borderActive].CGColor;
        [_pasteButton setTitleColor:[ZXTheme accentCyan] forState:UIControlStateNormal];
        _pasteButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_pasteButton addTarget:self action:@selector(pasteKeyTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_pasteButton];
        
        _labelCenterConstraint = [_floatingLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor];
        _labelTopConstraint = [_floatingLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:10];
        
        [NSLayoutConstraint activateConstraints:@[
            [_highlightBorder.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_highlightBorder.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_highlightBorder.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_highlightBorder.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            
            [_iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:18],
            [_iconView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_iconView.widthAnchor constraintEqualToConstant:18],
            [_iconView.heightAnchor constraintEqualToConstant:18],
            
            [_floatingLabel.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor constant:14],
            _labelCenterConstraint, 
            
            [_textField.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor constant:14],
            [_textField.trailingAnchor constraintEqualToAnchor:_pasteButton.leadingAnchor constant:-12],
            [_textField.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-10],
            [_textField.topAnchor constraintEqualToAnchor:self.topAnchor constant:22],
            
            [_pasteButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],
            [_pasteButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_pasteButton.heightAnchor constraintEqualToConstant:28],
            [_pasteButton.widthAnchor constraintEqualToConstant:65]
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
        self.floatingLabel.font = [ZXTheme fontBody:10 weight:UIFontWeightBold];
        self.floatingLabel.textColor = [ZXTheme accentCyan];
        self.iconView.tintColor = [ZXTheme accentCyan];
    } else {
        self.labelTopConstraint.active = NO;
        self.labelCenterConstraint.active = YES;
        self.floatingLabel.font = [ZXTheme fontBody:14 weight:UIFontWeightMedium];
        self.floatingLabel.textColor = [ZXTheme textMuted];
        self.iconView.tintColor = [ZXTheme textMuted];
    }
}

- (void)pasteKeyTapped {
    NSString *pb = [[UIPasteboard generalPasteboard].string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (pb.length > 0) {
        self.textField.text = pb;
        [self updateFloatingLabelStateAnimated:YES];
        [self.textField sendActionsForControlEvents:UIControlEventEditingChanged];
        
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
        self.layer.shadowOpacity = 0.25;
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

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect hitFrame = CGRectInset(self.bounds, -20, -20);
    return CGRectContainsPoint(hitFrame, point);
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
    self.thumbLeadingConstraint.constant = self.isOn ? 28 : 4;
    
    void (^stateUpdates)(void) = ^{
        [self layoutIfNeeded];
        
        if (self.isOn) {
            self.trackView.layer.borderColor = [ZXTheme accentCyan].CGColor;
            self.trackView.backgroundColor = [[ZXTheme accentCyan] colorWithAlphaComponent:0.15];
            self.thumbView.backgroundColor = [ZXTheme accentCyan];
            self.thumbView.layer.shadowColor = [ZXTheme accentCyan].CGColor;
            self.thumbView.layer.shadowOpacity = 0.9;
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
    overlay.alpha = 0;
    [parentView addSubview:overlay];
    
    UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    blur.frame = overlay.bounds;
    blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [overlay addSubview:blur];
    
    UIView *card = [[UIView alloc] init];
    [ZXTheme applyPremiumGlassmorphismToView:card cornerRadius:28];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.transform = CGAffineTransformMakeScale(0.85, 0.85);
    [overlay addSubview:card];
    
    card.layer.shadowColor = tint.CGColor;
    card.layer.shadowOpacity = 0.2;
    card.layer.shadowRadius = 50;
    card.layer.shadowOffset = CGSizeMake(0, 20);
    
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    iconView.tintColor = tint;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.layer.shadowColor = tint.CGColor;
    iconView.layer.shadowOpacity = 0.6;
    iconView.layer.shadowRadius = 20;
    [card addSubview:iconView];
    
    UILabel *titleLbl = [[UILabel alloc] init];
    titleLbl.text = [title uppercaseString];
    titleLbl.textColor = [ZXTheme textPrimary];
    titleLbl.font = [ZXTheme fontDisplay:17];
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
        [card.widthAnchor constraintEqualToConstant:320],
        
        [iconView.topAnchor constraintEqualToAnchor:card.topAnchor constant:36],
        [iconView.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [iconView.widthAnchor constraintEqualToConstant:55],
        [iconView.heightAnchor constraintEqualToConstant:55],
        
        [titleLbl.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:24],
        [titleLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [titleLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        
        [msgLbl.topAnchor constraintEqualToAnchor:titleLbl.bottomAnchor constant:12],
        [msgLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [msgLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        
        [btn.topAnchor constraintEqualToAnchor:msgLbl.bottomAnchor constant:36],
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
    
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
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

@property (nonatomic, strong) UIView *splashContainer;
@property (nonatomic, strong) UIView *authContainer;
@property (nonatomic, strong) UIView *verificationContainer;
@property (nonatomic, strong) UIView *dashboardContainer;

@property (nonatomic, strong) UIImageView *splashShield;
@property (nonatomic, strong) UIView *scannerLine;

@property (nonatomic, strong) ZXTextField *keyInput;
@property (nonatomic, strong) ZXButton *loginBtn;
@property (nonatomic, strong) UITapGestureRecognizer *dismissTap;

@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *expiryLabel;
@property (nonatomic, strong) UIScrollView *modulesScrollView;
@property (nonatomic, strong) UIStackView *modulesStackView; 
@property (nonatomic, strong) UIView *emptyStateView;

@end

@implementation ZentraxUI

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [ZXTheme bgDeepSpace];
    self.currentState = ZXAppStateInit;
    
    self.dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    self.dismissTap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:self.dismissTap];
    
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
    CGRect kbFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGRect btnRect = [self.authContainer convertRect:self.loginBtn.frame toView:self.view];
    CGFloat overlap = CGRectGetMaxY(btnRect) - kbFrame.origin.y;
    
    if (overlap > 0) {
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            weakSelf.authContainer.transform = CGAffineTransformMakeTranslation(0, -(overlap + 20));
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

- (void)setupCinematicAmbientBackground {
    UIImageView *grid = [[UIImageView alloc] initWithFrame:self.view.bounds];
    grid.image = [self createGridImage];
    grid.alpha = 0.15;
    grid.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:grid];
    
    UIView *topGlow = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 250, -150, 500, 500)];
    topGlow.backgroundColor = [[ZXTheme accentPurple] colorWithAlphaComponent:0.12];
    topGlow.layer.cornerRadius = 250;
    topGlow.layer.shadowColor = [ZXTheme accentPurple].CGColor;
    topGlow.layer.shadowRadius = 150;
    topGlow.layer.shadowOpacity = 1.0;
    [self.view addSubview:topGlow];
    
    UIView *bottomGlow = [[UIView alloc] initWithFrame:CGRectMake(-200, self.view.bounds.size.height - 300, 500, 500)];
    bottomGlow.backgroundColor = [[ZXTheme accentCyan] colorWithAlphaComponent:0.1];
    bottomGlow.layer.cornerRadius = 250;
    bottomGlow.layer.shadowColor = [ZXTheme accentCyan].CGColor;
    bottomGlow.layer.shadowRadius = 150;
    bottomGlow.layer.shadowOpacity = 1.0;
    [self.view addSubview:bottomGlow];
    
    [UIView animateWithDuration:12.0 delay:0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut animations:^{
        topGlow.transform = CGAffineTransformMakeTranslation(-100, 80);
        bottomGlow.transform = CGAffineTransformMakeTranslation(120, -100);
    } completion:nil];
}

- (UIImage *)createGridImage {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:1.0 alpha:0.1].CGColor);
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

#pragma mark - State Machine
- (void)transitionToState:(ZXAppState)newState {
    if (self.currentState == newState) return;
    self.currentState = newState;
    self.dismissTap.enabled = (newState != ZXAppStateDashboard);
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.splashContainer.alpha = (newState == ZXAppStateSplash) ? 1.0 : 0.0;
        weakSelf.authContainer.alpha = (newState == ZXAppStateAuth) ? 1.0 : 0.0;
        weakSelf.verificationContainer.alpha = (newState == ZXAppStateVerifying) ? 1.0 : 0.0;
        weakSelf.dashboardContainer.alpha = (newState == ZXAppStateDashboard) ? 1.0 : 0.0;
    } completion:nil];
}

#pragma mark - Premium Splash Sequence
- (void)setupSplash {
    _splashContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_splashContainer];
    
    _splashShield = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"shield.lefthalf.filled"]];
    _splashShield.tintColor = [ZXTheme accentCyan];
    _splashShield.contentMode = UIViewContentModeScaleAspectFit;
    _splashShield.layer.shadowColor = [ZXTheme accentCyan].CGColor;
    _splashShield.layer.shadowRadius = 40;
    _splashShield.layer.shadowOpacity = 0.9;
    _splashShield.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_splashShield];
    
    _scannerLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 2)];
    _scannerLine.backgroundColor = [UIColor whiteColor];
    _scannerLine.layer.shadowColor = [ZXTheme accentCyan].CGColor;
    _scannerLine.layer.shadowRadius = 8;
    _scannerLine.layer.shadowOpacity = 1.0;
    _scannerLine.layer.shadowOffset = CGSizeMake(0, 0);
    _scannerLine.alpha = 0;
    [_splashContainer addSubview:_scannerLine];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"SYSTEM INITIALIZING";
    title.textColor = [ZXTheme textPrimary];
    title.font = [ZXTheme fontDisplay:16];
    [ZXTheme applyTextTracking:title spacing:5.0];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:title];
    
    [NSLayoutConstraint activateConstraints:@[
        [_splashShield.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [_splashShield.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor constant:-40],
        [_splashShield.widthAnchor constraintEqualToConstant:90],
        [_splashShield.heightAnchor constraintEqualToConstant:100],
        
        [title.topAnchor constraintEqualToAnchor:_splashShield.bottomAnchor constant:40],
        [title.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
    ]];
}

- (void)runDeterministicLaunchSequence {
    self.currentState = ZXAppStateSplash;
    self.splashContainer.alpha = 1.0;
    
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.toValue = @1.1;
    pulse.duration = 0.8;
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    [self.splashShield.layer addAnimation:pulse forKey:@"pulse"];
    
    self.scannerLine.frame = CGRectMake(self.view.center.x - 45, self.view.center.y - 90, 90, 2);
    self.scannerLine.alpha = 1;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:1.2 delay:0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.scannerLine.frame = CGRectMake(weakSelf.view.center.x - 45, weakSelf.view.center.y + 10, 90, 2);
    } completion:nil];
    
    NSTimeInterval sequenceStartTime = CACurrentMediaTime();
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) {
        [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL isValid) {
            NSTimeInterval elapsed = CACurrentMediaTime() - sequenceStartTime;
            NSTimeInterval remainingDelay = MAX(0.0, 2.0 - elapsed);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, remainingDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                
                [strongSelf.splashShield.layer removeAllAnimations];
                strongSelf.scannerLine.alpha = 0;
                if (isValid) {
                    [strongSelf transitionToState:ZXAppStateDashboard];
                    [strongSelf showPremiumToast:@"Secure Session Restored" success:YES];
                } else {
                    [strongSelf transitionToState:ZXAppStateAuth];
                }
            });
        }];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            [strongSelf.splashShield.layer removeAllAnimations];
            strongSelf.scannerLine.alpha = 0;
            [strongSelf transitionToState:ZXAppStateAuth];
        });
    }
}

#pragma mark - Auth Flow
- (void)setupAuth {
    _authContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_authContainer];
    
    UILabel *headerSub = [[UILabel alloc] init];
    headerSub.text = @"ENTERPRISE ACCESS";
    headerSub.textColor = [ZXTheme accentCyan];
    headerSub.font = [ZXTheme fontMono:11 weight:UIFontWeightBold];
    [ZXTheme applyTextTracking:headerSub spacing:3.0];
    headerSub.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:headerSub];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"Authentication";
    title.textColor = [ZXTheme textPrimary];
    title.font = [ZXTheme fontDisplay:36];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:title];
    
    _keyInput = [[ZXTextField alloc] init];
    _keyInput.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:_keyInput];
    
    _loginBtn = [[ZXButton alloc] init];
    [_loginBtn setTitle:@"ESTABLISH LINK" forState:UIControlStateNormal];
    [_loginBtn addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside];
    _loginBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:_loginBtn];
    
    [NSLayoutConstraint activateConstraints:@[
        [headerSub.topAnchor constraintEqualToAnchor:_authContainer.safeAreaLayoutGuide.topAnchor constant:60],
        [headerSub.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:32],
        
        [title.topAnchor constraintEqualToAnchor:headerSub.bottomAnchor constant:8],
        [title.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:32],
        
        [_keyInput.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:60],
        [_keyInput.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:32],
        [_keyInput.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-32],
        [_keyInput.heightAnchor constraintEqualToConstant:64],
        
        [_loginBtn.bottomAnchor constraintEqualToAnchor:_authContainer.safeAreaLayoutGuide.bottomAnchor constant:-40],
        [_loginBtn.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:32],
        [_loginBtn.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-32],
        [_loginBtn.heightAnchor constraintEqualToConstant:58],
    ]];
}

- (void)handleLogin {
    [self dismissKeyboard];
    NSString *key = [self.keyInput.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (key.length == 0) {
        [self showPremiumToast:@"Invalid or empty protocol key." success:NO];
        return;
    }
    
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
                    [strongSelf showPremiumToast:@"Authentication Successful" success:YES];
                    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred];
                } else {
                    [strongSelf showGlobalErrorWithTitle:@"ACCESS DENIED" message:errorMsg ?: @"Key rejected by host."];
                }
            });
        }];
    } else {
        [self.loginBtn setLoading:NO];
        [self showGlobalErrorWithTitle:@"System Error" message:@"Authentication delegate is unavailable."];
    }
}

#pragma mark - Verification Screen
- (void)setupVerification {
    _verificationContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_verificationContainer];
}

#pragma mark - Dashboard Flow
- (void)setupDashboard {
    _dashboardContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_dashboardContainer];
    
    UIView *navBar = [[UIView alloc] init];
    navBar.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:navBar];
    
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.text = @"OVERSEER DASHBOARD";
    navTitle.textColor = [ZXTheme textPrimary];
    navTitle.font = [ZXTheme fontDisplay:16];
    [ZXTheme applyTextTracking:navTitle spacing:2.0];
    navTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [navBar addSubview:navTitle];
    
    UIButton *logoutBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [logoutBtn setImage:[UIImage systemImageNamed:@"power"] forState:UIControlStateNormal];
    logoutBtn.tintColor = [ZXTheme statusError];
    logoutBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [logoutBtn addTarget:self action:@selector(handleLogout) forControlEvents:UIControlEventTouchUpInside];
    [navBar addSubview:logoutBtn];
    
    UIView *statusCard = [[UIView alloc] init];
    [ZXTheme applyPremiumGlassmorphismToView:statusCard cornerRadius:20];
    statusCard.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:statusCard];
    
    UILabel *subTitle = [[UILabel alloc] init];
    subTitle.text = @"PROTOCOL STATUS";
    subTitle.textColor = [ZXTheme textMuted];
    subTitle.font = [ZXTheme fontMono:10 weight:UIFontWeightBold];
    [ZXTheme applyTextTracking:subTitle spacing:1.5];
    subTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:subTitle];
    
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.text = @"Active";
    _statusLabel.textColor = [ZXTheme statusSuccess];
    _statusLabel.font = [ZXTheme fontDisplay:22];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_statusLabel];
    
    _expiryLabel = [[UILabel alloc] init];
    _expiryLabel.text = @"Validating...";
    _expiryLabel.textColor = [ZXTheme textSecondary];
    _expiryLabel.font = [ZXTheme fontBody:12 weight:UIFontWeightMedium];
    _expiryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_expiryLabel];
    
    _modulesScrollView = [[UIScrollView alloc] init];
    _modulesScrollView.showsVerticalScrollIndicator = NO;
    _modulesScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _modulesScrollView.alwaysBounceVertical = YES;
    [_dashboardContainer addSubview:_modulesScrollView];
    
    _modulesStackView = [[UIStackView alloc] init];
    _modulesStackView.axis = UILayoutConstraintAxisVertical;
    _modulesStackView.spacing = 18;
    _modulesStackView.alignment = UIStackViewAlignmentFill;
    _modulesStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [_modulesScrollView addSubview:_modulesStackView];
    
    [self createEmptyStateView];
    
    [NSLayoutConstraint activateConstraints:@[
        [navBar.topAnchor constraintEqualToAnchor:_dashboardContainer.safeAreaLayoutGuide.topAnchor constant:10],
        [navBar.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [navBar.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [navBar.heightAnchor constraintEqualToConstant:44],
        
        [navTitle.leadingAnchor constraintEqualToAnchor:navBar.leadingAnchor],
        [navTitle.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],
        
        [logoutBtn.trailingAnchor constraintEqualToAnchor:navBar.trailingAnchor],
        [logoutBtn.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],
        [logoutBtn.widthAnchor constraintEqualToConstant:32],
        [logoutBtn.heightAnchor constraintEqualToConstant:32],
        
        [statusCard.topAnchor constraintEqualToAnchor:navBar.bottomAnchor constant:24],
        [statusCard.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [statusCard.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [statusCard.heightAnchor constraintEqualToConstant:110],
        
        [subTitle.topAnchor constraintEqualToAnchor:statusCard.topAnchor constant:24],
        [subTitle.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:24],
        
        [_statusLabel.topAnchor constraintEqualToAnchor:subTitle.bottomAnchor constant:6],
        [_statusLabel.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:24],
        
        [_expiryLabel.topAnchor constraintEqualToAnchor:_statusLabel.bottomAnchor constant:4],
        [_expiryLabel.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:24],
        
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
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"NO MODULES AVAILABLE";
    title.textColor = [ZXTheme textMuted];
    title.font = [ZXTheme fontDisplay:14];
    title.textAlignment = NSTextAlignmentCenter;
    [ZXTheme applyTextTracking:title spacing:2.0];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyStateView addSubview:title];
    
    [NSLayoutConstraint activateConstraints:@[
        [_emptyStateView.heightAnchor constraintEqualToConstant:200],
        [title.centerYAnchor constraintEqualToAnchor:_emptyStateView.centerYAnchor],
        [title.centerXAnchor constraintEqualToAnchor:_emptyStateView.centerXAnchor]
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
        sectionHeader.text = @"EXECUTION ENGINE";
        sectionHeader.textColor = [ZXTheme accentCyan];
        sectionHeader.font = [ZXTheme fontMono:10 weight:UIFontWeightBold];
        [ZXTheme applyTextTracking:sectionHeader spacing:2.0];
        [self.modulesStackView addArrangedSubview:sectionHeader];
        [self.modulesStackView setCustomSpacing:15 afterView:sectionHeader];
        
        for (NSDictionary *mod in modules) {
            NSString *moduleName = mod[@"name"] ?: @"UNKNOWN FEATURE";
            NSString *moduleDesc = mod[@"desc"] ?: mod[@"description"] ?: @"";
            NSString *currentState = mod[@"current_state"] ?: @"OFF"; 
            BOOL isModOn = [currentState isEqualToString:@"ON"];
            
            UIView *card = [[UIView alloc] init];
            [ZXTheme applyPremiumGlassmorphismToView:card cornerRadius:18];
            card.translatesAutoresizingMaskIntoConstraints = NO;
            
            UILabel *t = [[UILabel alloc] init];
            t.text = [moduleName uppercaseString];
            t.textColor = [ZXTheme textPrimary];
            t.font = [ZXTheme fontDisplay:16];
            t.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:t];
            
            UILabel *s = [[UILabel alloc] init];
            s.text = moduleDesc;
            s.textColor = [ZXTheme textSecondary];
            s.font = [ZXTheme fontBody:12 weight:UIFontWeightRegular];
            s.numberOfLines = 0;
            s.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:s];
            
            ZXToggle *toggle = [[ZXToggle alloc] init];
            toggle.moduleId = moduleName; 
            [toggle setOn:isModOn animated:NO]; 
            [toggle addTarget:self action:@selector(moduleToggled:) forControlEvents:UIControlEventValueChanged];
            [card addSubview:toggle];
            
            // High compression resistance to prevent long descriptions from squishing the toggle
            [toggle setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            
            [NSLayoutConstraint activateConstraints:@[
                [toggle.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
                [toggle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
                
                [t.topAnchor constraintEqualToAnchor:card.topAnchor constant:22],
                [t.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22],
                [t.trailingAnchor constraintLessThanOrEqualToAnchor:toggle.leadingAnchor constant:-16],
                
                [s.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:8],
                [s.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22],
                [s.trailingAnchor constraintLessThanOrEqualToAnchor:toggle.leadingAnchor constant:-16],
                [s.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-22]
            ]];
            
            [self.modulesStackView addArrangedSubview:card];
            
            card.alpha = 0;
            card.transform = CGAffineTransformMakeTranslation(0, 15);
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
            self.expiryLabel.text = @"Lifetime Access";
            self.expiryLabel.textColor = [ZXTheme accentCyan];
        } else if (expiryStr) {
            self.expiryLabel.text = [NSString stringWithFormat:@"Valid till: %@", expiryStr];
            self.expiryLabel.textColor = [ZXTheme textSecondary];
        } else {
            self.expiryLabel.text = @"No Expiry Data";
        }
        self.statusLabel.text = subData[@"status"] ?: @"Active";
    });
}

- (ZXToggle *)findToggleInCard:(UIView *)card {
    for (UIView *sub in card.subviews) {
        if ([sub isKindOfClass:[ZXToggle class]]) return (ZXToggle *)sub;
    }
    return nil;
}

- (void)moduleToggled:(ZXToggle *)sender {
    NSString *networkModuleId = sender.moduleId;
    if (!networkModuleId) return;
    
    BOOL requestedState = sender.isOn;
    ZXToggle *previousActiveToggle = nil;
    
    if (requestedState) {
        for (UIView *card in self.modulesStackView.arrangedSubviews) {
            ZXToggle *otherToggle = [self findToggleInCard:card];
            if (otherToggle && otherToggle != sender && otherToggle.isOn) {
                previousActiveToggle = otherToggle;
                [otherToggle setOn:NO animated:YES];
            }
        }
    }
    
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
                    [strongSelf showPremiumToast:toastMsg success:YES];
                } else {
                    [sender setOn:!requestedState animated:YES];
                    if (requestedState && previousActiveToggle) {
                        [previousActiveToggle setOn:YES animated:YES];
                    }
                    [strongSelf showGlobalErrorWithTitle:@"EXECUTION FAILED" message:errorMsg ?: @"Failed to inject execution payload safely."];
                }
            });
        }];
    } else {
        [sender setLoading:NO];
        [sender setOn:!requestedState animated:YES];
        if (requestedState && previousActiveToggle) {
            [previousActiveToggle setOn:YES animated:YES];
        }
        [self showGlobalErrorWithTitle:@"Bridge Disconnected" message:@"Execution delegate is unavailable. Cannot process action."];
    }
}

#pragma mark - Premium Toast Engine
- (void)showPremiumToast:(NSString *)msg success:(BOOL)success {
    for (UIView *v in self.view.subviews) {
        if (v.tag == 887766) {
            [v removeFromSuperview];
        }
    }
    
    CGFloat toastWidth = 280;
    CGFloat toastHeight = 50;
    
    UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
    CGFloat topInset = window.safeAreaInsets.top;
    if (topInset == 0) topInset = 45; 
    
    UIView *toast = [[UIView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - toastWidth)/2, -60, toastWidth, toastHeight)];
    toast.tag = 887766;
    
    [ZXTheme applyPremiumGlassmorphismToView:toast cornerRadius:25];
    toast.layer.borderColor = success ? [ZXTheme statusSuccess].CGColor : [ZXTheme statusError].CGColor;
    toast.layer.shadowColor = success ? [ZXTheme statusSuccess].CGColor : [ZXTheme statusError].CGColor;
    toast.layer.shadowOpacity = 0.5;
    toast.layer.shadowRadius = 15;
    toast.layer.shadowOffset = CGSizeMake(0, 5);
    
    UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectMake(16, 15, 20, 20)];
    icon.image = [[UIImage systemImageNamed:success ? @"checkmark.circle.fill" : @"xmark.circle.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    icon.tintColor = success ? [ZXTheme statusSuccess] : [ZXTheme statusError];
    [toast addSubview:icon];
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(46, 0, toastWidth - 60, toastHeight)];
    lbl.text = msg;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [ZXTheme fontBody:13 weight:UIFontWeightBold];
    [toast addSubview:lbl];
    
    [self.view addSubview:toast];
    
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:success ? UIImpactFeedbackStyleSoft : UIImpactFeedbackStyleHeavy] impactOccurred];
    
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        toast.frame = CGRectMake((self.view.bounds.size.width - toastWidth)/2, topInset + 10, toastWidth, toastHeight);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.4 delay:2.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
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
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"DISCONNECT NODE?" message:@"Hardware binding will remain active." preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Disconnect" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if ([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) {
            __weak typeof(self) weakSelf = self;
            [self.delegate zentraxDidRequestLogoutWithCompletion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (strongSelf) {
                        strongSelf.keyInput.textField.text = @"";
                        [strongSelf.keyInput updateFloatingLabelStateAnimated:NO];
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
        [ZXModalManager showModalWithIcon:@"xmark.octagon.fill" iconTint:[ZXTheme statusError] title:title message:msg actionTitle:@"DISMISS" inView:self.view];
    });
}
- (void)showSuccessMessage:(NSString *)title message:(NSString *)msg {}
- (void)showNetworkError {}
- (void)showServerError {}
- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds {}
- (void)showGlobalLoadingState:(NSString *)message {}
- (void)hideGlobalLoadingState {}

@end
