//
//  RemoteLogger.m
//  RemoteLogging
//
//  Created by Igor Mikheiko on 18.07.14.
//  Copyright (c) 2014 *instinctools. All rights reserved.
//

#import "RemoteLogger.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "RemoteLoggerServiceProvider.h"


@interface RemoteLogger () {
    DDFileLogger *fileLogger;
    RemoteLoggerServiceProvider *serviceProvider;
}

- (void)info:(NSString *)format arguments:(va_list)argList;
- (void)warn:(NSString *)format arguments:(va_list)argList;
- (void)error:(NSString *)format arguments:(va_list)argList;
- (void)verbose:(NSString *)format arguments:(va_list)argList;
- (void)debug:(NSString *)format arguments:(va_list)argList;

@end

void RLLog(NSString *format, ...) {
    if (format) {
        va_list argList;
        
        va_start(argList, format);
        [[RemoteLogger sharedInstance] verbose:format arguments:argList];
        va_end(argList);
    }
}


@implementation RemoteLogger

static int ddLogLevel = LOG_LEVEL_ALL;

+ (RemoteLogger *)sharedInstance
{
    static RemoteLogger *sharedInstance = nil;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        sharedInstance = [[RemoteLogger alloc] init];
    });
    
    return sharedInstance;
}

+ (void)info:(NSString *)format, ...
{
    if (format) {
        va_list argList;
        
        va_start(argList, format);
        [[self sharedInstance] info:format arguments:argList];
        va_end(argList);
    }
}

+ (void)error:(NSString *)format, ...
{
    if (format) {
        va_list argList;
        
        va_start(argList, format);
        [[self sharedInstance] error:format arguments:argList];
        va_end(argList);
    }
}

+ (void)warn:(NSString *)format, ...
{
    if (format) {
        va_list argList;
        
        va_start(argList, format);
        [[self sharedInstance] warn:format arguments:argList];
        va_end(argList);
    }
}

+ (void)verbose:(NSString *)format, ...
{
    if (format) {
        va_list argList;
        
        va_start(argList, format);
        [[self sharedInstance] verbose:format arguments:argList];
        va_end(argList);
    }
}

+ (void)debug:(NSString *)format, ...
{
    if (format) {
        va_list argList;
        
        va_start(argList, format);
        [[self sharedInstance] debug:format arguments:argList];
        va_end(argList);
    }
}

+ (int)logLevel
{
    return ddLogLevel;
}

+ (void)setLogLevel:(int)logLevel
{
    ddLogLevel = logLevel;
}

- (id)init
{
    if (self = [super init]) {
        [DDLog addLogger:[DDASLLogger sharedInstance]];
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
        
        fileLogger = [[DDFileLogger alloc] init];
        fileLogger.rollingFrequency = 60 * 60 * 12;
        fileLogger.logFileManager.maximumNumberOfLogFiles = 14;
        
        [DDLog addLogger:fileLogger];
        
        serviceProvider = [[RemoteLoggerServiceProvider alloc] initWithBaseURL:REMOTE_LOGGER_BASE_URL];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self sync];
        });
    }
    
    return self;
}

- (void)sync
{
    NSMutableArray *logFiles = [[NSMutableArray alloc] init];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    for (NSString *logFilePath in [fileLogger.logFileManager sortedLogFilePaths]) {
        [logFiles addObject:[logFilePath lastPathComponent]];
    }
    
    [params setObject:logFiles forKey:@"logs"];
        
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"RemoteLoggerErrorLogCounter"]) {
        [params setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"RemoteLoggerErrorLogCounter"] forKey:@"errors"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"RemoteLoggerWarnLogCounter"]) {
        [params setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"RemoteLoggerWarnLogCounter"] forKey:@"warnings"];
    }
    
    [serviceProvider sync:@{@"logs":logFiles} completion:^(NSError *error, NSArray *files) {
        if (error == nil) {
            dispatch_queue_t uploadQueue = dispatch_queue_create("RemoteLoggerUploadQueue", NULL);
            BOOL __block containsUploadErrors = NO;
            
            for (NSString *file in files) {
                dispatch_async(uploadQueue, ^{
                    NSString * __block fileToUpload = [[fileLogger.logFileManager logsDirectory] stringByAppendingPathComponent:file];

                    [serviceProvider uploadLog:fileToUpload completion:^(NSError *error) {
                        if (error) {
                            containsUploadErrors = YES;
                        }
                    }];
                });
            }
            
            dispatch_async(uploadQueue, ^{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (containsUploadErrors) ? 60 * NSEC_PER_SEC : 60 * 60 * NSEC_PER_SEC), dispatch_get_global_queue(0, 0), ^{
                    [self sync];
                });
            });
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 60 * 60 * NSEC_PER_SEC), dispatch_get_global_queue(0, 0), ^{
                [self sync];
            });
        }
    }];
}

