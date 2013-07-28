//
//  ehm.h
//  VideoIphone
//
//  Created by wangwei34 on 13-5-16.
//  Copyright (c) 2013年 com.baidu. All rights reserved.
//

#ifndef VideoIphone_ehm_h
#define VideoIphone_ehm_h

/*
 *  verify macros
 */
#define VBR(x)      NSAssert((x), @"ERROR")
#define VPR(p)      NSAssert(nil != (p), @"BAD POINTER")
// verify it's in mainthread
#define VMAINTHREAD()   NSAssert(YES == [NSThread isMainThread], @"ERROR")
// TODO flag
#define VTODO()         NSAssert(0, @"TODO")

/*
 *  check macros
 */
#define CBR(x)                                                  \
    do {                                                        \
        if (NO == (x))                                          \
        {                                                       \
            ret = NO;                                           \
            goto ERROR;                                         \
        }                                                       \
    } while(0)

#define CBRA(x)                                                 \
    do {                                                        \
        if (NO == (x))                                          \
        {                                                       \
            ret = NO;                                           \
            NSAssert(0, @"ERROR");                              \
            goto ERROR;                                         \
        }                                                       \
    } while(0)

#define CPR(p)                                                  \
    do {                                                        \
        if (nil == (p))                                         \
        {                                                       \
            ret = NO;                                           \
            goto ERROR;                                         \
        }                                                       \
    } while(0)

#define CPRA(p)                                                 \
    do {                                                        \
        if (nil == (p))                                         \
        {                                                       \
            ret = NO;                                           \
            NSAssert(0, @"BAD POINTER");                        \
            goto ERROR;                                         \
        }                                                       \
    } while(0)

// check the string from network
#define CSTRA(d)                                                        \
    do {                                                                \
        NSString *s = (NSString *)(d);                                  \
        CBRA(s && [s isKindOfClass:[NSString class]] && [s length] > 0);\
    } while(0)

/*
 *  const definition
 */
// error domain for NSError
extern NSString * const ERR_DOMAIN;

#endif
