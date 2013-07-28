//
//  HTTPP2PTask+Player.h
//  VideoIphone
//
//  Created by Wayne W on 13-7-28.
//  Copyright (c) 2013年 com.baidu. All rights reserved.
//

#import "HTTPP2PTask.h"

@interface HTTPP2PTask (Player)

+ (HTTPP2PTask*)createTask4P2PUrl:(NSString*)p2pURL delegate:(id<HTTPP2PTaskDelegate>)delegate;
+ (NSString*)httpURL4task:(HTTPP2PTask*)task;
+ (BOOL)stopP2PTask:(HTTPP2PTask*)task;

+ (HTTPP2PTask*)task4HTTPUrl:(NSString*)httpUrl;

+ (BOOL)supportURL:(NSString*)url;

@end
