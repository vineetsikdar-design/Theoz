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
        self.transform = CGAffineTransformMakeScale(0.97, 0.97);
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
        self.bgView.alpha = 0.7;
    } else {
        [self setTitle:self.originalTitle forState:UIControlStateNormal];
        [self.spinner stopAnimating];
        self.bgView.alpha = 1.0;
    }
}
@end

// MARK: 2. ZXTextField
@interface ZXTextField : UIView <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *visibilityButton;
@property (nonatomic, strong) UIButton *pasteButton;
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
        _textField.returnKeyType = UIReturnKeyDone;
        
        NSAttributedString *ph = [[NSAttributedString alloc] initWithString:@"ENTER YOUR LICENSE KEY" attributes:@{
            NSForegroundColorAttributeName: [ZXTheme textMuted],
            NSKernAttributeName: @(1.5)
        }];
        _textField.attributedPlaceholder = ph;
        [self addSubview:_textField];
        
        _pasteButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_pasteButton setTitle:@"PASTE" forState:UIControlStateNormal];
        _pasteButton.titleLabel.font = [ZXTheme fontHeading:13];
        [_pasteButton setTitleColor:[ZXTheme accentCyan] forState:UIControlStateNormal];
        _pasteButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_pasteButton addTarget:self action:@selector(pasteKeyTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_pasteButton];
        
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
            [_textField.trailingAnchor constraintEqualToAnchor:_pasteButton.leadingAnchor constant:-12],
            [_textField.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_textField.heightAnchor constraintEqualToAnchor:self.heightAnchor],
            
            [_pasteButton.trailingAnchor constraintEqualToAnchor:_visibilityButton.leadingAnchor constant:-12],
            [_pasteButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            
            [_visibilityButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20],
            [_visibilityButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_visibilityButton.widthAnchor constraintEqualToConstant:24],
            [_visibilityButton.heightAnchor constraintEqualToConstant:24]
        ]];
    }
    return self;
}

- (void)pasteKeyTapped {
    NSString *pb = [[UIPasteboard generalPasteboard].string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (pb.length > 0) {
        self.textField.text = pb;
        UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [haptic impactOccurred];
    } else {
        self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"CLIPBOARD EMPTY" attributes:@{NSForegroundColorAttributeName: [ZXTheme statusWarning]}];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"ENTER YOUR LICENSE KEY" attributes:@{NSForegroundColorAttributeName: [ZXTheme textMuted], NSKernAttributeName: @(1.5)}];
        });
    }
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end

// MARK: 3. ZXToggle (Precision Hardware Switch - With Network Binding)
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
@property (nonatomic, strong) UIView *emptyStateView;

// Rate limiting state
@property (nonatomic, strong) NSMutableDictionary *toggleTimestamps;
@end

@implementation ZentraxUI

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [ZXTheme bgDeepSpace];
    self.toggleTimestamps = [NSMutableDictionary dictionary];
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
    
    // Resume Lifecycle Fix: Only run splash on true fresh presentation
    if (!self.hasCompletedInitialPresentation) {
        self.hasCompletedInitialPresentation = YES;
        [self runInitialSessionCheck];
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
    topGlow.backgroundColor = [[ZXTheme accentViolet] colorWithAlphaComponent:0.06];
    topGlow.layer.cornerRadius = 250;
    topGlow.layer.shadowColor = [ZXTheme accentViolet].CGColor;
    topGlow.layer.shadowRadius = 150;
    topGlow.layer.shadowOpacity = 1.0;
    [self.view addSubview:topGlow];
    
    UIView *bottomGlow = [[UIView alloc] initWithFrame:CGRectMake(-150, self.view.bounds.size.height - 250, 400, 400)];
    bottomGlow.backgroundColor = [[ZXTheme accentCyan] colorWithAlphaComponent:0.04];
    bottomGlow.layer.cornerRadius = 200;
    bottomGlow.layer.shadowColor = [ZXTheme accentCyan].CGColor;
    bottomGlow.layer.shadowRadius = 150;
    bottomGlow.layer.shadowOpacity = 1.0;
    [self.view addSubview:bottomGlow];
    
    [UIView animateWithDuration:12.0 delay:0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut animations:^{
        topGlow.transform = CGAffineTransformMakeTranslation(-60, 80);
        bottomGlow.transform = CGAffineTransformMakeTranslation(80, -60);
    } completion:nil];
}

