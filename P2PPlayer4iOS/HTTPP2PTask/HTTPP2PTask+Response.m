//
//  HTTPP2PTask+Response.m
//  VideoIphone
//
//  Created by Wayne W on 13-7-28.
//  Copyright (c) 2013年 com.baidu. All rights reserved.
//

#import "HTTPP2PTask+Response.h"
#import "ehm.h"
#import "HTTPP2PTask+Player.h"

@implementation HTTPP2PTask (Response)

+ (HTTPP2PResponse*)response4Url:(NSString*)url
{
    HTTPP2PTask *task = [self task4HTTPUrl:url];
    if (!task)
    {
        return nil;
    }
    
    return [[HTTPP2PResponse alloc] initWithP2PTask:task];
}

@end
