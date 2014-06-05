//
//  NSString+Url.m
//  WQClient
//
//  Created by 慕桥(黄玉坤) on 14-2-26.
//  Copyright (c) 2014年 Alibaba. All rights reserved.
//

#import "NSString+Url.h"

@implementation NSString (Url)


#pragma mark - Url Encode

- (NSString *) stringUrlEncode
{
    //kCFStringEncodingUTF8
    return [self stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *) stringUrlDecode
{
    //kCFStringEncodingUTF8
    return [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *) encodeUrlWithStringEncoding:(NSStringEncoding)stringEncoding;
{
    if( [self length] == 0 ) return nil;
    
	NSArray *escapeChars = [NSArray arrayWithObjects:@";" , @"/" , @"?" , @":" ,
                            @"@" , @"&" , @"=" , @"+" ,	@"$" , @"," ,
                            @"!", @"'", @"(", @")", @"*", nil];
	
	NSArray *replaceChars = [NSArray arrayWithObjects:@"%3B" , @"%2F" , @"%3F" , @"%3A" ,
                             @"%40" , @"%26" , @"%3D" , @"%2B" , @"%24" , @"%2C" ,
                             @"%21", @"%27", @"%28", @"%29", @"%2A", nil];
	
	int len = [escapeChars count];
	
	NSString *temp = [self stringByAddingPercentEscapesUsingEncoding:stringEncoding];
	
	for(int i = 0; i < len; i++)
	{
		temp = [temp stringByReplacingOccurrencesOfString:[escapeChars objectAtIndex:i]
                                               withString:[replaceChars objectAtIndex:i]
                                                  options:NSLiteralSearch
                                                    range:NSMakeRange(0, [temp length])];
	}
	
	NSString *outString = [NSString stringWithString:temp];
	
	return outString;
}

#pragma mark - Url

- (NSMutableString *)stringByAppendParams:(NSDictionary *)params
{
    if ( self.length == 0 ) return nil;
    if ( params.count == 0 ) return self;
    
    NSString *anchors = nil;
    NSMutableString *suffix = [NSMutableString stringWithString:self];
    
    NSRange anchorsRang = [self rangeOfString:@"#" options:NSBackwardsSearch];
    if ( anchorsRang.location != NSNotFound )
    {
        NSString *subStr = [self substringToIndex:anchorsRang.location];
        suffix = [NSMutableString stringWithString:subStr?subStr:@""];
        anchors = [self substringFromIndex:anchorsRang.location];
    }
    
    NSRange rang = [suffix rangeOfString:@"?"];
    if ( rang.location == NSNotFound )
    {
        [suffix appendString:@"?"];
    }
    else if ( rang.location + rang.length < suffix.length )
    {
        [suffix appendString:@"&"];
    }
    
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSRange keyRng = [suffix rangeOfString:[NSString stringWithFormat:@"%@=", key]];
        if ( keyRng.location == NSNotFound )
        {
            [suffix appendFormat:@"%@=%@", key, obj];
            [suffix appendString:@"&"];
        }
    }];
    
    if ( [suffix hasSuffix:@"&"] )
    {
        [suffix deleteCharactersInRange:NSMakeRange(suffix.length - 1, 1)];
    }
    
    if ( anchors.length > 0 )
    {
        [suffix appendString:anchors];
    }
    
    return suffix;
}

//强制remove传入参数里的key的参数
- (NSString *)removeParams:(NSArray *)paramKeysAry
{
    if ( self.length == 0 ) return nil;
    if ( paramKeysAry.count == 0 ) return self;
    
    NSRange range = [self rangeOfString:@"?"];
    if ( range.location == NSNotFound )
    {
        return self;
    }
    
    NSMutableString* retUrlString = [NSMutableString string];
    [retUrlString appendFormat:@"%@",[self substringToIndex:range.location+1]];
    
    
    NSRange anchorRange = [self rangeOfString:@"#" options:NSBackwardsSearch];
    NSString *anchor = nil;
    NSString *query = nil;
    if (anchorRange.location != NSNotFound) {
        anchor = [self substringFromIndex:anchorRange.location];
        query = [self substringWithRange:NSMakeRange(range.location+1, anchorRange.location - range.location - 1)];
    }
    else{
        query = [self substringFromIndex:range.location+1];
    }
    
    
    if( [query length] > 0 )
    {
        NSArray* aryParam = [query componentsSeparatedByString:@"&"];
        for( NSString* str in aryParam )
        {
            NSArray* aryKenAndValue = [str componentsSeparatedByString:@"="];
            if( [aryKenAndValue count] >=  2 )
            {
                NSString* key = [aryKenAndValue objectAtIndex:0];
                NSString* value = [aryKenAndValue objectAtIndex:1];
                if ([paramKeysAry containsObject:key]) {
                    continue;
                }
                [retUrlString appendFormat:@"%@=%@&",key, value];
            }
            
        }
        [retUrlString hasSuffix:@"&"];
        [retUrlString deleteCharactersInRange:NSMakeRange(retUrlString.length-1, 1)];
    }
    if (anchor) {
        [retUrlString appendFormat:@"%@",anchor];
    }
    return retUrlString;
}

- (NSString*)getHostForUrlString
{
    NSURL* url = [NSURL URLWithString:self];
    NSString* strHost = [url host];
    
    return strHost;
}

- (NSDictionary*)getParamsInUrlString
{
    NSMutableDictionary* dicParam = [NSMutableDictionary dictionary];
    NSURL* previewUrl = [NSURL URLWithString:self];
    BOOL bEncodeUrl = NO;
    if (previewUrl == nil)
    {
        NSString* encodeUrl = [self stringUrlEncode];
        previewUrl = [NSURL URLWithString:encodeUrl];
        if (previewUrl != nil) bEncodeUrl = YES;
    }
    
    NSString* query = [previewUrl query];
    if (query != nil && bEncodeUrl)
    {
        query = [self stringUrlDecode];
    }
    else if ([query length] == 0)
    {
        NSRange range = [self rangeOfString:@"?"];
        if (range.length > 0) query = [self substringFromIndex:range.location+range.length];
    }
    
    if( [query length] > 0 )
    {
        NSArray* aryParam = [query componentsSeparatedByString:@"&"];
        for( NSString* str in aryParam )
        {
            NSArray* aryKenAndValue = [str componentsSeparatedByString:@"="];
            if( [aryKenAndValue count] >=  2 )
            {
                NSString* key = [aryKenAndValue objectAtIndex:0];
                NSString* value = [aryKenAndValue objectAtIndex:1];
                if ([value rangeOfString:@"%"].length > 0)
                {
                    value = [self stringUrlDecode];
                }
                if ( value && key )
                {
                    [dicParam setObject:value forKey:key];
                }
            }
        }
    }
    
    return dicParam;
}

@end
