//
//  ZentraxUI.m
//  Zentrax VIP - Premium Execution Node UI
//
//  Created by Zentrax Team.
//  Architecture: Ultra-Premium VIP Gaming Layer (V5 Final)
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
+ (UIColor *)accentPurple;
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

+ (void)applyTextTracking:(UILabel *)label spacing:(CGFloat)spacing;
+ (CAGradientLayer *)primaryGradient;
@end

@implementation ZXTheme

// True deep aesthetic
+ (UIColor *)bgDeepSpace { return [UIColor colorWithRed:0.03 green:0.03 blue:0.05 alpha:1.0]; }
+ (UIColor *)bgCardOuter { return [UIColor colorWithRed:0.08 green:0.09 blue:0.12 alpha:0.85]; }
+ (UIColor *)bgCardInner { return [UIColor colorWithRed:0.05 green:0.06 blue:0.08 alpha:0.90]; }
+ (UIColor *)borderSubtle { return [UIColor colorWithRed:0.15 green:0.18 blue:0.25 alpha:0.8]; }

// Neon Accents
+ (UIColor *)accentPurple { return [UIColor colorWithRed:0.55 green:0.20 blue:1.0 alpha:1.0]; }
+ (UIColor *)accentCyan { return [UIColor colorWithRed:0.0 green:0.90 blue:1.0 alpha:1.0]; }

// Text Hierarchy
+ (UIColor *)textPrimary { return [UIColor colorWithWhite:1.0 alpha:1.0]; }
+ (UIColor *)textSecondary { return [UIColor colorWithWhite:0.75 alpha:1.0]; }
+ (UIColor *)textMuted { return [UIColor colorWithWhite:0.50 alpha:1.0]; }

// Status
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

+ (CAGradientLayer *)primaryGradient {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[(id)[self accentPurple].CGColor, (id)[self accentCyan].CGColor];
    gradient.startPoint = CGPointMake(0.0, 0.5);
    gradient.endPoint = CGPointMake(1.0, 0.5);
    return gradient;
}

@end

#pragma mark - ================= LIVE ANIMATED BACKGROUND =================

@interface ZXAnimatedBackground : UIView
@property (nonatomic, strong) UIView *orb1;
@property (nonatomic, strong) UIView *orb2;
- (void)startAnimations;
- (void)stopAnimations;
@end

@implementation ZXAnimatedBackground
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [ZXTheme bgDeepSpace];
        self.clipsToBounds = YES;
        
        // Purple Orb
        _orb1 = [[UIView alloc] initWithFrame:CGRectMake(-100, -100, 400, 400)];
        _orb1.backgroundColor = [[ZXTheme accentPurple] colorWithAlphaComponent:0.15];
        _orb1.layer.cornerRadius = 200;
        _orb1.layer.shadowColor = [ZXTheme accentPurple].CGColor;
        _orb1.layer.shadowRadius = 80;
        _orb1.layer.shadowOpacity = 1.0;
        [self addSubview:_orb1];
        
        // Cyan Orb
        _orb2 = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width - 200, frame.size.height - 200, 500, 500)];
        _orb2.backgroundColor = [[ZXTheme accentCyan] colorWithAlphaComponent:0.12];
        _orb2.layer.cornerRadius = 250;
        _orb2.layer.shadowColor = [ZXTheme accentCyan].CGColor;
        _orb2.layer.shadowRadius = 100;
        _orb2.layer.shadowOpacity = 1.0;
        [self addSubview:_orb2];
        
        // Subtle Grid Overlay
        UIView *gridOverlay = [[UIView alloc] initWithFrame:self.bounds];
        gridOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        gridOverlay.backgroundColor = [UIColor colorWithPatternImage:[self createGridImage]];
        gridOverlay.alpha = 0.3;
        [self addSubview:gridOverlay];
    }
    return self;
}