- (void)info:(NSString *)format, ...
{
    if (format) {
        va_list argList;
        
        va_start(argList, format);
        [self info:format arguments:argList];
        va_end(argList);
    }
}

- (void)error:(NSString *)format, ...
{
    if (format) {
        va_list argList;
        
        va_start(argList, format);
        [self error:format arguments:argList];
        va_end(argList);
    }
}

- (void)warn:(NSString *)format, ...
{
    if (format) {
        va_list argList;
        
        va_start(argList, format);
        [self warn:format arguments:argList];
        va_end(argList);
    }
}

- (void)verbose:(NSString *)format, ...
{
    if (format) {
        va_list argList;
        
        va_start(argList, format);
        [self verbose:format arguments:argList];
        va_end(argList);
    }
}

- (void)debug:(NSString *)format, ...
{
    if (format) {
        va_list argList;
        
        va_start(argList, format);
        [self debug:format arguments:argList];
        va_end(argList);
    }
}

- (void)info:(NSString *)format arguments:(va_list)argList
{
//    NSNumber *counter = [[NSUserDefaults standardUserDefaults] objectForKey:@"RemoteLoggerInfoLogCounter"];
//    
//    if (counter) {
//        counter = [NSNumber numberWithInt:[counter intValue] + 1];
//    } else {
//        counter = @1;
//    }
    
    DDLogInfo([[NSString alloc] initWithFormat:format arguments:argList]);
//    [[NSUserDefaults standardUserDefaults] setObject:counter forKey:@"RemoteLoggerInfoLogCounter"];
}

- (void)error:(NSString *)format arguments:(va_list)argList
{
    NSNumber *counter = [[NSUserDefaults standardUserDefaults] objectForKey:@"RemoteLoggerErrorLogCounter"];
    
    if (counter) {
        counter = [NSNumber numberWithInt:[counter intValue] + 1];
    } else {
        counter = @1;
    }
    
    DDLogError([[NSString alloc] initWithFormat:format arguments:argList]);
    [[NSUserDefaults standardUserDefaults] setObject:counter forKey:@"RemoteLoggerErrorLogCounter"];
}

- (void)warn:(NSString *)format arguments:(va_list)argList
{
    NSNumber *counter = [[NSUserDefaults standardUserDefaults] objectForKey:@"RemoteLoggerWarnLogCounter"];
    
    if (counter) {
        counter = [NSNumber numberWithInt:[counter intValue] + 1];
    } else {
        counter = @1;
    }
    
    DDLogWarn([[NSString alloc] initWithFormat:format arguments:argList]);
    [[NSUserDefaults standardUserDefaults] setObject:counter forKey:@"RemoteLoggerWarnLogCounter"];
}

- (void)verbose:(NSString *)format arguments:(va_list)argList
{
//    NSNumber *counter = [[NSUserDefaults standardUserDefaults] objectForKey:@"RemoteLoggerVerboseLogCounter"];
//    
//    if (counter) {
//        counter = [NSNumber numberWithInt:[counter intValue] + 1];
//    } else {
//        counter = @1;
//    }
    
    DDLogVerbose([[NSString alloc] initWithFormat:format arguments:argList]);
//    [[NSUserDefaults standardUserDefaults] setObject:counter forKey:@"RemoteLoggerVerboseLogCounter"];
}

- (void)debug:(NSString *)format arguments:(va_list)argList
{
//    NSNumber *counter = [[NSUserDefaults standardUserDefaults] objectForKey:@"RemoteLoggerDebugLogCounter"];
//    
//    if (counter) {
//        counter = [NSNumber numberWithInt:[counter intValue] + 1];
//    } else {
//        counter = @1;
//    }
    
    DDLogDebug([[NSString alloc] initWithFormat:format arguments:argList]);
//    [[NSUserDefaults standardUserDefaults] setObject:counter forKey:@"RemoteLoggerDebugLogCounter"];
}

@end
