//
//  HTTPP2PTask.h
//  VideoIphone
//
//  Created by Wayne W on 13-7-28.
//  Copyright (c) 2013年 com.baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "p2pservice.h"

typedef enum
{
    HTTPP2PTask_STATUS_UNKNOWN = 0,
    
    HTTPP2PTask_STATUS_READY,
    
    HTTPP2PTask_STATUS_MAX,
}HTTPP2PTask_STATUS;

@class HTTPP2PTask;
@protocol HTTPP2PTaskDelegate <NSObject>
@end

@interface HTTPP2PTask : NSObject

@property (nonatomic, assign, readonly) task_handle_t task;
@property (nonatomic, retain, readonly) NSString *url;
@property (nonatomic, retain, readonly) NSString *key;

@property (nonatomic, assign) HTTPP2PTask_STATUS status;
@property (nonatomic, assign) id<HTTPP2PTaskDelegate> delegate;

+ (NSString*)key4url:(NSString*)url;

- (id)initWithTask:(task_handle_t)handle p2pUrl:(NSString*)url;

- (void)start;
- (void)stop;

- (BOOL)seekTo:(UInt64)offset;
- (UInt64)offset;

- (UInt64)contentLength;
- (NSData*)readDataOfLength:(unsigned int)length;

- (NSString*)contentType;

@end
