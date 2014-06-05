//
//  WXLog.m
//  WXMessengerKit
//
//  Created by 慕桥(黄玉坤) on 13-6-26.
//  Copyright (c) 2013年 taobao. All rights reserved.
//

#import "WXLog.h"
#import "ZipArchive.h"
#import "Reachability.h"
#import "WXClientUtils.h"
#import "ASIFormDataRequest.h"

#import "NSBundle+Extensions.h"
#import "iConsole.h"

#import <pthread.h>

#include <libkern/OSAtomic.h>
#include <execinfo.h>

//NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
//NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
//NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";
//const NSInteger UncaughtExceptionHandlerSkipAddressCount = 0;
//const NSInteger UncaughtExceptionHandlerReportAddressCount = 5;


#define WXLOG_ESC_CH @"\033"
// colors for log level, change it as your wish
#define WXLOG_COLOR_RED     WXLOG_ESC_CH @"#E8202A"
#define WXLOG_COLOR_GREEN   WXLOG_ESC_CH @"#7CFC00"
#define WXLOG_COLOR_BROWN   WXLOG_ESC_CH @"#DAA520"
#define WXLOG_COLOR_BLUE    WXLOG_ESC_CH @"#4169E1"
#define WXLOG_COLOR_WHITE   WXLOG_ESC_CH @"#FFFFFF"

// hard code, use 00000m for reset flag
#define WXLOG_COLOR_RESET   WXLOG_ESC_CH @"#00000m"

#define WXLOG_LEVEL_DEBUG_TAG   @"DEBUG"
#define WXLOG_LEVEL_INFO_TAG    @"INFO"
#define WXLOG_LEVEL_WARN_TAG    @"WARN"
#define WXLOG_LEVEL_ERROR_TAG   @"ERROR"

static NSDictionary *sWXLogDic = nil;
static NSString *s_path = nil;
static NSMutableString *s_logStringCache = nil;

pthread_mutex_t file_lock = PTHREAD_MUTEX_INITIALIZER;

@interface WXLogUtils()
@property (atomic, strong) NSMutableDictionary *dateFormatterDic;
@end

@implementation WXLogUtils
IMPLEMENT_SINGLETON_FOR_CLASS(WXLogUtils)

+ (dispatch_queue_t)sharedWXLogQueue
{
    static dispatch_queue_t _wxLogQueue = NULL;
    if (!_wxLogQueue) {
        @synchronized (self) {
            if (!_wxLogQueue) {
                dispatch_queue_t targeQqueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
                _wxLogQueue = dispatch_queue_create("WX_LOG_QUEUE_LABEL", DISPATCH_QUEUE_SERIAL);
                dispatch_set_target_queue(_wxLogQueue, targeQqueue);
            }
        }
    }
    
    return _wxLogQueue;
}

+ (NSString *)getLogLevelTag:(NSInteger)level
{
    NSString *levelTag = @"INFO";
    switch(level)
    {
        case WXLOGLEVEL_ERROR: {
            levelTag =  WXLOG_LEVEL_ERROR_TAG;
        } break;
        case WXLOGLEVEL_WARNING: {
            levelTag =  WXLOG_LEVEL_WARN_TAG;
        } break;
        case WXLOGLEVEL_INFO: {
            levelTag =  WXLOG_LEVEL_INFO_TAG;
        } break;
        case WXLOGLEVEL_DEBUG: {
            levelTag =  WXLOG_LEVEL_DEBUG_TAG;
        } break;
        default: {
        } break;
    }
    
    return levelTag;
}

+ (NSString *)getLogLevelColor:(NSInteger)level
{
    NSString *color = WXLOG_COLOR_WHITE;
    
    switch(level)
    {
        case WXLOGLEVEL_ERROR: {
            color =  WXLOG_COLOR_RED;
        } break;
        case WXLOGLEVEL_WARNING: {
            color =  WXLOG_COLOR_BROWN;
        } break;
        case WXLOGLEVEL_INFO: {
            color =  WXLOG_COLOR_GREEN;
        } break;
        case WXLOGLEVEL_DEBUG: {
            color =  WXLOG_COLOR_BLUE;
        } break;
        default: {
        } break;
    }
    
    return color;
}

