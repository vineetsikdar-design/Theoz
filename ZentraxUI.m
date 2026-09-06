//
//  ZentraxUI.m
//  Zentrax VIP - Premium Security Infrastructure UI
//
//  Drop-in visual/flow redesign.
//  Existing delegate callbacks and public interface are preserved.
//

#import "ZentraxUI.h"
#import "ZentraxNetworkManager.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <Security/Security.h>

#pragma mark - Safe UI Helpers

static UILabel *ZXLabel(NSString *text, UIFont *font, UIColor *color) {
    UILabel *label = [[UILabel alloc] init];
    label.text = text ?: @"";
    label.font = font ?: [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    label.textColor = color ?: [UIColor whiteColor];
    label.numberOfLines = 1;
    label.userInteractionEnabled = NO;
    return label;
}

#pragma mark - Theme

@interface ZXTheme : NSObject
+ (UIColor *)background; + (UIColor *)surface; + (UIColor *)surfaceRaised; + (UIColor *)surfaceInset; + (UIColor *)border; + (UIColor *)borderStrong; + (UIColor *)violet; + (UIColor *)indigo; + (UIColor *)cyan; + (UIColor *)lavender; + (UIColor *)primaryText; + (UIColor *)secondaryText; + (UIColor *)mutedText; + (UIColor *)success; + (UIColor *)warning; + (UIColor *)error; + (UIFont *)display:(CGFloat)size; + (UIFont *)heading:(CGFloat)size; + (UIFont *)body:(CGFloat)size weight:(UIFontWeight)weight; + (UIFont *)mono:(CGFloat)size weight:(UIFontWeight)weight; + (void)track:(UILabel *)label spacing:(CGFloat)spacing; + (void)styleCard:(UIView *)view radius:(CGFloat)radius;
@end
@implementation ZXTheme
+ (UIColor *)background { return [UIColor blackColor]; }
+ (UIColor *)surface { return [UIColor colorWithWhite:0.055 alpha:1.0]; }
+ (UIColor *)surfaceRaised { return [UIColor colorWithWhite:0.105 alpha:1.0]; }
+ (UIColor *)surfaceInset { return [UIColor colorWithWhite:0.018 alpha:1.0]; }
+ (UIColor *)border { return [UIColor colorWithWhite:0.20 alpha:0.90]; }
+ (UIColor *)borderStrong { return [UIColor colorWithWhite:0.78 alpha:0.95]; }
+ (UIColor *)violet { return [UIColor colorWithWhite:0.94 alpha:1]; }
+ (UIColor *)indigo { return [UIColor colorWithWhite:0.16 alpha:1]; }
+ (UIColor *)cyan { return [UIColor colorWithWhite:0.82 alpha:1]; }
+ (UIColor *)lavender { return [UIColor colorWithWhite:0.72 alpha:1]; }
+ (UIColor *)primaryText { return [UIColor colorWithWhite:0.985 alpha:1]; }
+ (UIColor *)secondaryText { return [UIColor colorWithWhite:0.67 alpha:1]; }
+ (UIColor *)mutedText { return [UIColor colorWithWhite:0.40 alpha:1]; }
+ (UIColor *)success { return [UIColor colorWithRed:0.26 green:0.88 blue:0.50 alpha:1]; }
+ (UIColor *)warning { return [UIColor colorWithRed:1 green:0.68 blue:0.22 alpha:1]; }
+ (UIColor *)error { return [UIColor colorWithRed:1 green:0.27 blue:0.34 alpha:1]; }
+ (UIFont *)display:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightBlack]; }
+ (UIFont *)heading:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightSemibold]; }
+ (UIFont *)body:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont systemFontOfSize:size weight:weight]; }
+ (UIFont *)mono:(CGFloat)size weight:(UIFontWeight)weight { return [UIFont monospacedSystemFontOfSize:size weight:weight]; }
+ (void)track:(UILabel *)label spacing:(CGFloat)spacing { if (!label.text.length) return; label.attributedText=[[NSAttributedString alloc] initWithString:label.text attributes:@{NSKernAttributeName:@(spacing)}]; }
+ (void)styleCard:(UIView *)view radius:(CGFloat)radius { view.backgroundColor=[self surface]; view.layer.cornerRadius=radius; view.layer.borderWidth=1; view.layer.borderColor=[self border].CGColor; view.layer.shadowColor=[UIColor blackColor].CGColor; view.layer.shadowOpacity=0.32; view.layer.shadowRadius=18; view.layer.shadowOffset=CGSizeMake(0,8); }
@end

#pragma mark - Ambient Background

@interface ZXAtmosphereView : UIView
- (void)startAtmosphere;
- (void)stopAtmosphere;
@end

@implementation ZXAtmosphereView
- (instancetype)initWithFrame:(CGRect)frame {
    self=[super initWithFrame:frame];
    if (!self) return nil;
    self.backgroundColor=[UIColor blackColor];
    self.opaque=YES;
    self.clipsToBounds=YES;
    self.userInteractionEnabled=NO;
    return self;
}
- (void)layoutSubviews { [super layoutSubviews]; }
- (void)startAtmosphere { /* Pure black static background by design. */ }
- (void)stopAtmosphere { /* No background animation. */ }
@end

#pragma mark - Premium Button

@interface ZXPremiumButton : UIButton
@property(nonatomic,strong) UIView *buttonSurface;
@property(nonatomic,strong) UIActivityIndicatorView *spinner;
@property(nonatomic,strong) NSString *savedTitle;
- (void)setLoading:(BOOL)loading;
@end

@implementation ZXPremiumButton
- (instancetype)init {
    self=[super initWithFrame:CGRectZero];
    if (!self) return nil;
    self.backgroundColor=[UIColor colorWithWhite:0.95 alpha:1.0];
    self.layer.cornerRadius=16.0;
    self.layer.borderWidth=1.0;
    self.layer.borderColor=[UIColor colorWithWhite:1.0 alpha:0.20].CGColor;
    self.clipsToBounds=NO;
    self.titleLabel.font=[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor colorWithWhite:0.25 alpha:1] forState:UIControlStateHighlighted];
    self.accessibilityTraits=UIAccessibilityTraitButton;

    _buttonSurface=[[UIView alloc] init];
    _buttonSurface.userInteractionEnabled=NO;
    _buttonSurface.backgroundColor=[UIColor colorWithWhite:0.95 alpha:1.0];
    _buttonSurface.layer.cornerRadius=16.0;
    _buttonSurface.clipsToBounds=YES;
    _buttonSurface.translatesAutoresizingMaskIntoConstraints=NO;
    [self addSubview:_buttonSurface];

    self.layer.shadowColor=[UIColor blackColor].CGColor;
    self.layer.shadowOpacity=0.28;
    self.layer.shadowRadius=14.0;
    self.layer.shadowOffset=CGSizeMake(0,7);

    _spinner=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    _spinner.color=[UIColor blackColor];
    _spinner.hidesWhenStopped=YES;
    _spinner.translatesAutoresizingMaskIntoConstraints=NO;
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
    [self addTarget:self action:@selector(zxTouchUp) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    return self;
}
- (void)layoutSubviews { [super layoutSubviews]; [self bringSubviewToFront:self.titleLabel]; [self bringSubviewToFront:self.spinner]; }
- (void)zxTouchDown {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction animations:^{ self.transform=CGAffineTransformMakeScale(0.982,0.982); self.layer.shadowOpacity=0.16; } completion:nil];
}
- (void)zxTouchUp {
    [UIView animateWithDuration:0.28 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0.25 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction animations:^{ self.transform=CGAffineTransformIdentity; self.layer.shadowOpacity=0.28; } completion:nil];
}
- (void)setLoading:(BOOL)loading {
    self.userInteractionEnabled=!loading;
    if (loading) {
        self.savedTitle=[self titleForState:UIControlStateNormal];
        [self setTitle:@"" forState:UIControlStateNormal];
        [_spinner startAnimating];
        self.alpha=0.72;
    } else {
        [self setTitle:self.savedTitle ?: @"" forState:UIControlStateNormal];
        [_spinner stopAnimating];
        self.alpha=1.0;
        self.transform=CGAffineTransformIdentity;
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

    _caption = ZXLabel(@"AUTHENTICATION KEY", [ZXTheme mono:9 weight:UIFontWeightBold], [ZXTheme lavender]);
    [ZXTheme track:_caption spacing:1.2];
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
- (void)updateStateAnimated:(BOOL)animated;
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

    [self updateStateAnimated:animated];
}

- (void)updateStateAnimated:(BOOL)animated {
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
    ZXAppStateDashboard,
    ZXAppStateStartupBlock
};

static NSString * const ZXSafeModeEnabledKey = @"Zentrax.SafeMode.Enabled";
static NSString * const ZXSafeModeNameKey = @"Zentrax.SafeMode.DisplayName";
static NSString * const ZXSafeModeLogoKey = @"Zentrax.SafeMode.LogoAsset";
static NSString * const ZXSafeModePasscodeService = @"in.zentrax.safemode";
static NSString * const ZXSafeModePasscodeAccount = @"passcode";
static NSString * const ZXLanguageKey = @"Zentrax.Language";
static NSString * const ZXThemeKey = @"Zentrax.Theme";
static NSString * const ZXLastKey = @"Zentrax_LastKey";
static NSInteger const ZXMaxPINAttempts = 5;

@interface ZentraxUI ()
@property(nonatomic,assign) ZXAppState currentState;
@property(nonatomic,assign) ZXStartupState startupState;
@property(nonatomic,assign) BOOL hasStarted;
@property(nonatomic,assign) BOOL isTransitioning;
@property(nonatomic,assign) BOOL safeModeEnabled;
@property(nonatomic,assign) ZXSafeModeState safeModeState;
@property(nonatomic,assign) BOOL privacyCaptureActive;
@property(nonatomic,assign) BOOL privacyOverlayPresented;
@property(nonatomic,assign) BOOL keyRevealed;
@property(nonatomic,assign) BOOL settingsVisible;
@property(nonatomic,assign) BOOL licensePermanent;
@property(nonatomic,assign) ZXLicenseUIStatus licenseStatus;
@property(nonatomic,strong) NSDate *serverDate;
@property(nonatomic,strong) NSDate *activatedAt;
@property(nonatomic,strong) NSDate *expiresAt;
@property(nonatomic,strong) NSTimer *licenseTimer;
@property(nonatomic,strong) NSTimer *heartbeatTimer;
@property(nonatomic,strong) NSTimer *rateLimitTimer;
@property(nonatomic,assign) NSInteger rateLimitSeconds;
@property(nonatomic,copy) NSString *serverBannerMessage;
@property(nonatomic,copy) NSString *serverBannerTitle;
@property(nonatomic,strong) NSDictionary *compatibilityData;
@property(nonatomic,strong) NSDictionary *dashboardConfiguration;
@property(nonatomic,strong) NSMutableDictionary<NSString *, NSNumber *> *functionStates;
@property(nonatomic,strong) NSMutableDictionary<NSString *, UIView *> *functionCards;
@property(nonatomic,strong) NSMutableDictionary<NSString *, UIControl *> *functionControls;
@property(nonatomic,strong) NSMutableDictionary<NSString *, NSDictionary *> *functionDefinitions;
@property(nonatomic,strong) NSMutableDictionary<NSString *, UILabel *> *functionStateLabels;

@property(nonatomic,strong) ZXAtmosphereView *atmosphereView;
@property(nonatomic,strong) UIView *splashContainer;
@property(nonatomic,strong) UIView *authContainer;
@property(nonatomic,strong) UIView *dashboardContainer;
@property(nonatomic,strong) UIView *settingsContainer;
@property(nonatomic,strong) UIView *startupBlockContainer;
@property(nonatomic,strong) UIView *safeLockContainer;
@property(nonatomic,strong) UIView *privacyOverlay;
@property(nonatomic,strong) UIView *globalLoadingOverlay;
@property(nonatomic,strong) UIView *toastView;
@property(nonatomic,strong) UIView *languageOverlay;

@property(nonatomic,strong) UIImageView *splashIcon;
@property(nonatomic,strong) UILabel *splashStatus;
@property(nonatomic,strong) UILabel *splashPercent;
@property(nonatomic,strong) UIView *splashFill;
@property(nonatomic,strong) UILabel *splashDetail;

@property(nonatomic,strong) UILabel *authEyebrow;
@property(nonatomic,strong) UILabel *authTitle;
@property(nonatomic,strong) UILabel *authSubtitle;
@property(nonatomic,strong) ZXPremiumField *keyInput;
@property(nonatomic,strong) ZXPremiumButton *loginBtn;
@property(nonatomic,strong) UISwitch *rememberSwitch;
@property(nonatomic,strong) UILabel *authStatus;

@property(nonatomic,strong) UILabel *licenseStatusLabel;
@property(nonatomic,strong) UILabel *expiryLabel;
@property(nonatomic,strong) UILabel *countdownLabel;
@property(nonatomic,strong) UILabel *keyRevealLabel;
@property(nonatomic,strong) UIButton *keyEyeButton;
@property(nonatomic,strong) UILabel *connectionLabel;
@property(nonatomic,strong) UIStackView *modulesStack;
@property(nonatomic,strong) UIScrollView *modulesScroll;
@property(nonatomic,strong) UIView *emptyState;
@property(nonatomic,strong) UIView *serverBannerView;
@property(nonatomic,strong) UIView *licenseCard;
@property(nonatomic,strong) UILabel *dashboardTitle;
@property(nonatomic,strong) UIButton *settingsButton;

@property(nonatomic,strong) UIScrollView *settingsScroll;
@property(nonatomic,strong) UIStackView *settingsStack;
@property(nonatomic,strong) UILabel *settingsTitle;
@property(nonatomic,strong) UIView *compatibilityCard;
@property(nonatomic,strong) UIView *safeModeCard;

@property(nonatomic,strong) UILabel *startupBlockTitle;
@property(nonatomic,strong) UILabel *startupBlockMessage;
@property(nonatomic,strong) UIButton *startupBlockAction;
@property(nonatomic,assign) ZXStartupState blockedState;

@property(nonatomic,strong) UILabel *safeLockTitle;
@property(nonatomic,strong) UILabel *safeLockSubtitle;
@property(nonatomic,strong) UIStackView *pinBoxes;
@property(nonatomic,strong) NSMutableString *enteredPIN;
@property(nonatomic,strong) UIView *keypadView;
@property(nonatomic,strong) UILabel *safeModeFooter;
@property(nonatomic,strong) UIButton *safeLockBackButton;
@property(nonatomic,strong) UILabel *safePinError;
@property(nonatomic,assign) BOOL safeModeCreatingPasscode;
@property(nonatomic,assign) BOOL safeModeDisabling;
@property(nonatomic,copy) NSString *pendingSafeModePasscode;
@property(nonatomic,assign) NSInteger safeModeAttemptsRemaining;

@property(nonatomic,strong) UIActivityIndicatorView *globalSpinner;
@property(nonatomic,strong) UILabel *globalLoadingTitle;
@property(nonatomic,strong) UILabel *globalLoadingDetail;
@end

@implementation ZentraxUI

- (void)startZentraxUI {
    if (self.safeModeEnabled) {
        [self updateSafeModeState:ZXSafeModeStateLocked];
        [self showSafeModeLockScreen];
        return;
    }
    [self beginBootstrap];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Lifecycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _functionStates = [NSMutableDictionary dictionary];
        _functionCards = [NSMutableDictionary dictionary];
        _functionControls = [NSMutableDictionary dictionary];
        _functionDefinitions = [NSMutableDictionary dictionary];
        _functionStateLabels = [NSMutableDictionary dictionary];
        _enteredPIN = [NSMutableString string];
        _safeModeAttemptsRemaining = ZXMaxPINAttempts;
        _licenseStatus = ZXLicenseUIStatusUnknown;
        _startupState = ZXStartupStateUnknown;
    }
    return self;
}

- (void)dealloc {
    [_licenseTimer invalidate];
    [_heartbeatTimer invalidate];
    [_rateLimitTimer invalidate];
    [_atmosphereView stopAtmosphere];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.view.tintColor = [ZXTheme primaryText];
    self.view.opaque = YES;
    self.currentState = ZXAppStateInit;

    _atmosphereView = [[ZXAtmosphereView alloc] initWithFrame:self.view.bounds];
    _atmosphereView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_atmosphereView];

    [self setupSplash];
    [self setupAuth];
    [self setupDashboard];
    [self setupSettingsScreen];
    [self setupStartupBlock];
    [self setupSafeModeLock];
    [self setupGlobalLoading];

    [self registerPrivacyObservers];
    [self applyInitialSafeModeState];
    [self setAllPrimaryContainersHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.atmosphereView startAtmosphere];
    if (!self.hasStarted) {
        self.hasStarted = YES;
        [self startZentraxUI];
    }
    [self updatePrivacyCaptureState];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.atmosphereView.frame = self.view.bounds;
    self.privacyOverlay.frame = self.view.bounds;
    self.globalLoadingOverlay.frame = self.view.bounds;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopLicenseCountdown];
    [self stopHeartbeatMonitor];
}

