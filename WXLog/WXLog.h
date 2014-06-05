//
//  MacroForDebug.h
//  
//
//  Created by 慕桥(黄玉坤) Moniface on 12-3-22.
//  Copyright (c) 2012年 Ali. All rights reserved.
//

/*
 * 说明：
 *      WXLog日志输出，debug下console会输出，debug下默认不输出到文件。release下console不输出，文件会输出，但文件输出的日志级别由WXLog.plist控制
 *      你可以进行的操作有：
 *          1：修改DISABLE_COLOR_LOG或DISABLE_MORE_INFO_LOG为0或1，从而控制是否颜色输出（如果颜色输出，你需要安装相关插件），是否额外输出文件名，行数，函数名等信息
 *          2：设置WXLOGLEVEL_MAX，从而控制输出日志的级别，如果你是Warning，则会输出包括warning，error的输出。这个是宏定义级别的输出，默认设置为debug（即输出所有）
 *          3：修改WXLog.plist文件中的日志输出级别。
 *      现在存在隐藏文件，这个WXLog.plist文件在sdk中，上层程序访问不到，于是release永远输出不到文件。
 */

#ifndef WX_MacroForDebug_h
#define WX_MacroForDebug_h

#import <Foundation/Foundation.h>

#import "WXClientFuncMacro.h"
#define    WXLOGLEVEL_DEBUG            4
#define    WXLOGLEVEL_INFO             3
#define    WXLOGLEVEL_WARNING          2
#define    WXLOGLEVEL_ERROR            1
#define    WXLOGLEVEL_DISABLE          0


//--------------------  WXLog开关  ----------------------
//下面这个用于控制是否写文件，如果是disable，则不写文件，其他的会写文件到document目录下的WXLog.txt。设置不同的level会写不同level信息到文件中。
//由于这个开关如果不是disable时，可能会因为log日志过多过频繁，进行大量的文件打开，关闭和读写操作，影响性能。
#define WXLOGLEVEL_MAX      WXLOGLEVEL_DEBUG

//开启还是关闭颜色输出,因为分级颜色输出时，会导致xcode4 log部分出现一点小问题。设置1为关闭颜色输出，0为开启
#define DISABLE_COLOR_LOG           0

//开启还是关闭file，line，function信息的输出。当设置为1后，不输出文件行号函数名等信息。0则开启输出。
//当DISABLE_COLOR_LOG==1 && DISABLE_MORE_INFO_LOG==1时，此时等效于NSLog功能
#define DISABLE_MORE_INFO_LOG       1

//-------------------------------------------------------

#define kWXLogCommonEnable      @"WXLog_Common_Enable"
#define kWXLogPluginEnable      @"WXLog_Plugin_Enable"

// NSString *logTail = [NSString stringWithFormat:@"locate : %s line:%d", __FUNCTION__, __LINE__];

#define WXLog_Common @"WXLog.txt"
#define WXLog(level, xx, ...) \
{\
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);\
    NSString *logPath = [[dirs objectAtIndex:0] stringByAppendingPathComponent:WXLog_Common];\
    WXPrint(level, logPath, xx, ##__VA_ARGS__);\
}

#define WXLog_Login @"WXLoginLog.txt"
#define WXLoginLog(level, xx, ...)\
{\
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);\
    NSString *logPath = [[dirs objectAtIndex:0] stringByAppendingPathComponent:WXLog_Login];\
    WXPrint(level, logPath, xx, ##__VA_ARGS__);\
}

#define WXLog4TesterFileName @"WXLog4Tester.txt"
#define WXLog4Tester(level, xx, ...)\
{\
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);\
    NSString *logPath = [[dirs objectAtIndex:0] stringByAppendingPathComponent:WXLog4TesterFileName];\
    WXPrint(level, logPath, xx, ##__VA_ARGS__);\
}

