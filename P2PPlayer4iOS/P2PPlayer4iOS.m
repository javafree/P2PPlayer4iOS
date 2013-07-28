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

#define KEY_PATH_STATUS     @"status"
#define KEY_PATH_BUF_EMPTY  @"playbackBufferEmpty"
#define KEY_PATH_KEEPUP     @"playbackLikelyToKeepUp"

@implementation P2PPlayer4iOS
{
    AVPlayerItem *_item;
}

@synthesize delegate;

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
    [self _cleanUp];
    
    HTTPP2PTask *task = [HTTPP2PTask createTask4P2PUrl:p2pURL delegate:nil];
    NSString *strURL = [HTTPP2PTask httpURL4task:task];
    
    _item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:strURL]];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:_item];
    
    [self setPlayer:player];
    [player play];
    
    [self _hookPlayback];
    
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

- (Float64)seekTo:(Float64)seconds
{
    CMTime time = CMTimeMakeWithSeconds(seconds, 1);
    [_item seekToTime:time];
    
    return CMTimeGetSeconds([_item currentTime]);
}

- (Float64)duration
{
    return CMTimeGetSeconds([_item duration]);
}

- (Float64)currentTime
{
    return CMTimeGetSeconds([_item currentTime]);
}

- (void)_hookPlayback
{    
    AVPlayer *plyr = [self player];
    [plyr addObserver:(id)self
           forKeyPath:KEY_PATH_STATUS
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
              context:nil];
    
    [plyr addPeriodicTimeObserverForInterval:(CMTimeMakeWithSeconds(1, 1))
                                       queue:(dispatch_get_main_queue())
                                  usingBlock:^(CMTime time)
    {
        [self.delegate playbackViewCore:self
                         newCurrentTime:CMTimeGetSeconds(time)];
    }];
                                                                                 
    [_item addObserver:(id)self
            forKeyPath:KEY_PATH_BUF_EMPTY
               options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
               context:nil];
    
    [_item addObserver:self
            forKeyPath:KEY_PATH_KEEPUP
               options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionNew
               context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    NSLog(@"[%@] %@", keyPath, change);
    
    if ([keyPath isEqualToString:KEY_PATH_STATUS])
    {
        
    }
    else if ([keyPath isEqualToString:KEY_PATH_BUF_EMPTY])
    {

    }
    else if ([keyPath isEqualToString:KEY_PATH_KEEPUP])
    {
        
    }
}

- (void)_cleanUp
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[self player] removeObserver:self forKeyPath:KEY_PATH_STATUS];
    [_item removeObserver:self forKeyPath:KEY_PATH_KEEPUP];
    [_item removeObserver:self forKeyPath:KEY_PATH_BUF_EMPTY];
}

- (void)dealloc
{
    [self _cleanUp];
}

@end