+ (BOOL) isLogOutFileEnable:(NSString *)logName ofLevel:(NSInteger)level
{
//#ifdef DEBUG
//    return YES;
//#endif
    if (!sWXLogDic)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"WXLog" ofType:@"plist"];
        sWXLogDic = [NSDictionary dictionaryWithContentsOfFile:path];
    }
    
    NSNumber *lvOutFile = [sWXLogDic objectForKey:logName];
    if (!lvOutFile) return NO;
    
    return [lvOutFile unsignedIntValue] >= level ? YES : NO;
}

+ (BOOL)setLogOutFileLevel:(int)level
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:@"WXLog.plist"];
    
    //现在假设都写在bundle里
    path = [[NSBundle mainBundle] pathForResource:@"WXLog" ofType:@"plist"];
    NSMutableDictionary* mutableDic = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    [mutableDic setObject:@(level) forKey:kWXLogCommonEnable];
    
    sWXLogDic = mutableDic?:@{kWXLogCommonEnable:@(level)};
    
    return YES;
}

- (void)submitWXLog
{
    dispatch_queue_t queue = [WXLogUtils sharedWXLogQueue];//dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_async(queue, ^{
        
        NSFileManager* sharedFM = [NSFileManager defaultManager];
        if(sharedFM == nil) return;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentpath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        
        NSString *logPath = [documentpath stringByAppendingPathComponent:WXLog_Common];
        if (![sharedFM fileExistsAtPath:logPath isDirectory:NULL]) return;
        
        // 压缩文件
        ZipArchive* zip = [[ZipArchive alloc] init];
        
        NSString* zipPath = [documentpath stringByAppendingString:@"/WXLog.zip"] ;
        BOOL result = [zip CreateZipFile2:zipPath Password:@"A98765432B"];
        if ( !result ) return;
        
        [zip addFileToZip:logPath newname:WXLog_Common];
        [zip CloseZipFile2];
        
        if([sharedFM fileExistsAtPath:zipPath isDirectory:NULL])
        {
            NSData* data = [sharedFM contentsAtPath:zipPath];
            if( data == nil || data.length == 0 ) return;
            
            NSURL *urlerror = [NSURL URLWithString:@"http://wangxin.taobao.com/up_pass/wxerrorup.php"];
            ASIFormDataRequest *requestErrorReport = [ASIFormDataRequest requestWithURL:urlerror];
            
            [requestErrorReport setUsername:@"wangwangreport"];
            [requestErrorReport setPassword:@"xG2Fc2HvMVSxs"];
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd_HH_mm_ss.SSSZ"];
            NSString *submitTime = [dateFormatter stringFromDate:[NSDate date]];
            
            NSString *fileFullName = nil;
          fileFullName = [NSString stringWithFormat:@"WXLog_%@v%@_@%@", submitTime,
                                      self.appVersion,[WXUserConfig getUserId]];
            
            [requestErrorReport setFile:zipPath withFileName:fileFullName andContentType:@"zip" forKey:@"upfile"];
            [requestErrorReport startSynchronous];
            
            NSString * responseResult = [requestErrorReport responseString];
            WXDEBUG(@"SubmitAssetionHitLog Response Result:%@", responseResult);
            
            if(requestErrorReport.responseStatusCode == 200)
            {
                [sharedFM removeItemAtPath:logPath error:nil];
            }
            
            [sharedFM removeItemAtPath:zipPath error:nil];
        }
        
    });
}

+ (void)clearLogFileIfNeed
{
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if ([dirs count] == 0) return;
    
    NSArray *aryLogFilePath = @[WXLog_Common, WXLog_Login];
    
    for (NSString *filePath in aryLogFilePath)
    {
        NSString *logPath = [[dirs objectAtIndex:0] stringByAppendingPathComponent:filePath];
        NSFileManager* manager = [NSFileManager defaultManager];
        
        if (![manager fileExistsAtPath:logPath]) return;
        long long nsize = [[manager attributesOfItemAtPath:logPath error:nil] fileSize];
        if (nsize > 1024*1024)
        {
            [manager removeItemAtPath:logPath error:nil];
        }
    }
}