- (UIImage *)createGridImage {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:1.0 alpha:0.04].CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    CGContextMoveToPoint(ctx, 0, 0); CGContextAddLineToPoint(ctx, 40, 0);
    CGContextMoveToPoint(ctx, 0, 0); CGContextAddLineToPoint(ctx, 0, 40);
    CGContextStrokePath(ctx);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (void)startAnimations {
    CABasicAnimation *move1 = [CABasicAnimation animationWithKeyPath:@"transform.translation"];
    move1.toValue = [NSValue valueWithCGPoint:CGPointMake(80, 150)];
    move1.duration = 12.0;
    move1.autoreverses = YES;
    move1.repeatCount = HUGE_VALF;
    move1.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.orb1.layer addAnimation:move1 forKey:@"float1"];
    
    CABasicAnimation *move2 = [CABasicAnimation animationWithKeyPath:@"transform.translation"];
    move2.toValue = [NSValue valueWithCGPoint:CGPointMake(-100, -120)];
    move2.duration = 15.0;
    move2.autoreverses = YES;
    move2.repeatCount = HUGE_VALF;
    move2.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.orb2.layer addAnimation:move2 forKey:@"float2"];
}

- (void)stopAnimations {
    [self.orb1.layer removeAllAnimations];
    [self.orb2.layer removeAllAnimations];
}
@end

#pragma mark - ================= UI COMPONENTS =================

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
        
        _gradientLayer = [ZXTheme primaryGradient];
        [_bgView.layer insertSublayer:_gradientLayer atIndex:0];
        
        self.layer.shadowColor = [ZXTheme accentCyan].CGColor;
        self.layer.shadowOpacity = 0.4;
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
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:0 animations:^{
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
        [self.spinner startAnimating];
        self.bgView.alpha = 0.8;
    } else {
        [self setTitle:self.originalTitle forState:UIControlStateNormal];
        [self.spinner stopAnimating];
        self.bgView.alpha = 1.0;
    }
}
@end

@interface ZXTextField : UIView <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *inputContainer;
@property (nonatomic, strong) UIImageView *iconView;
@end

@implementation ZXTextField

