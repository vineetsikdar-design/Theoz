//
//  ZentraxUI.m
//  Zentrax VIP - Premium Security Infrastructure UI
//
//  Drop-in visual/flow redesign.
//  Existing delegate callbacks and public interface are preserved.
//

#import "ZentraxUI.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>
#import <objc/runtime.h>

#pragma mark - Theme

@interface ZXTheme : NSObject
+ (UIColor *)background;
+ (UIColor *)surface;
+ (UIColor *)surfaceRaised;
+ (UIColor *)surfaceInset;
+ (UIColor *)border;
+ (UIColor *)borderStrong;
+ (UIColor *)violet;
+ (UIColor *)indigo;
+ (UIColor *)cyan;
+ (UIColor *)lavender;
+ (UIColor *)primaryText;
+ (UIColor *)secondaryText;
+ (UIColor *)mutedText;
+ (UIColor *)success;
+ (UIColor *)warning;
+ (UIColor *)error;
+ (UIFont *)display:(CGFloat)size;
+ (UIFont *)heading:(CGFloat)size;
+ (UIFont *)body:(CGFloat)size weight:(UIFontWeight)weight;
+ (UIFont *)mono:(CGFloat)size weight:(UIFontWeight)weight;
+ (void)track:(UILabel *)label spacing:(CGFloat)spacing;
+ (CAGradientLayer *)gradient;
+ (void)styleCard:(UIView *)view radius:(CGFloat)radius;
@end

@implementation ZXTheme

+ (UIColor *)background { return [UIColor colorWithRed:0.035 green:0.018 blue:0.070 alpha:1.0]; }
+ (UIColor *)surface { return [UIColor colorWithRed:0.070 green:0.032 blue:0.125 alpha:0.94]; }
+ (UIColor *)surfaceRaised { return [UIColor colorWithRed:0.095 green:0.045 blue:0.165 alpha:0.96]; }
+ (UIColor *)surfaceInset { return [UIColor colorWithRed:0.030 green:0.014 blue:0.060 alpha:0.90]; }
+ (UIColor *)border { return [UIColor colorWithRed:0.48 green:0.24 blue:0.78 alpha:0.34]; }
+ (UIColor *)borderStrong { return [UIColor colorWithRed:0.66 green:0.36 blue:1.0 alpha:0.72]; }
+ (UIColor *)violet { return [UIColor colorWithRed:0.55 green:0.22 blue:1.0 alpha:1.0]; }
+ (UIColor *)indigo { return [UIColor colorWithRed:0.28 green:0.20 blue:0.88 alpha:1.0]; }
+ (UIColor *)cyan { return [UIColor colorWithRed:0.20 green:0.78 blue:1.0 alpha:1.0]; }
+ (UIColor *)lavender { return [UIColor colorWithRed:0.78 green:0.58 blue:1.0 alpha:1.0]; }
+ (UIColor *)primaryText { return [UIColor colorWithWhite:0.98 alpha:1.0]; }
+ (UIColor *)secondaryText { return [UIColor colorWithRed:0.73 green:0.63 blue:0.86 alpha:1.0]; }
+ (UIColor *)mutedText { return [UIColor colorWithRed:0.43 green:0.31 blue:0.57 alpha:1.0]; }
+ (UIColor *)success { return [UIColor colorWithRed:0.20 green:0.92 blue:0.52 alpha:1.0]; }
+ (UIColor *)warning { return [UIColor colorWithRed:1.0 green:0.68 blue:0.20 alpha:1.0]; }
+ (UIColor *)error { return [UIColor colorWithRed:1.0 green:0.30 blue:0.43 alpha:1.0]; }

+ (UIFont *)display:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBlack]; }
+ (UIFont *)heading:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightSemibold]; }
+ (UIFont *)body:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont systemFontOfSize:size weight:weight]; }
+ (UIFont *)mono:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont monospacedSystemFontOfSize:size weight:weight]; }

+ (void)track:(UILabel *)label spacing:(CGFloat)spacing {
    if (!label.text.length) return;
    label.attributedText = [[NSAttributedString alloc] initWithString:label.text
                                                           attributes:@{NSKernAttributeName:@(spacing)}];
}

+ (CAGradientLayer *)gradient {
    CAGradientLayer *g = [CAGradientLayer layer];
    g.colors = @[(id)[self indigo].CGColor,
                 (id)[self violet].CGColor,
                 (id)[self lavender].CGColor];
    g.startPoint = CGPointMake(0.0, 0.0);
    g.endPoint = CGPointMake(1.0, 1.0);
    return g;
}

+ (void)styleCard:(UIView *)view radius:(CGFloat)radius {
    view.backgroundColor = [self surface];
    view.layer.cornerRadius = radius;
    view.layer.borderWidth = 1.0;
    view.layer.borderColor = [self border].CGColor;
    view.layer.shadowColor = [self violet].CGColor;
    view.layer.shadowOpacity = 0.10;
    view.layer.shadowRadius = 18.0;
    view.layer.shadowOffset = CGSizeMake(0, 8);
}
@end

#pragma mark - Ambient Background

@interface ZXAtmosphereView : UIView
@property(nonatomic,strong) CAGradientLayer *baseGradient;
@property(nonatomic,strong) UIView *gridView;
@property(nonatomic,strong) CAGradientLayer *gridSweep;
@property(nonatomic,strong) CAGradientLayer *violetField;
@property(nonatomic,strong) CAGradientLayer *blueField;
@property(nonatomic,strong) CAGradientLayer *vignette;
- (void)startAtmosphere;
- (void)stopAtmosphere;
@end

@implementation ZXAtmosphereView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.backgroundColor = [ZXTheme background];
    self.clipsToBounds = YES;
    self.userInteractionEnabled = NO;

    _baseGradient = [CAGradientLayer layer];
    _baseGradient.colors = @[
        (id)[UIColor colorWithRed:0.025 green:0.012 blue:0.050 alpha:1].CGColor,
        (id)[UIColor colorWithRed:0.070 green:0.020 blue:0.130 alpha:1].CGColor,
        (id)[UIColor colorWithRed:0.018 green:0.010 blue:0.045 alpha:1].CGColor
    ];
    _baseGradient.startPoint = CGPointMake(0.0, 0.0);
    _baseGradient.endPoint = CGPointMake(1.0, 1.0);
    [self.layer addSublayer:_baseGradient];

    // Soft radial light fields: no visible circle/bubble shapes.
    _violetField = [CAGradientLayer layer];
    _violetField.type = kCAGradientLayerRadial;
    _violetField.colors = @[
        (id)[[ZXTheme violet] colorWithAlphaComponent:0.11].CGColor,
        (id)[[ZXTheme violet] colorWithAlphaComponent:0.035].CGColor,
        (id)[UIColor clearColor].CGColor
    ];
    _violetField.locations = @[@0.0, @0.38, @1.0];
    [self.layer addSublayer:_violetField];

    _blueField = [CAGradientLayer layer];
    _blueField.type = kCAGradientLayerRadial;
    _blueField.colors = @[
        (id)[[ZXTheme cyan] colorWithAlphaComponent:0.055].CGColor,
        (id)[[ZXTheme indigo] colorWithAlphaComponent:0.020].CGColor,
        (id)[UIColor clearColor].CGColor
    ];
    _blueField.locations = @[@0.0, @0.40, @1.0];
    [self.layer addSublayer:_blueField];

    _gridView = [[UIView alloc] initWithFrame:CGRectZero];
    _gridView.backgroundColor = [UIColor colorWithPatternImage:[self gridImage]];
    _gridView.alpha = 0.18;
    [self addSubview:_gridView];

    _gridSweep = [CAGradientLayer layer];
    _gridSweep.colors = @[
        (id)[UIColor clearColor].CGColor,
        (id)[[ZXTheme lavender] colorWithAlphaComponent:0.11].CGColor,
        (id)[UIColor clearColor].CGColor
    ];
    _gridSweep.startPoint = CGPointMake(0, 0);
    _gridSweep.endPoint = CGPointMake(1, 0);
    [self.layer addSublayer:_gridSweep];

    _vignette = [CAGradientLayer layer];
    _vignette.colors = @[
        (id)[UIColor clearColor].CGColor,
        (id)[[UIColor blackColor] colorWithAlphaComponent:0.30].CGColor
    ];
    _vignette.startPoint = CGPointMake(0.5, 0.35);
    _vignette.endPoint = CGPointMake(0.5, 1.0);
    [self.layer addSublayer:_vignette];

    return self;
}

- (UIImage *)gridImage {
    CGSize size = CGSizeMake(48, 48);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, [[ZXTheme lavender] colorWithAlphaComponent:0.12].CGColor);
    CGContextSetLineWidth(ctx, 0.55);
    CGContextMoveToPoint(ctx, 0, 0);
    CGContextAddLineToPoint(ctx, 48, 0);
    CGContextMoveToPoint(ctx, 0, 0);
    CGContextAddLineToPoint(ctx, 0, 48);
    CGContextStrokePath(ctx);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.baseGradient.frame = self.bounds;
    self.violetField.frame = CGRectMake(-self.bounds.size.width * 0.35,
                                        -self.bounds.size.height * 0.12,
                                        self.bounds.size.width * 0.95,
                                        self.bounds.size.height * 0.72);
    self.blueField.frame = CGRectMake(self.bounds.size.width * 0.35,
                                      self.bounds.size.height * 0.42,
                                      self.bounds.size.width * 0.90,
                                      self.bounds.size.height * 0.70);
    self.gridView.frame = CGRectMake(0, -48, self.bounds.size.width, self.bounds.size.height + 96);
    self.gridSweep.frame = CGRectMake(-self.bounds.size.width, 0,
                                      self.bounds.size.width * 2.0, self.bounds.size.height);
    self.vignette.frame = self.bounds;
}

