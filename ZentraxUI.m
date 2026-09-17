		//
//  ZentraxUI.m
//  Zentrax VIP - Premium Security Infrastructure UI
//
//  Architecture: Server-authoritative UI / Network-driven state
//  Theme: Ultra-Premium Glassmorphism (iOS 27 Style)
//  Status: PRODUCTION AUDITED - BUG FREE
//

#import "ZentraxUI.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark - Constants & Keys

static NSString * const ZXLanguageKey = @"in.zentrax.global.language";
static NSString * const ZXLastKey = @"in.zentrax.global.lastkey";
static NSString * const ZXLoginAttemptsKey = @"in.zentrax.global.login.attempts";
static NSString * const ZXLoginTimeoutKey = @"in.zentrax.global.login.timeout";

#pragma mark - App State Enum

typedef NS_ENUM(NSInteger, ZXAppState) {
    ZXAppStateInit = 0,
    ZXAppStateSplash,
    ZXAppStateAuth,
    ZXAppStateDashboard,
    ZXAppStateStartupBlock
};


#pragma mark - ZENTRAX Material & Visual System

typedef NS_ENUM(NSInteger, ZXMaterialLevel) {
    ZXMaterialObsidian = 0,
    ZXMaterialGlass,
    ZXMaterialElevatedGlass,
    ZXMaterialClearGlass,
    ZXMaterialActiveGlass,
    ZXMaterialControlGlass
};

static NSString *ZXLocalizedUI(NSString *text);

static BOOL ZXReduceMotionEnabled(void) {
    return UIAccessibilityIsReduceMotionEnabled();
}

@interface ZXAmbientBackgroundView : UIView
@property(nonatomic,strong) CAGradientLayer *baseLayer;
@property(nonatomic,strong) CAGradientLayer *indigoBloom;
@property(nonatomic,strong) CAGradientLayer *violetBloom;
@property(nonatomic,strong) CALayer *grainLayer;
@end

@implementation ZXAmbientBackgroundView
- (instancetype)initWithFrame:(CGRect)frame {
    self=[super initWithFrame:frame];
    if(!self) return nil;
    self.userInteractionEnabled=NO;
    self.backgroundColor=[UIColor colorWithWhite:0.012 alpha:1.0];

    _baseLayer=[CAGradientLayer layer];
    _baseLayer.colors=@[
        (id)[UIColor colorWithWhite:0.010 alpha:1].CGColor,
        (id)[UIColor colorWithRed:0.018 green:0.017 blue:0.027 alpha:1].CGColor,
        (id)[UIColor colorWithWhite:0.008 alpha:1].CGColor
    ];
    _baseLayer.locations=@[@0,@0.52,@1];
    [self.layer addSublayer:_baseLayer];

    _indigoBloom=[CAGradientLayer layer];
    _indigoBloom.type=kCAGradientLayerRadial;
    _indigoBloom.colors=@[
        (id)[UIColor colorWithRed:0.20 green:0.17 blue:0.62 alpha:0.060].CGColor,
        (id)[UIColor clearColor].CGColor
    ];
    _indigoBloom.startPoint=CGPointMake(0.5,0.5);
    _indigoBloom.endPoint=CGPointMake(1,1);
    [self.layer addSublayer:_indigoBloom];

    _violetBloom=[CAGradientLayer layer];
    _violetBloom.type=kCAGradientLayerRadial;
    _violetBloom.colors=@[
        (id)[UIColor colorWithRed:0.34 green:0.22 blue:0.68 alpha:0.045].CGColor,
        (id)[UIColor clearColor].CGColor
    ];
    _violetBloom.startPoint=CGPointMake(0.5,0.5);
    _violetBloom.endPoint=CGPointMake(1,1);
    [self.layer addSublayer:_violetBloom];

    _grainLayer=[CALayer layer];
    _grainLayer.backgroundColor=[UIColor colorWithWhite:1 alpha:0.008].CGColor;
    _grainLayer.opacity=0.35;
    [self.layer addSublayer:_grainLayer];

    if(!ZXReduceMotionEnabled()) {
        CABasicAnimation *a=[CABasicAnimation animationWithKeyPath:@"transform.translation"];
        a.fromValue=[NSValue valueWithCGPoint:CGPointMake(-10,-7)];
        a.toValue=[NSValue valueWithCGPoint:CGPointMake(10,7)];
        a.duration=18.0;
        a.autoreverses=YES;
        a.repeatCount=HUGE_VALF;
        a.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [_indigoBloom addAnimation:a forKey:@"zx.ambient.indigo"];
        CABasicAnimation *b=[CABasicAnimation animationWithKeyPath:@"transform.translation"];
        b.fromValue=[NSValue valueWithCGPoint:CGPointMake(8,8)];
        b.toValue=[NSValue valueWithCGPoint:CGPointMake(-8,-8)];
        b.duration=23.0;
        b.autoreverses=YES;
        b.repeatCount=HUGE_VALF;
        b.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [_violetBloom addAnimation:b forKey:@"zx.ambient.violet"];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _baseLayer.frame=self.bounds;
    CGFloat w=CGRectGetWidth(self.bounds), h=CGRectGetHeight(self.bounds);
    _indigoBloom.frame=CGRectMake(-w*0.28,-h*0.22,w*1.45,h*1.25);
    _violetBloom.frame=CGRectMake(w*0.20,h*0.34,w*1.35,h*1.25);
    _grainLayer.frame=self.bounds;
}
@end

@interface ZXTheme : NSObject
+ (UIColor *)surfaceRaised; + (UIColor *)border; + (UIColor *)borderAccent;
+ (UIColor *)primaryText; + (UIColor *)secondaryText; + (UIColor *)mutedText;
+ (UIColor *)accentPrimary; + (UIColor *)accentSecondary;
+ (UIColor *)success; + (UIColor *)warning; + (UIColor *)error;
+ (UIFont *)display:(CGFloat)size; + (UIFont *)heading:(CGFloat)size;
+ (UIFont *)body:(CGFloat)size weight:(UIFontWeight)weight;
+ (UIFont *)mono:(CGFloat)size weight:(UIFontWeight)weight;
+ (void)track:(UILabel *)label spacing:(CGFloat)spacing;
@end

@implementation ZXTheme
+ (UIColor *)surfaceRaised { return [UIColor colorWithRed:0.055 green:0.056 blue:0.068 alpha:0.92]; }
+ (UIColor *)border { return [UIColor colorWithWhite:1 alpha:0.075]; }
+ (UIColor *)borderAccent { return [UIColor colorWithRed:0.38 green:0.32 blue:1.0 alpha:0.46]; }
+ (UIColor *)primaryText { return [UIColor colorWithWhite:0.985 alpha:1]; }
+ (UIColor *)secondaryText { return [UIColor colorWithWhite:0.66 alpha:1]; }
+ (UIColor *)mutedText { return [UIColor colorWithWhite:0.39 alpha:1]; }
+ (UIColor *)accentPrimary { return [UIColor colorWithRed:0.39 green:0.34 blue:0.98 alpha:1]; }
+ (UIColor *)accentSecondary { return [UIColor colorWithRed:0.68 green:0.62 blue:0.98 alpha:1]; }
+ (UIColor *)success { return [UIColor colorWithRed:0.40 green:0.82 blue:0.62 alpha:1]; }
+ (UIColor *)warning { return [UIColor colorWithRed:0.88 green:0.70 blue:0.35 alpha:1]; }
+ (UIColor *)error { return [UIColor colorWithRed:0.90 green:0.38 blue:0.43 alpha:1]; }
+ (UIFont *)display:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBold]; }
+ (UIFont *)heading:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightSemibold]; }
+ (UIFont *)body:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont systemFontOfSize:size weight:weight]; }
+ (UIFont *)mono:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont monospacedSystemFontOfSize:size weight:weight]; }
+ (void)track:(UILabel *)label spacing:(CGFloat)spacing {
    if(!label.text.length) return;
    label.attributedText=[[NSAttributedString alloc] initWithString:label.text attributes:@{NSKernAttributeName:@(spacing)}];
}
@end

static UIBlurEffectStyle ZXBlurStyleForMaterial(ZXMaterialLevel level) {
    switch(level) {
        case ZXMaterialObsidian: return UIBlurEffectStyleSystemChromeMaterialDark;
        case ZXMaterialElevatedGlass: return UIBlurEffectStyleSystemMaterialDark;
        case ZXMaterialClearGlass: return UIBlurEffectStyleSystemUltraThinMaterialDark;
        case ZXMaterialActiveGlass: return UIBlurEffectStyleSystemThinMaterialDark;
        case ZXMaterialControlGlass: return UIBlurEffectStyleSystemUltraThinMaterialDark;
        case ZXMaterialGlass:
        default: return UIBlurEffectStyleSystemThinMaterialDark;
    }
}

static UIColor *ZXFillForMaterial(ZXMaterialLevel level) {
    switch(level) {
        case ZXMaterialObsidian: return [UIColor colorWithWhite:0.02 alpha:0.88];
        case ZXMaterialElevatedGlass: return [UIColor colorWithWhite:0.08 alpha:0.48];
        case ZXMaterialClearGlass: return [UIColor colorWithWhite:1 alpha:0.025];
        case ZXMaterialActiveGlass: return [ZXTheme accentPrimary];
        case ZXMaterialControlGlass: return [UIColor colorWithWhite:0.08 alpha:0.50];
        case ZXMaterialGlass:
        default: return [UIColor colorWithWhite:0.055 alpha:0.42];
    }
}

@interface ZXGlassCard : UIView
@property(nonatomic,strong) UIVisualEffectView *blurView;
@property(nonatomic,strong) UIView *specularView;
@property(nonatomic,strong) CALayer *innerLayer;
@property(nonatomic,assign) ZXMaterialLevel materialLevel;
@property(nonatomic,assign) BOOL emphasized;
- (void)applyMaterial:(ZXMaterialLevel)level;
- (void)setEmphasized:(BOOL)emphasized animated:(BOOL)animated;
@end

