//
//  HTTPConnection+Ext.m
//  P2PPlayer4iOS
//
//  Created by Wayne W on 13-7-28.
//
//

#import "HTTPConnection+Ext.h"
#import <CocoaHTTPServer/HTTPResponse.h>
#import "HTTPP2PTask+Response.h"

@implementation HTTPConnection (Ext)

- (id<HTTPResponse>)httpResponseExtForMethod:(NSString*)method URI:(NSString*)uri
{
    return [HTTPP2PTask response4Url:uri];
}

@end