- (void)startAtmosphere {
    [self stopAtmosphere];

    CABasicAnimation *grid = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    grid.fromValue = @(-48);
    grid.toValue = @(48);
    grid.duration = 11.0;
    grid.repeatCount = HUGE_VALF;
    grid.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [self.gridView.layer addAnimation:grid forKey:@"gridDrift"];

    CABasicAnimation *sweep = [CABasicAnimation animationWithKeyPath:@"position.x"];
    sweep.fromValue = @(-self.bounds.size.width);
    sweep.toValue = @(self.bounds.size.width * 1.35);
    sweep.duration = 13.0;
    sweep.repeatCount = HUGE_VALF;
    sweep.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.gridSweep addAnimation:sweep forKey:@"gridLight"];

    CABasicAnimation *violetDrift = [CABasicAnimation animationWithKeyPath:@"position"];
    violetDrift.fromValue = [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(self.violetField.frame),
                                                                   CGRectGetMidY(self.violetField.frame))];
    violetDrift.toValue = [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(self.violetField.frame) + 55.0,
                                                                 CGRectGetMidY(self.violetField.frame) + 40.0)];
    violetDrift.duration = 18.0;
    violetDrift.autoreverses = YES;
    violetDrift.repeatCount = HUGE_VALF;
    violetDrift.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.violetField addAnimation:violetDrift forKey:@"violetDrift"];

    CABasicAnimation *blueDrift = [CABasicAnimation animationWithKeyPath:@"position"];
    blueDrift.fromValue = [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(self.blueField.frame),
                                                                 CGRectGetMidY(self.blueField.frame))];
    blueDrift.toValue = [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(self.blueField.frame) - 55.0,
                                                               CGRectGetMidY(self.blueField.frame) - 35.0)];
    blueDrift.duration = 21.0;
    blueDrift.autoreverses = YES;
    blueDrift.repeatCount = HUGE_VALF;
    blueDrift.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.blueField addAnimation:blueDrift forKey:@"blueDrift"];
}

- (void)stopAtmosphere {
    [self.gridView.layer removeAnimationForKey:@"gridDrift"];
    [self.gridSweep removeAnimationForKey:@"gridLight"];
    [self.violetField removeAllAnimations];
    [self.blueField removeAllAnimations];
    [self.layer removeAllAnimations];
}
@end

#pragma mark - Small UI Helpers

static UIView *ZXLine(void) {
    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [[ZXTheme lavender] colorWithAlphaComponent:0.14];
    return line;
}

static UILabel *ZXLabel(NSString *text, UIFont *font, UIColor *color) {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = font;
    label.textColor = color;
    return label;
}

#pragma mark - Premium Button

@interface ZXPremiumButton : UIButton
@property(nonatomic,strong) UIView *buttonSurface;
@property(nonatomic,strong) CAGradientLayer *gradientLayer;
@property(nonatomic,strong) UIActivityIndicatorView *spinner;
@property(nonatomic,strong) NSString *savedTitle;
- (void)setLoading:(BOOL)loading;
@end

@implementation ZXPremiumButton

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;

    self.layer.cornerRadius = 15;
    self.clipsToBounds = NO;
    self.titleLabel.font = [ZXTheme heading:14];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    _buttonSurface = [[UIView alloc] init];
    _buttonSurface.userInteractionEnabled = NO;
    _buttonSurface.layer.cornerRadius = 15;
    _buttonSurface.clipsToBounds = YES;
    _buttonSurface.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_buttonSurface];

    _gradientLayer = [ZXTheme gradient];
    [_buttonSurface.layer insertSublayer:_gradientLayer atIndex:0];

    self.layer.shadowColor = [ZXTheme violet].CGColor;
    self.layer.shadowOpacity = 0.28;
    self.layer.shadowRadius = 16;
    self.layer.shadowOffset = CGSizeMake(0, 7);

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    _spinner.color = [UIColor whiteColor];
    _spinner.hidesWhenStopped = YES;
    _spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_spinner];

    [NSLayoutConstraint activateConstraints:@[
        [_buttonSurface.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_buttonSurface.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_buttonSurface.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_buttonSurface.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_spinner.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_spinner.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
    ]];

    [self addTarget:self action:@selector(zxTouchDown) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(zxTouchUp) forControlEvents:UIControlEventTouchUpInside |
     UIControlEventTouchUpOutside | UIControlEventTouchCancel];

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.buttonSurface.bounds;
}

- (void)zxTouchDown {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [UIView animateWithDuration:0.16 animations:^{
        self.transform = CGAffineTransformMakeScale(0.975, 0.975);
        self.layer.shadowOpacity = 0.42;
    }];
}

- (void)zxTouchUp {
    [UIView animateWithDuration:0.35 delay:0
         usingSpringWithDamping:0.78 initialSpringVelocity:0.4
                       options:UIViewAnimationOptionAllowUserInteraction
                    animations:^{
        self.transform = CGAffineTransformIdentity;
        self.layer.shadowOpacity = 0.28;
    } completion:nil];
}

- (void)setLoading:(BOOL)loading {
    self.userInteractionEnabled = !loading;
    if (loading) {
        self.savedTitle = [self titleForState:UIControlStateNormal];
        [self setTitle:@"" forState:UIControlStateNormal];
        [_spinner startAnimating];
        self.buttonSurface.alpha = 0.72;
    } else {
        [self setTitle:self.savedTitle ?: @"" forState:UIControlStateNormal];
        [_spinner stopAnimating];
        self.buttonSurface.alpha = 1.0;
    }
}
@end

#pragma mark - Premium Key Field

@interface ZXPremiumField : UIView <UITextFieldDelegate>
@property(nonatomic,strong) UITextField *textField;
@property(nonatomic,strong) UILabel *caption;
@property(nonatomic,strong) UIView *container;
@property(nonatomic,strong) UIButton *pasteButton;
@property(nonatomic,strong) UIButton *eyeButton;
@property(nonatomic,strong) UIImageView *icon;
@end

@implementation ZXPremiumField

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;

    _caption = ZXLabel(@"AUTHENTICATION KEY", [ZXTheme mono:10 weight:UIFontWeightBold], [ZXTheme secondaryText]);
    [ZXTheme track:_caption spacing:1.5];
    _caption.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_caption];

    _container = [[UIView alloc] init];
    _container.backgroundColor = [ZXTheme surface];
    _container.layer.cornerRadius = 14;
    _container.layer.borderWidth = 1;
    _container.layer.borderColor = [ZXTheme border].CGColor;
    _container.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_container];

    _icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.shield.fill"]];
    _icon.tintColor = [ZXTheme mutedText];
    _icon.contentMode = UIViewContentModeScaleAspectFit;
    _icon.translatesAutoresizingMaskIntoConstraints = NO;
    [_container addSubview:_icon];

    _textField = [[UITextField alloc] init];
    _textField.textColor = [ZXTheme primaryText];
    _textField.font = [ZXTheme mono:14 weight:UIFontWeightMedium];
    _textField.secureTextEntry = YES;
    _textField.delegate = self;
    _textField.autocorrectionType = UITextAutocorrectionTypeNo;
    _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _textField.returnKeyType = UIReturnKeyDone;
    _textField.attributedPlaceholder = [[NSAttributedString alloc]
        initWithString:@"ZTX-XXXX-XXXX-XXXX"
            attributes:@{NSForegroundColorAttributeName:[ZXTheme mutedText]}];
    _textField.translatesAutoresizingMaskIntoConstraints = NO;
    [_container addSubview:_textField];

    _eyeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_eyeButton setImage:[UIImage systemImageNamed:@"eye.slash.fill"] forState:UIControlStateNormal];
    _eyeButton.tintColor = [ZXTheme mutedText];
    _eyeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_eyeButton addTarget:self action:@selector(toggleSecureEntry) forControlEvents:UIControlEventTouchUpInside];
    [_container addSubview:_eyeButton];

    _pasteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_pasteButton setTitle:@"PASTE" forState:UIControlStateNormal];
    _pasteButton.titleLabel.font = [ZXTheme heading:11];
    [_pasteButton setTitleColor:[ZXTheme lavender] forState:UIControlStateNormal];
    _pasteButton.backgroundColor = [[ZXTheme violet] colorWithAlphaComponent:0.10];
    _pasteButton.layer.cornerRadius = 8;
    _pasteButton.layer.borderWidth = 1;
    _pasteButton.layer.borderColor = [[ZXTheme violet] colorWithAlphaComponent:0.24].CGColor;
    _pasteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_pasteButton addTarget:self action:@selector(pasteKeyTapped) forControlEvents:UIControlEventTouchUpInside];
    [_container addSubview:_pasteButton];

    [NSLayoutConstraint activateConstraints:@[
        [_caption.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_caption.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:3],

        [_container.topAnchor constraintEqualToAnchor:_caption.bottomAnchor constant:8],
        [_container.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_container.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_container.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_container.heightAnchor constraintEqualToConstant:58],

        [_icon.leadingAnchor constraintEqualToAnchor:_container.leadingAnchor constant:15],
        [_icon.centerYAnchor constraintEqualToAnchor:_container.centerYAnchor],
        [_icon.widthAnchor constraintEqualToConstant:18],
        [_icon.heightAnchor constraintEqualToConstant:18],

        [_pasteButton.trailingAnchor constraintEqualToAnchor:_container.trailingAnchor constant:-9],
        [_pasteButton.centerYAnchor constraintEqualToAnchor:_container.centerYAnchor],
        [_pasteButton.widthAnchor constraintEqualToConstant:58],
        [_pasteButton.heightAnchor constraintEqualToConstant:32],

        [_eyeButton.trailingAnchor constraintEqualToAnchor:_pasteButton.leadingAnchor constant:-3],
        [_eyeButton.centerYAnchor constraintEqualToAnchor:_container.centerYAnchor],
        [_eyeButton.widthAnchor constraintEqualToConstant:30],
        [_eyeButton.heightAnchor constraintEqualToConstant:32],

        [_textField.leadingAnchor constraintEqualToAnchor:_icon.trailingAnchor constant:11],
        [_textField.trailingAnchor constraintEqualToAnchor:_eyeButton.leadingAnchor constant:-5],
        [_textField.centerYAnchor constraintEqualToAnchor:_container.centerYAnchor],
        [_textField.heightAnchor constraintEqualToConstant:40]
    ]];

    return self;
}

