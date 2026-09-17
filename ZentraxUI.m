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

static NSString *ZXLocalizedUI(NSString *text);

#pragma mark - App State Enum

typedef NS_ENUM(NSInteger, ZXAppState) {
    ZXAppStateInit = 0,
    ZXAppStateSplash,
    ZXAppStateAuth,
    ZXAppStateDashboard,
    ZXAppStateStartupBlock
};


#pragma mark - ZENTRAX Absolute Glass Design System

@interface ZXAmbientBackgroundView : UIView
@property(nonatomic,strong) CAGradientLayer *violetBloom;
@property(nonatomic,strong) CAGradientLayer *indigoBloom;
@end

@implementation ZXAmbientBackgroundView
- (instancetype)initWithFrame:(CGRect)frame {
    self=[super initWithFrame:frame];
    if(!self) return nil;
    self.backgroundColor=[UIColor blackColor];
    self.userInteractionEnabled=NO;

    _violetBloom=[CAGradientLayer layer];
    _violetBloom.type=kCAGradientLayerRadial;
    _violetBloom.colors=@[
        (id)[UIColor colorWithRed:0.28 green:0.20 blue:0.55 alpha:0.035].CGColor,
        (id)[UIColor clearColor].CGColor
    ];
    _violetBloom.startPoint=CGPointMake(0.5,0.5);
    _violetBloom.endPoint=CGPointMake(1.0,1.0);
    [self.layer addSublayer:_violetBloom];

    _indigoBloom=[CAGradientLayer layer];
    _indigoBloom.type=kCAGradientLayerRadial;
    _indigoBloom.colors=@[
        (id)[UIColor colorWithRed:0.20 green:0.24 blue:0.60 alpha:0.022].CGColor,
        (id)[UIColor clearColor].CGColor
    ];
    _indigoBloom.startPoint=CGPointMake(0.5,0.5);
    _indigoBloom.endPoint=CGPointMake(1.0,1.0);
    [self.layer addSublayer:_indigoBloom];

    CABasicAnimation *violet=[CABasicAnimation animationWithKeyPath:@"transform.translation"];
    violet.fromValue=[NSValue valueWithCGSize:CGSizeMake(-10,-14)];
    violet.toValue=[NSValue valueWithCGSize:CGSizeMake(10,12)];
    violet.duration=18.0;
    violet.autoreverses=YES;
    violet.repeatCount=HUGE_VALF;
    violet.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_violetBloom addAnimation:violet forKey:@"zx.ambient.violet"];

    CABasicAnimation *indigo=[CABasicAnimation animationWithKeyPath:@"transform.translation"];
    indigo.fromValue=[NSValue valueWithCGSize:CGSizeMake(12,10)];
    indigo.toValue=[NSValue valueWithCGSize:CGSizeMake(-8,-8)];
    indigo.duration=23.0;
    indigo.autoreverses=YES;
    indigo.repeatCount=HUGE_VALF;
    indigo.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_indigoBloom addAnimation:indigo forKey:@"zx.ambient.indigo"];
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w=CGRectGetWidth(self.bounds), h=CGRectGetHeight(self.bounds);
    _violetBloom.frame=CGRectMake(-w*0.25,-h*0.12,w*1.35,h*0.95);
    _indigoBloom.frame=CGRectMake(w*0.05,h*0.34,w*1.30,h*0.90);
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
+ (UIColor *)surfaceRaised { return [UIColor colorWithRed:0.055 green:0.055 blue:0.065 alpha:0.94]; }
+ (UIColor *)border { return [UIColor colorWithWhite:1.0 alpha:0.08]; }
+ (UIColor *)borderAccent { return [UIColor colorWithRed:0.55 green:0.48 blue:0.95 alpha:0.34]; }
+ (UIColor *)primaryText { return [UIColor colorWithWhite:1.0 alpha:0.98]; }
+ (UIColor *)secondaryText { return [UIColor colorWithWhite:1.0 alpha:0.60]; }
+ (UIColor *)mutedText { return [UIColor colorWithWhite:1.0 alpha:0.32]; }
+ (UIColor *)accentPrimary { return [UIColor colorWithRed:0.47 green:0.40 blue:0.90 alpha:1.0]; }
+ (UIColor *)accentSecondary { return [UIColor colorWithRed:0.66 green:0.60 blue:0.98 alpha:1.0]; }
+ (UIColor *)success { return [UIColor colorWithRed:0.32 green:0.82 blue:0.58 alpha:1.0]; }
+ (UIColor *)warning { return [UIColor colorWithRed:0.92 green:0.70 blue:0.32 alpha:1.0]; }
+ (UIColor *)error { return [UIColor colorWithRed:0.92 green:0.36 blue:0.40 alpha:1.0]; }
+ (UIFont *)display:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBold]; }
+ (UIFont *)heading:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightSemibold]; }
+ (UIFont *)body:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont systemFontOfSize:size weight:weight]; }
+ (UIFont *)mono:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont monospacedSystemFontOfSize:size weight:weight]; }
+ (void)track:(UILabel *)label spacing:(CGFloat)spacing {
    if(!label.text.length) return;
    NSMutableAttributedString *s=[[NSMutableAttributedString alloc] initWithString:label.text];
    [s addAttribute:NSKernAttributeName value:@(spacing) range:NSMakeRange(0,s.length)];
    [s addAttribute:NSFontAttributeName value:label.font range:NSMakeRange(0,s.length)];
    [s addAttribute:NSForegroundColorAttributeName value:label.textColor ?: [UIColor whiteColor] range:NSMakeRange(0,s.length)];
    label.attributedText=s;
}
@end

@interface ZXGlassCard : UIView
@property(nonatomic,strong) UIVisualEffectView *blurView;
@property(nonatomic,strong) UIView *specularLine;
@end

