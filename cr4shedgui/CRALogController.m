#import "CRALogController.h"
#import "Log.h"
#import "NSString+HTML.h"

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#pragma GCC diagnostic ignored "-Wunused-variable"
#pragma GCC diagnostic ignored "-Wprotocol"
#pragma GCC diagnostic ignored "-Wmacro-redefined"
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#pragma GCC diagnostic ignored "-Wincomplete-implementation"
#pragma GCC diagnostic ignored "-Wunknown-pragmas"
#pragma GCC diagnostic ignored "-Wformat"
#pragma GCC diagnostic ignored "-Wunknown-warning-option"
#pragma GCC diagnostic ignored "-Wincompatible-pointer-types"
#pragma GCC diagnostic ignored "-Wunused-value"
#pragma GCC diagnostic ignored "-Wunused-function"
#pragma GCC diagnostic ignored "-Wunused-variable"


#define rgbValue
#define UIColorFromHEX(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

 


@implementation CRALogController
-(instancetype)initWithLog:(Log*)log
{
	if ((self = [self init]))
	{
		_log = log;
		self.title = log.dateName;
	}
	return self;
}


NSArray *reArrangeArrays(NSArray *iObjects) {
    
    NSMutableArray *words = [[NSMutableArray alloc] init];
    NSMutableArray *colors = [[NSMutableArray alloc] init];
    
    CFIndex oneThree = 0;
    CFIndex twoFour = 1;
    for (CFIndex iCounter = 0; iCounter < iObjects.count; iCounter ++) {
        
        [words addObject:[iObjects objectAtIndex:oneThree]];
        [colors addObject:[iObjects objectAtIndex:twoFour]];
        
        oneThree = oneThree + 2;
        twoFour = twoFour + 2;
        
        if (oneThree > iObjects.count || twoFour > iObjects.count)
            break;
    }
    
    return @[[NSArray arrayWithArray:words],[NSArray arrayWithArray:colors]];
}


NSMutableAttributedString *colorizerText(NSString *originalText, NSArray *wordsAndColors, UIColor *theRestColor)  {
    
    NSArray *text = [reArrangeArrays(wordsAndColors) objectAtIndex:0];
    NSArray *color = [reArrangeArrays(wordsAndColors) objectAtIndex:1];
    
    NSMutableAttributedString *mutableAttString = [[NSMutableAttributedString alloc] initWithString:originalText attributes:@{NSForegroundColorAttributeName : theRestColor}];
    
    
    if (originalText != nil) {
        
        for (NSUInteger counter = 0; counter < color.count; counter ++) {
            
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"(%@)|([\\+\\[\\]])",[text objectAtIndex:counter]] options:kNilOptions error:nil];
            
            NSRange range = NSMakeRange(0 ,originalText.length);
            
            [regex enumerateMatchesInString:originalText options:kNilOptions range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                
                NSRange subStringRange = [result rangeAtIndex:0];
                
                [mutableAttString addAttribute:NSForegroundColorAttributeName value:[color objectAtIndex:counter] range:subStringRange];
                
            }];
        }
    }
    
    return mutableAttString;
}


- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {

            if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) 
				self.textView.alpha = 0.9;
             else 
				self.textView.alpha = 1.0;
            
			self.textView.attributedText = [self colorizeString];
        }
    }
}

