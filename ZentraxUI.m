//
//  ZentraxUI.m
//  Zentrax VIP - Premium Execution Node UI
//
//  Created by Zentrax Team.
//  Architecture: Ultra-Premium Gaming / Futuristic Layer V5
//  Status: PRODUCTION READY
//

#import "ZentraxUI.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>

#pragma mark - ================= GAMING DESIGN SYSTEM =================

@interface ZXTheme : NSObject
+ (UIColor *)bgDeepSpace;
+ (UIColor *)bgCardOuter;
+ (UIColor *)bgCardInner;
+ (UIColor *)borderSubtle;
+ (UIColor *)borderActive;
+ (UIColor *)neonCyan;
+ (UIColor *)neonCrimson;
+ (UIColor *)neonPurple;
+ (UIColor *)textPrimary;
+ (UIColor *)textSecondary;
+ (UIColor *)textMuted;
+ (UIFont *)fontDisplay:(CGFloat)size;
+ (UIFont *)fontHeading:(CGFloat)size;
+ (UIFont *)fontBody:(CGFloat)size weight:(UIFontWeight)weight;
+ (UIFont *)fontMono:(CGFloat)size weight:(UIFontWeight)weight;
+ (void)applyTextTracking:(UILabel *)label spacing:(CGFloat)spacing;
+ (void)applyGamingCardStyle:(UIView *)view;
@end

@implementation ZXTheme

// Aggressive Dark Gaming Colors
+ (UIColor *)bgDeepSpace { return [UIColor colorWithRed:0.04 green:0.04 blue:0.06 alpha:1.0]; }
+ (UIColor *)bgCardOuter { return [UIColor colorWithRed:0.08 green:0.09 blue:0.12 alpha:0.85]; }
+ (UIColor *)bgCardInner { return [UIColor colorWithRed:0.10 green:0.12 blue:0.16 alpha:0.95]; }
+ (UIColor *)borderSubtle { return [UIColor colorWithRed:0.15 green:0.18 blue:0.25 alpha:1.0]; }
+ (UIColor *)borderActive { return [self neonCyan]; }

// Neon Highlights
+ (UIColor *)neonCyan { return [UIColor colorWithRed:0.0 green:0.90 blue:1.0 alpha:1.0]; }
+ (UIColor *)neonCrimson { return [UIColor colorWithRed:1.0 green:0.15 blue:0.35 alpha:1.0]; }
+ (UIColor *)neonPurple { return [UIColor colorWithRed:0.70 green:0.20 blue:1.0 alpha:1.0]; }

+ (UIColor *)textPrimary { return [UIColor colorWithWhite:1.0 alpha:1.0]; }
+ (UIColor *)textSecondary { return [UIColor colorWithWhite:0.75 alpha:1.0]; }
+ (UIColor *)textMuted { return [UIColor colorWithWhite:0.45 alpha:1.0]; }

// Stronger Fonts for Gaming feel
+ (UIFont *)fontDisplay:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBlack]; }
+ (UIFont *)fontHeading:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightHeavy]; }
+ (UIFont *)fontBody:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont systemFontOfSize:size weight:weight]; }
+ (UIFont *)fontMono:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont monospacedSystemFontOfSize:size weight:weight]; }

+ (void)applyTextTracking:(UILabel *)label spacing:(CGFloat)spacing {
    if (!label.text) return;
    NSDictionary *attrs = @{NSKernAttributeName: @(spacing)};
    label.attributedText = [[NSAttributedString alloc] initWithString:label.text attributes:attrs];
}

+ (void)applyGamingCardStyle:(UIView *)view {
    view.backgroundColor = [self bgCardOuter];
    view.layer.cornerRadius = 12; // Sharper corners for gaming look
    view.layer.borderWidth = 1.0;
    view.layer.borderColor = [self borderSubtle].CGColor;
    
    // Subtle inner drop shadow for depth
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOpacity = 0.5;
    view.layer.shadowOffset = CGSizeMake(0, 5);
    view.layer.shadowRadius = 10;
}
@end

#pragma mark - ================= FUTURISTIC COMPONENTS =================

// Futuristic Glow Button
@interface ZXGamingButton : UIButton
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSString *originalTitle;
@property (nonatomic, strong) UIView *glowLayer;
- (void)setLoading:(BOOL)loading;
@end

@implementation ZXGamingButton