#pragma mark - Setup: Common

- (void)setAllPrimaryContainersHidden:(BOOL)hidden {
    self.splashContainer.hidden = hidden;
    self.authContainer.hidden = hidden;
    self.dashboardContainer.hidden = hidden;
    self.settingsContainer.hidden = hidden;
    self.startupBlockContainer.hidden = hidden;
    self.safeLockContainer.hidden = hidden;
}

- (void)transitionToPrimaryContainer:(UIView *)target {
    if (!target) return;
    NSArray *containers=@[self.splashContainer ?: [UIView new],self.authContainer ?: [UIView new],self.dashboardContainer ?: [UIView new],self.settingsContainer ?: [UIView new],self.startupBlockContainer ?: [UIView new],self.safeLockContainer ?: [UIView new]];
    for (UIView *container in containers) if (container!=target) { container.hidden=YES; container.alpha=1.0; container.transform=CGAffineTransformIdentity; }
    target.hidden=NO;
    target.alpha=0.0;
    target.transform=CGAffineTransformMakeTranslation(0,7.0);
    [UIView animateWithDuration:0.24 delay:0 usingSpringWithDamping:0.94 initialSpringVelocity:0.15 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction animations:^{ target.alpha=1.0; target.transform=CGAffineTransformIdentity; } completion:nil];
}

- (UIView *)card {
    UIView *v = [[UIView alloc] init];
    [ZXTheme styleCard:v radius:22.0];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    return v;
}

- (UILabel *)label:(NSString *)text size:(CGFloat)size weight:(UIFontWeight)weight color:(UIColor *)color {
    UILabel *l = [[UILabel alloc] init];
    l.text = text;
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
    b.accessibilityLabel = symbol;
    b.translatesAutoresizingMaskIntoConstraints = NO;
    [b.widthAnchor constraintEqualToConstant:size].active = YES;
    [b.heightAnchor constraintEqualToConstant:size].active = YES;
    return b;
}

- (void)styleSecondaryButton:(UIButton *)button {
    button.backgroundColor=[UIColor colorWithWhite:0.95 alpha:1.0];
    button.layer.cornerRadius=14.0;
    button.layer.borderWidth=1.0;
    button.layer.borderColor=[UIColor colorWithWhite:1.0 alpha:0.18].CGColor;
    button.layer.shadowColor=[UIColor blackColor].CGColor;
    button.layer.shadowOpacity=0.20;
    button.layer.shadowRadius=10.0;
    button.layer.shadowOffset=CGSizeMake(0,5);
    button.titleLabel.font=[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithWhite:0.25 alpha:1] forState:UIControlStateHighlighted];
    if (@available(iOS 15.0,*)) {
        UIButtonConfiguration *configuration=[UIButtonConfiguration plainButtonConfiguration];
        configuration.contentInsets=NSDirectionalEdgeInsetsMake(10,16,10,16);
        configuration.baseForegroundColor=[UIColor blackColor];
        configuration.background.backgroundColor=[UIColor colorWithWhite:0.95 alpha:1.0];
        configuration.background.strokeColor=[UIColor colorWithWhite:1.0 alpha:0.18];
        configuration.background.strokeWidth=1.0;
        configuration.background.cornerRadius=14.0;
        configuration.titleTextAttributesTransformer=^NSDictionary *(NSDictionary *attributes){
            NSMutableDictionary *updated=[attributes mutableCopy];
            updated[NSFontAttributeName]=[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
            return updated;
        };
        button.configuration=configuration;
    }
    [button addTarget:self action:@selector(zxSecondaryTouchDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(zxSecondaryTouchUp:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
}
- (void)zxSecondaryTouchDown:(UIButton *)button {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [UIView animateWithDuration:0.12 animations:^{ button.transform=CGAffineTransformMakeScale(0.985,0.985); button.alpha=0.92; }];
}
- (void)zxSecondaryTouchUp:(UIButton *)button {
    [UIView animateWithDuration:0.28 delay:0 usingSpringWithDamping:0.84 initialSpringVelocity:0.25 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction animations:^{ button.transform=CGAffineTransformIdentity; button.alpha=1.0; } completion:nil];
}

#pragma mark - Splash

- (void)setupSplash {
    _splashContainer = [[UIView alloc] init];
    _splashContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_splashContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_splashContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_splashContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_splashContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_splashContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    _splashIcon = [[UIImageView alloc] initWithImage:[self preferredLogoImage]];
    _splashIcon.contentMode = UIViewContentModeScaleAspectFit;
    _splashIcon.layer.cornerRadius = 30;
    _splashIcon.clipsToBounds = YES;
    _splashIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_splashIcon];

    UILabel *brand = [self label:@"ZENTRAX" size:28 weight:UIFontWeightBlack color:[ZXTheme primaryText]];
    [ZXTheme track:brand spacing:4.0];
    brand.textAlignment = NSTextAlignmentCenter;
    brand.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:brand];

    _splashStatus = [self label:@"SECURE BOOT" size:11 weight:UIFontWeightBold color:[ZXTheme secondaryText]];
    [ZXTheme track:_splashStatus spacing:2.2];
    _splashStatus.textAlignment = NSTextAlignmentCenter;
    _splashStatus.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_splashStatus];

    UIView *rail = [[UIView alloc] init];
    rail.backgroundColor = [ZXTheme surfaceRaised];
    rail.layer.cornerRadius = 2;
    rail.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:rail];

    _splashFill = [[UIView alloc] init];
    _splashFill.backgroundColor = [ZXTheme primaryText];
    _splashFill.layer.cornerRadius = 2;
    _splashFill.translatesAutoresizingMaskIntoConstraints = NO;
    [rail addSubview:_splashFill];

    _splashPercent = [self label:@"0%" size:10 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    _splashPercent.textAlignment = NSTextAlignmentRight;
    _splashPercent.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_splashPercent];

    _splashDetail = [self label:@"Initializing secure environment" size:11 weight:UIFontWeightRegular color:[ZXTheme mutedText]];
    _splashDetail.textAlignment = NSTextAlignmentCenter;
    _splashDetail.translatesAutoresizingMaskIntoConstraints = NO;
    [_splashContainer addSubview:_splashDetail];

    [NSLayoutConstraint activateConstraints:@[
        [_splashIcon.centerXAnchor constraintEqualToAnchor:_splashContainer.centerXAnchor],
        [_splashIcon.centerYAnchor constraintEqualToAnchor:_splashContainer.centerYAnchor constant:-92],
        [_splashIcon.widthAnchor constraintEqualToConstant:88],
        [_splashIcon.heightAnchor constraintEqualToConstant:88],
        [brand.topAnchor constraintEqualToAnchor:_splashIcon.bottomAnchor constant:20],
        [brand.leadingAnchor constraintEqualToAnchor:_splashContainer.leadingAnchor constant:30],
        [brand.trailingAnchor constraintEqualToAnchor:_splashContainer.trailingAnchor constant:-30],
        [_splashStatus.topAnchor constraintEqualToAnchor:brand.bottomAnchor constant:10],
        [_splashStatus.leadingAnchor constraintEqualToAnchor:_splashContainer.leadingAnchor constant:30],
        [_splashStatus.trailingAnchor constraintEqualToAnchor:_splashContainer.trailingAnchor constant:-30],
        [rail.leadingAnchor constraintEqualToAnchor:_splashContainer.leadingAnchor constant:68],
        [rail.trailingAnchor constraintEqualToAnchor:_splashContainer.trailingAnchor constant:-68],
        [rail.topAnchor constraintEqualToAnchor:_splashStatus.bottomAnchor constant:25],
        [rail.heightAnchor constraintEqualToConstant:4],
        [_splashFill.leadingAnchor constraintEqualToAnchor:rail.leadingAnchor],
        [_splashFill.topAnchor constraintEqualToAnchor:rail.topAnchor],
        [_splashFill.bottomAnchor constraintEqualToAnchor:rail.bottomAnchor],
        [_splashFill.widthAnchor constraintEqualToAnchor:rail.widthAnchor multiplier:0.001],
        [_splashPercent.topAnchor constraintEqualToAnchor:rail.bottomAnchor constant:9],
        [_splashPercent.trailingAnchor constraintEqualToAnchor:rail.trailingAnchor],
        [_splashPercent.widthAnchor constraintEqualToConstant:42],
        [_splashDetail.topAnchor constraintEqualToAnchor:_splashPercent.bottomAnchor constant:7],
        [_splashDetail.leadingAnchor constraintEqualToAnchor:_splashContainer.leadingAnchor constant:30],
        [_splashDetail.trailingAnchor constraintEqualToAnchor:_splashContainer.trailingAnchor constant:-30]
    ]];
}

- (void)runPremiumSplashCompletion:(void (^)(void))completion {
    NSArray *steps = @[
        @[@0.18, @"CONNECTING", @"Connecting to secure node"],
        @[@0.38, @"VERIFYING", @"Checking server policy"],
        @[@0.58, @"SECURING", @"Establishing protected session"],
        @[@0.78, @"LOADING", @"Loading configuration"],
        @[@0.94, @"READY", @"Finalizing secure interface"]
    ];
    [self runPremiumSplashStep:0 steps:steps completion:completion];
}

- (void)runPremiumSplashStep:(NSInteger)index
                        steps:(NSArray *)steps
                   completion:(void (^)(void))completion {
    if (index >= steps.count) {
        if (completion) completion();
        return;
    }

    NSArray *step = steps[index];
    CGFloat fraction = [step[0] doubleValue];
    self.splashStatus.text = step[1];
    self.splashDetail.text = step[2];
    self.splashPercent.text = [NSString stringWithFormat:@"%ld%%", (long)llround(fraction * 100.0)];

    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.22
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.splashFill.transform = CGAffineTransformMakeScale(MAX(0.001, fraction), 1.0);
    }
                     completion:^(BOOL finished) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self runPremiumSplashStep:index + 1 steps:steps completion:completion];
        });
    }];
}

#pragma mark - Authentication

- (void)setupAuth {
    _authContainer = [[UIView alloc] init];
    _authContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_authContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_authContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_authContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_authContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_authContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.alwaysBounceVertical = YES;
    scroll.showsVerticalScrollIndicator = NO;
    scroll.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [_authContainer addSubview:scroll];

    UIView *content = [[UIView alloc] init];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:content];

    _authEyebrow = [self label:@"PRIVATE ACCESS NODE" size:10 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:_authEyebrow spacing:2.0];
    _authEyebrow.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:_authEyebrow];

    UIImageView *logo = [[UIImageView alloc] initWithImage:[self preferredLogoImage]];
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.layer.cornerRadius = 24;
    logo.clipsToBounds = YES;
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:logo];

    _authTitle = [self label:@"Welcome back." size:30 weight:UIFontWeightBlack color:[ZXTheme primaryText]];
    _authTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:_authTitle];

    _authSubtitle = [self label:@"Authenticate your license to enter the secure ZENTRAX workspace." size:14 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    _authSubtitle.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:_authSubtitle];

    _keyInput = [[ZXPremiumField alloc] init];
    _keyInput.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:_keyInput];

    UIView *rememberRow = [[UIView alloc] init];
    rememberRow.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:rememberRow];

    _rememberSwitch = [[UISwitch alloc] init];
    _rememberSwitch.onTintColor = [ZXTheme primaryText];
    _rememberSwitch.thumbTintColor = [ZXTheme background];
    _rememberSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    _rememberSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"Zentrax.RememberMe"];
    [rememberRow addSubview:_rememberSwitch];

    UILabel *remember = [self label:@"Remember this license on this device" size:12 weight:UIFontWeightMedium color:[ZXTheme secondaryText]];
    remember.translatesAutoresizingMaskIntoConstraints = NO;
    [rememberRow addSubview:remember];

    _loginBtn = [[ZXPremiumButton alloc] init];
    [_loginBtn setTitle:@"AUTHENTICATE" forState:UIControlStateNormal];
    _loginBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_loginBtn addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:_loginBtn];

    _authStatus = [self label:@"" size:12 weight:UIFontWeightMedium color:[ZXTheme mutedText]];
    _authStatus.textAlignment = NSTextAlignmentCenter;
    _authStatus.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:_authStatus];

    UILabel *security = [self label:@"Server-authoritative authentication  •  Secure session  •  Device bound" size:10 weight:UIFontWeightMedium color:[ZXTheme mutedText]];
    security.textAlignment = NSTextAlignmentCenter;
    security.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:security];

    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor constraintEqualToAnchor:_authContainer.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:_authContainer.trailingAnchor],
        [scroll.topAnchor constraintEqualToAnchor:_authContainer.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:_authContainer.bottomAnchor],
        [content.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [content.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor],
        [_authEyebrow.topAnchor constraintEqualToAnchor:content.topAnchor constant:88],
        [_authEyebrow.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:28],
        [_authEyebrow.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-28],
        [logo.topAnchor constraintEqualToAnchor:_authEyebrow.bottomAnchor constant:18],
        [logo.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:28],
        [logo.widthAnchor constraintEqualToConstant:52],
        [logo.heightAnchor constraintEqualToConstant:52],
        [_authTitle.topAnchor constraintEqualToAnchor:logo.bottomAnchor constant:20],
        [_authTitle.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:28],
        [_authTitle.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-28],
        [_authSubtitle.topAnchor constraintEqualToAnchor:_authTitle.bottomAnchor constant:8],
        [_authSubtitle.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:28],
        [_authSubtitle.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-28],
        [_keyInput.topAnchor constraintEqualToAnchor:_authSubtitle.bottomAnchor constant:32],
        [_keyInput.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:28],
        [_keyInput.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-28],
        [rememberRow.topAnchor constraintEqualToAnchor:_keyInput.bottomAnchor constant:15],
        [rememberRow.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:28],
        [rememberRow.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-28],
        [rememberRow.heightAnchor constraintEqualToConstant:34],
        [_rememberSwitch.leadingAnchor constraintEqualToAnchor:rememberRow.leadingAnchor],
        [_rememberSwitch.centerYAnchor constraintEqualToAnchor:rememberRow.centerYAnchor],
        [remember.leadingAnchor constraintEqualToAnchor:_rememberSwitch.trailingAnchor constant:10],
        [remember.trailingAnchor constraintLessThanOrEqualToAnchor:rememberRow.trailingAnchor],
        [remember.centerYAnchor constraintEqualToAnchor:rememberRow.centerYAnchor],
        [_loginBtn.topAnchor constraintEqualToAnchor:rememberRow.bottomAnchor constant:16],
        [_loginBtn.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:28],
        [_loginBtn.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-28],
        [_loginBtn.heightAnchor constraintEqualToConstant:56],
        [_authStatus.topAnchor constraintEqualToAnchor:_loginBtn.bottomAnchor constant:16],
        [_authStatus.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:28],
        [_authStatus.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-28],
        [security.topAnchor constraintEqualToAnchor:_authStatus.bottomAnchor constant:28],
        [security.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:28],
        [security.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-28],
        [security.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-40]
    ]];
}