- (instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"LICENSE KEY";
        _titleLabel.textColor = [ZXTheme textMuted];
        _titleLabel.font = [ZXTheme fontMono:11 weight:UIFontWeightBold];
        [ZXTheme applyTextTracking:_titleLabel spacing:1.5];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_titleLabel];
        
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
        _textField.font = [ZXTheme fontMono:15 weight:UIFontWeightBold];
        _textField.secureTextEntry = YES;
        _textField.delegate = self;
        _textField.translatesAutoresizingMaskIntoConstraints = NO;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textField.returnKeyType = UIReturnKeyDone;
        _textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Enter your key..." attributes:@{NSForegroundColorAttributeName: [ZXTheme textMuted]}];
        [_inputContainer addSubview:_textField];
        
        UIButton *pasteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [pasteBtn setTitle:@"PASTE" forState:UIControlStateNormal];
        pasteBtn.titleLabel.font = [ZXTheme fontHeading:12];
        pasteBtn.backgroundColor = [ZXTheme bgCardInner];
        pasteBtn.layer.cornerRadius = 8;
        pasteBtn.layer.borderWidth = 1.0;
        pasteBtn.layer.borderColor = [ZXTheme borderSubtle].CGColor;
        [pasteBtn setTitleColor:[ZXTheme accentCyan] forState:UIControlStateNormal];
        pasteBtn.translatesAutoresizingMaskIntoConstraints = NO;
        [pasteBtn addTarget:self action:@selector(pasteKeyTapped) forControlEvents:UIControlEventTouchUpInside];
        [_inputContainer addSubview:pasteBtn];
        
        [NSLayoutConstraint activateConstraints:@[
            [_titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:4],
            
            [_inputContainer.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:8],
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
        self.inputContainer.layer.shadowColor = [ZXTheme accentCyan].CGColor;
        self.inputContainer.layer.shadowOpacity = 0.3;
        self.inputContainer.layer.shadowRadius = 10;
        self.iconView.tintColor = [ZXTheme accentCyan];
        self.titleLabel.textColor = [ZXTheme accentCyan];
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.3 animations:^{
        self.inputContainer.layer.borderColor = [ZXTheme borderSubtle].CGColor;
        self.inputContainer.layer.shadowOpacity = 0.0;
        self.iconView.tintColor = [ZXTheme textMuted];
        self.titleLabel.textColor = [ZXTheme textMuted];
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
    self.thumbLeadingConstraint.constant = self.isOn ? 26 : 4; // 50 - 20 - 4 = 26
    
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
+ (void)showModalWithIcon:(NSString *)iconName isError:(BOOL)isError title:(NSString *)title message:(NSString *)msg actionTitle:(NSString *)actTitle inView:(UIView *)parentView;
@end

@implementation ZXModalManager

+ (void)showModalWithIcon:(NSString *)iconName isError:(BOOL)isError title:(NSString *)title message:(NSString *)msg actionTitle:(NSString *)actTitle inView:(UIView *)parentView {
    
    UIView *overlay = [[UIView alloc] initWithFrame:parentView.bounds];
    overlay.tag = 100100;
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
    overlay.alpha = 0;
    [parentView addSubview:overlay];
    
    UIColor *tintColor = isError ? [ZXTheme statusError] : [ZXTheme accentCyan];
    
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [ZXTheme bgCardOuter];
    card.layer.cornerRadius = 24;
    card.layer.borderWidth = 1.5;
    card.layer.borderColor = tintColor.CGColor;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [overlay addSubview:card];
    
    card.layer.shadowColor = tintColor.CGColor;
    card.layer.shadowOpacity = 0.2;
    card.layer.shadowRadius = 40;
    card.layer.shadowOffset = CGSizeMake(0, 15);
    
    UIView *iconContainer = [[UIView alloc] init];
    iconContainer.backgroundColor = [tintColor colorWithAlphaComponent:0.1];
    iconContainer.layer.cornerRadius = 28;
    iconContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:iconContainer];
    
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    iconView.tintColor = tintColor;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [iconContainer addSubview:iconView];
    
    UILabel *titleLbl = [[UILabel alloc] init];
    titleLbl.text = [title uppercaseString];
    titleLbl.textColor = [ZXTheme textPrimary];
    titleLbl.font = [ZXTheme fontDisplay:17];
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
    
    if (isError) {
        // Red button for errors
        CAGradientLayer *redGrad = [CAGradientLayer layer];
        redGrad.colors = @[(id)[UIColor colorWithRed:1.0 green:0.2 blue:0.4 alpha:1.0].CGColor, (id)[UIColor colorWithRed:0.8 green:0.1 blue:0.2 alpha:1.0].CGColor];
        redGrad.startPoint = CGPointMake(0, 0); redGrad.endPoint = CGPointMake(1, 1);
        [btn.bgView.layer replaceSublayer:btn.gradientLayer with:redGrad];
        btn.gradientLayer = redGrad;
        btn.layer.shadowColor = [ZXTheme statusError].CGColor;
    }
    
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:btn];
    
    [NSLayoutConstraint activateConstraints:@[
        [card.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
        [card.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [card.widthAnchor constraintEqualToConstant:320],
        
        [iconContainer.topAnchor constraintEqualToAnchor:card.topAnchor constant:32],
        [iconContainer.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [iconContainer.widthAnchor constraintEqualToConstant:56],
        [iconContainer.heightAnchor constraintEqualToConstant:56],
        
        [iconView.centerXAnchor constraintEqualToAnchor:iconContainer.centerXAnchor],
        [iconView.centerYAnchor constraintEqualToAnchor:iconContainer.centerYAnchor],
        [iconView.widthAnchor constraintEqualToConstant:26],
        [iconView.heightAnchor constraintEqualToConstant:26],
        
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
    if (sender.view.tag == 100100) [self animateDismiss:sender.view];
}

+ (void)dismissBtnTapped:(UIButton *)btn {
    [self animateDismiss:btn.superview.superview];
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
@property (nonatomic, strong) ZXAnimatedBackground *backgroundView;
@property (nonatomic, strong) UIView *splashContainer;
@property (nonatomic, strong) UIView *authContainer;
@property (nonatomic, strong) UIView *verificationContainer;
@property (nonatomic, strong) UIView *dashboardContainer;

// Splash elements
@property (nonatomic, strong) UIImageView *splashShield;
@property (nonatomic, strong) UIView *progressTrack;
@property (nonatomic, strong) UIView *progressFill;

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

// State Management
@property (nonatomic, strong) NSTimer *heartbeatTimer;
@property (nonatomic, strong) NSArray *cachedModulesState; // Prevents UI Blinking on Heartbeat

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
    
    // 1. Setup Animated Background
    _backgroundView = [[ZXAnimatedBackground alloc] initWithFrame:self.view.bounds];
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_backgroundView];
    
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
    
    [self.backgroundView startAnimations];
    
    if (!self.hasCompletedInitialPresentation) {
        self.hasCompletedInitialPresentation = YES;
        [self runDeterministicLaunchSequence];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.backgroundView stopAnimations];
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

#pragma mark - State Machine & Heartbeat Protection
- (void)transitionToState:(ZXAppState)newState {
    if (self.currentState == newState) return;
    self.currentState = newState;
    self.dismissTap.enabled = (newState != ZXAppStateDashboard);
    
    if (newState == ZXAppStateDashboard) {
        [self startHeartbeatMonitor];
    } else {
        [self stopHeartbeatMonitor];
        self.cachedModulesState = nil; // Clear cache on logout
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
                    // Safety check to ensure true revocation vs temporary offline
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
    
    // Kill visually active modules instantly
    for (UIView *card in self.modulesStackView.arrangedSubviews) {
        ZXToggle *toggle = [self findToggleInCard:card];
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
                    [strongSelf.keyInput updateFloatingLabelStateAnimated:NO];
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
    title.text = @"ZENTRAX VIP";
    title.textColor = [UIColor whiteColor];
    title.font = [ZXTheme fontDisplay:28];
    [ZXTheme applyTextTracking:title spacing:4.0];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:title];
    
    UILabel *sub = [[UILabel alloc] init];
    sub.text = @"INITIALIZING SECURE ENVIRONMENT";
    sub.textColor = [ZXTheme textMuted];
    sub.font = [ZXTheme fontMono:10 weight:UIFontWeightBold];
    [ZXTheme applyTextTracking:sub spacing:2.0];
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
        [iconBg.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [iconBg.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor constant:-60],
        [iconBg.widthAnchor constraintEqualToConstant:90],
        [iconBg.heightAnchor constraintEqualToConstant:90],
        
        [_splashShield.centerXAnchor constraintEqualToAnchor:iconBg.centerXAnchor],
        [_splashShield.centerYAnchor constraintEqualToAnchor:iconBg.centerYAnchor],
        [_splashShield.widthAnchor constraintEqualToConstant:40],
        [_splashShield.heightAnchor constraintEqualToConstant:45],
        
        [title.topAnchor constraintEqualToAnchor:iconBg.bottomAnchor constant:30],
        [title.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        
        [sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:10],
        [sub.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        
        [_progressTrack.bottomAnchor constraintEqualToAnchor:_splashContainer.safeAreaLayoutGuide.bottomAnchor constant:-80],
        [_progressTrack.leadingAnchor constraintEqualToAnchor:_splashContainer.leadingAnchor constant:80],
        [_progressTrack.trailingAnchor constraintEqualToAnchor:_splashContainer.trailingAnchor constant:-80],
        [_progressTrack.heightAnchor constraintEqualToConstant:4]
    ]];
}

- (void)runDeterministicLaunchSequence {
    self.currentState = ZXAppStateSplash;
    self.splashContainer.alpha = 1.0;
    
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.toValue = @1.08;
    pulse.duration = 1.0;
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    [self.splashShield.layer addAnimation:pulse forKey:@"pulse"];
    
    // Progress Bar Animation
    [UIView animateWithDuration:1.5 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.progressFill.frame = CGRectMake(0, 0, (self.view.bounds.size.width - 160) * 0.8, 4);
    } completion:nil];
    
    NSTimeInterval sequenceStartTime = CACurrentMediaTime();
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) {
        [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL isValid) {
            NSTimeInterval elapsed = CACurrentMediaTime() - sequenceStartTime;
            NSTimeInterval remainingDelay = MAX(0.0, 1.8 - elapsed);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, remainingDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                
                [UIView animateWithDuration:0.4 animations:^{
                    self.progressFill.frame = CGRectMake(0, 0, self.view.bounds.size.width - 160, 4);
                } completion:^(BOOL finished) {
                    [self.splashShield.layer removeAllAnimations];
                    if (isValid) {
                        [self transitionToState:ZXAppStateDashboard];
                        [self showPremiumToast:@"Session Restored" success:YES];
                    } else {
                        [self transitionToState:ZXAppStateAuth];
                    }
                }];
            });
        }];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self.splashShield.layer removeAllAnimations];
            [self transitionToState:ZXAppStateAuth];
        });
    }
}

