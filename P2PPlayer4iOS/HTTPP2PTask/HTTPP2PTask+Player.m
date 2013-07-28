//
//  HTTPP2PTask+Player.m
//  VideoIphone
//
//  Created by Wayne W on 13-7-28.
//  Copyright (c) 2013年 com.baidu. All rights reserved.
//

#import "HTTPP2PTask+Player.h"
#import "ehm.h"
#import <CocoaHTTPServer/HTTPServer.h>

NSString * const URLFormat  = @"http://127.0.0.1:%d/p2p/res/%@";
#define HTTP_PORT_BASE      1014

static NSMutableDictionary *g_dictP2PTasks = nil;
static UInt16 g_port = HTTP_PORT_BASE;

// TaskItem
@interface TaskItem : NSObject
@property (nonatomic, retain) HTTPP2PTask *task;
@property (nonatomic, retain) HTTPServer *httpServer;
@end

@implementation TaskItem

@end

// HTTPP2PTask
@implementation HTTPP2PTask (Player)
+ (HTTPP2PTask*)createTask4P2PUrl:(NSString *)p2pURL delegate:(id<HTTPP2PTaskDelegate>)delegate
{
    if (!g_dictP2PTasks)
    {
        g_dictP2PTasks = [[NSMutableDictionary alloc] initWithCapacity:64];
    }
    VPR(g_dictP2PTasks);
    
    BOOL ret = YES;
    HTTPP2PTask *task = nil;
    HTTPServer *httpServer = nil;
    TaskItem *item = nil;
    
    NSString *key = [self key4url:p2pURL];
    CPR(key);
    
    // create the task
    task = [[HTTPP2PTask alloc] initWithTaskWithP2PUrl:p2pURL];
    CPR(task);
    
    item = [g_dictP2PTasks objectForKey:key];
    if (item)
    {
        task = item.task;
        goto ERROR;
    }
    
    // start http server
    {
        httpServer = [[HTTPServer alloc] init];
        CPR(httpServer);
        
        [httpServer setType:@"_http._tcp."];
        [httpServer setPort:g_port++];
    }
    
    // build the HTTPP2PTask
    item = [[TaskItem alloc] init];
    item.task = task;
    item.httpServer = httpServer;
    [g_dictP2PTasks setObject:item forKey:key];
    
    task.delegate = delegate;
    [task start];
    
    {
    NSError * error = nil;
    [httpServer start:&error];
    CBR(!error);
    }
ERROR:
    if (!ret)
    {
        [httpServer stop];
        
        if (task)
        {
            task.delegate = nil;
            [task stop];
        }
    }
    
    return task;
}

+ (NSString*)httpURL4task:(HTTPP2PTask*)task
{
    if (task.key)
    {
        TaskItem *item = [g_dictP2PTasks objectForKey:task.key];
        return [NSString stringWithFormat:URLFormat, item.httpServer.port, task.key];
    }
    
    VBR(0);
    return nil;
}

+ (BOOL)stopP2PTask:(HTTPP2PTask*)task
{
    BOOL ret = YES;
    TaskItem *item = nil;
    
    CPR(task.key);
    
    item = [g_dictP2PTasks objectForKey:task.key];
    if (task == item.task)
    {
        [g_dictP2PTasks removeObjectForKey:task.key];
        [item.httpServer stop];
    }
    else
    {
        VBR(0);
    }
    
    task.delegate = nil;
    [task stop];
    
ERROR:
    return ret;
}

+ (HTTPP2PTask*)task4HTTPUrl:(NSString*)httpUrl
{
    NSString *key = [httpUrl lastPathComponent];
    if (key && [key length])
    {
        TaskItem *item = [g_dictP2PTasks objectForKey:key];
        return item.task;
    }
    
    return nil;
}

@end