- (void)handleLogin {
    NSString *key = [_keyInput.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!key.length) {
        [self showToast:@"Enter your license key." success:NO];
        return;
    }
    [[NSUserDefaults standardUserDefaults] setBool:self.rememberSwitch.isOn forKey:@"Zentrax.RememberMe"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [_loginBtn setLoading:YES];
    _authStatus.textColor = [ZXTheme secondaryText];
    _authStatus.text = @"Connecting…";
    [self showGlobalLoadingState:@"AUTHENTICATING"];
    [self updateGlobalLoadingMessage:@"Connecting to ZENTRAX server"];

    __weak typeof(self) weakSelf = self;
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestAuthenticationWithKey:completion:)]) {
        [self.delegate zentraxDidRequestAuthenticationWithKey:key completion:^(BOOL success, ZXAuthError errorType, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) return;
                [self hideGlobalLoadingState];
                [self.loginBtn setLoading:NO];
                if (success) {
                    if (self.rememberSwitch.isOn) [[NSUserDefaults standardUserDefaults] setObject:key forKey:ZXLastKey];
                    else [[NSUserDefaults standardUserDefaults] removeObjectForKey:ZXLastKey];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    self.authStatus.textColor = [ZXTheme success];
                    self.authStatus.text = @"Access granted • Loading secure workspace";
                    [self showDashboard];
                } else {
                    [self presentAuthError:errorType message:errorMsg];
                }
            });
        }];
    } else {
        [self hideGlobalLoadingState];
        [self.loginBtn setLoading:NO];
        [self showGlobalErrorWithTitle:@"AUTHENTICATION UNAVAILABLE" message:@"The secure authentication bridge is not available."];
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

#pragma mark - Dashboard

- (void)setupDashboard {
    _dashboardContainer = [[UIView alloc] init];
    _dashboardContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_dashboardContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_dashboardContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_dashboardContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_dashboardContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_dashboardContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UIView *header = [[UIView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:header];

    UIImageView *logo = [[UIImageView alloc] initWithImage:[self preferredLogoImage]];
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.layer.cornerRadius = 14;
    logo.clipsToBounds = YES;
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:logo];

    _dashboardTitle = [self label:@"ZENTRAX" size:19 weight:UIFontWeightBlack color:[ZXTheme primaryText]];
    [ZXTheme track:_dashboardTitle spacing:1.5];
    _dashboardTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:_dashboardTitle];

    _connectionLabel = [self label:@"● SECURE" size:9 weight:UIFontWeightBold color:[ZXTheme success]];
    [ZXTheme track:_connectionLabel spacing:1.0];
    _connectionLabel.textAlignment = NSTextAlignmentRight;
    _connectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:_connectionLabel];

    _settingsButton = [self iconButton:@"slider.horizontal.3" size:34];
    _settingsButton.backgroundColor = [ZXTheme surfaceRaised];
    _settingsButton.layer.cornerRadius = 12;
    [_settingsButton addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:_settingsButton];

    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:20],
        [header.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-20],
        [header.topAnchor constraintEqualToAnchor:_dashboardContainer.safeAreaLayoutGuide.topAnchor constant:8],
        [header.heightAnchor constraintEqualToConstant:48],
        [logo.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [logo.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [logo.widthAnchor constraintEqualToConstant:38],
        [logo.heightAnchor constraintEqualToConstant:38],
        [_dashboardTitle.leadingAnchor constraintEqualToAnchor:logo.trailingAnchor constant:11],
        [_dashboardTitle.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [_connectionLabel.trailingAnchor constraintEqualToAnchor:_settingsButton.leadingAnchor constant:-10],
        [_connectionLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [_settingsButton.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],
        [_settingsButton.centerYAnchor constraintEqualToAnchor:header.centerYAnchor]
    ]];

    _serverBannerView = [[UIView alloc] init];
    _serverBannerView.translatesAutoresizingMaskIntoConstraints = NO;
    _serverBannerView.backgroundColor = [ZXTheme surfaceRaised];
    _serverBannerView.layer.cornerRadius = 14;
    _serverBannerView.layer.borderWidth = 1;
    _serverBannerView.layer.borderColor = [ZXTheme border].CGColor;
    [_dashboardContainer addSubview:_serverBannerView];
    [NSLayoutConstraint activateConstraints:@[
        [_serverBannerView.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:20],
        [_serverBannerView.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-20],
        [_serverBannerView.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:10],
        [_serverBannerView.heightAnchor constraintEqualToConstant:54]
    ]];
    UILabel *bannerIcon = [self label:@"i" size:12 weight:UIFontWeightBold color:[ZXTheme primaryText]];
    bannerIcon.textAlignment = NSTextAlignmentCenter;
    bannerIcon.backgroundColor = [ZXTheme surfaceInset];
    bannerIcon.layer.cornerRadius = 10;
    bannerIcon.clipsToBounds = YES;
    bannerIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [_serverBannerView addSubview:bannerIcon];
    UILabel *bannerText = [self label:@"Secure node connected." size:11 weight:UIFontWeightMedium color:[ZXTheme secondaryText]];
    bannerText.tag = 9101;
    bannerText.translatesAutoresizingMaskIntoConstraints = NO;
    [_serverBannerView addSubview:bannerText];
    [NSLayoutConstraint activateConstraints:@[
        [bannerIcon.leadingAnchor constraintEqualToAnchor:_serverBannerView.leadingAnchor constant:14],
        [bannerIcon.centerYAnchor constraintEqualToAnchor:_serverBannerView.centerYAnchor],
        [bannerIcon.widthAnchor constraintEqualToConstant:20], [bannerIcon.heightAnchor constraintEqualToConstant:20],
        [bannerText.leadingAnchor constraintEqualToAnchor:bannerIcon.trailingAnchor constant:10],
        [bannerText.trailingAnchor constraintEqualToAnchor:_serverBannerView.trailingAnchor constant:-14],
        [bannerText.centerYAnchor constraintEqualToAnchor:_serverBannerView.centerYAnchor]
    ]];

    _licenseCard = [self card];
    [_dashboardContainer addSubview:_licenseCard];
    [NSLayoutConstraint activateConstraints:@[
        [_licenseCard.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:20],
        [_licenseCard.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-20],
        [_licenseCard.topAnchor constraintEqualToAnchor:_serverBannerView.bottomAnchor constant:14],
        [_licenseCard.heightAnchor constraintEqualToConstant:190]
    ]];

    UILabel *licenseCaption = [self label:@"LICENSE CONTROL" size:9 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:licenseCaption spacing:1.8];
    licenseCaption.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:licenseCaption];

    _licenseStatusLabel = [self label:@"UNACTIVATED" size:12 weight:UIFontWeightBold color:[ZXTheme warning]];
    [ZXTheme track:_licenseStatusLabel spacing:1.2];
    _licenseStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:_licenseStatusLabel];

    _countdownLabel = [self label:@"—" size:30 weight:UIFontWeightBlack color:[ZXTheme primaryText]];
    _countdownLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:_countdownLabel];

    _expiryLabel = [self label:@"Awaiting first activation" size:11 weight:UIFontWeightMedium color:[ZXTheme secondaryText]];
    _expiryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:_expiryLabel];

    _keyRevealLabel = [self label:@"•••• •••• ••••" size:11 weight:UIFontWeightMedium color:[ZXTheme mutedText]];
    _keyRevealLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_licenseCard addSubview:_keyRevealLabel];

    _keyEyeButton = [self iconButton:@"eye.slash.fill" size:32];
    [_keyEyeButton addTarget:self action:@selector(toggleDashboardKey) forControlEvents:UIControlEventTouchUpInside];
    [_licenseCard addSubview:_keyEyeButton];

    [NSLayoutConstraint activateConstraints:@[
        [licenseCaption.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:18],
        [licenseCaption.topAnchor constraintEqualToAnchor:_licenseCard.topAnchor constant:17],
        [_licenseStatusLabel.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor constant:-18],
        [_licenseStatusLabel.centerYAnchor constraintEqualToAnchor:licenseCaption.centerYAnchor],
        [_countdownLabel.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:18],
        [_countdownLabel.topAnchor constraintEqualToAnchor:licenseCaption.bottomAnchor constant:17],
        [_countdownLabel.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor constant:-18],
        [_expiryLabel.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:18],
        [_expiryLabel.topAnchor constraintEqualToAnchor:_countdownLabel.bottomAnchor constant:2],
        [_expiryLabel.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor constant:-18],
        [_keyRevealLabel.leadingAnchor constraintEqualToAnchor:_licenseCard.leadingAnchor constant:18],
        [_keyRevealLabel.bottomAnchor constraintEqualToAnchor:_licenseCard.bottomAnchor constant:-16],
        [_keyRevealLabel.trailingAnchor constraintEqualToAnchor:_keyEyeButton.leadingAnchor constant:-8],
        [_keyEyeButton.trailingAnchor constraintEqualToAnchor:_licenseCard.trailingAnchor constant:-14],
        [_keyEyeButton.centerYAnchor constraintEqualToAnchor:_keyRevealLabel.centerYAnchor]
    ]];

    UILabel *functionsTitle = [self label:@"SECURE FUNCTIONS" size:10 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:functionsTitle spacing:1.8];
    functionsTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:functionsTitle];

    _modulesScroll = [[UIScrollView alloc] init];
    _modulesScroll.showsVerticalScrollIndicator = NO;
    _modulesScroll.alwaysBounceVertical = YES;
    _modulesScroll.translatesAutoresizingMaskIntoConstraints = NO;
    [_dashboardContainer addSubview:_modulesScroll];

    _modulesStack = [[UIStackView alloc] init];
    _modulesStack.axis = UILayoutConstraintAxisVertical;
    _modulesStack.spacing = 11;
    _modulesStack.translatesAutoresizingMaskIntoConstraints = NO;
    [_modulesScroll addSubview:_modulesStack];

    [NSLayoutConstraint activateConstraints:@[
        [functionsTitle.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:20],
        [functionsTitle.topAnchor constraintEqualToAnchor:_licenseCard.bottomAnchor constant:20],
        [functionsTitle.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-20],
        [_modulesScroll.leadingAnchor constraintEqualToAnchor:_dashboardContainer.leadingAnchor constant:20],
        [_modulesScroll.trailingAnchor constraintEqualToAnchor:_dashboardContainer.trailingAnchor constant:-20],
        [_modulesScroll.topAnchor constraintEqualToAnchor:functionsTitle.bottomAnchor constant:9],
        [_modulesScroll.bottomAnchor constraintEqualToAnchor:_dashboardContainer.safeAreaLayoutGuide.bottomAnchor constant:-12],
        [_modulesStack.leadingAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.leadingAnchor],
        [_modulesStack.trailingAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.trailingAnchor],
        [_modulesStack.topAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.topAnchor],
        [_modulesStack.bottomAnchor constraintEqualToAnchor:_modulesScroll.contentLayoutGuide.bottomAnchor],
        [_modulesStack.widthAnchor constraintEqualToAnchor:_modulesScroll.frameLayoutGuide.widthAnchor]
    ]];

    [self createEmptyStateView];
}

- (void)createEmptyStateView {
    _emptyState = [self card];
    _emptyState.backgroundColor = [ZXTheme surfaceInset];
    UILabel *icon = [self label:@"—" size:26 weight:UIFontWeightBlack color:[ZXTheme mutedText]];
    icon.textAlignment = NSTextAlignmentCenter;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyState addSubview:icon];
    UILabel *title = [self label:@"No functions available" size:14 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    title.textAlignment = NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyState addSubview:title];
    UILabel *detail = [self label:@"Your server configuration will appear here when functions are assigned to this license." size:11 weight:UIFontWeightRegular color:[ZXTheme mutedText]];
    detail.textAlignment = NSTextAlignmentCenter;
    detail.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyState addSubview:detail];
    [NSLayoutConstraint activateConstraints:@[
        [_emptyState.heightAnchor constraintEqualToConstant:148],
        [icon.centerXAnchor constraintEqualToAnchor:_emptyState.centerXAnchor], [icon.topAnchor constraintEqualToAnchor:_emptyState.topAnchor constant:22],
        [title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:7], [title.leadingAnchor constraintEqualToAnchor:_emptyState.leadingAnchor constant:20], [title.trailingAnchor constraintEqualToAnchor:_emptyState.trailingAnchor constant:-20],
        [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:6], [detail.leadingAnchor constraintEqualToAnchor:_emptyState.leadingAnchor constant:24], [detail.trailingAnchor constraintEqualToAnchor:_emptyState.trailingAnchor constant:-24]
    ]];
    [_modulesStack addArrangedSubview:_emptyState];
}

- (void)toggleDashboardKey {
    self.keyRevealed = !self.keyRevealed;
    NSString *key = [[NSUserDefaults standardUserDefaults] stringForKey:ZXLastKey] ?: @"";
    _keyRevealLabel.text = self.keyRevealed && key.length ? key : @"•••• •••• ••••";
    [_keyEyeButton setImage:[UIImage systemImageNamed:self.keyRevealed ? @"eye.fill" : @"eye.slash.fill"] forState:UIControlStateNormal];
}

#pragma mark - Dynamic Dashboard

- (void)updateDashboardWithModules:(NSArray<NSDictionary *> *)modules {
    [self updateDashboardWithConfiguration:@{ @"modules": modules ?: @[] }];
}

- (void)updateDashboardWithConfiguration:(NSDictionary *)configuration {
    if (![configuration isKindOfClass:[NSDictionary class]]) configuration=@{};
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self updateDashboardWithConfiguration:configuration]; });
        return;
    }
    self.dashboardConfiguration = configuration ?: @{};
    NSArray *categories = configuration[@"categories"];
    NSArray *modules = configuration[@"modules"] ?: configuration[@"functions"];
    if (![categories isKindOfClass:[NSArray class]] || !categories.count) {
        categories = modules;
    }

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
            UILabel *cat=[self label:categoryName.uppercaseString size:9 weight:UIFontWeightBold color:[ZXTheme mutedText]];
            [ZXTheme track:cat spacing:1.5];
            [_modulesStack addArrangedSubview:cat];
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
            BOOL on=[function[@"current_state"] boolValue] || [function[@"state"] boolValue] || [self.functionStates[fid] boolValue];
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

- (UIView *)functionCardForDefinition:(NSDictionary *)definition functionId:(NSString *)fid isOn:(BOOL)on {
    UIView *card = [self card];
    card.layer.cornerRadius = 18;

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"bolt.shield.fill"]];
    icon.tintColor = on ? [ZXTheme success] : [ZXTheme mutedText];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:icon];

    UILabel *title = [self label:[NSString stringWithFormat:@"%@", definition[@"name"] ?: definition[@"title"] ?: fid] size:15 weight:UIFontWeightSemibold color:[ZXTheme primaryText]];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:title];

    UILabel *detail = [self label:[NSString stringWithFormat:@"%@", definition[@"description"] ?: @"Server-managed secure function"] size:10 weight:UIFontWeightRegular color:[ZXTheme secondaryText]];
    detail.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:detail];

    UILabel *stateLabel = [self label:on ? @"ACTIVE" : @"READY" size:8 weight:UIFontWeightBold color:on ? [ZXTheme success] : [ZXTheme mutedText]];
    [ZXTheme track:stateLabel spacing:1.0];
    stateLabel.textAlignment = NSTextAlignmentRight;
    stateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:stateLabel];
    self.functionStateLabels[fid] = stateLabel;

    UISwitch *toggle = [[UISwitch alloc] init];
    toggle.onTintColor = [ZXTheme success];
    toggle.thumbTintColor = [ZXTheme background];
    toggle.on = on;
    toggle.accessibilityLabel = title.text;
    toggle.tag = (NSInteger)fid.hash;
    toggle.translatesAutoresizingMaskIntoConstraints = NO;
    [toggle addTarget:self action:@selector(functionToggleChanged:) forControlEvents:UIControlEventValueChanged];
    [card addSubview:toggle];
    self.functionControls[fid] = toggle;

    [NSLayoutConstraint activateConstraints:@[
        [card.heightAnchor constraintGreaterThanOrEqualToConstant:84],
        [icon.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:15], [icon.centerYAnchor constraintEqualToAnchor:card.centerYAnchor], [icon.widthAnchor constraintEqualToConstant:26], [icon.heightAnchor constraintEqualToConstant:26],
        [title.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:12], [title.topAnchor constraintEqualToAnchor:card.topAnchor constant:16], [title.trailingAnchor constraintLessThanOrEqualToAnchor:stateLabel.leadingAnchor constant:-10],
        [detail.leadingAnchor constraintEqualToAnchor:title.leadingAnchor], [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4], [detail.trailingAnchor constraintLessThanOrEqualToAnchor:card.trailingAnchor constant:-80],
        [stateLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-15], [stateLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [toggle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14], [toggle.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-12]
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
    NSString *fid = [self functionIdForControl:sender];
    if (!fid.length) return;
    BOOL requested = sender.isOn;
    self.functionStates[fid] = @(requested);
    sender.userInteractionEnabled = NO;
    UILabel *state = self.functionStateLabels[fid];
    state.textColor = [ZXTheme warning];
    state.text = @"PROCESSING";
    [ZXTheme track:state spacing:1.0];

    __weak typeof(self) weakSelf = self;
    void (^finish)(BOOL, NSString *) = ^(BOOL success, NSString *msg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            sender.userInteractionEnabled = YES;
            if (success) {
                self.functionStates[fid] = @(requested);
                state.text = requested ? @"ACTIVE" : @"READY";
                state.textColor = requested ? [ZXTheme success] : [ZXTheme mutedText];
                [self showToast:requested ? @"Function enabled" : @"Function disabled" success:YES];
            } else {
                sender.on = !requested;
                self.functionStates[fid] = @(!requested);
                state.text = !requested ? @"ACTIVE" : @"READY";
                state.textColor = !requested ? [ZXTheme success] : [ZXTheme mutedText];
                [self showGlobalErrorWithTitle:@"OPERATION FAILED" message:msg ?: @"The server could not complete this operation."];
            }
        });
    };

    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestFunctionOperation:action:completion:)]) {
        [self.delegate zentraxDidRequestFunctionOperation:fid action:requested completion:finish];
    } else if ([self.delegate respondsToSelector:@selector(zentraxDidRequestModuleToggle:state:completion:)]) {
        [self.delegate zentraxDidRequestModuleToggle:fid state:requested completion:finish];
    } else {
        finish(NO, @"Function operation bridge is unavailable.");
    }
}