#pragma mark - Premium Auth Flow
- (void)setupAuth {
    _authContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_authContainer];
    
    UILabel *headerSub = [[UILabel alloc] init];
    headerSub.text = @"WELCOME TO ZENTRAX";
    headerSub.textColor = [ZXTheme accentCyan];
    headerSub.font = [ZXTheme fontMono:11 weight:UIFontWeightBold];
    [ZXTheme applyTextTracking:headerSub spacing:3.0];
    headerSub.textAlignment = NSTextAlignmentCenter;
    headerSub.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:headerSub];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"VIP Authentication";
    title.textColor = [UIColor whiteColor];
    title.font = [ZXTheme fontDisplay:32];
    title.textAlignment = NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:title];
    
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor clearColor];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:card];
    
    _keyInput = [[ZXTextField alloc] init];
    _keyInput.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_keyInput];
    
    _loginBtn = [[ZXButton alloc] init];
    [_loginBtn setTitle:@"AUTHENTICATE" forState:UIControlStateNormal];
    [_loginBtn addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside];
    _loginBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_loginBtn];
    
    [NSLayoutConstraint activateConstraints:@[
        [headerSub.bottomAnchor constraintEqualToAnchor:title.topAnchor constant:-12],
        [headerSub.centerXAnchor constraintEqualToAnchor:_authContainer.centerXAnchor],
        
        [title.bottomAnchor constraintEqualToAnchor:card.topAnchor constant:-50],
        [title.centerXAnchor constraintEqualToAnchor:_authContainer.centerXAnchor],
        
        [card.centerYAnchor constraintEqualToAnchor:_authContainer.centerYAnchor constant:20],
        [card.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:32],
        [card.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-32],
        [card.heightAnchor constraintEqualToConstant:160],
        
        [_keyInput.topAnchor constraintEqualToAnchor:card.topAnchor],
        [_keyInput.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [_keyInput.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [_keyInput.heightAnchor constraintEqualToConstant:70],
        
        [_loginBtn.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],
        [_loginBtn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [_loginBtn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [_loginBtn.heightAnchor constraintEqualToConstant:60],
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
    __weak typeof(self) weakSelf = self;
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestAuthenticationWithKey:completion:)]) {
        [self.delegate zentraxDidRequestAuthenticationWithKey:key completion:^(BOOL success, ZXAuthError errorType, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                
                [strongSelf.loginBtn setLoading:NO];
                if (success) {
                    [strongSelf transitionToState:ZXAppStateDashboard];
                    [strongSelf showPremiumToast:@"Login Successful" success:YES];
                    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred];
                } else {
                    [strongSelf showGlobalErrorWithTitle:@"ACCESS DENIED" message:errorMsg ?: @"Key rejected by server node."];
                }
            });
        }];
    }
}

