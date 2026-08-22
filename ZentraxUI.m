//
//  ZentraxUI.m
//  Zentrax VIP - Premium Execution Node UI
//
//  Created by Zentrax Team.
//  Architecture: Ultra-Premium Security SaaS Layer
//  Status: PRODUCTION READY
//

#import "ZentraxUI.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>

#pragma mark - ================= PREMIUM DESIGN SYSTEM =================

@interface ZXTheme : NSObject
+ (UIColor *)bgDeepSpace;
+ (UIColor *)bgCardOuter;
+ (UIColor *)bgCardInner;
+ (UIColor *)borderSubtle;
+ (UIColor *)accentPrimary;
+ (UIColor *)accentSecondary;
+ (UIColor *)textPrimary;
+ (UIColor *)textSecondary;
+ (UIColor *)textMuted;
+ (UIColor *)statusSuccess;
+ (UIColor *)statusError;

+ (UIFont *)fontDisplay:(CGFloat)size;
+ (UIFont *)fontHeading:(CGFloat)size;
+ (UIFont *)fontBody:(CGFloat)size weight:(UIFontWeight)weight;
+ (UIFont *)fontMono:(CGFloat)size weight:(UIFontWeight)weight;

+ (CAGradientLayer *)premiumGradient;
+ (void)applyTextTracking:(UILabel *)label spacing:(CGFloat)spacing;
+ (void)applyPremiumGlassmorphismToView:(UIView *)view cornerRadius:(CGFloat)radius;
@end

@implementation ZXTheme

// Deep matte, enterprise-grade dark background
+ (UIColor *)bgDeepSpace { return [UIColor colorWithRed:0.04 green:0.04 blue:0.05 alpha:1.0]; }
+ (UIColor *)bgCardOuter { return [UIColor colorWithRed:0.08 green:0.08 blue:0.10 alpha:0.85]; }
+ (UIColor *)bgCardInner { return [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:1.0]; }

+ (UIColor *)borderSubtle { return [UIColor colorWithWhite:1.0 alpha:0.08]; }

// Clean SaaS Accents (Indigo & Cyan)
+ (UIColor *)accentPrimary { return [UIColor colorWithRed:0.35 green:0.34 blue:0.88 alpha:1.0]; }
+ (UIColor *)accentSecondary { return [UIColor colorWithRed:0.0 green:0.85 blue:1.0 alpha:1.0]; }

+ (UIColor *)textPrimary { return [UIColor colorWithWhite:0.98 alpha:1.0]; }
+ (UIColor *)textSecondary { return [UIColor colorWithWhite:0.65 alpha:1.0]; }
+ (UIColor *)textMuted { return [UIColor colorWithWhite:0.40 alpha:1.0]; }

+ (UIColor *)statusSuccess { return [UIColor colorWithRed:0.20 green:0.82 blue:0.40 alpha:1.0]; }
+ (UIColor *)statusError { return [UIColor colorWithRed:1.0 green:0.25 blue:0.30 alpha:1.0]; }

+ (UIFont *)fontDisplay:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBlack]; }
+ (UIFont *)fontHeading:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightSemibold]; }
+ (UIFont *)fontBody:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont systemFontOfSize:size weight:weight]; }
+ (UIFont *)fontMono:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont monospacedSystemFontOfSize:size weight:weight]; }

+ (CAGradientLayer *)premiumGradient {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[(id)[self accentPrimary].CGColor, (id)[self accentSecondary].CGColor];
    gradient.startPoint = CGPointMake(0.0, 0.0);
    gradient.endPoint = CGPointMake(1.0, 1.0);
    return gradient;
}

+ (void)applyTextTracking:(UILabel *)label spacing:(CGFloat)spacing {
    if (!label.text) return;
    NSDictionary *attrs = @{NSKernAttributeName: @(spacing)};
    label.attributedText = [[NSAttributedString alloc] initWithString:label.text attributes:attrs];
}

+ (void)applyPremiumGlassmorphismToView:(UIView *)view cornerRadius:(CGFloat)radius {
    for (UIView *sub in view.subviews) {
        if (sub.tag == 998877) [sub removeFromSuperview];
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

@end

#pragma mark - ================= SUBTLE ANIMATED BACKGROUND =================

@interface ZXAnimatedAtmosphere : UIView
@property (nonatomic, strong) UIView *gridLayer;
@property (nonatomic, strong) UIView *glow1;
@property (nonatomic, strong) UIView *glow2;
- (void)startAtmosphere;
- (void)stopAtmosphere;
@end

@implementation ZXAnimatedAtmosphere

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [ZXTheme bgDeepSpace];
        self.clipsToBounds = YES;
        self.userInteractionEnabled = NO;
        
        // Deep space subtle ambient glows
        _glow1 = [[UIView alloc] initWithFrame:CGRectMake(-150, -100, 500, 500)];
        _glow1.backgroundColor = [[ZXTheme accentPrimary] colorWithAlphaComponent:0.06];
        _glow1.layer.cornerRadius = 250;
        _glow1.layer.shadowColor = [ZXTheme accentPrimary].CGColor;
        _glow1.layer.shadowRadius = 100;
        _glow1.layer.shadowOpacity = 0.6;
        [self addSubview:_glow1];
        
        _glow2 = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width - 250, frame.size.height - 350, 600, 600)];
        _glow2.backgroundColor = [[ZXTheme accentSecondary] colorWithAlphaComponent:0.04];
        _glow2.layer.cornerRadius = 300;
        _glow2.layer.shadowColor = [ZXTheme accentSecondary].CGColor;
        _glow2.layer.shadowRadius = 120;
        _glow2.layer.shadowOpacity = 0.6;
        [self addSubview:_glow2];
        
        // Elegant minimal tracking grid
        _gridLayer = [[UIView alloc] initWithFrame:CGRectMake(0, -60, frame.size.width, frame.size.height + 120)];
        _gridLayer.backgroundColor = [UIColor colorWithPatternImage:[self drawGridImage]];
        _gridLayer.alpha = 0.15;
        [self addSubview:_gridLayer];
        
        // Smooth top/bottom fade
        CAGradientLayer *maskLayer = [CAGradientLayer layer];
        maskLayer.frame = self.bounds;
        maskLayer.colors = @[(id)[UIColor clearColor].CGColor, (id)[UIColor whiteColor].CGColor, (id)[UIColor whiteColor].CGColor, (id)[UIColor clearColor].CGColor];
        maskLayer.locations = @[@0.0, @0.2, @0.8, @1.0];
        self.layer.mask = maskLayer;
    }
    return self;
}

