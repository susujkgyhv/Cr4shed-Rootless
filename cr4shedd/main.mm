@import CoreFoundation;
@import Foundation;


#import <sharedutils.h>
#include <pthread.h>
#include <time.h>
#include <dlfcn.h>
#import <objc/runtime.h>  
#import <Cephei/HBPreferences.h>

 
#pragma GCC diagnostic ignored "-Wunused-result"

 


@interface Cr4shedServer : NSObject
-(BOOL) createDirectoryAtPath:(NSString*)path;
-(NSDictionary *) writeString:(NSString *)name userInfo:(NSDictionary*)userInfo;
-(void) sendNotification:(NSString *)name userInfo:(NSDictionary*)userInfo;
-(NSDictionary *) stringFromTime:(NSString *)name userInfo:(NSDictionary*)userInfo;
-(NSDictionary *) isProcessBlacklisted:(NSString*)name userInfo:(NSDictionary*)procName;
-(NSDictionary *) shouldLogJetsam;
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
	});
	return sharedInstance;
}

-(id)init
{
	if ((self = [super init]))
	{	
		
		#define _serviceName @"com.muirey03.cr4shedd"

        CrossOverIPC *crossOver = [objc_getClass("CrossOverIPC") centerNamed:_serviceName type:SERVICE_TYPE_LISTENER];

        [crossOver registerForMessageName:@"shouldLogJetsam" target:self selector:@selector(shouldLogJetsam)];
        [crossOver registerForMessageName:@"isProcessBlacklisted" target:self selector:@selector(isProcessBlacklisted:userInfo:)];
		[crossOver registerForMessageName:@"stringFromTime" target:self selector:@selector(stringFromTime:userInfo:)];
		[crossOver registerForMessageName:@"sendNotification" target:self selector:@selector(sendNotification:userInfo:)];
		[crossOver registerForMessageName:@"writeString" target:self selector:@selector(writeString:userInfo:)];

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

 
		 [[NSRunLoop currentRunLoop] run];

		return 0;
	}
}
