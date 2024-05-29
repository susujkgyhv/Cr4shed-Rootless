@import CoreFoundation;
@import Foundation;

 
#include <pthread.h>
#include <time.h>
#include <dlfcn.h>
#import <objc/runtime.h>  
#include <xpc/xpc.h>



#pragma GCC diagnostic ignored "-Wunused-function"
#pragma GCC diagnostic ignored "-Wobjc-property-no-attribute"

#define CLogLib(format, ...) NSLog(@"CM90~[libxpcToolStrap] : " format, ##__VA_ARGS__)


typedef enum {
	CR4SHEDD_MESSAGE_SHOULD_LOG_JETSAM,
	CR4SHEDD_MESSAGE_IS_PROCESS_BLACKLISTED,
	CR4SHEDD_MESSAGE_STRING_FROM_TIME,
	CR4SHEDD_MESSAGE_SEND_NOTIFICATION,
	CR4SHEDD_MESSAGE_WRITE_STRING,
} CR4SHEDD_MESSAGE_ID;



static NSDictionary *convertXPCDictionaryToNSDictionary(xpc_object_t xpcDict) {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    xpc_dictionary_apply(xpcDict, ^bool(const char *key, xpc_object_t value) {
        @try {
            if (key == NULL || value == NULL) {
                // CLogLib(@"Skipping null key or value");
                return true;
            }

            NSString *nsKey = [NSString stringWithUTF8String:key];
            id nsValue = nil;
            
            xpc_type_t valueType = xpc_get_type(value);
            if (valueType == XPC_TYPE_STRING) {
                nsValue = [NSString stringWithUTF8String:xpc_string_get_string_ptr(value)];
            } else if (valueType == XPC_TYPE_INT64) {
                nsValue = [NSNumber numberWithLongLong:xpc_int64_get_value(value)];
            } else if (valueType == XPC_TYPE_BOOL) {
                nsValue = [NSNumber numberWithBool:xpc_bool_get_value(value)];
            } else if (valueType == XPC_TYPE_DOUBLE) {
                nsValue = [NSNumber numberWithDouble:xpc_double_get_value(value)];
            } else if (valueType == XPC_TYPE_ARRAY) {
            } else if (valueType == XPC_TYPE_DICTIONARY) {
                nsValue = convertXPCDictionaryToNSDictionary(value);
            } else {
                // CLogLib(@"Unsupported XPC type");
            }

            if (nsValue) {
                dict[nsKey] = nsValue;
            } else {
                // CLogLib(@"Null nsValue for key: %@", nsKey);
            }
        } @catch (NSException *exception) {
            // CLogLib(@"Exception converting key %s: %@", key, exception);
        }

        return true;
    });
    return [dict copy];
}

static xpc_object_t convertNSDictionaryToXPCDictionary(NSDictionary *dict) {
    xpc_object_t xpcDict = xpc_dictionary_create(NULL, NULL, 0);
    
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![key isKindOfClass:[NSString class]]) {
            // CLogLib(@"Skipping non-string key: %@", key);
            return;
        }

        const char *cKey = [key UTF8String];
        
        if ([obj isKindOfClass:[NSString class]]) {
            xpc_dictionary_set_string(xpcDict, cKey, [obj UTF8String]);
        } else if ([obj isKindOfClass:[NSNumber class]]) {

            const char *objCType = [obj objCType];
            if (strcmp(objCType, @encode(BOOL)) == 0) {
                xpc_dictionary_set_bool(xpcDict, cKey, [obj boolValue]);
            } else if (strcmp(objCType, @encode(int)) == 0 ||
                       strcmp(objCType, @encode(long)) == 0 ||
                       strcmp(objCType, @encode(long long)) == 0 ||
                       strcmp(objCType, @encode(short)) == 0 ||
                       strcmp(objCType, @encode(char)) == 0) {
                xpc_dictionary_set_int64(xpcDict, cKey, [obj longLongValue]);
            } else if (strcmp(objCType, @encode(float)) == 0 ||
                       strcmp(objCType, @encode(double)) == 0) {
                xpc_dictionary_set_double(xpcDict, cKey, [obj doubleValue]);
            } else {
                // CLogLib(@"Unsupported NSNumber type for key: %@", key);
            }
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            xpc_object_t nestedDict = convertNSDictionaryToXPCDictionary((NSDictionary *)obj);
            xpc_dictionary_set_value(xpcDict, cKey, nestedDict);

        } else {
            // CLogLib(@"Unsupported type for key: %@", key);
        }
    }];
    
    return xpcDict;
}
 

static NSString *toString(const char *a1) {

    if (!a1) {
    return @"toString() got a NULL arg";
    }
    return [NSString stringWithUTF8String:a1];
}

#define CLog(fmt, ...) NSLog(@"CM90 : " fmt, ##__VA_ARGS__)

static xpc_object_t cr4sheddSendMessage(xpc_object_t message)
{
	xpc_connection_t connection = xpc_connection_create_mach_service("com.muirey03.cr4shedd", 0, XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);
	xpc_connection_set_event_handler(connection, ^(xpc_object_t object){
        xpc_type_t type = xpc_get_type(connection);
        if (type == XPC_TYPE_CONNECTION) { 

            // // CLog(@"[++] connected to com.muirey03.cr4shedd daemon");
        } else if (type == XPC_TYPE_ERROR) {
				// CLog(@"[--] XPC server error: %s", xpc_dictionary_get_string(connection, XPC_ERROR_KEY_DESCRIPTION));
			}
    });
	xpc_connection_resume(connection);

	return xpc_connection_send_message_with_reply_sync(connection, message);
}

static NSDictionary *sendAndReceiveMessage(NSDictionary *userInfoDict, CR4SHEDD_MESSAGE_ID type){

	xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
	xpc_dictionary_set_int64(message, "id", type);
	xpc_object_t userInfo = convertNSDictionaryToXPCDictionary(userInfoDict);
	xpc_dictionary_set_value(message, "userInfo", userInfo);
	
	xpc_object_t reply = cr4sheddSendMessage(message);
	if (reply) {
		xpc_type_t replyType = xpc_get_type(reply);
		if (replyType == XPC_TYPE_DICTIONARY) {
			xpc_object_t userInfo_reply = xpc_dictionary_get_value(reply, "userInfo");
			xpc_type_t userInfo_type = xpc_get_type(userInfo_reply);
			if (userInfo_type == XPC_TYPE_DICTIONARY) {
				return convertXPCDictionaryToNSDictionary(userInfo_reply);
			}
		}
	}

    return @{};
}