- (UIImage *)drawGridImage {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:1.0 alpha:0.1].CGColor);
    CGContextSetLineWidth(ctx, 0.5); // Elegant, thin lines
    CGContextMoveToPoint(ctx, 0, 0); CGContextAddLineToPoint(ctx, 40, 0);
    CGContextMoveToPoint(ctx, 0, 0); CGContextAddLineToPoint(ctx, 0, 40);
    CGContextStrokePath(ctx);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (void)startAtmosphere {
    // Smooth grid scroll
    CABasicAnimation *scroll = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    scroll.toValue = @(40);
    scroll.duration = 6.0;
    scroll.repeatCount = HUGE_VALF;
    scroll.fillMode = kCAFillModeForwards;
    [self.gridLayer.layer addAnimation:scroll forKey:@"gridScroll"];
    
    // Slow cinematic light shifting
    [UIView animateWithDuration:15.0 delay:0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut animations:^{
        self.glow1.transform = CGAffineTransformMakeTranslation(80, 120);
        self.glow2.transform = CGAffineTransformMakeTranslation(-100, -80);
    } completion:nil];
}

- (void)stopAtmosphere {
    [self.gridLayer.layer removeAllAnimations];
    [self.glow1.layer removeAllAnimations];
    [self.glow2.layer removeAllAnimations];
}

@end

#pragma mark - ================= PREMIUM UI COMPONENTS =================

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
        self.layer.cornerRadius = 12;
        self.titleLabel.font = [ZXTheme fontHeading:15];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        _bgView = [[UIView alloc] init];
        _bgView.layer.cornerRadius = 12;
        _bgView.clipsToBounds = YES;
        _bgView.userInteractionEnabled = NO;
        _bgView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_bgView];
        
        _gradientLayer = [ZXTheme premiumGradient];
        [_bgView.layer insertSublayer:_gradientLayer atIndex:0];
        
        self.layer.shadowColor = [ZXTheme accentPrimary].CGColor;
        self.layer.shadowOpacity = 0.25;
        self.layer.shadowRadius = 10;
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
            
            [_arrowIcon.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-18],
            [_arrowIcon.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_arrowIcon.widthAnchor constraintEqualToConstant:14],
            [_arrowIcon.heightAnchor constraintEqualToConstant:14]
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
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [UIView animateWithDuration:0.15 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformMakeScale(0.96, 0.96);
        self.layer.shadowOpacity = 0.5;
    } completion:nil];
}

- (void)touchUp {
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.transform = CGAffineTransformIdentity;
        self.layer.shadowOpacity = 0.25;
    } completion:nil];
}

- (void)setLoading:(BOOL)loading {
    self.userInteractionEnabled = !loading;
    if (loading) {
        self.originalTitle = [self titleForState:UIControlStateNormal];
        [self setTitle:@"" forState:UIControlStateNormal];
        self.arrowIcon.alpha = 0;
        [self.spinner startAnimating];
        self.bgView.alpha = 0.85;
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
@property (nonatomic, strong) UIButton *eyeButton;
@property (nonatomic, strong) UIView *inputContainer;
@property (nonatomic, strong) UIImageView *iconView;
@end

@implementation ZXTextField

- (instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
        
        _topLabel = [[UILabel alloc] init];
        _topLabel.text = @"SECURITY PROTOCOL KEY";
        _topLabel.textColor = [ZXTheme textSecondary];
        _topLabel.font = [ZXTheme fontHeading:11];
        [ZXTheme applyTextTracking:_topLabel spacing:1.0];
        _topLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_topLabel];
        
        _inputContainer = [[UIView alloc] init];
        _inputContainer.backgroundColor = [ZXTheme bgCardOuter];
        _inputContainer.layer.cornerRadius = 12;
        _inputContainer.layer.borderWidth = 1.0;
        _inputContainer.layer.borderColor = [ZXTheme borderSubtle].CGColor;
        _inputContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_inputContainer];
        
        _iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.shield.fill"]];
        _iconView.tintColor = [ZXTheme textMuted];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.translatesAutoresizingMaskIntoConstraints = NO;
        [_inputContainer addSubview:_iconView];
        
        _textField = [[UITextField alloc] init];
        _textField.textColor = [ZXTheme textPrimary];
        _textField.font = [ZXTheme fontMono:15 weight:UIFontWeightMedium];
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
        _pasteButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.06];
        _pasteButton.layer.cornerRadius = 6;
        [_pasteButton setTitleColor:[ZXTheme textPrimary] forState:UIControlStateNormal];
        _pasteButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_pasteButton addTarget:self action:@selector(pasteKeyTapped) forControlEvents:UIControlEventTouchUpInside];
        [_inputContainer addSubview:_pasteButton];
        
        _eyeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_eyeButton setImage:[UIImage systemImageNamed:@"eye.slash.fill"] forState:UIControlStateNormal];
        _eyeButton.tintColor = [ZXTheme textMuted];
        _eyeButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_eyeButton addTarget:self action:@selector(toggleSecureEntry) forControlEvents:UIControlEventTouchUpInside];
        [_inputContainer addSubview:_eyeButton];
        
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
            [_pasteButton.widthAnchor constraintEqualToConstant:60],
            
            [_eyeButton.trailingAnchor constraintEqualToAnchor:_pasteButton.leadingAnchor constant:-4],
            [_eyeButton.centerYAnchor constraintEqualToAnchor:_inputContainer.centerYAnchor],
            [_eyeButton.widthAnchor constraintEqualToConstant:32],
            [_eyeButton.heightAnchor constraintEqualToConstant:32],
            
            [_textField.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor constant:12],
            [_textField.trailingAnchor constraintEqualToAnchor:_eyeButton.leadingAnchor constant:-8],
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

