// By @CrazyMind90

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
#pragma clang diagnostic ignored "-Wnullability-completeness"
#pragma GCC diagnostic ignored "-Wunused-variable"
#pragma GCC diagnostic ignored "-Wprotocol"
#pragma GCC diagnostic ignored "-Wmacro-redefined"
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#pragma GCC diagnostic ignored "-Wincomplete-implementation"
#pragma GCC diagnostic ignored "-Wunguarded-availability-new"

#import <UIKit/UIKit.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <spawn.h>
#include <CommonCrypto/CommonDigest.h>
#include <CoreFoundation/CoreFoundation.h>
#include <stdint.h>
#include <stdio.h>
 


// NSTask.h
#import <Foundation/NSObject.h>

@class NSString, NSArray, NSDictionary;

@interface NSTask : NSObject

// Create an NSTask which can be run at a later time
// An NSTask can only be run once. Subsequent attempts to
// run an NSTask will raise.
// Upon task death a notification will be sent
//   { Name = NSTaskDidTerminateNotification; object = task; }
//

- (instancetype)init;

// set parameters
// these methods can only be done before a launch
- (void)setLaunchPath:(NSString *)path;
- (void)setArguments:(NSArray *)arguments;
- (void)setEnvironment:(NSDictionary *)dict;
// if not set, use current
- (void)setCurrentDirectoryPath:(NSString *)path;
// if not set, use current

// set standard I/O channels; may be either an NSFileHandle or an NSPipe
- (void)setStandardInput:(id)input;
- (void)setStandardOutput:(id)output;
- (void)setStandardError:(id)error;

// get parameters
- (NSString *)launchPath;
- (NSArray *)arguments;
- (NSDictionary *)environment;
- (NSString *)currentDirectoryPath;

// get standard I/O channels; could be either an NSFileHandle or an NSPipe
- (id)standardInput;
- (id)standardOutput;
- (id)standardError;

// actions
- (void)launch;

- (void)interrupt; // Not always possible. Sends SIGINT.
- (void)terminate; // Not always possible. Sends SIGTERM.

- (BOOL)suspend;
- (BOOL)resume;

// status
- (int)processIdentifier;
- (BOOL)isRunning;

- (int)terminationStatus;

@end

@interface NSTask (NSTaskConveniences)

+ (NSTask *)launchedTaskWithLaunchPath:(NSString *)path arguments:(NSArray *)arguments;
// convenience; create and launch

- (void)waitUntilExit;
// poll the runLoop in defaultMode until task completes

@end

FOUNDATION_EXPORT NSString * const NSTaskDidTerminateNotification;






#import <spawn.h>
#import <sys/sysctl.h>


#pragma GCC diagnostic ignored "-Wc++11-compat-deprecated-writable-strings"
#pragma GCC diagnostic ignored "-Wwritable-strings"

#define _POSIX_SPAWN_DISABLE_ASLR 0x0100
#define _POSIX_SPAWN_ALLOW_DATA_EXEC 0x2000
extern char **environ;

static NSString *RunCMDWithLog(NSString *runCMDWithLog) {

    const char *cmd = runCMDWithLog.UTF8String;
    char buffer[128];
    NSMutableString *output = [NSMutableString string];

    int pipefd[2];
    pid_t pid;

    if (pipe(pipefd) != 0) {
        return nil;
    }
    const char *argv[] = {"sh", "-c", cmd, NULL};
    int status;

    char *env[] = {
        "PATH=/usr/local/sbin:/var/jb/usr/local/sbin:/usr/local/bin:/var/jb/usr/local/bin:/usr/sbin:/var/jb/usr/sbin:/usr/bin:/var/jb/usr/bin:/sbin:/var/jb/sbin:/bin:/var/jb/bin:/usr/bin/X11:/var/jb/usr/bin/X11:/usr/games:/var/jb/usr/games", "NO_PASSWORD_PROMPT=1", NULL 
    };

    posix_spawn_file_actions_t action;
    posix_spawn_file_actions_init(&action);
    posix_spawn_file_actions_addclose(&action, pipefd[0]);
    posix_spawn_file_actions_adddup2(&action, pipefd[1], STDOUT_FILENO);
    posix_spawn_file_actions_addclose(&action, pipefd[1]);

    status = posix_spawn(&pid, "/var/jb/bin/bash", &action, NULL, (char* const*)argv, isRootHide() ? environ : env);

    if (status == 0) {
        close(pipefd[1]);

        while (1) {
            ssize_t bytesRead = read(pipefd[0], buffer, sizeof(buffer)-1);
            if (bytesRead <= 0) {
                break; 
            }
            buffer[bytesRead] = '\0';
            [output appendString:[NSString stringWithUTF8String:buffer]];
        }

        close(pipefd[0]);
    }

    posix_spawn_file_actions_destroy(&action);

    return output;
}



