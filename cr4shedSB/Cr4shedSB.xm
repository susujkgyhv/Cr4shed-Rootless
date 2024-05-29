@import Foundation;
#import <sharedutils.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#import <objc/runtime.h>
#include <libxpcToolStrap.h>
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
-(NSDictionary *)retrieveappBadgeValue:(NSString *)name userInfo:(NSDictionary*)userInfo;
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
		
		void *sandyHandle = dlopen(c_rootless("/usr/lib/libsandy.dylib"), RTLD_LAZY);
          if (sandyHandle) {

              int (*__dyn_libSandy_applyProfile)(const char *profileName) = (int (*)(const char *))dlsym(sandyHandle, "libSandy_applyProfile");
              if (__dyn_libSandy_applyProfile) {
                 __dyn_libSandy_applyProfile("Cr4shedTweak");
              }
		    }

		void *xpcToolHandle = dlopen(c_rootless("/usr/lib/libxpcToolStrap.dylib"), RTLD_LAZY);
	    if (xpcToolHandle) {
        libxpcToolStrap *libTool = [objc_getClass("libxpcToolStrap") shared];

        NSString *uName = @"com.muirey03.cr4shedSBserver";
	    
		[libTool defineUniqueName:uName];
        [libTool startEventWithMessageIDs:@[@"showCr4shedNotification"] uName:uName];
		[libTool addTarget:self selector:@selector(showCr4shedNotification:userInfo:) forMsgID:@"showCr4shedNotification" uName:uName];


		}
	}
	return self;
}

-(void) showCr4shedNotification:(NSString *)name userInfo:(NSDictionary*)userInfo {

	// CLog(@"SB~[Cr4shedSB]~ -[showCr4shedNotification:userInfo:]~");

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
		
		
 	    NSString *uid = [[NSUUID UUID] UUIDString];  
	   	NSString* bundleID = @"com.muirey03.cr4shedgui";
		NSString* title = @"Cr4shed";
	    

		// CLog(@"userInfo : %@",userInfo);

	    [objc_getClass("CPNotification") showAlertWithTitle:title
  	                                              message:(NSString *)userInfo[@"notifContent"]
	                                               userInfo:(NSDictionary *)userInfo[@"notifUserInfo"]
	                                             badgeCount:(badgeValue.intValue + 1)
	                                              soundName:nil //research UNNotificationSound
	                                                  delay:1 //cannot be zero & cannot be < 60 if repeats is YES
	                                                repeats:NO
	                                               bundleId:bundleID
	                                                   uuid:uid //specify if you need to use hideAlertWithBundleId and store the string for later use
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