- (void)setupVerification {}

#pragma mark - Premium Dashboard
- (void)setupDashboard {
    _dashboardContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_dashboardContainer];
    
    // Clean Header
    UIView *navBar = [[UIView alloc] init];
    navBar.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:navBar];
    
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.text = @"VIP DASHBOARD";
    navTitle.textColor = [UIColor whiteColor];
    navTitle.font = [ZXTheme fontHeading:18];
    [ZXTheme applyTextTracking:navTitle spacing:2.0];
    navTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [navBar addSubview:navTitle];
    
    UIButton *logoutBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [logoutBtn setImage:[[UIImage systemImageNamed:@"power"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    logoutBtn.tintColor = [ZXTheme statusError];
    logoutBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [logoutBtn addTarget:self action:@selector(handleLogout) forControlEvents:UIControlEventTouchUpInside];
    [navBar addSubview:logoutBtn];
    
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
    subTitle.font = [ZXTheme fontMono:11 weight:UIFontWeightBold];
    [ZXTheme applyTextTracking:subTitle spacing:1.5];
    subTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:subTitle];
    
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.text = @"ACTIVE";
    _statusLabel.textColor = [ZXTheme statusSuccess];
    _statusLabel.font = [ZXTheme fontDisplay:24];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_statusLabel];
    
    _expiryLabel = [[UILabel alloc] init];
    _expiryLabel.text = @"Syncing...";
    _expiryLabel.textColor = [ZXTheme textSecondary];
    _expiryLabel.font = [ZXTheme fontBody:13 weight:UIFontWeightMedium];
    _expiryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_expiryLabel];
    
    UIImageView *cardIcon = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"checkmark.seal.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    cardIcon.tintColor = [ZXTheme statusSuccess];
    cardIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:cardIcon];
    
    // Scroll Area
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
        
        [subTitle.topAnchor constraintEqualToAnchor:statusCard.topAnchor constant:20],
        [subTitle.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:20],
        
        [_statusLabel.topAnchor constraintEqualToAnchor:subTitle.bottomAnchor constant:8],
        [_statusLabel.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:20],
        
        [_expiryLabel.topAnchor constraintEqualToAnchor:_statusLabel.bottomAnchor constant:6],
        [_expiryLabel.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:20],
        
        [cardIcon.trailingAnchor constraintEqualToAnchor:statusCard.trailingAnchor constant:-20],
        [cardIcon.centerYAnchor constraintEqualToAnchor:statusCard.centerYAnchor],
        [cardIcon.widthAnchor constraintEqualToConstant:40],
        [cardIcon.heightAnchor constraintEqualToConstant:40],
        
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
    title.text = @"NO ACTIVE FEATURES";
    title.textColor = [UIColor whiteColor];
    title.font = [ZXTheme fontHeading:18];
    title.textAlignment = NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyStateView addSubview:title];
    
    UILabel *sub = [[UILabel alloc] init];
    sub.text = @"There are currently no functions available.";
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