- (instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 8;
        self.layer.borderWidth = 1.5;
        self.layer.borderColor = [ZXTheme neonCyan].CGColor;
        self.titleLabel.font = [ZXTheme fontDisplay:14];
        [self setTitleColor:[ZXTheme neonCyan] forState:UIControlStateNormal];
        
        _glowLayer = [[UIView alloc] init];
        _glowLayer.backgroundColor = [[ZXTheme neonCyan] colorWithAlphaComponent:0.15];
        _glowLayer.layer.cornerRadius = 8;
        _glowLayer.userInteractionEnabled = NO;
        _glowLayer.translatesAutoresizingMaskIntoConstraints = NO;
        [self insertSubview:_glowLayer atIndex:0];
        
        self.layer.shadowColor = [ZXTheme neonCyan].CGColor;
        self.layer.shadowOpacity = 0.5;
        self.layer.shadowRadius = 15;
        self.layer.shadowOffset = CGSizeZero;
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        _spinner.color = [ZXTheme neonCyan];
        _spinner.hidesWhenStopped = YES;
        _spinner.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_spinner];
        
        [NSLayoutConstraint activateConstraints:@[
            [_glowLayer.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_glowLayer.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_glowLayer.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_glowLayer.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [_spinner.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [_spinner.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
        ]];
        
        [self addTarget:self action:@selector(touchDown) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    }
    return self;
}

- (void)touchDown {
    if (!self.userInteractionEnabled) return;
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
    [haptic impactOccurred];
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformMakeScale(0.96, 0.96);
        self.glowLayer.backgroundColor = [[ZXTheme neonCyan] colorWithAlphaComponent:0.4];
        self.layer.shadowRadius = 25;
    } completion:nil];
}

