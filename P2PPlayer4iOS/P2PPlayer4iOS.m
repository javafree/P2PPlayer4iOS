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
    HTTPP2PTask *tast = [HTTPP2PTask createTask4P2PUrl:p2pURL delegate:nil];
    NSString *strURL = [HTTPP2PTask httpURL4task:tast];
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:strURL]];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
    
    [self setPlayer:player];
    [player play];
    
    return YES;
}

@end