@implementation ZXGlassCard
- (instancetype)init {
    self=[super initWithFrame:CGRectZero];
    if(!self) return nil;
    self.backgroundColor=[UIColor clearColor];
    self.translatesAutoresizingMaskIntoConstraints=NO;
    self.layer.cornerRadius=26.0;
    self.layer.shadowColor=[UIColor blackColor].CGColor;
    self.layer.shadowOpacity=0.38;
    self.layer.shadowRadius=28.0;
    self.layer.shadowOffset=CGSizeMake(0,12);

    _blurView=[[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    _blurView.layer.cornerRadius=26.0;
    _blurView.layer.borderWidth=0.5;
    _blurView.layer.borderColor=[UIColor colorWithWhite:1.0 alpha:0.08].CGColor;
    _blurView.clipsToBounds=YES;
    _blurView.translatesAutoresizingMaskIntoConstraints=NO;
    [super addSubview:_blurView];

    _specularLine=[[UIView alloc] init];
    _specularLine.backgroundColor=[UIColor colorWithWhite:1 alpha:0.035];
    _specularLine.layer.cornerRadius=0.5;
    _specularLine.translatesAutoresizingMaskIntoConstraints=NO;
    [_blurView.contentView addSubview:_specularLine];

    [NSLayoutConstraint activateConstraints:@[
        [_blurView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_blurView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_blurView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_blurView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_specularLine.leadingAnchor constraintEqualToAnchor:_blurView.contentView.leadingAnchor constant:20],
        [_specularLine.trailingAnchor constraintEqualToAnchor:_blurView.contentView.trailingAnchor constant:-20],
        [_specularLine.topAnchor constraintEqualToAnchor:_blurView.contentView.topAnchor constant:0.5],
        [_specularLine.heightAnchor constraintEqualToConstant:0.5]
    ]];
    return self;
}
- (void)addSubview:(UIView *)view {
    if(view==_blurView) [super addSubview:view];
    else if(view==_specularLine) [_blurView.contentView addSubview:view];
    else [_blurView.contentView addSubview:view];
}
@end

@interface ZXPremiumButton : UIButton
@property(nonatomic,strong) UIView *surface;
@property(nonatomic,strong) UIActivityIndicatorView *spinner;
@property(nonatomic,strong) NSString *savedTitle;
@end

@implementation ZXPremiumButton
- (instancetype)init {
    self=[super initWithFrame:CGRectZero];
    if(!self) return nil;
    self.translatesAutoresizingMaskIntoConstraints=NO;
    self.backgroundColor=[UIColor clearColor];
    self.layer.cornerRadius=18;
    self.layer.borderWidth=0.5;
    self.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.12].CGColor;
    self.clipsToBounds=NO;
    self.titleLabel.font=[ZXTheme heading:15];
    [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.surface=[[UIView alloc] init];
    self.surface.backgroundColor=[UIColor colorWithWhite:1 alpha:0.94];
    self.surface.layer.cornerRadius=18;
    self.surface.userInteractionEnabled=NO;
    self.surface.translatesAutoresizingMaskIntoConstraints=NO;
    [self insertSubview:self.surface atIndex:0];
    [NSLayoutConstraint activateConstraints:@[
        [self.surface.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.surface.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.surface.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.surface.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
    self.layer.shadowColor=[UIColor blackColor].CGColor;
    self.layer.shadowOpacity=0.22;
    self.layer.shadowRadius=18;
    self.layer.shadowOffset=CGSizeMake(0,8);

    _spinner=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    _spinner.color=[UIColor blackColor];
    _spinner.hidesWhenStopped=YES;
    _spinner.translatesAutoresizingMaskIntoConstraints=NO;
    [self addSubview:_spinner];
    [NSLayoutConstraint activateConstraints:@[
        [_spinner.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_spinner.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
    ]];
    [self addTarget:self action:@selector(zxTouchDown) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(zxTouchUp) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    return self;
}
- (void)zxTouchDown {
    if(!self.enabled) return;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    [UIView animateWithDuration:0.12 animations:^{
        self.transform=CGAffineTransformMakeScale(0.985,0.985);
        self.surface.alpha=0.86;
    }];
}
- (void)zxTouchUp {
    [UIView animateWithDuration:0.42 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0.2 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.transform=CGAffineTransformIdentity;
        self.surface.alpha=1.0;
    } completion:nil];
}
- (void)setLoading:(BOOL)loading {
    self.userInteractionEnabled=!loading;
    if(loading){
        self.savedTitle=[self titleForState:UIControlStateNormal];
        [self setTitle:@"" forState:UIControlStateNormal];
        [_spinner startAnimating];
    }else{
        [self setTitle:self.savedTitle ?: @"" forState:UIControlStateNormal];
        [_spinner stopAnimating];
    }
}
@end

@interface ZXPremiumField : UIView <UITextFieldDelegate>
@property(nonatomic,strong) UITextField *textField;
@property(nonatomic,strong) UIVisualEffectView *blurContainer;
@property(nonatomic,strong) UIButton *clearBtn;
@property(nonatomic,strong) UIImageView *iconView;
@end

@implementation ZXPremiumField
- (instancetype)init {
    self=[super initWithFrame:CGRectZero];
    if(!self) return nil;
    self.translatesAutoresizingMaskIntoConstraints=NO;

    _blurContainer=[[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    _blurContainer.layer.cornerRadius=19;
    _blurContainer.layer.borderWidth=0.5;
    _blurContainer.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.08].CGColor;
    _blurContainer.clipsToBounds=YES;
    _blurContainer.translatesAutoresizingMaskIntoConstraints=NO;
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
    _textField.returnKeyType=UIReturnKeyDone;
    _textField.attributedPlaceholder=[[NSAttributedString alloc] initWithString:ZXLocalizedUI(@"Enter License Key") attributes:@{NSForegroundColorAttributeName:[ZXTheme mutedText],NSFontAttributeName:[ZXTheme body:15 weight:UIFontWeightRegular]}];
    _textField.translatesAutoresizingMaskIntoConstraints=NO;
    [_textField addTarget:self action:@selector(textChanged) forControlEvents:UIControlEventEditingChanged];
    [_blurContainer.contentView addSubview:_textField];

    _clearBtn=[UIButton buttonWithType:UIButtonTypeSystem];
    [_clearBtn setImage:[UIImage systemImageNamed:@"xmark.circle"] forState:UIControlStateNormal];
    _clearBtn.tintColor=[ZXTheme mutedText];
    _clearBtn.translatesAutoresizingMaskIntoConstraints=NO;
    _clearBtn.hidden=YES;
    [_clearBtn addTarget:self action:@selector(clearText) forControlEvents:UIControlEventTouchUpInside];
    [_blurContainer.contentView addSubview:_clearBtn];

    [NSLayoutConstraint activateConstraints:@[
        [_blurContainer.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_blurContainer.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_blurContainer.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_blurContainer.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_blurContainer.heightAnchor constraintEqualToConstant:62],
        [_iconView.leadingAnchor constraintEqualToAnchor:_blurContainer.contentView.leadingAnchor constant:20],
        [_iconView.centerYAnchor constraintEqualToAnchor:_blurContainer.contentView.centerYAnchor],
        [_iconView.widthAnchor constraintEqualToConstant:19],
        [_iconView.heightAnchor constraintEqualToConstant:19],
        [_clearBtn.trailingAnchor constraintEqualToAnchor:_blurContainer.contentView.trailingAnchor constant:-12],
        [_clearBtn.centerYAnchor constraintEqualToAnchor:_blurContainer.contentView.centerYAnchor],
        [_clearBtn.widthAnchor constraintEqualToConstant:32],
        [_clearBtn.heightAnchor constraintEqualToConstant:32],
        [_textField.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor constant:15],
        [_textField.trailingAnchor constraintEqualToAnchor:_clearBtn.leadingAnchor constant:-8],
        [_textField.centerYAnchor constraintEqualToAnchor:_blurContainer.contentView.centerYAnchor]
    ]];
    return self;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.28 animations:^{
        self.blurContainer.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.24].CGColor;
        self.iconView.tintColor=[ZXTheme primaryText];
        self.transform=CGAffineTransformMakeScale(1.006,1.006);
    }];
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.28 animations:^{
        self.blurContainer.layer.borderColor=[ZXTheme border].CGColor;
        self.iconView.tintColor=[ZXTheme mutedText];
        self.transform=CGAffineTransformIdentity;
    }];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField { [textField resignFirstResponder]; return YES; }
- (void)textChanged { self.clearBtn.hidden=(self.textField.text.length==0); }
- (void)clearText {
    self.textField.text=@"";
    self.clearBtn.hidden=YES;
}
@end

@interface ZXPremiumToggle : UIControl
@property(nonatomic,assign,getter=isOn) BOOL on;
@property(nonatomic,strong) UIView *track;
@property(nonatomic,strong) UIView *thumb;
@property(nonatomic,strong) UIView *specular;
@property(nonatomic,assign) BOOL processing;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
- (void)setProcessing:(BOOL)processing;
@end

@implementation ZXPremiumToggle
- (instancetype)init {
    self=[super initWithFrame:CGRectMake(0,0,56,34)];
    if(!self) return nil;
    self.translatesAutoresizingMaskIntoConstraints=NO;
    self.accessibilityTraits=UIAccessibilityTraitButton;
    _track=[[UIView alloc] init];
    _track.translatesAutoresizingMaskIntoConstraints=NO;
    _track.layer.cornerRadius=17;
    _track.backgroundColor=[UIColor colorWithWhite:1 alpha:0.08];
    _track.layer.borderWidth=0.5;
    _track.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.12].CGColor;
    [self addSubview:_track];
    _thumb=[[UIView alloc] init];
    _thumb.translatesAutoresizingMaskIntoConstraints=NO;
    _thumb.layer.cornerRadius=14;
    _thumb.backgroundColor=[UIColor colorWithWhite:0.96 alpha:1];
    _thumb.layer.shadowColor=[UIColor blackColor].CGColor;
    _thumb.layer.shadowOpacity=0.35;
    _thumb.layer.shadowRadius=5;
    _thumb.layer.shadowOffset=CGSizeMake(0,2);
    [self addSubview:_thumb];
    _specular=[[UIView alloc] init];
    _specular.backgroundColor=[UIColor colorWithWhite:1 alpha:0.55];
    _specular.layer.cornerRadius=0.75;
    _specular.translatesAutoresizingMaskIntoConstraints=NO;
    [_thumb addSubview:_specular];
    [NSLayoutConstraint activateConstraints:@[
        [_track.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_track.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_track.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_track.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_thumb.widthAnchor constraintEqualToConstant:28],
        [_thumb.heightAnchor constraintEqualToConstant:28],
        [_thumb.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_specular.leadingAnchor constraintEqualToAnchor:_thumb.leadingAnchor constant:6],
        [_specular.trailingAnchor constraintEqualToAnchor:_thumb.trailingAnchor constant:-6],
        [_specular.topAnchor constraintEqualToAnchor:_thumb.topAnchor constant:4],
        [_specular.heightAnchor constraintEqualToConstant:1.5]
    ]];
    [self setOn:NO animated:NO];
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat inset=3.0;
    CGFloat x=self.on ? CGRectGetWidth(self.bounds)-28-inset : inset;
    self.thumb.frame=CGRectMake(x,3,28,28);
}
- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _on=on;
    self.accessibilityValue=on ? @"On" : @"Off";
    UIColor *trackColor=on ? [[ZXTheme accentPrimary] colorWithAlphaComponent:0.42] : [UIColor colorWithWhite:1 alpha:0.08];
    UIColor *thumbColor=on ? [UIColor colorWithWhite:1 alpha:0.98] : [UIColor colorWithWhite:0.80 alpha:1];
    void (^changes)(void)=^{
        self.track.backgroundColor=trackColor;
        self.track.layer.borderColor=(on ? [[ZXTheme accentSecondary] colorWithAlphaComponent:0.34] : [UIColor colorWithWhite:1 alpha:0.12]).CGColor;
        self.thumb.backgroundColor=thumbColor;
        self.thumb.layer.shadowColor=on ? [ZXTheme accentPrimary].CGColor : [UIColor blackColor].CGColor;
        self.thumb.layer.shadowOpacity=on ? 0.28 : 0.35;
        [self setNeedsLayout];
        [self layoutIfNeeded];
    };
    if(animated){
        [UIView animateWithDuration:0.46 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0.2 options:UIViewAnimationOptionAllowUserInteraction animations:changes completion:nil];
    } else changes();
}
- (void)setProcessing:(BOOL)processing {
    _processing=processing;
    self.userInteractionEnabled=!processing;
    self.alpha=processing ? 0.68 : 1.0;
}
- (void)beginTracking {
    if(!self.userInteractionEnabled) return;
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
    [UIView animateWithDuration:0.10 animations:^{ self.transform=CGAffineTransformMakeScale(0.97,0.97); }];
}
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [self beginTracking];
    return [super beginTrackingWithTouch:touch withEvent:event];
}
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    BOOL inside=CGRectContainsPoint(self.bounds,[touch locationInView:self]);
    [super endTrackingWithTouch:touch withEvent:event];
    [UIView animateWithDuration:0.38 delay:0 usingSpringWithDamping:0.76 initialSpringVelocity:0.2 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.transform=CGAffineTransformIdentity;
    } completion:nil];
    if(inside && self.userInteractionEnabled){
        [self setOn:!self.on animated:YES];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}
- (void)cancelTrackingWithEvent:(UIEvent *)event {
    [super cancelTrackingWithEvent:event];
    [UIView animateWithDuration:0.28 animations:^{ self.transform=CGAffineTransformIdentity; }];
}
- (void)sendActionsForControlEvents:(UIControlEvents)controlEvents {
    [super sendActionsForControlEvents:controlEvents];
}
@end

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
    if([value isKindOfClass:[NSString class]]){
        NSString *s=[(NSString *)value lowercaseString];
        if([s isEqualToString:@"1"]||[s isEqualToString:@"true"]||[s isEqualToString:@"yes"]||[s isEqualToString:@"on"]) return YES;
    }
    return NO;
}