- (void)touchUp {
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.transform = CGAffineTransformIdentity;
        self.glowLayer.backgroundColor = [[ZXTheme neonCyan] colorWithAlphaComponent:0.15];
        self.layer.shadowRadius = 15;
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

// Cyberpunk Text Field
@interface ZXGamingField : UIView <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *focusBorder;
@end

@implementation ZXGamingField

- (instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = [ZXTheme bgCardInner];
        self.layer.cornerRadius = 8;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [ZXTheme borderSubtle].CGColor;
        
        _focusBorder = [[UIView alloc] init];
        _focusBorder.layer.cornerRadius = 8;
        _focusBorder.layer.borderWidth = 1.5;
        _focusBorder.layer.borderColor = [ZXTheme neonCyan].CGColor;
        _focusBorder.alpha = 0;
        _focusBorder.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_focusBorder];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"LICENSE KEY";
        _titleLabel.textColor = [ZXTheme textMuted];
        _titleLabel.font = [ZXTheme fontMono:10 weight:UIFontWeightBold];
        [ZXTheme applyTextTracking:_titleLabel spacing:2.0];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_titleLabel];
        
        _textField = [[UITextField alloc] init];
        _textField.textColor = [ZXTheme textPrimary];
        _textField.font = [ZXTheme fontMono:15 weight:UIFontWeightBold];
        _textField.secureTextEntry = YES;
        _textField.delegate = self;
        _textField.translatesAutoresizingMaskIntoConstraints = NO;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textField.returnKeyType = UIReturnKeyDone;
        [self addSubview:_textField];
        
        UIButton *pasteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [pasteBtn setTitle:@"[PASTE]" forState:UIControlStateNormal];
        pasteBtn.titleLabel.font = [ZXTheme fontMono:11 weight:UIFontWeightBold];
        [pasteBtn setTitleColor:[ZXTheme neonCyan] forState:UIControlStateNormal];
        pasteBtn.translatesAutoresizingMaskIntoConstraints = NO;
        [pasteBtn addTarget:self action:@selector(pasteKey) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:pasteBtn];
        
        [NSLayoutConstraint activateConstraints:@[
            [_focusBorder.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_focusBorder.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_focusBorder.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_focusBorder.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            
            [_titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:12],
            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
            
            [_textField.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:4],
            [_textField.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
            [_textField.trailingAnchor constraintEqualToAnchor:pasteBtn.leadingAnchor constant:-10],
            [_textField.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-12],
            
            [pasteBtn.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],
            [pasteBtn.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
        ]];
    }
    return self;
}

- (void)pasteKey {
    NSString *pb = [[UIPasteboard generalPasteboard].string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (pb.length > 0) {
        self.textField.text = pb;
        [self.textField sendActionsForControlEvents:UIControlEventEditingChanged];
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.3 animations:^{
        self.focusBorder.alpha = 1.0;
        self.titleLabel.textColor = [ZXTheme neonCyan];
        self.layer.shadowColor = [ZXTheme neonCyan].CGColor;
        self.layer.shadowOpacity = 0.3;
        self.layer.shadowRadius = 10;
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.3 animations:^{
        self.focusBorder.alpha = 0.0;
        self.titleLabel.textColor = [ZXTheme textMuted];
        self.layer.shadowOpacity = 0.0;
    }];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField { [textField resignFirstResponder]; return YES; }
@end

// Hardcore Gaming Switch (Blocky, Neon)
@interface ZXGamingToggle : UIControl
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, strong) NSString *moduleId; 
@property (nonatomic, strong) UIView *trackView;
@property (nonatomic, strong) UIView *thumbView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSLayoutConstraint *thumbLeadingConstraint;
@end

@implementation ZXGamingToggle

- (instancetype)init {
    if (self = [super init]) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        [NSLayoutConstraint activateConstraints:@[
            [self.widthAnchor constraintEqualToConstant:56],
            [self.heightAnchor constraintEqualToConstant:28]
        ]];
        
        _trackView = [[UIView alloc] init];
        _trackView.backgroundColor = [ZXTheme bgCardInner];
        _trackView.layer.cornerRadius = 6; // Sharper edges
        _trackView.layer.borderWidth = 1.5;
        _trackView.layer.borderColor = [ZXTheme borderSubtle].CGColor;
        _trackView.userInteractionEnabled = NO;
        _trackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_trackView];
        
        _thumbView = [[UIView alloc] init];
        _thumbView.backgroundColor = [ZXTheme textMuted];
        _thumbView.layer.cornerRadius = 4; // Blocky thumb
        _thumbView.userInteractionEnabled = NO;
        _thumbView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_thumbView];
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        _spinner.transform = CGAffineTransformMakeScale(0.6, 0.6);
        _spinner.hidesWhenStopped = YES;
        _spinner.userInteractionEnabled = NO;
        _spinner.translatesAutoresizingMaskIntoConstraints = NO;
        [_thumbView addSubview:_spinner];
        
        // Exact Layout bounds
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
    return CGRectContainsPoint(CGRectInset(self.bounds, -20, -20), point);
}

- (void)handleTap {
    if (!self.userInteractionEnabled) return;
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
    [haptic impactOccurred];
    [self setOn:!self.isOn animated:YES];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _isOn = on;
    [self updateStateAnimated:animated];
}

- (void)updateStateAnimated:(BOOL)animated {
    self.thumbLeadingConstraint.constant = self.isOn ? 32 : 4; // 56 - 20 - 4 = 32
    
    void (^stateUpdates)(void) = ^{
        [self layoutIfNeeded];
        
        if (self.isOn) {
            self.trackView.layer.borderColor = [ZXTheme neonCyan].CGColor;
            self.trackView.backgroundColor = [[ZXTheme neonCyan] colorWithAlphaComponent:0.2];
            self.thumbView.backgroundColor = [ZXTheme neonCyan];
            self.thumbView.layer.shadowColor = [ZXTheme neonCyan].CGColor;
            self.thumbView.layer.shadowOpacity = 1.0;
            self.thumbView.layer.shadowRadius = 10;
        } else {
            self.trackView.layer.borderColor = [ZXTheme borderSubtle].CGColor;
            self.trackView.backgroundColor = [ZXTheme bgCardInner];
            self.thumbView.backgroundColor = [ZXTheme textMuted];
            self.thumbView.layer.shadowOpacity = 0.0;
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.4 options:UIViewAnimationOptionCurveEaseInOut animations:stateUpdates completion:nil];
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

#pragma mark - ================= GAMING MODALS & TOASTS =================

@interface ZXModalManager : NSObject
+ (void)showModalWithIcon:(NSString *)iconName isError:(BOOL)isError title:(NSString *)title message:(NSString *)msg actionTitle:(NSString *)actTitle inView:(UIView *)parentView;
@end

@implementation ZXModalManager

+ (void)showModalWithIcon:(NSString *)iconName isError:(BOOL)isError title:(NSString *)title message:(NSString *)msg actionTitle:(NSString *)actTitle inView:(UIView *)parentView {
    UIColor *tint = isError ? [ZXTheme neonCrimson] : [ZXTheme neonCyan];
    
    UIView *overlay = [[UIView alloc] initWithFrame:parentView.bounds];
    overlay.tag = 100100;
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
    overlay.alpha = 0;
    [parentView addSubview:overlay];
    
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [ZXTheme bgCardOuter];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 2.0;
    card.layer.borderColor = tint.CGColor;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.transform = CGAffineTransformMakeScale(1.1, 1.1); // Aggressive pop-in
    [overlay addSubview:card];
    
    card.layer.shadowColor = tint.CGColor;
    card.layer.shadowOpacity = 0.4;
    card.layer.shadowRadius = 30;
    
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    iconView.tintColor = tint;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:iconView];
    
    UILabel *titleLbl = [[UILabel alloc] init];
    titleLbl.text = [title uppercaseString];
    titleLbl.textColor = [ZXTheme textPrimary];
    titleLbl.font = [ZXTheme fontDisplay:18];
    [ZXTheme applyTextTracking:titleLbl spacing:2.0];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    titleLbl.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:titleLbl];
    
    UILabel *msgLbl = [[UILabel alloc] init];
    msgLbl.text = msg;
    msgLbl.textColor = [ZXTheme textSecondary];
    msgLbl.font = [ZXTheme fontMono:13 weight:UIFontWeightRegular];
    msgLbl.textAlignment = NSTextAlignmentCenter;
    msgLbl.numberOfLines = 0;
    msgLbl.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:msgLbl];
    
    ZXGamingButton *btn = [[ZXGamingButton alloc] init];
    [btn setTitle:actTitle forState:UIControlStateNormal];
    if (isError) {
        btn.layer.borderColor = [ZXTheme neonCrimson].CGColor;
        [btn setTitleColor:[ZXTheme neonCrimson] forState:UIControlStateNormal];
        btn.glowLayer.backgroundColor = [[ZXTheme neonCrimson] colorWithAlphaComponent:0.15];
        btn.layer.shadowColor = [ZXTheme neonCrimson].CGColor;
    }
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:btn];
    
    [NSLayoutConstraint activateConstraints:@[
        [card.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
        [card.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [card.widthAnchor constraintEqualToConstant:320],
        
        [iconView.topAnchor constraintEqualToAnchor:card.topAnchor constant:30],
        [iconView.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [iconView.widthAnchor constraintEqualToConstant:40],
        [iconView.heightAnchor constraintEqualToConstant:40],
        
        [titleLbl.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:20],
        [titleLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [titleLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        
        [msgLbl.topAnchor constraintEqualToAnchor:titleLbl.bottomAnchor constant:12],
        [msgLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [msgLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        
        [btn.topAnchor constraintEqualToAnchor:msgLbl.bottomAnchor constant:30],
        [btn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [btn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [btn.heightAnchor constraintEqualToConstant:50],
        [btn.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20]
    ]];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissOverlay:)];
    [btn addTarget:self action:@selector(dismissBtnTapped:) forControlEvents:UIControlEventTouchUpInside];
    [overlay addGestureRecognizer:tap];
    
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid];
    [haptic impactOccurred];
    
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
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

#pragma mark - ================= MAIN CONTROLLER =================

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

@property (nonatomic, strong) UIImageView *radarIcon;
@property (nonatomic, strong) UILabel *glitchLabel;

@property (nonatomic, strong) ZXGamingField *keyInput;
@property (nonatomic, strong) ZXGamingButton *loginBtn;
@property (nonatomic, strong) UITapGestureRecognizer *dismissTap;

@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *expiryLabel;
@property (nonatomic, strong) UIScrollView *modulesScrollView;
@property (nonatomic, strong) UIStackView *modulesStackView; 
@property (nonatomic, strong) UIView *emptyStateView;

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
    
    [self setupCyberpunkBackground];
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
        [self runTerminalLaunchSequence];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopHeartbeatMonitor];
}

- (void)dismissKeyboard { [self.view endEditing:YES]; }

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

#pragma mark - Cyberpunk Background
- (void)setupCyberpunkBackground {
    // Hexagonal / Grid faint overlay
    UIView *grid = [[UIView alloc] initWithFrame:self.view.bounds];
    grid.backgroundColor = [UIColor colorWithPatternImage:[self createHexGridImage]];
    grid.alpha = 0.4;
    [self.view addSubview:grid];
    
    // Aggressive Light Flares
    UIView *cyanFlare = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 150, -100, 300, 300)];
    cyanFlare.backgroundColor = [[ZXTheme neonCyan] colorWithAlphaComponent:0.15];
    cyanFlare.layer.cornerRadius = 150;
    cyanFlare.layer.shadowColor = [ZXTheme neonCyan].CGColor;
    cyanFlare.layer.shadowRadius = 100;
    cyanFlare.layer.shadowOpacity = 1.0;
    [self.view addSubview:cyanFlare];
    
    UIView *redFlare = [[UIView alloc] initWithFrame:CGRectMake(-150, self.view.bounds.size.height - 200, 400, 400)];
    redFlare.backgroundColor = [[ZXTheme neonCrimson] colorWithAlphaComponent:0.1];
    redFlare.layer.cornerRadius = 200;
    redFlare.layer.shadowColor = [ZXTheme neonCrimson].CGColor;
    redFlare.layer.shadowRadius = 120;
    redFlare.layer.shadowOpacity = 1.0;
    [self.view addSubview:redFlare];
}

- (UIImage *)createHexGridImage {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(30, 30), NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:1.0 alpha:0.05].CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    CGContextMoveToPoint(ctx, 0, 0); CGContextAddLineToPoint(ctx, 30, 0);
    CGContextMoveToPoint(ctx, 0, 0); CGContextAddLineToPoint(ctx, 0, 30);
    CGContextStrokePath(ctx);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeTile];
}