-(NSMutableAttributedString *) colorizeString {

	UIColor *backgroundColor;
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){13,0,0}])
        backgroundColor = [UIColor systemBackgroundColor];
    else { 
        backgroundColor = [UIColor whiteColor];
	}

	return colorizerText([(NSString *)_log.contents kv_encodeHTMLCharacterEntities],
	@[
	@"Date:",UIColor.orangeColor,
	@"Process:",UIColor.orangeColor,
	@"Bundle id:",UIColor.orangeColor,
	@"Device:",UIColor.orangeColor,
	@"Bundle version:",UIColor.orangeColor,

	@"Exception type:",UIColorFromHEX(0xC03865),
	@"Exception subtype:",UIColorFromHEX(0xC03865),
	@"Exception codes:",UIColorFromHEX(0xC03865),
	@"Reason:",UIColor.greenColor,
    @"Termination Reason:",UIColor.greenColor,
	@"Culprit:",UIColor.greenColor,
	
	@"Call stack:",UIColor.orangeColor,

	@"Register values:",UIColor.orangeColor,

	@"Loaded images:",UIColor.orangeColor,

	@".dylib",UIColorFromHEX(0xC03865),

	@"-",UIColorFromHEX(0xC03865),
	@"[",UIColorFromHEX(0xC03865),
	@"]",UIColorFromHEX(0xC03865),
	@"+",UIColorFromHEX(0xC03865),
 


	],[self invertedColor:backgroundColor]);
}

-(void)loadView
{
    [super loadView];

    if ([self.navigationItem respondsToSelector:@selector(setLargeTitleDisplayMode:)])
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;

    UIColor *backgroundColor;
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){13,0,0}])
        backgroundColor = [UIColor systemBackgroundColor];
    else
        backgroundColor = [UIColor whiteColor];
    
    self.view.backgroundColor = backgroundColor;

    UIBarButtonItem* shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share:)];
    self.navigationItem.rightBarButtonItem = shareButton;

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:scrollView];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height * 2)]; 
	
    self.textView.editable = NO;
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.alpha = 0.8;
    self.textView.textContainer.lineBreakMode = NSLineBreakByWordWrapping; 
	self.textView.attributedText = [self colorizeString];
	self.textView.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:10];
 
    [scrollView addSubview:self.textView];

   
	CGSize sizeThatFits = [self.textView sizeThatFits:CGSizeMake(self.textView.frame.size.width, CGFLOAT_MAX)];

	NSArray *lines = [self.textView.text componentsSeparatedByString:@"\n"];

	CGFloat textViewHeight = sizeThatFits.height; 
	CGFloat maxLineHeight = 0;
	CGFloat maxLineWidth = 0;

	for (NSString *line in lines) {
		CGSize lineSize = [line sizeWithAttributes:@{NSFontAttributeName: self.textView.font}];
		maxLineWidth = MAX(maxLineWidth, lineSize.width);
		maxLineHeight += ceil(lineSize.height); 
	}

	maxLineWidth += 20;
	

	textViewHeight = maxLineHeight + self.textView.textContainerInset.top + self.textView.textContainerInset.bottom;  

	self.textView.frame = CGRectMake(0, 0, maxLineWidth, textViewHeight);
	scrollView.contentSize = CGSizeMake(maxLineWidth, textViewHeight);
 
    scrollView.minimumZoomScale = 1.0;
    scrollView.maximumZoomScale = 3.0;
    scrollView.delegate = self;
    
    self.textView.scrollEnabled = NO;
}



- (UIColor *)invertedColor:(UIColor *)color
{
    CGFloat r, g, b, a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    return [UIColor colorWithRed:(1.0 - r) green:(1.0 - g) blue:(1.0 - b) alpha:a];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    for (UIView *subview in scrollView.subviews) {
        if ([subview isKindOfClass:[UITextView class]]) {
            return subview;
        }
    }
    return nil;
}


 
-(void)viewDidAppear:(BOOL)arg1
{
	[super viewDidAppear:arg1];
	self.navigationController.interactivePopGestureRecognizer.delegate = self;
	self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

-(void)share:(id)sender
{
	NSArray* activityItems = @[[(NSString *)_log.contents kv_encodeHTMLCharacterEntities]];
	UIActivityViewController* activityViewControntroller = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
	activityViewControntroller.excludedActivityTypes = @[];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		activityViewControntroller.popoverPresentationController.sourceView = self.view;
		activityViewControntroller.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/4, 0, 0);
	}
	[self presentViewController:activityViewControntroller animated:YES completion:nil];
}
@end
