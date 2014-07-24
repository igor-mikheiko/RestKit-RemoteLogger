//
//  RemoteLoggerServiceProvider.h
//  RemoteLogging
//
//  Created by Igor Mikheiko on 18.07.14.
//  Copyright (c) 2014 *instinctools. All rights reserved.
//

#import <Foundation/Foundation.h>

#define REMOTE_LOGGER_BASE_URL        @"http://localhost:8080/"

@interface RemoteLoggerServiceProvider : NSObject

- (id)initWithBaseURL:(NSString *)baseURL;
- (void)sync:(NSDictionary *)parameters completion:(void (^)(NSError *error, NSArray *files))completion;
- (void)uploadLog:(NSString *)logFilePath completion:(void (^)(NSError *error))completion;

@end
