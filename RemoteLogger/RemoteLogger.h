//
//  RemoteLogger.h
//  RemoteLogging
//
//  Created by Igor Mikheiko on 18.07.14.
//  Copyright (c) 2014 *instinctools. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDLog.h"

#define NSLog(format, ...) RLLog(format, ##__VA_ARGS__)

void RLLog(NSString *format, ...);

@interface RemoteLogger : NSObject

+ (RemoteLogger *)sharedInstance;
+ (void)info:(NSString *)format, ...;
+ (void)error:(NSString *)format, ...;
+ (void)warn:(NSString *)format, ...;
+ (void)verbose:(NSString *)format, ...;
+ (void)debug:(NSString *)format, ...;
+ (int)logLevel;
+ (void)setLogLevel:(int)logLevel;

- (void)info:(NSString *)format, ...;
- (void)error:(NSString *)format, ...;
- (void)warn:(NSString *)format, ...;
- (void)verbose:(NSString *)format, ...;
- (void)debug:(NSString *)format, ...;

@end