+(void)outputLogInfoColorful:(NSString *)logInfo logHead:(NSString *)logHead level:(NSInteger)level   // 将日志输出控制台
{
    NSString *lv_tag = [WXLogUtils getLogLevelTag:level];
    NSString *color = [WXLogUtils getLogLevelColor:level];
    
    printf("%s", [color UTF8String]);
    printf("%s[%s]", [WXLOG_ESC_CH UTF8String], [lv_tag UTF8String]);
    
    printf("\n%s ", [[[NSDate date] description] UTF8String]);
    if(0 == DISABLE_MORE_INFO_LOG)
    {
        printf("%s", [logHead UTF8String]);
    }
    
    printf("%s", [logInfo UTF8String]);
    
    printf("%s[/%s]", [WXLOG_ESC_CH UTF8String], [lv_tag UTF8String]);
    printf("%s", [WXLOG_COLOR_RESET UTF8String]);
    
    printf("\n");
}

+ (void)outputLogInfoToFile:(NSString *)path logInfo:(NSString *)logInfo logHead:(NSString *)logHead level:(NSInteger)level        // 将日志写文件
{
    try {
        if ( [path length] == 0 ) return;
        
        WXLogUtils *logUtilsSharedIns = [WXLogUtils sharedInstance];
        NSDateFormatter *formatter = nil;
        
        @synchronized( logUtilsSharedIns.dateFormatterDic )
        {
            if ( logUtilsSharedIns.dateFormatterDic == nil )
            {
                logUtilsSharedIns.dateFormatterDic = [NSMutableDictionary dictionary];
            }
            
            NSString *thread = [NSString stringWithFormat:@"%p",[NSThread currentThread]];
            formatter = [logUtilsSharedIns.dateFormatterDic objectForKey:thread];
            if ( formatter == nil )
            {
                formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
                if ( formatter!= nil && thread != nil )
                {
                    [logUtilsSharedIns.dateFormatterDic setObject:formatter forKey:thread];
                }
            }
        }
        
		NSString *dateTime = [formatter stringFromDate:[NSDate date]];
        NSString *lvTag = [WXLogUtils getLogLevelTag:level];
		
		NSString *logText = [NSString stringWithFormat:@"%@ [ %@ ]\n%@ : %@ \n\n", dateTime, lvTag, logHead, logInfo];
		dispatch_queue_t queue = [WXLogUtils sharedWXLogQueue];//dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
		dispatch_async(queue, ^{
            
            pthread_mutex_lock(&file_lock);
            
            BOOL ouputSameFile = [path isEqualToString:s_path];
            
            if ( !s_logStringCache ) { s_logStringCache = [[NSMutableString alloc] init]; }
            if ( !ouputSameFile || s_logStringCache.length > 1024 * 32 )
            {
                FILE *file = fopen([s_path UTF8String], "ab");
                fwrite([s_logStringCache UTF8String], strlen([s_logStringCache UTF8String]), 1, file);
                fclose(file);
                
                RELEASE_SAFELY(s_logStringCache);
                s_logStringCache = [[NSMutableString alloc] init];
            }
            
            [s_logStringCache appendString:logText];
            
            if ( !ouputSameFile )
            {
                RELEASE_SAFELY(s_path);
                s_path = path;
            }
            
            pthread_mutex_unlock(&file_lock);
		});
	}
	catch (NSException *exception) {
		NSLog(@"WXLog Output Exception:%@", exception);
    }
}

+ (void)outputLog2iConsoleWithLogInfo:(NSString *)logInfo level:(NSInteger)level
{
    if ( ![self iConsoleEnabled] ) return;
    switch(level)
    {
        case WXLOGLEVEL_ERROR: {
            [iConsole error:@"%@", logInfo];
        } break;
        case WXLOGLEVEL_WARNING: {
            [iConsole warn:@"%@", logInfo];
        } break;
        case WXLOGLEVEL_INFO: {
            [iConsole info:@"%@", logInfo];
        } break;
        case WXLOGLEVEL_DEBUG:
        default: {
            [iConsole log:@"%@", logInfo];
        } break;
    }
}

