#import "CRAAppDelegate.h"

@import Foundation;

#include <stdlib.h>
#include <signal.h>
#include <uuid/uuid.h>
#include <mach/mach.h>
#import <sharedutils.h>
   
 
int main(int argc, char * argv[]) {
    @autoreleasepool {

		return UIApplicationMain(argc, argv, nil, NSStringFromClass(CRAAppDelegate.class));
    }
}