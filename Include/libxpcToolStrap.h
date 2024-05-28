
@import CoreFoundation;
@import Foundation;
#import <objc/runtime.h>  


@interface libxpcToolStrap : NSObject

@property void (^constHandler)(NSString *msgID,NSDictionary *userInfo);
@property void (^constReplyHandler)(NSString *msgID,NSDictionary *userInfo);


- (NSString *) defineUniqueName:(NSString *)uname;
- (void) postToClientWithMsgID:(NSString *)msgID uName:(NSString *)uname userInfo:(NSDictionary *)dict;
- (void) postToClientAndReceiveReplyWithMsgID:(NSString *)msgID uName:(NSString *)uname userInfo:(NSDictionary *)dict;
- (void) addTarget:(id)target selector:(SEL)sel forMsgID:(NSString *)msgID uName:(NSString *)uName;
- (void) startEventWithMessageIDs:(NSArray<NSString *> *)ids uName:(NSString *)uName;

+ (instancetype) shared;
@end
 