- (void)toggleSecureEntry {
    self.textField.secureTextEntry = !self.textField.secureTextEntry;
    NSString *icon = self.textField.secureTextEntry ? @"eye.slash.fill" : @"eye.fill";
    [self.eyeButton setImage:[UIImage systemImageNamed:icon] forState:UIControlStateNormal];
    
    NSString *txt = self.textField.text;
    self.textField.text = @"";
    self.textField.text = txt;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.3 animations:^{
        self.inputContainer.layer.borderColor = [ZXTheme accentPrimary].CGColor;
        self.iconView.tintColor = [ZXTheme accentSecondary];
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
        _thumbView.layer.cornerRadius = 12;
        _thumbView.userInteractionEnabled = NO;
        _thumbView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_thumbView];
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        _spinner.transform = CGAffineTransformMakeScale(0.6, 0.6);
        _spinner.hidesWhenStopped = YES;
        _spinner.translatesAutoresizingMaskIntoConstraints = NO;
        [_thumbView addSubview:_spinner];
        
        _thumbLeadingConstraint = [_thumbView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:2];
        
        [NSLayoutConstraint activateConstraints:@[
            [_trackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_trackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_trackView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_trackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            
            [_thumbView.widthAnchor constraintEqualToConstant:24],
            [_thumbView.heightAnchor constraintEqualToConstant:24],
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

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return CGRectContainsPoint(CGRectInset(self.bounds, -15, -15), point);
}

- (void)handleTap {
    if (!self.userInteractionEnabled) return;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [self setOn:!self.isOn animated:YES];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _isOn = on;
    [self updateStateAnimated:animated];
}

- (void)updateStateAnimated:(BOOL)animated {
    self.thumbLeadingConstraint.constant = self.isOn ? 24 : 2; // 50 - 24 - 2 = 24
    
    void (^stateUpdates)(void) = ^{
        [self layoutIfNeeded];
        if (self.isOn) {
            self.trackView.layer.borderColor = [ZXTheme accentSecondary].CGColor;
            self.trackView.backgroundColor = [ZXTheme accentSecondary];
            self.thumbView.backgroundColor = [UIColor whiteColor];
        } else {
            self.trackView.layer.borderColor = [ZXTheme borderSubtle].CGColor;
            self.trackView.backgroundColor = [ZXTheme bgCardInner];
            self.thumbView.backgroundColor = [ZXTheme textMuted];
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.4 options:UIViewAnimationOptionCurveEaseInOut animations:stateUpdates completion:nil];
    } else {
        stateUpdates();
    }
}

- (void)setLoading:(BOOL)loading {
    self.userInteractionEnabled = !loading;
    if (loading) {
        self.thumbView.backgroundColor = [UIColor clearColor];
        [self.spinner startAnimating];
    } else {
        [self.spinner stopAnimating];
        [self updateStateAnimated:YES];
    }
}

@end

#pragma mark - ================= NOTIFICATION / MODAL SYSTEM =================

@interface ZXPremiumToast : NSObject
+ (void)showSuccess:(NSString *)message inView:(UIView *)view;
+ (void)showError:(NSString *)title message:(NSString *)msg inView:(UIView *)view;
@end

@implementation ZXPremiumToast

// Compact elegant toast for normal successes/actions (Replacing huge modals)
+ (void)showSuccess:(NSString *)message inView:(UIView *)view {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *v in view.subviews) {
            if (v.tag == 887766) [v removeFromSuperview];
        }
        
        CGFloat toastWidth = 260;
        CGFloat toastHeight = 44;
        
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
        
        UIView *toast = [[UIView alloc] initWithFrame:CGRectMake((view.bounds.size.width - toastWidth)/2, -60, toastWidth, toastHeight)];
        toast.tag = 887766;
        [ZXTheme applyPremiumGlassmorphismToView:toast cornerRadius:22];
        toast.layer.borderColor = [ZXTheme borderSubtle].CGColor;
        toast.layer.shadowColor = [UIColor blackColor].CGColor;
        toast.layer.shadowOpacity = 0.3;
        toast.layer.shadowRadius = 15;
        toast.layer.zPosition = 9999;
        
        UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(16, 18, 8, 8)];
        dot.backgroundColor = [ZXTheme statusSuccess];
        dot.layer.cornerRadius = 4;
        dot.layer.shadowColor = [ZXTheme statusSuccess].CGColor;
        dot.layer.shadowRadius = 4;
        dot.layer.shadowOpacity = 0.8;
        [toast addSubview:dot];
        
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(36, 0, toastWidth - 50, toastHeight)];
        lbl.text = message;
        lbl.textColor = [UIColor whiteColor];
        lbl.font = [ZXTheme fontHeading:13];
        [toast addSubview:lbl];
        
        [view addSubview:toast];
        
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
        
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            toast.frame = CGRectMake((view.bounds.size.width - toastWidth)/2, topInset + 10, toastWidth, toastHeight);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 delay:1.8 options:UIViewAnimationOptionCurveEaseIn animations:^{
                toast.frame = CGRectMake((view.bounds.size.width - toastWidth)/2, -60, toastWidth, toastHeight);
                toast.alpha = 0;
            } completion:^(BOOL finished) {
                [toast removeFromSuperview];
            }];
        }];
    });
}