#pragma mark - State Machine & Heartbeat (Auto-Logout Logic)
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
    [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.splashContainer.alpha = (newState == ZXAppStateSplash) ? 1.0 : 0.0;
        weakSelf.authContainer.alpha = (newState == ZXAppStateAuth) ? 1.0 : 0.0;
        weakSelf.verificationContainer.alpha = (newState == ZXAppStateVerifying) ? 1.0 : 0.0;
        weakSelf.dashboardContainer.alpha = (newState == ZXAppStateDashboard) ? 1.0 : 0.0;
    } completion:nil];
}

- (void)startHeartbeatMonitor {
    [self stopHeartbeatMonitor];
    // Ping every 15 seconds to check if Admin deleted the key
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
                    // Check if token was wiped completely (meaning REVOKED or EXPIRED, not just offline)
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
                        // User's key was deleted or expired -> Execute Auto-Logout Flow
                        [strongSelf handleRevokedSessionEnvironment];
                    }
                }
            });
        }];
    }
}

// THE CRITICAL AUTO-LOGOUT & MODULE KILL-SWITCH
- (void)handleRevokedSessionEnvironment {
    [self stopHeartbeatMonitor];
    
    // Visually force ALL active modules to OFF instantly
    for (UIView *card in self.modulesStackView.arrangedSubviews) {
        ZXGamingToggle *toggle = [self findToggleInCard:card];
        if (toggle) {
            toggle.userInteractionEnabled = NO; // Lock the user out of the toggle
            [toggle setOn:NO animated:YES];     // Slide to OFF
        }
    }
    
    // Show aggressive red alert
    [self showGlobalErrorWithTitle:@"ACCESS REVOKED" message:@"Your Zentrax VIP key has been deleted or expired by the administrator. Disconnecting..."];
    
    // Force logout process and kick to login screen
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

#pragma mark - Gaming Splash Sequence
- (void)setupSplash {
    _splashContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_splashContainer];
    
    // Radar / Target Icon
    _radarIcon = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"scope"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    _radarIcon.tintColor = [ZXTheme neonCyan];
    _radarIcon.contentMode = UIViewContentModeScaleAspectFit;
    _radarIcon.layer.shadowColor = [ZXTheme neonCyan].CGColor;
    _radarIcon.layer.shadowRadius = 25;
    _radarIcon.layer.shadowOpacity = 1.0;
    _radarIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_radarIcon];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"ZENTRAX VIP";
    title.textColor = [UIColor whiteColor];
    title.font = [ZXTheme fontDisplay:26];
    [ZXTheme applyTextTracking:title spacing:8.0];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:title];
    
    _glitchLabel = [[UILabel alloc] init];
    _glitchLabel.text = @"> ENGINE_INIT...";
    _glitchLabel.textColor = [ZXTheme neonCyan];
    _glitchLabel.font = [ZXTheme fontMono:12 weight:UIFontWeightBold];
    [ZXTheme applyTextTracking:_glitchLabel spacing:2.0];
    _glitchLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_glitchLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [_radarIcon.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [_radarIcon.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor constant:-60],
        [_radarIcon.widthAnchor constraintEqualToConstant:100],
        [_radarIcon.heightAnchor constraintEqualToConstant:100],
        
        [title.topAnchor constraintEqualToAnchor:_radarIcon.bottomAnchor constant:40],
        [title.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        
        [_glitchLabel.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:12],
        [_glitchLabel.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
    ]];
}

