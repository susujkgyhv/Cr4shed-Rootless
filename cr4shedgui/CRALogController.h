@import UIKit;
@import WebKit;

@class Log;
@interface CRALogController : UIViewController <UIGestureRecognizerDelegate,UIScrollViewDelegate>
{
	WKWebView* webView;
	NSString* logMessage;
}
@property UITextView *textView;
@property (nonatomic, strong) Log* log;
-(instancetype)initWithLog:(Log*)log;
@end