#pragma mark - State Machine
- (void)transitionToState:(ZXAppState)newState {
    self.currentState = newState;
    [UIView animateWithDuration:0.6 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.splashContainer.alpha = (newState == ZXAppStateSplash) ? 1.0 : 0.0;
        self.authContainer.alpha = (newState == ZXAppStateAuth) ? 1.0 : 0.0;
        self.verificationContainer.alpha = (newState == ZXAppStateVerifying) ? 1.0 : 0.0;
        self.dashboardContainer.alpha = (newState == ZXAppStateDashboard) ? 1.0 : 0.0;
    } completion:nil];
}

- (void)runInitialSessionCheck {
    [self transitionToState:ZXAppStateVerifying];
    self.verificationStepLabel.text = @"RESTORING SESSION";
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) {
        [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL isValid) {
            if (isValid) {
                self.verificationStepLabel.text = @"SESSION VERIFIED";
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [self transitionToState:ZXAppStateDashboard];
                });
            } else {
                [self transitionToState:ZXAppStateSplash];
                [self runSplashSequence];
            }
        }];
    } else {
        [self transitionToState:ZXAppStateSplash];
        [self runSplashSequence];
    }
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

- (void)runSplashSequence {
    [UIView animateWithDuration:1.5 delay:0.3 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.progressFill.frame = CGRectMake(0, 0, (self.view.bounds.size.width - 160) * 0.85, 3);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.4 animations:^{
            self.progressFill.frame = CGRectMake(0, 0, self.view.bounds.size.width - 160, 3);
        } completion:^(BOOL finished) {
            [self transitionToState:ZXAppStateAuth];
        }];
    }];
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
        [_loginBtn.heightAnchor constraintEqualToConstant:60],
    ]];
}

- (void)handleLogin {
    [self dismissKeyboard];
    
    NSString *key = self.keyInput.textField.text;
    if (key.length == 0) {
        [self showGlobalErrorWithTitle:@"Authentication Failed" message:@"You must enter a valid license key to proceed."];
        return;
    }
    
    [self.loginBtn setLoading:YES];
    [self transitionToState:ZXAppStateVerifying];
    
    // Four Step Visual Sequence
    self.verificationStepLabel.text = @"SECURE CONNECTION";
    self.verificationStepLabel.textColor = [ZXTheme accentCyan];
    [self.verificationSpinner startAnimating];
    
    NSArray *steps = @[@"VERIFYING LICENSE", @"VALIDATING ACCESS", @"FINALIZING SESSION"];
    for (int i = 0; i < steps.count; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (0.5 * (i + 1)) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (self.currentState == ZXAppStateVerifying) {
                self.verificationStepLabel.text = steps[i];
            }
        });
    }
    
    NSTimeInterval startTime = CACurrentMediaTime();
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestAuthenticationWithKey:completion:)]) {
        [self.delegate zentraxDidRequestAuthenticationWithKey:key completion:^(BOOL success, NSString *errorMsg) {
            
            NSTimeInterval elapsed = CACurrentMediaTime() - startTime;
            NSTimeInterval remainingDelay = MAX(0.0, 2.0 - elapsed); // Enforce ~2s minimum duration
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, remainingDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self.loginBtn setLoading:NO];
                if (success) {
                    [self executeSuccessAnimation];
                } else {
                    [self transitionToState:ZXAppStateAuth];
                    
                    if (errorMsg && [errorMsg.lowercaseString containsString:@"expired"]) {
                        [ZXModalManager showModalWithIcon:@"exclamationmark.triangle.fill" iconTint:[ZXTheme statusWarning] title:@"License Expired" message:@"This license has expired and can no longer be used." actionTitle:@"TRY ANOTHER KEY" inView:self.view];
                    } else if (errorMsg && [errorMsg.lowercaseString containsString:@"connection"]) {
                        [ZXModalManager showModalWithIcon:@"wifi.slash" iconTint:[ZXTheme statusError] title:@"Connection Problem" message:@"We couldn't reach the Zentrax verification service." actionTitle:@"TRY AGAIN" inView:self.view];
                    } else {
                        [self showGlobalErrorWithTitle:@"Verification Failed" message:errorMsg ?: @"The license key could not be verified."];
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
    [logoutBtn setImage:[UIImage systemImageNamed:@"rectangle.portrait.and.arrow.right"] forState:UIControlStateNormal];
    logoutBtn.tintColor = [ZXTheme textMuted];
    logoutBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [logoutBtn addTarget:self action:@selector(handleLogout) forControlEvents:UIControlEventTouchUpInside];
    [navBar addSubview:logoutBtn];
    
    UIView *statusCard = [[UIView alloc] init];
    [ZXTheme applyPremiumGlassmorphismToView:statusCard cornerRadius:20];
    statusCard.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:statusCard];
    
    UILabel *subTitle = [[UILabel alloc] init];
    subTitle.text = @"LICENSE STATUS";
    subTitle.textColor = [ZXTheme textMuted];
    subTitle.font = [ZXTheme fontMono:11 weight:UIFontWeightBold];
    [ZXTheme applyTextTracking:subTitle spacing:1.5];
    subTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:subTitle];
    
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.text = @"Awaiting Status..."; 
    _statusLabel.textColor = [ZXTheme textPrimary];
    _statusLabel.font = [ZXTheme fontHeading:18];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_statusLabel];
    
    _expiryLabel = [[UILabel alloc] init];
    _expiryLabel.text = @"Authenticating..."; 
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
    [_dashboardContainer addSubview:_modulesScrollView];
    
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
        [logoutBtn.widthAnchor constraintEqualToConstant:30],
        [logoutBtn.heightAnchor constraintEqualToConstant:30],
        
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
        [_modulesScrollView.bottomAnchor constraintEqualToAnchor:_dashboardContainer.bottomAnchor]
    ]];
}

