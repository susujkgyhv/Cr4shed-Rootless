@import Foundation;
#import <sharedutils.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#import <objc/runtime.h>


#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
#pragma clang diagnostic ignored "-Wnullability-completeness"
#pragma GCC diagnostic ignored "-Wunused-variable"
#pragma GCC diagnostic ignored "-Wprotocol"
#pragma GCC diagnostic ignored "-Wmacro-redefined"
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#pragma GCC diagnostic ignored "-Wincomplete-implementation"
#pragma GCC diagnostic ignored "-Wunguarded-availability-new"
#pragma GCC diagnostic ignored "-Wunused-function"

 

@interface CPDistributedMessagingCenter (Cr4shedSB) 
- (bool)doesServerExist;
@end


@interface SBApplicationController : NSObject
+(id) sharedInstanceIfExists;
-(id) applicationWithBundleIdentifier:(NSString *)bundle;
@end 

@interface SBApplication : NSObject
@property NSString *badgeValue;
@end


#define CLog(fmt, ...) NSLog(@"[+] Cr4shedLogger : " fmt, ##__VA_ARGS__)



@interface Cr4shedSBServer : NSObject
-(NSDictionary *)retrieveappBadgeValue:(NSString *)name userInfo:(NSDictionary*)userInfo;
@end

@implementation Cr4shedSBServer
{
	CPDistributedMessagingCenter *_messagingCenter;
}

+(void)load
{
	[self sharedInstance];
}

+(id)sharedInstance
{
	static dispatch_once_t once = 0;
	__strong static id sharedInstance = nil;
	dispatch_once(&once, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

BOOL didInitServer = NO;
-(id)init
{
	if ((self = [super init]))
	{
		
		if (didInitServer)
			return self;
				
		_messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.muirey03.cr4shedSBserver"];

		rocketbootstrap_distributedmessagingcenter_apply(_messagingCenter);

		[_messagingCenter runServerOnCurrentThread];

		[_messagingCenter registerForMessageName:@"retrieveappBadgeValue" target:self selector:@selector(retrieveappBadgeValue:userInfo:)];

		CLog(@"com.muirey03.cr4shedSBserver created");
		didInitServer = YES;
	}
	return self;
}

-(NSDictionary *) retrieveappBadgeValue:(NSString *)name userInfo:(NSDictionary*)userInfo {

 
		SBApplicationController *appCont = [objc_getClass("SBApplicationController") sharedInstanceIfExists];
		if (appCont) { 

		SBApplication *application = [appCont applicationWithBundleIdentifier:@"com.muirey03.cr4shedgui"];
		if (application) { 
		
		NSString *badgeValue = application.badgeValue;
		if (!badgeValue) {
			badgeValue = @"0";
		}
		return @{@"badgeValue" : badgeValue ?: @"0"};
		}
		} 

		 
	return @{@"badgeValue" : @"0"};
  }

@end 

%ctor
{
		 
	[Cr4shedSBServer load];
			
			 
}