#import "CRAAppDelegate.h"
#import <libnotifications.h>

@import Foundation;

#include <stdlib.h>
#include <signal.h>
#include <uuid/uuid.h>
#include <mach/mach.h>
#import <sharedutils.h>
#include <libxpcToolStrap.h>

  



@interface SharedUnitil : NSObject

@property NSString *notifContent;
@property NSDictionary *notifUserInfo;
-(void) sendMsg;
@end

@implementation SharedUnitil
-(id)init
{
	if ((self = [super init]))
	{
	}
	return self;
}

-(void) sendMsg {

	CLog(@"SharedUnitil.[sendMsg]~");

	void *xpcToolHandle = dlopen("/var/jb/usr/lib/libxpcToolStrap.dylib", RTLD_LAZY);
	if (xpcToolHandle) {

	libxpcToolStrap *libTool = [objc_getClass("libxpcToolStrap") shared];
	
	NSString *uName = @"com.muirey03.cr4shedSBserver";

	[libTool defineUniqueName:uName];
    [libTool postToClientWithMsgID:@"showCr4shedNotification" uName:uName userInfo:@{@"notifContent":self.notifContent,@"notifUserInfo":self.notifUserInfo}];

	CLog(@"-[postToClientWithMsgID:]~showCr4shedNotification");
	}
}
 

@end 




NSString *hexToString(NSString *hexString) {
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:hexString.length / 2];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i = 0; i < [hexString length] / 2; i++) {
        byte_chars[0] = [hexString characterAtIndex:i * 2];
        byte_chars[1] = [hexString characterAtIndex:i * 2 + 1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

NSData *hexToData(NSString *hexString) {
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:hexString.length / 2];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0', '\0', '\0'};
    int i;
    for (i = 0; i < [hexString length] / 2; i++) {
        byte_chars[0] = [hexString characterAtIndex:i * 2];
        byte_chars[1] = [hexString characterAtIndex:i * 2 + 1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return data;
}


NSDictionary *hexToDict(NSString *hexString) {
    NSData *data = hexToData(hexString);
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (!dict) {
        NSLog(@"Error converting hex to dictionary: %@", error.localizedDescription);
        return nil;
    }

    return dict;
}



int main(int argc, char * argv[]) {
    @autoreleasepool {


        if (argc > 1 && strcmp(argv[1], "ShowNotification") == 0) {
        NSString *notifContentHex = [NSString stringWithUTF8String:argv[3]];
        NSString *notifUserInfoHex = [NSString stringWithUTF8String:argv[5]];

        NSString *notifContent = hexToString(notifContentHex);
        NSDictionary *notifUserInfo = hexToDict(notifUserInfoHex);
 


      void *sandyHandle = dlopen("/var/jb/usr/lib/libsandy.dylib", RTLD_LAZY);
          if (sandyHandle) {

              int (*__dyn_libSandy_applyProfile)(const char *profileName) = (int (*)(const char *))dlsym(sandyHandle, "libSandy_applyProfile");
             
              if (__dyn_libSandy_applyProfile) {

                  __dyn_libSandy_applyProfile("Cr4shedTweak");
                  __dyn_libSandy_applyProfile("libnotifications");
                  __dyn_libSandy_applyProfile("xpcToolStrap");
 

                  SharedUnitil *sharedut = [[SharedUnitil alloc] init];
                  sharedut.notifContent = notifContent;
                  sharedut.notifUserInfo = notifUserInfo;
                  [sharedut sendMsg];
 
              }
		    }

 
            return 0;  
        }

		return UIApplicationMain(argc, argv, nil, NSStringFromClass(CRAAppDelegate.class));
    }
}