// Compact premium modal for errors/critical info
+ (void)showError:(NSString *)title message:(NSString *)msg inView:(UIView *)view {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *overlay = [[UIView alloc] initWithFrame:view.bounds];
        overlay.tag = 100100;
        overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        overlay.alpha = 0;
        overlay.layer.zPosition = 9999;
        [view addSubview:overlay];
        
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurView.frame = overlay.bounds;
        blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        blurView.alpha = 0.8;
        [overlay addSubview:blurView];
        
        UIView *card = [[UIView alloc] init];
        [ZXTheme applyPremiumGlassmorphismToView:card cornerRadius:20];
        card.layer.borderColor = [ZXTheme statusError].CGColor;
        card.translatesAutoresizingMaskIntoConstraints = NO;
        card.transform = CGAffineTransformMakeScale(1.05, 1.05);
        [overlay addSubview:card];
        
        UIView *iconContainer = [[UIView alloc] init];
        iconContainer.backgroundColor = [[ZXTheme statusError] colorWithAlphaComponent:0.1];
        iconContainer.layer.cornerRadius = 24;
        iconContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [card addSubview:iconContainer];
        
        UIImageView *iconView = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"exclamationmark.triangle.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        iconView.tintColor = [ZXTheme statusError];
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        iconView.translatesAutoresizingMaskIntoConstraints = NO;
        [iconContainer addSubview:iconView];
        
        UILabel *titleLbl = [[UILabel alloc] init];
        titleLbl.text = [title uppercaseString];
        titleLbl.textColor = [ZXTheme textPrimary];
        titleLbl.font = [ZXTheme fontHeading:16];
        [ZXTheme applyTextTracking:titleLbl spacing:1.0];
        titleLbl.textAlignment = NSTextAlignmentCenter;
        titleLbl.translatesAutoresizingMaskIntoConstraints = NO;
        [card addSubview:titleLbl];
        
        UILabel *msgLbl = [[UILabel alloc] init];
        msgLbl.text = msg;
        msgLbl.textColor = [ZXTheme textSecondary];
        msgLbl.font = [ZXTheme fontBody:13 weight:UIFontWeightRegular];
        msgLbl.textAlignment = NSTextAlignmentCenter;
        msgLbl.numberOfLines = 0;
        msgLbl.translatesAutoresizingMaskIntoConstraints = NO;
        [card addSubview:msgLbl];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:@"DISMISS" forState:UIControlStateNormal];
        btn.titleLabel.font = [ZXTheme fontHeading:14];
        btn.layer.cornerRadius = 10;
        btn.backgroundColor = [[ZXTheme statusError] colorWithAlphaComponent:0.15];
        [btn setTitleColor:[ZXTheme statusError] forState:UIControlStateNormal];
        btn.layer.borderWidth = 1.0;
        btn.layer.borderColor = [ZXTheme statusError].CGColor;
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        [card addSubview:btn];
        
        [NSLayoutConstraint activateConstraints:@[
            [card.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
            [card.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
            [card.widthAnchor constraintEqualToConstant:300],
            
            [iconContainer.topAnchor constraintEqualToAnchor:card.topAnchor constant:24],
            [iconContainer.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
            [iconContainer.widthAnchor constraintEqualToConstant:48],
            [iconContainer.heightAnchor constraintEqualToConstant:48],
            
            [iconView.centerXAnchor constraintEqualToAnchor:iconContainer.centerXAnchor],
            [iconView.centerYAnchor constraintEqualToAnchor:iconContainer.centerYAnchor],
            [iconView.widthAnchor constraintEqualToConstant:22],
            [iconView.heightAnchor constraintEqualToConstant:22],
            
            [titleLbl.topAnchor constraintEqualToAnchor:iconContainer.bottomAnchor constant:16],
            [titleLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
            [titleLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
            
            [msgLbl.topAnchor constraintEqualToAnchor:titleLbl.bottomAnchor constant:8],
            [msgLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
            [msgLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
            
            [btn.topAnchor constraintEqualToAnchor:msgLbl.bottomAnchor constant:24],
            [btn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
            [btn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
            [btn.heightAnchor constraintEqualToConstant:44],
            [btn.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-24]
        ]];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissErrorModal:)];
        [btn addTarget:self action:@selector(dismissErrorBtnTapped:) forControlEvents:UIControlEventTouchUpInside];
        [overlay addGestureRecognizer:tap];
        
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred];
        
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            overlay.alpha = 1.0;
            card.transform = CGAffineTransformIdentity;
        } completion:nil];
    });
}

+ (void)dismissErrorModal:(UITapGestureRecognizer *)sender {
    if (sender.view.tag == 100100) [self animateErrorDismiss:sender.view];
}
+ (void)dismissErrorBtnTapped:(UIButton *)btn {
    [self animateErrorDismiss:btn.superview.superview];
}
+ (void)animateErrorDismiss:(UIView *)overlay {
    [UIView animateWithDuration:0.25 animations:^{
        overlay.alpha = 0;
        overlay.subviews.lastObject.transform = CGAffineTransformMakeScale(0.95, 0.95);
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
// Startup State Synchronizers
@property (nonatomic, assign) BOOL hasCompletedInitialPresentation;
@property (nonatomic, assign) BOOL isSplashAnimationDone;
@property (nonatomic, assign) BOOL isApiVerificationDone;
@property (nonatomic, assign) BOOL apiVerificationResult;

@property (nonatomic, assign) ZXAppState currentState;

// Background
@property (nonatomic, strong) ZXAnimatedAtmosphere *animatedBackground;

// Flow Containers
@property (nonatomic, strong) UIView *splashContainer;
@property (nonatomic, strong) UIView *authContainer;
@property (nonatomic, strong) UIView *dashboardContainer;

// Splash elements
@property (nonatomic, strong) UIImageView *splashIcon;
@property (nonatomic, strong) UILabel *splashStatusLabel;
@property (nonatomic, strong) UILabel *splashPercentageLabel;
@property (nonatomic, strong) UIView *splashProgressTrack;
@property (nonatomic, strong) UIView *splashProgressFill;

// Auth elements
@property (nonatomic, strong) ZXTextField *keyInput;
@property (nonatomic, strong) ZXButton *loginBtn;
@property (nonatomic, strong) UITapGestureRecognizer *dismissTap;

// Dashboard elements
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *expiryLabel;
@property (nonatomic, strong) UILabel *keyRevealLabel;
@property (nonatomic, strong) UIButton *keyEyeButton;
@property (nonatomic, assign) BOOL isKeyRevealed;

@property (nonatomic, strong) UIScrollView *modulesScrollView;
@property (nonatomic, strong) UIStackView *modulesStackView; 
@property (nonatomic, strong) UIView *emptyStateView;

// State Management
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
    
    _animatedBackground = [[ZXAnimatedAtmosphere alloc] initWithFrame:self.view.bounds];
    _animatedBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_animatedBackground];
    
    [self setupSplash];
    [self setupAuth];
    [self setupDashboard];
    
    // Strict Startup Alphas to eliminate Black Screen
    [self.view bringSubviewToFront:self.splashContainer];
    self.splashContainer.alpha = 1.0;
    self.authContainer.alpha = 0.0;
    self.dashboardContainer.alpha = 0.0;
    self.currentState = ZXAppStateSplash;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self.animatedBackground startAtmosphere];
    
    if (!self.hasCompletedInitialPresentation) {
        self.hasCompletedInitialPresentation = YES;
        [self runStrictStartupSequence];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.animatedBackground stopAtmosphere];
    [self stopHeartbeatMonitor];
}

- (void)dismissKeyboard { [self.view endEditing:YES]; }

#pragma mark - Keyboard
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

#pragma mark - Safe State Transitions
- (void)transitionToState:(ZXAppState)newState completion:(void(^)(void))completionBlock {
    if (self.currentState == newState) {
        if (completionBlock) completionBlock();
        return;
    }
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
        self.dashboardContainer.alpha = (newState == ZXAppStateDashboard) ? 1.0 : 0.0;
    } completion:^(BOOL finished) {
        if (completionBlock) completionBlock();
    }];
}

#pragma mark - Heartbeat Security
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
        __weak typeof(self) weakSelf = self;
        [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL isValid) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                
                if (!isValid) {
                    BOOL sessionRemainsActive = YES;
                    Class nmClass = NSClassFromString(@"ZentraxNetworkManager");
                    if (nmClass) {
                        id sharedInst = [nmClass performSelector:NSSelectorFromString(@"sharedManager")];
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

- (void)handleRevokedSessionEnvironment {
    [self stopHeartbeatMonitor];
    for (UIView *card in self.modulesStackView.arrangedSubviews) {
        ZXToggle *toggle = [self findToggleInCard:card];
        if (toggle) {
            toggle.userInteractionEnabled = NO;
            [toggle setOn:NO animated:YES];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Zentrax_LastKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [ZXPremiumToast showError:@"ACCESS REVOKED" message:@"Your license has been disabled or expired by the administrator." inView:self.view];
    
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        if ([strongSelf.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) {
            [strongSelf.delegate zentraxDidRequestLogoutWithCompletion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    strongSelf.keyInput.textField.text = @"";
                    [strongSelf transitionToState:ZXAppStateAuth completion:nil];
                });
            }];
        } else {
            [strongSelf transitionToState:ZXAppStateAuth completion:nil];
        }
    });
}