- (void)updateFunctionState:(NSString *)functionId state:(BOOL)isOn {
    if (!functionId.length) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.functionStates[functionId] = @(isOn);
        UISwitch *toggle = (UISwitch *)self.functionControls[functionId];
        if ([toggle isKindOfClass:[UISwitch class]]) [toggle setOn:isOn animated:YES];
        UILabel *label = self.functionStateLabels[functionId];
        label.text = isOn ? @"ACTIVE" : @"READY";
        label.textColor = isOn ? [ZXTheme success] : [ZXTheme mutedText];
    });
}

- (void)updateFunctionStates:(NSDictionary<NSString *,NSNumber *> *)states {
    if (![states isKindOfClass:[NSDictionary class]]) return;
    for (NSString *fid in states) {
        id value=states[fid];
        if (![value respondsToSelector:@selector(boolValue)]) continue;
        [self updateFunctionState:fid state:[value boolValue]];
    }
}

#pragma mark - Subscription / Time

- (void)updateSubscriptionState:(NSDictionary *)subData {
    if (![subData isKindOfClass:[NSDictionary class]]) return;
    NSString *status = [[NSString stringWithFormat:@"%@", subData[@"status"] ?: @"unknown"] lowercaseString];
    ZXLicenseUIStatus uiStatus = ZXLicenseUIStatusUnknown;
    if ([status isEqualToString:@"unactivated"]) uiStatus = ZXLicenseUIStatusUnactivated;
    else if ([status isEqualToString:@"active"]) uiStatus = ZXLicenseUIStatusActive;
    else if ([status isEqualToString:@"expired"]) uiStatus = ZXLicenseUIStatusExpired;
    else if ([status isEqualToString:@"revoked"]) uiStatus = ZXLicenseUIStatusRevoked;
    else if ([status isEqualToString:@"disabled"]) uiStatus = ZXLicenseUIStatusDisabled;

    NSDate *activated = [self dateFromServerValue:subData[@"activated_at"]];
    NSDate *expires = [self dateFromServerValue:subData[@"expires_at"]];
    BOOL permanent = [subData[@"is_permanent"] boolValue];
    [self updateLicenseStatus:uiStatus activatedAt:activated expiresAt:expires isPermanent:permanent];
}

- (void)updateLicenseStatus:(ZXLicenseUIStatus)status activatedAt:(NSDate *)activatedAt expiresAt:(NSDate *)expiresAt isPermanent:(BOOL)isPermanent {
    self.licenseStatus = status;
    self.activatedAt = activatedAt;
    self.expiresAt = expiresAt;
    self.licensePermanent = isPermanent;
    NSString *text = @"UNKNOWN";
    UIColor *color = [ZXTheme mutedText];
    switch (status) {
        case ZXLicenseUIStatusUnactivated: text = @"UNACTIVATED"; color = [ZXTheme warning]; break;
        case ZXLicenseUIStatusActive: text = @"ACTIVE"; color = [ZXTheme success]; break;
        case ZXLicenseUIStatusExpired: text = @"EXPIRED"; color = [ZXTheme error]; break;
        case ZXLicenseUIStatusRevoked: text = @"REVOKED"; color = [ZXTheme error]; break;
        case ZXLicenseUIStatusDisabled: text = @"DISABLED"; color = [ZXTheme error]; break;
        default: break;
    }
    _licenseStatusLabel.text = text;
    _licenseStatusLabel.textColor = color;
    if (isPermanent) {
        _countdownLabel.text = @"PERMANENT";
        _expiryLabel.text = @"Lifetime server entitlement";
    } else if (expiresAt) {
        [self startLicenseCountdown];
        [self refreshLicenseCountdown];
    } else if (status == ZXLicenseUIStatusUnactivated) {
        _countdownLabel.text = @"NOT STARTED";
        _expiryLabel.text = @"Timer starts on first successful activation";
    }
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
        // The stored value is a reference point; advance it using monotonic wall time from the update.
        NSDate *reference = objc_getAssociatedObject(self, @selector(estimatedServerNow));
        if (!reference) {
            reference = [NSDate date];
            objc_setAssociatedObject(self, @selector(estimatedServerNow), reference, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:reference];
        return [self.serverDate dateByAddingTimeInterval:MAX(0, elapsed)];
    }
    Class managerClass = NSClassFromString(@"ZentraxNetworkManager");
    SEL sel = NSSelectorFromString(@"estimatedServerDate");
    if (managerClass && [managerClass respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
        id manager = ((id (*)(id, SEL))objc_msgSend)((id)managerClass, NSSelectorFromString(@"sharedManager"));
        if ([manager respondsToSelector:sel]) {
            NSDate *d = ((NSDate *(*)(id, SEL))objc_msgSend)(manager, sel);
            if (d) return d;
        }
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
    if (self.licensePermanent) {
        _countdownLabel.text = @"PERMANENT";
        return;
    }
    if (!self.expiresAt) return;
    NSTimeInterval remaining = [self.expiresAt timeIntervalSinceDate:[self estimatedServerNow]];
    if (remaining <= 0) {
        _countdownLabel.text = @"EXPIRED";
        _expiryLabel.text = @"Server entitlement has ended";
        _licenseStatusLabel.text = @"EXPIRED";
        _licenseStatusLabel.textColor = [ZXTheme error];
        [self stopLicenseCountdown];
        return;
    }
    NSInteger total = (NSInteger)floor(remaining);
    NSInteger days = total / 86400; total %= 86400;
    NSInteger hours = total / 3600; total %= 3600;
    NSInteger minutes = total / 60; NSInteger seconds = total % 60;
    if (days > 0) _countdownLabel.text = [NSString stringWithFormat:@"%ldd %02ldh %02ldm", (long)days, (long)hours, (long)minutes];
    else _countdownLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
    _expiryLabel.text = [NSString stringWithFormat:@"Expires %@", [self shortDateString:self.expiresAt]];
}

- (NSString *)shortDateString:(NSDate *)date {
    if (!date) return @"—";
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.dateStyle = NSDateFormatterMediumStyle;
    f.timeStyle = NSDateFormatterShortStyle;
    return [f stringFromDate:date];
}

#pragma mark - Server Banner

- (void)updateServerBanner:(NSDictionary *)banner {
    if (![banner isKindOfClass:[NSDictionary class]] || !banner.count) {
        _serverBannerView.hidden = NO;
        UILabel *l = [_serverBannerView viewWithTag:9101];
        l.text = @"Secure node connected.";
        return;
    }
    _serverBannerTitle = [NSString stringWithFormat:@"%@", banner[@"title"] ?: @"SERVER NOTICE"];
    _serverBannerMessage = [NSString stringWithFormat:@"%@", banner[@"message"] ?: @"Secure node connected."];
    UILabel *l = [_serverBannerView viewWithTag:9101];
    l.text = self.serverBannerMessage.length ? self.serverBannerMessage : self.serverBannerTitle;
    _serverBannerView.hidden = NO;
}

#pragma mark - Startup Screens

- (void)setupStartupBlock {
    _startupBlockContainer = [[UIView alloc] init];
    _startupBlockContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_startupBlockContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_startupBlockContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [_startupBlockContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor], [_startupBlockContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor], [_startupBlockContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UIView *card = [self card];
    [_startupBlockContainer addSubview:card];
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.shield.fill"]];
    icon.tintColor = [ZXTheme primaryText]; icon.contentMode = UIViewContentModeScaleAspectFit; icon.translatesAutoresizingMaskIntoConstraints = NO; [card addSubview:icon];
    _startupBlockTitle = [self label:@"SECURITY GATE" size:22 weight:UIFontWeightBlack color:[ZXTheme primaryText]]; _startupBlockTitle.textAlignment = NSTextAlignmentCenter; _startupBlockTitle.translatesAutoresizingMaskIntoConstraints = NO; [card addSubview:_startupBlockTitle];
    _startupBlockMessage = [self label:@"" size:13 weight:UIFontWeightRegular color:[ZXTheme secondaryText]]; _startupBlockMessage.textAlignment = NSTextAlignmentCenter; _startupBlockMessage.translatesAutoresizingMaskIntoConstraints = NO; [card addSubview:_startupBlockMessage];
    _startupBlockAction = [UIButton buttonWithType:UIButtonTypeSystem]; [self styleSecondaryButton:_startupBlockAction]; [_startupBlockAction setTitle:@"RETRY" forState:UIControlStateNormal]; _startupBlockAction.translatesAutoresizingMaskIntoConstraints = NO; [_startupBlockAction addTarget:self action:@selector(startupBlockRetry) forControlEvents:UIControlEventTouchUpInside]; [card addSubview:_startupBlockAction];
    [NSLayoutConstraint activateConstraints:@[
        [card.leadingAnchor constraintEqualToAnchor:_startupBlockContainer.leadingAnchor constant:28], [card.trailingAnchor constraintEqualToAnchor:_startupBlockContainer.trailingAnchor constant:-28], [card.centerYAnchor constraintEqualToAnchor:_startupBlockContainer.centerYAnchor],
        [icon.topAnchor constraintEqualToAnchor:card.topAnchor constant:30], [icon.centerXAnchor constraintEqualToAnchor:card.centerXAnchor], [icon.widthAnchor constraintEqualToConstant:48], [icon.heightAnchor constraintEqualToConstant:48],
        [_startupBlockTitle.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:18], [_startupBlockTitle.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22], [_startupBlockTitle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-22],
        [_startupBlockMessage.topAnchor constraintEqualToAnchor:_startupBlockTitle.bottomAnchor constant:10], [_startupBlockMessage.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:25], [_startupBlockMessage.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-25],
        [_startupBlockAction.topAnchor constraintEqualToAnchor:_startupBlockMessage.bottomAnchor constant:22], [_startupBlockAction.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:25], [_startupBlockAction.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-25], [_startupBlockAction.heightAnchor constraintEqualToConstant:48], [_startupBlockAction.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-25]
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
        case ZXStartupStateConnectionError: title = @"CONNECTION LOST"; action = @"RETRY CONNECTION"; break;
        default: break;
    }
    _startupBlockTitle.text = title;
    _startupBlockMessage.text = message.length ? message : @"The server did not permit the secure workspace to open.";
    [_startupBlockAction setTitle:action forState:UIControlStateNormal];
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
    self.splashContainer.hidden = YES;
    NSString *selectedLanguage = [[NSUserDefaults standardUserDefaults] stringForKey:ZXLanguageKey];
    if (!selectedLanguage.length) {
        [self showLanguageSelection];
        return;
    }
    NSString *key = [[NSUserDefaults standardUserDefaults] stringForKey:ZXLastKey];
    if (key.length && [[NSUserDefaults standardUserDefaults] boolForKey:@"Zentrax.RememberMe"]) {
        if ([self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) {
            __weak typeof(self) weakSelf = self;
            [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL valid) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) self = weakSelf; if (!self) return;
                    if (valid) [self showDashboard]; else [self showLoginScreen];
                });
            }];
        } else [self showLoginScreen];
    } else {
        [self showLoginScreen];
    }
}

- (void)startupBlockRetry {
    if (self.blockedState == ZXStartupStateIncompatible) [self requestDeviceCompatibilityRecheck];
    else [self beginBootstrap];
}

- (void)showLoginScreen {
    if (self.safeModeEnabled) { [self showSafeModeLockScreen]; return; }
    [self transitionToPrimaryContainer:self.authContainer];
    self.currentState = ZXAppStateAuth;
    NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:ZXLastKey];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Zentrax.RememberMe"] && saved.length) self.keyInput.textField.text = saved;
    [self stopHeartbeatMonitor];
}

- (void)showDashboard {
    if (self.safeModeEnabled && self.safeModeState != ZXSafeModeStateUnlocked) { [self showSafeModeLockScreen]; return; }
    [self transitionToPrimaryContainer:self.dashboardContainer];
    self.currentState = ZXAppStateDashboard;
    [self startHeartbeatMonitor];

    /*
     * Do not rebuild the dashboard synchronously inside the authentication
     * completion.  The authenticated session is already stored by the network
     * manager.  Let the controller finish its first layout pass, then consume
     * the cached server configuration on the next main-queue turn.
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.currentState != ZXAppStateDashboard) return;
        @try {
            [self refreshDashboardFromManagerIfAvailable];
        } @catch (NSException *exception) {
            NSLog(@"[Zentrax VIP] Dashboard configuration exception: %@", exception);
        }
    });
}

- (void)showMaintenanceScreenWithMessage:(NSString *)message { [self showStartupState:ZXStartupStateMaintenance message:message]; }
- (void)showUpdateRequiredScreenWithMessage:(NSString *)message { [self showStartupState:ZXStartupStateVersionMismatch message:message]; }
- (void)showConnectionErrorScreenWithMessage:(NSString *)message { [self showStartupState:ZXStartupStateConnectionError message:message]; }
- (void)showCompatibilityScreenWithData:(NSDictionary *)compatibility {
    NSDictionary *safe=[compatibility isKindOfClass:[NSDictionary class]] ? compatibility : @{};
    [self updateDeviceCompatibility:safe];
    id reason=safe[@"reason"] ?: safe[@"message"];
    NSString *message=[reason isKindOfClass:[NSString class]] ? reason : nil;
    [self showStartupState:ZXStartupStateIncompatible message:message];
}

#pragma mark - Bootstrap Bridge

- (void)beginBootstrap {
    if (self.safeModeEnabled) { [self showSafeModeLockScreen]; return; }
    self.startupState = ZXStartupStateBootstrapping;
    [self showStartupState:ZXStartupStateBootstrapping message:nil];

    Class cls = NSClassFromString(@"ZentraxNetworkManager");
    if (!cls || ![cls respondsToSelector:NSSelectorFromString(@"sharedManager")]) {
        [self handleBootstrapState:ZXStartupStateReady message:nil];
        return;
    }
    id manager = ((id (*)(id, SEL))objc_msgSend)((id)cls, NSSelectorFromString(@"sharedManager"));
    if (!manager || ![manager isKindOfClass:[ZentraxNetworkManager class]]) {
        [self handleBootstrapState:ZXStartupStateConnectionError message:@"Secure network manager is unavailable."];
        return;
    }
    SEL bootstrap = NSSelectorFromString(@"bootstrapWithCompletion:");
    if (!manager || ![manager respondsToSelector:bootstrap]) {
        [self handleBootstrapState:ZXStartupStateReady message:nil];
        return;
    }
    __weak typeof(self) weakSelf = self;

    /*
     * ZXBootstrapCompletion has FIVE parameters:
     *   success, response, bootstrapState, errorType, errorMessage
     *
     * The previous implementation declared only FOUR parameters and therefore
     * interpreted errorType as an NSString *.  When bootstrap failed, that
     * integer was later used as a message object, which could dereference an
     * invalid pointer and terminate the app immediately while the splash was
     * still at 0%.
     *
     * Keep the callback strongly typed so this cannot silently regress.
     */
    ZXBootstrapCompletion completion = ^(BOOL success,
                                         NSDictionary * _Nullable response,
                                         ZXBootstrapState bootstrapState,
                                         ZXNetworkErrorType errorType,
                                         NSString * _Nullable errorMsg) {
        (void)errorType;
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;

        ZXStartupState state = ZXStartupStateConnectionError;
        switch (bootstrapState) {
            case ZXBootstrapStateReady:
                state = ZXStartupStateReady;
                break;
            case ZXBootstrapStateMaintenance:
                state = ZXStartupStateMaintenance;
                break;
            case ZXBootstrapStateVersionMismatch:
                state = ZXStartupStateVersionMismatch;
                break;
            case ZXBootstrapStateIncompatible:
                state = ZXStartupStateIncompatible;
                break;
            case ZXBootstrapStateConnectionError:
                state = ZXStartupStateConnectionError;
                break;
            case ZXBootstrapStateUnknown:
            default:
                state = success ? ZXStartupStateReady : ZXStartupStateConnectionError;
                break;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (response.count) {
                [self consumeBootstrapPayload:response];
            }
            NSString *message=[errorMsg isKindOfClass:[NSString class]] ? errorMsg : nil;
            if (!message.length && [response isKindOfClass:[NSDictionary class]]) {
                id responseMessage=((NSDictionary *)response)[@"message"];
                if ([responseMessage isKindOfClass:[NSString class]]) message=responseMessage;
            }
            [self handleBootstrapState:state message:message];
        });
    };

    /* Use the declared API rather than an untyped objc_msgSend block call. */
    [(ZentraxNetworkManager *)manager bootstrapWithCompletion:completion];
}