#define WXPrint(logLevel, path, xx, ...) \
{\
    NSString *logInfo = [NSString stringWithFormat:xx, ##__VA_ARGS__];\
    NSString *logHead = [NSString stringWithFormat:@"%s line:%d", __FUNCTION__, __LINE__];\
    [WXLogUtils outputLogInfoToFile:path logInfo:logInfo logHead:logHead level:logLevel];\
    [WXLogUtils outputLog2iConsoleWithLogInfo:logInfo level:logLevel];\
}

#define outputByLevel(logLevel, xx, ...) \
{\
    const char *filePath = __FILE__;\
    char *fileName = (char *)malloc(sizeof(char) * strlen(filePath));\
    \
    int l = strlen(filePath);\
    while (l-- >= 0 && filePath[l] != '/') {}\
    strcpy(fileName, filePath + (l >= 0 ? l + 1 : 0));\
    \
    NSString *logHead = [NSString stringWithFormat:@"%s (line:%u) \n %s:", fileName, __LINE__, __FUNCTION__];\
    NSString *logInfo = [NSString stringWithFormat:xx, ##__VA_ARGS__];\
    [WXLogUtils outputLogInfoColorful:logInfo logHead:logHead level:logLevel];\
    \
    if (fileName) { \
        free(fileName);\
        fileName = NULL;\
    }\
}

#define outputWithoutColor(level, xx, ...) \
{\
    NSString* nsFileName = @"";\
    if(0==DISABLE_MORE_INFO_LOG) {\
        const char *filePath = __FILE__;\
        char *fileName = (char *)malloc(sizeof(char) * strlen(filePath));\
        \
        int l = strlen(filePath);\
        while (l-- >= 0 && filePath[l] != '/') {}\
        strcpy(fileName, filePath + (l >= 0 ? l + 1 : 0));\
        nsFileName = [NSString stringWithFormat:@"%s (line:%u) \n %s:",fileName, __LINE__, __FUNCTION__];\
        if (fileName) { \
            free(fileName);\
            fileName = NULL;\
        }\
    }\
    NSLog(@"%@[%@] %@", nsFileName ,[WXLogUtils getLogLevelTag:level], [NSString stringWithFormat:xx, ##__VA_ARGS__]);\
}

#ifdef DEBUG
    #if 0 != DISABLE_COLOR_LOG
        #define output(level, xx, ...) outputWithoutColor(level, xx, ##__VA_ARGS__)
    #else
        #define output(level, xx, ...) outputByLevel(level, xx, ##__VA_ARGS__)
    #endif
#else
    #define output(level, xx, ...) ((void)0)
#endif

#define WXLogEx(level, xx, ...) \
{\
    output(level, xx, ##__VA_ARGS__);\
    \
    if([WXLogUtils isLogOutFileEnable:kWXLogCommonEnable ofLevel:level])\
    {\
        WXLog(level, xx, ##__VA_ARGS__)\
    }\
}

#if WXLOGLEVEL_ERROR <= WXLOGLEVEL_MAX
#define WXERROR(xx, ...) WXLogEx(WXLOGLEVEL_ERROR, xx, ##__VA_ARGS__)
#else
#define WXERROR(xx, ...) ((void)0)
#endif

#if WXLOGLEVEL_WARNING <= WXLOGLEVEL_MAX
#define WXWARNING(xx, ...) WXLogEx(WXLOGLEVEL_WARNING, xx, ##__VA_ARGS__)
#else
#define WXWARNING(xx, ...) ((void)0)
#endif

#if WXLOGLEVEL_INFO <= WXLOGLEVEL_MAX
#define WXINFO(xx, ...) WXLogEx(WXLOGLEVEL_INFO, xx, ##__VA_ARGS__)
#else
#define WXINFO(xx, ...) ((void)0)
#endif

#if WXLOGLEVEL_DEBUG <= WXLOGLEVEL_MAX
#define WXDEBUG(xx, ...) WXLogEx(WXLOGLEVEL_DEBUG, xx, ##__VA_ARGS__)
#else
#define WXDEBUG(xx, ...) ((void)0)
#endif

// 该宏会触发日志上传，请谨慎使用。如有使用请联系慕桥Review
#define WXLog_Assertion @"WXAssertionLog.txt"
#define WXAssert(condition, aCode, xx, ...) \
{\
    if ( !condition )\
    { \
        NSString *desc = [NSString stringWithFormat:xx, ##__VA_ARGS__];\
        NSAssert(condition, desc);\
        WXERROR(desc, nil);\
        [WXLogUtils hitAssertionWithDesc:desc code:aCode];\
    }\
}

@interface WXLogUtils : NSObject
DECLARE_SINGLETON_FOR_CLASS(WXLogUtils)

@property (nonatomic, strong) NSString *appVersion;

+ (void)outputLogInfoColorful:(NSString *)logInfo logHead:(NSString *)logHead level:(NSInteger)level;   // 将日志输出到控制台
+ (void)outputLogInfoToFile:(NSString *)path logInfo:(NSString *)logInfo logHead:(NSString *)logHead level:(NSInteger)level;        // 将日志写文件
+ (void)outputLog2iConsoleWithLogInfo:(NSString *)logInfo level:(NSInteger)level;

+ (NSString *)getLogLevelTag:(NSInteger)level;
+ (NSString *)getLogLevelColor:(NSInteger)level;

+ (BOOL)isLogOutFileEnable:(NSString *)logName ofLevel:(int)level;
+ (BOOL)setLogOutFileLevel:(int)level;

// 提交WXLog.txt。该函数只在手动上传日志时调用。
// 没有网络和文件大小限制。
- (void)submitWXLog;
+ (void)clearLogFileIfNeed;

- (void)submitAssetionHitLog;   // 提交断言日志
+ (void)hitAssertionWithDesc:(NSString *)desc code:(NSString *)code;  // 命中断言

- (void)cleanCachedLogString;   // 将内存中日志内容写文件并清空

// 打印当前线程堆栈
// @param count : max stack frame count
+ (void)printCallStack:(int)count;

///将stdout和stderr输出到文件，由于平台关联占不可恢复。
+ (void)setStdPrintfToFile;
///将stdout缓存同步刷新到文件,一般可在applicationDidEnterBackground时调用
+ (void)flushStdPrintf;

/// 开启程序内控制台日志输出功能，开启该功能需要使用iConsoleWindow作为程序主窗口
/// 该功能默认关闭
+ (void)enableiConsole:(BOOL)enable;
@end

#endif // WX_MacroForDebug_h