- (void)createEmptyStateView {
    _emptyStateView = [[UIView alloc] initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width, 200)];
    
    UIView *iconContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
    iconContainer.center = CGPointMake(self.view.bounds.size.width / 2, 35);
    iconContainer.layer.cornerRadius = 35;
    iconContainer.backgroundColor = [[ZXTheme accentCyan] colorWithAlphaComponent:0.1];
    iconContainer.layer.shadowColor = [ZXTheme accentCyan].CGColor;
    iconContainer.layer.shadowRadius = 20;
    iconContainer.layer.shadowOpacity = 0.5;
    [_emptyStateView addSubview:iconContainer];
    
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"cube.transparent"]];
    icon.tintColor = [ZXTheme accentCyan];
    icon.frame = CGRectMake(15, 15, 40, 40);
    [iconContainer addSubview:icon];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 90, self.view.bounds.size.width - 40, 25)];
    title.text = @"No Functions Available";
    title.textColor = [ZXTheme textPrimary];
    title.font = [ZXTheme fontHeading:18];
    title.textAlignment = NSTextAlignmentCenter;
    [_emptyStateView addSubview:title];
    
    UILabel *sub = [[UILabel alloc] initWithFrame:CGRectMake(40, 120, self.view.bounds.size.width - 80, 40)];
    sub.text = @"There are currently no functions available for your account.\nCheck back later when new functions become available.";
    sub.textColor = [ZXTheme textSecondary];
    sub.font = [ZXTheme fontBody:13 weight:UIFontWeightRegular];
    sub.textAlignment = NSTextAlignmentCenter;
    sub.numberOfLines = 0;
    [_emptyStateView addSubview:sub];
}