- (void)runTerminalLaunchSequence {
    self.currentState = ZXAppStateSplash;
    self.splashContainer.alpha = 1.0;
    
    // Spin the radar
    CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    spin.toValue = @(M_PI * 2);
    spin.duration = 2.0;
    spin.repeatCount = HUGE_VALF;
    [self.radarIcon.layer addAnimation:spin forKey:@"spin"];
    
    // Simulate terminal boot
    NSArray *texts = @[@"> BYPASSING_SANDBOX...", @"> INJECTING_DAEMON...", @"> SECURING_CONNECTION..."];
    for (int i=0; i<texts.count; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (0.5 * (i+1)) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if(self.currentState == ZXAppStateSplash) self.glitchLabel.text = texts[i];
        });
    }
    
    NSTimeInterval sequenceStartTime = CACurrentMediaTime();
    
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) {
        [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL isValid) {
            NSTimeInterval elapsed = CACurrentMediaTime() - sequenceStartTime;
            NSTimeInterval remainingDelay = MAX(0.0, 2.0 - elapsed);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, remainingDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self.radarIcon.layer removeAllAnimations];
                if (isValid) {
                    [self transitionToState:ZXAppStateDashboard];
                    [self showGamingToast:@"SESSION RESTORED" isError:NO];
                } else {
                    [self transitionToState:ZXAppStateAuth];
                }
            });
        }];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self.radarIcon.layer removeAllAnimations];
            [self transitionToState:ZXAppStateAuth];
        });
    }
}