+ (void)hitAssertionWithDesc:(NSString *)desc code:(NSString *)code
{    
    dispatch_queue_t queue = [WXLogUtils sharedWXLogQueue];//dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_async(queue, ^{
        NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *logWritePath = [[dirs objectAtIndex:0] stringByAppendingPathComponent:WXLog_Assertion];
        NSString *logReadPath = [[dirs objectAtIndex:0] stringByAppendingPathComponent:WXLog_Common];
        
        try {
            NSString *logText = nil ;
            NSMutableString *assertDesc = [NSMutableString string];
            long filesize = 0;
            FILE *file_read = fopen([logReadPath UTF8String], "r");
            if( file_read != NULL )
            {
                fseek(file_read, 0, SEEK_END);
                filesize = ftell(file_read);
                //获取后10k的用户日志
                long readStart = filesize - MIN(filesize, 1024*10);
                fseek(file_read, readStart, SEEK_SET );
                
                char char_array[MIN(filesize, 1024*10)];
                memset (char_array, 0, sizeof(char_array));
                
                fread((void*)&char_array, sizeof(char_array), 1, file_read);
                fclose (file_read);
                
                logText = [[NSString alloc] initWithCString:(const char*)char_array encoding:NSUTF8StringEncoding];
            }
            
            NSString *head = nil;
            head = [NSString stringWithFormat:@"Assertion Hit[%@](%@) %s %s : \n %@", code,
                              [WXUserConfig getUserId], __DATE__, __TIME__, desc];
            
            [assertDesc appendString:head];
            
            if (logText != nil && logText.length > 0)
            {
                [assertDesc appendString:logText];
            }
            
            [assertDesc appendString:@"\n************************** Assertion Hit *************************\n"];
            
            FILE *file_write = fopen([logWritePath UTF8String], "ab");
            if( file_write != NULL )
            {
                bool needClean = false;
                fseek(file_write, 0, SEEK_END);
                filesize = ftell(file_write);
                fseek(file_write, 0, SEEK_SET );
                
                needClean = filesize > 1024*1024*2; // 上限2M
                
                fwrite([assertDesc UTF8String], strlen([assertDesc UTF8String]), 1, file_write);
                fclose(file_write);
                
                if ( needClean )
                {
                    remove([logWritePath UTF8String]);
                }
            }
            
            if( logText != nil ) {  }
        }
        catch (NSException *exception) {
            NSLog(@"WXLog hitAssertionWithDesc Exception:%@", exception);
        }
    });
}

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanCachedLogString) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanCachedLogString) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanCachedLogString) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanCachedLogString) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [self cleanCachedLogString];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)cleanCachedLogString
{
    dispatch_queue_t queue = [WXLogUtils sharedWXLogQueue];//dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_async(queue, ^{
        pthread_mutex_lock(&file_lock);
        
        if ( s_logStringCache.length > 0 && s_path.length > 0 )
        {
            FILE *file = fopen([s_path UTF8String], "ab");
            fwrite([s_logStringCache UTF8String], strlen([s_logStringCache UTF8String]), 1, file);
            fclose(file);
            
            RELEASE_SAFELY(s_logStringCache);
            s_logStringCache = [[NSMutableString alloc] init];
        }
        
        pthread_mutex_unlock(&file_lock);
    });
}