- (void)pasteKeyTapped {
    NSString *value = [[UIPasteboard generalPasteboard].string
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (value.length) {
        self.textField.text = value;
        [self.textField sendActionsForControlEvents:UIControlEventEditingChanged];
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    }
}

- (void)toggleSecureEntry {
    BOOL secure = !self.textField.secureTextEntry;
    NSString *value = self.textField.text ?: @"";
    self.textField.secureTextEntry = secure;
    self.textField.text = value;
    [self.eyeButton setImage:[UIImage systemImageNamed:(secure ? @"eye.slash.fill" : @"eye.fill")]
                    forState:UIControlStateNormal];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.22 animations:^{
        self.container.layer.borderColor = [ZXTheme borderStrong].CGColor;
        self.icon.tintColor = [ZXTheme cyan];
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.22 animations:^{
        self.container.layer.borderColor = [ZXTheme border].CGColor;
        self.icon.tintColor = [ZXTheme mutedText];
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end

#pragma mark - Toggle

@interface ZXPremiumToggle : UIControl
@property(nonatomic,assign) BOOL isOn;
@property(nonatomic,strong) NSString *moduleId;
@property(nonatomic,strong) UIView *track;
@property(nonatomic,strong) UIView *thumb;
@property(nonatomic,strong) UIActivityIndicatorView *spinner;
@property(nonatomic,strong) NSLayoutConstraint *thumbLeading;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
- (void)setLoading:(BOOL)loading;
@end

@implementation ZXPremiumToggle

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;

    self.translatesAutoresizingMaskIntoConstraints = NO;

    _track = [[UIView alloc] init];
    _track.backgroundColor = [ZXTheme surfaceInset];
    _track.layer.cornerRadius = 14;
    _track.layer.borderWidth = 1;
    _track.layer.borderColor = [ZXTheme border].CGColor;
    _track.userInteractionEnabled = NO;
    _track.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_track];

    _thumb = [[UIView alloc] init];
    _thumb.backgroundColor = [ZXTheme mutedText];
    _thumb.layer.cornerRadius = 10;
    _thumb.userInteractionEnabled = NO;
    _thumb.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_thumb];

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    _spinner.transform = CGAffineTransformMakeScale(0.55, 0.55);
    _spinner.hidesWhenStopped = YES;
    _spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [_thumb addSubview:_spinner];

    _thumbLeading = [_thumb.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:4];

    [NSLayoutConstraint activateConstraints:@[
        [self.widthAnchor constraintEqualToConstant:50],
        [self.heightAnchor constraintEqualToConstant:28],
        [_track.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_track.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_track.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_track.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_thumb.widthAnchor constraintEqualToConstant:20],
        [_thumb.heightAnchor constraintEqualToConstant:20],
        [_thumb.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        _thumbLeading,
        [_spinner.centerXAnchor constraintEqualToAnchor:_thumb.centerXAnchor],
        [_spinner.centerYAnchor constraintEqualToAnchor:_thumb.centerYAnchor]
    ]];

    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)]];
    [self updateStateAnimated:NO];
    return self;
}

- (void)handleTap {
    if (!self.userInteractionEnabled) return;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [self setOn:!self.isOn animated:YES];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _isOn = on;
    self.thumbLeading.constant = on ? 26 : 4;

    void (^updates)(void) = ^{
        [self layoutIfNeeded];
        if (self.isOn) {
            self.track.backgroundColor = [[ZXTheme violet] colorWithAlphaComponent:0.15];
            self.track.layer.borderColor = [[ZXTheme lavender] colorWithAlphaComponent:0.62].CGColor;
            self.thumb.backgroundColor = [ZXTheme lavender];
            self.thumb.layer.shadowColor = [ZXTheme violet].CGColor;
            self.thumb.layer.shadowOpacity = 0.85;
            self.thumb.layer.shadowRadius = 7;
        } else {
            self.track.backgroundColor = [ZXTheme surfaceInset];
            self.track.layer.borderColor = [ZXTheme border].CGColor;
            self.thumb.backgroundColor = [ZXTheme mutedText];
            self.thumb.layer.shadowOpacity = 0;
        }
    };

    if (animated) {
        [UIView animateWithDuration:0.36 delay:0
             usingSpringWithDamping:0.80 initialSpringVelocity:0.4
                           options:UIViewAnimationOptionCurveEaseInOut
                        animations:updates completion:nil];
    } else {
        updates();
    }
}

- (void)setLoading:(BOOL)loading {
    self.userInteractionEnabled = !loading;
    if (loading) {
        self.thumb.backgroundColor = [UIColor clearColor];
        self.thumb.layer.shadowOpacity = 0;
        [self.spinner startAnimating];
    } else {
        [self.spinner stopAnimating];
        [self updateStateAnimated:YES];
    }
}
@end

#pragma mark - Toast

@interface ZXPremiumToast : NSObject
+ (void)showVerificationInView:(UIView *)view;
+ (void)showSuccess:(NSString *)message inView:(UIView *)view;
@end

@implementation ZXPremiumToast

+ (void)showVerificationInView:(UIView *)view {
    [self showMessage:@"NODE VERIFIED" subtitle:@"Secure session established." inView:view verification:YES];
}

+ (void)showSuccess:(NSString *)message inView:(UIView *)view {
    [self showMessage:message subtitle:@"Operation completed successfully." inView:view verification:NO];
}

+ (void)showMessage:(NSString *)message subtitle:(NSString *)subtitle inView:(UIView *)view verification:(BOOL)verification {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *sub in [view.subviews copy]) {
            if (sub.tag == 887766) [sub removeFromSuperview];
        }

        UIView *toast = [[UIView alloc] init];
        toast.tag = 887766;
        toast.backgroundColor = [ZXTheme surfaceRaised];
        toast.layer.cornerRadius = 17;
        toast.layer.borderWidth = 1;
        toast.layer.borderColor = [[ZXTheme violet] colorWithAlphaComponent:0.42].CGColor;
        toast.layer.shadowColor = [ZXTheme violet].CGColor;
        toast.layer.shadowOpacity = 0.22;
        toast.layer.shadowRadius = 22;
        toast.layer.shadowOffset = CGSizeMake(0, 8);
        toast.translatesAutoresizingMaskIntoConstraints = NO;

        UIView *dot = [[UIView alloc] init];
        dot.backgroundColor = verification ? [ZXTheme success] : [ZXTheme cyan];
        dot.layer.cornerRadius = 5;
        dot.translatesAutoresizingMaskIntoConstraints = NO;
        [toast addSubview:dot];

        UILabel *title = ZXLabel(message, [ZXTheme heading:13], [ZXTheme primaryText]);
        title.translatesAutoresizingMaskIntoConstraints = NO;
        [toast addSubview:title];

        UILabel *detail = ZXLabel(subtitle, [ZXTheme body:10 weight:UIFontWeightRegular], [ZXTheme secondaryText]);
        detail.translatesAutoresizingMaskIntoConstraints = NO;
        [toast addSubview:detail];

        [view addSubview:toast];

        UILayoutGuide *safe = view.safeAreaLayoutGuide;
        [NSLayoutConstraint activateConstraints:@[
            [toast.centerXAnchor constraintEqualToAnchor:view.centerXAnchor],
            [toast.topAnchor constraintEqualToAnchor:safe.topAnchor constant:10],
            [toast.widthAnchor constraintLessThanOrEqualToAnchor:view.widthAnchor constant:-40],
            [toast.heightAnchor constraintEqualToConstant:58],

            [dot.leadingAnchor constraintEqualToAnchor:toast.leadingAnchor constant:16],
            [dot.centerYAnchor constraintEqualToAnchor:toast.centerYAnchor],
            [dot.widthAnchor constraintEqualToConstant:10],
            [dot.heightAnchor constraintEqualToConstant:10],

            [title.leadingAnchor constraintEqualToAnchor:dot.trailingAnchor constant:11],
            [title.topAnchor constraintEqualToAnchor:toast.topAnchor constant:11],
            [title.trailingAnchor constraintEqualToAnchor:toast.trailingAnchor constant:-15],

            [detail.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
            [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:2],
            [detail.trailingAnchor constraintEqualToAnchor:title.trailingAnchor]
        ]];

        toast.alpha = 0;
        toast.transform = CGAffineTransformMakeTranslation(0, -10);
        [view layoutIfNeeded];

        [UIView animateWithDuration:0.42 delay:0
             usingSpringWithDamping:0.82 initialSpringVelocity:0.2
                           options:UIViewAnimationOptionCurveEaseOut
                        animations:^{
            toast.alpha = 1;
            toast.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 delay:2.8
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                toast.alpha = 0;
                toast.transform = CGAffineTransformMakeTranslation(0, -8);
            } completion:^(BOOL done) {
                [toast removeFromSuperview];
            }];
        }];
    });
}
@end

#pragma mark - Modal

