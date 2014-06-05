//
//  NSString+Url.h
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 14-2-26.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Url)

- (NSString *) stringUrlEncode;
- (NSString *) stringUrlDecode;

- (NSString *) encodeUrlWithStringEncoding:(NSStringEncoding)stringEncoding;

- (NSString *) getHostForUrlString;
- (NSDictionary *) getParamsInUrlString;

- (void) removeParams:(NSArray *)paramKeysAry;
- (NSMutableString *) stringByAppendParams:(NSDictionary *)params;

@end