- (void)consumeBootstrapPayload:(NSDictionary *)payload {
    if (![payload isKindOfClass:[NSDictionary class]]) return;
    id serverTime=payload[@"server_time"] ?: payload[@"server_iso"];
    if (!serverTime) {
        id server=payload[@"server"];
        if ([server isKindOfClass:[NSDictionary class]]) serverTime=((NSDictionary *)server)[@"time"] ?: ((NSDictionary *)server)[@"iso"];
    }
    NSDate *d=[self dateFromServerValue:serverTime];
    if (d) [self updateServerTime:d];
    NSDictionary *config = payload[@"configuration"] ?: payload[@"config"] ?: payload[@"dashboard_data"];
    if ([config isKindOfClass:[NSDictionary class]]) [self updateDashboardWithConfiguration:config];
    NSDictionary *license = payload[@"license"];
    if ([license isKindOfClass:[NSDictionary class]]) [self updateSubscriptionState:license];
    NSDictionary *banner = payload[@"banner"] ?: payload[@"notice"];
    if ([banner isKindOfClass:[NSDictionary class]]) [self updateServerBanner:banner];
    NSDictionary *compat = payload[@"compatibility"];
    if ([compat isKindOfClass:[NSDictionary class]]) [self updateDeviceCompatibility:compat];
}

- (void)refreshDashboardFromManagerIfAvailable {
    Class cls = NSClassFromString(@"ZentraxNetworkManager");
    if (!cls || ![cls respondsToSelector:NSSelectorFromString(@"sharedManager")]) return;
    id manager = ((id (*)(id, SEL))objc_msgSend)((id)cls, NSSelectorFromString(@"sharedManager"));
    SEL configSel = NSSelectorFromString(@"cachedConfiguration");
    if ([manager respondsToSelector:configSel]) {
        NSDictionary *config = ((NSDictionary *(*)(id, SEL))objc_msgSend)(manager, configSel);
        if ([config isKindOfClass:[NSDictionary class]]) [self updateDashboardWithConfiguration:config];
    }
}

#pragma mark - Heartbeat

- (void)startHeartbeatMonitor {
    [self stopHeartbeatMonitor];
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(heartbeatTick) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.heartbeatTimer forMode:NSRunLoopCommonModes];
    _connectionLabel.text = @"● SECURE";
    _connectionLabel.textColor = [ZXTheme success];
}

- (void)stopHeartbeatMonitor { [self.heartbeatTimer invalidate]; self.heartbeatTimer = nil; }

- (void)heartbeatTick {
    if (self.currentState != ZXAppStateDashboard) return;
    if (![self.delegate respondsToSelector:@selector(zentraxDidRequestSessionVerificationWithCompletion:)]) return;
    __weak typeof(self) weakSelf = self;
    [self.delegate zentraxDidRequestSessionVerificationWithCompletion:^(BOOL valid) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf; if (!self) return;
            if (!valid) [self handleRevokedSessionEnvironment];
            else { self.connectionLabel.text = @"● SECURE"; self.connectionLabel.textColor = [ZXTheme success]; }
        });
    }];
}

- (void)handleRevokedSessionEnvironment {
    [self stopHeartbeatMonitor];
    _connectionLabel.text = @"● OFFLINE"; _connectionLabel.textColor = [ZXTheme error];
    for (NSString *fid in self.functionControls) ((UIControl *)self.functionControls[fid]).userInteractionEnabled = NO;
    [self showGlobalErrorWithTitle:@"SESSION ENDED" message:@"Your secure session is no longer valid. Please authenticate again."];
    __weak typeof(self) weakSelf = self;
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) {
        [self.delegate zentraxDidRequestLogoutWithCompletion:^{ dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf showLoginScreen]; }); }];
    } else [self showLoginScreen];
}

#pragma mark - Settings

- (void)setupSettingsScreen {
    _settingsContainer = [[UIView alloc] init];
    _settingsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_settingsContainer];
    [NSLayoutConstraint activateConstraints:@[
        [_settingsContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [_settingsContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor], [_settingsContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor], [_settingsContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UIView *header = [[UIView alloc] init]; header.translatesAutoresizingMaskIntoConstraints = NO; [_settingsContainer addSubview:header];
    UIButton *back = [self iconButton:@"chevron.left" size:34]; back.backgroundColor = [ZXTheme surfaceRaised]; back.layer.cornerRadius = 12; [back addTarget:self action:@selector(closeSettings) forControlEvents:UIControlEventTouchUpInside]; [header addSubview:back];
    _settingsTitle = [self label:@"Settings" size:24 weight:UIFontWeightBlack color:[ZXTheme primaryText]]; _settingsTitle.translatesAutoresizingMaskIntoConstraints = NO; [header addSubview:_settingsTitle];
    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:_settingsContainer.leadingAnchor constant:20], [header.trailingAnchor constraintEqualToAnchor:_settingsContainer.trailingAnchor constant:-20], [header.topAnchor constraintEqualToAnchor:_settingsContainer.safeAreaLayoutGuide.topAnchor constant:8], [header.heightAnchor constraintEqualToConstant:44],
        [back.leadingAnchor constraintEqualToAnchor:header.leadingAnchor], [back.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [_settingsTitle.leadingAnchor constraintEqualToAnchor:back.trailingAnchor constant:13], [_settingsTitle.centerYAnchor constraintEqualToAnchor:header.centerYAnchor], [_settingsTitle.trailingAnchor constraintLessThanOrEqualToAnchor:header.trailingAnchor]
    ]];

    _settingsScroll = [[UIScrollView alloc] init]; _settingsScroll.showsVerticalScrollIndicator = NO; _settingsScroll.translatesAutoresizingMaskIntoConstraints = NO; [_settingsContainer addSubview:_settingsScroll];
    _settingsStack = [[UIStackView alloc] init]; _settingsStack.axis = UILayoutConstraintAxisVertical; _settingsStack.spacing = 12; _settingsStack.translatesAutoresizingMaskIntoConstraints = NO; [_settingsScroll addSubview:_settingsStack];
    [NSLayoutConstraint activateConstraints:@[
        [_settingsScroll.leadingAnchor constraintEqualToAnchor:_settingsContainer.leadingAnchor constant:20], [_settingsScroll.trailingAnchor constraintEqualToAnchor:_settingsContainer.trailingAnchor constant:-20], [_settingsScroll.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:14], [_settingsScroll.bottomAnchor constraintEqualToAnchor:_settingsContainer.safeAreaLayoutGuide.bottomAnchor constant:-10],
        [_settingsStack.leadingAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.leadingAnchor], [_settingsStack.trailingAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.trailingAnchor], [_settingsStack.topAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.topAnchor], [_settingsStack.bottomAnchor constraintEqualToAnchor:_settingsScroll.contentLayoutGuide.bottomAnchor], [_settingsStack.widthAnchor constraintEqualToAnchor:_settingsScroll.frameLayoutGuide.widthAnchor]
    ]];
    [self rebuildSettings];
}

- (UIView *)settingsRow:(NSString *)title subtitle:(NSString *)subtitle icon:(NSString *)iconName action:(SEL)action accessory:(UIView *)accessory {
    UIView *row = [[UIView alloc] init]; row.backgroundColor = [ZXTheme surface]; row.layer.cornerRadius = 18; row.layer.borderWidth = 1; row.layer.borderColor = [ZXTheme border].CGColor; row.translatesAutoresizingMaskIntoConstraints = NO; [row.heightAnchor constraintGreaterThanOrEqualToConstant:72].active = YES;
    UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:iconName]]; iv.tintColor = [ZXTheme primaryText]; iv.translatesAutoresizingMaskIntoConstraints = NO; [row addSubview:iv];
    UILabel *t = [self label:title size:14 weight:UIFontWeightSemibold color:[ZXTheme primaryText]]; t.translatesAutoresizingMaskIntoConstraints = NO; [row addSubview:t];
    UILabel *s = [self label:subtitle size:10 weight:UIFontWeightRegular color:[ZXTheme mutedText]]; s.translatesAutoresizingMaskIntoConstraints = NO; [row addSubview:s];
    [NSLayoutConstraint activateConstraints:@[[iv.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:16],[iv.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],[iv.widthAnchor constraintEqualToConstant:22],[iv.heightAnchor constraintEqualToConstant:22],[t.leadingAnchor constraintEqualToAnchor:iv.trailingAnchor constant:13],[t.topAnchor constraintEqualToAnchor:row.topAnchor constant:14],[t.trailingAnchor constraintLessThanOrEqualToAnchor:row.trailingAnchor constant:-65],[s.leadingAnchor constraintEqualToAnchor:t.leadingAnchor],[s.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:3],[s.trailingAnchor constraintLessThanOrEqualToAnchor:row.trailingAnchor constant:-65]]];
    if (accessory) { accessory.translatesAutoresizingMaskIntoConstraints = NO; [row addSubview:accessory]; [NSLayoutConstraint activateConstraints:@[[accessory.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-14],[accessory.centerYAnchor constraintEqualToAnchor:row.centerYAnchor]]]; }
    else { UIImageView *chev = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]]; chev.tintColor = [ZXTheme mutedText]; chev.translatesAutoresizingMaskIntoConstraints = NO; [row addSubview:chev]; [NSLayoutConstraint activateConstraints:@[[chev.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-17],[chev.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],[chev.widthAnchor constraintEqualToConstant:12],[chev.heightAnchor constraintEqualToConstant:16]]]; }
    if (action) { UIButton *hit = [UIButton buttonWithType:UIButtonTypeSystem]; hit.translatesAutoresizingMaskIntoConstraints = NO; [hit addTarget:self action:action forControlEvents:UIControlEventTouchUpInside]; [row addSubview:hit]; [NSLayoutConstraint activateConstraints:@[[hit.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],[hit.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],[hit.topAnchor constraintEqualToAnchor:row.topAnchor],[hit.bottomAnchor constraintEqualToAnchor:row.bottomAnchor]]]; }
    return row;
}

- (UIView *)deviceInfoCard {
    UIView *card=[self card];
    card.layer.cornerRadius=20.0;
    UILabel *eyebrow=[self label:@"DEVICE STATUS" size:9 weight:UIFontWeightBold color:[ZXTheme mutedText]];
    [ZXTheme track:eyebrow spacing:1.5]; eyebrow.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:eyebrow];
    NSString *device=[NSString stringWithFormat:@"%@",self.compatibilityData[@"device_name"] ?: self.compatibilityData[@"device"] ?: UIDevice.currentDevice.model ?: @"Unknown device"];
    NSString *ios=[NSString stringWithFormat:@"iOS %@",self.compatibilityData[@"ios_version"] ?: UIDevice.currentDevice.systemVersion ?: @"—"];
    NSString *status=[[NSString stringWithFormat:@"%@",self.compatibilityData[@"status"] ?: @"unknown"] lowercaseString];
    BOOL supported=[status isEqualToString:@"supported"];
    BOOL unsupported=[status isEqualToString:@"unsupported"];
    NSString *statusText=supported?@"SUPPORTED":(unsupported?@"UNSUPPORTED":@"NOT VERIFIED");
    UIColor *statusColor=supported?[ZXTheme success]:(unsupported?[ZXTheme error]:[ZXTheme warning]);
    UILabel *name=[self label:device size:17 weight:UIFontWeightSemibold color:[ZXTheme primaryText]]; name.translatesAutoresizingMaskIntoConstraints=NO; name.numberOfLines=2; [card addSubview:name];
    UILabel *version=[self label:ios size:11 weight:UIFontWeightMedium color:[ZXTheme secondaryText]]; version.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:version];
    UIView *pill=[[UIView alloc] init]; pill.backgroundColor=[statusColor colorWithAlphaComponent:0.12]; pill.layer.cornerRadius=9; pill.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:pill];
    UILabel *pillText=[self label:statusText size:9 weight:UIFontWeightBold color:statusColor]; [ZXTheme track:pillText spacing:1.0]; pillText.translatesAutoresizingMaskIntoConstraints=NO; [pill addSubview:pillText];
    UILabel *details=[self label:[self compatibilitySubtitle] size:10 weight:UIFontWeightRegular color:[ZXTheme mutedText]]; details.translatesAutoresizingMaskIntoConstraints=NO; details.numberOfLines=2; [card addSubview:details];
    UIButton *open=[self iconButton:@"chevron.right" size:28]; open.tintColor=[ZXTheme mutedText]; [open addTarget:self action:@selector(showDeviceCompatibilityDetails) forControlEvents:UIControlEventTouchUpInside]; [card addSubview:open];
    [NSLayoutConstraint activateConstraints:@[
        [card.heightAnchor constraintGreaterThanOrEqualToConstant:122],
        [eyebrow.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],[eyebrow.topAnchor constraintEqualToAnchor:card.topAnchor constant:15],
        [name.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],[name.topAnchor constraintEqualToAnchor:eyebrow.bottomAnchor constant:7],[name.trailingAnchor constraintLessThanOrEqualToAnchor:pill.leadingAnchor constant:-10],
        [version.leadingAnchor constraintEqualToAnchor:name.leadingAnchor],[version.topAnchor constraintEqualToAnchor:name.bottomAnchor constant:3],
        [pill.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],[pill.topAnchor constraintEqualToAnchor:card.topAnchor constant:15],[pill.heightAnchor constraintEqualToConstant:28],
        [pillText.leadingAnchor constraintEqualToAnchor:pill.leadingAnchor constant:10],[pillText.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor constant:-10],[pillText.centerYAnchor constraintEqualToAnchor:pill.centerYAnchor],
        [details.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],[details.trailingAnchor constraintEqualToAnchor:open.leadingAnchor constant:-6],[details.topAnchor constraintEqualToAnchor:version.bottomAnchor constant:9],[details.bottomAnchor constraintLessThanOrEqualToAnchor:card.bottomAnchor constant:-15],
        [open.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-12],[open.centerYAnchor constraintEqualToAnchor:details.centerYAnchor]
    ]];
    return card;
}