#pragma mark - High-Tech Auth Flow
- (void)setupAuth {
    _authContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_authContainer];
    
    UILabel *headerSub = [[UILabel alloc] init];
    headerSub.text = @"[ ZENTRAX NETWORK ]";
    headerSub.textColor = [ZXTheme neonCyan];
    headerSub.font = [ZXTheme fontMono:12 weight:UIFontWeightBold];
    [ZXTheme applyTextTracking:headerSub spacing:3.0];
    headerSub.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:headerSub];
    
    UILabel *title = [[UILabel alloc] init];
    title.text = @"ACCESS PORTAL";
    title.textColor = [UIColor whiteColor];
    title.font = [ZXTheme fontDisplay:36];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:title];
    
    _keyInput = [[ZXGamingField alloc] init];
    _keyInput.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:_keyInput];
    
    _loginBtn = [[ZXGamingButton alloc] init];
    [_loginBtn setTitle:@"AUTHENTICATE" forState:UIControlStateNormal];
    [_loginBtn addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside];
    _loginBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:_loginBtn];
    
    [NSLayoutConstraint activateConstraints:@[
        [headerSub.topAnchor constraintEqualToAnchor:_authContainer.safeAreaLayoutGuide.topAnchor constant:80],
        [headerSub.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:32],
        
        [title.topAnchor constraintEqualToAnchor:headerSub.bottomAnchor constant:4],
        [title.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:32],
        
        [_keyInput.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:50],
        [_keyInput.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:32],
        [_keyInput.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-32],
        [_keyInput.heightAnchor constraintEqualToConstant:70],
        
        [_loginBtn.bottomAnchor constraintEqualToAnchor:_authContainer.safeAreaLayoutGuide.bottomAnchor constant:-40],
        [_loginBtn.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:32],
        [_loginBtn.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-32],
        [_loginBtn.heightAnchor constraintEqualToConstant:60],
    ]];
}

