//
//  RemoteLoggerServiceProvider.m
//  RemoteLogging
//
//  Created by Igor Mikheiko on 18.07.14.
//  Copyright (c) 2014 *instinctools. All rights reserved.
//

#import "RemoteLoggerServiceProvider.h"
#import "RestKit.h"
#import "OpenUDID.h"

@interface RemoteLoggerErrorResponse : NSObject

@property (nonatomic, retain) NSString *error;

@end

@interface RemoteLoggerEmptyResponse : NSObject

@end

@interface RemoteLoggerSyncResponse : NSObject

@property (nonatomic, retain) NSArray *files;

@end

@interface RemoteLoggerServiceProvider () {
    RKObjectManager *objectManager;
}

@end

@implementation RemoteLoggerErrorResponse

@end

@implementation RemoteLoggerEmptyResponse

@end

@implementation RemoteLoggerSyncResponse

@end

@implementation RemoteLoggerServiceProvider

+ (RemoteLoggerServiceProvider *)sharedInstance
{
    static RemoteLoggerServiceProvider* sharedInstance = nil;
    static dispatch_once_t predicate;
    
    dispatch_once( &predicate, ^{
        sharedInstance = [[RemoteLoggerServiceProvider alloc] initWithBaseURL:REMOTE_LOGGER_BASE_URL];
    });
    
    return sharedInstance;
}

- (id)initWithBaseURL:(NSString *)baseURL
{
    if (self = [super init]) {
        objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:baseURL]];
        objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
        
        RKObjectMapping *errorResponseMapping = [RKObjectMapping mappingForClass:[RemoteLoggerErrorResponse class]];
        [errorResponseMapping addAttributeMappingsFromDictionary:@{@"error":@"error"}];
        
        RKObjectMapping *emptyResponseMapping = [RKObjectMapping mappingForClass:[RemoteLoggerEmptyResponse class]];
        [emptyResponseMapping addAttributeMappingsFromDictionary:@{}];
        
        RKObjectMapping *syncResponceMapping = [RKObjectMapping mappingForClass:[RemoteLoggerSyncResponse class]];
        [syncResponceMapping addAttributeMappingsFromDictionary:@{@"get_logs":@"files"}];
        
        RKResponseDescriptor *errorResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:errorResponseMapping method:RKRequestMethodAny pathPattern:@"sync/:UDID" keyPath:@"sync" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassServerError)];
        [objectManager addResponseDescriptor:errorResponseDescriptor];
        
        RKResponseDescriptor *clientErrorResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:errorResponseMapping method:RKRequestMethodAny pathPattern:@"sync/:UDID" keyPath:@"sync" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassClientError)];
        [objectManager addResponseDescriptor:clientErrorResponseDescriptor];
        
        RKResponseDescriptor *syncResponceDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:syncResponceMapping method:RKRequestMethodAny pathPattern:@"sync/:UDID" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
        [objectManager addResponseDescriptor:syncResponceDescriptor];
    }
    
    return self;
}

- (void)sync:(NSDictionary *)parameters completion:(void (^)(NSError *error, NSArray *files))completion
{
    if (completion == nil) {
        @throw [NSException exceptionWithName:@"RemoteLoggerServiceProvider" reason:@"Completion method is required" userInfo:nil];
    }
    
    NSMutableDictionary *requestParameters = [[NSMutableDictionary alloc] init];
    [requestParameters setObject:([parameters objectForKey:@"logs"]) ? [parameters objectForKey:@"logs"] : @[] forKey:@"logs"];
    
    if ([parameters objectForKey:@"warnings"]) {
        [requestParameters setObject:[parameters objectForKey:@"warnings"] forKey:@"warnings"];
    }
    
    if ([parameters objectForKey:@"errors"]) {
        [requestParameters setObject:[parameters objectForKey:@"errors"] forKey:@"errors"];
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *requestPath = [[NSString alloc] initWithFormat:@"sync/%@", [OpenUDID value]];
        
        [objectManager postObject:nil path:requestPath parameters:requestParameters success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
            RemoteLoggerSyncResponse *result = [mappingResult.array objectAtIndex:0];
            
            if ([result isKindOfClass:[RemoteLoggerSyncResponse class]]) {
                completion(nil, result.files);
            } else {
                completion(nil, @[]);
            }
        } failure:^(RKObjectRequestOperation *operation, NSError *error) {
            completion(error, nil);
        }];
    });
}

- (void)uploadLog:(NSString *)logFilePath completion:(void (^)(NSError *error))completion
{
    if (completion == nil) {
        @throw [NSException exceptionWithName:@"RemoteLoggerServiceProvider" reason:@"Completion method is required" userInfo:nil];
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *requestPath = [[NSString alloc] initWithFormat:@"log/%@", [OpenUDID value]];
        NSMutableURLRequest *request = [objectManager multipartFormRequestWithObject:nil method:RKRequestMethodPOST path:[requestPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:[NSData dataWithContentsOfFile:logFilePath] name:@"log" fileName:[logFilePath lastPathComponent] mimeType:@"text/plain"];
        }];
        
        RKObjectRequestOperation *operation = [objectManager objectRequestOperationWithRequest:request success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
            completion(nil);
        } failure:^(RKObjectRequestOperation *operation, NSError *error) {
            completion(error);
        }];
        [objectManager enqueueObjectRequestOperation:operation];
    });
}

@end