@interface ZXModalManager : NSObject
+ (void)showWithIcon:(NSString *)iconName
             isError:(BOOL)isError
               title:(NSString *)title
             message:(NSString *)message
         actionTitle:(NSString *)actionTitle
              inView:(UIView *)parent;
@end

@implementation ZXModalManager

+ (void)showWithIcon:(NSString *)iconName
             isError:(BOOL)isError
               title:(NSString *)title
             message:(NSString *)message
         actionTitle:(NSString *)actionTitle
              inView:(UIView *)parent {

    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *v in [parent.subviews copy]) {
            if (v.tag == 100100) [v removeFromSuperview];
        }

        UIView *overlay = [[UIView alloc] initWithFrame:parent.bounds];
        overlay.tag = 100100;
        overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.62];
        overlay.alpha = 0;
        [parent addSubview:overlay];

        UIView *card = [[UIView alloc] init];
        [ZXTheme styleCard:card radius:22];
        card.layer.borderColor = (isError ? [ZXTheme error] : [ZXTheme success]).CGColor;
        card.layer.shadowOpacity = 0.30;
        card.translatesAutoresizingMaskIntoConstraints = NO;
        [overlay addSubview:card];

        UIView *iconBox = [[UIView alloc] init];
        UIColor *accent = isError ? [ZXTheme error] : [ZXTheme success];
        iconBox.backgroundColor = [accent colorWithAlphaComponent:0.10];
        iconBox.layer.cornerRadius = 25;
        iconBox.translatesAutoresizingMaskIntoConstraints = NO;
        [card addSubview:iconBox];

        UIImageView *icon = [[UIImageView alloc]
            initWithImage:[[UIImage systemImageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        icon.tintColor = accent;
        icon.contentMode = UIViewContentModeScaleAspectFit;
        icon.translatesAutoresizingMaskIntoConstraints = NO;
        [iconBox addSubview:icon];

        UILabel *titleLabel = ZXLabel(title.uppercaseString, [ZXTheme heading:16], [ZXTheme primaryText]);
        [ZXTheme track:titleLabel spacing:1.0];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [card addSubview:titleLabel];

        UILabel *messageLabel = ZXLabel(message ?: @"", [ZXTheme body:13 weight:UIFontWeightRegular], [ZXTheme secondaryText]);
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [card addSubview:messageLabel];

        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setTitle:actionTitle ?: @"DISMISS" forState:UIControlStateNormal];
        button.titleLabel.font = [ZXTheme heading:13];
        [button setTitleColor:(isError ? [ZXTheme error] : [ZXTheme primaryText]) forState:UIControlStateNormal];
        button.backgroundColor = isError ? [[ZXTheme error] colorWithAlphaComponent:0.09] : [ZXTheme surfaceInset];
        button.layer.cornerRadius = 11;
        button.layer.borderWidth = 1;
        button.layer.borderColor = (isError ? [ZXTheme error] : [ZXTheme border]).CGColor;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [card addSubview:button];

        [button addTarget:self action:@selector(dismissButton:) forControlEvents:UIControlEventTouchUpInside];

        [NSLayoutConstraint activateConstraints:@[
            [card.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
            [card.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
            [card.leadingAnchor constraintEqualToAnchor:overlay.leadingAnchor constant:34],
            [card.trailingAnchor constraintEqualToAnchor:overlay.trailingAnchor constant:-34],

            [iconBox.topAnchor constraintEqualToAnchor:card.topAnchor constant:24],
            [iconBox.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
            [iconBox.widthAnchor constraintEqualToConstant:50],
            [iconBox.heightAnchor constraintEqualToConstant:50],

            [icon.centerXAnchor constraintEqualToAnchor:iconBox.centerXAnchor],
            [icon.centerYAnchor constraintEqualToAnchor:iconBox.centerYAnchor],
            [icon.widthAnchor constraintEqualToConstant:23],
            [icon.heightAnchor constraintEqualToConstant:23],

            [titleLabel.topAnchor constraintEqualToAnchor:iconBox.bottomAnchor constant:15],
            [titleLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
            [titleLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],

            [messageLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:8],
            [messageLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
            [messageLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],

            [button.topAnchor constraintEqualToAnchor:messageLabel.bottomAnchor constant:22],
            [button.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
            [button.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
            [button.heightAnchor constraintEqualToConstant:44],
            [button.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-24]
        ]];

        objc_setAssociatedObject(button, @selector(dismissButton:), overlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        card.transform = CGAffineTransformMakeScale(0.96, 0.96);
        [UIView animateWithDuration:0.36 delay:0
             usingSpringWithDamping:0.84 initialSpringVelocity:0.3
                           options:UIViewAnimationOptionCurveEaseOut
                        animations:^{
            overlay.alpha = 1;
            card.transform = CGAffineTransformIdentity;
        } completion:nil];
    });
}

+ (void)dismissButton:(UIButton *)button {
    UIView *overlay = objc_getAssociatedObject(button, @selector(dismissButton:));
    [UIView animateWithDuration:0.24 animations:^{
        overlay.alpha = 0;
    } completion:^(BOOL finished) {
        [overlay removeFromSuperview];
    }];
}
@end

#pragma mark - Main Controller

typedef NS_ENUM(NSInteger, ZXAppState) {
    ZXAppStateInit = 0,
    ZXAppStateSplash,
    ZXAppStateAuth,
    ZXAppStateDashboard
};

@interface ZentraxUI ()
@property(nonatomic,assign) ZXAppState currentState;
@property(nonatomic,assign) BOOL hasStarted;
@property(nonatomic,assign) BOOL splashFinished;
@property(nonatomic,assign) BOOL verificationFinished;
@property(nonatomic,assign) BOOL verificationResult;
@property(nonatomic,assign) BOOL verificationPresentationQueued;
@property(nonatomic,assign) BOOL verificationPresented;

@property(nonatomic,strong) ZXAtmosphereView *atmosphereView;
@property(nonatomic,strong) UIView *splashContainer;
@property(nonatomic,strong) UIView *authContainer;
@property(nonatomic,strong) UIView *dashboardContainer;

@property(nonatomic,strong) UIImageView *splashIcon;
@property(nonatomic,strong) UILabel *splashStatus;
@property(nonatomic,strong) UILabel *splashPercent;
@property(nonatomic,strong) UIView *splashRail;
@property(nonatomic,strong) UIView *splashFill;
@property(nonatomic,strong) CAGradientLayer *splashGradient;

@property(nonatomic,strong) ZXPremiumField *keyInput;
@property(nonatomic,strong) ZXPremiumButton *loginBtn;

@property(nonatomic,strong) UILabel *statusLabel;
@property(nonatomic,strong) UILabel *expiryLabel;
@property(nonatomic,strong) UILabel *keyRevealLabel;
@property(nonatomic,strong) UIButton *keyEyeButton;
@property(nonatomic,assign) BOOL isKeyRevealed;

@property(nonatomic,strong) UIScrollView *modulesScroll;
@property(nonatomic,strong) UIStackView *modulesStack;
@property(nonatomic,strong) UIView *emptyState;

@property(nonatomic,strong) NSTimer *heartbeatTimer;
@property(nonatomic,strong) NSArray *cachedModulesState;
@end

@implementation ZentraxUI

- (void)dealloc {
    [_heartbeatTimer invalidate];
    _heartbeatTimer = nil;
    [_atmosphereView stopAtmosphere];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [ZXTheme background];
    self.currentState = ZXAppStateInit;

    _atmosphereView = [[ZXAtmosphereView alloc] initWithFrame:self.view.bounds];
    _atmosphereView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_atmosphereView];

    [self setupSplash];
    [self setupAuth];
    [self setupDashboard];

    _splashContainer.alpha = 1;
    _authContainer.alpha = 0;
    _dashboardContainer.alpha = 0;
    self.currentState = ZXAppStateSplash;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    [self.atmosphereView startAtmosphere];

    if (!self.hasStarted) {
        self.hasStarted = YES;
        [self runStartupSequence];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.atmosphereView stopAtmosphere];
    [self stopHeartbeatMonitor];
}

#pragma mark - Startup

- (void)runStartupSequence {
    self.currentState = ZXAppStateSplash;
    self.splashFinished = NO;
    self.verificationFinished = NO;
    self.verificationResult = NO;
    self.verificationPresentationQueued = NO;
    self.verificationPresented = NO;

    [self.view bringSubviewToFront:self.splashContainer];
    self.splashContainer.alpha = 1;

    self.splashFill.transform = CGAffineTransformMakeScale(0.001, 1);
    self.splashPercent.text = @"0%";
    self.splashStatus.text = @"INITIALIZING";

    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.fromValue = @0.98;
    pulse.toValue = @1.035;
    pulse.duration = 1.2;
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    [self.splashIcon.layer addAnimation:pulse forKey:@"splashPulse"];

    [self animateSplashStep:0.10 text:@"INITIALIZING" percent:@"10%" duration:0.30 completion:^{
        [self animateSplashStep:0.25 text:@"VERIFYING NODE" percent:@"25%" duration:0.35 completion:^{
            [self animateSplashStep:0.40 text:@"AUTHENTICATING" percent:@"40%" duration:0.35 completion:^{
                [self animateSplashStep:0.60 text:@"SYNCHRONIZING" percent:@"60%" duration:0.40 completion:^{
                    [self animateSplashStep:0.80 text:@"SECURING SESSION" percent:@"80%" duration:0.40 completion:^{
                        [self animateSplashStep:0.95 text:@"FINALIZING" percent:@"95%" duration:0.35 completion:^{
                            self.splashFinished = YES;
                            [self evaluateStartup];
                        }];
                    }];
                }];
            }];
        }];
    }];

    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) {
        __weak typeof(self) weakSelf = self;
        [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL valid) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) return;
                self.verificationFinished = YES;
                self.verificationResult = valid;
                [self evaluateStartup];
            });
        }];
    } else {
        self.verificationFinished = YES;
        self.verificationResult = NO;
        [self evaluateStartup];
    }
}