// Critical Bug Fix: Prevent UI blinking/re-rendering on Heartbeat if data is identical
- (BOOL)isModuleDataIdentical:(NSArray *)newModules {
    if (!self.cachedModulesState) return NO;
    if (newModules.count != self.cachedModulesState.count) return NO;
    
    for (int i=0; i<newModules.count; i++) {
        NSDictionary *newMod = newModules[i];
        NSDictionary *oldMod = self.cachedModulesState[i];
        if (![newMod isEqualToDictionary:oldMod]) {
            return NO;
        }
    }
    return YES;
}

- (void)updateDashboardWithModules:(NSArray<NSDictionary *> *)modules {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Prevent blinking on background refresh
        if ([self isModuleDataIdentical:modules]) {
            return;
        }
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
        sectionHeader.text = @"ACTIVE FEATURES";
        sectionHeader.textColor = [ZXTheme accentCyan];
        sectionHeader.font = [ZXTheme fontMono:11 weight:UIFontWeightBold];
        [ZXTheme applyTextTracking:sectionHeader spacing:2.0];
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
            
            UIView *indicator = [[UIView alloc] init];
            indicator.backgroundColor = isModOn ? [ZXTheme accentCyan] : [ZXTheme textMuted];
            indicator.layer.cornerRadius = 3;
            if (isModOn) {
                indicator.layer.shadowColor = [ZXTheme accentCyan].CGColor;
                indicator.layer.shadowOpacity = 1.0;
                indicator.layer.shadowRadius = 5;
            }
            indicator.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:indicator];
            
            UILabel *t = [[UILabel alloc] init];
            t.text = [moduleName uppercaseString];
            t.textColor = [UIColor whiteColor];
            t.font = [ZXTheme fontHeading:16];
            t.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:t];
            
            ZXToggle *toggle = [[ZXToggle alloc] init];
            toggle.moduleId = moduleName; 
            [toggle setOn:isModOn animated:NO]; 
            [toggle addTarget:self action:@selector(moduleToggled:) forControlEvents:UIControlEventValueChanged];
            [card addSubview:toggle];
            
            // Premium Inset Box for Description
            UIView *descBox = [[UIView alloc] init];
            descBox.backgroundColor = [ZXTheme bgCardInner];
            descBox.layer.cornerRadius = 10;
            descBox.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:descBox];
            
            UILabel *s = [[UILabel alloc] init];
            s.text = moduleDesc;
            s.textColor = [ZXTheme textSecondary];
            s.font = [ZXTheme fontBody:13 weight:UIFontWeightRegular];
            s.numberOfLines = 0;
            s.translatesAutoresizingMaskIntoConstraints = NO;
            [descBox addSubview:s];
            
            [NSLayoutConstraint activateConstraints:@[
                [indicator.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
                [indicator.centerYAnchor constraintEqualToAnchor:t.centerYAnchor],
                [indicator.widthAnchor constraintEqualToConstant:6],
                [indicator.heightAnchor constraintEqualToConstant:6],
                
                [t.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
                [t.leadingAnchor constraintEqualToAnchor:indicator.trailingAnchor constant:12],
                [t.trailingAnchor constraintLessThanOrEqualToAnchor:toggle.leadingAnchor constant:-16],
                
                [toggle.centerYAnchor constraintEqualToAnchor:t.centerYAnchor],
                [toggle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
                
                [descBox.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:16],
                [descBox.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
                [descBox.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
                [descBox.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20],
                
                [s.topAnchor constraintEqualToAnchor:descBox.topAnchor constant:12],
                [s.leadingAnchor constraintEqualToAnchor:descBox.leadingAnchor constant:16],
                [s.trailingAnchor constraintEqualToAnchor:descBox.trailingAnchor constant:-16],
                [s.bottomAnchor constraintEqualToAnchor:descBox.bottomAnchor constant:-12]
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
            self.expiryLabel.text = @"EXPIRES: LIFETIME ACCESS";
            self.expiryLabel.textColor = [ZXTheme accentCyan];
        } else if (expiryStr) {
            self.expiryLabel.text = [[NSString stringWithFormat:@"EXPIRES: %@", expiryStr] uppercaseString];
            self.expiryLabel.textColor = [ZXTheme textSecondary];
        } else {
            self.expiryLabel.text = @"NO EXPIRY DATA";
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
                    NSString *toastMsg = requestedState ? @"Function Enabled" : @"Function Disabled";
                    [strongSelf showPremiumToast:toastMsg success:YES];
                    
                    // Force refresh cache to match local state
                    strongSelf.cachedModulesState = nil;
                } else {
                    [sender setOn:!requestedState animated:YES];
                    [strongSelf showGlobalErrorWithTitle:@"Injection Failed" message:errorMsg ?: @"Failed to inject execution payload safely."];
                }
            });
        }];
    }
}

