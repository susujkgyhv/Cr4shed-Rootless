@import Foundation;
#import <sharedutils.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#import <objc/runtime.h>
#import <libnotifications.h>

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
#pragma clang diagnostic ignored "-Wnullability-completeness"
#pragma GCC diagnostic ignored "-Wunused-variable"
#pragma GCC diagnostic ignored "-Wprotocol"
#pragma GCC diagnostic ignored "-Wmacro-redefined"
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#pragma GCC diagnostic ignored "-Wincomplete-implementation"
#pragma GCC diagnostic ignored "-Wunguarded-availability-new"
#pragma GCC diagnostic ignored "-Wunused-function"

 
 


@interface SBApplicationController : NSObject
+(id) sharedInstanceIfExists;
-(id) applicationWithBundleIdentifier:(NSString *)bundle;
@end 

@interface SBApplication : NSObject
@property NSString *badgeValue;
@end


#define CLog(fmt, ...) NSLog(@"[+] CM90 : " fmt, ##__VA_ARGS__)



@interface Cr4shedSBServer : NSObject
-(void) showCr4shedNotification:(NSString *)name userInfo:(NSDictionary*)userInfo;
@end

@implementation Cr4shedSBServer
 

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
		#define _serviceName @"com.muirey03.cr4shedSBserver"

        CrossOverIPC *crossOver = [objc_getClass("CrossOverIPC") centerNamed:_serviceName type:SERVICE_TYPE_LISTENER];
        [crossOver registerForMessageName:@"showCr4shedNotification" target:self selector:@selector(showCr4shedNotification:userInfo:)];
		
	}
	return self;
}

-(void) showCr4shedNotification:(NSString *)name userInfo:(NSDictionary*)userInfo {

 
	NSString *badgeValue = NULL; 
	SBApplicationController *appCont = [objc_getClass("SBApplicationController") sharedInstanceIfExists];
		if (appCont) { 

	SBApplication *application = [appCont applicationWithBundleIdentifier:@"com.muirey03.cr4shedgui"];
	if (application) { 
	
	badgeValue = application.badgeValue;
	if (!badgeValue) {
		badgeValue = @"0";
	}
 
 
	void *handle = dlopen(c_rootless("/usr/lib/libnotifications.dylib"), RTLD_LAZY);
	if (handle != NULL) {                                            
		 
	    [objc_getClass("CPNotification") showAlertWithTitle:@"Cr4shed"
  	                                              message:(NSString *)userInfo[@"notifContent"]
	                                               userInfo:(NSDictionary *)userInfo[@"notifUserInfo"]
	                                             badgeCount:(badgeValue.intValue + 1)
	                                              soundName:nil  
	                                                  delay:1
	                                                repeats:NO
	                                               bundleId: @"com.muirey03.cr4shedgui"
	                                                   uuid:[[NSUUID UUID] UUIDString]
	                                                 silent:NO];				       				       
	}

	dlclose(handle);

	}
  }
}
 

@end 

%ctor
{
	[Cr4shedSBServer load];
}