#pragma mark - Premium Splash & Startup Synchronization
- (void)setupSplash {
    _splashContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    _splashContainer.layer.zPosition = 500; // Always top until removed
    [self.view addSubview:_splashContainer];
    
    UIView *iconBg = [[UIView alloc] init];
    iconBg.backgroundColor = [[ZXTheme accentSecondary] colorWithAlphaComponent:0.1];
    iconBg.layer.cornerRadius = 35;
    iconBg.layer.shadowColor = [ZXTheme accentSecondary].CGColor;
    iconBg.layer.shadowRadius = 15;
    iconBg.layer.shadowOpacity = 0.5;
    iconBg.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:iconBg];
    
    _splashIcon = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"shield.lefthalf.filled"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    _splashIcon.tintColor = [ZXTheme accentSecondary];
    _splashIcon.contentMode = UIViewContentModeScaleAspectFit;
    _splashIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [iconBg addSubview:_splashIcon];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"ZENTRAX VIP";
    title.textColor = [UIColor whiteColor];
    title.font = [ZXTheme fontDisplay:24];
    [ZXTheme applyTextTracking:title spacing:4.0];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:title];
    
    // Custom Luminous Rail Progress
    _splashProgressTrack = [[UIView alloc] init];
    _splashProgressTrack.backgroundColor = [ZXTheme borderSubtle];
    _splashProgressTrack.layer.cornerRadius = 2;
    _splashProgressTrack.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_splashProgressTrack];
    
    _splashProgressFill = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 4)];
    _splashProgressFill.layer.cornerRadius = 2;
    CAGradientLayer *railGrad = [CAGradientLayer layer];
    railGrad.colors = @[(id)[ZXTheme accentPrimary].CGColor, (id)[ZXTheme accentSecondary].CGColor];
    railGrad.startPoint = CGPointMake(0, 0);
    railGrad.endPoint = CGPointMake(1, 0);
    railGrad.frame = CGRectMake(0, 0, self.view.bounds.size.width - 120, 4);
    [_splashProgressFill.layer addSublayer:railGrad];
    _splashProgressFill.clipsToBounds = YES;
    _splashProgressFill.layer.shadowColor = [ZXTheme accentSecondary].CGColor;
    _splashProgressFill.layer.shadowRadius = 8;
    _splashProgressFill.layer.shadowOpacity = 0.8;
    [_splashProgressTrack addSubview:_splashProgressFill];
    
    _splashStatusLabel = [[UILabel alloc] init];
    _splashStatusLabel.text = @"INITIALIZING...";
    _splashStatusLabel.textColor = [ZXTheme textMuted];
    _splashStatusLabel.font = [ZXTheme fontMono:10 weight:UIFontWeightBold];
    [ZXTheme applyTextTracking:_splashStatusLabel spacing:1.5];
    _splashStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_splashStatusLabel];
    
    _splashPercentageLabel = [[UILabel alloc] init];
    _splashPercentageLabel.text = @"0%";
    _splashPercentageLabel.textColor = [ZXTheme textSecondary];
    _splashPercentageLabel.font = [ZXTheme fontMono:10 weight:UIFontWeightBold];
    _splashPercentageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_splashPercentageLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [iconBg.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [iconBg.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor constant:-60],
        [iconBg.widthAnchor constraintEqualToConstant:70],
        [iconBg.heightAnchor constraintEqualToConstant:70],
        
        [_splashIcon.centerXAnchor constraintEqualToAnchor:iconBg.centerXAnchor],
        [_splashIcon.centerYAnchor constraintEqualToAnchor:iconBg.centerYAnchor],
        [_splashIcon.widthAnchor constraintEqualToConstant:30],
        [_splashIcon.heightAnchor constraintEqualToConstant:35],
        
        [title.topAnchor constraintEqualToAnchor:iconBg.bottomAnchor constant:24],
        [title.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        
        [_splashProgressTrack.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:40],
        [_splashProgressTrack.leadingAnchor constraintEqualToAnchor:_splashContainer.leadingAnchor constant:60],
        [_splashProgressTrack.trailingAnchor constraintEqualToAnchor:_splashContainer.trailingAnchor constant:-60],
        [_splashProgressTrack.heightAnchor constraintEqualToConstant:4],
        
        [_splashStatusLabel.topAnchor constraintEqualToAnchor:_splashProgressTrack.bottomAnchor constant:12],
        [_splashStatusLabel.leadingAnchor constraintEqualToAnchor:_splashProgressTrack.leadingAnchor],
        
        [_splashPercentageLabel.topAnchor constraintEqualToAnchor:_splashProgressTrack.bottomAnchor constant:12],
        [_splashPercentageLabel.trailingAnchor constraintEqualToAnchor:_splashProgressTrack.trailingAnchor]
    ]];
}

- (void)updateSplashTextSmoothly:(NSString *)newText percentage:(NSString *)pct {
    CATransition *animation = [CATransition animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = kCATransitionFade;
    animation.duration = 0.3;
    [self.splashStatusLabel.layer addAnimation:animation forKey:@"fade"];
    [self.splashPercentageLabel.layer addAnimation:animation forKey:@"fade"];
    self.splashStatusLabel.text = newText;
    self.splashPercentageLabel.text = pct;
}

// STRICT STARTUP SEQUENCE to prevent overlapping errors
- (void)runStrictStartupSequence {
    self.isSplashAnimationDone = NO;
    self.isApiVerificationDone = NO;
    self.apiVerificationResult = NO;
    
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.toValue = @1.05;
    pulse.duration = 1.0;
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    [self.splashIcon.layer addAnimation:pulse forKey:@"pulse"];
    
    CGFloat fullWidth = self.view.bounds.size.width - 120;
    
    // Controlled Progress Animation (Ensures splash is visible for at least 1.6s)
    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.splashProgressFill.frame = CGRectMake(0, 0, fullWidth * 0.25, 4);
    } completion:^(BOOL finished) {
        [self updateSplashTextSmoothly:@"VERIFYING PROTOCOLS" percentage:@"25%"];
        
        [UIView animateWithDuration:0.5 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.splashProgressFill.frame = CGRectMake(0, 0, fullWidth * 0.60, 4);
        } completion:^(BOOL finished) {
            [self updateSplashTextSmoothly:@"SYNCHRONIZING SECURE NODE" percentage:@"60%"];
            
            [UIView animateWithDuration:0.5 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.splashProgressFill.frame = CGRectMake(0, 0, fullWidth * 0.95, 4);
            } completion:^(BOOL finished) {
                
                // Animation almost complete. Wait for API.
                self.isSplashAnimationDone = YES;
                [self evaluateStartupState];
            }];
        }];
    }];
    
    // Parallel API call
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) {
        __weak typeof(self) weakSelf = self;
        [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL isValid) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                strongSelf.isApiVerificationDone = YES;
                strongSelf.apiVerificationResult = isValid;
                [strongSelf evaluateStartupState];
            });
        }];
    } else {
        self.isApiVerificationDone = YES;
        self.apiVerificationResult = NO;
        [self evaluateStartupState];
    }
}

// Safely evaluate if both animation and API have finished before transitioning
- (void)evaluateStartupState {
    if (!self.isSplashAnimationDone || !self.isApiVerificationDone) return;
    
    // Both done. Complete the progress bar.
    CGFloat fullWidth = self.view.bounds.size.width - 120;
    [self updateSplashTextSmoothly:@"SYSTEM READY" percentage:@"100%"];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.splashProgressFill.frame = CGRectMake(0, 0, fullWidth, 4);
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self.splashIcon.layer removeAllAnimations];
            
            if (self.apiVerificationResult) {
                [self populateDashboardKey];
                // Smoothly Transition -> THEN show elegant compact verification toast
                [self transitionToState:ZXAppStateDashboard completion:^{
                    [self showCompactVerificationSuccess];
                }];
            } else {
                [self transitionToState:ZXAppStateAuth completion:nil];
            }
        });
    }];
}

// Premium integrated verification success (Not a huge popup)
- (void)showCompactVerificationSuccess {
    [ZXPremiumToast showSuccess:@"NODE VERIFIED" inView:self.view];
}

