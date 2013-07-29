//
//  HTTPP2PResponse.m
//  VideoIphone
//
//  Created by Wayne W on 13-7-20.
//  Copyright (c) 2013年 com.baidu. All rights reserved.
//

#import "HTTPP2PResponse.h"
#import "ehm.h"

@implementation HTTPP2PResponse
{
    HTTPP2PTask *_task;
    UInt64 _offset;
}

- (id)initWithP2PTask:(HTTPP2PTask*)task
{
    self = [super init];
    if (self)
    {
        VPR(task);
        _task = task;
    }
    
    return self;
}

- (void)dealloc
{
}

#pragma mark HTTPResponse
- (UInt64)contentLength
{
    return [_task contentLength];
}

- (UInt64)offset
{
    return _offset;
}

- (void)setOffset:(UInt64)offset
{
    _offset = offset;
}

- (NSData *)readDataOfLength:(unsigned int)length
{
    [_task seekTo:_offset];
    
    NSData *data = [_task readDataOfLength:length];
    _offset += data.length;
    
    return data;
}

- (BOOL)isDone
{
    return _offset >= [self contentLength];
}

- (NSDictionary *)httpHeaders
{
    if (![_task contentType])
    {
        return nil;
    }
    
    return [NSDictionary dictionaryWithObject:[_task contentType] forKey:@"Content-Type"];
}

@end