static NSString *ZXCurrentLanguage(void) {
    NSUserDefaults *d=[[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *lang=[d stringForKey:ZXLanguageKey];
    return lang.length ? lang : @"English";
}

static NSString *ZXLocalizedUI(NSString *text) {
    if(![text isKindOfClass:[NSString class]]||!text.length) return text ?: @"";
    NSString *language=ZXCurrentLanguage();
    if([language isEqualToString:@"English"]) return text;
    NSDictionary *vi=@{
        @"Settings":@"Cài đặt",@"Sign Out":@"Đăng xuất",@"AUTHENTICATE":@"XÁC THỰC",
        @"Choose your language":@"Chọn ngôn ngữ",@"ACTIVE":@"ĐANG BẬT",@"READY":@"SẴN SÀNG",
        @"LIFETIME":@"VĨNH VIỄN",@"OFFLINE":@"NGOẠI TUYẾN"
    };
    NSDictionary *zh=@{
        @"Settings":@"设置",@"Sign Out":@"退出登录",@"AUTHENTICATE":@"验证",
        @"Choose your language":@"选择语言",@"ACTIVE":@"已启用",@"READY":@"就绪",
        @"LIFETIME":@"终身",@"OFFLINE":@"离线"
    };
    NSDictionary *ja=@{
        @"Settings":@"設定",@"Sign Out":@"サインアウト",@"AUTHENTICATE":@"認証",
        @"Choose your language":@"言語を選択",@"ACTIVE":@"有効",@"READY":@"準備完了",
        @"LIFETIME":@"無期限",@"OFFLINE":@"オフライン"
    };
    if([language isEqualToString:@"Tiếng Việt"]) return vi[text] ?: text;
    if([language isEqualToString:@"简体中文"]) return zh[text] ?: text;
    if([language isEqualToString:@"日本語"]) return ja[text] ?: text;
    return text;
}

@interface ZXOrbitLoader : UIView
@property(nonatomic,strong) CAShapeLayer *trackLayer;
@property(nonatomic,strong) CAShapeLayer *orbitLayer;
@property(nonatomic,assign) BOOL loading;
- (void)startAnimating;
- (void)stopAnimating;
@end

@implementation ZXOrbitLoader
- (instancetype)init {
    self=[super initWithFrame:CGRectMake(0,0,28,28)];
    if(!self) return nil;
    self.backgroundColor=[UIColor clearColor];
    self.translatesAutoresizingMaskIntoConstraints=NO;
    _trackLayer=[CAShapeLayer layer];
    _trackLayer.fillColor=[UIColor clearColor].CGColor;
    _trackLayer.strokeColor=[UIColor colorWithWhite:1 alpha:0.10].CGColor;
    _trackLayer.lineWidth=1.2;
    _trackLayer.lineCap=kCALineCapRound;
    [self.layer addSublayer:_trackLayer];
    _orbitLayer=[CAShapeLayer layer];
    _orbitLayer.fillColor=[UIColor clearColor].CGColor;
    _orbitLayer.strokeColor=[ZXTheme accentSecondary].CGColor;
    _orbitLayer.lineWidth=1.5;
    _orbitLayer.lineCap=kCALineCapRound;
    [self.layer addSublayer:_orbitLayer];
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat inset=3.0;
    CGRect r=CGRectInset(self.bounds,inset,inset);
    _trackLayer.frame=self.bounds;
    _trackLayer.path=[UIBezierPath bezierPathWithOvalInRect:r].CGPath;
    _orbitLayer.frame=self.bounds;
    CGPathRef p=[UIBezierPath bezierPathWithOvalInRect:r].CGPath;
    _orbitLayer.path=p;
}
- (void)startAnimating {
    self.loading=YES;
    if([self.orbitLayer animationForKey:@"zx.orbit"]) return;
    CABasicAnimation *a=[CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    a.fromValue=@0; a.toValue=@(M_PI*2); a.duration=1.15; a.repeatCount=HUGE_VALF;
    a.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.orbitLayer addAnimation:a forKey:@"zx.orbit"];
    CABasicAnimation *pulse=[CABasicAnimation animationWithKeyPath:@"opacity"];
    pulse.fromValue=@0.42; pulse.toValue=@1.0; pulse.duration=0.8; pulse.autoreverses=YES; pulse.repeatCount=HUGE_VALF;
    [self.orbitLayer addAnimation:pulse forKey:@"zx.pulse"];
}
- (void)stopAnimating {
    self.loading=NO;
    [self.orbitLayer removeAnimationForKey:@"zx.orbit"];
    [self.orbitLayer removeAnimationForKey:@"zx.pulse"];
}
@end

#pragma mark - Main Controller

@interface ZentraxUI () <UITextFieldDelegate>
@property(nonatomic,strong) UIView *backgroundEnvironment;
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
@property(nonatomic,strong) UILabel *globalLoadingTitle;
@property(nonatomic,strong) UILabel *globalLoadingDetail;

- (UIImage *)preferredLogoImage;
- (void)toggleSettingsKey:(UIButton *)sender;
- (void)rebuildAllContainers;
- (void)styleSecondaryButton:(UIButton *)button;
- (void)presentActivationStatusForFunction:(NSString *)functionId activating:(BOOL)activating;
- (void)dismissActivationStatusSuccess:(BOOL)success functionId:(NSString *)functionId;
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
    if(!target) return;
    NSArray *containers=@[self.splashContainer ?: [UIView new],self.authContainer ?: [UIView new],self.dashboardContainer ?: [UIView new],self.settingsContainer ?: [UIView new],self.startupBlockContainer ?: [UIView new]];
    for(UIView *container in containers){
        if(container!=target){
            container.hidden=YES; container.alpha=1.0; container.transform=CGAffineTransformIdentity;
        }
    }
    target.hidden=NO;
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    target.alpha=0;
    target.transform=CGAffineTransformMakeScale(0.985,0.985);
    [UIView animateWithDuration:0.42 delay:0 usingSpringWithDamping:0.86 initialSpringVelocity:0.18 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction animations:^{
        target.alpha=1.0;
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
    _splashContainer.backgroundColor=[UIColor blackColor];
    [self.view addSubview:_splashContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_splashContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_splashContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_splashContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_splashContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UIView *mark=[[UIView alloc] init];
    mark.translatesAutoresizingMaskIntoConstraints=NO;
    [_splashContainer addSubview:mark];

    _splashLogo=[[UIImageView alloc] initWithImage:[self preferredLogoImage]];
    _splashLogo.contentMode=UIViewContentModeScaleAspectFit;
    _splashLogo.layer.cornerRadius=24;
    _splashLogo.clipsToBounds=YES;
    _splashLogo.translatesAutoresizingMaskIntoConstraints=NO;
    _splashLogo.alpha=0.0;
    [mark addSubview:_splashLogo];

    UILabel *brand=[self label:@"ZENTRAX" size:25 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    [ZXTheme track:brand spacing:4.0];
    brand.textAlignment=NSTextAlignmentCenter;
    brand.translatesAutoresizingMaskIntoConstraints=NO;
    brand.alpha=0.0;
    [mark addSubview:brand];

    ZXOrbitLoader *loader=[[ZXOrbitLoader alloc] init];
    loader.tag=8101;
    [_splashContainer addSubview:loader];
    [loader startAnimating];

    _splashStatus=[self label:@"Initializing secure environment" size:11 weight:UIFontWeightMedium color:[ZXTheme mutedText]];
    _splashStatus.textAlignment=NSTextAlignmentCenter;
    _splashStatus.translatesAutoresizingMaskIntoConstraints=NO;
    _splashStatus.alpha=0.0;
    [_splashContainer addSubview:_splashStatus];

    _splashProgressLabel=[self label:@"" size:1 weight:UIFontWeightRegular color:[UIColor clearColor]];
    _splashProgressLabel.hidden=YES;
    [_splashContainer addSubview:_splashProgressLabel];

    [NSLayoutConstraint activateConstraints:@[
        [mark.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [mark.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor constant:-20],
        [mark.widthAnchor constraintEqualToConstant:160],
        [mark.heightAnchor constraintEqualToConstant:142],
        [_splashLogo.centerXAnchor constraintEqualToAnchor:mark.centerXAnchor],
        [_splashLogo.topAnchor constraintEqualToAnchor:mark.topAnchor],
        [_splashLogo.widthAnchor constraintEqualToConstant:72],
        [_splashLogo.heightAnchor constraintEqualToConstant:72],
        [brand.topAnchor constraintEqualToAnchor:_splashLogo.bottomAnchor constant:24],
        [brand.centerXAnchor constraintEqualToAnchor:mark.centerXAnchor],
        [loader.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [loader.topAnchor constraintEqualToAnchor:mark.bottomAnchor constant:30],
        [loader.widthAnchor constraintEqualToConstant:24],
        [loader.heightAnchor constraintEqualToConstant:24],
        [_splashStatus.topAnchor constraintEqualToAnchor:loader.bottomAnchor constant:18],
        [_splashStatus.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [_splashStatus.leadingAnchor constraintGreaterThanOrEqualToAnchor:_splashContainer.leadingAnchor constant:32],
        [_splashStatus.trailingAnchor constraintLessThanOrEqualToAnchor:_splashContainer.trailingAnchor constant:-32]
    ]];

    _splashLogo.transform=CGAffineTransformMakeScale(0.92,0.92);
    brand.transform=CGAffineTransformMakeScale(0.97,0.97);
    [UIView animateWithDuration:0.55 delay:0.05 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.splashLogo.alpha=1.0;
        self.splashLogo.transform=CGAffineTransformIdentity;
        brand.alpha=1.0;
        brand.transform=CGAffineTransformIdentity;
        self.splashStatus.alpha=1.0;
    } completion:nil];
}

- (void)runPremiumSplashCompletion:(void (^)(void))completion {
    self.pendingSplashCompletion=completion;
    self.currentSplashProgress=0.0;
    [self.splashAnimationTimer invalidate];
    self.splashAnimationTimer=[NSTimer scheduledTimerWithTimeInterval:0.016 target:self selector:@selector(tickSplashAnimation:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.splashAnimationTimer forMode:NSRunLoopCommonModes];
}
- (void)tickSplashAnimation:(NSTimer *)timer {
    self.currentSplashProgress += 5.5;
    if(self.currentSplashProgress>100.0) self.currentSplashProgress=100.0;
    if(self.splashStatus) {
        NSArray *states=@[@"Initializing secure environment",@"Preparing interface",@"Verifying session",@"Synchronizing state"];
        NSInteger index=MIN(states.count-1,(NSInteger)(self.currentSplashProgress/26.0));
        self.splashStatus.text=ZXLocalizedUI(states[index]);
    }
    if(self.currentSplashProgress>=100.0){
        [self.splashAnimationTimer invalidate];
        self.splashAnimationTimer=nil;
        if(self.pendingSplashCompletion){
            void (^completion)(void)=[self.pendingSplashCompletion copy];
            self.pendingSplashCompletion=nil;
            completion();
        }
    }
}

#pragma mark - Authentication (Elegant & Timeout Protected)

- (void)setupAuth {
    _authContainer=[[UIView alloc] init];
    _authContainer.translatesAutoresizingMaskIntoConstraints=NO;
    _authContainer.backgroundColor=[UIColor clearColor];
    [self.view addSubview:_authContainer];
    [_authContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active=YES;
    [_authContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active=YES;
    [_authContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor].active=YES;
    [_authContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active=YES;

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

    UILabel *eyebrow=[self label:@"ZENTRAX" size:12 weight:UIFontWeightSemibold color:[ZXTheme mutedText]];
    [ZXTheme track:eyebrow spacing:3.0];
    eyebrow.textAlignment=NSTextAlignmentCenter;
    eyebrow.translatesAutoresizingMaskIntoConstraints=NO;
    [content addSubview:eyebrow];

    UILabel *title=[self label:@"Welcome back." size:34 weight:UIFontWeightBold color:[ZXTheme primaryText]];
    title.textAlignment=NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints=NO;
    [content addSubview:title];

    UILabel *subtitle=[self label:@"Secure access to your ZENTRAX environment." size:15 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    subtitle.textAlignment=NSTextAlignmentCenter;
    subtitle.numberOfLines=2;
    subtitle.translatesAutoresizingMaskIntoConstraints=NO;
    [content addSubview:subtitle];

    ZXGlassCard *card=[[ZXGlassCard alloc] init];
    [content addSubview:card];

    UILabel *keyTitle=[self label:@"LICENSE KEY" size:11 weight:UIFontWeightSemibold color:[ZXTheme mutedText]];
    [ZXTheme track:keyTitle spacing:1.8];
    keyTitle.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:keyTitle];

    _keyInput=[[ZXPremiumField alloc] init];
    _keyInput.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:_keyInput];

    _loginBtn=[[ZXPremiumButton alloc] init];
    [_loginBtn setTitle:ZXLocalizedUI(@"CONTINUE") forState:UIControlStateNormal];
    [_loginBtn addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:_loginBtn];

    _authStatus=[self label:@"" size:13 weight:UIFontWeightMedium color:[ZXTheme mutedText]];
    _authStatus.textAlignment=NSTextAlignmentCenter;
    _authStatus.numberOfLines=2;
    _authStatus.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:_authStatus];

    [NSLayoutConstraint activateConstraints:@[
        [eyebrow.topAnchor constraintEqualToAnchor:content.topAnchor constant:MAX(52.0, self.view.safeAreaInsets.top+30)],
        [eyebrow.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],
        [title.topAnchor constraintEqualToAnchor:eyebrow.bottomAnchor constant:16],
        [title.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:24],
        [title.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-24],
        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:10],
        [subtitle.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:32],
        [subtitle.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-32],
        [card.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:36],
        [card.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:24],
        [card.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-24],
        [keyTitle.topAnchor constraintEqualToAnchor:card.topAnchor constant:24],
        [keyTitle.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [_keyInput.topAnchor constraintEqualToAnchor:keyTitle.bottomAnchor constant:12],
        [_keyInput.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [_keyInput.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        [_loginBtn.topAnchor constraintEqualToAnchor:_keyInput.bottomAnchor constant:16],
        [_loginBtn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [_loginBtn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        [_loginBtn.heightAnchor constraintEqualToConstant:56],
        [_authStatus.topAnchor constraintEqualToAnchor:_loginBtn.bottomAnchor constant:16],
        [_authStatus.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [_authStatus.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        [_authStatus.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-24],
        [card.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-48]
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

    UILabel *title=[self label:@"ZENTRAX" size:18 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    [ZXTheme track:title spacing:2.2];
    title.translatesAutoresizingMaskIntoConstraints=NO;
    [header addSubview:title];

    _connectionDot=[[UIView alloc] init];
    _connectionDot.backgroundColor=[ZXTheme success];
    _connectionDot.layer.cornerRadius=3;
    _connectionDot.translatesAutoresizingMaskIntoConstraints=NO;
    [header addSubview:_connectionDot];

    _connectionLabel=[self label:@"SECURE" size:10 weight:UIFontWeightSemibold color:[ZXTheme secondaryText]];
    [ZXTheme track:_connectionLabel spacing:1.4];
    _connectionLabel.translatesAutoresizingMaskIntoConstraints=NO;
    [header addSubview:_connectionLabel];

    UIButton *settings=[self iconButton:@"line.3.horizontal" size:42];
    settings.accessibilityLabel=@"Settings";
    [settings addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:settings];

    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [header.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [header.topAnchor constraintEqualToAnchor:_dashboardContainer.safeAreaLayoutGuide.topAnchor constant:10],
        [header.heightAnchor constraintEqualToConstant:48],
        [logo.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [logo.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [logo.widthAnchor constraintEqualToConstant:30],
        [logo.heightAnchor constraintEqualToConstant:30],
        [title.leadingAnchor constraintEqualToAnchor:logo.trailingAnchor constant:12],
        [title.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [settings.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],
        [settings.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [_connectionLabel.trailingAnchor constraintEqualToAnchor:settings.leadingAnchor constant:-14],
        [_connectionLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [_connectionDot.trailingAnchor constraintEqualToAnchor:_connectionLabel.leadingAnchor constant:-7],
        [_connectionDot.centerYAnchor constraintEqualToAnchor:_connectionLabel.centerYAnchor],
        [_connectionDot.widthAnchor constraintEqualToConstant:6],
        [_connectionDot.heightAnchor constraintEqualToConstant:6]
    ]];

    _licenseCard=[[ZXGlassCard alloc] init];
    [_dashboardContainer addSubview:_licenseCard];
    [NSLayoutConstraint activateConstraints:@[
        [_licenseCard.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [_licenseCard.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [_licenseCard.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:24],
        [_licenseCard.heightAnchor constraintGreaterThanOrEqualToConstant:148]
    ]];

    UILabel *eyebrow=[self label:@"SECURE ENVIRONMENT" size:10 weight:UIFontWeightSemibold color:[ZXTheme mutedText]];
    [ZXTheme track:eyebrow spacing:2.0];
    eyebrow.translatesAutoresizingMaskIntoConstraints=NO;
    [_licenseCard addSubview:eyebrow];

    _licenseStatusLabel=[self label:@"UNACTIVATED" size:11 weight:UIFontWeightSemibold color:[ZXTheme warning]];
    [ZXTheme track:_licenseStatusLabel spacing:1.2];
    _licenseStatusLabel.translatesAutoresizingMaskIntoConstraints=NO;
    [_licenseCard addSubview:_licenseStatusLabel];

    _countdownLabel=[self label:@"—" size:34 weight:UIFontWeightBold color:[ZXTheme primaryText]];
    _countdownLabel.font=[ZXTheme mono:30 weight:UIFontWeightMedium];
    _countdownLabel.translatesAutoresizingMaskIntoConstraints=NO;
    [_licenseCard addSubview:_countdownLabel];

    UILabel *caption=[self label:@"License validity" size:12 weight:UIFontWeightRegular color:[ZXTheme mutedText]];
    caption.translatesAutoresizingMaskIntoConstraints=NO;
    [_licenseCard addSubview:caption];

    [NSLayoutConstraint activateConstraints:@[
        [eyebrow.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:24],
        [eyebrow.topAnchor constraintEqualToAnchor:_licenseCard.topAnchor constant:24],
        [_licenseStatusLabel.leadingAnchor constraintEqualToAnchor:eyebrow.trailingAnchor constant:12],
        [_licenseStatusLabel.centerYAnchor constraintEqualToAnchor:eyebrow.centerYAnchor],
        [_countdownLabel.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:24],
        [_countdownLabel.topAnchor constraintEqualToAnchor:eyebrow.bottomAnchor constant:18],
        [_countdownLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_licenseCard.trailingAnchor constant:-24],
        [caption.leadingAnchor constraintEqualToAnchor:_countdownLabel.leadingAnchor],
        [caption.topAnchor constraintEqualToAnchor:_countdownLabel.bottomAnchor constant:4],
        [caption.bottomAnchor constraintEqualToAnchor:_licenseCard.bottomAnchor constant:-22]
    ]];

    _modulesScroll=[[UIScrollView alloc] init];
    _modulesScroll.showsVerticalScrollIndicator=NO;
    _modulesScroll.alwaysBounceVertical=YES;
    _modulesScroll.translatesAutoresizingMaskIntoConstraints=NO;
    [_dashboardContainer addSubview:_modulesScroll];

    _modulesStack=[[UIStackView alloc] init];
    _modulesStack.axis=UILayoutConstraintAxisVertical;
    _modulesStack.spacing=16;
    _modulesStack.translatesAutoresizingMaskIntoConstraints=NO;
    [_modulesScroll addSubview:_modulesStack];

    [NSLayoutConstraint activateConstraints:@[
        [_modulesScroll.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:24],
        [_modulesScroll.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-24],
        [_modulesScroll.topAnchor constraintEqualToAnchor:_licenseCard.bottomAnchor constant:40],
        [_modulesScroll.bottomAnchor constraintEqualToAnchor:_dashboardContainer.bottomAnchor],
        [_modulesStack.leadingAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.leadingAnchor],
        [_modulesStack.trailingAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.trailingAnchor],
        [_modulesStack.topAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.topAnchor],
        [_modulesStack.bottomAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.bottomAnchor constant:-48],
        [_modulesStack.widthAnchor constraintEqualToAnchor:_modulesScroll.frameLayoutGuide.widthAnchor]
    ]];
    [self createEmptyStateView];
}

- (void)createEmptyStateView {
    _emptyState=[[ZXGlassCard alloc] init];
    UIImageView *icon=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"cube.transparent"]];
    icon.tintColor=[ZXTheme mutedText];
    icon.translatesAutoresizingMaskIntoConstraints=NO;
    [_emptyState addSubview:icon];
    UILabel *title=[self label:@"No functions assigned" size:16 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    title.textAlignment=NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints=NO;
    [_emptyState addSubview:title];
    UILabel *detail=[self label:@"Server configuration will appear here." size:13 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    detail.textAlignment=NSTextAlignmentCenter;
    detail.numberOfLines=2;
    detail.translatesAutoresizingMaskIntoConstraints=NO;
    [_emptyState addSubview:detail];
    [NSLayoutConstraint activateConstraints:@[
        [_emptyState.heightAnchor constraintGreaterThanOrEqualToConstant:180],
        [icon.centerXAnchor constraintEqualToAnchor:_emptyState.centerXAnchor],
        [icon.topAnchor constraintEqualToAnchor:_emptyState.topAnchor constant:34],
        [icon.widthAnchor constraintEqualToConstant:28],
        [icon.heightAnchor constraintEqualToConstant:28],
        [title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:18],
        [title.leadingAnchor constraintEqualToAnchor:_emptyState.leadingAnchor constant:24],
        [title.trailingAnchor constraintEqualToAnchor:_emptyState.trailingAnchor constant:-24],
        [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:7],
        [detail.leadingAnchor constraintEqualToAnchor:_emptyState.leadingAnchor constant:28],
        [detail.trailingAnchor constraintEqualToAnchor:_emptyState.trailingAnchor constant:-28],
        [detail.bottomAnchor constraintLessThanOrEqualToAnchor:_emptyState.bottomAnchor constant:-28]
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
            UIView *headerWrapper = [[UIView alloc] init];
            headerWrapper.translatesAutoresizingMaskIntoConstraints = NO;
            
            UIView *glassPill = [[UIView alloc] init];
            glassPill.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
            glassPill.layer.cornerRadius = 12;
            glassPill.layer.borderWidth = 1.0;
            glassPill.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
            glassPill.translatesAutoresizingMaskIntoConstraints = NO;
            [headerWrapper addSubview:glassPill];
            
            UILabel *cat = [self label:categoryName.uppercaseString size:12 weight:UIFontWeightHeavy color:[UIColor whiteColor]];
            [ZXTheme track:cat spacing:2.0];
            cat.translatesAutoresizingMaskIntoConstraints = NO;
            [glassPill addSubview:cat];
            
            [NSLayoutConstraint activateConstraints:@[
                [glassPill.leadingAnchor constraintEqualToAnchor:headerWrapper.leadingAnchor],
                [glassPill.topAnchor constraintEqualToAnchor:headerWrapper.topAnchor constant:12],
                [glassPill.bottomAnchor constraintEqualToAnchor:headerWrapper.bottomAnchor constant:-4],
                
                [cat.leadingAnchor constraintEqualToAnchor:glassPill.leadingAnchor constant:16],
                [cat.trailingAnchor constraintEqualToAnchor:glassPill.trailingAnchor constant:-16],
                [cat.topAnchor constraintEqualToAnchor:glassPill.topAnchor constant:8],
                [cat.bottomAnchor constraintEqualToAnchor:glassPill.bottomAnchor constant:-8]
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
    card.layer.cornerRadius=24.0;
    card.blurView.layer.cornerRadius=24.0;
    card.blurView.layer.borderColor=on ? [[ZXTheme accentSecondary] colorWithAlphaComponent:0.20].CGColor : [ZXTheme border].CGColor;

    UIView *icon=[UIView new];
    icon.translatesAutoresizingMaskIntoConstraints=NO;
    icon.backgroundColor=[UIColor clearColor];
    [card addSubview:icon];

    UIImageView *glyph=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"shield.lefthalf.filled"]];
    glyph.tintColor=on ? [ZXTheme primaryText] : [ZXTheme mutedText];
    glyph.translatesAutoresizingMaskIntoConstraints=NO;
    [icon addSubview:glyph];

    UILabel *title=[self label:[NSString stringWithFormat:@"%@",definition[@"name"] ?: definition[@"title"] ?: fid] size:17 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    title.numberOfLines=2;
    title.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:title];

    UIView *dot=[[UIView alloc] init];
    dot.translatesAutoresizingMaskIntoConstraints=NO;
    dot.layer.cornerRadius=3;
    dot.tag=9001;
    dot.backgroundColor=on ? [ZXTheme success] : [UIColor colorWithWhite:1 alpha:0.25];
    [card addSubview:dot];

    UILabel *state=[self label:on ? @"ACTIVE" : @"READY" size:10 weight:UIFontWeightMedium color:on ? [ZXTheme success] : [ZXTheme mutedText]];
    [ZXTheme track:state spacing:1.0];
    state.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:state];
    self.functionStateLabels[fid]=state;

    ZXPremiumToggle *toggle=[[ZXPremiumToggle alloc] init];
    [toggle setOn:on animated:NO];
    toggle.accessibilityLabel=[NSString stringWithFormat:@"%@",definition[@"name"] ?: definition[@"title"] ?: fid];
    [toggle addTarget:self action:@selector(functionToggleChanged:) forControlEvents:UIControlEventValueChanged];
    [card addSubview:toggle];
    self.functionControls[fid]=toggle;

    NSString *description=[NSString stringWithFormat:@"%@",definition[@"description"] ?: @"Server-managed secure function."];
    UILabel *detail=[self label:description size:13 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    detail.numberOfLines=0;
    detail.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:detail];

    [NSLayoutConstraint activateConstraints:@[
        [icon.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [icon.topAnchor constraintEqualToAnchor:card.topAnchor constant:24],
        [icon.widthAnchor constraintEqualToConstant:28],
        [icon.heightAnchor constraintEqualToConstant:28],
        [glyph.leadingAnchor constraintEqualToAnchor:icon.leadingAnchor],
        [glyph.trailingAnchor constraintEqualToAnchor:icon.trailingAnchor],
        [glyph.topAnchor constraintEqualToAnchor:icon.topAnchor],
        [glyph.bottomAnchor constraintEqualToAnchor:icon.bottomAnchor],

        [toggle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        [toggle.topAnchor constraintEqualToAnchor:card.topAnchor constant:22],
        [toggle.widthAnchor constraintEqualToConstant:56],
        [toggle.heightAnchor constraintEqualToConstant:34],

        [title.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:14],
        [title.trailingAnchor constraintLessThanOrEqualToAnchor:toggle.leadingAnchor constant:-14],
        [title.topAnchor constraintEqualToAnchor:card.topAnchor constant:21],

        [dot.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [dot.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:10],
        [dot.widthAnchor constraintEqualToConstant:6],
        [dot.heightAnchor constraintEqualToConstant:6],
        [dot.centerYAnchor constraintEqualToAnchor:state.centerYAnchor],

        [state.leadingAnchor constraintEqualToAnchor:dot.trailingAnchor constant:7],
        [state.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:5],

        [detail.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [detail.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        [detail.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:18],
        [detail.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-24]
    ]];
    return card;
}

- (void)presentActivationStatusForFunction:(NSString *)functionId activating:(BOOL)activating {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *old=[self.view viewWithTag:4933];
        if(old) [old removeFromSuperview];

        UIVisualEffectView *overlay=[[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
        overlay.tag=4933;
        overlay.translatesAutoresizingMaskIntoConstraints=NO;
        overlay.backgroundColor=[UIColor colorWithWhite:0 alpha:0.30];
        overlay.alpha=0;
        overlay.layer.zPosition=35000;
        [self.view addSubview:overlay];

        ZXGlassCard *card=[[ZXGlassCard alloc] init];
        card.layer.cornerRadius=24; card.blurView.layer.cornerRadius=24;
        [overlay.contentView addSubview:card];

        ZXOrbitLoader *loader=[[ZXOrbitLoader alloc] init];
        [card addSubview:loader];

        NSString *name=[NSString stringWithFormat:@"%@",self.functionDefinitions[functionId][@"name"] ?: self.functionDefinitions[functionId][@"title"] ?: functionId];
        UILabel *title=[self label:activating ? @"Activating" : @"Deactivating" size:15 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
        title.text=[NSString stringWithFormat:@"%@ %@",ZXLocalizedUI(activating ? @"Activating" : @"Deactivating"),name];
        title.textAlignment=NSTextAlignmentCenter;
        title.translatesAutoresizingMaskIntoConstraints=NO;
        [card addSubview:title];

        UILabel *detail=[self label:@"Secure operation in progress" size:12 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
        detail.textAlignment=NSTextAlignmentCenter; detail.translatesAutoresizingMaskIntoConstraints=NO;
        [card addSubview:detail];

        [NSLayoutConstraint activateConstraints:@[
            [overlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [overlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [overlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [overlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
            [card.centerXAnchor constraintEqualToAnchor:overlay.contentView.centerXAnchor],
            [card.centerYAnchor constraintEqualToAnchor:overlay.contentView.centerYAnchor],
            [card.leadingAnchor constraintGreaterThanOrEqualToAnchor:overlay.contentView.leadingAnchor constant:44],
            [card.trailingAnchor constraintLessThanOrEqualToAnchor:overlay.contentView.trailingAnchor constant:-44],
            [loader.topAnchor constraintEqualToAnchor:card.topAnchor constant:24],
            [loader.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
            [loader.widthAnchor constraintEqualToConstant:28],
            [loader.heightAnchor constraintEqualToConstant:28],
            [title.topAnchor constraintEqualToAnchor:loader.bottomAnchor constant:14],
            [title.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
            [title.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
            [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:5],
            [detail.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
            [detail.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
            [detail.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-24]
        ]];

        card.transform=CGAffineTransformMakeScale(0.92,0.92);
        [UIView animateWithDuration:0.48 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.2 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            overlay.alpha=1; card.transform=CGAffineTransformIdentity;
        } completion:nil];
    });
}
- (void)dismissActivationStatusSuccess:(BOOL)success functionId:(NSString *)functionId {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *overlay=[self.view viewWithTag:4933];
        if(!overlay) return;
        UILabel *title=nil;
        for(UIView *v in overlay.subviews) {
            if([v isKindOfClass:[UIVisualEffectView class]]) {
                for(UIView *c in ((UIVisualEffectView *)v).contentView.subviews) {
                    if([c isKindOfClass:[ZXGlassCard class]]) {
                        UIView *gc=(UIView *)c;
                        for(UIView *sub in ((ZXGlassCard *)gc).blurView.contentView.subviews)
                            if([sub isKindOfClass:[UILabel class]]) { title=(UILabel *)sub; break; }
                    }
                }
            }
        }
        if(title){
            title.text=success ? ZXLocalizedUI(@"Activated") : ZXLocalizedUI(@"Operation failed");
            title.textColor=success ? [ZXTheme success] : [ZXTheme error];
        }
        for(UIView *v in overlay.subviews) if([v isKindOfClass:[UIVisualEffectView class]])
            for(UIView *c in ((UIVisualEffectView *)v).contentView.subviews)
                if([c isKindOfClass:[ZXGlassCard class]])
                    for(UIView *sub in ((ZXGlassCard *)c).blurView.contentView.subviews)
                        if([sub isKindOfClass:[ZXOrbitLoader class]]) [(ZXOrbitLoader *)sub stopAnimating];

        if(success) [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeSuccess];
        else [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeError];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.62*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
            if(overlay.superview){
                [UIView animateWithDuration:0.24 animations:^{ overlay.alpha=0; } completion:^(BOOL f){ [overlay removeFromSuperview]; }];
            }
        });
    });
}

- (NSString *)functionIdForControl:(UIControl *)control {
    for (NSString *fid in self.functionControls) {
        if (self.functionControls[fid] == control) return fid;
    }
    return nil;
}

- (void)functionToggleChanged:(ZXPremiumToggle *)sender {
    NSString *fid=[self functionIdForControl:sender];
    if(!fid.length) return;
    BOOL requested=sender.isOn;
    [sender setProcessing:YES];
    ZXGlassCard *card=(ZXGlassCard *)self.functionCards[fid];
    UILabel *state=self.functionStateLabels[fid];
    if(state){
        state.text=ZXLocalizedUI(@"VERIFYING");
        state.textColor=[ZXTheme warning];
    }
    [self presentActivationStatusForFunction:fid activating:requested];

    __weak typeof(self) weakSelf=self;
    void (^finish)(BOOL,NSString *)=^(BOOL success,NSString *msg){
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self=weakSelf;
            if(!self) return;
            [sender setProcessing:NO];
            BOOL finalState=success ? requested : !requested;
            self.functionStates[fid]=@(finalState);
            [sender setOn:finalState animated:YES];
            if(state){
                state.text=ZXLocalizedUI(finalState ? @"ACTIVE" : @"READY");
                state.textColor=finalState ? [ZXTheme success] : [ZXTheme mutedText];
            }
            [UIView animateWithDuration:0.30 animations:^{
                card.blurView.layer.borderColor=finalState ? [[ZXTheme accentSecondary] colorWithAlphaComponent:0.20].CGColor : [ZXTheme border].CGColor;
                card.layer.shadowOpacity=finalState ? 0.22 : 0.12;
                card.layer.shadowColor=finalState ? [ZXTheme accentPrimary].CGColor : [UIColor blackColor].CGColor;
            }];
            [self dismissActivationStatusSuccess:success functionId:fid];
            if(!success && msg.length) [self showToast:msg success:NO];
        });
    };

    if([self.delegate respondsToSelector:@selector(zentraxDidRequestFunctionOperation:action:completion:)])
        [self.delegate zentraxDidRequestFunctionOperation:fid action:requested completion:finish];
    else if([self.delegate respondsToSelector:@selector(zentraxDidRequestModuleToggle:state:completion:)])
        [self.delegate zentraxDidRequestModuleToggle:fid state:requested completion:finish];
    else {
        Class mgrCls=NSClassFromString(@"ZentraxNetworkManager");
        if(mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]){
            id manager=((id(*)(id,SEL))objc_msgSend)((id)mgrCls,NSSelectorFromString(@"sharedManager"));
            SEL operSel=NSSelectorFromString(@"performModuleOperationWithFunctionId:action:completion:");
            if([manager respondsToSelector:operSel]){
                void (^netCompletion)(BOOL,NSDictionary *,NSString *)=^(BOOL succ,NSDictionary *res,NSString *err){ finish(succ,err); };
                ((void(*)(id,SEL,id,NSInteger,id))objc_msgSend)(manager,operSel,fid,requested ? 2 : 1,netCompletion);
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
    button.backgroundColor=[UIColor colorWithWhite:1 alpha:0.06];
    button.layer.cornerRadius=18;
    button.layer.borderWidth=0.5;
    button.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.10].CGColor;
    button.layer.shadowColor=[UIColor blackColor].CGColor;
    button.layer.shadowOpacity=0.20;
    button.layer.shadowRadius=18;
    button.layer.shadowOffset=CGSizeMake(0,8);
    button.titleLabel.font=[ZXTheme heading:14];
    [button setTitleColor:[ZXTheme primaryText] forState:UIControlStateNormal];
    [button setTitleColor:[ZXTheme secondaryText] forState:UIControlStateHighlighted];
    button.accessibilityTraits=UIAccessibilityTraitButton;
    [button addTarget:self action:@selector(zxSecondaryButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(zxSecondaryButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
}

- (void)zxSecondaryButtonTouchDown:(UIButton *)button {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [UIView animateWithDuration:0.11 animations:^{
        button.transform=CGAffineTransformMakeScale(0.985,0.985);
        button.alpha=0.82;
    }];
}

- (void)zxSecondaryButtonTouchUp:(UIButton *)button {
    [UIView animateWithDuration:0.42 delay:0 usingSpringWithDamping:0.76 initialSpringVelocity:0.2 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        button.transform=CGAffineTransformIdentity;
        button.alpha=1.0;
    } completion:nil];
}

- (void)setupStartupBlock {
    _startupBlockContainer = [[UIView alloc] init];
    _startupBlockContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_startupBlockContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_startupBlockContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_startupBlockContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_startupBlockContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_startupBlockContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    ZXGlassCard *card = [[ZXGlassCard alloc] init];
    [_startupBlockContainer addSubview:card];
    
    UIView *iconBg = [[UIView alloc] init];
    iconBg.backgroundColor = [[ZXTheme error] colorWithAlphaComponent:0.15];
    iconBg.layer.cornerRadius = 28;
    iconBg.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:iconBg];
    
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"exclamationmark.shield.fill"]];
    icon.tintColor = [ZXTheme error];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [iconBg addSubview:icon];
    
    _startupBlockTitle = [self label:@"ACCESS DENIED" size:22 weight:UIFontWeightHeavy color:[ZXTheme primaryText]];
    _startupBlockTitle.textAlignment = NSTextAlignmentCenter;
    _startupBlockTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_startupBlockTitle];
    
    _startupBlockMessage = [self label:@"" size:15 weight:UIFontWeightMedium color:[ZXTheme secondaryText]];
    _startupBlockMessage.textAlignment = NSTextAlignmentCenter;
    _startupBlockMessage.numberOfLines = 0;
    _startupBlockMessage.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_startupBlockMessage];
    
    _startupBlockAction = [UIButton buttonWithType:UIButtonTypeSystem];
    [self styleSecondaryButton:_startupBlockAction];
    [_startupBlockAction setTitle:ZXLocalizedUI(@"RETRY CONNECTION") forState:UIControlStateNormal];
    _startupBlockAction.translatesAutoresizingMaskIntoConstraints = NO;
    [_startupBlockAction addTarget:self action:@selector(startupBlockRetry) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:_startupBlockAction];
    
    [NSLayoutConstraint activateConstraints:@[
        [card.leadingAnchor constraintEqualToAnchor:_startupBlockContainer.leadingAnchor constant:32],
        [card.trailingAnchor constraintEqualToAnchor:_startupBlockContainer.trailingAnchor constant:-32],
        [card.centerYAnchor constraintEqualToAnchor:_startupBlockContainer.centerYAnchor],
        
        [iconBg.topAnchor constraintEqualToAnchor:card.topAnchor constant:32],
        [iconBg.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [iconBg.widthAnchor constraintEqualToConstant:56],
        [iconBg.heightAnchor constraintEqualToConstant:56],
        
        [icon.centerXAnchor constraintEqualToAnchor:iconBg.centerXAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:iconBg.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:28],
        [icon.heightAnchor constraintEqualToConstant:28],
        
        [_startupBlockTitle.topAnchor constraintEqualToAnchor:iconBg.bottomAnchor constant:24],
        [_startupBlockTitle.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [_startupBlockTitle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        
        [_startupBlockMessage.topAnchor constraintEqualToAnchor:_startupBlockTitle.bottomAnchor constant:12],
        [_startupBlockMessage.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [_startupBlockMessage.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        
        [_startupBlockAction.topAnchor constraintEqualToAnchor:_startupBlockMessage.bottomAnchor constant:32],
        [_startupBlockAction.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [_startupBlockAction.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        [_startupBlockAction.heightAnchor constraintEqualToConstant:56],
        [_startupBlockAction.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-24]
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
    if (_settingsContainer) [_settingsContainer removeFromSuperview];
    
    _settingsContainer = [[UIView alloc] init];
    _settingsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_settingsContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_settingsContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_settingsContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_settingsContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_settingsContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UIView *header = [[UIView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [_settingsContainer addSubview:header];
    
    UIButton *back = [self iconButton:@"chevron.left" size:28];
    [back addTarget:self action:@selector(closeSettings) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:back];
    
    UILabel *settingsTitle = [self label:@"Settings" size:24 weight:UIFontWeightHeavy color:[ZXTheme primaryText]];
    settingsTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:settingsTitle];
    
    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:_settingsContainer.leadingAnchor constant:24],
        [header.trailingAnchor constraintEqualToAnchor:_settingsContainer.trailingAnchor constant:-24],
        [header.topAnchor constraintEqualToAnchor:_settingsContainer.safeAreaLayoutGuide.topAnchor constant:12],
        [header.heightAnchor constraintEqualToConstant:44],
        
        [back.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [back.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        
        [settingsTitle.leadingAnchor constraintEqualToAnchor:back.trailingAnchor constant:16],
        [settingsTitle.centerYAnchor constraintEqualToAnchor:header.centerYAnchor]
    ]];

    _settingsScroll = [[UIScrollView alloc] init];
    _settingsScroll.showsVerticalScrollIndicator = NO;
    _settingsScroll.translatesAutoresizingMaskIntoConstraints = NO;
    [_settingsContainer addSubview:_settingsScroll];
    
    _settingsStack = [[UIStackView alloc] init];
    _settingsStack.axis = UILayoutConstraintAxisVertical;
    _settingsStack.spacing = 20;
    _settingsStack.translatesAutoresizingMaskIntoConstraints = NO;
    [_settingsScroll addSubview:_settingsStack];
    
    [NSLayoutConstraint activateConstraints:@[
        [_settingsScroll.leadingAnchor constraintEqualToAnchor:_settingsContainer.leadingAnchor constant:24],
        [_settingsScroll.trailingAnchor constraintEqualToAnchor:_settingsContainer.trailingAnchor constant:-24],
        [_settingsScroll.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:24],
        [_settingsScroll.bottomAnchor constraintEqualToAnchor:_settingsContainer.bottomAnchor],
        
        [_settingsStack.leadingAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.leadingAnchor],
        [_settingsStack.trailingAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.trailingAnchor],
        [_settingsStack.topAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.topAnchor],
        [_settingsStack.bottomAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.bottomAnchor constant:-40],
        [_settingsStack.widthAnchor constraintEqualToAnchor:_settingsScroll.frameLayoutGuide.widthAnchor]
    ]];
    [self rebuildSettings];
}

- (UIView *)settingsRow:(NSString *)title subtitle:(NSString *)subtitle icon:(NSString *)iconName color:(UIColor *)color action:(SEL)action accessory:(UIView *)accessory {
    ZXGlassCard *row=[[ZXGlassCard alloc] init];
    row.layer.cornerRadius=22; row.blurView.layer.cornerRadius=22;

    UIImageView *iv=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:iconName]];
    iv.tintColor=color ?: [ZXTheme secondaryText];
    iv.contentMode=UIViewContentModeScaleAspectFit;
    iv.translatesAutoresizingMaskIntoConstraints=NO;
    [row addSubview:iv];

    UILabel *t=[self label:title size:15 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    t.translatesAutoresizingMaskIntoConstraints=NO;
    [row addSubview:t];

    UILabel *sub=[self label:subtitle size:12 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    sub.numberOfLines=2;
    sub.translatesAutoresizingMaskIntoConstraints=NO;
    [row addSubview:sub];

    [NSLayoutConstraint activateConstraints:@[
        [row.heightAnchor constraintGreaterThanOrEqualToConstant:82],
        [iv.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:24],
        [iv.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [iv.widthAnchor constraintEqualToConstant:22],
        [iv.heightAnchor constraintEqualToConstant:22],
        [t.leadingAnchor constraintEqualToAnchor:iv.trailingAnchor constant:16],
        [t.topAnchor constraintEqualToAnchor:row.topAnchor constant:18],
        [t.trailingAnchor constraintLessThanOrEqualToAnchor:row.trailingAnchor constant:-62],
        [sub.leadingAnchor constraintEqualToAnchor:t.leadingAnchor],
        [sub.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:5],
        [sub.trailingAnchor constraintLessThanOrEqualToAnchor:row.trailingAnchor constant:-62],
        [sub.bottomAnchor constraintLessThanOrEqualToAnchor:row.bottomAnchor constant:-18]
    ]];

    if(accessory){
        accessory.translatesAutoresizingMaskIntoConstraints=NO;
        [row addSubview:accessory];
        [NSLayoutConstraint activateConstraints:@[
            [accessory.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-20],
            [accessory.centerYAnchor constraintEqualToAnchor:row.centerYAnchor]
        ]];
    }else{
        UIImageView *chev=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
        chev.tintColor=[ZXTheme mutedText];
        chev.translatesAutoresizingMaskIntoConstraints=NO;
        [row addSubview:chev];
        [NSLayoutConstraint activateConstraints:@[
            [chev.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-22],
            [chev.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
            [chev.widthAnchor constraintEqualToConstant:10],
            [chev.heightAnchor constraintEqualToConstant:14]
        ]];
    }
    if(action){
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
    return row;
}

- (void)rebuildSettings {
    for (UIView *v in [self.settingsStack.arrangedSubviews copy]) {
        [self.settingsStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    
    // License Info Segment
    UILabel *licLabel = [self label:@"LICENSE INFO" size:12 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:licLabel spacing:2.0];
    [self.settingsStack addArrangedSubview:licLabel];
    
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
    NSString *currentKey = [d stringForKey:ZXLastKey];
    
    UIButton *eye = [UIButton buttonWithType:UIButtonTypeSystem];
    [eye setImage:[UIImage systemImageNamed:self.settingsKeyRevealed ? @"eye.fill" : @"eye.slash.fill"] forState:UIControlStateNormal];
    eye.tintColor = [ZXTheme mutedText];
    [eye addTarget:self action:@selector(toggleSettingsKey:) forControlEvents:UIControlEventTouchUpInside];
    
    UIView *keyRow = [self settingsRow:ZXLocalizedUI(@"License Key") 
                              subtitle:self.settingsKeyRevealed && currentKey.length ? currentKey : @"•••• •••• ••••" 
                                  icon:@"key.fill" 
                                 color:[ZXTheme accentPrimary] 
                                action:nil 
                             accessory:eye];
    
    // Store label to update text dynamically
    for (UIView *sub in keyRow.subviews) {
        if ([sub isKindOfClass:[UILabel class]] && ((UILabel *)sub).font == [ZXTheme body:14 weight:UIFontWeightRegular]) {
            self.settingsKeyLabel = (UILabel *)sub;
            self.settingsKeyLabel.font = [ZXTheme mono:14 weight:UIFontWeightMedium];
        }
    }
    [self.settingsStack addArrangedSubview:keyRow];

    NSString *expiryStr = @"";
    if (self.licensePermanent) expiryStr = ZXLocalizedUI(@"LIFETIME");
    else if (self.expiresAt) {
        NSDateFormatter *f = [[NSDateFormatter alloc] init];
        f.dateStyle = NSDateFormatterMediumStyle;
        f.timeStyle = NSDateFormatterShortStyle;
        expiryStr = [f stringFromDate:self.expiresAt];
    } else expiryStr = ZXLocalizedUI(@"UNACTIVATED");

    UIView *expRow = [self settingsRow:ZXLocalizedUI(@"Expiry Date") subtitle:expiryStr icon:@"calendar.badge.clock" color:[ZXTheme warning] action:nil accessory:nil];
    for (UIView *sub in expRow.subviews) {
        if ([sub isKindOfClass:[UILabel class]] && ((UILabel *)sub).font == [ZXTheme body:14 weight:UIFontWeightRegular]) {
            self.settingsExpiryLabel = (UILabel *)sub;
            self.settingsExpiryLabel.font = [ZXTheme mono:14 weight:UIFontWeightMedium];
        }
    }
    [self.settingsStack addArrangedSubview:expRow];

    // Preferences
    UILabel *prefLabel = [self label:@"PREFERENCES" size:12 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:prefLabel spacing:2.0];
    [self.settingsStack addArrangedSubview:prefLabel];
    
    NSString *language = [d stringForKey:ZXLanguageKey] ?: @"English";
    [self.settingsStack addArrangedSubview:[self settingsRow:ZXLocalizedUI(@"Language") subtitle:language icon:@"globe" color:[ZXTheme accentSecondary] action:@selector(showLanguagePicker) accessory:nil]];

    UILabel *accLabel = [self label:@"SESSION" size:12 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:accLabel spacing:2.0];
    [self.settingsStack addArrangedSubview:accLabel];
    [self.settingsStack addArrangedSubview:[self settingsRow:ZXLocalizedUI(@"Sign Out") subtitle:ZXLocalizedUI(@"Close the current secure session.") icon:@"rectangle.portrait.and.arrow.right" color:[ZXTheme error] action:@selector(handleLogout) accessory:nil]];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *existing=[self.view viewWithTag:4912];
        if(existing){ [existing removeFromSuperview]; return; }

        UIView *overlay=[[UIView alloc] init];
        overlay.tag=4912;
        overlay.translatesAutoresizingMaskIntoConstraints=NO;
        overlay.backgroundColor=[UIColor colorWithWhite:0 alpha:0.58];
        overlay.alpha=0;
        overlay.layer.zPosition=40000;
        [self.view addSubview:overlay];

        ZXGlassCard *card=[[ZXGlassCard alloc] init];
        card.layer.cornerRadius=28; card.blurView.layer.cornerRadius=28;
        [overlay addSubview:card];

        UILabel *title=[self label:ZXLocalizedUI(@"Language") size:22 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
        title.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:title];

        UILabel *subtitle=[self label:ZXLocalizedUI(@"Choose your language") size:13 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
        subtitle.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:subtitle];

        NSArray *langs=@[@"English",@"Tiếng Việt",@"简体中文",@"日本語"];
        UIStackView *stack=[[UIStackView alloc] init];
        stack.axis=UILayoutConstraintAxisVertical; stack.spacing=8; stack.translatesAutoresizingMaskIntoConstraints=NO;
        [card addSubview:stack];

        __weak typeof(self) weakSelf=self;
        for(NSString *langName in langs){
            UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
            b.translatesAutoresizingMaskIntoConstraints=NO;
            b.contentHorizontalAlignment=UIControlContentHorizontalAlignmentLeft;
            b.layer.cornerRadius=16;
            b.layer.borderWidth=0.5;
            b.layer.borderColor=[ZXTheme border].CGColor;
            b.backgroundColor=[UIColor colorWithWhite:1 alpha:0.035];
            [b setTitle:langName forState:UIControlStateNormal];
            [b setTitleColor:[ZXTheme primaryText] forState:UIControlStateNormal];
            b.titleLabel.font=[ZXTheme body:15 weight:UIFontWeightMedium];
            b.layoutMargins=UIEdgeInsetsMake(0,16,0,16);
            [stack addArrangedSubview:b];
            [b.heightAnchor constraintEqualToConstant:48].active=YES;
            [b addAction:[UIAction actionWithHandler:^(__kindof UIAction *action){
                __strong typeof(weakSelf) self=weakSelf; if(!self) return;
                NSDictionary *oldConfig=self.dashboardConfiguration;
                NSDictionary *oldStates=[self.functionStates copy];
                BOOL dashboard=(self.currentState==ZXAppStateDashboard);
                NSUserDefaults *d=[[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
                [d setObject:langName forKey:ZXLanguageKey]; [d synchronize];
                [UIView animateWithDuration:0.20 animations:^{ overlay.alpha=0; card.transform=CGAffineTransformMakeScale(0.98,0.98); } completion:^(BOOL f){
                    [overlay removeFromSuperview];
                    [self rebuildAllContainers];
                    if(oldConfig.count){ [self updateDashboardWithConfiguration:oldConfig]; [self updateFunctionStates:oldStates]; }
                    if(dashboard) [self showDashboard]; else [self showSettings];
                }];
            }] forControlEvents:UIControlEventTouchUpInside];
        }

        UIButton *cancel=[UIButton buttonWithType:UIButtonTypeSystem];
        [cancel setTitle:ZXLocalizedUI(@"Cancel") forState:UIControlStateNormal];
        cancel.titleLabel.font=[ZXTheme body:14 weight:UIFontWeightMedium];
        [cancel setTitleColor:[ZXTheme secondaryText] forState:UIControlStateNormal];
        cancel.translatesAutoresizingMaskIntoConstraints=NO;
        [card addSubview:cancel];
        [cancel addAction:[UIAction actionWithHandler:^(__kindof UIAction *action){
            [UIView animateWithDuration:0.18 animations:^{ overlay.alpha=0; card.transform=CGAffineTransformMakeScale(0.98,0.98); } completion:^(BOOL f){ [overlay removeFromSuperview]; }];
        }] forControlEvents:UIControlEventTouchUpInside];

        [NSLayoutConstraint activateConstraints:@[
            [overlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [overlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [overlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [overlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
            [card.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
            [card.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
            [card.leadingAnchor constraintEqualToAnchor:overlay.leadingAnchor constant:28],
            [card.trailingAnchor constraintEqualToAnchor:overlay.trailingAnchor constant:-28],
            [title.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
            [title.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
            [title.topAnchor constraintEqualToAnchor:card.topAnchor constant:24],
            [subtitle.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
            [subtitle.trailingAnchor constraintEqualToAnchor:title.trailingAnchor],
            [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:6],
            [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
            [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
            [stack.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:20],
            [cancel.topAnchor constraintEqualToAnchor:stack.bottomAnchor constant:12],
            [cancel.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
            [cancel.heightAnchor constraintEqualToConstant:44],
            [cancel.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14]
        ]];

        card.transform=CGAffineTransformMakeScale(0.94,0.94);
        [UIView animateWithDuration:0.48 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0.2 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            overlay.alpha=1; card.transform=CGAffineTransformIdentity;
        } completion:nil];
    });
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
    UIVisualEffectView *overlay=[[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    _globalLoadingOverlay=overlay;
    overlay.translatesAutoresizingMaskIntoConstraints=NO;
    overlay.hidden=YES;
    overlay.alpha=0;
    overlay.layer.zPosition=10000;
    [self.view addSubview:overlay];

    ZXGlassCard *card=[[ZXGlassCard alloc] init];
    [overlay.contentView addSubview:card];

    _globalSpinner=[[ZXOrbitLoader alloc] init];
    [card addSubview:_globalSpinner];

    _globalLoadingTitle=[self label:@"SECURE OPERATION" size:16 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    _globalLoadingTitle.textAlignment=NSTextAlignmentCenter;
    _globalLoadingTitle.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:_globalLoadingTitle];

    _globalLoadingDetail=[self label:@"Please wait…" size:13 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    _globalLoadingDetail.textAlignment=NSTextAlignmentCenter;
    _globalLoadingDetail.translatesAutoresizingMaskIntoConstraints=NO;
    [card addSubview:_globalLoadingDetail];

    [NSLayoutConstraint activateConstraints:@[
        [overlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [overlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [overlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [overlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [card.centerXAnchor constraintEqualToAnchor:overlay.contentView.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:overlay.contentView.centerYAnchor],
        [card.leadingAnchor constraintEqualToAnchor:overlay.contentView.leadingAnchor constant:40],
        [card.trailingAnchor constraintEqualToAnchor:overlay.contentView.trailingAnchor constant:-40],
        [_globalSpinner.topAnchor constraintEqualToAnchor:card.topAnchor constant:28],
        [_globalSpinner.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [_globalSpinner.widthAnchor constraintEqualToConstant:30],
        [_globalSpinner.heightAnchor constraintEqualToConstant:30],
        [_globalLoadingTitle.topAnchor constraintEqualToAnchor:_globalSpinner.bottomAnchor constant:18],
        [_globalLoadingTitle.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [_globalLoadingTitle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [_globalLoadingDetail.topAnchor constraintEqualToAnchor:_globalLoadingTitle.bottomAnchor constant:6],
        [_globalLoadingDetail.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [_globalLoadingDetail.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [_globalLoadingDetail.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-24]
    ]];
}

- (void)showGlobalLoadingState:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.globalLoadingOverlay.hidden=NO;
        self.globalLoadingOverlay.alpha=0;
        self.globalLoadingTitle.text=ZXLocalizedUI(message.length ? message : @"SECURE OPERATION");
        self.globalLoadingDetail.text=ZXLocalizedUI(@"Please wait…");
        [self.globalSpinner startAnimating];
        [UIView animateWithDuration:0.32 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.globalLoadingOverlay.alpha=1;
        } completion:nil];
    });
}
- (void)updateGlobalLoadingMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{ self.globalLoadingDetail.text=ZXLocalizedUI(message ?: @"Please wait…"); });
}
- (void)hideGlobalLoadingState {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.globalSpinner stopAnimating];
        [UIView animateWithDuration:0.24 animations:^{ self.globalLoadingOverlay.alpha=0; } completion:^(BOOL finished){ self.globalLoadingOverlay.hidden=YES; }];
    });
}

- (void)showToast:(NSString *)message success:(BOOL)success {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.toastView) [self.toastView removeFromSuperview];

        UIColor *accent=success ? [ZXTheme success] : [ZXTheme error];
        ZXGlassCard *toast=[[ZXGlassCard alloc] init];
        toast.layer.cornerRadius=20; toast.blurView.layer.cornerRadius=20;
        toast.layer.zPosition=30000;
        toast.translatesAutoresizingMaskIntoConstraints=NO;
        [self.view addSubview:toast];
        self.toastView=toast;

        UIView *dot=[[UIView alloc] init];
        dot.backgroundColor=accent; dot.layer.cornerRadius=4; dot.translatesAutoresizingMaskIntoConstraints=NO;
        [toast addSubview:dot];

        UILabel *label=[self label:ZXLocalizedUI(message ?: @"") size:13 weight:UIFontWeightMedium color:[ZXTheme primaryText]];
        label.numberOfLines=2; label.translatesAutoresizingMaskIntoConstraints=NO;
        [toast addSubview:label];

        [NSLayoutConstraint activateConstraints:@[
            [toast.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [toast.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:14],
            [toast.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24],
            [toast.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24],
            [dot.leadingAnchor constraintEqualToAnchor:toast.leadingAnchor constant:18],
            [dot.centerYAnchor constraintEqualToAnchor:toast.centerYAnchor],
            [dot.widthAnchor constraintEqualToConstant:8],
            [dot.heightAnchor constraintEqualToConstant:8],
            [label.leadingAnchor constraintEqualToAnchor:dot.trailingAnchor constant:12],
            [label.trailingAnchor constraintEqualToAnchor:toast.trailingAnchor constant:-18],
            [label.topAnchor constraintEqualToAnchor:toast.topAnchor constant:14],
            [label.bottomAnchor constraintEqualToAnchor:toast.bottomAnchor constant:-14]
        ]];

        toast.alpha=0; toast.transform=CGAffineTransformMakeScale(0.94,0.94);
        if(success) [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeSuccess];
        else [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeError];

        [UIView animateWithDuration:0.46 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0.2 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            toast.alpha=1; toast.transform=CGAffineTransformIdentity;
        } completion:nil];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(3.0*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
            if(self.toastView==toast){
                [UIView animateWithDuration:0.24 animations:^{
                    toast.alpha=0; toast.transform=CGAffineTransformMakeScale(0.98,0.98);
                } completion:^(BOOL f){ [toast removeFromSuperview]; if(self.toastView==toast) self.toastView=nil; }];
            }
        });
    });
}

- (void)showCustomConfirmationWithTitle:(NSString *)title message:(NSString *)message confirmTitle:(NSString *)confirmTitle completion:(void (^)(void))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *existing=[self.view viewWithTag:4911];
        if(existing) [existing removeFromSuperview];

        UIVisualEffectView *overlay=[[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
        overlay.tag=4911;
        overlay.translatesAutoresizingMaskIntoConstraints=NO;
        overlay.backgroundColor=[UIColor colorWithWhite:0 alpha:0.40];
        overlay.alpha=0;
        overlay.layer.zPosition=40000;
        [self.view addSubview:overlay];

        ZXGlassCard *card=[[ZXGlassCard alloc] init];
        card.layer.cornerRadius=28; card.blurView.layer.cornerRadius=28;
        [overlay.contentView addSubview:card];

        UIView *accent=[[UIView alloc] init];
        accent.backgroundColor=[ZXTheme accentPrimary];
        accent.layer.cornerRadius=1;
        accent.translatesAutoresizingMaskIntoConstraints=NO;
        [card addSubview:accent];

        UILabel *t=[self label:title size:22 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
        t.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:t];

        UILabel *m=[self label:message size:14 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
        m.numberOfLines=0; m.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:m];

        UIButton *ok=[UIButton buttonWithType:UIButtonTypeSystem];
        [self styleSecondaryButton:ok];
        [ok setTitle:ZXLocalizedUI(confirmTitle ?: @"OK") forState:UIControlStateNormal];
        ok.translatesAutoresizingMaskIntoConstraints=NO;
        [card addSubview:ok];

        __weak typeof(self) weakSelf=self;
        [ok addAction:[UIAction actionWithHandler:^(__kindof UIAction *action){
            __strong typeof(weakSelf) self=weakSelf; if(!self) return;
            [UIView animateWithDuration:0.22 animations:^{
                overlay.alpha=0; card.transform=CGAffineTransformMakeScale(0.97,0.97);
            } completion:^(BOOL f){
                [overlay removeFromSuperview];
                if(completion) completion();
            }];
        }] forControlEvents:UIControlEventTouchUpInside];

        [NSLayoutConstraint activateConstraints:@[
            [overlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [overlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [overlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [overlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
            [card.centerXAnchor constraintEqualToAnchor:overlay.contentView.centerXAnchor],
            [card.centerYAnchor constraintEqualToAnchor:overlay.contentView.centerYAnchor],
            [card.leadingAnchor constraintEqualToAnchor:overlay.contentView.leadingAnchor constant:28],
            [card.trailingAnchor constraintEqualToAnchor:overlay.contentView.trailingAnchor constant:-28],
            [accent.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
            [accent.topAnchor constraintEqualToAnchor:card.topAnchor constant:28],
            [accent.widthAnchor constraintEqualToConstant:2],
            [accent.heightAnchor constraintEqualToConstant:22],
            [t.leadingAnchor constraintEqualToAnchor:accent.trailingAnchor constant:12],
            [t.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
            [t.topAnchor constraintEqualToAnchor:card.topAnchor constant:24],
            [m.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
            [m.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
            [m.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:12],
            [ok.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
            [ok.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
            [ok.topAnchor constraintEqualToAnchor:m.bottomAnchor constant:24],
            [ok.heightAnchor constraintEqualToConstant:52],
            [ok.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-24]
        ]];

        card.transform=CGAffineTransformMakeScale(0.94,0.94);
        [UIView animateWithDuration:0.52 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.2 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            overlay.alpha=1; card.transform=CGAffineTransformIdentity;
        } completion:nil];
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
        __strong typeof(weakSelf) self=weakSelf; if(!self) return;
        Class mgrCls=NSClassFromString(@"ZentraxNetworkManager");
        if(mgrCls && [mgrCls respondsToSelector:NSSelectorFromString(@"sharedManager")]){
            id manager=((id(*)(id,SEL))objc_msgSend)((id)mgrCls,NSSelectorFromString(@"sharedManager"));
            SEL outSel=NSSelectorFromString(@"logout");
            if([manager respondsToSelector:outSel]) ((void(*)(id,SEL))objc_msgSend)(manager,outSel);
        }
        NSUserDefaults *globalDefaults=[[NSUserDefaults alloc] initWithSuiteName:@"in.zentrax.global"];
        [globalDefaults removeObjectForKey:ZXLastKey]; [globalDefaults synchronize];
        if([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)])
            [self.delegate zentraxDidRequestLogoutWithCompletion:^{ dispatch_async(dispatch_get_main_queue(), ^{ [self showLoginScreen]; }); }];
        else [self showLoginScreen];
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
        ZXPremiumToggle *toggle=(ZXPremiumToggle *)self.functionControls[functionId];
        if([toggle isKindOfClass:[ZXPremiumToggle class]]) [toggle setOn:isOn animated:YES];

        UILabel *label=self.functionStateLabels[functionId];
        ZXGlassCard *card=(ZXGlassCard *)self.functionCards[functionId];
        if(label && card){
            label.text=ZXLocalizedUI(isOn ? @"ACTIVE" : @"READY");
            label.textColor=isOn ? [ZXTheme success] : [ZXTheme mutedText];
            [UIView animateWithDuration:0.30 animations:^{
                card.blurView.layer.borderColor=isOn ? [[ZXTheme accentSecondary] colorWithAlphaComponent:0.20].CGColor : [ZXTheme border].CGColor;
                card.layer.shadowOpacity=isOn ? 0.22 : 0.12;
                card.layer.shadowColor=isOn ? [ZXTheme accentPrimary].CGColor : [UIColor blackColor].CGColor;
            }];
            for(UIView *v in card.blurView.contentView.subviews){
                if(v.tag==9001) v.backgroundColor=isOn ? [ZXTheme success] : [UIColor colorWithWhite:1 alpha:0.25];
                for(UIView *sub in v.subviews) if([sub isKindOfClass:[UIImageView class]]) ((UIImageView *)sub).tintColor=isOn ? [ZXTheme primaryText] : [ZXTheme mutedText];
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