- (void)rebuildSettings {
    for (UIView *v in [self.settingsStack.arrangedSubviews copy]) { [self.settingsStack removeArrangedSubview:v]; [v removeFromSuperview]; }
    [self.settingsStack addArrangedSubview:[self settingsSectionLabel:@"SECURITY"]];
    UISwitch *safe = [[UISwitch alloc] init]; safe.onTintColor = [ZXTheme primaryText]; safe.thumbTintColor = [ZXTheme background]; safe.on = self.safeModeEnabled; [safe addTarget:self action:@selector(safeModeSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    self.safeModeCard = [self settingsRow:@"Safe UI Mode" subtitle:safe.isOn ? @"Protected lock screen is enabled" : @"Add a private six-digit lock screen" icon:@"lock.fill" action:nil accessory:safe];
    [self.settingsStack addArrangedSubview:self.safeModeCard];

    [self.settingsStack addArrangedSubview:[self settingsSectionLabel:@"DEVICE"]];
    self.compatibilityCard = [self deviceInfoCard];
    [self.settingsStack addArrangedSubview:self.compatibilityCard];

    [self.settingsStack addArrangedSubview:[self settingsSectionLabel:@"PREFERENCES"]];
    NSString *language = [[NSUserDefaults standardUserDefaults] stringForKey:ZXLanguageKey] ?: @"English";
    [self.settingsStack addArrangedSubview:[self settingsRow:@"Language" subtitle:language icon:@"globe" action:@selector(showLanguagePicker) accessory:nil]];
    NSString *selectedTheme=[[NSUserDefaults standardUserDefaults] stringForKey:ZXThemeKey] ?: @"Obsidian Black";
    [self.settingsStack addArrangedSubview:[self settingsRow:@"Appearance" subtitle:[NSString stringWithFormat:@"%@ • Pure black premium interface",selectedTheme] icon:@"circle.lefthalf.filled" action:@selector(showThemeInfo) accessory:nil]];

    [self.settingsStack addArrangedSubview:[self settingsSectionLabel:@"ACCOUNT"]];
    [self.settingsStack addArrangedSubview:[self settingsRow:@"Sign Out" subtitle:@"Close the current secure session" icon:@"rectangle.portrait.and.arrow.right" action:@selector(handleLogout) accessory:nil]];

    [self.settingsStack addArrangedSubview:[self settingsSectionLabel:@"ABOUT"]];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: @"—";
    UIView *about = [self settingsRow:@"ZENTRAX" subtitle:[NSString stringWithFormat:@"Version %@ • Server-authoritative security workspace", version] icon:@"shield.lefthalf.filled" action:nil accessory:nil];
    [self.settingsStack addArrangedSubview:about];
}

- (UILabel *)settingsSectionLabel:(NSString *)text {
    UILabel *l = [self label:text size:9 weight:UIFontWeightBold color:[ZXTheme mutedText]]; [ZXTheme track:l spacing:1.6]; l.translatesAutoresizingMaskIntoConstraints = NO; return l;
}

- (void)showSettings { [self showSettingsSection:nil]; }
- (void)showSettingsSection:(NSString * _Nullable)sectionIdentifier {
    if (self.safeModeEnabled && self.safeModeState != ZXSafeModeStateUnlocked) { [self showSafeModeLockScreen]; return; }
    self.settingsVisible = YES;
    [self rebuildSettings];
    [self transitionToPrimaryContainer:self.settingsContainer];
}
- (void)closeSettings { self.settingsVisible = NO; [self showDashboard]; }

- (void)safeModeSwitchChanged:(UISwitch *)sender {
    if (sender.isOn) {
        [self showSafeModeSettings];
    } else {
        sender.on=YES;
        [self requestSafeModeDisableConfirmation];
    }
}

#pragma mark - Safe UI Mode

- (void)applyInitialSafeModeState {
    self.safeModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:ZXSafeModeEnabledKey];
    self.safeModeState = self.safeModeEnabled ? ZXSafeModeStateLocked : ZXSafeModeStateOff;
}

- (void)updateSafeModeState:(ZXSafeModeState)state {
    self.safeModeState = state;
    self.safeModeEnabled = (state != ZXSafeModeStateOff);
    [[NSUserDefaults standardUserDefaults] setBool:self.safeModeEnabled forKey:ZXSafeModeEnabledKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (self.settingsVisible) [self rebuildSettings];
}

- (BOOL)keychainStorePIN:(NSString *)pin {
    NSData *data = [pin dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *query = @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrService:ZXSafeModePasscodeService, (__bridge id)kSecAttrAccount:ZXSafeModePasscodeAccount};
    SecItemDelete((__bridge CFDictionaryRef)query);
    NSMutableDictionary *add = [query mutableCopy]; add[(__bridge id)kSecValueData] = data; add[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
    return SecItemAdd((__bridge CFDictionaryRef)add, NULL) == errSecSuccess;
}

- (NSString *)keychainPIN {
    NSDictionary *q = @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrService:ZXSafeModePasscodeService, (__bridge id)kSecAttrAccount:ZXSafeModePasscodeAccount, (__bridge id)kSecReturnData:@YES, (__bridge id)kSecMatchLimit:(__bridge id)kSecMatchLimitOne};
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)q, &result);
    if (status != errSecSuccess || !result) return nil;
    NSData *data = CFBridgingRelease(result);
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (void)showSafeModeSettings {
    if (self.safeModeEnabled) { [self showSafeModeLockScreen]; return; }
    self.safeModeCreatingPasscode = YES;
    self.pendingSafeModePasscode = nil;
    [self updateSafeModeState:ZXSafeModeStateOff];
    [self showSafeModeLockScreen];
}

- (void)setupSafeModeLock {
    _safeLockContainer = [[UIView alloc] init]; _safeLockContainer.translatesAutoresizingMaskIntoConstraints = NO; [self.view addSubview:_safeLockContainer];
    [NSLayoutConstraint activateConstraints:@[[_safeLockContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],[_safeLockContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],[_safeLockContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],[_safeLockContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]]];

    _safeLockBackButton = [self iconButton:@"chevron.left" size:34]; _safeLockBackButton.backgroundColor = [ZXTheme surfaceRaised]; _safeLockBackButton.layer.cornerRadius = 12; _safeLockBackButton.hidden = YES; [_safeLockBackButton addTarget:self action:@selector(cancelSafeModeCreation) forControlEvents:UIControlEventTouchUpInside]; [_safeLockContainer addSubview:_safeLockBackButton];
    [NSLayoutConstraint activateConstraints:@[[_safeLockBackButton.leadingAnchor constraintEqualToAnchor:_safeLockContainer.safeAreaLayoutGuide.leadingAnchor constant:20],[_safeLockBackButton.topAnchor constraintEqualToAnchor:_safeLockContainer.safeAreaLayoutGuide.topAnchor constant:8]]];

    UIImageView *logo = [[UIImageView alloc] initWithImage:[self safeModeLogoImage]]; logo.contentMode = UIViewContentModeScaleAspectFit; logo.layer.cornerRadius = 24; logo.clipsToBounds = YES; logo.translatesAutoresizingMaskIntoConstraints = NO; [_safeLockContainer addSubview:logo];
    _safeLockTitle = [self label:@"Enter passcode" size:27 weight:UIFontWeightSemibold color:[ZXTheme primaryText]]; _safeLockTitle.textAlignment = NSTextAlignmentCenter; _safeLockTitle.translatesAutoresizingMaskIntoConstraints = NO; [_safeLockContainer addSubview:_safeLockTitle];
    _safeLockSubtitle = [self label:@"" size:1 weight:UIFontWeightRegular color:[UIColor clearColor]]; _safeLockSubtitle.textAlignment = NSTextAlignmentCenter; _safeLockSubtitle.translatesAutoresizingMaskIntoConstraints = NO; [_safeLockContainer addSubview:_safeLockSubtitle];
    _safePinError = [self label:@"" size:12 weight:UIFontWeightMedium color:[ZXTheme error]]; _safePinError.textAlignment = NSTextAlignmentCenter; _safePinError.translatesAutoresizingMaskIntoConstraints = NO; [_safeLockContainer addSubview:_safePinError];

    _pinBoxes = [[UIStackView alloc] init]; _pinBoxes.axis = UILayoutConstraintAxisHorizontal; _pinBoxes.spacing = 10; _pinBoxes.distribution = UIStackViewDistributionFillEqually; _pinBoxes.translatesAutoresizingMaskIntoConstraints = NO; [_safeLockContainer addSubview:_pinBoxes];
    for (NSInteger i=0;i<6;i++) { UIView *box = [[UIView alloc] init]; box.layer.cornerRadius=15; box.layer.borderWidth=1.2; box.layer.borderColor=[UIColor colorWithWhite:0.20 alpha:1].CGColor; box.backgroundColor=[UIColor colorWithWhite:0.025 alpha:1]; box.tag=7000+i; [_pinBoxes addArrangedSubview:box]; [box.heightAnchor constraintEqualToConstant:66].active=YES; }

    _keypadView = [[UIView alloc] init]; _keypadView.backgroundColor=[UIColor colorWithWhite:0.075 alpha:1]; _keypadView.layer.cornerRadius=42; _keypadView.layer.maskedCorners=kCALayerMinXMinYCorner|kCALayerMaxXMinYCorner; _keypadView.layer.borderWidth=1; _keypadView.layer.borderColor=[UIColor colorWithWhite:0.19 alpha:1].CGColor; _keypadView.clipsToBounds=YES; _keypadView.translatesAutoresizingMaskIntoConstraints = NO; [_safeLockContainer addSubview:_keypadView];
    [self buildSafeKeypad];
    _safeModeFooter = [self label:@"" size:1 weight:UIFontWeightRegular color:[UIColor clearColor]]; _safeModeFooter.hidden=YES; _safeModeFooter.translatesAutoresizingMaskIntoConstraints = NO; [_safeLockContainer addSubview:_safeModeFooter];

    [NSLayoutConstraint activateConstraints:@[
        [logo.centerXAnchor constraintEqualToAnchor:_safeLockContainer.centerXAnchor], [logo.topAnchor constraintEqualToAnchor:_safeLockContainer.safeAreaLayoutGuide.topAnchor constant:92], [logo.widthAnchor constraintEqualToConstant:58], [logo.heightAnchor constraintEqualToConstant:58],
        [NSLayoutConstraint constraintWithItem:_safeLockTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_safeLockContainer attribute:NSLayoutAttributeCenterY multiplier:0.66 constant:0.0], [_safeLockTitle.leadingAnchor constraintEqualToAnchor:_safeLockContainer.leadingAnchor constant:24], [_safeLockTitle.trailingAnchor constraintEqualToAnchor:_safeLockContainer.trailingAnchor constant:-24],
        [_safeLockSubtitle.topAnchor constraintEqualToAnchor:_safeLockTitle.bottomAnchor constant:1], [_safeLockSubtitle.leadingAnchor constraintEqualToAnchor:_safeLockContainer.leadingAnchor constant:24], [_safeLockSubtitle.trailingAnchor constraintEqualToAnchor:_safeLockContainer.trailingAnchor constant:-24],
        [_safePinError.topAnchor constraintEqualToAnchor:_safeLockSubtitle.bottomAnchor constant:1], [_safePinError.leadingAnchor constraintEqualToAnchor:_safeLockContainer.leadingAnchor constant:24], [_safePinError.trailingAnchor constraintEqualToAnchor:_safeLockContainer.trailingAnchor constant:-24],
        [_pinBoxes.topAnchor constraintEqualToAnchor:_safePinError.bottomAnchor constant:18], [_pinBoxes.leadingAnchor constraintEqualToAnchor:_safeLockContainer.leadingAnchor constant:50], [_pinBoxes.trailingAnchor constraintEqualToAnchor:_safeLockContainer.trailingAnchor constant:-50],
        [_keypadView.leadingAnchor constraintEqualToAnchor:_safeLockContainer.leadingAnchor], [_keypadView.trailingAnchor constraintEqualToAnchor:_safeLockContainer.trailingAnchor], [_keypadView.bottomAnchor constraintEqualToAnchor:_safeLockContainer.bottomAnchor], [_keypadView.heightAnchor constraintEqualToConstant:420],
        [_safeModeFooter.bottomAnchor constraintEqualToAnchor:_keypadView.topAnchor], [_safeModeFooter.leadingAnchor constraintEqualToAnchor:_safeLockContainer.leadingAnchor], [_safeModeFooter.trailingAnchor constraintEqualToAnchor:_safeLockContainer.trailingAnchor]
    ]];
}

- (void)buildSafeKeypad {
    NSArray *titles = @[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"",@"0",@"⌫"];
    UIStackView *rows = [[UIStackView alloc] init];
    rows.axis = UILayoutConstraintAxisVertical;
    rows.spacing = 10;
    rows.distribution = UIStackViewDistributionFillEqually;
    rows.translatesAutoresizingMaskIntoConstraints = NO;
    [_keypadView addSubview:rows];
    [NSLayoutConstraint activateConstraints:@[[rows.leadingAnchor constraintEqualToAnchor:_keypadView.leadingAnchor constant:10],[rows.trailingAnchor constraintEqualToAnchor:_keypadView.trailingAnchor constant:-10],[rows.topAnchor constraintEqualToAnchor:_keypadView.topAnchor constant:18],[rows.bottomAnchor constraintEqualToAnchor:_keypadView.bottomAnchor constant:-18]]];

    for (NSInteger rowIndex=0; rowIndex<4; rowIndex++) {
        UIStackView *row = [[UIStackView alloc] init];
        row.axis = UILayoutConstraintAxisHorizontal;
        row.spacing = 10;
        row.distribution = UIStackViewDistributionFillEqually;
        [rows addArrangedSubview:row];
        for (NSInteger col=0; col<3; col++) {
            NSInteger idx=rowIndex*3+col;
            UIButton *button=[UIButton buttonWithType:UIButtonTypeSystem];
            NSString *title=titles[idx];
            [button setTitle:title forState:UIControlStateNormal];
            button.titleLabel.font=[ZXTheme body:(idx==11?26:29) weight:UIFontWeightMedium];
            [button setTitleColor:[ZXTheme primaryText] forState:UIControlStateNormal];
            button.backgroundColor=[UIColor colorWithWhite:0.105 alpha:1];
            button.layer.cornerRadius=16;
            button.layer.borderWidth=1;
            button.layer.borderColor=[UIColor colorWithWhite:0.17 alpha:1].CGColor;
            button.tag=8000+idx;
            button.translatesAutoresizingMaskIntoConstraints=NO;
            if (idx==9) { button.alpha=0; button.userInteractionEnabled=NO; }
            else [button addTarget:self action:@selector(safeKeypadPressed:) forControlEvents:UIControlEventTouchUpInside];
            [row addArrangedSubview:button];
        }
    }
}

- (void)showSafeModeLockScreen {
    self.enteredPIN.string = @"";
    self.safeModeAttemptsRemaining = ZXMaxPINAttempts;
    self.safePinError.text = @"";
    [self updatePINBoxes];
    self.safeLockTitle.text = self.safeModeCreatingPasscode ? @"Create Passcode" : @"Enter passcode";
    self.safeLockSubtitle.text = self.safeModeCreatingPasscode ? @"Create a 6-digit private passcode" : @"Enter passcode";
    self.safeLockBackButton.hidden = !self.safeModeCreatingPasscode;
    [self transitionToPrimaryContainer:self.safeLockContainer];
    self.currentState = ZXAppStateStartupBlock;
}

- (BOOL)safeModeCreatingPasscode { return _safeModeCreatingPasscode; }

- (NSString *)safeModeDisplayName {
    NSString *name = [[NSUserDefaults standardUserDefaults] stringForKey:ZXSafeModeNameKey];
    return name.length ? name : @"Private Space";
}

- (UIImage *)safeModeLogoImage {
    NSString *asset = [[NSUserDefaults standardUserDefaults] stringForKey:ZXSafeModeLogoKey];
    UIImage *image = asset.length ? [UIImage imageNamed:asset] : nil;
    return image ?: [self preferredLogoImage];
}

- (void)updatePINBoxes {
    for (NSInteger i=0;i<6;i++) {
        UIView *box = [self.pinBoxes.arrangedSubviews objectAtIndex:i];
        box.layer.borderColor = (i < self.enteredPIN.length ? [ZXTheme primaryText] : [UIColor colorWithWhite:0.20 alpha:1]).CGColor;
        for (UIView *sub in [box.subviews copy]) [sub removeFromSuperview];
        if (i < self.enteredPIN.length) {
            UILabel *dot = [self label:@"●" size:15 weight:UIFontWeightBold color:[ZXTheme primaryText]]; dot.textAlignment=NSTextAlignmentCenter; dot.translatesAutoresizingMaskIntoConstraints=NO; [box addSubview:dot]; [NSLayoutConstraint activateConstraints:@[[dot.centerXAnchor constraintEqualToAnchor:box.centerXAnchor],[dot.centerYAnchor constraintEqualToAnchor:box.centerYAnchor]]];
        }
    }
}

- (void)safeKeypadPressed:(UIButton *)button {
    NSInteger idx = button.tag - 8000;
    if (idx == 11) {
        if (self.enteredPIN.length) [self.enteredPIN deleteCharactersInRange:NSMakeRange(self.enteredPIN.length-1,1)];
        [self updatePINBoxes]; return;
    }
    if (idx == 9 || self.enteredPIN.length >= 6) return;
    NSString *digit = [NSString stringWithFormat:@"%ld", (long)(idx+1)];
    if (idx == 10) digit = @"0";
    [self.enteredPIN appendString:digit];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [self updatePINBoxes];
    if (self.enteredPIN.length == 6) [self processEnteredPIN];
}

- (void)processEnteredPIN {
    if (self.safeModeCreatingPasscode) {
        if (!self.pendingSafeModePasscode.length) {
            self.pendingSafeModePasscode = [self.enteredPIN copy];
            self.enteredPIN.string = @"";
            self.safeLockTitle.text = @"Confirm Passcode";
            self.safeLockSubtitle.text = @"Enter the same 6-digit passcode again";
            [self updatePINBoxes];
            return;
        }
        if (![self.pendingSafeModePasscode isEqualToString:self.enteredPIN]) {
            self.safePinError.text = @"Passcodes do not match. Try again.";
            self.pendingSafeModePasscode = nil;
            self.enteredPIN.string = @"";
            [self updatePINBoxes];
            [self shakePINBoxes];
            return;
        }
        if (![self keychainStorePIN:self.enteredPIN]) {
            self.safePinError.text = @"Unable to securely store passcode.";
            return;
        }
        self.safeModeCreatingPasscode = NO;
        self.pendingSafeModePasscode = nil;
        [self updateSafeModeState:ZXSafeModeStateUnlocked];
        [self showToast:@"Safe UI Mode enabled" success:YES];
        [self showDashboard];
        return;
    }

    NSString *saved = [self keychainPIN];
    if (saved.length && [saved isEqualToString:self.enteredPIN]) {
        if (self.safeModeDisabling) {
            self.safeModeDisabling = NO;
            [self actuallyDisableSafeMode];
        } else {
            [self updateSafeModeState:ZXSafeModeStateUnlocked];
            [self showToast:@"Private space unlocked" success:YES];
            [self showDashboard];
        }
        return;
    }
    self.safeModeAttemptsRemaining = MAX(0, self.safeModeAttemptsRemaining - 1);
    self.safePinError.text = self.safeModeAttemptsRemaining > 0 ? [NSString stringWithFormat:@"Incorrect passcode • %ld attempts remaining", (long)self.safeModeAttemptsRemaining] : @"Incorrect passcode";
    self.enteredPIN.string = @"";
    [self updatePINBoxes];
    [self shakePINBoxes];
}

- (void)shakePINBoxes {
    [UIView animateKeyframesWithDuration:0.35 delay:0 options:0 animations:^{
        self.pinBoxes.transform = CGAffineTransformMakeTranslation(-9,0);
        [UIView addKeyframeWithRelativeStartTime:0.20 relativeDuration:0.25 animations:^{ self.pinBoxes.transform = CGAffineTransformMakeTranslation(9,0); }];
        [UIView addKeyframeWithRelativeStartTime:0.45 relativeDuration:0.25 animations:^{ self.pinBoxes.transform = CGAffineTransformIdentity; }];
    } completion:nil];
    [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeError];
}

- (void)lockSafeMode {
    if (!self.safeModeEnabled) return;
    [self updateSafeModeState:ZXSafeModeStateLocked];
    [self showSafeModeLockScreen];
}

- (void)unlockSafeMode {
    if (!self.safeModeEnabled) return;
    [self updateSafeModeState:ZXSafeModeStateUnlocked];
}

- (void)cancelSafeModeCreation {
    self.safeModeCreatingPasscode = NO;
    self.safeModeDisabling = NO;
    self.pendingSafeModePasscode = nil;
    self.enteredPIN.string = @"";
    [self updateSafeModeState:ZXSafeModeStateOff];
    [self showSettings];
}

- (void)requestSafeModeDisableConfirmation {
    [self showCustomConfirmationWithTitle:@"Disable Safe UI Mode?" message:@"Enter your current passcode to disable private lock protection." confirmTitle:@"VERIFY" completion:^{ [self beginDisableSafeModeVerification]; }];
}

- (void)beginDisableSafeModeVerification {
    self.safeModeCreatingPasscode = NO;
    self.safeModeDisabling = YES;
    self.safeModeEnabled = YES;
    self.safeModeState = ZXSafeModeStateLocked;
    [self showSafeModeLockScreen];
    self.safeLockTitle.text = @"Disable Safe UI Mode";
    self.safeLockSubtitle.text = @"Enter your current passcode";
    __weak typeof(self) weakSelf = self;
    objc_setAssociatedObject(self.safeLockContainer, @selector(beginDisableSafeModeVerification), ^{ [weakSelf actuallyDisableSafeMode]; }, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)actuallyDisableSafeMode {
    self.safeModeDisabling = NO;
    SecItemDelete((__bridge CFDictionaryRef)@{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,(__bridge id)kSecAttrService:ZXSafeModePasscodeService,(__bridge id)kSecAttrAccount:ZXSafeModePasscodeAccount});
    [self updateSafeModeState:ZXSafeModeStateOff];
    [self showDashboard];
}

#pragma mark - Device Compatibility

- (void)updateDeviceCompatibility:(NSDictionary *)compatibility {
    if (![compatibility isKindOfClass:[NSDictionary class]]) return;
    self.compatibilityData = compatibility;
    if (self.settingsVisible) [self rebuildSettings];
}

- (NSString *)compatibilitySubtitle {
    NSString *status = [[NSString stringWithFormat:@"%@", self.compatibilityData[@"status"] ?: @"unknown"] lowercaseString];
    if ([status isEqualToString:@"supported"]) return @"Supported on this device";
    if ([status isEqualToString:@"unsupported"]) {
        id reason=self.compatibilityData[@"reason"];
        NSString *safeReason=[reason isKindOfClass:[NSString class]] && [reason length] ? reason : @"Server policy";
        return [NSString stringWithFormat:@"Unsupported • %@",safeReason];
    }
    return @"Check device, iOS and architecture support";
}

- (void)showDeviceCompatibilityDetails {
    NSString *device = [NSString stringWithFormat:@"%@", self.compatibilityData[@"device_name"] ?: self.compatibilityData[@"device"] ?: UIDevice.currentDevice.model];
    NSString *ios = [NSString stringWithFormat:@"%@", self.compatibilityData[@"ios_version"] ?: UIDevice.currentDevice.systemVersion];
    NSString *arch = [NSString stringWithFormat:@"%@", self.compatibilityData[@"architecture"] ?: @"—"];
    NSString *app = [NSString stringWithFormat:@"%@", self.compatibilityData[@"app_version"] ?: ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"—")];
    NSString *required = [NSString stringWithFormat:@"%@", self.compatibilityData[@"required_ios_version"] ?: @"—"];
    NSString *status = [NSString stringWithFormat:@"%@", self.compatibilityData[@"status"] ?: @"UNKNOWN"];
    NSString *reason = [NSString stringWithFormat:@"%@", self.compatibilityData[@"reason"] ?: @"No additional restriction reported."];
    NSString *message = [NSString stringWithFormat:@"Device   %@\n\niOS      %@\n\nArch     %@\n\nApp      %@\n\nRequired %@\n\nStatus   %@\n\n%@",device,ios,arch,app,required,status,reason];
    [self showCustomConfirmationWithTitle:@"DEVICE COMPATIBILITY" message:message confirmTitle:@"RECHECK" completion:^{ [self requestDeviceCompatibilityRecheck]; }];
}

- (void)requestDeviceCompatibilityRecheck {
    [self showGlobalLoadingState:@"CHECKING DEVICE"];
    if ([self.delegate respondsToSelector:@selector(zentraxDidRequestCompatibilityRecheckWithCompletion:)]) {
        __weak typeof(self) weakSelf = self;
        [self.delegate zentraxDidRequestCompatibilityRecheckWithCompletion:^(BOOL success, NSDictionary *compatibility, NSString *errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf; if (!self) return;
                [self hideGlobalLoadingState];
                if (success) { [self updateDeviceCompatibility:compatibility ?: @{}]; [self showSuccessMessage:@"COMPATIBILITY VERIFIED" message:[self compatibilitySubtitle]]; }
                else [self showGlobalErrorWithTitle:@"COMPATIBILITY CHECK FAILED" message:errorMsg ?: @"Unable to verify device compatibility."];
            });
        }];
    } else {
        [self hideGlobalLoadingState];
        [self showGlobalErrorWithTitle:@"UNAVAILABLE" message:@"Compatibility service is not connected."];
    }
}