// Full Green Tick Center Screen Popup (Used ONLY for Manual Login Authentication)
- (void)showLoginSuccessCardWithCompletion:(void(^)(void))completion {
    UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    overlay.alpha = 0;
    overlay.layer.zPosition = 9999;
    [self.view addSubview:overlay];
    
    UIView *card = [[UIView alloc] init];
    [ZXTheme applyPremiumGlassmorphismToView:card cornerRadius:20];
    card.layer.borderColor = [ZXTheme statusSuccess].CGColor;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [overlay addSubview:card];
    
    card.layer.shadowColor = [ZXTheme statusSuccess].CGColor;
    card.layer.shadowOpacity = 0.3;
    card.layer.shadowRadius = 30;
    card.layer.shadowOffset = CGSizeMake(0, 10);
    
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"checkmark.circle.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    iconView.tintColor = [ZXTheme statusSuccess];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:iconView];
    
    UILabel *titleLbl = [[UILabel alloc] init];
    titleLbl.text = @"NODE ACTIVATED";
    titleLbl.textColor = [UIColor whiteColor];
    titleLbl.font = [ZXTheme fontDisplay:16];
    [ZXTheme applyTextTracking:titleLbl spacing:1.5];
    titleLbl.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:titleLbl];
    
    [NSLayoutConstraint activateConstraints:@[
        [card.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor constant:-20],
        [card.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [card.widthAnchor constraintEqualToConstant:220],
        [card.heightAnchor constraintEqualToConstant:160],
        
        [iconView.centerYAnchor constraintEqualToAnchor:card.centerYAnchor constant:-16],
        [iconView.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [iconView.widthAnchor constraintEqualToConstant:45],
        [iconView.heightAnchor constraintEqualToConstant:45],
        
        [titleLbl.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:16],
        [titleLbl.centerXAnchor constraintEqualToAnchor:card.centerXAnchor]
    ]];
    
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred];
    
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        overlay.alpha = 1.0;
        card.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                overlay.alpha = 0;
                card.transform = CGAffineTransformMakeScale(0.9, 0.9);
            } completion:^(BOOL finished) {
                [overlay removeFromSuperview];
                if (completion) completion();
            }];
        });
    }];
}

#pragma mark - Premium Auth Flow
- (void)setupAuth {
    _authContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_authContainer];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"ZENTRAX";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont systemFontOfSize:42 weight:UIFontWeightBlack];
    title.textAlignment = NSTextAlignmentCenter;
    [ZXTheme applyTextTracking:title spacing:2.0];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    
    title.layer.shadowColor = [ZXTheme accentSecondary].CGColor;
    title.layer.shadowRadius = 15.0;
    title.layer.shadowOpacity = 0.5;
    title.layer.shadowOffset = CGSizeZero;
    [_authContainer addSubview:title];
    
    UILabel *desc = [[UILabel alloc] init];
    desc.text = @"Enter your master key to authenticate and unlock execution features.";
    desc.textColor = [ZXTheme textSecondary];
    desc.font = [ZXTheme fontBody:14 weight:UIFontWeightRegular];
    desc.textAlignment = NSTextAlignmentCenter;
    desc.numberOfLines = 0;
    desc.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:desc];
    
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor clearColor];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:card];
    
    _keyInput = [[ZXTextField alloc] init];
    _keyInput.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_keyInput];
    
    _loginBtn = [[ZXPremiumButton alloc] init];
    [_loginBtn setTitle:@"AUTHENTICATE NODE" forState:UIControlStateNormal];
    [_loginBtn addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside];
    _loginBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_loginBtn];
    
    [NSLayoutConstraint activateConstraints:@[
        [title.topAnchor constraintEqualToAnchor:_authContainer.safeAreaLayoutGuide.topAnchor constant:80],
        [title.centerXAnchor constraintEqualToAnchor:_authContainer.centerXAnchor],
        
        [desc.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:12],
        [desc.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:40],
        [desc.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-40],
        
        [card.topAnchor constraintEqualToAnchor:desc.bottomAnchor constant:40],
        [card.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:24],
        [card.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-24],
        [card.heightAnchor constraintEqualToConstant:160],
        
        [_keyInput.topAnchor constraintEqualToAnchor:card.topAnchor],
        [_keyInput.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [_keyInput.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [_keyInput.heightAnchor constraintEqualToConstant:70],
        
        [_loginBtn.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],
        [_loginBtn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [_loginBtn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [_loginBtn.heightAnchor constraintEqualToConstant:54],
    ]];
}

- (void)handleLogin {
    [self dismissKeyboard];
    NSString *key = [self.keyInput.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (key.length == 0) {
        [ZXPremiumToast showError:@"INVALID INPUT" message:@"License key cannot be empty." inView:self.view];
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
                    [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"Zentrax_LastKey"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    [strongSelf populateDashboardKey];
                    
                    // Show Full Card over Auth Screen, then transition
                    [strongSelf showLoginSuccessCardWithCompletion:^{
                        [strongSelf transitionToState:ZXAppStateDashboard completion:nil];
                    }];
                } else {
                    [ZXModalManager showModalWithIcon:@"xmark.octagon.fill" isError:YES title:@"ACCESS DENIED" message:errorMsg ?: @"Key rejected by server node." actionTitle:@"DISMISS" inView:strongSelf.view];
                }
            });
        }];
    }
}