#pragma mark - Centered Top-Down Toast
- (void)showPremiumToast:(NSString *)msg success:(BOOL)success {
    for (UIView *v in self.view.subviews) {
        if (v.tag == 887766) [v removeFromSuperview];
    }
    
    UIColor *tint = success ? [ZXTheme statusSuccess] : [ZXTheme statusError];
    CGFloat toastWidth = 260;
    CGFloat toastHeight = 44;
    
    // AutoLayout safe centering without rotation bugs
    CGFloat screenWidth = self.view.bounds.size.width;
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
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        topInset = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets.top;
#pragma clang diagnostic pop
    }
    if (topInset == 0) topInset = 45;
    
    UIView *toast = [[UIView alloc] initWithFrame:CGRectMake((screenWidth - toastWidth)/2, -60, toastWidth, toastHeight)];
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
        [ZXModalManager showModalWithIcon:@"exclamationmark.triangle.fill" isError:YES title:title message:msg actionTitle:@"Dismiss" inView:self.view];
    });
}
- (void)showSuccessMessage:(NSString *)title message:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        [ZXModalManager showModalWithIcon:@"checkmark.shield.fill" isError:NO title:title message:msg actionTitle:@"Continue" inView:self.view];
    });
}
- (void)showNetworkError { [self showPremiumToast:@"Network Connection Lost" success:NO]; }
- (void)showServerError { [self showPremiumToast:@"Server Unavailable" success:NO]; }
- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds {
    NSString *msg = [NSString stringWithFormat:@"Request limits reached. Cooldown active for %ld seconds.", (long)seconds];
    dispatch_async(dispatch_get_main_queue(), ^{
        [ZXModalManager showModalWithIcon:@"timer" isError:YES title:@"Rate Limited" message:msg actionTitle:@"Understood" inView:self.view];
    });
}
- (void)showGlobalLoadingState:(NSString *)message {}
- (void)hideGlobalLoadingState {}

@end