- (void)updateDashboardWithModules:(NSArray<NSDictionary *> *)modules {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.modulesScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        if (!modules || modules.count == 0) {
            [self.modulesScrollView addSubview:self.emptyStateView];
            self.emptyStateView.alpha = 0;
            self.emptyStateView.transform = CGAffineTransformMakeScale(0.85, 0.85);
            [UIView animateWithDuration:0.5 delay:0.2 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.emptyStateView.alpha = 1;
                self.emptyStateView.transform = CGAffineTransformIdentity;
            } completion:nil];
            return;
        }
        
        CGFloat yOffset = 10;
        
        UILabel *sectionHeader = [[UILabel alloc] initWithFrame:CGRectMake(24, yOffset, 200, 20)];
        sectionHeader.text = @"CONTROL CENTER";
        sectionHeader.textColor = [ZXTheme accentCyan];
        sectionHeader.font = [ZXTheme fontMono:11 weight:UIFontWeightBold];
        [ZXTheme applyTextTracking:sectionHeader spacing:2.0];
        [self.modulesScrollView addSubview:sectionHeader];
        
        yOffset += 40;
        
        for (NSDictionary *mod in modules) {
            NSString *moduleName = mod[@"name"] ?: @"UNKNOWN FEATURE";
            NSString *moduleDesc = mod[@"desc"] ?: mod[@"description"] ?: @"No description provided.";
            
            UIView *card = [[UIView alloc] initWithFrame:CGRectMake(24, yOffset, self.view.bounds.size.width - 48, 80)];
            [ZXTheme applyPremiumGlassmorphismToView:card cornerRadius:14];
            
            UIView *iconContainer = [[UIView alloc] initWithFrame:CGRectMake(16, 20, 40, 40)];
            iconContainer.backgroundColor = [[ZXTheme accentCyan] colorWithAlphaComponent:0.1];
            iconContainer.layer.cornerRadius = 8;
            iconContainer.layer.shadowColor = [ZXTheme accentCyan].CGColor;
            iconContainer.layer.shadowRadius = 8;
            iconContainer.layer.shadowOpacity = 0.3;
            [card addSubview:iconContainer];
            
            NSString *iconName = mod[@"icon"] ?: @"bolt.fill";
            UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:iconName]];
            icon.tintColor = [ZXTheme accentCyan];
            icon.frame = CGRectMake(10, 10, 20, 20);
            [iconContainer addSubview:icon];
            
            UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(72, 18, card.bounds.size.width - 140, 20)];
            t.text = [moduleName uppercaseString];
            t.textColor = [ZXTheme textPrimary];
            t.font = [ZXTheme fontHeading:15];
            [card addSubview:t];
            
            UILabel *s = [[UILabel alloc] initWithFrame:CGRectMake(72, 42, card.bounds.size.width - 140, 16)];
            s.text = [moduleDesc uppercaseString];
            s.textColor = [ZXTheme textMuted];
            s.font = [ZXTheme fontBody:11 weight:UIFontWeightMedium];
            [card addSubview:s];
            
            ZXToggle *toggle = [[ZXToggle alloc] init];
            toggle.frame = CGRectMake(card.bounds.size.width - 70, 25, 54, 30);
            toggle.moduleId = moduleName; 
            [toggle addTarget:self action:@selector(moduleToggled:) forControlEvents:UIControlEventValueChanged];
            [card addSubview:toggle];
            
            card.alpha = 0;
            card.transform = CGAffineTransformMakeTranslation(0, 20);
            [self.modulesScrollView addSubview:card];
            yOffset += 96;
            
            [UIView animateWithDuration:0.5 delay:([modules indexOfObject:mod] * 0.1) usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                card.alpha = 1;
                card.transform = CGAffineTransformIdentity;
            } completion:nil];
        }
        
        self.modulesScrollView.contentSize = CGSizeMake(self.view.bounds.size.width, yOffset + 50);
    });
}

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
            self.statusLabel.text = @"Active";
        }
    });
}

- (void)moduleToggled:(ZXToggle *)sender {
    NSString *networkModuleId = sender.moduleId;
    if (!networkModuleId) return;
    
    NSDate *now = [NSDate date];
    
    NSMutableArray *stamps = self.toggleTimestamps[networkModuleId] ?: [NSMutableArray array];
    [stamps filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDate *d, NSDictionary *b) {
        return [now timeIntervalSinceDate:d] < 5.0; 
    }]];
    [stamps addObject:now];
    self.toggleTimestamps[networkModuleId] = stamps;
    
    if (stamps.count > 4) {
        [sender setOn:!sender.isOn animated:YES];
        [self showRateLimitErrorWithSecondsRemaining:5];
        return;
    }
    
    [sender setLoading:YES];
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestModuleToggle:state:completion:)]) {
        [self.delegate zentraxDidRequestModuleToggle:networkModuleId state:sender.isOn completion:^(BOOL success, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setLoading:NO];
                if (!success) {
                    [sender setOn:!sender.isOn animated:YES];
                    [self showGlobalErrorWithTitle:@"Action Failed" message:errorMsg ?: @"Failed to verify feature access."];
                }
            });
        }];
    } else {
        [sender setLoading:NO];
        [sender setOn:!sender.isOn animated:YES]; 
        [self showGlobalErrorWithTitle:@"Configuration Error" message:@"Execution delegate is unavailable. Cannot process action."];
    }
}

#pragma mark - Logout and Errors
- (void)handleLogout {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sign out of Zentrax VIP?" message:@"Your saved session will be removed from this device." preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Logout" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if ([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) {
            [self.delegate zentraxDidRequestLogoutWithCompletion:^{
                self.keyInput.textField.text = @"";
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
    [self showGlobalErrorWithTitle:@"CONNECTION ERROR" message:@"Secure connection to the Zentrax VIP network could not be established. Verify your network access."];
}

- (void)showServerError {
    [self showGlobalErrorWithTitle:@"Server Error" message:@"The Zentrax server responded with an unexpected status. Retrying is advised."];
}

- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds {
    NSString *msg = [NSString stringWithFormat:@"Maximum request capacity reached to preserve server stability. Cooldown active for %ld seconds.", (long)seconds];
    [ZXModalManager showModalWithIcon:@"timer" iconTint:[ZXTheme statusWarning] title:@"RATE LIMITED" message:msg actionTitle:@"UNDERSTOOD" inView:self.view];
}

- (void)showGlobalLoadingState:(NSString *)message {}
- (void)hideGlobalLoadingState {}

@end