- (void)handleLogin {
    [self dismissKeyboard];
    NSString *key = [self.keyInput.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (key.length == 0) {
        [self showGamingToast:@"INVALID KEY DETECTED" isError:YES];
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
                    [strongSelf showGamingToast:@"ACCESS GRANTED" isError:NO];
                    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred];
                } else {
                    [strongSelf showGlobalErrorWithTitle:@"ACCESS DENIED" message:errorMsg ?: @"Key rejected by server node."];
                }
            });
        }];
    }
}

- (void)setupVerification {} // Unused in gaming setup, transition is instant

#pragma mark - Premium Gaming Dashboard
- (void)setupDashboard {
    _dashboardContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_dashboardContainer];
    
    UIView *navBar = [[UIView alloc] init];
    navBar.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:navBar];
    
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.text = @"ZENTRAX VIP";
    navTitle.textColor = [UIColor whiteColor];
    navTitle.font = [ZXTheme fontDisplay:20];
    [ZXTheme applyTextTracking:navTitle spacing:4.0];
    navTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [navBar addSubview:navTitle];
    
    UIButton *logoutBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [logoutBtn setImage:[[UIImage systemImageNamed:@"power"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    logoutBtn.tintColor = [ZXTheme neonCrimson];
    logoutBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [logoutBtn addTarget:self action:@selector(handleLogout) forControlEvents:UIControlEventTouchUpInside];
    [navBar addSubview:logoutBtn];
    
    // Status Card -> LICENSE STATUS
    UIView *statusCard = [[UIView alloc] init];
    [ZXTheme applyGamingCardStyle:statusCard];
    statusCard.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:statusCard];
    
    UILabel *subTitle = [[UILabel alloc] init];
    subTitle.text = @"[ LICENSE STATUS ]";
    subTitle.textColor = [ZXTheme neonCyan];
    subTitle.font = [ZXTheme fontMono:10 weight:UIFontWeightBold];
    [ZXTheme applyTextTracking:subTitle spacing:2.0];
    subTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:subTitle];
    
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.text = @"ACTIVE";
    _statusLabel.textColor = [UIColor whiteColor];
    _statusLabel.font = [ZXTheme fontDisplay:24];
    _statusLabel.layer.shadowColor = [ZXTheme neonCyan].CGColor;
    _statusLabel.layer.shadowRadius = 10;
    _statusLabel.layer.shadowOpacity = 0.8;
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_statusLabel];
    
    _expiryLabel = [[UILabel alloc] init];
    _expiryLabel.text = @"VALIDATING NODE...";
    _expiryLabel.textColor = [ZXTheme textMuted];
    _expiryLabel.font = [ZXTheme fontMono:11 weight:UIFontWeightBold];
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
        
        [navTitle.leadingAnchor constraintEqualToAnchor:navBar.leadingAnchor],
        [navTitle.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],
        
        [logoutBtn.trailingAnchor constraintEqualToAnchor:navBar.trailingAnchor],
        [logoutBtn.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],
        [logoutBtn.widthAnchor constraintEqualToConstant:32],
        [logoutBtn.heightAnchor constraintEqualToConstant:32],
        
        [statusCard.topAnchor constraintEqualToAnchor:navBar.bottomAnchor constant:20],
        [statusCard.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [statusCard.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [statusCard.heightAnchor constraintEqualToConstant:105],
        
        [subTitle.topAnchor constraintEqualToAnchor:statusCard.topAnchor constant:20],
        [subTitle.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:20],
        
        [_statusLabel.topAnchor constraintEqualToAnchor:subTitle.bottomAnchor constant:8],
        [_statusLabel.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:20],
        
        [_expiryLabel.topAnchor constraintEqualToAnchor:_statusLabel.bottomAnchor constant:6],
        [_expiryLabel.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:20],
        
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
    title.text = @"NO ACTIVE FEATURES";
    title.textColor = [ZXTheme textMuted];
    title.font = [ZXTheme fontDisplay:16];
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
        sectionHeader.text = @"// ACTIVE FEATURES";
        sectionHeader.textColor = [ZXTheme neonCyan];
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
            [ZXTheme applyGamingCardStyle:card];
            card.translatesAutoresizingMaskIntoConstraints = NO;
            
            UILabel *t = [[UILabel alloc] init];
            t.text = [moduleName uppercaseString];
            t.textColor = [UIColor whiteColor];
            t.font = [ZXTheme fontHeading:16];
            t.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:t];
            
            UILabel *s = [[UILabel alloc] init];
            s.text = moduleDesc;
            s.textColor = [ZXTheme textSecondary];
            s.font = [ZXTheme fontBody:12 weight:UIFontWeightRegular];
            s.numberOfLines = 0;
            s.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:s];
            
            ZXGamingToggle *toggle = [[ZXGamingToggle alloc] init];
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
            self.expiryLabel.text = @"EXPIRES: LIFETIME ACCESS";
            self.expiryLabel.textColor = [ZXTheme neonCyan];
        } else if (expiryStr) {
            self.expiryLabel.text = [[NSString stringWithFormat:@"EXPIRES: %@", expiryStr] uppercaseString];
            self.expiryLabel.textColor = [ZXTheme textSecondary];
        } else {
            self.expiryLabel.text = @"NO EXPIRY DATA";
        }
        self.statusLabel.text = [subData[@"status"] uppercaseString] ?: @"ACTIVE";
    });
}

