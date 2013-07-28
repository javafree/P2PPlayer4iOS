//
//  HTTPP2PResponse.h
//  VideoIphone
//
//  Created by Wayne W on 13-7-20.
//  Copyright (c) 2013年 com.baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaHTTPServer/HTTPResponse.h>
#import "HTTPP2PTask.h"

@interface HTTPP2PResponse : NSObject <HTTPResponse>

- (id)initWithP2PTask:(HTTPP2PTask*)task;
- (NSString*)contentType;

@end
