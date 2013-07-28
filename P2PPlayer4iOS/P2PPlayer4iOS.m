//
//  P2PPlayer4iOS.m
//  P2PPlayer4iOS
//
//  Created by Wayne W on 13-7-28.
//
//

#import "P2PPlayer4iOS.h"
#import <AVFoundation/AVFoundation.h>
#import "HTTPP2PTask+Player.h"

@implementation P2PPlayer4iOS
{
    AVPlayerItem *_item;
}

+ (BOOL)supportURL:(NSString*)url
{
    return [HTTPP2PTask supportURL:url];
}

+ (Class)layerClass
{
	return [AVPlayerLayer class];
}

- (AVPlayer*)player
{
	return [(AVPlayerLayer*)[self layer] player];
}

- (void)setPlayer:(AVPlayer*)player
{
	[(AVPlayerLayer*)[self layer] setPlayer:player];
}

- (BOOL)playP2PUrl:(NSString*)p2pURL
{
    HTTPP2PTask *task = [HTTPP2PTask createTask4P2PUrl:p2pURL delegate:nil];
    NSString *strURL = [HTTPP2PTask httpURL4task:task];
    
    _item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:strURL]];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:_item];
    
    [self setPlayer:player];
    [player play];
    
    return YES;
}

- (void)pause
{
    if ([self player].rate > 0)
    {
        [[self player] pause];
    }
    else
    {
        [[self player] play];
    }
}

- (void)_hookPlayItem:(AVPlayerItem*)item
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