#pragma mark - Global Loading / Toast / Modal

- (void)setupGlobalLoading {
    _globalLoadingOverlay = [[UIView alloc] initWithFrame:self.view.bounds];
    _globalLoadingOverlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.72];
    _globalLoadingOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _globalLoadingOverlay.hidden = YES;
    _globalLoadingOverlay.layer.zPosition = 10000;
    [self.view addSubview:_globalLoadingOverlay];
    UIView *card = [self card]; card.backgroundColor=[ZXTheme surfaceRaised]; [_globalLoadingOverlay addSubview:card];
    _globalSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium]; _globalSpinner.color=[ZXTheme primaryText]; _globalSpinner.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:_globalSpinner];
    _globalLoadingTitle=[self label:@"SECURE OPERATION" size:14 weight:UIFontWeightSemibold color:[ZXTheme primaryText]]; _globalLoadingTitle.textAlignment=NSTextAlignmentCenter; _globalLoadingTitle.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:_globalLoadingTitle];
    _globalLoadingDetail=[self label:@"Please wait…" size:10 weight:UIFontWeightRegular color:[ZXTheme mutedText]]; _globalLoadingDetail.textAlignment=NSTextAlignmentCenter; _globalLoadingDetail.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:_globalLoadingDetail];
    [NSLayoutConstraint activateConstraints:@[[card.centerXAnchor constraintEqualToAnchor:_globalLoadingOverlay.centerXAnchor],[card.centerYAnchor constraintEqualToAnchor:_globalLoadingOverlay.centerYAnchor],[card.widthAnchor constraintEqualToConstant:250],[card.heightAnchor constraintEqualToConstant:142],[_globalSpinner.topAnchor constraintEqualToAnchor:card.topAnchor constant:25],[_globalSpinner.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],[_globalLoadingTitle.topAnchor constraintEqualToAnchor:_globalSpinner.bottomAnchor constant:15],[_globalLoadingTitle.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:15],[_globalLoadingTitle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-15],[_globalLoadingDetail.topAnchor constraintEqualToAnchor:_globalLoadingTitle.bottomAnchor constant:5],[_globalLoadingDetail.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:15],[_globalLoadingDetail.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-15]]];
}

- (void)showGlobalLoadingState:(NSString *)message { dispatch_async(dispatch_get_main_queue(), ^{ self.globalLoadingOverlay.hidden=NO; self.globalLoadingOverlay.alpha=0; self.globalLoadingTitle.text=message.length?message:@"SECURE OPERATION"; [self.globalSpinner startAnimating]; [UIView animateWithDuration:0.18 animations:^{ self.globalLoadingOverlay.alpha=1; }]; }); }
- (void)updateGlobalLoadingMessage:(NSString *)message { dispatch_async(dispatch_get_main_queue(), ^{ self.globalLoadingDetail.text=message ?: @"Please wait…"; }); }
- (void)hideGlobalLoadingState { dispatch_async(dispatch_get_main_queue(), ^{ [self.globalSpinner stopAnimating]; [UIView animateWithDuration:0.16 animations:^{ self.globalLoadingOverlay.alpha=0; } completion:^(BOOL finished){ self.globalLoadingOverlay.hidden=YES; }]; }); }

- (void)showToast:(NSString *)message { [self showToast:message success:YES]; }
- (void)showToast:(NSString *)message success:(BOOL)success {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.toastView) [self.toastView removeFromSuperview];
        UIView *toast = [[UIView alloc] init]; toast.backgroundColor=[ZXTheme surfaceRaised]; toast.layer.cornerRadius=16; toast.layer.borderWidth=1; toast.layer.borderColor=(success?[ZXTheme success]:[ZXTheme error]).CGColor; toast.translatesAutoresizingMaskIntoConstraints=NO; [self.view addSubview:toast]; self.toastView=toast;
        UILabel *dot=[self label:success?@"✓":@"!" size:12 weight:UIFontWeightBlack color:success?[ZXTheme success]:[ZXTheme error]]; dot.textAlignment=NSTextAlignmentCenter; dot.translatesAutoresizingMaskIntoConstraints=NO; [toast addSubview:dot];
        UILabel *text=[self label:message ?: @"" size:12 weight:UIFontWeightSemibold color:[ZXTheme primaryText]]; text.translatesAutoresizingMaskIntoConstraints=NO; [toast addSubview:text];
        [NSLayoutConstraint activateConstraints:@[[toast.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],[toast.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12],[toast.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24],[toast.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24],[toast.heightAnchor constraintEqualToConstant:54],[dot.leadingAnchor constraintEqualToAnchor:toast.leadingAnchor constant:15],[dot.centerYAnchor constraintEqualToAnchor:toast.centerYAnchor],[dot.widthAnchor constraintEqualToConstant:20],[text.leadingAnchor constraintEqualToAnchor:dot.trailingAnchor constant:8],[text.trailingAnchor constraintEqualToAnchor:toast.trailingAnchor constant:-15],[text.centerYAnchor constraintEqualToAnchor:toast.centerYAnchor]]];
        toast.alpha=0; toast.transform=CGAffineTransformMakeTranslation(0,-10); [UIView animateWithDuration:0.28 animations:^{toast.alpha=1;toast.transform=CGAffineTransformIdentity;}];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(2.5*NSEC_PER_SEC)),dispatch_get_main_queue(),^{if(self.toastView==toast){[UIView animateWithDuration:0.2 animations:^{toast.alpha=0;} completion:^(BOOL f){[toast removeFromSuperview];self.toastView=nil;}];}});
    });
}

- (void)showGlobalErrorWithTitle:(NSString *)title message:(NSString *)message { [self showCustomConfirmationWithTitle:title message:message confirmTitle:@"DISMISS" completion:nil]; }
- (void)showSuccessMessage:(NSString *)title message:(NSString *)message { [self showCustomConfirmationWithTitle:title message:message confirmTitle:@"CONTINUE" completion:nil]; }
- (void)showNetworkError { [self showGlobalErrorWithTitle:@"CONNECTION ERROR" message:@"Network connection lost. Try again when the secure node is reachable."]; }
- (void)showServerError { [self showGlobalErrorWithTitle:@"SERVER ERROR" message:@"The ZENTRAX server could not complete the request."]; }
- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds { [self showGlobalErrorWithTitle:@"RATE LIMITED" message:[NSString stringWithFormat:@"Request limit reached. Try again in %ld seconds.",(long)MAX(0,seconds)]]; }

- (void)showCustomConfirmationWithTitle:(NSString *)title message:(NSString *)message confirmTitle:(NSString *)confirmTitle completion:(void (^)(void))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *overlay=[[UIView alloc] initWithFrame:self.view.bounds]; overlay.backgroundColor=[[UIColor blackColor] colorWithAlphaComponent:0.78]; overlay.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight; overlay.tag=440044; [self.view addSubview:overlay];
        UIView *card=[self card]; [overlay addSubview:card];
        UILabel *t=[self label:title.uppercaseString size:16 weight:UIFontWeightBold color:[ZXTheme primaryText]]; [ZXTheme track:t spacing:1.0]; t.textAlignment=NSTextAlignmentCenter; t.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:t];
        UILabel *m=[self label:message ?: @"" size:12 weight:UIFontWeightRegular color:[ZXTheme secondaryText]]; m.textAlignment=NSTextAlignmentCenter; m.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:m];
        UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem]; [self styleSecondaryButton:b]; [b setTitle:confirmTitle ?: @"DISMISS" forState:UIControlStateNormal]; b.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:b];
        UIButton *x=[UIButton buttonWithType:UIButtonTypeSystem]; [x setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal]; x.tintColor=[ZXTheme mutedText]; x.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:x];
        objc_setAssociatedObject(b,@selector(showCustomConfirmationWithTitle:message:confirmTitle:completion:),overlay,OBJC_ASSOCIATION_RETAIN_NONATOMIC); objc_setAssociatedObject(b,@selector(showCustomConfirmationWithTitle:message:confirmTitle:completion:),completion,OBJC_ASSOCIATION_COPY_NONATOMIC);
        // Store both overlay and callback in a tiny holder to avoid selector-specific global state.
        NSDictionary *holder=@{ @"overlay":overlay, @"completion":completion ?: ^{} }; objc_setAssociatedObject(b,@selector(showGlobalErrorWithTitle:message:),holder,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [b addTarget:self action:@selector(customModalConfirm:) forControlEvents:UIControlEventTouchUpInside]; [x addTarget:self action:@selector(customModalDismiss:) forControlEvents:UIControlEventTouchUpInside]; objc_setAssociatedObject(x,@selector(customModalDismiss:),overlay,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [NSLayoutConstraint activateConstraints:@[[card.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],[card.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],[card.leadingAnchor constraintEqualToAnchor:overlay.leadingAnchor constant:30],[card.trailingAnchor constraintEqualToAnchor:overlay.trailingAnchor constant:-30],[x.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],[x.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-12],[x.widthAnchor constraintEqualToConstant:30],[x.heightAnchor constraintEqualToConstant:30],[t.topAnchor constraintEqualToAnchor:card.topAnchor constant:28],[t.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],[t.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],[m.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:10],[m.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],[m.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],[b.topAnchor constraintEqualToAnchor:m.bottomAnchor constant:22],[b.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],[b.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],[b.heightAnchor constraintEqualToConstant:48],[b.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-24]]];
        overlay.alpha=0; card.transform=CGAffineTransformMakeScale(0.96,0.96); [UIView animateWithDuration:0.28 animations:^{overlay.alpha=1;card.transform=CGAffineTransformIdentity;}];
    });
}

