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

+ (void)initialize
{
    [super initialize];
    
    g_dictP2PTasks = [[NSMutableDictionary alloc] initWithCapacity:64];
}

+ (HTTPP2PTask*)createTask4P2PUrl:(NSString *)p2pURL delegate:(id<HTTPP2PTaskDelegate>)delegate
{
    BOOL ret = YES;
    HTTPP2PTask *task = nil;
    HTTPServer *httpServer = nil;
    task_handle_t handle = nil;
    
    // start p2p
    {
        task_param_t  taskParam = {0};
        taskParam.url = (char *)[p2pURL UTF8String];
        taskParam.flag = eTaskParamCacheMemory;
        
        int done = p2pservice_task_create(&taskParam, &handle);
        CBR(done >= 0 && handle);
        
        p2pservice_set_playing(handle, true);
    }
    
    // start http server
    {
        httpServer = [[HTTPServer alloc] init];
        CPR(httpServer);
        
        [httpServer setType:@"_http._tcp."];
        [httpServer setPort:g_port++];
    }
    
    // build the HTTPP2PTask for handle
    CBR(handle && p2pURL && [p2pURL length] > 0);
    
    {
        NSString *key = [self key4url:p2pURL];
        CPR(key);
        
        task = [g_dictP2PTasks objectForKey:key];
        if (!task)
        {
            task = [[HTTPP2PTask alloc] initWithTask:handle p2pUrl:p2pURL];
            CPR(task);
            
            TaskItem *item = [[TaskItem alloc] init];
            item.task = task;
            item.httpServer = httpServer;
            [g_dictP2PTasks setObject:item forKey:key];
            
            task.delegate = delegate;
            [task start];
            
            NSError * error = nil;
            [httpServer start:&error];
            CBR(!error);
        }
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
        else
        {
            p2pservice_task_destroy(handle);
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