- (void)animateSplashStep:(CGFloat)fraction
                     text:(NSString *)text
                   percent:(NSString *)percent
                  duration:(NSTimeInterval)duration
                completion:(void (^)(void))completion {

    [UIView animateWithDuration:duration delay:0
         options:UIViewAnimationOptionCurveEaseInOut
                      animations:^{
        self.splashFill.transform = CGAffineTransformMakeScale(MAX(fraction, 0.001), 1);
    } completion:^(BOOL finished) {
        CATransition *fade = [CATransition animation];
        fade.type = kCATransitionFade;
        fade.duration = 0.18;
        [self.splashStatus.layer addAnimation:fade forKey:@"statusFade"];
        [self.splashPercent.layer addAnimation:fade forKey:@"percentFade"];
        self.splashStatus.text = text;
        self.splashPercent.text = percent;
        if (completion) completion();
    }];
}

- (void)evaluateStartup {
    if (!self.splashFinished || !self.verificationFinished) return;

    [self animateSplashStep:1.0 text:@"READY" percent:@"100%" duration:0.28 completion:^{
        [self.splashIcon.layer removeAnimationForKey:@"splashPulse"];

        UIView *splash = self.splashContainer;
        [UIView animateWithDuration:0.48 delay:0
             usingSpringWithDamping:0.92 initialSpringVelocity:0.15
                           options:UIViewAnimationOptionCurveEaseInOut
                        animations:^{
            splash.alpha = 0;
            splash.transform = CGAffineTransformMakeScale(1.015, 1.015);
        } completion:^(BOOL finished) {
            splash.hidden = YES;
            splash.transform = CGAffineTransformIdentity;

            if (self.verificationResult) {
                [self populateDashboardKey];
                [self transitionToState:ZXAppStateDashboard completion:^{
                    if (!self.verificationPresented) {
                        self.verificationPresented = YES;
                        [ZXPremiumToast showVerificationInView:self.view];
                    }
                }];
            } else {
                [self transitionToState:ZXAppStateAuth completion:nil];
            }
        }];
    }];
}

#pragma mark - State

- (void)transitionToState:(ZXAppState)newState completion:(void (^)(void))completion {
    if (self.currentState == newState) {
        if (completion) completion();
        return;
    }

    self.currentState = newState;

    if (newState == ZXAppStateDashboard) {
        self.authContainer.userInteractionEnabled = NO;
        self.dashboardContainer.userInteractionEnabled = YES;
        [self startHeartbeatMonitor];
    } else {
        [self stopHeartbeatMonitor];
    }

    self.splashContainer.hidden = (newState != ZXAppStateSplash);

    [UIView animateWithDuration:0.42 delay:0
         options:UIViewAnimationOptionCurveEaseInOut
                      animations:^{
        self.splashContainer.alpha = (newState == ZXAppStateSplash) ? 1 : 0;
        self.authContainer.alpha = (newState == ZXAppStateAuth) ? 1 : 0;
        self.dashboardContainer.alpha = (newState == ZXAppStateDashboard) ? 1 : 0;
    } completion:^(BOOL finished) {
        if (completion) completion();
    }];
}

#pragma mark - Splash

- (void)setupSplash {
    _splashContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    _splashContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _splashContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_splashContainer];

    UIView *iconBox = [[UIView alloc] init];
    iconBox.backgroundColor = [[ZXTheme violet] colorWithAlphaComponent:0.08];
    iconBox.layer.cornerRadius = 34;
    iconBox.layer.borderWidth = 1;
    iconBox.layer.borderColor = [[ZXTheme lavender] colorWithAlphaComponent:0.30].CGColor;
    iconBox.layer.shadowColor = [ZXTheme violet].CGColor;
    iconBox.layer.shadowOpacity = 0.28;
    iconBox.layer.shadowRadius = 24;
    iconBox.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:iconBox];

    _splashIcon = [[UIImageView alloc]
        initWithImage:[[UIImage systemImageNamed:@"shield.lefthalf.filled"]
                       imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    _splashIcon.tintColor = [ZXTheme lavender];
    _splashIcon.contentMode = UIViewContentModeScaleAspectFit;
    _splashIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [iconBox addSubview:_splashIcon];

    UILabel *brand = ZXLabel(@"ZENTRAX", [ZXTheme display:29], [ZXTheme primaryText]);
    [ZXTheme track:brand spacing:4.0];
    brand.translatesAutoresizingMaskIntoConstraints = NO;
    [self.splashContainer addSubview:brand];

    UILabel *sub = ZXLabel(@"SECURE INFRASTRUCTURE NODE", [ZXTheme mono:9 weight:UIFontWeightBold], [ZXTheme secondaryText]);
    [ZXTheme track:sub spacing:1.8];
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    [self.splashContainer addSubview:sub];

    _splashRail = [[UIView alloc] init];
    _splashRail.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.06];
    _splashRail.layer.cornerRadius = 2;
    _splashRail.translatesAutoresizingMaskIntoConstraints = NO;
    [self.splashContainer addSubview:_splashRail];

    _splashFill = [[UIView alloc] init];
    _splashFill.layer.cornerRadius = 2;
    _splashFill.clipsToBounds = YES;
    _splashFill.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashRail addSubview:_splashFill];

    _splashGradient = [ZXTheme gradient];
    [_splashFill.layer addSublayer:_splashGradient];

    _splashStatus = ZXLabel(@"INITIALIZING", [ZXTheme mono:9 weight:UIFontWeightBold], [ZXTheme mutedText]);
    [ZXTheme track:_splashStatus spacing:1.4];
    _splashStatus.translatesAutoresizingMaskIntoConstraints = NO;
    [self.splashContainer addSubview:_splashStatus];

    _splashPercent = ZXLabel(@"0%", [ZXTheme mono:9 weight:UIFontWeightBold], [ZXTheme secondaryText]);
    _splashPercent.textAlignment = NSTextAlignmentRight;
    _splashPercent.translatesAutoresizingMaskIntoConstraints = NO;
    [self.splashContainer addSubview:_splashPercent];

    [NSLayoutConstraint activateConstraints:@[
        [iconBox.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [iconBox.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor constant:-82],
        [iconBox.widthAnchor constraintEqualToConstant:68],
        [iconBox.heightAnchor constraintEqualToConstant:68],

        [_splashIcon.centerXAnchor constraintEqualToAnchor:iconBox.centerXAnchor],
        [_splashIcon.centerYAnchor constraintEqualToAnchor:iconBox.centerYAnchor],
        [_splashIcon.widthAnchor constraintEqualToConstant:30],
        [_splashIcon.heightAnchor constraintEqualToConstant:34],

        [brand.topAnchor constraintEqualToAnchor:iconBox.bottomAnchor constant:22],
        [brand.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],

        [sub.topAnchor constraintEqualToAnchor:brand.bottomAnchor constant:7],
        [sub.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],

        [_splashRail.topAnchor constraintEqualToAnchor:sub.bottomAnchor constant:40],
        [_splashRail.leadingAnchor constraintEqualToAnchor:_splashContainer.leadingAnchor constant:56],
        [_splashRail.trailingAnchor constraintEqualToAnchor:_splashContainer.trailingAnchor constant:-56],
        [_splashRail.heightAnchor constraintEqualToConstant:4],

        [_splashFill.leadingAnchor constraintEqualToAnchor:_splashRail.leadingAnchor],
        [_splashFill.topAnchor constraintEqualToAnchor:_splashRail.topAnchor],
        [_splashFill.bottomAnchor constraintEqualToAnchor:_splashRail.bottomAnchor],
        [_splashFill.widthAnchor constraintEqualToAnchor:_splashRail.widthAnchor],

        [_splashStatus.topAnchor constraintEqualToAnchor:_splashRail.bottomAnchor constant:11],
        [_splashStatus.leadingAnchor constraintEqualToAnchor:_splashRail.leadingAnchor],

        [_splashPercent.topAnchor constraintEqualToAnchor:_splashRail.bottomAnchor constant:11],
        [_splashPercent.trailingAnchor constraintEqualToAnchor:_splashRail.trailingAnchor]
    ]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.splashGradient.frame = self.splashFill.bounds;
}

#pragma mark - Auth

- (void)setupAuth {
    _authContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    _authContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_authContainer];

    UILabel *eyebrow = ZXLabel(@"SECURE ACCESS", [ZXTheme mono:10 weight:UIFontWeightBold], [ZXTheme lavender]);
    [ZXTheme track:eyebrow spacing:2.0];
    eyebrow.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:eyebrow];

    UILabel *title = ZXLabel(@"ZENTRAX", [ZXTheme display:42], [ZXTheme primaryText]);
    [ZXTheme track:title spacing:2.5];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:title];

    UILabel *desc = ZXLabel(@"Authenticate your node to access the protected execution environment.", [ZXTheme body:14 weight:UIFontWeightRegular], [ZXTheme secondaryText]);
    desc.numberOfLines = 0;
    desc.textAlignment = NSTextAlignmentCenter;
    desc.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:desc];

    UIView *card = [[UIView alloc] init];
    [ZXTheme styleCard:card radius:20];
    card.layer.borderColor = [[ZXTheme violet] colorWithAlphaComponent:0.30].CGColor;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:card];

    _keyInput = [[ZXPremiumField alloc] init];
    _keyInput.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:_keyInput];

    _loginBtn = [[ZXPremiumButton alloc] init];
    [_loginBtn setTitle:@"AUTHENTICATE NODE" forState:UIControlStateNormal];
    _loginBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_loginBtn addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:_loginBtn];

    UILabel *security = ZXLabel(@"SESSION ENCRYPTION  â¢  VERIFIED CHANNEL", [ZXTheme mono:8 weight:UIFontWeightBold], [ZXTheme mutedText]);
    [ZXTheme track:security spacing:1.0];
    security.textAlignment = NSTextAlignmentCenter;
    security.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:security];

    [NSLayoutConstraint activateConstraints:@[
        [eyebrow.topAnchor constraintEqualToAnchor:_authContainer.safeAreaLayoutGuide.topAnchor constant:76],
        [eyebrow.centerXAnchor constraintEqualToAnchor:_authContainer.centerXAnchor],

        [title.topAnchor constraintEqualToAnchor:eyebrow.bottomAnchor constant:8],
        [title.centerXAnchor constraintEqualToAnchor:_authContainer.centerXAnchor],

        [desc.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:12],
        [desc.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:42],
        [desc.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-42],

        [card.topAnchor constraintEqualToAnchor:desc.bottomAnchor constant:34],
        [card.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor constant:22],
        [card.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor constant:-22],

        [_keyInput.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
        [_keyInput.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
        [_keyInput.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],
        [_keyInput.heightAnchor constraintEqualToConstant:70],

        [_loginBtn.topAnchor constraintEqualToAnchor:_keyInput.bottomAnchor constant:18],
        [_loginBtn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
        [_loginBtn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],
        [_loginBtn.heightAnchor constraintEqualToConstant:54],

        [security.topAnchor constraintEqualToAnchor:_loginBtn.bottomAnchor constant:15],
        [security.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
        [security.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],
        [security.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18]
    ]];
}

- (void)handleLogin {
    [self.view endEditing:YES];

    NSString *key = [self.keyInput.textField.text
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (!key.length) {
        [ZXModalManager showWithIcon:@"xmark.octagon.fill"
                             isError:YES
                               title:@"INVALID INPUT"
                             message:@"License key cannot be empty."
                         actionTitle:@"DISMISS"
                              inView:self.view];
        return;
    }

    if (!self.loginBtn.userInteractionEnabled) return;

    [self.loginBtn setLoading:YES];

    __weak typeof(self) weakSelf = self;
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestAuthenticationWithKey:completion:)]) {
        [self.delegate zentraxDidRequestAuthenticationWithKey:key completion:^(BOOL success, ZXAuthError errorType, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) return;

                [self.loginBtn setLoading:NO];

                if (success) {
                    [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"Zentrax_LastKey"];
                    [[NSUserDefaults standardUserDefaults] synchronize];

                    [self populateDashboardKey];
                    [self transitionToState:ZXAppStateDashboard completion:^{
                        if (!self.verificationPresented) {
                            self.verificationPresented = YES;
                            [ZXPremiumToast showSuccess:@"NODE ACTIVATED" inView:self.view];
                        }
                    }];
                } else {
                    [ZXModalManager showWithIcon:@"xmark.octagon.fill"
                                         isError:YES
                                           title:@"ACCESS DENIED"
                                         message:errorMsg ?: @"Authentication was rejected by the secure node."
                                     actionTitle:@"DISMISS"
                                          inView:self.view];
                }
            });
        }];
    } else {
        [self.loginBtn setLoading:NO];
    }
}