- (void)submitAssetionHitLog
{
    dispatch_queue_t queue = [WXLogUtils sharedWXLogQueue];
    dispatch_async(queue, ^{
        
        Reachability * reachAbility = [Reachability reachabilityForInternetConnection];
        NetworkStatus netStatus = [reachAbility currentReachabilityStatus];
        
        if (netStatus != ReachableViaWiFi)  return; // Wifi网络环境下上传
        
        NSFileManager* sharedFM = [NSFileManager defaultManager];
        if(sharedFM == nil) return;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentpath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        
        NSString *logPath = [documentpath stringByAppendingPathComponent:WXLog_Assertion];
        if (![sharedFM fileExistsAtPath:logPath isDirectory:NULL]) return;
        
        // 压缩文件
        ZipArchive* zip = [[ZipArchive alloc] init];
        
        NSString* zipFileName = [NSString stringWithFormat:@"%@.zip",logPath.lastPathComponent];
        NSString* zipPath = [documentpath stringByAppendingPathComponent:zipFileName];
        BOOL result = [zip CreateZipFile2:zipPath Password:@"A98765432B"];
        if ( !result ) return;
        
        [zip addFileToZip:logPath newname:logPath.lastPathComponent];
        
        [zip CloseZipFile2];
        
        if([sharedFM fileExistsAtPath:zipPath isDirectory:NULL])
        {
            NSDictionary * attributes = [sharedFM attributesOfItemAtPath:zipPath error:nil];
            NSNumber *fileSize = [attributes objectForKey:NSFileSize];
            if( fileSize != nil && [fileSize intValue] > 100*1024 ) // 文件上限50K，超出不上传
            {
                [sharedFM removeItemAtPath:zipPath error:nil];
                return;
            }
            
            NSData* data = [sharedFM contentsAtPath:zipPath];
            if( data == nil || data.length == 0 ) return;
            
            NSURL *urlerror = [NSURL URLWithString:@"http://wangxin.taobao.com/up_pass/wxerrorup.php"];
            ASIFormDataRequest *requestErrorReport = [ASIFormDataRequest requestWithURL:urlerror];
            
            [requestErrorReport setUsername:@"wangwangreport"];
            [requestErrorReport setPassword:@"xG2Fc2HvMVSxs"];
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd_HH_mm_ss.SSSZ"];
            NSString *submitTime = [dateFormatter stringFromDate:[NSDate date]];
            
            NSString *fileFullName = nil;
            fileFullName = [NSString stringWithFormat:@"AssetionHit_%@v%@_@%@", submitTime,
                                      self.appVersion,[WXUserConfig getUserId]];
            
            [requestErrorReport setFile:zipPath withFileName:fileFullName andContentType:@"zip" forKey:@"upfile"];
            [requestErrorReport startSynchronous];
            
            NSString * responseResult = [requestErrorReport responseString];
            WXDEBUG(@"SubmitAssetionHitLog Response Result:%@", responseResult);

            if(requestErrorReport.responseStatusCode == 200)
            {
                [sharedFM removeItemAtPath:logPath error:nil];
            }
            
            [sharedFM removeItemAtPath:zipPath error:nil];
        }
        
    });
}

#pragma mark - print call stack
+ (NSArray *)backtraceWithMaxCount:(int)maxCount
{
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    int startIndex = 0;
    int endIndex = 0;
    if (maxCount + startIndex >= frames) {
        endIndex = frames;
    }
    else{
        endIndex = startIndex + maxCount;
    }
    for (i = startIndex; i < endIndex; i++)
    {
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    return backtrace;
}

+ (void)printCallStack:(int)count
{
    NSArray* ary =[WXLogUtils backtraceWithMaxCount:count];
    WXERROR(@"%@", ary);
}

+ (void)setStdPrintfToFile
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"yyyy-MM-dd_HH_mm_ss"];
//    NSDate *date = [NSDate date];
//    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    NSString *fileName =[NSString stringWithFormat:@"WXStdPrintf.txt"];
    NSString *logFilePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stdout);
}

+ (void)flushStdPrintf
{
    fflush(stdout);
}

/// 开启程序内控制台日志输出功能，开启该功能需要使用iConsoleWindow作为程序主窗口
/// 该功能默认关闭

#define kUDKiConsoleEnable @"kUDKiConsoleEnable"
static NSNumber *iConsoleEnable = nil;
+ (void)enableiConsole:(BOOL)enable
{
    if ( iConsoleEnable == nil ) { iConsoleEnable = @(enable); }
    [USER_DEFAULT setObject:iConsoleEnable forKey:kUDKiConsoleEnable];
}

+ (BOOL)iConsoleEnabled
{
    if ( iConsoleEnable ) return [iConsoleEnable boolValue];
    iConsoleEnable = [USER_DEFAULT objectForKey:kUDKiConsoleEnable];
    if ( iConsoleEnable ) return [iConsoleEnable boolValue];
    
    return NO;
}

@end