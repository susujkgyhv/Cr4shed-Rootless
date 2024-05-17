@import CoreFoundation;
@import Foundation;


#import <sharedutils.h>
#include <pthread.h>
#include <time.h>
#include <dlfcn.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>
#import <objc/runtime.h>  



@interface CPDistributedMessagingCenter (Cr4shed_) 
- (bool)doesServerExist;
@end



@interface Cr4shedServer : NSObject
-(BOOL)createDirectoryAtPath:(NSString*)path;
-(NSDictionary *)writeString:(NSString *)name userInfo:(NSDictionary*)userInfo;
-(void)sendNotification:(NSString *)name userInfo:(NSDictionary*)userInfo;
-(NSDictionary *)stringFromTime:(NSString *)name userInfo:(NSDictionary*)userInfo;
-(NSDictionary *)isProcessBlacklisted:(NSString*)name userInfo:(NSDictionary*)procName;
-(NSDictionary *)shouldLogJetsam;
@end

@implementation Cr4shedServer
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

		void *sandyHandle = dlopen("/var/jb/usr/lib/libsandy.dylib", RTLD_LAZY);
          if (sandyHandle) {

              int (*__dyn_libSandy_applyProfile)(const char *profileName) = (int (*)(const char *))dlsym(sandyHandle, "libSandy_applyProfile");
              if (__dyn_libSandy_applyProfile) {
                 __dyn_libSandy_applyProfile("Cr4shedTweak");

              }
		    }

	});
	return sharedInstance;
}

-(id)init
{
	if ((self = [super init]))
	{
		
		_messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.muirey03.cr4sheddserver"];

		if ([_messagingCenter doesServerExist]) {
			return self;
		}

		rocketbootstrap_distributedmessagingcenter_apply(_messagingCenter);

		[_messagingCenter runServerOnCurrentThread];

		[_messagingCenter registerForMessageName:@"writeString" target:self selector:@selector(writeString:userInfo:)];
		[_messagingCenter registerForMessageName:@"sendNotification" target:self selector:@selector(sendNotification:userInfo:)];
		[_messagingCenter registerForMessageName:@"stringFromTime" target:self selector:@selector(stringFromTime:userInfo:)];
		[_messagingCenter registerForMessageName:@"isProcessBlacklisted" target:self selector:@selector(isProcessBlacklisted:userInfo:)];
		[_messagingCenter registerForMessageName:@"shouldLogJetsam" target:self selector:@selector(shouldLogJetsam)];

	}
	return self;
}

-(NSDictionary*)writeString:(NSString *)name userInfo:(NSDictionary*)userInfo
{
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
	NSString* const cr4Dir = @"/var/mobile/Library/Cr4shed";
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
 
	NSString* content = userInfo[@"content"];
	NSDictionary* notifUserInfo = userInfo[@"userInfo"];
	showCr4shedNotification(content, notifUserInfo);
}

-(NSDictionary*)stringFromTime:(NSString *)name userInfo:(NSDictionary*)userInfo
{
	time_t t = (time_t)[userInfo[@"time"] integerValue];
	CR4DateFormat type = (CR4DateFormat)[userInfo[@"type"] integerValue];
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:t];
	NSString* ret = stringFromDate(date, type);
	return ret ? @{@"ret" : ret} : @{};
}

-(NSDictionary *)isProcessBlacklisted:(NSString *)name userInfo:(NSDictionary*)userInfo
{	
	return @{@"ret" : @(isBlacklisted(userInfo[@"value"]))};
}

-(NSDictionary *) shouldLogJetsam {

	return @{@"ret" : @(wantsLogJetsam())};
}
@end

int main(int argc, char** argv, char** envp)
{
	@autoreleasepool
	{
		[Cr4shedServer load];

		NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
		for (;;)
			[runLoop run];
		return 0;
	}
}