#pragma mark - Premium Security Dashboard
- (void)setupDashboard {
    _dashboardContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_dashboardContainer];
    
    UIView *navBar = [[UIView alloc] init];
    navBar.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:navBar];
    
    UIImageView *navIcon = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"shield.lefthalf.filled"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    navIcon.tintColor = [ZXTheme accentSecondary];
    navIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [navBar addSubview:navIcon];
    
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.text = @"ZENTRAX VIP";
    navTitle.textColor = [UIColor whiteColor];
    navTitle.font = [ZXTheme fontHeading:16];
    [ZXTheme applyTextTracking:navTitle spacing:1.5];
    navTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [navBar addSubview:navTitle];
    
    UIButton *logoutBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [logoutBtn setImage:[[UIImage systemImageNamed:@"power"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    logoutBtn.tintColor = [ZXTheme textMuted];
    logoutBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [logoutBtn addTarget:self action:@selector(handleLogout) forControlEvents:UIControlEventTouchUpInside];
    [navBar addSubview:logoutBtn];
    
    // Status Card (High-End Security Layout)
    UIView *statusCard = [[UIView alloc] init];
    [ZXTheme applyPremiumGlassmorphismToView:statusCard cornerRadius:18];
    statusCard.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:statusCard];
    
    // Top Half: Status & Validity
    UILabel *subTitle = [[UILabel alloc] init];
    subTitle.text = @"SECURITY NODE STATUS";
    subTitle.textColor = [ZXTheme textMuted];
    subTitle.font = [ZXTheme fontMono:10 weight:UIFontWeightBold];
    [ZXTheme applyTextTracking:subTitle spacing:1.0];
    subTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:subTitle];
    
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.text = @"ACTIVE";
    _statusLabel.textColor = [ZXTheme statusSuccess];
    _statusLabel.font = [ZXTheme fontDisplay:20];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_statusLabel];
    
    UILabel *expSubTitle = [[UILabel alloc] init];
    expSubTitle.text = @"VALIDITY";
    expSubTitle.textColor = [ZXTheme textMuted];
    expSubTitle.font = [ZXTheme fontMono:10 weight:UIFontWeightBold];
    [ZXTheme applyTextTracking:expSubTitle spacing:1.0];
    expSubTitle.textAlignment = NSTextAlignmentRight;
    expSubTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:expSubTitle];
    
    _expiryLabel = [[UILabel alloc] init];
    _expiryLabel.text = @"Syncing...";
    _expiryLabel.textColor = [UIColor whiteColor];
    _expiryLabel.font = [ZXTheme fontHeading:14];
    _expiryLabel.textAlignment = NSTextAlignmentRight;
    _expiryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_expiryLabel];
    
    // Bottom Half: Master Key Hidden Container
    UIView *keyBox = [[UIView alloc] init];
    keyBox.backgroundColor = [ZXTheme bgCardInner];
    keyBox.layer.cornerRadius = 10;
    keyBox.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:keyBox];
    
    UIImageView *keyIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"key.fill"]];
    keyIcon.tintColor = [ZXTheme textMuted];
    keyIcon.contentMode = UIViewContentModeScaleAspectFit;
    keyIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [keyBox addSubview:keyIcon];
    
    _keyRevealLabel = [[UILabel alloc] init];
    _keyRevealLabel.text = @"••••••••••••";
    _keyRevealLabel.textColor = [ZXTheme textPrimary];
    _keyRevealLabel.font = [ZXTheme fontMono:12 weight:UIFontWeightBold];
    _keyRevealLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [keyBox addSubview:_keyRevealLabel];
    
    _keyEyeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_keyEyeButton setImage:[UIImage systemImageNamed:@"eye.slash.fill"] forState:UIControlStateNormal];
    _keyEyeButton.tintColor = [ZXTheme textMuted];
    _keyEyeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_keyEyeButton addTarget:self action:@selector(toggleDashboardKey) forControlEvents:UIControlEventTouchUpInside];
    [keyBox addSubview:_keyEyeButton];
    
    [self populateDashboardKey];
    
    // Scroll Area for Modules
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
        [navIcon.widthAnchor constraintEqualToConstant:20],
        [navIcon.heightAnchor constraintEqualToConstant:24],
        
        [navTitle.leadingAnchor constraintEqualToAnchor:navIcon.trailingAnchor constant:12],
        [navTitle.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],
        
        [logoutBtn.trailingAnchor constraintEqualToAnchor:navBar.trailingAnchor],
        [logoutBtn.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],
        [logoutBtn.widthAnchor constraintEqualToConstant:32],
        [logoutBtn.heightAnchor constraintEqualToConstant:32],
        
        [statusCard.topAnchor constraintEqualToAnchor:navBar.bottomAnchor constant:20],
        [statusCard.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:20],
        [statusCard.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-20],
        [statusCard.heightAnchor constraintEqualToConstant:130],
        
        [subTitle.topAnchor constraintEqualToAnchor:statusCard.topAnchor constant:18],
        [subTitle.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:20],
        
        [_statusLabel.topAnchor constraintEqualToAnchor:subTitle.bottomAnchor constant:4],
        [_statusLabel.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:20],
        
        [expSubTitle.topAnchor constraintEqualToAnchor:statusCard.topAnchor constant:18],
        [expSubTitle.trailingAnchor constraintEqualToAnchor:statusCard.trailingAnchor constant:-20],
        
        [_expiryLabel.centerYAnchor constraintEqualToAnchor:_statusLabel.centerYAnchor],
        [_expiryLabel.trailingAnchor constraintEqualToAnchor:statusCard.trailingAnchor constant:-20],
        
        [keyBox.bottomAnchor constraintEqualToAnchor:statusCard.bottomAnchor constant:-16],
        [keyBox.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:16],
        [keyBox.trailingAnchor constraintEqualToAnchor:statusCard.trailingAnchor constant:-16],
        [keyBox.heightAnchor constraintEqualToConstant:44],
        
        [keyIcon.leadingAnchor constraintEqualToAnchor:keyBox.leadingAnchor constant:12],
        [keyIcon.centerYAnchor constraintEqualToAnchor:keyBox.centerYAnchor],
        [keyIcon.widthAnchor constraintEqualToConstant:16],
        [keyIcon.heightAnchor constraintEqualToConstant:16],
        
        [_keyRevealLabel.leadingAnchor constraintEqualToAnchor:keyIcon.trailingAnchor constant:10],
        [_keyRevealLabel.centerYAnchor constraintEqualToAnchor:keyBox.centerYAnchor],
        
        [_keyEyeButton.trailingAnchor constraintEqualToAnchor:keyBox.trailingAnchor constant:-6],
        [_keyEyeButton.centerYAnchor constraintEqualToAnchor:keyBox.centerYAnchor],
        [_keyEyeButton.widthAnchor constraintEqualToConstant:32],
        [_keyEyeButton.heightAnchor constraintEqualToConstant:32],
        
        [_modulesScrollView.topAnchor constraintEqualToAnchor:statusCard.bottomAnchor constant:20],
        [_modulesScrollView.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor],
        [_modulesScrollView.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor],
        [_modulesScrollView.bottomAnchor constraintEqualToAnchor:_dashboardContainer.bottomAnchor],
        
        [_modulesStackView.topAnchor constraintEqualToAnchor:_modulesScrollView.contentLayoutGuide.topAnchor constant:10],
        [_modulesStackView.leadingAnchor constraintEqualToAnchor:_modulesScrollView.frameLayoutGuide.leadingAnchor constant:20],
        [_modulesStackView.trailingAnchor constraintEqualToAnchor:_modulesScrollView.frameLayoutGuide.trailingAnchor constant:-20],
        [_modulesStackView.bottomAnchor constraintEqualToAnchor:_modulesScrollView.contentLayoutGuide.bottomAnchor constant:-40]
    ]];
}

- (void)populateDashboardKey {
    self.isKeyRevealed = NO;
    [self updateDashboardKeyDisplay];
}

- (void)toggleDashboardKey {
    self.isKeyRevealed = !self.isKeyRevealed;
    [self updateDashboardKeyDisplay];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
}

- (void)updateDashboardKeyDisplay {
    NSString *key = [[NSUserDefaults standardUserDefaults] stringForKey:@"Zentrax_LastKey"];
    if (!key || key.length == 0) key = @"NO-KEY-FOUND";
    
    if (self.isKeyRevealed) {
        self.keyRevealLabel.text = key;
        [self.keyEyeButton setImage:[UIImage systemImageNamed:@"eye.fill"] forState:UIControlStateNormal];
        self.keyEyeButton.tintColor = [ZXTheme accentSecondary];
    } else {
        if (key.length > 4) {
            NSString *last4 = [key substringFromIndex:key.length - 4];
            self.keyRevealLabel.text = [NSString stringWithFormat:@"••••••••%@", last4];
        } else {
            self.keyRevealLabel.text = @"••••••••••••";
        }
        [self.keyEyeButton setImage:[UIImage systemImageNamed:@"eye.slash.fill"] forState:UIControlStateNormal];
        self.keyEyeButton.tintColor = [ZXTheme textMuted];
    }
}