- (void)customModalConfirm:(UIButton *)button {
    NSDictionary *holder=objc_getAssociatedObject(button,@selector(showGlobalErrorWithTitle:message:)); UIView *overlay=holder[@"overlay"]; void (^completion)(void)=holder[@"completion"];
    [UIView animateWithDuration:0.16 animations:^{overlay.alpha=0;} completion:^(BOOL f){[overlay removeFromSuperview];if(completion)completion();}];
}
- (void)customModalDismiss:(UIButton *)button { UIView *overlay=objc_getAssociatedObject(button,@selector(customModalDismiss:)); [UIView animateWithDuration:0.16 animations:^{overlay.alpha=0;} completion:^(BOOL f){[overlay removeFromSuperview];}]; }

#pragma mark - Logout / Navigation

- (void)handleLogout {
    __weak typeof(self) weakSelf = self;
    [self showCustomConfirmationWithTitle:@"SIGN OUT?" message:@"Your current secure session will be closed. You can authenticate again at any time." confirmTitle:@"SIGN OUT" completion:^{
        __strong typeof(weakSelf) self=weakSelf; if(!self)return;
        if ([self.delegate respondsToSelector:@selector(zentraxDidRequestLogoutWithCompletion:)]) [self.delegate zentraxDidRequestLogoutWithCompletion:^{ dispatch_async(dispatch_get_main_queue(), ^{ [[NSUserDefaults standardUserDefaults] removeObjectForKey:ZXLastKey]; [self showLoginScreen]; }); }];
        else { [[NSUserDefaults standardUserDefaults] removeObjectForKey:ZXLastKey]; [self showLoginScreen]; }
    }];
}

- (void)resetToStartup {
    self.hasStarted = NO; self.currentState = ZXAppStateInit; [self stopHeartbeatMonitor]; [self stopLicenseCountdown]; [self beginBootstrap];
}
- (void)dismissPresentedUI { [self dismissViewControllerAnimated:YES completion:nil]; }
- (BOOL)isShowingLogin { return self.currentState == ZXAppStateAuth && !self.authContainer.hidden; }
- (BOOL)isShowingDashboard { return self.currentState == ZXAppStateDashboard && !self.dashboardContainer.hidden; }
- (BOOL)isShowingSafeModeLock { return !self.safeLockContainer.hidden && self.safeModeEnabled; }

#pragma mark - Language / Theme

- (void)showLanguageSelection {
    if (self.languageOverlay.superview) return;
    UIView *overlay=[[UIView alloc] initWithFrame:self.view.bounds];
    overlay.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    overlay.backgroundColor=[ZXTheme background];
    overlay.layer.zPosition=25000;
    self.languageOverlay=overlay;
    [self.view addSubview:overlay];

    UIImageView *logo=[[UIImageView alloc] initWithImage:[self preferredLogoImage]]; logo.contentMode=UIViewContentModeScaleAspectFit; logo.translatesAutoresizingMaskIntoConstraints=NO; [overlay addSubview:logo];
    UILabel *eyebrow=[self label:@"WELCOME TO ZENTRAX" size:9 weight:UIFontWeightBold color:[ZXTheme mutedText]]; [ZXTheme track:eyebrow spacing:1.8]; eyebrow.textAlignment=NSTextAlignmentCenter; eyebrow.translatesAutoresizingMaskIntoConstraints=NO; [overlay addSubview:eyebrow];
    UILabel *title=[self label:@"Choose your language" size:28 weight:UIFontWeightBlack color:[ZXTheme primaryText]]; title.textAlignment=NSTextAlignmentCenter; title.translatesAutoresizingMaskIntoConstraints=NO; [overlay addSubview:title];
    UILabel *subtitle=[self label:@"You can change this anytime from Settings." size:12 weight:UIFontWeightRegular color:[ZXTheme secondaryText] ]; subtitle.textAlignment=NSTextAlignmentCenter; subtitle.translatesAutoresizingMaskIntoConstraints=NO; [overlay addSubview:subtitle];

    UIStackView *stack=[[UIStackView alloc] init]; stack.axis=UILayoutConstraintAxisVertical; stack.spacing=10; stack.translatesAutoresizingMaskIntoConstraints=NO; [overlay addSubview:stack];
    NSArray *langs=@[@[@"English",@"English"],@[@"Tiếng Việt",@"Tiếng Việt"],@[@"简体中文",@"简体中文"]];
    for (NSArray *pair in langs) {
        UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem]; [self styleSecondaryButton:b]; [b setTitle:pair[0] forState:UIControlStateNormal]; b.accessibilityLabel=pair[0]; b.accessibilityHint=@"Select language"; b.tag=(NSInteger)stack.arrangedSubviews.count + 1; [b addTarget:self action:@selector(languageSelected:) forControlEvents:UIControlEventTouchUpInside]; [stack addArrangedSubview:b]; [b.heightAnchor constraintEqualToConstant:56].active=YES;
    }
    [NSLayoutConstraint activateConstraints:@[[logo.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],[logo.topAnchor constraintEqualToAnchor:overlay.safeAreaLayoutGuide.topAnchor constant:100],[logo.widthAnchor constraintEqualToConstant:64],[logo.heightAnchor constraintEqualToConstant:64],[eyebrow.topAnchor constraintEqualToAnchor:logo.bottomAnchor constant:20],[eyebrow.leadingAnchor constraintEqualToAnchor:overlay.leadingAnchor constant:30],[eyebrow.trailingAnchor constraintEqualToAnchor:overlay.trailingAnchor constant:-30],[title.topAnchor constraintEqualToAnchor:eyebrow.bottomAnchor constant:10],[title.leadingAnchor constraintEqualToAnchor:overlay.leadingAnchor constant:24],[title.trailingAnchor constraintEqualToAnchor:overlay.trailingAnchor constant:-24],[subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],[subtitle.leadingAnchor constraintEqualToAnchor:overlay.leadingAnchor constant:24],[subtitle.trailingAnchor constraintEqualToAnchor:overlay.trailingAnchor constant:-24],[stack.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:28],[stack.leadingAnchor constraintEqualToAnchor:overlay.leadingAnchor constant:32],[stack.trailingAnchor constraintEqualToAnchor:overlay.trailingAnchor constant:-32]]];
    overlay.alpha=0; [UIView animateWithDuration:0.32 animations:^{overlay.alpha=1;}];
}

- (void)languageSelected:(UIButton *)button {
    NSArray *values=@[@"English",@"Tiếng Việt",@"简体中文"];
    NSInteger selected=button.tag - 1;
    NSString *language=(selected>=0 && selected<values.count) ? values[selected] : @"English";
    if (!language.length) language=@"English";
    [[NSUserDefaults standardUserDefaults] setObject:language forKey:ZXLanguageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    UIView *overlay=self.languageOverlay; self.languageOverlay=nil;
    [UIView animateWithDuration:0.22 animations:^{overlay.alpha=0;} completion:^(BOOL f){[overlay removeFromSuperview];[self showLoginScreen];}];
}

- (void)showLanguagePicker { [self showLanguageSelection]; }
- (void)showThemeInfo {
    UIView *overlay=[[UIView alloc] initWithFrame:self.view.bounds]; overlay.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight; overlay.backgroundColor=[[UIColor blackColor] colorWithAlphaComponent:0.82]; overlay.tag=551155; [self.view addSubview:overlay];
    UIView *card=[self card]; [overlay addSubview:card];
    UILabel *title=[self label:@"PREMIUM THEMES" size:17 weight:UIFontWeightBlack color:[ZXTheme primaryText]]; title.textAlignment=NSTextAlignmentCenter; title.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:title];
    UILabel *sub=[self label:@"Curated visual systems. The current flagship is Obsidian Black." size:11 weight:UIFontWeightRegular color:[ZXTheme secondaryText]]; sub.textAlignment=NSTextAlignmentCenter; sub.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:sub];
    UIStackView *stack=[[UIStackView alloc] init]; stack.axis=UILayoutConstraintAxisVertical; stack.spacing=9; stack.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:stack];
    NSArray *themes=@[@"Obsidian Black",@"Carbon Silver",@"Midnight Graphite",@"Stealth Mono"];
    NSString *selectedTheme=[[NSUserDefaults standardUserDefaults] stringForKey:ZXThemeKey] ?: @"Obsidian Black";
    for (NSString *name in themes) {
        UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
        [self styleSecondaryButton:b];
        [b setTitle:name forState:UIControlStateNormal];
        [b setImage:[UIImage systemImageNamed:[name isEqualToString:selectedTheme] ? @"checkmark.circle.fill" : @"circle"] forState:UIControlStateNormal];
        b.semanticContentAttribute=UISemanticContentAttributeForceLeftToRight;
        if (@available(iOS 15.0, *)) {
            UIButtonConfiguration *cfg = b.configuration;
            cfg.imagePadding = 8.0;
            b.configuration = cfg;
        }
        [stack addArrangedSubview:b];
        [b.heightAnchor constraintEqualToConstant:48].active=YES;
        [b addTarget:self action:@selector(themeOptionPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    UIButton *close=[UIButton buttonWithType:UIButtonTypeSystem]; [self styleSecondaryButton:close]; [close setTitle:@"DONE" forState:UIControlStateNormal]; close.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:close]; [close addTarget:self action:@selector(closeThemeOverlay:) forControlEvents:UIControlEventTouchUpInside];
    [NSLayoutConstraint activateConstraints:@[[card.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],[card.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],[card.leadingAnchor constraintEqualToAnchor:overlay.leadingAnchor constant:25],[card.trailingAnchor constraintEqualToAnchor:overlay.trailingAnchor constant:-25],[title.topAnchor constraintEqualToAnchor:card.topAnchor constant:25],[title.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],[title.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],[sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],[sub.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],[sub.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],[stack.topAnchor constraintEqualToAnchor:sub.bottomAnchor constant:18],[stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],[stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],[close.topAnchor constraintEqualToAnchor:stack.bottomAnchor constant:14],[close.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],[close.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],[close.heightAnchor constraintEqualToConstant:48],[close.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20]]];
}
- (void)themeOptionPressed:(UIButton *)button {
    NSString *theme=button.currentTitle.length ? button.currentTitle : @"Obsidian Black";
    [[NSUserDefaults standardUserDefaults] setObject:theme forKey:ZXThemeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self showToast:[NSString stringWithFormat:@"%@ selected",theme] success:YES];
    UIView *overlay=button.superview.superview.superview;
    [UIView animateWithDuration:0.18 animations:^{ overlay.alpha=0; } completion:^(BOOL finished){
        [overlay removeFromSuperview];
        if (self.settingsVisible) [self rebuildSettings];
    }];
}
- (void)closeThemeOverlay:(UIButton *)button { UIView *overlay=button.superview.superview; [UIView animateWithDuration:0.16 animations:^{overlay.alpha=0;} completion:^(BOOL f){[overlay removeFromSuperview];}]; }

#pragma mark - Privacy / Screen Capture

- (void)registerPrivacyObservers {
    NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(updatePrivacyCaptureState) name:UIScreenCapturedDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(handleScreenshotNotification:) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    [nc addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [nc addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)appWillResignActive:(NSNotification *)note { if (self.safeModeEnabled) { [self lockSafeMode]; [self showPrivacyOverlayForReason:@"Private Space is protected while the app is not active."]; } }
- (void)appDidBecomeActive:(NSNotification *)note { [self updatePrivacyCaptureState]; }
- (void)handleScreenshotNotification:(NSNotification *)note {
    if (!self.safeModeEnabled) return;
    [self showPrivacyOverlayForReason:@"Screenshot event detected. Private content remains protected while Safe UI Mode is active."];
}
- (void)updatePrivacyCaptureState {
    BOOL captured = [UIScreen mainScreen].isCaptured;
    if (captured && self.safeModeEnabled) [self showPrivacyOverlayForReason:@"Screen recording or screen sharing detected. Private content is currently protected."];
    else if (!captured && self.privacyOverlayPresented) [self hidePrivacyOverlay];
}

- (void)showPrivacyOverlayForReason:(NSString *)reason {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.safeModeEnabled) return;
        if (!self.privacyOverlay) {
            self.privacyOverlay=[[UIView alloc] initWithFrame:self.view.bounds]; self.privacyOverlay.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight; self.privacyOverlay.backgroundColor=[ZXTheme background]; self.privacyOverlay.layer.zPosition=30000;
            UIImageView *logo=[[UIImageView alloc] initWithImage:[self safeModeLogoImage]]; logo.contentMode=UIViewContentModeScaleAspectFit; logo.translatesAutoresizingMaskIntoConstraints=NO; [self.privacyOverlay addSubview:logo];
            UILabel *t=[self label:@"PRIVATE CONTENT PROTECTED" size:19 weight:UIFontWeightBlack color:[ZXTheme primaryText]]; t.textAlignment=NSTextAlignmentCenter; t.translatesAutoresizingMaskIntoConstraints=NO; [self.privacyOverlay addSubview:t];
            UILabel *m=[self label:@"" size:13 weight:UIFontWeightMedium color:[ZXTheme secondaryText]]; m.tag=9300; m.textAlignment=NSTextAlignmentCenter; m.translatesAutoresizingMaskIntoConstraints=NO; [self.privacyOverlay addSubview:m];
            UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem]; [self styleSecondaryButton:b]; [b setTitle:@"CHECK AGAIN" forState:UIControlStateNormal]; b.translatesAutoresizingMaskIntoConstraints=NO; [b addTarget:self action:@selector(updatePrivacyCaptureState) forControlEvents:UIControlEventTouchUpInside]; [self.privacyOverlay addSubview:b];
            [NSLayoutConstraint activateConstraints:@[[logo.centerXAnchor constraintEqualToAnchor:self.privacyOverlay.centerXAnchor],[logo.centerYAnchor constraintEqualToAnchor:self.privacyOverlay.centerYAnchor constant:-105],[logo.widthAnchor constraintEqualToConstant:72],[logo.heightAnchor constraintEqualToConstant:72],[t.topAnchor constraintEqualToAnchor:logo.bottomAnchor constant:24],[t.leadingAnchor constraintEqualToAnchor:self.privacyOverlay.leadingAnchor constant:25],[t.trailingAnchor constraintEqualToAnchor:self.privacyOverlay.trailingAnchor constant:-25],[m.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:10],[m.leadingAnchor constraintEqualToAnchor:self.privacyOverlay.leadingAnchor constant:35],[m.trailingAnchor constraintEqualToAnchor:self.privacyOverlay.trailingAnchor constant:-35],[b.topAnchor constraintEqualToAnchor:m.bottomAnchor constant:24],[b.centerXAnchor constraintEqualToAnchor:self.privacyOverlay.centerXAnchor],[b.heightAnchor constraintEqualToConstant:48],[b.widthAnchor constraintEqualToConstant:170]]];
        }
        UILabel *m=[self.privacyOverlay viewWithTag:9300]; m.text=reason ?: @"Screen recording and screen sharing are blocked while Safe UI Mode is active. iOS reports screenshot events to the app.";
        if (!self.privacyOverlay.superview) [self.view addSubview:self.privacyOverlay];
        self.privacyOverlayPresented=YES;
    });
}
- (void)hidePrivacyOverlay { dispatch_async(dispatch_get_main_queue(), ^{[self.privacyOverlay removeFromSuperview];self.privacyOverlayPresented=NO;}); }

#pragma mark - Branding Helpers

- (UIImage *)preferredLogoImage {
    NSArray *names=@[@"ZentraxLogo",@"AppIcon60x60",@"AppIcon"]; for (NSString *n in names) { UIImage *i=[UIImage imageNamed:n]; if(i)return i; }
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(120,120),YES,0); [[ZXTheme surfaceRaised] setFill]; UIRectFill(CGRectMake(0,0,120,120)); NSDictionary *attrs=@{NSFontAttributeName:[ZXTheme display:54],NSForegroundColorAttributeName:[ZXTheme primaryText]}; [@"Z" drawInRect:CGRectMake(34,27,52,65) withAttributes:attrs]; UIImage *i=UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); return i;
}

@end
 