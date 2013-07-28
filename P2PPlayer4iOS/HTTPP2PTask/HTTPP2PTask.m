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

// TaskParam
@interface TaskParam : NSObject
@property (nonatomic, assign) task_handle_t p2pHandle;
@end

@implementation TaskParam

@end

// HTTPP2PTask
@implementation HTTPP2PTask
{
    NSThread *_thread;
    UInt64 _offset;
    
    NSRange _rangeData;
    NSMutableData *_cachedData;
}

@synthesize task = _p2pTask;
@synthesize url = _p2pUrl;
@synthesize key = _md5Url;

- (id)initWithTask:(task_handle_t)handle p2pUrl:(NSString*)url
{
    self = [super init];
    if (self)
    {
        VBR(handle);
        VBR(url && [url length] > 0);
        
        _p2pTask = handle;
        _p2pUrl = url;
        
        _md5Url = [[self class] key4url:_p2pUrl];
        VPR(_md5Url);
        
        TaskParam *param = [[TaskParam alloc] init];
        param.p2pHandle = _p2pTask;
        _thread = [[NSThread alloc] initWithTarget:self
                                          selector:@selector(_workerThread:)
                                            object:param];
        VPR(_thread);
        _thread.threadPriority = 0.5;
        
        _cachedData = [NSMutableData dataWithCapacity:CHUNK_SIZE];
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
    return [[url dataUsingEncoding:NSUTF8StringEncoding] MD5HexDigest];
}

- (void)start
{
    VMAINTHREAD();
    
    _rangeData = NSMakeRange(0, 0);
    
    VPR(_p2pTask);
    p2pservice_task_start(_p2pTask);
    
    [self _waitUntilReady];
    
    VBR(![_thread isExecuting]);
    [_thread start];
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
    VMAINTHREAD();
    
    _offset = offset;
    
    return YES;
}

- (NSData *)readDataOfLength:(unsigned int)length
{
    VMAINTHREAD();
    
    NSData *data = nil;
    BOOL ret = YES;
    
    if (![self _waitUntilDataAvailableAtOffset:_offset])
    {
        return nil;
    }
    
    UInt64 remain = _rangeData.length + _rangeData.location - _offset;
    if (length > remain)
    {
        length = remain;
    }
    
    if (length == 0)
    {
        VBR(0);
        data = [NSMutableData dataWithLength:0];
        goto ERROR;
    }
    
    {
        void *pos = (char*)[_cachedData mutableBytes] + _offset;
        data = [NSData dataWithBytesNoCopy:pos length:length freeWhenDone:NO];
    }
    
ERROR:
    if (!ret)
    {
        data = nil;
    }
    
    return data;
}

#pragma mark private
- (void)_workerThread:(TaskParam*)param
{
    @autoreleasepool
    {
        NSFileHandle *tmpFile = [self _tmpFile:YES];
        UInt64 maxOffst = [self _fileSize];        
        BOOL keepReading = YES;
        static char buf[CHUNK_SIZE] = {0};
        memset(buf, 0, sizeof(buf));
        UInt64 offst = 0;
        
        while (maxOffst == 0)
        {
            sleep(1);
            maxOffst = [self _fileSize];
        }
        
        while (keepReading)
        {
            VBR(maxOffst > 0);
            VBR(maxOffst >= offst);
            
            UInt64 remain = maxOffst - offst;
            if (remain == 0)
            {
                break;
            }
            
            task_info_t info = {0};
            p2pservice_task_info(param.p2pHandle, &info);
            NSLog(@"speed=%d, downloaded=%llu", info.downspeed, info.downloaded);
            
            UInt64 len = MIN(remain, sizeof(buf));
            int read = p2pservice_read(param.p2pHandle, offst, buf, len, false);
            if (read > 0)
            {
                NSData *data = [NSData dataWithBytesNoCopy:buf length:read freeWhenDone:NO];
                offst += read;
                
                [tmpFile writeData:data];
                [tmpFile synchronizeFile];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self->_rangeData = NSMakeRange(0, offst);
                    [self->_cachedData appendData:data];
                });
            }
            else
            {
                sleep(1);
            }
        }
        
        [tmpFile closeFile];
    }
}

- (NSFileHandle*)_tmpFile:(BOOL)forWrite
{
    BOOL ret = YES;
    NSFileHandle *file = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *path = [self _path2tmpFile];
    CPR(path);

    if (forWrite)
    {
        if (![fileManager fileExistsAtPath:path])
        {
            ret = [fileManager createFileAtPath:path contents:nil attributes:nil];
            CBR(ret);
        }
        
        file = [NSFileHandle fileHandleForWritingAtPath:path];
    }
    else
    {
        file = [NSFileHandle fileHandleForReadingAtPath:path];
    }
    CPR(file);
    
ERROR:
    return file;
}

- (void)_cleanUp
{
    p2pservice_task_stop(_p2pTask);
    
    [_thread cancel];
    _thread = nil;
    
    NSString *path = [self _path2tmpFile];
    if (path)
    {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
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

- (BOOL)_waitUntilDataAvailableAtOffset:(UInt64)offst
{
    VMAINTHREAD();
    
    VBR([self _fileSize] > 0);
    
    if (offst >= [self _fileSize])
    {
        return NO;
    }
    
    while (offst >= _rangeData.location + _rangeData.length)
    {
        [self _wait];
    }
    
    return YES;
}

#pragma mark helper
- (NSString*)_path2tmpFile
{
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    VPR(cachesPath);
    
    return [NSString stringWithFormat:@"%@/%@_%@", cachesPath, NSStringFromClass([self class]), _md5Url];
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

@end
