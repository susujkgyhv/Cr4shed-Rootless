#import "CRAAppDelegate.h"
#import "CRARootViewController.h"
#import "CRASettingsViewController.h"
#import "CRALogController.h"
#import "Log.h"
#import <UserNotifications/UserNotifications.h>
#include <dlfcn.h>

#pragma GCC diagnostic ignored "-Wunused-variable"
#pragma GCC diagnostic ignored "-Wprotocol"
#pragma GCC diagnostic ignored "-Wmacro-redefined"
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#pragma GCC diagnostic ignored "-Wincomplete-implementation"
#pragma GCC diagnostic ignored "-Wunknown-pragmas"
#pragma GCC diagnostic ignored "-Wformat"
#pragma GCC diagnostic ignored "-Wunknown-warning-option"
#pragma GCC diagnostic ignored "-Wincompatible-pointer-types"
#pragma GCC diagnostic ignored "-Wnullability-completeness"
#pragma GCC diagnostic ignored "-Wunused-but-set-variable" 
#pragma GCC diagnostic ignored "-Wimplicit-function-declaration"
#pragma GCC diagnostic ignored "-Wunused-function"


@implementation CRAAppDelegate

-(BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
	[UNUserNotificationCenter currentNotificationCenter].delegate = self;

	//create UI:
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	
	_rootViewController = [[UINavigationController alloc] initWithRootViewController:[CRARootViewController new]];
	_settingsViewController = [[UINavigationController alloc] initWithRootViewController:[CRASettingsViewController newSettingsController]];

	_tabBarVC = [UITabBarController new];
	_tabBarVC.viewControllers = @[_rootViewController, _settingsViewController];
	_window.rootViewController = _tabBarVC;
	[_window makeKeyAndVisible];
	
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
         
    }];

    [[UIApplication sharedApplication] registerForRemoteNotifications];

	return YES;
}


 

-(void)applicationDidBecomeActive:(UIApplication*)application
{
	//reset badge number:
	[application setApplicationIconBadgeNumber:0];
}

-(void)userNotificationCenter:(UNUserNotificationCenter*)center didReceiveNotificationResponse:(UNNotificationResponse*)response withCompletionHandler:(void (^)(void))completionHandler
{
	NSString* logPath = response.notification.request.content.userInfo[@"logPath"];
	if (logPath.length)
		[self displayLog:logPath];
	if (completionHandler)
		completionHandler();
}

-(void)displayLog:(NSString*)logPath
{
	Log* log = [[Log alloc] initWithPath:logPath];
	CRALogController* logVC = [[CRALogController alloc] initWithLog:log];
	_tabBarVC.selectedViewController = _rootViewController;
	[_rootViewController pushViewController:logVC animated:YES];
}

@end