#pragma mark - Dashboard

- (void)setupDashboard {
    _dashboardContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    _dashboardContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_dashboardContainer];

    UIView *header = [[UIView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:header];

    UIView *brandMark = [[UIView alloc] init];
    brandMark.backgroundColor = [[ZXTheme violet] colorWithAlphaComponent:0.12];
    brandMark.layer.cornerRadius = 16;
    brandMark.layer.borderWidth = 1;
    brandMark.layer.borderColor = [[ZXTheme lavender] colorWithAlphaComponent:0.25].CGColor;
    brandMark.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:brandMark];

    UIImageView *mark = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"shield.lefthalf.filled"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    mark.tintColor = [ZXTheme lavender];
    mark.translatesAutoresizingMaskIntoConstraints = NO;
    [brandMark addSubview:mark];

    UILabel *brand = ZXLabel(@"ZENTRAX", [ZXTheme heading:15], [ZXTheme primaryText]);
    [ZXTheme track:brand spacing:1.8];
    brand.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:brand];

    UILabel *node = ZXLabel(@"SECURE NODE", [ZXTheme mono:8 weight:UIFontWeightBold], [ZXTheme mutedText]);
    [ZXTheme track:node spacing:1.2];
    node.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:node];

    UIButton *logout = [UIButton buttonWithType:UIButtonTypeSystem];
    [logout setImage:[UIImage systemImageNamed:@"power"] forState:UIControlStateNormal];
    logout.tintColor = [ZXTheme secondaryText];
    logout.translatesAutoresizingMaskIntoConstraints = NO;
    [logout addTarget:self action:@selector(handleLogout) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:logout];

    UIView *statusCard = [[UIView alloc] init];
    [ZXTheme styleCard:statusCard radius:20];
    statusCard.layer.borderColor = [[ZXTheme violet] colorWithAlphaComponent:0.34].CGColor;
    statusCard.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:statusCard];

    UILabel *statusCaption = ZXLabel(@"NODE STATUS", [ZXTheme mono:9 weight:UIFontWeightBold], [ZXTheme mutedText]);
    [ZXTheme track:statusCaption spacing:1.5];
    statusCaption.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:statusCaption];

    UIView *statusDot = [[UIView alloc] init];
    statusDot.backgroundColor = [ZXTheme success];
    statusDot.layer.cornerRadius = 4;
    statusDot.layer.shadowColor = [ZXTheme success].CGColor;
    statusDot.layer.shadowRadius = 7;
    statusDot.layer.shadowOpacity = 0.75;
    statusDot.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:statusDot];

    _statusLabel = ZXLabel(@"ACTIVE", [ZXTheme display:18], [ZXTheme success]);
    [ZXTheme track:_statusLabel spacing:1.0];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_statusLabel];

    UILabel *validityCaption = ZXLabel(@"VALIDITY", [ZXTheme mono:9 weight:UIFontWeightBold], [ZXTheme mutedText]);
    [ZXTheme track:validityCaption spacing:1.5];
    validityCaption.textAlignment = NSTextAlignmentRight;
    validityCaption.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:validityCaption];

    _expiryLabel = ZXLabel(@"SYNCING", [ZXTheme heading:13], [ZXTheme primaryText]);
    _expiryLabel.textAlignment = NSTextAlignmentRight;
    _expiryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:_expiryLabel];

    UIView *separator = ZXLine();
    separator.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:separator];

    UIView *keyBox = [[UIView alloc] init];
    keyBox.backgroundColor = [ZXTheme surfaceInset];
    keyBox.layer.cornerRadius = 11;
    keyBox.layer.borderWidth = 1;
    keyBox.layer.borderColor = [[ZXTheme violet] colorWithAlphaComponent:0.16].CGColor;
    keyBox.translatesAutoresizingMaskIntoConstraints = NO;
    [statusCard addSubview:keyBox];

    UIImageView *keyIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"key.fill"]];
    keyIcon.tintColor = [ZXTheme lavender];
    keyIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [keyBox addSubview:keyIcon];

    _keyRevealLabel = ZXLabel(@"â¢â¢â¢â¢â¢â¢â¢â¢â¢â¢â¢â¢", [ZXTheme mono:11 weight:UIFontWeightBold], [ZXTheme primaryText]);
    _keyRevealLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [keyBox addSubview:_keyRevealLabel];

    _keyEyeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_keyEyeButton setImage:[UIImage systemImageNamed:@"eye.slash.fill"] forState:UIControlStateNormal];
    _keyEyeButton.tintColor = [ZXTheme mutedText];
    _keyEyeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_keyEyeButton addTarget:self action:@selector(toggleDashboardKey) forControlEvents:UIControlEventTouchUpInside];
    [keyBox addSubview:_keyEyeButton];

    [self populateDashboardKey];

    _modulesScroll = [[UIScrollView alloc] init];
    _modulesScroll.showsVerticalScrollIndicator = NO;
    _modulesScroll.alwaysBounceVertical = YES;
    _modulesScroll.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:_modulesScroll];

    _modulesStack = [[UIStackView alloc] init];
    _modulesStack.axis = UILayoutConstraintAxisVertical;
    _modulesStack.spacing = 13;
    _modulesStack.alignment = UIStackViewAlignmentFill;
    _modulesStack.translatesAutoresizingMaskIntoConstraints = NO;
    [_modulesScroll addSubview:_modulesStack];

    [self createEmptyStateView];

    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:_dashboardContainer.safeAreaLayoutGuide.topAnchor constant:8],
        [header.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:20],
        [header.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-20],
        [header.heightAnchor constraintEqualToConstant:46],

        [brandMark.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [brandMark.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [brandMark.widthAnchor constraintEqualToConstant:32],
        [brandMark.heightAnchor constraintEqualToConstant:32],

        [mark.centerXAnchor constraintEqualToAnchor:brandMark.centerXAnchor],
        [mark.centerYAnchor constraintEqualToAnchor:brandMark.centerYAnchor],
        [mark.widthAnchor constraintEqualToConstant:17],
        [mark.heightAnchor constraintEqualToConstant:19],

        [brand.leadingAnchor constraintEqualToAnchor:brandMark.trailingAnchor constant:10],
        [brand.topAnchor constraintEqualToAnchor:header.topAnchor constant:6],

        [node.leadingAnchor constraintEqualToAnchor:brand.leadingAnchor],
        [node.topAnchor constraintEqualToAnchor:brand.bottomAnchor constant:2],

        [logout.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],
        [logout.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [logout.widthAnchor constraintEqualToConstant:36],
        [logout.heightAnchor constraintEqualToConstant:36],

        [statusCard.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:13],
        [statusCard.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:20],
        [statusCard.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-20],
        [statusCard.heightAnchor constraintEqualToConstant:151],

        [statusCaption.topAnchor constraintEqualToAnchor:statusCard.topAnchor constant:17],
        [statusCaption.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:17],

        [statusDot.leadingAnchor constraintEqualToAnchor:statusCaption.trailingAnchor constant:8],
        [statusDot.centerYAnchor constraintEqualToAnchor:statusCaption.centerYAnchor],
        [statusDot.widthAnchor constraintEqualToConstant:8],
        [statusDot.heightAnchor constraintEqualToConstant:8],

        [_statusLabel.topAnchor constraintEqualToAnchor:statusCaption.bottomAnchor constant:3],
        [_statusLabel.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:17],

        [validityCaption.topAnchor constraintEqualToAnchor:statusCard.topAnchor constant:17],
        [validityCaption.trailingAnchor constraintEqualToAnchor:statusCard.trailingAnchor constant:-17],

        [_expiryLabel.topAnchor constraintEqualToAnchor:validityCaption.bottomAnchor constant:3],
        [_expiryLabel.trailingAnchor constraintEqualToAnchor:statusCard.trailingAnchor constant:-17],

        [separator.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:17],
        [separator.trailingAnchor constraintEqualToAnchor:statusCard.trailingAnchor constant:-17],
        [separator.topAnchor constraintEqualToAnchor:_statusLabel.bottomAnchor constant:11],
        [separator.heightAnchor constraintEqualToConstant:1],

        [keyBox.leadingAnchor constraintEqualToAnchor:statusCard.leadingAnchor constant:13],
        [keyBox.trailingAnchor constraintEqualToAnchor:statusCard.trailingAnchor constant:-13],
        [keyBox.bottomAnchor constraintEqualToAnchor:statusCard.bottomAnchor constant:-13],
        [keyBox.heightAnchor constraintEqualToConstant:43],

        [keyIcon.leadingAnchor constraintEqualToAnchor:keyBox.leadingAnchor constant:12],
        [keyIcon.centerYAnchor constraintEqualToAnchor:keyBox.centerYAnchor],
        [keyIcon.widthAnchor constraintEqualToConstant:16],
        [keyIcon.heightAnchor constraintEqualToConstant:16],

        [_keyRevealLabel.leadingAnchor constraintEqualToAnchor:keyIcon.trailingAnchor constant:9],
        [_keyRevealLabel.centerYAnchor constraintEqualToAnchor:keyBox.centerYAnchor],
        [_keyRevealLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_keyEyeButton.leadingAnchor constant:-5],

        [_keyEyeButton.trailingAnchor constraintEqualToAnchor:keyBox.trailingAnchor constant:-5],
        [_keyEyeButton.centerYAnchor constraintEqualToAnchor:keyBox.centerYAnchor],
        [_keyEyeButton.widthAnchor constraintEqualToConstant:34],
        [_keyEyeButton.heightAnchor constraintEqualToConstant:34],

        [_modulesScroll.topAnchor constraintEqualToAnchor:statusCard.bottomAnchor constant:15],
        [_modulesScroll.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor],
        [_modulesScroll.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor],
        [_modulesScroll.bottomAnchor constraintEqualToAnchor:_dashboardContainer.bottomAnchor],

        [_modulesStack.topAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.topAnchor constant:5],
        [_modulesStack.leadingAnchor constraintEqualToAnchor:_modulesScroll.frameLayoutGuide.leadingAnchor constant:20],
        [_modulesStack.trailingAnchor constraintEqualToAnchor:_modulesScroll.frameLayoutGuide.trailingAnchor constant:-20],
        [_modulesStack.bottomAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.bottomAnchor constant:-32]
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
    if (!key.length) key = @"NO-KEY-FOUND";

    if (self.isKeyRevealed) {
        self.keyRevealLabel.text = key;
        [self.keyEyeButton setImage:[UIImage systemImageNamed:@"eye.fill"] forState:UIControlStateNormal];
        self.keyEyeButton.tintColor = [ZXTheme cyan];
    } else {
        if (key.length > 4) {
            self.keyRevealLabel.text = [NSString stringWithFormat:@"â¢â¢â¢â¢â¢â¢â¢â¢%@", [key substringFromIndex:key.length - 4]];
        } else {
            self.keyRevealLabel.text = @"â¢â¢â¢â¢â¢â¢â¢â¢â¢â¢â¢â¢";
        }
        [self.keyEyeButton setImage:[UIImage systemImageNamed:@"eye.slash.fill"] forState:UIControlStateNormal];
        self.keyEyeButton.tintColor = [ZXTheme mutedText];
    }
}

#pragma mark - Empty State / Modules

- (void)createEmptyStateView {
    _emptyState = [[UIView alloc] init];
    _emptyState.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *iconBox = [[UIView alloc] init];
    iconBox.backgroundColor = [[ZXTheme violet] colorWithAlphaComponent:0.08];
    iconBox.layer.cornerRadius = 22;
    iconBox.layer.borderWidth = 1;
    iconBox.layer.borderColor = [[ZXTheme violet] colorWithAlphaComponent:0.20].CGColor;
    iconBox.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyState addSubview:iconBox];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"cube.transparent"]];
    icon.tintColor = [ZXTheme lavender];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [iconBox addSubview:icon];

    UILabel *title = ZXLabel(@"NO ACTIVE MODULES", [ZXTheme heading:14], [ZXTheme secondaryText]);
    [ZXTheme track:title spacing:1.2];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyState addSubview:title];

    UILabel *detail = ZXLabel(@"Protected execution modules will appear here.", [ZXTheme body:11 weight:UIFontWeightRegular], [ZXTheme mutedText]);
    detail.textAlignment = NSTextAlignmentCenter;
    detail.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyState addSubview:detail];

    [NSLayoutConstraint activateConstraints:@[
        [_emptyState.heightAnchor constraintEqualToConstant:165],
        [iconBox.topAnchor constraintEqualToAnchor:_emptyState.topAnchor constant:20],
        [iconBox.centerXAnchor constraintEqualToAnchor:_emptyState.centerXAnchor],
        [iconBox.widthAnchor constraintEqualToConstant:44],
        [iconBox.heightAnchor constraintEqualToConstant:44],
        [icon.centerXAnchor constraintEqualToAnchor:iconBox.centerXAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:iconBox.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:20],
        [icon.heightAnchor constraintEqualToConstant:20],
        [title.topAnchor constraintEqualToAnchor:iconBox.bottomAnchor constant:14],
        [title.centerXAnchor constraintEqualToAnchor:_emptyState.centerXAnchor],
        [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:6],
        [detail.leadingAnchor constraintEqualToAnchor:_emptyState.leadingAnchor constant:20],
        [detail.trailingAnchor constraintEqualToAnchor:_emptyState.trailingAnchor constant:-20]
    ]];
}

