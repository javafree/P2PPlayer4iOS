//
//  HTTPP2PTask+Response.h
//  VideoIphone
//
//  Created by Wayne W on 13-7-28.
//  Copyright (c) 2013年 com.baidu. All rights reserved.
//

#import "HTTPP2PTask.h"
#import "HTTPP2PResponse.h"

#define SEL_CONTENT_TYPE        @selector(contentType)

@interface HTTPP2PTask (Response)

+ (HTTPP2PResponse*)response4Url:(NSString*)url;

@end
