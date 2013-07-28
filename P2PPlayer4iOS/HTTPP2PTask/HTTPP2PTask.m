//
//  HTTPP2PTask.m
//  VideoIphone
//
//  Created by Wayne W on 13-7-28.
//  Copyright (c) 2013年 com.baidu. All rights reserved.
//

#import "HTTPP2PTask.h"
#import "ehm.h"
#import "NSData+MD5Digest.h"

#define CHUNK_SIZE      (1024 * 512)

// HTTPP2PTask
@implementation HTTPP2PTask
{
    UInt64 _offset;
}

@synthesize task = _p2pTask;
@synthesize url = _p2pUrl;
@synthesize key = _md5Url;

+ (void)initialize
{
    [super initialize];
    
    p2pservice_init(6, true);
    p2pservice_set_cache_size(1024 * 1024 * 4);
}

- (id)initWithTaskWithP2PUrl:(NSString*)url
{
    self = [super init];
    if (self)
    {
        VBR(url && [url length] > 0);
        
        _p2pUrl = url;
        
        _md5Url = [[self class] key4url:_p2pUrl];
        VPR(_md5Url);
        
        _p2pTask = [self _handle4P2PUrl];
        if (!_p2pTask)
        {
            VBR(0);
            self = nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    p2pservice_task_destroy(_p2pTask);
    _p2pTask = nil;
    
    [self _cleanUp];
}

#pragma mark public
+ (NSString*)key4url:(NSString*)url
{
    if (url && [url length] > 0)
    {
        return [[url dataUsingEncoding:NSUTF8StringEncoding] MD5HexDigest];
    }
    
    return nil;
}

- (void)start
{
    VMAINTHREAD();
    
    VPR(_p2pTask);
    p2pservice_task_start(_p2pTask);
    
    [self _waitUntilReady];
}

- (void)stop
{
    VMAINTHREAD();
    
    [self _cleanUp];
}

- (NSString*)contentType
{
    return @"video/mp4";
}

- (UInt64)contentLength
{
    return [self _fileSize];
}

- (UInt64)offset
{
    return _offset;
}

- (BOOL)seekTo:(UInt64)offset
{
    _offset = offset;
    NSLog(@"[seekTo] %llu", _offset);
    
    return YES;
}

- (NSData *)readDataOfLength:(unsigned int)length
{
    NSMutableData *data = nil;
    BOOL ret = YES;
    UInt64 offst = 0;
    
    if (_offset >= [self _fileSize])
    {
        _offset = [self _fileSize];
        CBR(0);
    }
    
    length = MIN([self _fileSize] - _offset, length);
    
    data = [NSMutableData dataWithLength:length];
    CPR(data);

    offst = _offset;
    NSLog(@"[readDataOfLength] offset=%llu, length=%u", offst, length);
    while (1)
    {
        char *buf = [data mutableBytes];
        int read = p2pservice_read(_p2pTask, offst, buf, length, false);
        if (read > 0)
        {
            [data setLength:read];
            _offset = read + offst;
            
            break;
        }
        else
        {
            sleep(1);
        }
        
        task_stat_t stat = {0};
        p2pservice_task_stat(_p2pTask, &stat);
        
        task_info_t info = {0};
        p2pservice_task_info(_p2pTask, &info);
        NSLog(@"speed=%d, downloaded=%llu, readpos=%llu, unfinish=%llu, short=%llu, long=%llu, winpos=%llu", info.downspeed, info.downloaded, stat.read_pos, stat.unfinish_pos, stat.short_win, stat.long_win, stat.win_pos);
    }
    
ERROR:
    if (!ret)
    {
        data = nil;
    }
    
    return data;
}

#pragma mark private
- (void)_cleanUp
{
    p2pservice_task_stop(_p2pTask);
}

- (BOOL)_waitUntilReady
{
    VMAINTHREAD();
    
    while ([self _fileSize] == 0)
    {
        [self _wait];
    }
    
    return YES;
}

#pragma mark helper
- (NSString*)_path2cache
{
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    VPR(cachesPath);
    
    return [NSString stringWithFormat:@"%@/%@/%@/", cachesPath, NSStringFromClass([self class]), _md5Url];
}

- (UInt64)_fileSize
{
    p2p_task_info_t inf = {0};
    p2pservice_task_info(_p2pTask, &inf);
    
    return inf.filesize;
}

- (void)_wait
{
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
}

- (task_handle_t)_handle4P2PUrl
{
    BOOL ret = YES;
    task_handle_t handle = nil;
    task_param_t  taskParam = {0};
    
    NSString *cachesPath = [self _path2cache];
    CPRA(cachesPath);
    
    taskParam.url = (char *)[_p2pUrl UTF8String];
    taskParam.flag = eTaskParamCacheToFile;
    taskParam.path = (char*)[cachesPath UTF8String];
    taskParam.filename = (char*)[_md5Url UTF8String];
    
    {
        int done = p2pservice_task_create(&taskParam, &handle);
        CBR(done >= 0 && handle);
    }
    
    p2pservice_set_playing(handle, true);
    
ERROR:
    if (!ret && handle)
    {
        p2pservice_task_destroy(handle);
        handle = nil;
    }
    
    return handle;
}

@end