- (BOOL)isModuleDataIdentical:(NSArray *)newModules {
    if (!self.cachedModulesState || newModules.count != self.cachedModulesState.count) return NO;
    for (NSUInteger i = 0; i < newModules.count; i++) {
        if (![newModules[i] isEqual:self.cachedModulesState[i]]) return NO;
    }
    return YES;
}

- (void)updateDashboardWithModules:(NSArray<NSDictionary *> *)modules {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isModuleDataIdentical:modules]) return;

        self.cachedModulesState = [modules copy];

        for (UIView *view in [self.modulesStack.arrangedSubviews copy]) {
            [self.modulesStack removeArrangedSubview:view];
            [view removeFromSuperview];
        }

        if (!modules.count) {
            [self.modulesStack addArrangedSubview:self.emptyState];
            self.emptyState.alpha = 0;
            [UIView animateWithDuration:0.35 animations:^{
                self.emptyState.alpha = 1;
            }];
            return;
        }

        UILabel *header = ZXLabel(@"PROTECTED MODULES", [ZXTheme mono:10 weight:UIFontWeightBold], [ZXTheme mutedText]);
        [ZXTheme track:header spacing:1.5];
        [self.modulesStack addArrangedSubview:header];
        [self.modulesStack setCustomSpacing:3 afterView:header];

        for (NSUInteger index = 0; index < modules.count; index++) {
            NSDictionary *mod = modules[index];
            NSString *name = mod[@"name"] ?: @"UNKNOWN MODULE";
            NSString *desc = mod[@"desc"] ?: mod[@"description"] ?: @"";
            NSString *state = mod[@"current_state"] ?: @"OFF";
            BOOL on = [state.uppercaseString isEqualToString:@"ON"];

            UIView *card = [[UIView alloc] init];
            [ZXTheme styleCard:card radius:16];
            card.layer.borderColor = [[ZXTheme violet] colorWithAlphaComponent:0.24].CGColor;
            card.translatesAutoresizingMaskIntoConstraints = NO;

            UIView *accent = [[UIView alloc] init];
            accent.backgroundColor = on ? [ZXTheme success] : [[ZXTheme violet] colorWithAlphaComponent:0.35];
            accent.layer.cornerRadius = 2;
            accent.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:accent];

            UILabel *title = ZXLabel(name, [ZXTheme heading:14], [ZXTheme primaryText]);
            title.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:title];

            UILabel *stateLabel = ZXLabel(on ? @"ONLINE" : @"STANDBY",
                                          [ZXTheme mono:8 weight:UIFontWeightBold],
                                          on ? [ZXTheme success] : [ZXTheme mutedText]);
            [ZXTheme track:stateLabel spacing:1.1];
            stateLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:stateLabel];

            ZXPremiumToggle *toggle = [[ZXPremiumToggle alloc] init];
            toggle.moduleId = name;
            [toggle setOn:on animated:NO];
            [toggle addTarget:self action:@selector(moduleToggled:) forControlEvents:UIControlEventValueChanged];
            [card addSubview:toggle];

            UIView *descBox = [[UIView alloc] init];
            descBox.backgroundColor = [ZXTheme surfaceInset];
            descBox.layer.cornerRadius = 9;
            descBox.layer.borderWidth = 1;
            descBox.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.035].CGColor;
            descBox.translatesAutoresizingMaskIntoConstraints = NO;
            [card addSubview:descBox];

            UILabel *descLabel = ZXLabel(desc, [ZXTheme body:11 weight:UIFontWeightRegular], [ZXTheme secondaryText]);
            descLabel.numberOfLines = 0;
            descLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [descBox addSubview:descLabel];

            [NSLayoutConstraint activateConstraints:@[
                [card.heightAnchor constraintGreaterThanOrEqualToConstant:105],

                [accent.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
                [accent.topAnchor constraintEqualToAnchor:card.topAnchor],
                [accent.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],
                [accent.widthAnchor constraintEqualToConstant:3],

                [title.topAnchor constraintEqualToAnchor:card.topAnchor constant:15],
                [title.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:15],
                [title.trailingAnchor constraintLessThanOrEqualToAnchor:toggle.leadingAnchor constant:-8],

                [stateLabel.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:3],
                [stateLabel.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],

                [toggle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-15],
                [toggle.topAnchor constraintEqualToAnchor:card.topAnchor constant:15],

                [descBox.topAnchor constraintEqualToAnchor:stateLabel.bottomAnchor constant:11],
                [descBox.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:15],
                [descBox.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-15],
                [descBox.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14],

                [descLabel.topAnchor constraintEqualToAnchor:descBox.topAnchor constant:9],
                [descLabel.leadingAnchor constraintEqualToAnchor:descBox.leadingAnchor constant:10],
                [descLabel.trailingAnchor constraintEqualToAnchor:descBox.trailingAnchor constant:-10],
                [descLabel.bottomAnchor constraintEqualToAnchor:descBox.bottomAnchor constant:-9]
            ]];

            [self.modulesStack addArrangedSubview:card];

            card.alpha = 0;
            card.transform = CGAffineTransformMakeTranslation(0, 10);
            [UIView animateWithDuration:0.38
                                  delay:MIN(index * 0.045, 0.25)
                 usingSpringWithDamping:0.86
                  initialSpringVelocity:0.2
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                card.alpha = 1;
                card.transform = CGAffineTransformIdentity;
            } completion:nil];
        }
    });
}

