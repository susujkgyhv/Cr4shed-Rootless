@import CoreFoundation;
@import Foundation;


#import <sharedutils.h>
#include <pthread.h>
#include <time.h>
#include <dlfcn.h>
#import <objc/runtime.h>  
#include <libxpcToolStrap.h>
#import <Cephei/HBPreferences.h>

 
#pragma GCC diagnostic ignored "-Wunused-result"

 


@interface Cr4shedServer : NSObject
-(BOOL)createDirectoryAtPath:(NSString*)path;
-(NSDictionary *)writeString:(NSString *)name userInfo:(NSDictionary*)userInfo;
-(void)sendNotification:(NSString *)name userInfo:(NSDictionary*)userInfo;
-(NSDictionary *)stringFromTime:(NSString *)name userInfo:(NSDictionary*)userInfo;
-(NSDictionary *)isProcessBlacklisted:(NSString*)name userInfo:(NSDictionary*)procName;
-(NSDictionary *)shouldLogJetsam;
@end

@implementation Cr4shedServer
 

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

		void *sandyHandle = dlopen(c_rootless("/usr/lib/libsandy.dylib"), RTLD_LAZY);
          if (sandyHandle) {

              int (*__dyn_libSandy_applyProfile)(const char *profileName) = (int (*)(const char *))dlsym(sandyHandle, "libSandy_applyProfile");
              if (__dyn_libSandy_applyProfile) {
                 __dyn_libSandy_applyProfile("Cr4shedTweak");
				__dyn_libSandy_applyProfile("libnotifications");
              }
		    }

	});
	return sharedInstance;
}

-(id)init
{
	if ((self = [super init]))
	{	
 
	}
	return self;
}

-(NSDictionary*)writeString:(NSString *)name userInfo:(NSDictionary*)userInfo
{	

	 // CLog(@"-[cr4shedd]~ -[writeString:userInfo:]");
	//get info from userInfo:
	NSString* str = userInfo[@"string"];
	NSString* filename = [userInfo[@"filename"] lastPathComponent];
	if (!filename)
		return nil;
	NSString* fullFilename = [filename stringByAppendingPathExtension:@"log"];
	//validate filename is safe:
	if ([fullFilename pathComponents].count > 1)
		return nil;
	//formulate path:
	NSString* const cr4Dir = rootless(@"/var/mobile/Library/Cr4shed");
	NSString* path = [cr4Dir stringByAppendingPathComponent:fullFilename];
	//create cr4shed dir if neccessary:
	//(deleting it if it is a file not a dir)
	NSFileManager* manager = [NSFileManager defaultManager];
	BOOL isDir = NO;
	BOOL exists = [manager fileExistsAtPath:cr4Dir isDirectory:&isDir];
	if (!exists || !isDir)
	{
		if (exists)
			[manager removeItemAtPath:cr4Dir error:NULL];
		exists = [self createDirectoryAtPath:cr4Dir];
		if (!exists)
			return nil;
	}
	//change path so that it doesn't conflict:
	for (unsigned long long i = 1; [[NSFileManager defaultManager] fileExistsAtPath:path]; i++)
		path = [cr4Dir stringByAppendingPathComponent:[[NSString stringWithFormat:@"%@ (%llu)", filename, i] stringByAppendingPathExtension:@"log"]];
	//create new file:
	NSDictionary<NSFileAttributeKey, id>* attributes = @{
		NSFilePosixPermissions : @0666,
		NSFileOwnerAccountName : @"mobile",
		NSFileGroupOwnerAccountName : @"mobile"
	};
	NSData* contentsData = [str dataUsingEncoding:NSUTF8StringEncoding];
	[manager createFileAtPath:path contents:contentsData attributes:attributes];
	return @{@"path" : path};
}

-(BOOL)createDirectoryAtPath:(NSString*)path
{	
	NSDictionary<NSFileAttributeKey, id>* attributes = @{
		NSFilePosixPermissions : @0755,
		NSFileOwnerAccountName : @"mobile",
		NSFileGroupOwnerAccountName : @"mobile"
	};
	return [[NSFileManager defaultManager] createDirectoryAtURL:[NSURL fileURLWithPath:path] withIntermediateDirectories:YES attributes:attributes error:NULL];
}


-(void)sendNotification:(NSString *)name userInfo:(NSDictionary*)userInfo
{
	// CLog(@"-[cr4shedd]~ -[sendNotification:userInfo:]");
	NSString* content = userInfo[@"content"];
	NSDictionary* notifUserInfo = userInfo[@"userInfo"];
	showCr4shedNotification(content, notifUserInfo);
}

-(NSDictionary*)stringFromTime:(NSString *)name userInfo:(NSDictionary*)userInfo
{	
	// CLog(@"-[cr4shedd]~ -[stringFromTime:userInfo:]");
	time_t t = (time_t)[userInfo[@"time"] integerValue];
	CR4DateFormat type = (CR4DateFormat)[userInfo[@"type"] integerValue];
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:t];
	NSString* ret = stringFromDate(date, type);
	return ret ? @{@"ret" : ret} : @{};
}

-(NSDictionary *)isProcessBlacklisted:(NSString *)name userInfo:(NSDictionary*)userInfo
{    
    HBPreferences* prefs = sharedPreferences();
    NSArray<NSString*>* blacklist = [prefs objectForKey:kProcessBlacklist];
    return @{@"ret" : @((blacklist && [blacklist containsObject:userInfo[@"value"]]))};
}