- (void)createEmptyStateView {
    _emptyStateView = [[UIView alloc] init];
    _emptyStateView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIImageView *icon = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"cube.transparent"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    icon.tintColor = [ZXTheme textMuted];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyStateView addSubview:icon];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"No Active Modules";
    title.textColor = [UIColor whiteColor];
    title.font = [ZXTheme fontHeading:16];
    title.textAlignment = NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyStateView addSubview:title];
    
    [NSLayoutConstraint activateConstraints:@[
        [_emptyStateView.heightAnchor constraintEqualToConstant:180],
        [icon.centerXAnchor constraintEqualToAnchor:_emptyStateView.centerXAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:_emptyStateView.centerYAnchor constant:-20],
        [icon.widthAnchor constraintEqualToConstant:32],
        [icon.heightAnchor constraintEqualToConstant:32],
        [title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:16],
        [title.centerXAnchor constraintEqualToAnchor:_emptyStateView.centerXAnchor]
    ]];
}

- (BOOL)isModuleDataIdentical:(NSArray *)newModules {
    if (!self.cachedModulesState || newModules.count != self.cachedModulesState.count) return NO;
    for (int i = 0; i < newModules.count; i++) {
        if (![newModules[i] isEqualToDictionary:self.cachedModulesState[i]]) {
            return NO;
        }
    }
    return YES;
}

- (void)updateDashboardWithModules:(NSArray<NSDictionary *> *)modules {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isModuleDataIdentical:modules]) return; 
        
        self.cachedModulesState = modules;
        
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
        sectionHeader.text = @"EXECUTION MODULES";
        sectionHeader.textColor = [ZXTheme textMuted];
        sectionHeader.font = [ZXTheme fontMono:11 weight:UIFontWeightBold];
        [ZXTheme applyTextTracking:sectionHeader spacing:1.5];
        [self.modulesStackView addArrangedSubview:sectionHeader];
        [self.modulesStackView setCustomSpacing:12 afterView:sectionHeader];
        
        for (NSDictionary *mod in modules) {
            NSString *moduleName = mod[@"name"] ?: @"UNKNOWN";
            NSString *moduleDesc = mod[@"desc"] ?: mod[@"description"] ?: @"";
            NSString *currentState = mod[@"current_state"] ?: @"OFF"; 
            BOOL isModOn = [currentState isEqualToString:@"ON"];
            
            UIView *card = [[UIView alloc] init];
            [ZXTheme applyPremiumGlassmorphismToView:card cornerRadius:14];
            card.translatesAutoresizingMaskIntoConstraints = NO;
            
            UILabel *t = [[UILabel alloc] init];
            t.text = moduleName;
            t.textColor = [UIColor whiteColor];
            t.font = [ZXTheme fontHeading:15];
            t.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:t];
            
            ZXToggle *toggle = [[ZXToggle alloc] init];
            toggle.moduleId = moduleName; 
            [toggle setOn:isModOn animated:NO]; 
            [toggle addTarget:self action:@selector(moduleToggled:) forControlEvents:UIControlEventValueChanged];
            [card addSubview:toggle];
            
            // Subtle Inset Box for Description (Very Premium)
            UIView *descBox = [[UIView alloc] init];
            descBox.backgroundColor = [ZXTheme bgCardInner];
            descBox.layer.cornerRadius = 8;
            descBox.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:descBox];
            
            UILabel *s = [[UILabel alloc] init];
            s.text = moduleDesc;
            s.textColor = [ZXTheme textSecondary];
            s.font = [ZXTheme fontBody:12 weight:UIFontWeightRegular];
            s.numberOfLines = 0;
            s.translatesAutoresizingMaskIntoConstraints = NO;
            [descBox addSubview:s];
            
            [toggle setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            
            [NSLayoutConstraint activateConstraints:@[
                [toggle.centerYAnchor constraintEqualToAnchor:card.topAnchor constant:28],
                [toggle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
                
                [t.centerYAnchor constraintEqualToAnchor:toggle.centerYAnchor],
                [t.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
                [t.trailingAnchor constraintLessThanOrEqualToAnchor:toggle.leadingAnchor constant:-12],
                
                [descBox.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:12],
                [descBox.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
                [descBox.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
                [descBox.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16],
                
                [s.topAnchor constraintEqualToAnchor:descBox.topAnchor constant:10],
                [s.leadingAnchor constraintEqualToAnchor:descBox.leadingAnchor constant:12],
                [s.trailingAnchor constraintEqualToAnchor:descBox.trailingAnchor constant:-12],
                [s.bottomAnchor constraintEqualToAnchor:descBox.bottomAnchor constant:-10]
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
            self.expiryLabel.text = @"LIFETIME ACCESS";
        } else if (expiryStr) {
            self.expiryLabel.text = [expiryStr uppercaseString];
        } else {
            self.expiryLabel.text = @"--";
        }
        
        NSString *s = subData[@"status"] ?: @"Active";
        self.statusLabel.text = [s uppercaseString];
        if ([s.lowercaseString isEqualToString:@"active"]) {
            self.statusLabel.textColor = [ZXTheme statusSuccess];
        } else {
            self.statusLabel.textColor = [ZXTheme statusWarning];
        }
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
                    [ZXPremiumToast showSuccess:toastMsg inView:strongSelf.view];
                    strongSelf.cachedModulesState = nil;
                } else {
                    [sender setOn:!requestedState animated:YES];
                    [ZXModalManager showModalWithIcon:@"xmark.octagon.fill" isError:YES title:@"INJECTION FAILED" message:errorMsg ?: @"Failed to inject payload." actionTitle:@"DISMISS" inView:strongSelf.view];
                }
            });
        }];
    }
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
                        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Zentrax_LastKey"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        [strongSelf transitionToState:ZXAppStateAuth completion:nil];
                    }
                });
            }];
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showGlobalErrorWithTitle:(NSString *)title message:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        [ZXModalManager showModalWithIcon:@"exclamationmark.triangle.fill" isError:YES title:title message:msg actionTitle:@"Dismiss" inView:self.view];
    });
}
- (void)showSuccessMessage:(NSString *)title message:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        [ZXModalManager showModalWithIcon:@"checkmark.shield.fill" isError:NO title:title message:msg actionTitle:@"Continue" inView:self.view];
    });
}
- (void)showNetworkError { [ZXPremiumToast showError:@"CONNECTION FAILED" message:@"Network connection lost." inView:self.view]; }
- (void)showServerError { [ZXPremiumToast showError:@"SERVER ERROR" message:@"Node server is unavailable." inView:self.view]; }
- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds {
    NSString *msg = [NSString stringWithFormat:@"Request limits reached. Cooldown active for %ld seconds.", (long)seconds];
    dispatch_async(dispatch_get_main_queue(), ^{
        [ZXModalManager showModalWithIcon:@"timer" isError:YES title:@"Rate Limited" message:msg actionTitle:@"Understood" inView:self.view];
    });
}
- (void)showGlobalLoadingState:(NSString *)message {}
- (void)hideGlobalLoadingState {}

@end