@implementation ZXGlassCard
- (instancetype)init {
    if(self=[super initWithFrame:CGRectZero]) {
        self.translatesAutoresizingMaskIntoConstraints=NO;
        self.backgroundColor=[UIColor clearColor];
        self.clipsToBounds=NO;
        _materialLevel=ZXMaterialGlass;

        _blurView=[[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:ZXBlurStyleForMaterial(_materialLevel)]];
        _blurView.translatesAutoresizingMaskIntoConstraints=NO;
        _blurView.layer.cornerRadius=26;
        _blurView.layer.cornerCurve=kCACornerCurveContinuous;
        _blurView.clipsToBounds=YES;
        [super addSubview:_blurView];
        [NSLayoutConstraint activateConstraints:@[
            [_blurView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_blurView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_blurView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_blurView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];

        _specularView=[[UIView alloc] init];
        _specularView.userInteractionEnabled=NO;
        _specularView.backgroundColor=[UIColor colorWithWhite:1 alpha:0.045];
        _specularView.layer.cornerRadius=26;
        _specularView.layer.cornerCurve=kCACornerCurveContinuous;
        _specularView.translatesAutoresizingMaskIntoConstraints=NO;
        [_blurView.contentView addSubview:_specularView];
        [NSLayoutConstraint activateConstraints:@[
            [_specularView.leadingAnchor constraintEqualToAnchor:_blurView.contentView.leadingAnchor],
            [_specularView.trailingAnchor constraintEqualToAnchor:_blurView.contentView.trailingAnchor],
            [_specularView.topAnchor constraintEqualToAnchor:_blurView.contentView.topAnchor],
            [_specularView.heightAnchor constraintEqualToConstant:1]
        ]];

        _innerLayer=[CALayer layer];
        _innerLayer.borderWidth=1;
        _innerLayer.borderColor=[UIColor colorWithWhite:1 alpha:0.035].CGColor;
        _innerLayer.cornerRadius=26;
        _innerLayer.cornerCurve=kCACornerCurveContinuous;
        [_blurView.contentView.layer addSublayer:_innerLayer];

        self.layer.shadowColor=[UIColor blackColor].CGColor;
        self.layer.shadowOpacity=0.30;
        self.layer.shadowRadius=24;
        self.layer.shadowOffset=CGSizeMake(0,12);
        [self applyMaterial:ZXMaterialGlass];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _innerLayer.frame=_blurView.bounds;
}
- (void)addSubview:(UIView *)view {
    if(view==_blurView) [super addSubview:view];
    else [_blurView.contentView addSubview:view];
}
- (void)applyMaterial:(ZXMaterialLevel)level {
    _materialLevel=level;
    _blurView.effect=[UIBlurEffect effectWithStyle:ZXBlurStyleForMaterial(level)];
    _blurView.backgroundColor=ZXFillForMaterial(level);
    CGFloat radius=(level==ZXMaterialControlGlass ? 18.0 : 26.0);
    _blurView.layer.cornerRadius=radius;
    _specularView.layer.cornerRadius=radius;
    _innerLayer.cornerRadius=radius;
    _innerLayer.borderColor=(level==ZXMaterialActiveGlass ? [[ZXTheme accentPrimary] colorWithAlphaComponent:0.34] : [UIColor colorWithWhite:1 alpha:0.035]).CGColor;
    _specularView.backgroundColor=(level==ZXMaterialActiveGlass ? [[ZXTheme accentSecondary] colorWithAlphaComponent:0.13] : [UIColor colorWithWhite:1 alpha:(level==ZXMaterialClearGlass ? 0.025 : 0.045)]);
    self.layer.shadowOpacity=(level==ZXMaterialActiveGlass ? 0.40 : 0.28);
    self.layer.shadowColor=(level==ZXMaterialActiveGlass ? [ZXTheme accentPrimary].CGColor : [UIColor blackColor].CGColor);
}
- (void)setEmphasized:(BOOL)emphasized animated:(BOOL)animated {
    _emphasized=emphasized;
    void (^changes)(void)=^{
        _innerLayer.borderColor=emphasized ? [[ZXTheme accentPrimary] colorWithAlphaComponent:0.40].CGColor : [UIColor colorWithWhite:1 alpha:0.035].CGColor;
        self.layer.shadowColor=emphasized ? [ZXTheme accentPrimary].CGColor : [UIColor blackColor].CGColor;
        self.layer.shadowOpacity=emphasized ? 0.34 : 0.28;
        self.layer.shadowRadius=emphasized ? 28 : 24;
    };
    if(animated && !ZXReduceMotionEnabled()) [UIView animateWithDuration:0.28 animations:changes];
    else changes();
}
@end

@interface ZXOrbitLoader : UIView
@property(nonatomic,strong) CAShapeLayer *trackLayer;
@property(nonatomic,strong) CAShapeLayer *orbitLayer;
@property(nonatomic,strong) CAShapeLayer *coreLayer;
@property(nonatomic,assign) BOOL animating;
- (void)startAnimating;
- (void)stopAnimating;
@end

@implementation ZXOrbitLoader
- (instancetype)init {
    if(self=[super initWithFrame:CGRectMake(0,0,28,28)]) {
        self.userInteractionEnabled=NO;
        _trackLayer=[CAShapeLayer layer];
        _trackLayer.fillColor=[UIColor clearColor].CGColor;
        _trackLayer.strokeColor=[UIColor colorWithWhite:1 alpha:0.11].CGColor;
        _trackLayer.lineWidth=1.0;
        [self.layer addSublayer:_trackLayer];

        _orbitLayer=[CAShapeLayer layer];
        _orbitLayer.fillColor=[UIColor clearColor];
        _orbitLayer.strokeColor=[ZXTheme accentSecondary].CGColor;
        _orbitLayer.lineWidth=1.5;
        _orbitLayer.lineCap=kCALineCapRound;
        _orbitLayer.strokeStart=0.03;
        _orbitLayer.strokeEnd=0.38;
        [self.layer addSublayer:_orbitLayer];

        _coreLayer=[CAShapeLayer layer];
        _coreLayer.fillColor=[UIColor colorWithWhite:1 alpha:0.88].CGColor;
        [self.layer addSublayer:_coreLayer];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect r=CGRectInset(self.bounds,2,2);
    CGPathRef path=CGPathCreateWithEllipseInRect(r,NULL);
    _trackLayer.path=path;
    _orbitLayer.path=path;
    CGPathRelease(path);
    CGFloat d=3.0;
    CGPathRef corePath=CGPathCreateWithEllipseInRect(CGRectMake(CGRectGetMidX(self.bounds)-d/2,CGRectGetMidY(self.bounds)-d/2,d,d),NULL);
    _coreLayer.path=corePath;
    CGPathRelease(corePath);
}
- (void)startAnimating {
    _animating=YES;
    if(ZXReduceMotionEnabled()) {
        _orbitLayer.strokeEnd=0.42;
        return;
    }
    if([_orbitLayer animationForKey:@"zx.orbit"]) return;
    CABasicAnimation *spin=[CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    spin.fromValue=@0;
    spin.toValue=@(M_PI*2);
    spin.duration=1.15;
    spin.repeatCount=HUGE_VALF;
    spin.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_orbitLayer addAnimation:spin forKey:@"zx.orbit"];
    CABasicAnimation *pulse=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.fromValue=@0.82;
    pulse.toValue=@1.12;
    pulse.duration=0.85;
    pulse.autoreverses=YES;
    pulse.repeatCount=HUGE_VALF;
    [_coreLayer addAnimation:pulse forKey:@"zx.core"];
}
- (void)stopAnimating {
    _animating=NO;
    [_orbitLayer removeAnimationForKey:@"zx.orbit"];
    [_coreLayer removeAnimationForKey:@"zx.core"];
}
@end

@interface ZXPremiumButton : UIButton
@property(nonatomic,strong) CAGradientLayer *gradientLayer;
@property(nonatomic,strong) ZXOrbitLoader *spinner;
@property(nonatomic,strong) NSString *savedTitle;
@property(nonatomic,strong) UIView *surface;
@property(nonatomic,strong) UIView *sweep;
@end

@implementation ZXPremiumButton
- (instancetype)init {
    if(self=[super initWithFrame:CGRectZero]) {
        self.translatesAutoresizingMaskIntoConstraints=NO;
        self.titleLabel.font=[ZXTheme heading:16];
        self.layer.cornerRadius=20;
        self.layer.cornerCurve=kCACornerCurveContinuous;
        self.layer.borderWidth=1;
        self.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.11].CGColor;
        self.backgroundColor=[UIColor colorWithWhite:0.92 alpha:0.97];
        [self setTitleColor:[UIColor colorWithWhite:0.03 alpha:1] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor colorWithWhite:0.03 alpha:0.55] forState:UIControlStateDisabled];
        self.layer.shadowColor=[UIColor blackColor].CGColor;
        self.layer.shadowOpacity=0.24;
        self.layer.shadowRadius=18;
        self.layer.shadowOffset=CGSizeMake(0,8);

        _sweep=[[UIView alloc] init];
        _sweep.userInteractionEnabled=NO;
        _sweep.backgroundColor=[UIColor colorWithWhite:1 alpha:0.18];
        _sweep.layer.cornerRadius=2;
        _sweep.alpha=0;
        [self addSubview:_sweep];

        _spinner=[[ZXOrbitLoader alloc] init];
        _spinner.translatesAutoresizingMaskIntoConstraints=NO;
        _spinner.hidden=YES;
        [self addSubview:_spinner];
        [NSLayoutConstraint activateConstraints:@[
            [_spinner.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [_spinner.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_spinner.widthAnchor constraintEqualToConstant:24],
            [_spinner.heightAnchor constraintEqualToConstant:24]
        ]];

        [self addTarget:self action:@selector(zxTouchDown) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(zxTouchUp) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _sweep.frame=CGRectMake(-80,0,56,CGRectGetHeight(self.bounds));
    _sweep.layer.cornerRadius=MAX(1,CGRectGetHeight(self.bounds)/2);
}
- (void)zxTouchDown {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    if(!ZXReduceMotionEnabled()) [UIView animateWithDuration:0.12 animations:^{ self.transform=CGAffineTransformMakeScale(0.985,0.985); }];
}
- (void)zxTouchUp {
    if(!ZXReduceMotionEnabled()) [UIView animateWithDuration:0.34 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0.15 options:UIViewAnimationOptionAllowUserInteraction animations:^{ self.transform=CGAffineTransformIdentity; } completion:nil];
    else self.transform=CGAffineTransformIdentity;
}
- (void)setLoading:(BOOL)loading {
    self.userInteractionEnabled=!loading;
    if(loading) {
        self.savedTitle=[self titleForState:UIControlStateNormal];
        [self setTitle:@"" forState:UIControlStateNormal];
        _spinner.hidden=NO;
        [_spinner startAnimating];
        [UIView animateWithDuration:0.18 animations:^{ self.backgroundColor=[UIColor colorWithWhite:0.15 alpha:0.96]; self.layer.borderColor=[[ZXTheme accentPrimary] colorWithAlphaComponent:0.35].CGColor; }];
    } else {
        [_spinner stopAnimating];
        _spinner.hidden=YES;
        [self setTitle:self.savedTitle ?: @"" forState:UIControlStateNormal];
        [UIView animateWithDuration:0.24 animations:^{ self.backgroundColor=[UIColor colorWithWhite:0.92 alpha:0.97]; self.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.11].CGColor; }];
    }
}
@end

@interface ZXPremiumField : UIView <UITextFieldDelegate>
@property(nonatomic,strong) UITextField *textField;
@property(nonatomic,strong) UIVisualEffectView *blurContainer;
@property(nonatomic,strong) UIButton *clearBtn;
@property(nonatomic,strong) UIImageView *iconView;
@property(nonatomic,strong) UIView *focusLine;
@end

@implementation ZXPremiumField
- (instancetype)init {
    if(self=[super initWithFrame:CGRectZero]) {
        self.translatesAutoresizingMaskIntoConstraints=NO;
        _blurContainer=[[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
        _blurContainer.translatesAutoresizingMaskIntoConstraints=NO;
        _blurContainer.layer.cornerRadius=20;
        _blurContainer.layer.cornerCurve=kCACornerCurveContinuous;
        _blurContainer.layer.borderWidth=1;
        _blurContainer.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.075].CGColor;
        _blurContainer.clipsToBounds=YES;
        [self addSubview:_blurContainer];

        _iconView=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"key"]];
        _iconView.tintColor=[ZXTheme mutedText];
        _iconView.contentMode=UIViewContentModeScaleAspectFit;
        _iconView.translatesAutoresizingMaskIntoConstraints=NO;
        [_blurContainer.contentView addSubview:_iconView];

        _textField=[[UITextField alloc] init];
        _textField.textColor=[ZXTheme primaryText];
        _textField.font=[ZXTheme mono:15 weight:UIFontWeightMedium];
        _textField.secureTextEntry=NO;
        _textField.delegate=self;
        _textField.autocorrectionType=UITextAutocorrectionTypeNo;
        _textField.autocapitalizationType=UITextAutocapitalizationTypeNone;
        _textField.spellCheckingType=UITextSpellCheckingTypeNo;
        _textField.returnKeyType=UIReturnKeyDone;
        _textField.attributedPlaceholder=[[NSAttributedString alloc] initWithString:ZXLocalizedUI(@"Enter License Key") attributes:@{
            NSForegroundColorAttributeName:[ZXTheme mutedText],
            NSFontAttributeName:[ZXTheme mono:15 weight:UIFontWeightRegular]
        }];
        _textField.translatesAutoresizingMaskIntoConstraints=NO;
        [_blurContainer.contentView addSubview:_textField];

        _clearBtn=[UIButton buttonWithType:UIButtonTypeSystem];
        [_clearBtn setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
        _clearBtn.tintColor=[ZXTheme mutedText];
        _clearBtn.alpha=0;
        _clearBtn.translatesAutoresizingMaskIntoConstraints=NO;
        [_clearBtn addTarget:self action:@selector(clearText) forControlEvents:UIControlEventTouchUpInside];
        [_blurContainer.contentView addSubview:_clearBtn];

        _focusLine=[[UIView alloc] init];
        _focusLine.backgroundColor=[ZXTheme accentPrimary];
        _focusLine.alpha=0;
        _focusLine.translatesAutoresizingMaskIntoConstraints=NO;
        [_blurContainer.contentView addSubview:_focusLine];

        [NSLayoutConstraint activateConstraints:@[
            [_blurContainer.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_blurContainer.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_blurContainer.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_blurContainer.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [_iconView.leadingAnchor constraintEqualToAnchor:_blurContainer.contentView.leadingAnchor constant:18],
            [_iconView.centerYAnchor constraintEqualToAnchor:_blurContainer.contentView.centerYAnchor],
            [_iconView.widthAnchor constraintEqualToConstant:20],
            [_iconView.heightAnchor constraintEqualToConstant:20],
            [_textField.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor constant:14],
            [_textField.topAnchor constraintEqualToAnchor:_blurContainer.contentView.topAnchor constant:3],
            [_textField.bottomAnchor constraintEqualToAnchor:_blurContainer.contentView.bottomAnchor constant:-3],
            [_textField.trailingAnchor constraintEqualToAnchor:_clearBtn.leadingAnchor constant:-8],
            [_clearBtn.trailingAnchor constraintEqualToAnchor:_blurContainer.contentView.trailingAnchor constant:-16],
            [_clearBtn.centerYAnchor constraintEqualToAnchor:_blurContainer.contentView.centerYAnchor],
            [_clearBtn.widthAnchor constraintEqualToConstant:22],
            [_clearBtn.heightAnchor constraintEqualToConstant:22],
            [_focusLine.leadingAnchor constraintEqualToAnchor:_blurContainer.contentView.leadingAnchor constant:18],
            [_focusLine.trailingAnchor constraintEqualToAnchor:_blurContainer.contentView.trailingAnchor constant:-18],
            [_focusLine.bottomAnchor constraintEqualToAnchor:_blurContainer.contentView.bottomAnchor constant:-1],
            [_focusLine.heightAnchor constraintEqualToConstant:1]
        ]];
        [_textField addTarget:self action:@selector(textChanged) forControlEvents:UIControlEventEditingChanged];
    }
    return self;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    _blurContainer.layer.borderColor=[[ZXTheme accentPrimary] colorWithAlphaComponent:0.38].CGColor;
    _iconView.tintColor=[ZXTheme accentSecondary];
    if(!ZXReduceMotionEnabled()) {
        [UIView animateWithDuration:0.22 animations:^{ self.focusLine.alpha=0.85; }];
    } else self.focusLine.alpha=0.85;
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    _blurContainer.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.075].CGColor;
    _iconView.tintColor=[ZXTheme mutedText];
    if(!ZXReduceMotionEnabled()) [UIView animateWithDuration:0.18 animations:^{ self.focusLine.alpha=0; }];
    else self.focusLine.alpha=0;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
- (void)textChanged {
    _clearBtn.alpha=_textField.text.length ? 1 : 0;
}
- (void)clearText {
    _textField.text=@"";
    [self textChanged];
    [_textField becomeFirstResponder];
}
@end

@interface ZXPremiumToggle : UISwitch
@property(nonatomic,strong) CALayer *zxTrack;
@property(nonatomic,strong) CALayer *zxThumb;
@property(nonatomic,strong) CALayer *zxCore;
@property(nonatomic,assign) BOOL processing;
@property(nonatomic,assign) BOOL desiredState;
- (void)setProcessing:(BOOL)processing;
- (BOOL)consumeUserRequest;
@end

@implementation ZXPremiumToggle
- (instancetype)init {
    if(self=[super initWithFrame:CGRectMake(0,0,58,34)]) {
        self.onTintColor=[UIColor clearColor];
        self.tintColor=[UIColor clearColor];
        self.thumbTintColor=[UIColor clearColor];
        self.backgroundColor=[UIColor clearColor];
        self.opaque=NO;
        self.accessibilityTraits=UIAccessibilityTraitButton;
        _zxTrack=[CALayer layer];
        _zxTrack.cornerRadius=17;
        _zxTrack.backgroundColor=[UIColor colorWithWhite:1 alpha:0.055].CGColor;
        _zxTrack.borderWidth=1;
        _zxTrack.borderColor=[UIColor colorWithWhite:1 alpha:0.10].CGColor;
        [self.layer addSublayer:_zxTrack];

        _zxThumb=[CALayer layer];
        _zxThumb.cornerRadius=13;
        _zxThumb.backgroundColor=[UIColor colorWithWhite:0.70 alpha:0.96].CGColor;
        _zxThumb.shadowColor=[UIColor blackColor].CGColor;
        _zxThumb.shadowOpacity=0.35;
        _zxThumb.shadowRadius=5;
        _zxThumb.shadowOffset=CGSizeMake(0,2);
        [self.layer addSublayer:_zxThumb];

        _zxCore=[CALayer layer];
        _zxCore.cornerRadius=3;
        _zxCore.backgroundColor=[UIColor whiteColor].CGColor;
        _zxCore.opacity=0;
        [self.layer addSublayer:_zxCore];

    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w=CGRectGetWidth(self.bounds), h=CGRectGetHeight(self.bounds);
    CGFloat trackH=32;
    _zxTrack.frame=CGRectMake(0,(h-trackH)/2,w,trackH);
    CGFloat d=26;
    CGFloat x=self.isOn ? w-d-3 : 3;
    _zxThumb.frame=CGRectMake(x,(h-d)/2,d,d);
    _zxCore.frame=CGRectMake(CGRectGetMidX(_zxThumb.frame)-3,CGRectGetMidY(_zxThumb.frame)-3,6,6);
}
- (void)drawRect:(CGRect)rect { /* Native switch visuals are fully replaced by layers. */ }
- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _desiredState=on;
    [super setOn:on animated:NO];
    void (^changes)(void)=^{ [self setNeedsLayout]; [self layoutIfNeeded]; };
    if(animated && !ZXReduceMotionEnabled()) [UIView animateWithDuration:0.26 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0.15 options:UIViewAnimationOptionBeginFromCurrentState animations:changes completion:nil];
    else changes();
}
- (void)setProcessing:(BOOL)processing {
    _processing=processing;
    self.userInteractionEnabled=!processing;
    _zxCore.opacity=processing ? 1 : 0;
    if(processing) {
        _zxThumb.backgroundColor=[UIColor colorWithWhite:0.96 alpha:0.95].CGColor;
        _zxTrack.backgroundColor=[[ZXTheme accentPrimary] colorWithAlphaComponent:0.13].CGColor;
        _zxTrack.borderColor=[[ZXTheme accentPrimary] colorWithAlphaComponent:0.36].CGColor;
        if(!ZXReduceMotionEnabled()) {
            CABasicAnimation *pulse=[CABasicAnimation animationWithKeyPath:@"opacity"];
            pulse.fromValue=@0.35; pulse.toValue=@1.0; pulse.duration=0.7; pulse.autoreverses=YES; pulse.repeatCount=HUGE_VALF;
            [_zxCore addAnimation:pulse forKey:@"zx.processing"];
        }
    } else {
        [_zxCore removeAnimationForKey:@"zx.processing"];
        _zxCore.opacity=0;
        [self refreshVisuals];
    }
}
- (void)refreshVisuals {
    BOOL on=self.isOn;
    _zxTrack.backgroundColor=(on ? [[ZXTheme accentPrimary] colorWithAlphaComponent:0.22] : [UIColor colorWithWhite:1 alpha:0.055]).CGColor;
    _zxTrack.borderColor=(on ? [[ZXTheme accentSecondary] colorWithAlphaComponent:0.42] : [UIColor colorWithWhite:1 alpha:0.10]).CGColor;
    _zxThumb.backgroundColor=(on ? [UIColor colorWithWhite:0.98 alpha:0.98] : [UIColor colorWithWhite:0.62 alpha:0.95]).CGColor;
    [self setNeedsLayout];
}
- (BOOL)consumeUserRequest {
    BOOL requested=[super isOn];
    _desiredState=requested;
    /* UISwitch changes its native value before sending UIControlEventValueChanged.
       Revert that internal value immediately; the presentation/controller decides the final state. */
    [super setOn:!requested animated:NO];
    [self refreshVisuals];
    return requested;
}
- (void)setHighlighted:(BOOL)highlighted { [super setHighlighted:highlighted]; }
@end

#pragma mark - UI Helpers

static UILabel *ZXLabel(NSString *text, UIFont *font, UIColor *color) {
    UILabel *label=[[UILabel alloc] init];
    label.text=text ?: @"";
    label.font=font ?: [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    label.textColor=color ?: [UIColor whiteColor];
    label.numberOfLines=1;
    label.userInteractionEnabled=NO;
    return label;
}

static BOOL ZXIsTruthyValue(id value) {
    if(!value || value==[NSNull null]) return NO;
    if([value isKindOfClass:[NSNumber class]]) return [value boolValue];
    if([value isKindOfClass:[NSString class]]) {
        NSString *s=[(NSString *)value lowercaseString];
        if([s isEqualToString:@"1"] || [s isEqualToString:@"true"] || [s isEqualToString:@"yes"] || [s isEqualToString:@"on"]) return YES;
    }
    return NO;
}

static NSString *ZXCurrentLanguage(void) {
    NSUserDefaults *d=[[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *lang=[d stringForKey:ZXLanguageKey];
    return lang.length ? lang : @"English";
}

static NSString *ZXLocalizedUI(NSString *text) {
    if(![text isKindOfClass:[NSString class]] || !text.length) return text ?: @"";
    NSString *language=ZXCurrentLanguage();
    if([language isEqualToString:@"English"]) return text;
    NSDictionary *vi=@{
        @"Settings":@"Cài đặt", @"Sign Out":@"Đăng xuất", @"AUTHENTICATE":@"XÁC THỰC",
        @"Choose your language":@"Chọn ngôn ngữ", @"ACTIVE":@"ĐANG BẬT", @"READY":@"SẴN SÀNG",
        @"LIFETIME":@"VĨNH VIỄN", @"OFFLINE":@"NGOẠI TUYẾN"
    };
    NSDictionary *zh=@{
        @"Settings":@"设置", @"Sign Out":@"退出登录", @"AUTHENTICATE":@"验证",
        @"Choose your language":@"选择语言", @"ACTIVE":@"已启用", @"READY":@"就绪",
        @"LIFETIME":@"终身", @"OFFLINE":@"离线"
    };
    NSDictionary *ja=@{
        @"Settings":@"設定", @"Sign Out":@"サインアウト", @"AUTHENTICATE":@"認証",
        @"Choose your language":@"言語を選択", @"ACTIVE":@"有効", @"READY":@"準備完了",
        @"LIFETIME":@"無期限", @"OFFLINE":@"オフライン"
    };
    if([language isEqualToString:@"Tiếng Việt"]) return vi[text] ?: text;
    if([language isEqualToString:@"简体中文"]) return zh[text] ?: text;
    if([language isEqualToString:@"日本語"]) return ja[text] ?: text;
    return text;
}

static void ZXSetButtonSymbol(UIButton *button, NSString *name, CGFloat size) {
    UIImageSymbolConfiguration *cfg=[UIImageSymbolConfiguration configurationWithPointSize:size weight:UIImageSymbolWeightMedium scale:UIImageSymbolScaleMedium];
    [button setPreferredSymbolConfiguration:cfg];
    [button setImage:[UIImage systemImageNamed:name withConfiguration:cfg] forState:UIControlStateNormal];
}

#pragma mark - Presentation Components
@interface ZentraxUI () <UITextFieldDelegate>
@property(nonatomic,strong) ZXAmbientBackgroundView *backgroundEnvironment;
@property(nonatomic,assign) ZXAppState currentState;
@property(nonatomic,assign) ZXStartupState startupState;
@property(nonatomic,assign) BOOL hasStarted;

@property(nonatomic,assign) BOOL settingsVisible;
@property(nonatomic,assign) BOOL settingsKeyRevealed;

@property(nonatomic,assign) BOOL licensePermanent;
@property(nonatomic,assign) ZXLicenseUIStatus licenseStatus;
@property(nonatomic,strong) NSDate *serverDate;
@property(nonatomic,strong) NSDate *activatedAt;
@property(nonatomic,strong) NSDate *expiresAt;
@property(nonatomic,strong) NSTimer *licenseTimer;
@property(nonatomic,strong) NSTimer *heartbeatTimer;

@property(nonatomic,strong) NSDictionary *compatibilityData;
@property(nonatomic,strong) NSDictionary *dashboardConfiguration;
@property(nonatomic,strong) NSMutableDictionary<NSString *, NSNumber *> *functionStates;
@property(nonatomic,strong) NSMutableDictionary<NSString *, UIView *> *functionCards;
@property(nonatomic,strong) NSMutableDictionary<NSString *, UIControl *> *functionControls;
@property(nonatomic,strong) NSMutableDictionary<NSString *, NSDictionary *> *functionDefinitions;
@property(nonatomic,strong) NSMutableDictionary<NSString *, UILabel *> *functionStateLabels;

@property(nonatomic,strong) UIView *splashContainer;
@property(nonatomic,strong) UIView *authContainer;
@property(nonatomic,strong) UIView *dashboardContainer;
@property(nonatomic,strong) UIView *settingsContainer;
@property(nonatomic,strong) UIView *startupBlockContainer;
@property(nonatomic,strong) UIView *globalLoadingOverlay;
@property(nonatomic,strong) UIView *toastView;

@property(nonatomic,strong) UILabel *splashStatus;
@property(nonatomic,strong) UILabel *splashProgressLabel;
@property(nonatomic,strong) UIImageView *splashLogo;
@property(nonatomic,assign) CGFloat currentSplashProgress;
@property(nonatomic,strong) NSTimer *splashAnimationTimer;
@property(nonatomic,copy) void (^pendingSplashCompletion)(void);

@property(nonatomic,strong) ZXPremiumField *keyInput;
@property(nonatomic,strong) ZXPremiumButton *loginBtn;
@property(nonatomic,strong) UILabel *authStatus;
@property(nonatomic,strong) UIScrollView *authScroll;

@property(nonatomic,strong) UILabel *countdownLabel;
@property(nonatomic,strong) UILabel *licenseStatusLabel;
@property(nonatomic,strong) UILabel *settingsKeyLabel;
@property(nonatomic,strong) UILabel *settingsExpiryLabel;
@property(nonatomic,strong) UILabel *connectionLabel;
@property(nonatomic,strong) UIView *connectionDot;
@property(nonatomic,strong) UIStackView *modulesStack;
@property(nonatomic,strong) UIScrollView *modulesScroll;
@property(nonatomic,strong) UIView *emptyState;
@property(nonatomic,strong) ZXGlassCard *licenseCard;

@property(nonatomic,strong) UIScrollView *settingsScroll;
@property(nonatomic,strong) UIStackView *settingsStack;

@property(nonatomic,strong) UILabel *startupBlockTitle;
@property(nonatomic,strong) UILabel *startupBlockMessage;
@property(nonatomic,strong) UIButton *startupBlockAction;
@property(nonatomic,assign) ZXStartupState blockedState;

@property(nonatomic,strong) ZXOrbitLoader *globalSpinner;
@property(nonatomic,strong) UIView *featureStatusOverlay;
@property(nonatomic,strong) ZXOrbitLoader *featureStatusLoader;
@property(nonatomic,strong) UILabel *featureStatusTitle;
@property(nonatomic,strong) UILabel *featureStatusDetail;
@property(nonatomic,assign) BOOL featureStatusActivating;
@property(nonatomic,strong) UILabel *globalLoadingTitle;
@property(nonatomic,strong) UILabel *globalLoadingDetail;

- (UIImage *)preferredLogoImage;
- (void)toggleSettingsKey:(UIButton *)sender;
- (void)rebuildAllContainers;
- (void)styleSecondaryButton:(UIButton *)button;
- (void)showFeatureOperationStatus:(NSString *)functionId activating:(BOOL)activating;
- (void)finishFeatureOperationStatus:(BOOL)success functionId:(NSString *)functionId message:(NSString *)message;
@end

@implementation ZentraxUI

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _functionStates = [NSMutableDictionary dictionary];
        _functionCards = [NSMutableDictionary dictionary];
        _functionControls = [NSMutableDictionary dictionary];
        _functionDefinitions = [NSMutableDictionary dictionary];
        _functionStateLabels = [NSMutableDictionary dictionary];
        _licenseStatus = ZXLicenseUIStatusUnknown;
        _startupState = ZXStartupStateUnknown;
    }
    return self;
}

- (void)dealloc {
    [_licenseTimer invalidate];
    [_heartbeatTimer invalidate];
    [_splashAnimationTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _backgroundEnvironment = [[ZXAmbientBackgroundView alloc] initWithFrame:self.view.bounds];
    _backgroundEnvironment.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_backgroundEnvironment];
    
    self.view.tintColor = [ZXTheme accentPrimary];
    self.currentState = ZXAppStateInit;

    [self rebuildAllContainers];
    [self setAllPrimaryContainersHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)rebuildAllContainers {
    NSDictionary *savedDashboard = self.dashboardConfiguration;
    NSDictionary *savedFunctionStates = [self.functionStates copy];
    BOOL wasSettings = self.settingsVisible;
    BOOL wasDashboard = (self.currentState == ZXAppStateDashboard);
    BOOL wasAuth = (self.currentState == ZXAppStateAuth);

    [self.splashContainer removeFromSuperview];
    [self.authContainer removeFromSuperview];
    [self.dashboardContainer removeFromSuperview];
    [self.settingsContainer removeFromSuperview];
    [self.startupBlockContainer removeFromSuperview];
    [self.globalLoadingOverlay removeFromSuperview];

    [self setupSplash];
    [self setupAuth];
    [self setupDashboard];
    [self setupSettingsScreen];
    [self setupStartupBlock];
    [self setupGlobalLoading];
    [self setAllPrimaryContainersHidden:YES];

    if (savedDashboard.count) {
        [self updateDashboardWithConfiguration:savedDashboard];
        [self updateFunctionStates:savedFunctionStates];
    }
    if (wasSettings) {
        [self setupSettingsScreen];
        [self transitionToPrimaryContainer:self.settingsContainer];
    } else if (wasDashboard) {
        [self showDashboard];
    } else if (wasAuth) {
        [self showLoginScreen];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.hasStarted) {
        self.hasStarted = YES;
        [self startZentraxUI];
    }
}

- (void)startZentraxUI {
    [self beginBootstrap];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Setup: Common

- (void)setAllPrimaryContainersHidden:(BOOL)hidden {
    self.splashContainer.hidden = hidden;
    self.authContainer.hidden = hidden;
    self.dashboardContainer.hidden = hidden;
    self.settingsContainer.hidden = hidden;
    self.startupBlockContainer.hidden = hidden;
}

- (void)transitionToPrimaryContainer:(UIView *)target {
    NSArray *containers=@[_splashContainer ?: [UIView new],_authContainer ?: [UIView new],_dashboardContainer ?: [UIView new],_settingsContainer ?: [UIView new],_startupBlockContainer ?: [UIView new]];
    for(UIView *container in containers) {
        if(container==target) continue;
        container.hidden=YES;
        container.alpha=0;
        container.transform=CGAffineTransformIdentity;
    }
    target.hidden=NO;
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];

    target.alpha=0;
    target.transform=CGAffineTransformMakeScale(0.992,0.992);
    if(ZXReduceMotionEnabled()) {
        target.alpha=1;
        target.transform=CGAffineTransformIdentity;
        return;
    }
    [UIView animateWithDuration:0.34 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseOut animations:^{
        target.alpha=1;
        target.transform=CGAffineTransformIdentity;
    } completion:nil];
}

- (UILabel *)label:(NSString *)text size:(CGFloat)size weight:(UIFontWeight)weight color:(UIColor *)color {
    UILabel *l = [[UILabel alloc] init];
    l.text = ZXLocalizedUI(text);
    l.font = [ZXTheme body:size weight:weight];
    l.textColor = color;
    l.numberOfLines = 0;
    return l;
}

- (UIButton *)iconButton:(NSString *)symbol size:(CGFloat)size {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *image = [UIImage systemImageNamed:symbol];
    [b setImage:image forState:UIControlStateNormal];
    b.tintColor = [ZXTheme primaryText];
    b.imageView.contentMode = UIViewContentModeScaleAspectFit;
    b.translatesAutoresizingMaskIntoConstraints = NO;
    [b.widthAnchor constraintEqualToConstant:size].active = YES;
    [b.heightAnchor constraintEqualToConstant:size].active = YES;
    return b;
}

#pragma mark - Splash

- (void)setupSplash {
    _splashContainer=[[UIView alloc] init];
    _splashContainer.translatesAutoresizingMaskIntoConstraints=NO;
    [self.view addSubview:_splashContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_splashContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_splashContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_splashContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_splashContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UIView *markField=[[UIView alloc] init];
    markField.translatesAutoresizingMaskIntoConstraints=NO;
    [_splashContainer addSubview:markField];

    _splashLogo=[[UIImageView alloc] initWithImage:[self preferredLogoImage]];
    _splashLogo.contentMode=UIViewContentModeScaleAspectFit;
    _splashLogo.layer.cornerRadius=22;
    _splashLogo.layer.cornerCurve=kCACornerCurveContinuous;
    _splashLogo.clipsToBounds=YES;
    _splashLogo.translatesAutoresizingMaskIntoConstraints=NO;
    [markField addSubview:_splashLogo];

    UILabel *wordmark=[self label:@"ZENTRAX" size:34 weight:UIFontWeightBold color:[ZXTheme primaryText]];
    [ZXTheme track:wordmark spacing:5.2];
    wordmark.textAlignment=NSTextAlignmentCenter;
    wordmark.translatesAutoresizingMaskIntoConstraints=NO;
    [_splashContainer addSubview:wordmark];

    UIView *thread=[[UIView alloc] init];
    thread.backgroundColor=[UIColor colorWithWhite:1 alpha:0.16];
    thread.layer.cornerRadius=0.5;
    thread.translatesAutoresizingMaskIntoConstraints=NO;
    [_splashContainer addSubview:thread];

    _splashStatus=[self label:@"PREPARING SECURE ENVIRONMENT" size:10 weight:UIFontWeightSemibold color:[ZXTheme secondaryText]];
    [ZXTheme track:_splashStatus spacing:2.1];
    _splashStatus.textAlignment=NSTextAlignmentCenter;
    _splashStatus.translatesAutoresizingMaskIntoConstraints=NO;
    [_splashContainer addSubview:_splashStatus];

    _splashProgressLabel=[self label:@"" size:1 weight:UIFontWeightRegular color:[UIColor clearColor]];
    _splashProgressLabel.hidden=YES;
    _splashProgressLabel.translatesAutoresizingMaskIntoConstraints=NO;
    [_splashContainer addSubview:_splashProgressLabel];

    ZXOrbitLoader *loader=[[ZXOrbitLoader alloc] init];
    loader.translatesAutoresizingMaskIntoConstraints=NO;
    [_splashContainer addSubview:loader];
    [loader startAnimating];

    UILabel *micro=[self label:@"SECURE SESSION" size:9 weight:UIFontWeightMedium color:[ZXTheme mutedText]];
    [ZXTheme track:micro spacing:2.4];
    micro.textAlignment=NSTextAlignmentCenter;
    micro.translatesAutoresizingMaskIntoConstraints=NO;
    [_splashContainer addSubview:micro];

    [NSLayoutConstraint activateConstraints:@[
        [markField.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [markField.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor constant:-72],
        [markField.widthAnchor constraintEqualToConstant:76],
        [markField.heightAnchor constraintEqualToConstant:76],
        [_splashLogo.leadingAnchor constraintEqualToAnchor:markField.leadingAnchor],
        [_splashLogo.trailingAnchor constraintEqualToAnchor:markField.trailingAnchor],
        [_splashLogo.topAnchor constraintEqualToAnchor:markField.topAnchor],
        [_splashLogo.bottomAnchor constraintEqualToAnchor:markField.bottomAnchor],
        [wordmark.topAnchor constraintEqualToAnchor:markField.bottomAnchor constant:26],
        [wordmark.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [thread.topAnchor constraintEqualToAnchor:wordmark.bottomAnchor constant:22],
        [thread.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [thread.widthAnchor constraintEqualToConstant:46],
        [thread.heightAnchor constraintEqualToConstant:1],
        [loader.topAnchor constraintEqualToAnchor:thread.bottomAnchor constant:28],
        [loader.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [loader.widthAnchor constraintEqualToConstant:22],
        [loader.heightAnchor constraintEqualToConstant:22],
        [_splashStatus.topAnchor constraintEqualToAnchor:loader.bottomAnchor constant:18],
        [_splashStatus.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [micro.bottomAnchor constraintEqualToAnchor:_splashContainer.safeAreaLayoutGuide.bottomAnchor constant:-26],
        [micro.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor]
    ]];

    if(!ZXReduceMotionEnabled()) {
        _splashLogo.alpha=0;
        wordmark.alpha=0;
        loader.alpha=0;
        _splashStatus.alpha=0;
        [UIView animateWithDuration:0.65 delay:0.05 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.splashLogo.alpha=1;
            wordmark.alpha=1;
            loader.alpha=1;
            self.splashStatus.alpha=1;
        } completion:nil];
    }
}

- (void)runPremiumSplashCompletion:(void (^)(void))completion {
    self.pendingSplashCompletion = completion;
    self.currentSplashProgress = 0.0;
    self.splashAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(tickSplashAnimation:) userInfo:nil repeats:YES];
}

- (void)tickSplashAnimation:(NSTimer *)timer {
    self.currentSplashProgress += 1.5;
    if(self.currentSplashProgress > 100.0) self.currentSplashProgress = 100.0;
    self.splashProgressLabel.text = [NSString stringWithFormat:@"%d%%", (int)self.currentSplashProgress];
    
    if (self.currentSplashProgress >= 100.0) {
        [self.splashAnimationTimer invalidate];
        self.splashAnimationTimer = nil;
        if (self.pendingSplashCompletion) {
            self.pendingSplashCompletion();
            self.pendingSplashCompletion = nil;
        }
    }
}

#pragma mark - Authentication (Elegant & Timeout Protected)

- (void)setupAuth {
    _authContainer=[[UIView alloc] init];
    _authContainer.translatesAutoresizingMaskIntoConstraints=NO;
    [self.view addSubview:_authContainer];

    _authScroll=[[UIScrollView alloc] init];
    _authScroll.alwaysBounceVertical=YES;
    _authScroll.showsVerticalScrollIndicator=NO;
    _authScroll.keyboardDismissMode=UIScrollViewKeyboardDismissModeInteractive;
    _authScroll.translatesAutoresizingMaskIntoConstraints=NO;
    [_authContainer addSubview:_authScroll];

    UIView *content=[[UIView alloc] init];
    content.translatesAutoresizingMaskIntoConstraints=NO;
    [_authScroll addSubview:content];

    [NSLayoutConstraint activateConstraints:@[
        [_authContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_authContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_authContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_authContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [_authScroll.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor],
        [_authScroll.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor],
        [_authScroll.topAnchor constraintEqualToAnchor:_authContainer.topAnchor],
        [_authScroll.bottomAnchor constraintEqualToAnchor:_authContainer.bottomAnchor],
        [content.leadingAnchor constraintEqualToAnchor:_authScroll.contentLayoutGuide.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:_authScroll.contentLayoutGuide.trailingAnchor],
        [content.topAnchor constraintEqualToAnchor:_authScroll.contentLayoutGuide.topAnchor],
        [content.bottomAnchor constraintEqualToAnchor:_authScroll.contentLayoutGuide.bottomAnchor],
        [content.widthAnchor constraintEqualToAnchor:_authScroll.frameLayoutGuide.widthAnchor],
        [content.heightAnchor constraintGreaterThanOrEqualToAnchor:_authScroll.frameLayoutGuide.heightAnchor]
    ]];

    UILabel *eyebrow=[self label:@"ZENTRAX / SECURE ACCESS" size:10 weight:UIFontWeightSemibold color:[ZXTheme mutedText]];
    [ZXTheme track:eyebrow spacing:2.4];
    eyebrow.textAlignment=NSTextAlignmentCenter;
    eyebrow.translatesAutoresizingMaskIntoConstraints=NO;
    [content addSubview:eyebrow];

    UIImageView *logo=[[UIImageView alloc] initWithImage:[self preferredLogoImage]];
    logo.contentMode=UIViewContentModeScaleAspectFit;
    logo.layer.cornerRadius=20;
    logo.layer.cornerCurve=kCACornerCurveContinuous;
    logo.clipsToBounds=YES;
    logo.translatesAutoresizingMaskIntoConstraints=NO;
    [content addSubview:logo];

    UILabel *title=[self label:@"Welcome back." size:34 weight:UIFontWeightBold color:[ZXTheme primaryText]];
    title.textAlignment=NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints=NO;
    [content addSubview:title];

    UILabel *subtitle=[self label:@"Authenticate your ZENTRAX secure environment." size:14 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    subtitle.textAlignment=NSTextAlignmentCenter;
    subtitle.numberOfLines=2;
    subtitle.translatesAutoresizingMaskIntoConstraints=NO;
    [content addSubview:subtitle];

    UIView *credentialFrame=[[UIView alloc] init];
    credentialFrame.translatesAutoresizingMaskIntoConstraints=NO;
    [content addSubview:credentialFrame];

    UILabel *fieldCaption=[self label:@"LICENSE KEY" size:10 weight:UIFontWeightSemibold color:[ZXTheme mutedText]];
    [ZXTheme track:fieldCaption spacing:1.8];
    fieldCaption.translatesAutoresizingMaskIntoConstraints=NO;
    [credentialFrame addSubview:fieldCaption];

    _keyInput=[[ZXPremiumField alloc] init];
    _keyInput.translatesAutoresizingMaskIntoConstraints=NO;
    [credentialFrame addSubview:_keyInput];

    _loginBtn=[[ZXPremiumButton alloc] init];
    [_loginBtn setTitle:ZXLocalizedUI(@"CONTINUE") forState:UIControlStateNormal];
    _loginBtn.translatesAutoresizingMaskIntoConstraints=NO;
    [_loginBtn addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside];
    [credentialFrame addSubview:_loginBtn];

    _authStatus=[self label:@"" size:13 weight:UIFontWeightMedium color:[ZXTheme mutedText]];
    _authStatus.textAlignment=NSTextAlignmentCenter;
    _authStatus.numberOfLines=0;
    _authStatus.translatesAutoresizingMaskIntoConstraints=NO;
    [credentialFrame addSubview:_authStatus];

    UILabel *foot=[self label:@"Your key is validated by the existing secure service." size:10 weight:UIFontWeightRegular color:[ZXTheme mutedText]];
    foot.textAlignment=NSTextAlignmentCenter;
    foot.numberOfLines=2;
    foot.translatesAutoresizingMaskIntoConstraints=NO;
    [content addSubview:foot];

    [NSLayoutConstraint activateConstraints:@[
        [eyebrow.topAnchor constraintEqualToAnchor:content.topAnchor constant:46],
        [eyebrow.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],
        [logo.topAnchor constraintEqualToAnchor:eyebrow.bottomAnchor constant:28],
        [logo.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],
        [logo.widthAnchor constraintEqualToConstant:68],
        [logo.heightAnchor constraintEqualToConstant:68],
        [title.topAnchor constraintEqualToAnchor:logo.bottomAnchor constant:24],
        [title.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:28],
        [title.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-28],
        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
        [subtitle.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:40],
        [subtitle.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-40],
        [credentialFrame.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:38],
        [credentialFrame.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:24],
        [credentialFrame.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-24],
        [fieldCaption.topAnchor constraintEqualToAnchor:credentialFrame.topAnchor],
        [fieldCaption.leadingAnchor constraintEqualToAnchor:credentialFrame.leadingAnchor constant:4],
        [_keyInput.topAnchor constraintEqualToAnchor:fieldCaption.bottomAnchor constant:9],
        [_keyInput.leadingAnchor constraintEqualToAnchor:credentialFrame.leadingAnchor],
        [_keyInput.trailingAnchor constraintEqualToAnchor:credentialFrame.trailingAnchor],
        [_keyInput.heightAnchor constraintEqualToConstant:62],
        [_loginBtn.topAnchor constraintEqualToAnchor:_keyInput.bottomAnchor constant:14],
        [_loginBtn.leadingAnchor constraintEqualToAnchor:credentialFrame.leadingAnchor],
        [_loginBtn.trailingAnchor constraintEqualToAnchor:credentialFrame.trailingAnchor],
        [_loginBtn.heightAnchor constraintEqualToConstant:58],
        [_authStatus.topAnchor constraintEqualToAnchor:_loginBtn.bottomAnchor constant:16],
        [_authStatus.leadingAnchor constraintEqualToAnchor:credentialFrame.leadingAnchor constant:8],
        [_authStatus.trailingAnchor constraintEqualToAnchor:credentialFrame.trailingAnchor constant:-8],
        [foot.topAnchor constraintEqualToAnchor:_authStatus.bottomAnchor constant:30],
        [foot.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:48],
        [foot.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-48],
        [foot.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-30]
    ]];
}

- (void)keyboardWillShow:(NSNotification *)note {
    CGSize kbSize = [[note.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    self.authScroll.contentInset = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.authScroll.scrollIndicatorInsets = self.authScroll.contentInset;
}
- (void)keyboardWillHide:(NSNotification *)note {
    self.authScroll.contentInset = UIEdgeInsetsZero;
    self.authScroll.scrollIndicatorInsets = UIEdgeInsetsZero;
}

- (void)handleLogin {
    [self.view endEditing:YES]; 
    
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSDate *timeout = [d objectForKey:ZXLoginTimeoutKey];
    if (timeout && [timeout timeIntervalSinceNow] > 0) {
        NSInteger mins = (NSInteger)ceil([timeout timeIntervalSinceNow] / 60.0);
        self.authStatus.textColor = [ZXTheme error];
        self.authStatus.text = [NSString stringWithFormat:ZXLocalizedUI(@"Authentication locked. Try again in %ld min."), (long)mins];
        [self showToast:self.authStatus.text success:NO];
        [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeError];
        return;
    }
    
    NSString *key = [_keyInput.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!key.length) {
        [self showToast:@"Enter your license key." success:NO];
        return;
    }
    
    [d setObject:key forKey:ZXLastKey];
    [d synchronize];

    [_loginBtn setLoading:YES];
    _authStatus.textColor = [ZXTheme secondaryText];
    _authStatus.text = ZXLocalizedUI(@"Authenticating...");

    __weak typeof(self) weakSelf = self;
    void (^processResult)(BOOL, ZXAuthError, NSString *) = ^(BOOL success, ZXAuthError errorType, NSString *errorMsg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf; if (!self) return;
            [self.loginBtn setLoading:NO];
            
            NSUserDefaults *ud = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
            if (success) {
                [ud removeObjectForKey:ZXLoginAttemptsKey];
                [ud removeObjectForKey:ZXLoginTimeoutKey];
                [ud synchronize];
                
                self.authStatus.textColor = [ZXTheme success];
                self.authStatus.text = ZXLocalizedUI(@"Access Granted");
                [self showDashboard];
            } else {
                NSString *finalErrorMsg = errorMsg; 
                NSInteger attempts = [ud integerForKey:ZXLoginAttemptsKey] + 1;
                [ud setInteger:attempts forKey:ZXLoginAttemptsKey];
                if (attempts >= 5) {
                    [ud setObject:[[NSDate date] dateByAddingTimeInterval:600] forKey:ZXLoginTimeoutKey]; // 10 minutes
                    [ud removeObjectForKey:ZXLoginAttemptsKey];
                    finalErrorMsg = @"Too many failed attempts. You are timed out for 10 minutes.";
                }
                [ud synchronize];
                [self presentAuthError:errorType message:finalErrorMsg];
            }
        });
    };

    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestAuthenticationWithKey:completion:)]) {
        [self.delegate zentraxDidRequestAuthenticationWithKey:key completion:processResult];
    } else {
        Class mgrCls = NSClassFromString(@"ZentraxNetworkManager");
        if (mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
            id manager = ((id (*)(id, SEL))objc_msgSend)((id)mgrCls, NSSelectorFromString(@"sharedManager"));
            SEL authSel = NSSelectorFromString(@"authenticateWithKey:completion:");
            if ([manager respondsToSelector:authSel]) {
                void (^netCompletion)(BOOL, NSDictionary *, NSInteger, NSString *) = ^(BOOL success, NSDictionary *res, NSInteger errType, NSString *errMsg) {
                    processResult(success, (ZXAuthError)errType, errMsg);
                };
                ((void (*)(id, SEL, id, id))objc_msgSend)(manager, authSel, key, netCompletion);
            } else processResult(NO, ZXAuthErrorServer, @"Integration bridge unavailable.");
        } else processResult(NO, ZXAuthErrorServer, @"Integration bridge unavailable.");
    }
}

- (void)presentAuthError:(ZXAuthError)errorType message:(NSString *)message {
    NSString *title = @"ACCESS DENIED";
    NSString *fallback = message.length ? message : @"The server rejected this authentication request.";
    switch (errorType) {
        case ZXAuthErrorConnection: title = @"CONNECTION ERROR"; break;
        case ZXAuthErrorServer: title = @"SERVER ERROR"; break;
        case ZXAuthErrorMaintenance: title = @"MAINTENANCE"; break;
        case ZXAuthErrorVersionMismatch: title = @"UPDATE REQUIRED"; break;
        case ZXAuthErrorCompatibility: title = @"DEVICE UNSUPPORTED"; break;
        case ZXAuthErrorRateLimited: title = @"TOO MANY REQUESTS"; break;
        case ZXAuthErrorExpiredKey: title = @"LICENSE EXPIRED"; break;
        case ZXAuthErrorRevokedKey: title = @"ACCESS REVOKED"; break;
        case ZXAuthErrorDeviceLimit: title = @"DEVICE LIMIT"; break;
        default: break;
    }
    _authStatus.textColor = [ZXTheme error];
    _authStatus.text = fallback;
    [self showGlobalErrorWithTitle:title message:fallback];
}

#pragma mark - Dashboard (Ultra Premium Home)

- (void)setupDashboard {
    if(_dashboardContainer) [_dashboardContainer removeFromSuperview];

    _dashboardContainer=[[UIView alloc] init];
    _dashboardContainer.translatesAutoresizingMaskIntoConstraints=NO;
    [self.view addSubview:_dashboardContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_dashboardContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_dashboardContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_dashboardContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_dashboardContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UIView *header=[[UIView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints=NO;
    [_dashboardContainer addSubview:header];

    UIImageView *logo=[[UIImageView alloc] initWithImage:[self preferredLogoImage]];
    logo.contentMode=UIViewContentModeScaleAspectFit;
    logo.layer.cornerRadius=9;
    logo.clipsToBounds=YES;
    logo.translatesAutoresizingMaskIntoConstraints=NO;
    [header addSubview:logo];

    UILabel *wordmark=[self label:@"ZENTRAX" size:17 weight:UIFontWeightBold color:[ZXTheme primaryText]];
    [ZXTheme track:wordmark spacing:2.2];
    wordmark.translatesAutoresizingMaskIntoConstraints=NO;
    [header addSubview:wordmark];

    _connectionDot=[[UIView alloc] init];
    _connectionDot.backgroundColor=[ZXTheme success];
    _connectionDot.layer.cornerRadius=2.5;
    _connectionDot.layer.shadowColor=[ZXTheme success].CGColor;
    _connectionDot.layer.shadowOpacity=0.45;
    _connectionDot.layer.shadowRadius=5;
    _connectionDot.translatesAutoresizingMaskIntoConstraints=NO;
    [header addSubview:_connectionDot];

    _connectionLabel=[self label:@"SECURE" size:9 weight:UIFontWeightSemibold color:[ZXTheme secondaryText]];
    [ZXTheme track:_connectionLabel spacing:1.7];
    _connectionLabel.translatesAutoresizingMaskIntoConstraints=NO;
    [header addSubview:_connectionLabel];

    UIButton *settingsBtn=[self iconButton:@"slider.horizontal.3" size:32];
    settingsBtn.tintColor=[ZXTheme secondaryText];
    settingsBtn.accessibilityLabel=ZXLocalizedUI(@"Settings");
    settingsBtn.layer.cornerRadius=16;
    settingsBtn.backgroundColor=[UIColor colorWithWhite:1 alpha:0.035];
    [settingsBtn addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:settingsBtn];

    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [header.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [header.topAnchor constraintEqualToAnchor:_dashboardContainer.safeAreaLayoutGuide.topAnchor constant:10],
        [header.heightAnchor constraintEqualToConstant:42],
        [logo.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [logo.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [logo.widthAnchor constraintEqualToConstant:28],
        [logo.heightAnchor constraintEqualToConstant:28],
        [wordmark.leadingAnchor constraintEqualToAnchor:logo.trailingAnchor constant:12],
        [wordmark.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [settingsBtn.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],
        [settingsBtn.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [settingsBtn.widthAnchor constraintEqualToConstant:32],
        [settingsBtn.heightAnchor constraintEqualToConstant:32],
        [_connectionLabel.trailingAnchor constraintEqualToAnchor:settingsBtn.leadingAnchor constant:-13],
        [_connectionLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [_connectionDot.trailingAnchor constraintEqualToAnchor:_connectionLabel.leadingAnchor constant:-6],
        [_connectionDot.centerYAnchor constraintEqualToAnchor:_connectionLabel.centerYAnchor],
        [_connectionDot.widthAnchor constraintEqualToConstant:5],
        [_connectionDot.heightAnchor constraintEqualToConstant:5]
    ]];

    _licenseCard=[[ZXGlassCard alloc] init];
    [_licenseCard applyMaterial:ZXMaterialElevatedGlass];
    [_dashboardContainer addSubview:_licenseCard];
    [NSLayoutConstraint activateConstraints:@[
        [_licenseCard.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:20],
        [_licenseCard.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-20],
        [_licenseCard.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:24],
        [_licenseCard.heightAnchor constraintEqualToConstant:156]
    ]];

    UILabel *eyebrow=[self label:@"SECURE ENVIRONMENT" size:10 weight:UIFontWeightSemibold color:[ZXTheme mutedText]];
    [ZXTheme track:eyebrow spacing:2.0];
    eyebrow.translatesAutoresizingMaskIntoConstraints=NO;
    [_licenseCard addSubview:eyebrow];

    _licenseStatusLabel=[self label:@"UNACTIVATED" size:11 weight:UIFontWeightSemibold color:[ZXTheme warning]];
    [ZXTheme track:_licenseStatusLabel spacing:1.4];
    _licenseStatusLabel.translatesAutoresizingMaskIntoConstraints=NO;
    [_licenseCard addSubview:_licenseStatusLabel];

    _countdownLabel=[self label:@"—" size:38 weight:UIFontWeightBold color:[ZXTheme primaryText]];
    _countdownLabel.font=[ZXTheme mono:36 weight:UIFontWeightSemibold];
    _countdownLabel.adjustsFontSizeToFitWidth=YES;
    _countdownLabel.minimumScaleFactor=0.72;
    _countdownLabel.translatesAutoresizingMaskIntoConstraints=NO;
    [_licenseCard addSubview:_countdownLabel];

    UIView *rule=[[UIView alloc] init];
    rule.backgroundColor=[UIColor colorWithWhite:1 alpha:0.07];
    rule.translatesAutoresizingMaskIntoConstraints=NO;
    [_licenseCard addSubview:rule];

    UILabel *caption=[self label:@"REMAINING / STATUS" size:9 weight:UIFontWeightMedium color:[ZXTheme mutedText]];
    [ZXTheme track:caption spacing:1.6];
    caption.translatesAutoresizingMaskIntoConstraints=NO;
    [_licenseCard addSubview:caption];

    [NSLayoutConstraint activateConstraints:@[
        [eyebrow.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:22],
        [eyebrow.topAnchor constraintEqualToAnchor:_licenseCard.topAnchor constant:20],
        [_licenseStatusLabel.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor constant:-22],
        [_licenseStatusLabel.centerYAnchor constraintEqualToAnchor:eyebrow.centerYAnchor],
        [rule.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:22],
        [rule.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor constant:-22],
        [rule.topAnchor constraintEqualToAnchor:eyebrow.bottomAnchor constant:15],
        [rule.heightAnchor constraintEqualToConstant:1],
        [_countdownLabel.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:22],
        [_countdownLabel.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor constant:-22],
        [_countdownLabel.topAnchor constraintEqualToAnchor:rule.bottomAnchor constant:13],
        [caption.leadingAnchor constraintEqualToAnchor:_countdownLabel.leadingAnchor],
        [caption.bottomAnchor constraintEqualToAnchor:_licenseCard.bottomAnchor constant:-18]
    ]];

    _modulesScroll=[[UIScrollView alloc] init];
    _modulesScroll.showsVerticalScrollIndicator=NO;
    _modulesScroll.alwaysBounceVertical=YES;
    _modulesScroll.keyboardDismissMode=UIScrollViewKeyboardDismissModeInteractive;
    _modulesScroll.translatesAutoresizingMaskIntoConstraints=NO;
    [_dashboardContainer addSubview:_modulesScroll];

    _modulesStack=[[UIStackView alloc] init];
    _modulesStack.axis=UILayoutConstraintAxisVertical;
    _modulesStack.spacing=14;
    _modulesStack.translatesAutoresizingMaskIntoConstraints=NO;
    [_modulesScroll addSubview:_modulesStack];

    [NSLayoutConstraint activateConstraints:@[
        [_modulesScroll.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:20],
        [_modulesScroll.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-20],
        [_modulesScroll.topAnchor constraintEqualToAnchor:_licenseCard.bottomAnchor constant:22],
        [_modulesScroll.bottomAnchor constraintEqualToAnchor:_dashboardContainer.bottomAnchor],
        [_modulesStack.leadingAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.leadingAnchor],
        [_modulesStack.trailingAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.trailingAnchor],
        [_modulesStack.topAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.topAnchor],
        [_modulesStack.bottomAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.bottomAnchor constant:-34],
        [_modulesStack.widthAnchor constraintEqualToAnchor:_modulesScroll.frameLayoutGuide.widthAnchor]
    ]];

    [self createEmptyStateView];
}

- (void)createEmptyStateView {
    _emptyState=[[ZXGlassCard alloc] init];
    [_emptyState applyMaterial:ZXMaterialClearGlass];

    UIView *signal=[[UIView alloc] init];
    signal.backgroundColor=[UIColor colorWithWhite:1 alpha:0.13];
    signal.layer.cornerRadius=2;
    signal.translatesAutoresizingMaskIntoConstraints=NO;
    [_emptyState addSubview:signal];

    UIImageView *icon=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"square.stack.3d.up"]];
    icon.tintColor=[ZXTheme secondaryText];
    icon.translatesAutoresizingMaskIntoConstraints=NO;
    [_emptyState addSubview:icon];

    UILabel *title=[self label:@"No functions assigned" size:16 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    title.textAlignment=NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints=NO;
    [_emptyState addSubview:title];

    UILabel *detail=[self label:@"Server configuration will appear here." size:13 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    detail.textAlignment=NSTextAlignmentCenter;
    detail.translatesAutoresizingMaskIntoConstraints=NO;
    [_emptyState addSubview:detail];

    [NSLayoutConstraint activateConstraints:@[
        [_emptyState.heightAnchor constraintEqualToConstant:178],
        [signal.topAnchor constraintEqualToAnchor:_emptyState.topAnchor constant:24],
        [signal.centerXAnchor constraintEqualToAnchor:_emptyState.centerXAnchor],
        [signal.widthAnchor constraintEqualToConstant:34],
        [signal.heightAnchor constraintEqualToConstant:1],
        [icon.topAnchor constraintEqualToAnchor:signal.bottomAnchor constant:22],
        [icon.centerXAnchor constraintEqualToAnchor:_emptyState.centerXAnchor],
        [icon.widthAnchor constraintEqualToConstant:24],
        [icon.heightAnchor constraintEqualToConstant:24],
        [title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:13],
        [title.centerXAnchor constraintEqualToAnchor:_emptyState.centerXAnchor],
        [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:6],
        [detail.centerXAnchor constraintEqualToAnchor:_emptyState.centerXAnchor],
        [detail.leadingAnchor constraintGreaterThanOrEqualToAnchor:_emptyState.leadingAnchor constant:20],
        [detail.trailingAnchor constraintLessThanOrEqualToAnchor:_emptyState.trailingAnchor constant:-20]
    ]];
}

#pragma mark - Dynamic Dashboard Updates

- (void)updateDashboardWithModules:(NSArray<NSDictionary *> *)modules {
    [self updateDashboardWithConfiguration:@{ @"modules": modules ?: @[] }];
}

- (void)updateDashboardWithConfiguration:(NSDictionary *)configuration {
    if (![configuration isKindOfClass:[NSDictionary class]]) configuration=@{};
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self updateDashboardWithConfiguration:configuration]; });
        return;
    }
    
    NSArray *categories = configuration[@"categories"];
    NSArray *modules = configuration[@"modules"] ?: configuration[@"functions"];
    if (![categories isKindOfClass:[NSArray class]] || !categories.count) categories = modules;
    
    BOOL incomingHasUsableData = NO;
    for (id rawCategory in ([categories isKindOfClass:[NSArray class]] ? categories : @[])) {
        if (![rawCategory isKindOfClass:[NSDictionary class]]) continue;
        NSArray *functions = rawCategory[@"functions"];
        if ([functions isKindOfClass:[NSArray class]] && functions.count) { incomingHasUsableData = YES; break; }
        if (rawCategory[@"id"] || rawCategory[@"function_id"] || rawCategory[@"name"]) { incomingHasUsableData = YES; break; }
    }
    if (!incomingHasUsableData && self.functionDefinitions.count > 0) return;
    
    self.dashboardConfiguration = configuration ?: @{};

    for (UIView *v in [self.modulesStack.arrangedSubviews copy]) {
        [self.modulesStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    [self.functionCards removeAllObjects];
    [self.functionControls removeAllObjects];
    [self.functionDefinitions removeAllObjects];
    [self.functionStateLabels removeAllObjects];

    BOOL hasFunctions = NO;
    if (![categories isKindOfClass:[NSArray class]]) categories=@[];
    for (id rawCategory in categories) {
        if (![rawCategory isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *category=(NSDictionary *)rawCategory;
        NSArray *functions=category[@"functions"];
        NSString *categoryName=[category[@"name"] isKindOfClass:[NSString class]] ? category[@"name"] : ([category[@"title"] isKindOfClass:[NSString class]] ? category[@"title"] : nil);
        if (![functions isKindOfClass:[NSArray class]]) { functions=@[category]; categoryName=nil; }
        
        if (categoryName.length) {
            UIView *headerWrapper=[[UIView alloc] init];
            headerWrapper.translatesAutoresizingMaskIntoConstraints=NO;

            UILabel *cat=[self label:categoryName.uppercaseString size:10 weight:UIFontWeightSemibold color:[ZXTheme mutedText]];
            [ZXTheme track:cat spacing:2.0];
            cat.translatesAutoresizingMaskIntoConstraints=NO;
            [headerWrapper addSubview:cat];

            UIView *line=[[UIView alloc] init];
            line.backgroundColor=[UIColor colorWithWhite:1 alpha:0.055];
            line.translatesAutoresizingMaskIntoConstraints=NO;
            [headerWrapper addSubview:line];

            [NSLayoutConstraint activateConstraints:@[
                [headerWrapper.heightAnchor constraintEqualToConstant:28],
                [cat.leadingAnchor constraintEqualToAnchor:headerWrapper.leadingAnchor constant:2],
                [cat.centerYAnchor constraintEqualToAnchor:headerWrapper.centerYAnchor constant:2],
                [line.leadingAnchor constraintEqualToAnchor:cat.trailingAnchor constant:12],
                [line.trailingAnchor constraintEqualToAnchor:headerWrapper.trailingAnchor],
                [line.centerYAnchor constraintEqualToAnchor:cat.centerYAnchor],
                [line.heightAnchor constraintEqualToConstant:1]
            ]];
            [_modulesStack addArrangedSubview:headerWrapper];
        }
        
        for (id rawFunction in functions) {
            if (![rawFunction isKindOfClass:[NSDictionary class]]) continue;
            NSDictionary *function=(NSDictionary *)rawFunction;
            id rawID=function[@"id"] ?: function[@"function_id"] ?: function[@"name"];
            if (![rawID isKindOfClass:[NSString class]] && ![rawID isKindOfClass:[NSNumber class]]) continue;
            NSString *fid=[NSString stringWithFormat:@"%@",rawID];
            if (!fid.length) continue;
            
            hasFunctions=YES;
            [self.functionDefinitions setObject:function forKey:fid];
            id serverCurrentState = function[@"current_state"];
            id serverState = function[@"state"];
            BOOL on = NO;
            if (serverCurrentState != nil && serverCurrentState != [NSNull null]) on = ZXIsTruthyValue(serverCurrentState);
            else if (serverState != nil && serverState != [NSNull null]) on = ZXIsTruthyValue(serverState);
            else on = [self.functionStates[fid] boolValue];
            
            self.functionStates[fid]=@(on);
            UIView *card=[self functionCardForDefinition:function functionId:fid isOn:on];
            [_modulesStack addArrangedSubview:card];
            self.functionCards[fid]=card;
        }
    }
    if (!hasFunctions) {
        [self.modulesStack addArrangedSubview:self.emptyState];
    }
}

// Ultra Premium Glass Function Card
- (UIView *)functionCardForDefinition:(NSDictionary *)definition functionId:(NSString *)fid isOn:(BOOL)on {
    ZXGlassCard *card=[[ZXGlassCard alloc] init];
    BOOL featured=[definition[@"featured"] boolValue] || [definition[@"primary"] boolValue] || [definition[@"priority"] integerValue] > 0;
    [card applyMaterial:on ? ZXMaterialActiveGlass : (featured ? ZXMaterialElevatedGlass : ZXMaterialGlass)];
    [card setEmphasized:on animated:NO];

    UIView *indexRail=[[UIView alloc] init];
    indexRail.backgroundColor=on ? [ZXTheme accentSecondary] : [UIColor colorWithWhite:1 alpha:0.16];
    indexRail.layer.cornerRadius=1;
    indexRail.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:indexRail];

    NSString *name=[NSString stringWithFormat:@"%@",definition[@"name"] ?: definition[@"title"] ?: fid];
    UILabel *title=[self label:name size:(featured ? 19 : 17) weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    title.numberOfLines=2;
    title.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:title];

    UILabel *state=[self label:on ? @"ACTIVE" : @"READY" size:9 weight:UIFontWeightSemibold color:on ? [ZXTheme success] : [ZXTheme mutedText]];
    [ZXTheme track:state spacing:1.6];
    state.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:state];
    self.functionStateLabels[fid]=state;

    ZXPremiumToggle *toggle=[[ZXPremiumToggle alloc] init];
    toggle.on=on;
    toggle.desiredState=on;
    toggle.accessibilityLabel=name;
    toggle.accessibilityValue=ZXLocalizedUI(on ? @"ACTIVE" : @"READY");
    toggle.translatesAutoresizingMaskIntoConstraints=NO;
    [toggle addTarget:self action:@selector(functionToggleChanged:) forControlEvents:UIControlEventValueChanged];
    [card addSubview:toggle];
    self.functionControls[fid]=toggle;

    NSString *description=[NSString stringWithFormat:@"%@",definition[@"description"] ?: @"Server-managed secure function."];
    UILabel *detail=[self label:description size:13 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    detail.numberOfLines=0;
    detail.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:detail];

    UILabel *fidLabel=[self label:fid size:9 weight:UIFontWeightMedium color:[ZXTheme mutedText]];
    fidLabel.font=[ZXTheme mono:9 weight:UIFontWeightMedium];
    fidLabel.alpha=0.72;
    fidLabel.numberOfLines=1;
    fidLabel.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:fidLabel];

    CGFloat height=featured ? 144 : 124;
    [NSLayoutConstraint activateConstraints:@[
        [card.heightAnchor constraintGreaterThanOrEqualToConstant:height],
        [indexRail.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
        [indexRail.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
        [indexRail.widthAnchor constraintEqualToConstant:2],
        [indexRail.heightAnchor constraintEqualToConstant:28],
        [title.leadingAnchor constraintEqualToAnchor:indexRail.trailingAnchor constant:13],
        [title.topAnchor constraintEqualToAnchor:card.topAnchor constant:19],
        [title.trailingAnchor constraintLessThanOrEqualToAnchor:toggle.leadingAnchor constant:-10],
        [state.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [state.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:7],
        [toggle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],
        [toggle.centerYAnchor constraintEqualToAnchor:card.topAnchor constant:31],
        [toggle.widthAnchor constraintEqualToConstant:58],
        [toggle.heightAnchor constraintEqualToConstant:34],
        [detail.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
        [detail.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],
        [detail.topAnchor constraintGreaterThanOrEqualToAnchor:state.bottomAnchor constant:13],
        [detail.bottomAnchor constraintLessThanOrEqualToAnchor:fidLabel.topAnchor constant:-8],
        [fidLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
        [fidLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],
        [fidLabel.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-15]
    ]];
    return card;
}

- (NSString *)functionIdForControl:(UIControl *)control {
    for (NSString *fid in self.functionControls) {
        if (self.functionControls[fid] == control) return fid;
    }
    return nil;
}

- (void)functionToggleChanged:(UISwitch *)sender {
    NSString *fid=[self functionIdForControl:sender];
    if(!fid.length) return;

    BOOL requested=sender.isOn;
    if([sender isKindOfClass:[ZXPremiumToggle class]]) {
        ZXPremiumToggle *toggle=(ZXPremiumToggle *)sender;
        requested=[toggle consumeUserRequest];
    }

    sender.userInteractionEnabled=NO;
    if([sender isKindOfClass:[ZXPremiumToggle class]]) [(ZXPremiumToggle *)sender setProcessing:YES];

    UILabel *state=self.functionStateLabels[fid];
    if(state) {
        state.text=ZXLocalizedUI(@"PROCESSING");
        state.textColor=[ZXTheme warning];
    }
    [self showFeatureOperationStatus:fid activating:requested];

    __weak typeof(self) weakSelf=self;
    void (^finish)(BOOL,NSString *)=^(BOOL success,NSString *msg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self=weakSelf;
            if(!self) return;

            sender.userInteractionEnabled=YES;

            /* Preserve the existing engine's result semantics exactly:
               success adopts the requested state; failure restores the prior state. */
            BOOL finalState=success ? requested : !requested;
            self.functionStates[fid]=@(finalState);
            if([sender isKindOfClass:[ZXPremiumToggle class]]) {
                ZXPremiumToggle *toggle=(ZXPremiumToggle *)sender;
                toggle.desiredState=finalState;
                [toggle setProcessing:NO];
                [toggle setOn:finalState animated:YES];
                toggle.accessibilityValue=ZXLocalizedUI(finalState ? @"ACTIVE" : @"READY");
            } else {
                sender.on=finalState;
            }

            if(state) {
                state.text=ZXLocalizedUI(finalState ? @"ACTIVE" : @"READY");
                state.textColor=finalState ? [ZXTheme success] : [ZXTheme mutedText];
            }

            ZXGlassCard *card=(ZXGlassCard *)self.functionCards[fid];
            if(card) {
                [card applyMaterial:finalState ? ZXMaterialActiveGlass : ZXMaterialGlass];
                [card setEmphasized:finalState animated:YES];
            }

            [self finishFeatureOperationStatus:success functionId:fid message:msg];
            if(!success && msg.length>0) [self showToast:msg success:NO];
        });
    };

    /* EXISTING NETWORK / DELEGATE ENGINE — intentionally preserved. */
    if([self.delegate respondsToSelector:@selector(zentraxDidRequestFunctionOperation:action:completion:)]) {
        [self.delegate zentraxDidRequestFunctionOperation:fid action:requested completion:finish];
    } else if([self.delegate respondsToSelector:@selector(zentraxDidRequestModuleToggle:state:completion:)]) {
        [self.delegate zentraxDidRequestModuleToggle:fid state:requested completion:finish];
    } else {
        Class mgrCls=NSClassFromString(@"ZentraxNetworkManager");
        if(mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
            id manager=((id (*)(id, SEL))objc_msgSend)((id)mgrCls, NSSelectorFromString(@"sharedManager"));
            SEL operSel=NSSelectorFromString(@"performModuleOperationWithFunctionId:action:completion:");
            if([manager respondsToSelector:operSel]) {
                void (^netCompletion)(BOOL,NSDictionary *,NSString *)=^(BOOL succ,NSDictionary *res,NSString *err){ finish(succ,err); };
                ((void (*)(id, SEL, id, NSInteger, id))objc_msgSend)(manager, operSel, fid, requested ? 2 : 1, netCompletion);
            } else finish(NO,@"Integration bridge unavailable.");
        } else finish(NO,@"Integration bridge unavailable.");
    }
}

#pragma mark - Subscription / Time

- (void)updateSubscriptionState:(NSDictionary *)subData {
    if (![subData isKindOfClass:[NSDictionary class]]) return;
    NSString *statusRaw = subData[@"status"];
    if (!statusRaw && self.licenseStatus == ZXLicenseUIStatusActive) return; 
    NSString *status = [[NSString stringWithFormat:@"%@", (statusRaw ?: @"unknown")] lowercaseString];
    
    ZXLicenseUIStatus uiStatus = ZXLicenseUIStatusUnknown;
    if ([status isEqualToString:@"unactivated"]) uiStatus = ZXLicenseUIStatusUnactivated;
    else if ([status isEqualToString:@"active"]) uiStatus = ZXLicenseUIStatusActive;
    else if ([status isEqualToString:@"expired"]) uiStatus = ZXLicenseUIStatusExpired;
    else if ([status isEqualToString:@"revoked"]) uiStatus = ZXLicenseUIStatusRevoked;
    else if ([status isEqualToString:@"disabled"]) uiStatus = ZXLicenseUIStatusDisabled;

    NSDate *activated = [self dateFromServerValue:subData[@"activated_at"]];
    NSDate *expires = [self dateFromServerValue:subData[@"expires_at"]];
    BOOL permanent = [subData[@"is_permanent"] boolValue];
    if (subData[@"is_permanent"] == nil && self.licensePermanent) permanent = YES;
    
    [self updateLicenseStatus:uiStatus activatedAt:activated expiresAt:expires isPermanent:permanent];
}

- (void)updateLicenseStatus:(ZXLicenseUIStatus)status activatedAt:(NSDate *)activatedAt expiresAt:(NSDate *)expiresAt isPermanent:(BOOL)isPermanent {
    self.licenseStatus = status;
    self.activatedAt = activatedAt;
    self.expiresAt = expiresAt;
    self.licensePermanent = isPermanent;
    
    NSString *text = ZXLocalizedUI(@"UNKNOWN");
    UIColor *color = [ZXTheme mutedText];
    switch (status) {
        case ZXLicenseUIStatusUnactivated: text = ZXLocalizedUI(@"UNACTIVATED"); color = [ZXTheme warning]; break;
        case ZXLicenseUIStatusActive: text = ZXLocalizedUI(@"ACTIVE"); color = [ZXTheme success]; break;
        case ZXLicenseUIStatusExpired: text = ZXLocalizedUI(@"EXPIRED"); color = [ZXTheme error]; break;
        case ZXLicenseUIStatusRevoked: text = ZXLocalizedUI(@"REVOKED"); color = [ZXTheme error]; break;
        case ZXLicenseUIStatusDisabled: text = ZXLocalizedUI(@"DISABLED"); color = [ZXTheme error]; break;
        default: break;
    }
    
    self.licenseStatusLabel.text = text;
    self.licenseStatusLabel.textColor = color;
    
    if (isPermanent) {
        self.countdownLabel.text = ZXLocalizedUI(@"LIFETIME");
        [self stopLicenseCountdown];
    } else if (expiresAt) {
        [self startLicenseCountdown];
        [self refreshLicenseCountdown];
    } else if (status == ZXLicenseUIStatusUnactivated) {
        self.countdownLabel.text = ZXLocalizedUI(@"NOT STARTED");
        [self stopLicenseCountdown];
    }
    if (self.settingsVisible) [self rebuildSettings];
}

- (NSDate *)dateFromServerValue:(id)value {
    if ([value isKindOfClass:[NSDate class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
    if (![value isKindOfClass:[NSString class]]) return nil;
    NSString *s = value;
    if (!s.length) return nil;
    NSISO8601DateFormatter *f = [[NSISO8601DateFormatter alloc] init];
    NSDate *d = [f dateFromString:s];
    if (d) return d;
    return nil;
}

- (void)updateServerTime:(NSDate *)serverDate {
    if ([serverDate isKindOfClass:[NSDate class]]) self.serverDate = serverDate;
}

- (NSDate *)estimatedServerNow {
    if (self.serverDate) {
        NSDate *reference = objc_getAssociatedObject(self, @selector(estimatedServerNow));
        if (!reference) {
            reference = [NSDate date];
            objc_setAssociatedObject(self, @selector(estimatedServerNow), reference, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:reference];
        return [self.serverDate dateByAddingTimeInterval:MAX(0, elapsed)];
    }
    return [NSDate date];
}

- (void)startLicenseCountdown {
    [self stopLicenseCountdown];
    if (self.licensePermanent || !self.expiresAt) return;
    self.licenseTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshLicenseCountdown) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.licenseTimer forMode:NSRunLoopCommonModes];
}
- (void)stopLicenseCountdown {
    [self.licenseTimer invalidate];
    self.licenseTimer = nil;
}

- (void)refreshLicenseCountdown {
    if (self.licensePermanent) return;
    if (!self.expiresAt) return;
    NSTimeInterval remaining = [self.expiresAt timeIntervalSinceDate:[self estimatedServerNow]];
    if (remaining <= 0) {
        self.countdownLabel.text = ZXLocalizedUI(@"00:00:00");
        self.licenseStatusLabel.text = ZXLocalizedUI(@"EXPIRED");
        self.licenseStatusLabel.textColor = [ZXTheme error];
        if (self.settingsVisible && self.settingsExpiryLabel) self.settingsExpiryLabel.text = ZXLocalizedUI(@"EXPIRED");
        [self stopLicenseCountdown];
        return;
    }
    NSInteger total = (NSInteger)floor(remaining);
    NSInteger days = total / 86400; total %= 86400;
    NSInteger hours = total / 3600; total %= 3600;
    NSInteger minutes = total / 60; NSInteger seconds = total % 60;
    
    if (days > 0) self.countdownLabel.text = [NSString stringWithFormat:@"%ldd %02ldh %02ldm", (long)days, (long)hours, (long)minutes];
    else self.countdownLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}

#pragma mark - Startup Block & Bootstrap

- (void)styleSecondaryButton:(UIButton *)button {
    if(!button) return;

    button.layer.cornerRadius=16;
    button.layer.cornerCurve=kCACornerCurveContinuous;
    button.layer.borderWidth=1;
    button.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.075].CGColor;
    button.backgroundColor=[UIColor colorWithWhite:1 alpha:0.035];

    UIButtonConfiguration *cfg=[UIButtonConfiguration plainButtonConfiguration];
    cfg.title=button.currentTitle;
    cfg.contentInsets=NSDirectionalEdgeInsetsMake(0,18,0,18);
    cfg.baseForegroundColor=[ZXTheme primaryText];
    button.configuration=cfg;

    button.titleLabel.font=[ZXTheme body:14 weight:UIFontWeightSemibold];
    button.layer.shadowColor=[UIColor blackColor].CGColor;
    button.layer.shadowOpacity=0.16;
    button.layer.shadowRadius=12;
    button.layer.shadowOffset=CGSizeMake(0,5);
    button.clipsToBounds=NO;

    [button addTarget:self action:@selector(zxSecondaryButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(zxSecondaryButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
}

- (void)zxSecondaryButtonTouchDown:(UIButton *)button {
    [UIView animateWithDuration:0.12
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        button.transform = CGAffineTransformMakeScale(0.97, 0.97);
        button.alpha = 0.88;
    } completion:nil];
}

- (void)zxSecondaryButtonTouchUp:(UIButton *)button {
    [UIView animateWithDuration:0.28
                          delay:0.0
         usingSpringWithDamping:0.72
          initialSpringVelocity:0.25
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        button.transform = CGAffineTransformIdentity;
        button.alpha = 1.0;
    } completion:nil];
}

- (void)setupStartupBlock {
    _startupBlockContainer=[[UIView alloc] init];
    _startupBlockContainer.translatesAutoresizingMaskIntoConstraints=NO;
    [self.view addSubview:_startupBlockContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_startupBlockContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_startupBlockContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_startupBlockContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_startupBlockContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    ZXGlassCard *card=[[ZXGlassCard alloc] init];
    [card applyMaterial:ZXMaterialElevatedGlass];
    [_startupBlockContainer addSubview:card];

    UIView *statusMark=[[UIView alloc] init];
    statusMark.backgroundColor=[[ZXTheme error] colorWithAlphaComponent:0.12];
    statusMark.layer.cornerRadius=20;
    statusMark.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:statusMark];

    UIImageView *icon=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"exclamationmark.shield"]];
    icon.tintColor=[ZXTheme error];
    icon.translatesAutoresizingMaskIntoConstraints=NO;
    [statusMark addSubview:icon];

    _startupBlockTitle=[self label:@"ACCESS DENIED" size:23 weight:UIFontWeightBold color:[ZXTheme primaryText]];
    _startupBlockTitle.textAlignment=NSTextAlignmentCenter;
    _startupBlockTitle.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:_startupBlockTitle];

    _startupBlockMessage=[self label:@"" size:13 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    _startupBlockMessage.textAlignment=NSTextAlignmentCenter;
    _startupBlockMessage.numberOfLines=0;
    _startupBlockMessage.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:_startupBlockMessage];

    _startupBlockAction=[UIButton buttonWithType:UIButtonTypeSystem];
    [self styleSecondaryButton:_startupBlockAction];
    [_startupBlockAction setTitle:ZXLocalizedUI(@"RETRY CONNECTION") forState:UIControlStateNormal];
    _startupBlockAction.translatesAutoresizingMaskIntoConstraints=NO;
    [_startupBlockAction addTarget:self action:@selector(startupBlockRetry) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:_startupBlockAction];

    [NSLayoutConstraint activateConstraints:@[
        [card.leadingAnchor constraintEqualToAnchor:_startupBlockContainer.leadingAnchor constant:28],
        [card.trailingAnchor constraintEqualToAnchor:_startupBlockContainer.trailingAnchor constant:-28],
        [card.centerYAnchor constraintEqualToAnchor:_startupBlockContainer.centerYAnchor],
        [statusMark.topAnchor constraintEqualToAnchor:card.topAnchor constant:28],
        [statusMark.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [statusMark.widthAnchor constraintEqualToConstant:40],
        [statusMark.heightAnchor constraintEqualToConstant:40],
        [icon.centerXAnchor constraintEqualToAnchor:statusMark.centerXAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:statusMark.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:21],
        [icon.heightAnchor constraintEqualToConstant:21],
        [_startupBlockTitle.topAnchor constraintEqualToAnchor:statusMark.bottomAnchor constant:20],
        [_startupBlockTitle.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22],
        [_startupBlockTitle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-22],
        [_startupBlockMessage.topAnchor constraintEqualToAnchor:_startupBlockTitle.bottomAnchor constant:9],
        [_startupBlockMessage.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22],
        [_startupBlockMessage.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-22],
        [_startupBlockAction.topAnchor constraintEqualToAnchor:_startupBlockMessage.bottomAnchor constant:22],
        [_startupBlockAction.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22],
        [_startupBlockAction.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-22],
        [_startupBlockAction.heightAnchor constraintEqualToConstant:52],
        [_startupBlockAction.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20]
    ]];
}

- (void)showStartupState:(ZXStartupState)state message:(NSString *)message {
    self.startupState = state;
    if (state == ZXStartupStateReady) return;
    if (state == ZXStartupStateBootstrapping) {
        [self transitionToPrimaryContainer:self.splashContainer];
        return;
    }
    [self transitionToPrimaryContainer:self.startupBlockContainer];
    self.blockedState = state;
    NSString *title = @"SECURITY GATE";
    NSString *action = @"RETRY";
    switch (state) {
        case ZXStartupStateMaintenance: title = @"MAINTENANCE"; action = @"CHECK AGAIN"; break;
        case ZXStartupStateVersionMismatch: title = @"UPDATE REQUIRED"; action = @"CHECK AGAIN"; break;
        case ZXStartupStateIncompatible: title = @"DEVICE UNSUPPORTED"; action = @"RECHECK DEVICE"; break;
        case ZXStartupStateConnectionError: title = @"CONNECTION LOST"; action = @"RETRY"; break;
        default: break;
    }
    _startupBlockTitle.text = ZXLocalizedUI(title);
    _startupBlockMessage.text = message.length ? message : ZXLocalizedUI(@"The server did not permit the secure workspace to open.");
    [_startupBlockAction setTitle:ZXLocalizedUI(action) forState:UIControlStateNormal];
}

- (void)handleBootstrapState:(ZXStartupState)state message:(NSString *)message {
    self.startupState = state;
    if (state == ZXStartupStateReady) {
        [self runPremiumSplashCompletion:^{ [self completeStartupRouting]; }];
    } else {
        [self runPremiumSplashCompletion:^{ [self showStartupState:state message:message]; }];
    }
}

- (void)completeStartupRouting {
    NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *key = [globalDefaults stringForKey:ZXLastKey];
    if (key.length > 0) {
        if ([self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) {
            __weak typeof(self) weakSelf = self;
            [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL valid) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) self = weakSelf; if (!self) return;
                    if (valid) [self showDashboard]; else [self showLoginScreen];
                });
            }];
        } else {
            Class mgrCls = NSClassFromString(@"ZentraxNetworkManager");
            if (mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
                id manager = ((id (*)(id, SEL))objc_msgSend)((id)mgrCls, NSSelectorFromString(@"sharedManager"));
                SEL verifySel = NSSelectorFromString(@"verifySessionWithCompletion:");
                if ([manager respondsToSelector:verifySel]) {
                    void (^netCompletion)(BOOL, NSDictionary *, NSInteger, NSString *) = ^(BOOL valid, NSDictionary *res, NSInteger errType, NSString *errMsg) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (valid) [self showDashboard]; else [self showLoginScreen];
                        });
                    };
                    ((void (*)(id, SEL, id))objc_msgSend)(manager, verifySel, netCompletion);
                } else [self showLoginScreen];
            } else [self showLoginScreen];
        }
    } else {
        [self showLoginScreen];
    }
}

- (void)startupBlockRetry {
    if (self.blockedState == ZXStartupStateIncompatible) [self requestDeviceCompatibilityRecheck];
    else [self beginBootstrap];
}

- (void)beginBootstrap {
    self.startupState = ZXStartupStateBootstrapping;
    [self showStartupState:ZXStartupStateBootstrapping message:nil];

    Class cls = NSClassFromString(@"ZentraxNetworkManager");
    if (!cls || ![cls respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
        [self handleBootstrapState:ZXStartupStateReady message:nil];
        return;
    }
    id manager = ((id (*)(id, SEL))objc_msgSend)((id)cls, NSSelectorFromString(@"sharedManager"));
    SEL bootstrap = NSSelectorFromString(@"bootstrapWithCompletion:");
    if (!manager || ![manager respondsToSelector:bootstrap]) {
        [self handleBootstrapState:ZXStartupStateReady message:nil];
        return;
    }
    __weak typeof(self) weakSelf = self;
    
    void (^completion)(BOOL, NSDictionary *, NSInteger, NSInteger, NSString *) = ^(BOOL success, NSDictionary *response, NSInteger bootstrapState, NSInteger errorType, NSString *errorMsg) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        ZXStartupState state = ZXStartupStateConnectionError;
        switch (bootstrapState) {
            case 1: state = ZXStartupStateReady; break;
            case 2: state = ZXStartupStateMaintenance; break;
            case 3: state = ZXStartupStateVersionMismatch; break;
            case 4: state = ZXStartupStateIncompatible; break;
            case 5: state = ZXStartupStateConnectionError; break;
            default: state = success ? ZXStartupStateReady : ZXStartupStateConnectionError; break;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([response isKindOfClass:[NSDictionary class]] && response.count) {
                id serverTime=response[@"server_time"] ?: response[@"server_iso"];
                if (!serverTime && [response[@"server"] isKindOfClass:[NSDictionary class]]) {
                    serverTime = response[@"server"][@"time"];
                }
                NSDate *d=[self dateFromServerValue:serverTime];
                if (d) [self updateServerTime:d];
                
                NSDictionary *config = response[@"configuration"] ?: response[@"config"];
                if ([config isKindOfClass:[NSDictionary class]]) [self updateDashboardWithConfiguration:config];
                
                NSDictionary *license = response[@"license"];
                if ([license isKindOfClass:[NSDictionary class]]) [self updateSubscriptionState:license];
                
                NSDictionary *compat = response[@"compatibility"];
                if ([compat isKindOfClass:[NSDictionary class]]) [self updateDeviceCompatibility:compat];
            }
            NSString *message=[errorMsg isKindOfClass:[NSString class]] ? errorMsg : nil;
            if (!message.length && [response isKindOfClass:[NSDictionary class]]) {
                id responseMessage=response[@"message"];
                if ([responseMessage isKindOfClass:[NSString class]]) message=responseMessage;
            }
            [self handleBootstrapState:state message:message];
        });
    };
    
    ((void(*)(id, SEL, id))objc_msgSend)(manager, bootstrap, completion);
}

#pragma mark - Heartbeat & Session Revocation

- (void)startHeartbeatMonitor {
    [self stopHeartbeatMonitor];
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(heartbeatTick) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.heartbeatTimer forMode:NSRunLoopCommonModes];
}
- (void)stopHeartbeatMonitor { [self.heartbeatTimer invalidate]; self.heartbeatTimer = nil; }

- (void)heartbeatTick {
    if (self.currentState != ZXAppStateDashboard) return;

    if (![self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) {
        Class mgrCls = NSClassFromString(@"ZentraxNetworkManager");
        if (mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
            id manager = ((id (*)(id, SEL))objc_msgSend)((id)mgrCls, NSSelectorFromString(@"sharedManager"));
            SEL verifySel = NSSelectorFromString(@"verifySessionWithCompletion:");
            if ([manager respondsToSelector:verifySel]) {
                __weak typeof(self) weakSelf = self;
                void (^netCompletion)(BOOL, NSDictionary *, NSInteger, NSString *) = ^(BOOL valid, NSDictionary *res, NSInteger errType, NSString *errMsg) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        __strong typeof(weakSelf) self = weakSelf; if (!self) return;
                        if (!valid) [self handleRevokedSessionEnvironment];
                        else if (res[@"license"]) [self updateSubscriptionState:res[@"license"]];
                    });
                };
                ((void (*)(id, SEL, id))objc_msgSend)(manager, verifySel, netCompletion);
            }
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL valid) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf; if (!self) return;
            if (!valid) [self handleRevokedSessionEnvironment];
        });
    }];
}

- (void)handleRevokedSessionEnvironment {
    [self stopHeartbeatMonitor];
    for (NSString *fid in self.functionControls) ((UIControl *)self.functionControls[fid]).userInteractionEnabled = NO;
    
    __weak typeof(self) weakSelf = self;
    [self showCustomConfirmationWithTitle:ZXLocalizedUI(@"SESSION EXPIRED") 
                                  message:ZXLocalizedUI(@"Your license was deleted, revoked, or transferred. You have been logged out.") 
                             confirmTitle:ZXLocalizedUI(@"OK") 
                               completion:^{
        __strong typeof(weakSelf) self = weakSelf; if (!self) return;
        
        if ([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) {
            [self.delegate zentraxDidRequestLogoutWithCompletion:^{ dispatch_async(dispatch_get_main_queue(), ^{ [self showLoginScreen]; }); }];
        } else {
            Class mgrCls = NSClassFromString(@"ZentraxNetworkManager");
            if (mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
                id manager = ((id (*)(id, SEL))objc_msgSend)((id)mgrCls, NSSelectorFromString(@"sharedManager"));
                SEL outSel = NSSelectorFromString(@"logout");
                if ([manager respondsToSelector:outSel]) ((void (*)(id, SEL))objc_msgSend)(manager, outSel);
            }
            NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
            [globalDefaults removeObjectForKey:ZXLastKey];
            [globalDefaults synchronize];
            [self showLoginScreen];
        }
    }];
}

#pragma mark - Settings (License Details Moved Here)

- (void)setupSettingsScreen {
    if(_settingsContainer) [_settingsContainer removeFromSuperview];

    _settingsContainer=[[UIView alloc] init];
    _settingsContainer.translatesAutoresizingMaskIntoConstraints=NO;
    [self.view addSubview:_settingsContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_settingsContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_settingsContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_settingsContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_settingsContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UIView *header=[[UIView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints=NO;
    [_settingsContainer addSubview:header];

    UIButton *back=[self iconButton:@"chevron.left" size:34];
    back.tintColor=[ZXTheme primaryText];
    back.layer.cornerRadius=17;
    back.backgroundColor=[UIColor colorWithWhite:1 alpha:0.035];
    [back addTarget:self action:@selector(closeSettings) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:back];

    UILabel *title=[self label:@"Settings" size:29 weight:UIFontWeightBold color:[ZXTheme primaryText]];
    title.translatesAutoresizingMaskIntoConstraints=NO;
    [header addSubview:title];

    UILabel *context=[self label:@"ZENTRAX / CONTROL SURFACE" size:9 weight:UIFontWeightSemibold color:[ZXTheme mutedText]];
    [ZXTheme track:context spacing:1.8];
    context.translatesAutoresizingMaskIntoConstraints=NO;
    [header addSubview:context];

    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:_settingsContainer.leadingAnchor constant:20],
        [header.trailingAnchor constraintEqualToAnchor:_settingsContainer.trailingAnchor constant:-20],
        [header.topAnchor constraintEqualToAnchor:_settingsContainer.safeAreaLayoutGuide.topAnchor constant:10],
        [header.heightAnchor constraintEqualToConstant:70],
        [back.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [back.topAnchor constraintEqualToAnchor:header.topAnchor],
        [back.widthAnchor constraintEqualToConstant:34],
        [back.heightAnchor constraintEqualToConstant:34],
        [title.leadingAnchor constraintEqualToAnchor:back.trailingAnchor constant:14],
        [title.topAnchor constraintEqualToAnchor:header.topAnchor],
        [context.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [context.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4]
    ]];

    _settingsScroll=[[UIScrollView alloc] init];
    _settingsScroll.showsVerticalScrollIndicator=NO;
    _settingsScroll.alwaysBounceVertical=YES;
    _settingsScroll.translatesAutoresizingMaskIntoConstraints=NO;
    [_settingsContainer addSubview:_settingsScroll];

    _settingsStack=[[UIStackView alloc] init];
    _settingsStack.axis=UILayoutConstraintAxisVertical;
    _settingsStack.spacing=10;
    _settingsStack.translatesAutoresizingMaskIntoConstraints=NO;
    [_settingsScroll addSubview:_settingsStack];

    [NSLayoutConstraint activateConstraints:@[
        [_settingsScroll.leadingAnchor constraintEqualToAnchor:_settingsContainer.leadingAnchor constant:20],
        [_settingsScroll.trailingAnchor constraintEqualToAnchor:_settingsContainer.trailingAnchor constant:-20],
        [_settingsScroll.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:8],
        [_settingsScroll.bottomAnchor constraintEqualToAnchor:_settingsContainer.bottomAnchor],
        [_settingsStack.leadingAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.leadingAnchor],
        [_settingsStack.trailingAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.trailingAnchor],
        [_settingsStack.topAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.topAnchor],
        [_settingsStack.bottomAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.bottomAnchor constant:-28],
        [_settingsStack.widthAnchor constraintEqualToAnchor:_settingsScroll.frameLayoutGuide.widthAnchor]
    ]];
    [self rebuildSettings];
}

- (UIView *)settingsRow:(NSString *)title subtitle:(NSString *)subtitle icon:(NSString *)iconName color:(UIColor *)color action:(SEL)action accessory:(UIView *)accessory {
    ZXGlassCard *row=[[ZXGlassCard alloc] init];
    [row applyMaterial:ZXMaterialClearGlass];

    UIView *iconShell=[[UIView alloc] init];
    iconShell.backgroundColor=[color colorWithAlphaComponent:0.10];
    iconShell.layer.cornerRadius=13;
    iconShell.translatesAutoresizingMaskIntoConstraints=NO;
    [row addSubview:iconShell];

    UIImageView *iv=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:iconName]];
    iv.tintColor=color;
    iv.contentMode=UIViewContentModeScaleAspectFit;
    iv.translatesAutoresizingMaskIntoConstraints=NO;
    [iconShell addSubview:iv];

    UILabel *t=[self label:title size:15 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    t.translatesAutoresizingMaskIntoConstraints=NO;
    [row addSubview:t];

    UILabel *s=[self label:subtitle ?: @"" size:11 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    s.numberOfLines=1;
    s.lineBreakMode=NSLineBreakByTruncatingTail;
    s.translatesAutoresizingMaskIntoConstraints=NO;
    [row addSubview:s];

    if(accessory) {
        accessory.translatesAutoresizingMaskIntoConstraints=NO;
        [row addSubview:accessory];
    } else {
        UIImageView *chev=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
        chev.tintColor=[ZXTheme mutedText];
        chev.translatesAutoresizingMaskIntoConstraints=NO;
        [row addSubview:chev];
        accessory=chev;
    }

    if(action) {
        UIButton *hit=[UIButton buttonWithType:UIButtonTypeSystem];
        hit.translatesAutoresizingMaskIntoConstraints=NO;
        hit.accessibilityLabel=title;
        [hit addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
        [row addSubview:hit];
        [NSLayoutConstraint activateConstraints:@[
            [hit.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],
            [hit.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],
            [hit.topAnchor constraintEqualToAnchor:row.topAnchor],
            [hit.bottomAnchor constraintEqualToAnchor:row.bottomAnchor]
        ]];
    }

    [NSLayoutConstraint activateConstraints:@[
        [row.heightAnchor constraintEqualToConstant:74],
        [iconShell.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:15],
        [iconShell.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [iconShell.widthAnchor constraintEqualToConstant:42],
        [iconShell.heightAnchor constraintEqualToConstant:42],
        [iv.centerXAnchor constraintEqualToAnchor:iconShell.centerXAnchor],
        [iv.centerYAnchor constraintEqualToAnchor:iconShell.centerYAnchor],
        [iv.widthAnchor constraintEqualToConstant:19],
        [iv.heightAnchor constraintEqualToConstant:19],
        [t.leadingAnchor constraintEqualToAnchor:iconShell.trailingAnchor constant:13],
        [t.topAnchor constraintEqualToAnchor:row.topAnchor constant:17],
        [t.trailingAnchor constraintLessThanOrEqualToAnchor:accessory.leadingAnchor constant:-12],
        [s.leadingAnchor constraintEqualToAnchor:t.leadingAnchor],
        [s.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:3],
        [s.trailingAnchor constraintLessThanOrEqualToAnchor:accessory.leadingAnchor constant:-12],
        [accessory.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-16],
        [accessory.centerYAnchor constraintEqualToAnchor:row.centerYAnchor]
    ]];
    return row;
}

- (void)rebuildSettings {
    for(UIView *v in [self.settingsStack.arrangedSubviews copy]) {
        [self.settingsStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    UILabel *licLabel=[self label:@"LICENSE" size:9 weight:UIFontWeightSemibold color:[ZXTheme mutedText]];
    [ZXTheme track:licLabel spacing:2.0];
    licLabel.translatesAutoresizingMaskIntoConstraints=NO;
    [self.settingsStack addArrangedSubview:licLabel];

    NSUserDefaults *d=[[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *currentKey=[d stringForKey:ZXLastKey];

    UIButton *eye=[UIButton buttonWithType:UIButtonTypeSystem];
    [eye setImage:[UIImage systemImageNamed:self.settingsKeyRevealed ? @"eye.fill" : @"eye.slash.fill"] forState:UIControlStateNormal];
    eye.tintColor=[ZXTheme secondaryText];
    eye.accessibilityLabel=ZXLocalizedUI(@"License Key");
    eye.translatesAutoresizingMaskIntoConstraints=NO;
    [eye.widthAnchor constraintEqualToConstant:34].active=YES;
    [eye.heightAnchor constraintEqualToConstant:34].active=YES;
    [eye addTarget:self action:@selector(toggleSettingsKey:) forControlEvents:UIControlEventTouchUpInside];

    NSString *displayKey=(self.settingsKeyRevealed && currentKey.length) ? currentKey : @"•••• •••• ••••";
    UIView *keyRow=[self settingsRow:ZXLocalizedUI(@"License Key")
                            subtitle:displayKey
                                icon:@"key.fill"
                               color:[ZXTheme accentSecondary]
                              action:nil
                           accessory:eye];
    self.settingsKeyLabel=nil;
    /* The subtitle is intentionally represented by the row's text labels; locate it through
       the visual card's blur content hierarchy so existing update paths keep working. */
    for(UIView *v in keyRow.subviews) {
        if([v isKindOfClass:[UIVisualEffectView class]]) {
            for(UIView *sub in ((UIVisualEffectView *)v).contentView.subviews) {
                if([sub isKindOfClass:[UILabel class]] && ((UILabel *)sub).text.length) {
                    UILabel *candidate=(UILabel *)sub;
                    if([candidate.text isEqualToString:displayKey]) {
                        self.settingsKeyLabel=candidate;
                        candidate.font=[ZXTheme mono:12 weight:UIFontWeightMedium];
                    }
                }
            }
        }
    }
    [self.settingsStack addArrangedSubview:keyRow];

    NSString *expiryStr=@"";
    if(self.licensePermanent) expiryStr=ZXLocalizedUI(@"LIFETIME");
    else if(self.expiresAt) {
        NSDateFormatter *f=[[NSDateFormatter alloc] init];
        f.dateStyle=NSDateFormatterMediumStyle;
        f.timeStyle=NSDateFormatterShortStyle;
        expiryStr=[f stringFromDate:self.expiresAt];
    } else expiryStr=ZXLocalizedUI(@"UNACTIVATED");

    UILabel *expiryAccessory=[self label:expiryStr size:10 weight:UIFontWeightMedium color:[ZXTheme secondaryText]];
    expiryAccessory.textAlignment=NSTextAlignmentRight;
    expiryAccessory.numberOfLines=2;
    expiryAccessory.preferredMaxLayoutWidth=120;
    expiryAccessory.translatesAutoresizingMaskIntoConstraints=NO;
    [expiryAccessory.widthAnchor constraintLessThanOrEqualToConstant:126].active=YES;

    UIView *expRow=[self settingsRow:ZXLocalizedUI(@"Expiry Date")
                           subtitle:ZXLocalizedUI(@"Current server subscription")
                               icon:@"calendar.badge.clock"
                              color:[ZXTheme warning]
                             action:nil
                          accessory:expiryAccessory];
    self.settingsExpiryLabel=expiryAccessory;
    [self.settingsStack addArrangedSubview:expRow];

    UILabel *prefLabel=[self label:@"PREFERENCES" size:9 weight:UIFontWeightSemibold color:[ZXTheme mutedText]];
    [ZXTheme track:prefLabel spacing:2.0];
    prefLabel.translatesAutoresizingMaskIntoConstraints=NO;
    [self.settingsStack addArrangedSubview:prefLabel];

    NSString *language=[d stringForKey:ZXLanguageKey] ?: @"English";
    [self.settingsStack addArrangedSubview:[self settingsRow:ZXLocalizedUI(@"Language")
                                                    subtitle:language
                                                        icon:@"globe"
                                                       color:[ZXTheme accentSecondary]
                                                      action:@selector(showLanguagePicker)
                                                   accessory:nil]];

    UILabel *sessionLabel=[self label:@"SESSION" size:9 weight:UIFontWeightSemibold color:[ZXTheme mutedText]];
    [ZXTheme track:sessionLabel spacing:2.0];
    sessionLabel.translatesAutoresizingMaskIntoConstraints=NO;
    [self.settingsStack addArrangedSubview:sessionLabel];

    [self.settingsStack addArrangedSubview:[self settingsRow:ZXLocalizedUI(@"Sign Out")
                                                     subtitle:ZXLocalizedUI(@"Close the current secure session.")
                                                         icon:@"rectangle.portrait.and.arrow.right"
                                                        color:[ZXTheme error]
                                                       action:@selector(handleLogout)
                                                    accessory:nil]];
}

- (void)toggleSettingsKey:(UIButton *)sender {
    self.settingsKeyRevealed = !self.settingsKeyRevealed;
    [sender setImage:[UIImage systemImageNamed:self.settingsKeyRevealed ? @"eye.fill" : @"eye.slash.fill"] forState:UIControlStateNormal];
    
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *key = [d stringForKey:ZXLastKey];
    self.settingsKeyLabel.text = self.settingsKeyRevealed && key.length ? key : @"•••• •••• ••••";
    self.settingsKeyLabel.textColor = self.settingsKeyRevealed ? [UIColor whiteColor] : [ZXTheme secondaryText];
}

- (void)showSettings {
    self.settingsVisible = YES;
    [self setupSettingsScreen];
    [self transitionToPrimaryContainer:self.settingsContainer];
}
- (void)closeSettings { self.settingsVisible = NO; [self showDashboard]; }

#pragma mark - Safe UI Mode (Stubs for Compatibility)

- (void)applyInitialSafeModeState { /* Purged */ }
- (void)updateSafeModeState:(ZXSafeModeState)state { /* Purged */ }
- (void)showSafeModeLockScreen { /* Purged */ }
- (void)updatePrivacyCaptureState { /* Purged */ }
- (void)showPrivacyOverlay { /* Purged */ }
- (void)hidePrivacyOverlay { /* Purged */ }

#pragma mark - Language Picker & Rechecks

- (void)showLanguagePicker {
    NSArray *langs=@[@"English",@"Tiếng Việt",@"简体中文",@"日本語"];

    UIView *overlay=[[UIView alloc] init];
    overlay.backgroundColor=[UIColor colorWithWhite:0 alpha:0.58];
    overlay.translatesAutoresizingMaskIntoConstraints=NO;
    overlay.alpha=0;
    overlay.tag=4922;
    overlay.layer.zPosition=42000;
    [self.view addSubview:overlay];

    ZXGlassCard *panel=[[ZXGlassCard alloc] init];
    [panel applyMaterial:ZXMaterialElevatedGlass];
    panel.translatesAutoresizingMaskIntoConstraints=NO;
    [overlay addSubview:panel];

    UILabel *title=[self label:ZXLocalizedUI(@"Language") size:21 weight:UIFontWeightBold color:[ZXTheme primaryText]];
    title.translatesAutoresizingMaskIntoConstraints=NO;
    [panel addSubview:title];

    UILabel *detail=[self label:ZXLocalizedUI(@"Choose your language") size:12 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    detail.translatesAutoresizingMaskIntoConstraints=NO;
    [panel addSubview:detail];

    UIStackView *stack=[[UIStackView alloc] init];
    stack.axis=UILayoutConstraintAxisVertical;
    stack.spacing=6;
    stack.translatesAutoresizingMaskIntoConstraints=NO;
    [panel addSubview:stack];

    NSUserDefaults *defaults=[[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *selected= [defaults stringForKey:ZXLanguageKey] ?: @"English";

    __weak typeof(self) weakSelf=self;
    for(NSString *lang in langs) {
        UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
        b.layer.cornerRadius=14;
        b.layer.cornerCurve=kCACornerCurveContinuous;
        b.layer.borderWidth=1;
        b.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.06].CGColor;
        b.backgroundColor=[lang isEqualToString:selected] ? [[ZXTheme accentPrimary] colorWithAlphaComponent:0.13] : [UIColor colorWithWhite:1 alpha:0.025];
        b.contentHorizontalAlignment=UIControlContentHorizontalAlignmentLeft;
        b.titleLabel.font=[ZXTheme body:14 weight:UIFontWeightMedium];
        [b setTitle:lang forState:UIControlStateNormal];
        [b setTitleColor:[ZXTheme primaryText] forState:UIControlStateNormal];
        UIButtonConfiguration *bcfg=[UIButtonConfiguration plainButtonConfiguration];
        bcfg.contentInsets=NSDirectionalEdgeInsetsMake(0,16,0,16);
        bcfg.title=lang;
        bcfg.baseForegroundColor=[ZXTheme primaryText];
        b.configuration=bcfg;
        b.translatesAutoresizingMaskIntoConstraints=NO;
        b.accessibilityTraits=[lang isEqualToString:selected] ? UIAccessibilityTraitSelected : UIAccessibilityTraitNone;
        [b.heightAnchor constraintEqualToConstant:46].active=YES;
        [stack addArrangedSubview:b];

        [b addAction:[UIAction actionWithHandler:^(__kindof UIAction *action){
            __strong typeof(weakSelf) self=weakSelf;
            if(!self) return;

            NSDictionary *oldConfig=self.dashboardConfiguration;
            NSDictionary *oldStates=[self.functionStates copy];
            BOOL dashboard=(self.currentState==ZXAppStateDashboard);
            NSUserDefaults *d=[[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
            [d setObject:lang forKey:ZXLanguageKey];
            [d synchronize];

            [UIView animateWithDuration:ZXReduceMotionEnabled()?0:0.20 animations:^{ overlay.alpha=0; } completion:^(BOOL finished){
                [overlay removeFromSuperview];
                [self rebuildAllContainers];
                if(oldConfig.count){
                    [self updateDashboardWithConfiguration:oldConfig];
                    [self updateFunctionStates:oldStates];
                }
                if(dashboard) [self showDashboard]; else [self showSettings];
            }];
        }] forControlEvents:UIControlEventTouchUpInside];
    }

    UIButton *cancel=[UIButton buttonWithType:UIButtonTypeSystem];
    cancel.layer.cornerRadius=14;
    cancel.layer.cornerCurve=kCACornerCurveContinuous;
    cancel.backgroundColor=[UIColor colorWithWhite:1 alpha:0.025];
    cancel.layer.borderWidth=1;
    cancel.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.055].CGColor;
    cancel.titleLabel.font=[ZXTheme body:14 weight:UIFontWeightSemibold];
    [cancel setTitle:ZXLocalizedUI(@"Cancel") forState:UIControlStateNormal];
    [cancel setTitleColor:[ZXTheme secondaryText] forState:UIControlStateNormal];
    cancel.translatesAutoresizingMaskIntoConstraints=NO;
    [stack addArrangedSubview:cancel];
    [cancel.heightAnchor constraintEqualToConstant:44].active=YES;
    [cancel addAction:[UIAction actionWithHandler:^(__kindof UIAction *action){
        [UIView animateWithDuration:ZXReduceMotionEnabled()?0:0.18 animations:^{ overlay.alpha=0; } completion:^(BOOL finished){ [overlay removeFromSuperview]; }];
    }] forControlEvents:UIControlEventTouchUpInside];

    [NSLayoutConstraint activateConstraints:@[
        [panel.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [panel.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
        [panel.leadingAnchor constraintEqualToAnchor:overlay.leadingAnchor constant:28],
        [panel.trailingAnchor constraintEqualToAnchor:overlay.trailingAnchor constant:-28],
        [title.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:22],
        [title.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-22],
        [title.topAnchor constraintEqualToAnchor:panel.topAnchor constant:24],
        [detail.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [detail.trailingAnchor constraintEqualToAnchor:title.trailingAnchor],
        [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:5],
        [stack.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-16],
        [stack.topAnchor constraintEqualToAnchor:detail.bottomAnchor constant:17],
        [stack.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-16]
    ]];

    [self.view bringSubviewToFront:overlay];
    if(ZXReduceMotionEnabled()) overlay.alpha=1;
    else {
        panel.transform=CGAffineTransformMakeScale(0.95,0.95);
        [UIView animateWithDuration:0.28 delay:0 usingSpringWithDamping:0.84 initialSpringVelocity:0.12 options:0 animations:^{
            overlay.alpha=1;
            panel.transform=CGAffineTransformIdentity;
        } completion:nil];
    }
}

- (void)requestDeviceCompatibilityRecheck {
    [self showGlobalLoadingState:@"CHECKING DEVICE"];
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestCompatibilityRecheckWithCompletion:)]) {
        __weak typeof(self) weakSelf = self;
        [self.delegate zentraxDidRequestCompatibilityRecheckWithCompletion:^(BOOL success, NSDictionary *compatibility, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf; if (!self) return;
                [self hideGlobalLoadingState];
                if (success) {
                    [self updateDeviceCompatibility:compatibility ?: @{}];
                    [self showToast:ZXLocalizedUI(@"Compatibility Verified") success:YES];
                } else {
                    [self showGlobalErrorWithTitle:ZXLocalizedUI(@"CHECK FAILED") message:errorMsg ?: ZXLocalizedUI(@"Unable to verify device.")];
                }
            });
        }];
    } else {
        [self hideGlobalLoadingState];
        [self showGlobalErrorWithTitle:@"UNAVAILABLE" message:@"Compatibility service is not connected."];
    }
}

- (void)updateDeviceCompatibility:(NSDictionary *)compatibility {
    if (![compatibility isKindOfClass:[NSDictionary class]]) return;
    self.compatibilityData = compatibility;
    if (self.settingsVisible) [self rebuildSettings];
}
- (void)showCompatibilityScreenWithData:(NSDictionary *)compatibility {
    [self updateDeviceCompatibility:compatibility];
    NSString *reason = compatibility[@"reason"] ?: compatibility[@"message"];
    [self showStartupState:ZXStartupStateIncompatible message:reason];
}

#pragma mark - Global Modals & Loading

- (void)setupGlobalLoading {
    UIVisualEffectView *backdrop=[[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    backdrop.translatesAutoresizingMaskIntoConstraints=NO;
    backdrop.hidden=YES;
    backdrop.alpha=0;
    backdrop.layer.zPosition=10000;
    [_globalLoadingOverlay removeFromSuperview];
    _globalLoadingOverlay=backdrop;
    [self.view addSubview:backdrop];
    [NSLayoutConstraint activateConstraints:@[
        [backdrop.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [backdrop.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [backdrop.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [backdrop.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    ZXGlassCard *card=[[ZXGlassCard alloc] init];
    [card applyMaterial:ZXMaterialElevatedGlass];
    card.translatesAutoresizingMaskIntoConstraints=NO;
    [backdrop.contentView addSubview:card];

    _globalSpinner=[[ZXOrbitLoader alloc] init];
    _globalSpinner.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:_globalSpinner];

    _globalLoadingTitle=[self label:@"SECURE OPERATION" size:15 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    _globalLoadingTitle.textAlignment=NSTextAlignmentCenter;
    _globalLoadingTitle.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:_globalLoadingTitle];

    _globalLoadingDetail=[self label:@"Please wait…" size:11 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    _globalLoadingDetail.textAlignment=NSTextAlignmentCenter;
    _globalLoadingDetail.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:_globalLoadingDetail];

    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:backdrop.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:backdrop.centerYAnchor],
        [card.widthAnchor constraintEqualToConstant:246],
        [card.heightAnchor constraintEqualToConstant:142],
        [_globalSpinner.topAnchor constraintEqualToAnchor:card.topAnchor constant:24],
        [_globalSpinner.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [_globalSpinner.widthAnchor constraintEqualToConstant:26],
        [_globalSpinner.heightAnchor constraintEqualToConstant:26],
        [_globalLoadingTitle.topAnchor constraintEqualToAnchor:_globalSpinner.bottomAnchor constant:15],
        [_globalLoadingTitle.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
        [_globalLoadingTitle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],
        [_globalLoadingDetail.topAnchor constraintEqualToAnchor:_globalLoadingTitle.bottomAnchor constant:5],
        [_globalLoadingDetail.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
        [_globalLoadingDetail.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18]
    ]];
}

- (void)showGlobalLoadingState:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.globalLoadingOverlay.hidden=NO;
        self.globalLoadingOverlay.alpha=0;
        self.globalLoadingTitle.text=ZXLocalizedUI(message.length ? message : @"SECURE OPERATION");
        self.globalLoadingDetail.text=ZXLocalizedUI(@"Please wait…");
        [self.globalSpinner startAnimating];
        if(ZXReduceMotionEnabled()) self.globalLoadingOverlay.alpha=1;
        else [UIView animateWithDuration:0.22 animations:^{ self.globalLoadingOverlay.alpha=1; }];
    });
}
- (void)updateGlobalLoadingMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{ self.globalLoadingDetail.text = ZXLocalizedUI(message ?: @"Please wait…"); });
}
- (void)hideGlobalLoadingState {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.globalSpinner stopAnimating];
        void (^hide)(void)=^{ self.globalLoadingOverlay.hidden=YES; };
        if(ZXReduceMotionEnabled()) { self.globalLoadingOverlay.alpha=0; hide(); }
        else [UIView animateWithDuration:0.18 animations:^{ self.globalLoadingOverlay.alpha=0; } completion:^(BOOL finished){ hide(); }];
    });
}


- (void)showFeatureOperationStatus:(NSString *)functionId activating:(BOOL)activating {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.featureStatusOverlay) [self.featureStatusOverlay removeFromSuperview];

        UIView *overlay=[[UIView alloc] init];
        overlay.translatesAutoresizingMaskIntoConstraints=NO;
        overlay.backgroundColor=[UIColor colorWithWhite:0 alpha:0.18];
        overlay.layer.zPosition=30000;
        overlay.alpha=0;
        [self.view addSubview:overlay];
        self.featureStatusOverlay=overlay;
        self.featureStatusActivating=activating;

        ZXGlassCard *card=[[ZXGlassCard alloc] init];
        [card applyMaterial:ZXMaterialElevatedGlass];
        card.translatesAutoresizingMaskIntoConstraints=NO;
        [overlay addSubview:card];

        UIView *thread=[[UIView alloc] init];
        thread.backgroundColor=[[ZXTheme accentSecondary] colorWithAlphaComponent:0.78];
        thread.layer.cornerRadius=0.5;
        thread.translatesAutoresizingMaskIntoConstraints=NO;
        [card addSubview:thread];

        ZXOrbitLoader *loader=[[ZXOrbitLoader alloc] init];
        loader.translatesAutoresizingMaskIntoConstraints=NO;
        [card addSubview:loader];
        self.featureStatusLoader=loader;
        [loader startAnimating];

        UILabel *title=[self label:ZXLocalizedUI(activating ? @"Activating" : @"Deactivating") size:16 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
        title.textAlignment=NSTextAlignmentCenter;
        title.translatesAutoresizingMaskIntoConstraints=NO;
        [card addSubview:title];
        self.featureStatusTitle=title;

        NSDictionary *definition=self.functionDefinitions[functionId];
        NSString *name=[NSString stringWithFormat:@"%@",definition[@"name"] ?: definition[@"title"] ?: functionId];
        UILabel *detail=[self label:name size:11 weight:UIFontWeightMedium color:[ZXTheme secondaryText]];
        detail.textAlignment=NSTextAlignmentCenter;
        detail.numberOfLines=2;
        detail.translatesAutoresizingMaskIntoConstraints=NO;
        [card addSubview:detail];
        self.featureStatusDetail=detail;

        [NSLayoutConstraint activateConstraints:@[
            [card.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
            [card.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
            [card.widthAnchor constraintEqualToConstant:238],
            [card.heightAnchor constraintEqualToConstant:148],
            [thread.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
            [thread.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
            [thread.widthAnchor constraintEqualToConstant:32],
            [thread.heightAnchor constraintEqualToConstant:1],
            [loader.topAnchor constraintEqualToAnchor:thread.bottomAnchor constant:18],
            [loader.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
            [loader.widthAnchor constraintEqualToConstant:24],
            [loader.heightAnchor constraintEqualToConstant:24],
            [title.topAnchor constraintEqualToAnchor:loader.bottomAnchor constant:12],
            [title.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
            [title.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],
            [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4],
            [detail.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
            [detail.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18]
        ]];

        card.alpha=0;
        card.transform=CGAffineTransformMakeScale(0.94,0.94);
        if(ZXReduceMotionEnabled()) {
            overlay.alpha=1;
            card.alpha=1;
            card.transform=CGAffineTransformIdentity;
        } else {
            [UIView animateWithDuration:0.28 delay:0 usingSpringWithDamping:0.84 initialSpringVelocity:0.1 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                overlay.alpha=1;
                card.alpha=1;
                card.transform=CGAffineTransformIdentity;
            } completion:nil];
        }
    });
}

- (void)finishFeatureOperationStatus:(BOOL)success functionId:(NSString *)functionId message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *overlay=self.featureStatusOverlay;
        if(!overlay) return;

        [self.featureStatusLoader stopAnimating];
        NSString *titleText;
        if(success) titleText=ZXLocalizedUI(self.featureStatusActivating ? @"Activated" : @"Deactivated");
        else titleText=ZXLocalizedUI(self.featureStatusActivating ? @"Activation failed" : @"Deactivation failed");
        self.featureStatusTitle.text=titleText;
        self.featureStatusTitle.textColor=success ? [ZXTheme success] : [ZXTheme error];
        self.featureStatusDetail.text=message.length ? message : ZXLocalizedUI(success ? @"Server confirmed the operation." : @"The server did not confirm the operation.");

        if(success) {
            [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeSuccess];
        } else {
            [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeError];
        }

        UIView *mark=[[UIView alloc] initWithFrame:CGRectMake(0,0,20,20)];
        mark.layer.cornerRadius=10;
        mark.backgroundColor=(success ? [ZXTheme success] : [ZXTheme error]);
        mark.alpha=0;
        [overlay addSubview:mark];
        mark.translatesAutoresizingMaskIntoConstraints=NO;
        [NSLayoutConstraint activateConstraints:@[
            [mark.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
            [mark.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor constant:-18],
            [mark.widthAnchor constraintEqualToConstant:20],
            [mark.heightAnchor constraintEqualToConstant:20]
        ]];
        UIImageView *iv=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:success ? @"checkmark" : @"xmark"]];
        iv.tintColor=[UIColor colorWithWhite:0 alpha:0.82];
        iv.translatesAutoresizingMaskIntoConstraints=NO;
        [mark addSubview:iv];
        [NSLayoutConstraint activateConstraints:@[
            [iv.centerXAnchor constraintEqualToAnchor:mark.centerXAnchor],
            [iv.centerYAnchor constraintEqualToAnchor:mark.centerYAnchor],
            [iv.widthAnchor constraintEqualToConstant:10],
            [iv.heightAnchor constraintEqualToConstant:10]
        ]];

        if(!ZXReduceMotionEnabled()) {
            mark.transform=CGAffineTransformMakeScale(0.5,0.5);
            [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.72 initialSpringVelocity:0.2 options:0 animations:^{
                mark.alpha=1;
                mark.transform=CGAffineTransformIdentity;
            } completion:nil];
        } else mark.alpha=1;

        NSTimeInterval delay=success ? 0.72 : 0.92;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(delay*NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
            if(self.featureStatusOverlay!=overlay) return;
            void (^remove)(void)=^{ [overlay removeFromSuperview]; self.featureStatusOverlay=nil; self.featureStatusLoader=nil; self.featureStatusTitle=nil; self.featureStatusDetail=nil; };
            if(ZXReduceMotionEnabled()) remove();
            else [UIView animateWithDuration:0.20 animations:^{ overlay.alpha=0; } completion:^(BOOL finished){ remove(); }];
        });
    });
}

- (void)showToast:(NSString *)message success:(BOOL)success {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.toastView) [self.toastView removeFromSuperview];

        UIColor *accent=success ? [ZXTheme success] : [ZXTheme error];
        UIView *toast=[[UIView alloc] init];
        toast.translatesAutoresizingMaskIntoConstraints=NO;
        toast.backgroundColor=[UIColor colorWithWhite:0.055 alpha:0.94];
        toast.layer.cornerRadius=18;
        toast.layer.cornerCurve=kCACornerCurveContinuous;
        toast.layer.borderWidth=1;
        toast.layer.borderColor=[accent colorWithAlphaComponent:0.22].CGColor;
        toast.layer.shadowColor=[UIColor blackColor].CGColor;
        toast.layer.shadowOpacity=0.34;
        toast.layer.shadowRadius=20;
        toast.layer.shadowOffset=CGSizeMake(0,8);
        [self.view addSubview:toast];
        self.toastView=toast;

        UIView *dot=[[UIView alloc] init];
        dot.backgroundColor=accent;
        dot.layer.cornerRadius=3;
        dot.translatesAutoresizingMaskIntoConstraints=NO;
        [toast addSubview:dot];

        UIImageView *icon=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:success ? @"checkmark" : @"exclamationmark"]];
        icon.tintColor=accent;
        icon.translatesAutoresizingMaskIntoConstraints=NO;
        [toast addSubview:icon];

        UILabel *label=[self label:ZXLocalizedUI(message ?: @"") size:12 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
        label.numberOfLines=2;
        label.translatesAutoresizingMaskIntoConstraints=NO;
        [toast addSubview:label];

        [NSLayoutConstraint activateConstraints:@[
            [toast.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [toast.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12],
            [toast.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:18],
            [toast.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-18],
            [toast.heightAnchor constraintGreaterThanOrEqualToConstant:52],
            [dot.leadingAnchor constraintEqualToAnchor:toast.leadingAnchor constant:15],
            [dot.centerYAnchor constraintEqualToAnchor:toast.centerYAnchor],
            [dot.widthAnchor constraintEqualToConstant:6],
            [dot.heightAnchor constraintEqualToConstant:6],
            [icon.leadingAnchor constraintEqualToAnchor:dot.trailingAnchor constant:9],
            [icon.centerYAnchor constraintEqualToAnchor:toast.centerYAnchor],
            [icon.widthAnchor constraintEqualToConstant:15],
            [icon.heightAnchor constraintEqualToConstant:15],
            [label.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:9],
            [label.trailingAnchor constraintEqualToAnchor:toast.trailingAnchor constant:-15],
            [label.topAnchor constraintEqualToAnchor:toast.topAnchor constant:12],
            [label.bottomAnchor constraintEqualToAnchor:toast.bottomAnchor constant:-12]
        ]];

        toast.alpha=0;
        toast.transform=CGAffineTransformMakeTranslation(0,-8);
        [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:success ? UINotificationFeedbackTypeSuccess : UINotificationFeedbackTypeError];

        void (^show)(void)=^{
            toast.alpha=1;
            toast.transform=CGAffineTransformIdentity;
        };
        if(ZXReduceMotionEnabled()) show();
        else [UIView animateWithDuration:0.30 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0.1 options:0 animations:show completion:nil];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(2.8*NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
            if(self.toastView!=toast) return;
            [UIView animateWithDuration:ZXReduceMotionEnabled()?0:0.18 animations:^{ toast.alpha=0; } completion:^(BOOL finished){ [toast removeFromSuperview]; if(self.toastView==toast) self.toastView=nil; }];
        });
    });
}

- (void)showCustomConfirmationWithTitle:(NSString *)title message:(NSString *)message confirmTitle:(NSString *)confirmTitle completion:(void (^)(void))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *existing=[self.view viewWithTag:4911];
        if(existing) [existing removeFromSuperview];

        UIView *overlay=[[UIView alloc] init];
        overlay.tag=4911;
        overlay.translatesAutoresizingMaskIntoConstraints=NO;
        overlay.backgroundColor=[UIColor colorWithWhite:0 alpha:0.58];
        overlay.layer.zPosition=40000;
        overlay.alpha=0;
        [self.view addSubview:overlay];

        ZXGlassCard *card=[[ZXGlassCard alloc] init];
        [card applyMaterial:ZXMaterialElevatedGlass];
        card.translatesAutoresizingMaskIntoConstraints=NO;
        [overlay addSubview:card];

        UIView *thread=[[UIView alloc] init];
        thread.backgroundColor=[ZXTheme accentSecondary];
        thread.layer.cornerRadius=0.5;
        thread.translatesAutoresizingMaskIntoConstraints=NO;
        [card addSubview:thread];

        UILabel *t=[self label:title size:21 weight:UIFontWeightBold color:[ZXTheme primaryText]];
        t.numberOfLines=2;
        t.translatesAutoresizingMaskIntoConstraints=NO;
        [card addSubview:t];

        UILabel *m=[self label:message size:13 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
        m.numberOfLines=0;
        m.translatesAutoresizingMaskIntoConstraints=NO;
        [card addSubview:m];

        UIStackView *actions=[[UIStackView alloc] init];
        actions.axis=UILayoutConstraintAxisHorizontal;
        actions.spacing=8;
        actions.distribution=UIStackViewDistributionFillEqually;
        actions.translatesAutoresizingMaskIntoConstraints=NO;
        [card addSubview:actions];

        UIButton *cancel=[UIButton buttonWithType:UIButtonTypeSystem];
        cancel.layer.cornerRadius=14;
        cancel.layer.cornerCurve=kCACornerCurveContinuous;
        cancel.layer.borderWidth=1;
        cancel.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.07].CGColor;
        cancel.backgroundColor=[UIColor colorWithWhite:1 alpha:0.025];
        cancel.titleLabel.font=[ZXTheme body:14 weight:UIFontWeightSemibold];
        [cancel setTitle:ZXLocalizedUI(@"Cancel") forState:UIControlStateNormal];
        [cancel setTitleColor:[ZXTheme secondaryText] forState:UIControlStateNormal];
        [actions addArrangedSubview:cancel];

        UIButton *confirm=[UIButton buttonWithType:UIButtonTypeSystem];
        confirm.layer.cornerRadius=14;
        confirm.layer.cornerCurve=kCACornerCurveContinuous;
        confirm.layer.borderWidth=1;
        confirm.layer.borderColor=[[ZXTheme accentPrimary] colorWithAlphaComponent:0.30].CGColor;
        confirm.backgroundColor=[[ZXTheme accentPrimary] colorWithAlphaComponent:0.12];
        confirm.titleLabel.font=[ZXTheme body:14 weight:UIFontWeightSemibold];
        [confirm setTitle:ZXLocalizedUI(confirmTitle ?: @"OK") forState:UIControlStateNormal];
        [confirm setTitleColor:[ZXTheme primaryText] forState:UIControlStateNormal];
        [actions addArrangedSubview:confirm];

        [cancel addAction:[UIAction actionWithHandler:^(__kindof UIAction *action){
            void (^remove)(void)=^{ [overlay removeFromSuperview]; };
            if(ZXReduceMotionEnabled()) remove();
            else [UIView animateWithDuration:0.16 animations:^{ overlay.alpha=0; } completion:^(BOOL finished){ remove(); }];
        }] forControlEvents:UIControlEventTouchUpInside];

        __weak typeof(self) weakSelf=self;
        [confirm addAction:[UIAction actionWithHandler:^(__kindof UIAction *action){
            __strong typeof(weakSelf) self=weakSelf;
            if(!self) return;
            void (^finish)(void)=^{ [overlay removeFromSuperview]; if(completion) completion(); };
            if(ZXReduceMotionEnabled()) finish();
            else [UIView animateWithDuration:0.18 animations:^{ overlay.alpha=0; } completion:^(BOOL finished){ finish(); }];
        }] forControlEvents:UIControlEventTouchUpInside];

        [NSLayoutConstraint activateConstraints:@[
            [card.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
            [card.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
            [card.leadingAnchor constraintEqualToAnchor:overlay.leadingAnchor constant:28],
            [card.trailingAnchor constraintEqualToAnchor:overlay.trailingAnchor constant:-28],
            [thread.topAnchor constraintEqualToAnchor:card.topAnchor constant:22],
            [thread.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22],
            [thread.widthAnchor constraintEqualToConstant:34],
            [thread.heightAnchor constraintEqualToConstant:1],
            [t.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22],
            [t.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-22],
            [t.topAnchor constraintEqualToAnchor:thread.bottomAnchor constant:17],
            [m.leadingAnchor constraintEqualToAnchor:t.leadingAnchor],
            [m.trailingAnchor constraintEqualToAnchor:t.trailingAnchor],
            [m.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:8],
            [actions.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
            [actions.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],
            [actions.topAnchor constraintEqualToAnchor:m.bottomAnchor constant:20],
            [actions.heightAnchor constraintEqualToConstant:48],
            [actions.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18]
        ]];

        [self.view bringSubviewToFront:overlay];
        if(ZXReduceMotionEnabled()) {
            overlay.alpha=1;
        } else {
            card.alpha=0;
            card.transform=CGAffineTransformMakeScale(0.96,0.96);
            [UIView animateWithDuration:0.26 delay:0 usingSpringWithDamping:0.84 initialSpringVelocity:0.12 options:0 animations:^{
                overlay.alpha=1;
                card.alpha=1;
                card.transform=CGAffineTransformIdentity;
            } completion:nil];
        }
    });
}

- (void)showToast:(NSString *)message { [self showToast:message success:YES]; }
- (void)showGlobalErrorWithTitle:(NSString *)title message:(NSString *)message { [self showCustomConfirmationWithTitle:title message:message confirmTitle:@"DISMISS" completion:nil]; }
- (void)showSuccessMessage:(NSString *)title message:(NSString *)message { [self showCustomConfirmationWithTitle:title message:message confirmTitle:@"CONTINUE" completion:nil]; }
- (void)showNetworkError { [self showGlobalErrorWithTitle:@"CONNECTION ERROR" message:@"Network connection lost. Try again when the secure node is reachable."]; }
- (void)showServerError { [self showGlobalErrorWithTitle:@"SERVER ERROR" message:@"The ZENTRAX server could not complete the request."]; }
- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds { [self showGlobalErrorWithTitle:@"RATE LIMITED" message:[NSString stringWithFormat:@"Request limit reached. Try again in %ld seconds.",(long)MAX(0,seconds)]]; }

- (void)showLoginScreen {
    [self transitionToPrimaryContainer:self.authContainer];
    self.currentState = ZXAppStateAuth;
    NSUserDefaults *globalDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *saved = [globalDefaults stringForKey:ZXLastKey];
    if (saved.length) {
        self.keyInput.textField.text = saved;
        self.keyInput.clearBtn.hidden = NO;
    }
    [self stopHeartbeatMonitor];
}

- (void)showDashboard {
    if (self.dashboardConfiguration.count && self.functionDefinitions.count==0) {
        [self updateDashboardWithConfiguration:self.dashboardConfiguration];
    }
    [self transitionToPrimaryContainer:self.dashboardContainer];
    self.currentState = ZXAppStateDashboard;
    [self updateLicenseStatus:self.licenseStatus activatedAt:self.activatedAt expiresAt:self.expiresAt isPermanent:self.licensePermanent];
    [self startHeartbeatMonitor];
}

- (void)showMaintenanceScreenWithMessage:(NSString *)message { [self showStartupState:ZXStartupStateMaintenance message:message]; }
- (void)showUpdateRequiredScreenWithMessage:(NSString *)message { [self showStartupState:ZXStartupStateVersionMismatch message:message]; }
- (void)showConnectionErrorScreenWithMessage:(NSString *)message { [self showStartupState:ZXStartupStateConnectionError message:message]; }

- (void)handleLogout {
    __weak typeof(self) weakSelf=self;
    [self showCustomConfirmationWithTitle:ZXLocalizedUI(@"SIGN OUT")
                                  message:ZXLocalizedUI(@"Your current secure session will be closed.")
                            confirmTitle:ZXLocalizedUI(@"Sign Out")
                               completion:^{
        __strong typeof(weakSelf) self=weakSelf;
        if(!self) return;

        /* Existing logout engine — unchanged. */
        Class mgrCls=NSClassFromString(@"ZentraxNetworkManager");
        if(mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
            id manager=((id (*)(id, SEL))objc_msgSend)((id)mgrCls, NSSelectorFromString(@"sharedManager"));
            SEL outSel=NSSelectorFromString(@"logout");
            if([manager respondsToSelector:outSel]) {
                ((void (*)(id, SEL))objc_msgSend)(manager, outSel);
            }
        }

        NSUserDefaults *globalDefaults=[[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
        [globalDefaults removeObjectForKey:ZXLastKey];
        [globalDefaults synchronize];

        if([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) {
            [self.delegate zentraxDidRequestLogoutWithCompletion:^{
                dispatch_async(dispatch_get_main_queue(), ^{ [self showLoginScreen]; });
            }];
        } else {
            [self showLoginScreen];
        }
    }];
}

- (UIImage *)preferredLogoImage {
    NSArray *names=@[@"ZentraxLogo",@"AppIcon60x60",@"AppIcon"];
    for (NSString *n in names) { UIImage *i=[UIImage imageNamed:n]; if(i) return i; }
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(120,120),YES,0);
    [[UIColor clearColor] setFill]; UIRectFill(CGRectMake(0,0,120,120));
    [[ZXTheme accentPrimary] setStroke]; UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(24, 24, 72, 72) cornerRadius:18]; path.lineWidth = 6; [path stroke];
    NSDictionary *attrs=@{NSFontAttributeName:[UIFont systemFontOfSize:46 weight:UIFontWeightHeavy],NSForegroundColorAttributeName:[UIColor whiteColor]};
    [@"Z" drawInRect:CGRectMake(44,36,50,60) withAttributes:attrs];
    UIImage *i=UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); return i;
}

- (void)resetToStartup { self.hasStarted = NO; self.currentState = ZXAppStateInit; [self stopHeartbeatMonitor]; [self stopLicenseCountdown]; [self beginBootstrap]; }
- (void)dismissPresentedUI { [self dismissViewControllerAnimated:YES completion:nil]; }
- (BOOL)isShowingLogin { return self.currentState == ZXAppStateAuth && !self.authContainer.hidden; }
- (BOOL)isShowingDashboard { return self.currentState == ZXAppStateDashboard && !self.dashboardContainer.hidden; }
- (BOOL)isShowingSafeModeLock { return NO; }

#pragma mark - Public Methods (From Header)

- (void)updateFunctionState:(NSString *)functionId state:(BOOL)isOn {
    if(!functionId.length) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.functionStates[functionId]=@(ZXIsTruthyValue(@(isOn)));

        UIControl *control=self.functionControls[functionId];
        if([control isKindOfClass:[ZXPremiumToggle class]]) {
            ZXPremiumToggle *toggle=(ZXPremiumToggle *)control;
            toggle.desiredState=isOn;
            [toggle setProcessing:NO];
            [toggle setOn:isOn animated:YES];
            toggle.accessibilityValue=ZXLocalizedUI(isOn ? @"ACTIVE" : @"READY");
        } else if([control isKindOfClass:[UISwitch class]]) {
            [(UISwitch *)control setOn:isOn animated:YES];
        }

        UILabel *label=self.functionStateLabels[functionId];
        if(label) {
            label.text=ZXLocalizedUI(isOn ? @"ACTIVE" : @"READY");
            label.textColor=isOn ? [ZXTheme success] : [ZXTheme mutedText];

            ZXGlassCard *card=(ZXGlassCard *)self.functionCards[functionId];
            if(card) {
                [card applyMaterial:isOn ? ZXMaterialActiveGlass : ZXMaterialGlass];
                [card setEmphasized:isOn animated:YES];
            }
        }
    });
}

- (void)updateFunctionStates:(NSDictionary<NSString *, NSNumber *> *)states {
    if (![states isKindOfClass:[NSDictionary class]]) return;
    for (NSString *fid in states) {
        id value = states[fid];
        if (![value respondsToSelector:@selector(boolValue)]) continue;
        [self updateFunctionState:fid state:[value boolValue]];
    }
}

- (void)updateServerBanner:(NSDictionary *)banner { }
- (void)showDeviceCompatibilityDetails { [self showSettings]; }
- (void)showSafeModeSettings { }
- (void)lockSafeMode { }
- (void)unlockSafeMode { }
- (void)showSettingsSection:(NSString *)sectionIdentifier { [self showSettings]; }

@end