-(NSDictionary *) shouldLogJetsam {

    HBPreferences* prefs = sharedPreferences();
    bool shouldLogJetsam = [prefs objectForKey:kEnableJetsam];
    return @{@"ret" : @(shouldLogJetsam)};
}

@end







int main(int argc, char** argv, char** envp)
{
	@autoreleasepool
	{
		[Cr4shedServer load];

		void *sandyHandle = dlopen(c_rootless("/usr/lib/libsandy.dylib"), RTLD_LAZY);
          if (sandyHandle) {

              int (*__dyn_libSandy_applyProfile)(const char *profileName) = (int (*)(const char *))dlsym(sandyHandle, "libSandy_applyProfile");
              if (__dyn_libSandy_applyProfile) {
                  __dyn_libSandy_applyProfile("Cr4shedTweak");
			      __dyn_libSandy_applyProfile("libnotifications");
				  __dyn_libSandy_applyProfile("xpcToolStrap");
              }
		    }

		xpc_connection_t service = xpc_connection_create_mach_service("com.muirey03.cr4shedd", NULL, XPC_CONNECTION_MACH_SERVICE_LISTENER);
		if (!service) {

			return 0;
		}

		
		xpc_connection_set_event_handler(service, ^(xpc_object_t connection) {
			xpc_type_t type = xpc_get_type(connection);
			if (type == XPC_TYPE_CONNECTION) {
				xpc_connection_set_event_handler(connection, ^(xpc_object_t message) {
					if (xpc_get_type(message) == XPC_TYPE_DICTIONARY) {

						int64_t idValue = xpc_dictionary_get_int64(message, "id");
               			 CR4SHEDD_MESSAGE_ID messageId = (CR4SHEDD_MESSAGE_ID)idValue;
						switch (messageId) {
							case CR4SHEDD_MESSAGE_SHOULD_LOG_JETSAM: {
								xpc_object_t reply = xpc_dictionary_create_reply(message);
								NSDictionary *shouldLogJetsamDict = [Cr4shedServer.sharedInstance shouldLogJetsam];
								xpc_object_t shouldLogJetsam = convertNSDictionaryToXPCDictionary(shouldLogJetsamDict);
								xpc_dictionary_set_value(reply, "userInfo", shouldLogJetsam);
								xpc_connection_send_message(connection, reply);
								break;
							}
							case CR4SHEDD_MESSAGE_IS_PROCESS_BLACKLISTED: {
								xpc_object_t userInfo = xpc_dictionary_get_value(message, "userInfo");
								NSDictionary *userInfoDict = convertXPCDictionaryToNSDictionary(userInfo);
								NSDictionary *isProcessBlacklistedDict = [Cr4shedServer.sharedInstance isProcessBlacklisted:@"" userInfo:userInfoDict];
								xpc_object_t isProcessBlacklisted = convertNSDictionaryToXPCDictionary(isProcessBlacklistedDict);
								xpc_object_t reply = xpc_dictionary_create_reply(message);
								xpc_dictionary_set_value(reply, "userInfo", isProcessBlacklisted);
								xpc_connection_send_message(connection, reply);
								break;
							}
							case CR4SHEDD_MESSAGE_STRING_FROM_TIME: {
								xpc_object_t userInfo = xpc_dictionary_get_value(message, "userInfo");
								NSDictionary *userInfoDict = convertXPCDictionaryToNSDictionary(userInfo);
								NSDictionary *stringFromTimeDict = [Cr4shedServer.sharedInstance stringFromTime:@"" userInfo:userInfoDict];
								xpc_object_t stringFromTime = convertNSDictionaryToXPCDictionary(stringFromTimeDict);
								xpc_object_t reply = xpc_dictionary_create_reply(message);
								xpc_dictionary_set_value(reply, "userInfo", stringFromTime);
								xpc_connection_send_message(connection, reply);
								break;
							}
							case CR4SHEDD_MESSAGE_SEND_NOTIFICATION: {
								xpc_object_t userInfo = xpc_dictionary_get_value(message, "userInfo");
								NSDictionary *userInfoDict = convertXPCDictionaryToNSDictionary(userInfo);
								[Cr4shedServer.sharedInstance sendNotification:@"" userInfo:userInfoDict];
								xpc_object_t reply = xpc_dictionary_create_reply(message);
								xpc_connection_send_message(connection, reply);
								break;
							}
							case CR4SHEDD_MESSAGE_WRITE_STRING: {
								xpc_object_t userInfo = xpc_dictionary_get_value(message, "userInfo");
								NSDictionary *userInfoDict = convertXPCDictionaryToNSDictionary(userInfo);
								NSDictionary *writeStringDict = [Cr4shedServer.sharedInstance writeString:@"" userInfo:userInfoDict];
								xpc_object_t writeString = convertNSDictionaryToXPCDictionary(writeStringDict);
								xpc_object_t reply = xpc_dictionary_create_reply(message);
								xpc_dictionary_set_value(reply, "userInfo", writeString);
								xpc_connection_send_message(connection, reply);
								break;
							}
						}
					}
				});
				xpc_connection_resume(connection);
			} else if (type == XPC_TYPE_ERROR) {
				// CLog(@"XPC server error: %s", xpc_dictionary_get_string(connection, XPC_ERROR_KEY_DESCRIPTION));
			}
		});


		xpc_connection_resume(service);

		 [[NSRunLoop currentRunLoop] run];

		return 0;
	}
}
