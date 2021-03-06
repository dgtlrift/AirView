//
//  AirViewHTTPConnection.m
//  AirView
//
//  Created by Łukasz Przytuła on 06.05.2015.
//
//

#import "AirViewHTTPConnection.h"
#import <Foundation/NSCharacterSet.h>
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "HTTPReverseResponse.h"
#import "HTTPLogging.h"
#import "AirViewHTTPConfig.h"
#import "AirViewServerInfo.h"
#import "airtunesd_wrapper.h"

const int httpLogLevel = HTTP_LOG_LEVEL_VERBOSE;

@implementation AirViewHTTPConnection

- (instancetype)initWithAsyncSocket:(GCDAsyncSocket *)newSocket configuration:(HTTPConfig *)aConfig {
    self = [super initWithAsyncSocket:newSocket configuration:aConfig];
    if (self) {
        self.serverInfo = [[AirViewServerInfo alloc] init];
        
        NSMutableDictionary *supportedMethods = [[NSMutableDictionary alloc] init];
        if (self.supportedGETEndpoints) {
            supportedMethods[@"GET"] = self.supportedGETEndpoints;
        }
        if (self.supportedPOSTEndpoints) {
            supportedMethods[@"POST"] = self.supportedPOSTEndpoints;
        }
        if (self.supportedPUTEndpoints) {
            supportedMethods[@"PUT"] = self.supportedPUTEndpoints;
        }
        self.supportedMethodsAndPaths = supportedMethods;
    }
    return self;
}

- (void)prepareForBodyWithSize:(UInt64)contentLength {
//    HTTPLogTrace();
    
//    HTTPLogVerbose(@"prepareForBodyWithSize %qu", contentLength);
}


- (void)processDataChunk:(NSData *)postDataChunk {
//    HTTPLogTrace();
    
    BOOL result = [request appendData:postDataChunk];
    if (!result) {
//        NSLog(@"Couldn't append bytes!");
    }
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
//    HTTPLogTrace();
    
    if ([self.supportedMethodsAndPaths.allKeys containsObject:method]) {
        NSDictionary *supportedPaths = self.supportedMethodsAndPaths[method];
        for (NSString *pathPrefix in supportedPaths.allKeys) {
            if ([path hasPrefix:pathPrefix]) {
//                HTTPLogError(@"%@: path %@, method %@", [self class], path, method);
                return YES;
            }
        }
    }
    
//    HTTPLogError(@"%@: path %@ not supported for method %@", [self class], path, method);
    
    return [super supportsMethod:method atPath:path];
}

#pragma mark - Helpers

- (AirViewController *)airplay {
    AirViewHTTPConfig *cfg = [config isKindOfClass:[AirViewHTTPConfig class]] ? (id)config : nil;
    return cfg.airplay;
}

- (BOOL)isPlistRequest {
    return [request.allHeaderFields[@"Content-Type"] isEqualToString:@"application/x-apple-binary-plist"];
}

- (NSDictionary *)dictFromPlistBody {
    NSDictionary *dict;
    NSString *error;
    dict = (NSDictionary *)[NSPropertyListSerialization
                                          propertyListFromData:[request body]
                                          mutabilityOption:NSPropertyListImmutable
                                          format:NULL
                                          errorDescription:&error ];
    return dict;
}

#pragma mark - Supported endpoints

- (NSDictionary *)supportedGETEndpoints {
    return nil;
}

- (NSDictionary *)supportedPOSTEndpoints {
    return nil;
}

- (NSDictionary *)supportedPUTEndpoints {
    return nil;
}

#pragma mark - Responses for supported endpoints

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    NSString *methodName = [NSString stringWithFormat:@"%@_%@", method, self.supportedMethodsAndPaths[method][path]];
    SEL selector = NSSelectorFromString(methodName);
    if ([self respondsToSelector:selector]) {
        id response = [self performSelector:selector];
        return response;
    }
    return [super httpResponseForMethod:method URI:path];
}

@end