- (ZXGamingToggle *)findToggleInCard:(UIView *)card {
    for (UIView *sub in card.subviews) {
        if ([sub isKindOfClass:[ZXGamingToggle class]]) return (ZXGamingToggle *)sub;
    }
    return nil;
}

- (void)moduleToggled:(ZXGamingToggle *)sender {
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
                    NSString *toastMsg = requestedState ? @"MODULE INJECTED" : @"MODULE REVERTED";
                    [strongSelf showGamingToast:toastMsg isError:NO];
                } else {
                    [sender setOn:!requestedState animated:YES];
                    [strongSelf showGlobalErrorWithTitle:@"INJECTION FAILED" message:errorMsg ?: @"Failed to inject execution payload safely."];
                }
            });
        }];
    }
}

#pragma mark - Premium Gaming Toast
- (void)showGamingToast:(NSString *)msg isError:(BOOL)isError {
    for (UIView *v in self.view.subviews) {
        if (v.tag == 887766) [v removeFromSuperview];
    }
    
    UIColor *tint = isError ? [ZXTheme neonCrimson] : [ZXTheme neonCyan];
    CGFloat toastWidth = 260;
    CGFloat toastHeight = 44;
    
    UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
    CGFloat topInset = window.safeAreaInsets.top;
    if (topInset == 0) topInset = 45; 
    
    UIView *toast = [[UIView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - toastWidth)/2, -60, toastWidth, toastHeight)];
    toast.tag = 887766;
    toast.backgroundColor = [ZXTheme bgCardOuter];
    toast.layer.cornerRadius = 8;
    toast.layer.borderWidth = 1.5;
    toast.layer.borderColor = tint.CGColor;
    toast.layer.shadowColor = tint.CGColor;
    toast.layer.shadowOpacity = 0.6;
    toast.layer.shadowRadius = 15;
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:toast.bounds];
    lbl.text = msg;
    lbl.textColor = [UIColor whiteColor];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.font = [ZXTheme fontDisplay:12];
    [ZXTheme applyTextTracking:lbl spacing:1.5];
    [toast addSubview:lbl];
    
    [self.view addSubview:toast];
    
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:isError ? UIImpactFeedbackStyleHeavy : UIImpactFeedbackStyleSoft] impactOccurred];
    
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
        [ZXModalManager showModalWithIcon:@"xmark.octagon.fill" isError:YES title:title message:msg actionTitle:@"DISMISS" inView:self.view];
    });
}
- (void)showSuccessMessage:(NSString *)title message:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        [ZXModalManager showModalWithIcon:@"checkmark.shield.fill" isError:NO title:title message:msg actionTitle:@"CONTINUE" inView:self.view];
    });
}
- (void)showNetworkError { [self showGamingToast:@"NETWORK CONNECTION LOST" isError:YES]; }
- (void)showServerError { [self showGamingToast:@"SERVER UNAVAILABLE" isError:YES]; }
- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds {
    NSString *msg = [NSString stringWithFormat:@"Request limits reached. Cooldown active for %ld seconds.", (long)seconds];
    dispatch_async(dispatch_get_main_queue(), ^{
        [ZXModalManager showModalWithIcon:@"timer" isError:YES title:@"RATE LIMITED" message:msg actionTitle:@"UNDERSTOOD" inView:self.view];
    });
}
- (void)showGlobalLoadingState:(NSString *)message {}
- (void)hideGlobalLoadingState {}

@end