- (void)updateSubscriptionState:(NSDictionary *)subData {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *expiry = subData[@"expiry"];
        self.expiryLabel.text = expiry.length ? expiry.uppercaseString : @"--";

        NSString *status = subData[@"status"] ?: @"Active";
        self.statusLabel.text = status.uppercaseString;
        BOOL active = [status.lowercaseString isEqualToString:@"active"];
        self.statusLabel.textColor = active ? [ZXTheme success] : [ZXTheme warning];
    });
}

- (ZXPremiumToggle *)findToggleInCard:(UIView *)card {
    for (UIView *subview in card.subviews) {
        if ([subview isKindOfClass:[ZXPremiumToggle class]]) return (ZXPremiumToggle *)subview;
    }
    return nil;
}

- (void)moduleToggled:(ZXPremiumToggle *)sender {
    NSString *moduleId = sender.moduleId;
    if (!moduleId.length) return;

    BOOL requestedState = sender.isOn;
    [sender setLoading:YES];

    __weak typeof(self) weakSelf = self;
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestModuleToggle:state:completion:)]) {
        [self.delegate zentraxDidRequestModuleToggle:moduleId state:requestedState completion:^(BOOL success, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) return;

                [sender setLoading:NO];

                if (success) {
                    self.cachedModulesState = nil;
                    [ZXPremiumToast showSuccess:(requestedState ? @"MODULE ACTIVATED" : @"MODULE DEACTIVATED")
                                         inView:self.view];
                } else {
                    [sender setOn:!requestedState animated:YES];
                    [ZXModalManager showWithIcon:@"xmark.octagon.fill"
                                         isError:YES
                                           title:@"OPERATION FAILED"
                                         message:errorMsg ?: @"The module state could not be updated."
                                     actionTitle:@"DISMISS"
                                          inView:self.view];
                }
            });
        }];
    } else {
        [sender setLoading:NO];
    }
}

#pragma mark - Heartbeat

- (void)startHeartbeatMonitor {
    [self stopHeartbeatMonitor];
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:15.0
                                                           target:self
                                                         selector:@selector(heartbeatTick)
                                                         userInfo:nil
                                                          repeats:YES];
}

- (void)stopHeartbeatMonitor {
    [self.heartbeatTimer invalidate];
    self.heartbeatTimer = nil;
}

- (void)heartbeatTick {
    if (self.currentState != ZXAppStateDashboard) return;

    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) {
        __weak typeof(self) weakSelf = self;
        [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL valid) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self || valid) return;

                Class managerClass = NSClassFromString(@"ZentraxNetworkManager");
                BOOL activeSession = YES;

                if (managerClass && [managerClass respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
                    id manager = ((id (*)(id, SEL))objc_msgSend)((id)managerClass, NSSelectorFromString(@"sharedManager"));
                    SEL selector = NSSelectorFromString(@"hasActiveSession");
                    if (manager && [manager respondsToSelector:selector]) {
                        activeSession = ((BOOL (*)(id, SEL))objc_msgSend)(manager, selector);
                    }
                }

                if (!activeSession) [self handleRevokedSessionEnvironment];
            });
        }];
    }
}

- (void)handleRevokedSessionEnvironment {
    [self stopHeartbeatMonitor];

    for (UIView *card in self.modulesStack.arrangedSubviews) {
        ZXPremiumToggle *toggle = [self findToggleInCard:card];
        if (toggle) {
            toggle.userInteractionEnabled = NO;
            [toggle setOn:NO animated:YES];
        }
    }

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Zentrax_LastKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [ZXModalManager showWithIcon:@"xmark.octagon.fill"
                         isError:YES
                           title:@"ACCESS REVOKED"
                         message:@"Your license has been disabled or has expired."
                     actionTitle:@"DISMISS"
                          inView:self.view];

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;

        if ([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) {
            [self.delegate zentraxDidRequestLogoutWithCompletion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.keyInput.textField.text = @"";
                    [self transitionToState:ZXAppStateAuth completion:nil];
                });
            }];
        } else {
            self.keyInput.textField.text = @"";
            [self transitionToState:ZXAppStateAuth completion:nil];
        }
    });
}

#pragma mark - Logout / Public UI

- (void)handleLogout {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Disconnect Node?"
                                            message:@"Your secure session will be closed."
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Disconnect"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;

        if ([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) {
            [self.delegate zentraxDidRequestLogoutWithCompletion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.keyInput.textField.text = @"";
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Zentrax_LastKey"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    [self transitionToState:ZXAppStateAuth completion:nil];
                });
            }];
        } else {
            self.keyInput.textField.text = @"";
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Zentrax_LastKey"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self transitionToState:ZXAppStateAuth completion:nil];
        }
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    if (self.currentState != ZXAppStateAuth) return;

    CGRect keyboard = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    CGRect buttonRect = [self.loginBtn.superview convertRect:self.loginBtn.frame toView:self.view];
    CGFloat overlap = CGRectGetMaxY(buttonRect) - keyboard.origin.y;

    if (overlap > 0) {
        [UIView animateWithDuration:duration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            self.authContainer.transform = CGAffineTransformMakeTranslation(0, -(overlap + 14));
        } completion:nil];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.authContainer.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)showGlobalErrorWithTitle:(NSString *)title message:(NSString *)msg {
    [ZXModalManager showWithIcon:@"exclamationmark.triangle.fill"
                         isError:YES
                           title:title
                         message:msg
                     actionTitle:@"DISMISS"
                          inView:self.view];
}

- (void)showSuccessMessage:(NSString *)title message:(NSString *)msg {
    [ZXModalManager showWithIcon:@"checkmark.shield.fill"
                         isError:NO
                           title:title
                         message:msg
                     actionTitle:@"CONTINUE"
                          inView:self.view];
}

- (void)showNetworkError {
    [ZXModalManager showWithIcon:@"wifi.slash"
                         isError:YES
                           title:@"CONNECTION ERROR"
                         message:@"Network connection lost."
                     actionTitle:@"DISMISS"
                          inView:self.view];
}

- (void)showServerError {
    [ZXModalManager showWithIcon:@"server.rack"
                         isError:YES
                           title:@"SERVER ERROR"
                         message:@"Node server is unavailable."
                     actionTitle:@"DISMISS"
                          inView:self.view];
}

- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds {
    NSString *message = [NSString stringWithFormat:@"Request limit reached. Cooldown active for %ld seconds.", (long)seconds];
    [ZXModalManager showWithIcon:@"timer"
                         isError:YES
                           title:@"RATE LIMITED"
                         message:message
                     actionTitle:@"UNDERSTOOD"
                          inView:self.view];
}

- (void)showGlobalLoadingState:(NSString *)message {
    // Intentionally kept as a public no-op for compatibility with the existing interface.
}

- (void)hideGlobalLoadingState {
    // Intentionally kept as a public no-op for compatibility with the existing interface.
}

@end
