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
#import "ehm.h"

#define KEY_PATH_STATUS     @"status"
#define KEY_PATH_BUF_EMPTY  @"playbackBufferEmpty"
#define KEY_PATH_KEEPUP     @"playbackLikelyToKeepUp"
#define KEY_PATH_LOADEDRANGE    @"loadedTimeRanges"

#define DESIRED_BUFFER      CMTimeMake(10, 1)

@implementation P2PPlayer4iOS
{
    AVPlayerItem *_item;
    
    BOOL _isPaused;
    BOOL _isBufferring;
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
    [self play];
    
    [self _hookPlayback];
    
    return YES;
}

#pragma mark PlaybackViewCore
- (void)play
{
    _isPaused = NO;
    _isBufferring = NO;
    
    [[self player] play];
}

- (void)pause
{
    if (!_isPaused)
    {
        _isPaused = YES;
        [[self player] pause];
    }
    else
    {
        [self play];
    }
}

- (Float64)seekTo:(Float64)seconds
{
    seconds = MIN(seconds, self.duration);
    
    _isBufferring = YES;
    [[self player] pause];
    
    CMTime time = CMTimeMakeWithSeconds(seconds, 1);
    [_item seekToTime:time completionHandler:^(BOOL finished) {
        [self _tryToResume];
    }];
    
    return CMTimeGetSeconds([_item currentTime]);
}

- (BOOL)isBufferring
{
    return _isBufferring;
}

- (BOOL)didReachEnd
{
    return CMTimeCompare(_item.currentTime, _item.duration) != -1;
}

- (BOOL)isPaused
{
    if (_isPaused)
    {
        VBR([self player].rate == 0.0f);
    }
    
    return _isPaused;
}

- (BOOL)isPlaying
{
    if ([self isPaused])
    {
        VBR([self player].rate == 0.0f);
    }
    
    return [self player].rate > 0.0f;
}

- (Float64)duration
{
    if (CMTIME_IS_INVALID([_item duration]))
    {
        return 60.0 * 60 * 60;  // large number
    }
    
    return CMTimeGetSeconds([_item duration]);
}

- (Float64)currentTime
{
    return CMTimeGetSeconds([_item currentTime]);
}

- (Float64)startOfLoaded
{    
    return CMTimeGetSeconds([self _loadedTimeRange].start);
}

- (Float64)durationOfLoaded
{
    return CMTimeGetSeconds([self _loadedTimeRange].duration);
}

- (Float64)endOfLoaded
{
    return CMTimeGetSeconds(CMTimeRangeGetEnd([self _loadedTimeRange]));
}

#pragma mark private
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
               options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
               context:nil];
    
    [_item addObserver:self
            forKeyPath:KEY_PATH_LOADEDRANGE
               options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
               context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_playbackDidEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:_item];
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
        BOOL empty = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (!empty)
        {
            [self _tryToResume];
        }
        else
        {
            _isBufferring = empty;
        }
        
        [self.delegate playbackViewCore:self isBufferring:[self isBufferring]];
    }
    else if ([keyPath isEqualToString:KEY_PATH_KEEPUP])
    {
        if (_item.playbackLikelyToKeepUp && [self isBufferring])
        {
            [self _tryToResume];
            
            [self.delegate playbackViewCore:self isBufferring:[self isBufferring]];
        }
    }
    else if ([keyPath isEqualToString:KEY_PATH_LOADEDRANGE])
    {
        [self _tryToResume];
        [self.delegate playbackViewCoreLoadedRangeChanged:self];
    }
}

- (void)_playbackDidEnd:(NSNotification*)notif
{
    NSLog(@"[_playbackDidEnd] %@", notif.userInfo);
    
    _isPaused = NO;
    _isBufferring = NO;
    
    [self.delegate playbackViewCoreDidEnd:self];
}

- (void)_tryToResume
{
    if ([self isPaused] || [self isPlaying])
    {
        return;
    }
    
    Float64 last = [self endOfLoaded];
    Float64 expect = CMTimeGetSeconds(CMTimeAdd(_item.currentTime, DESIRED_BUFFER));
    expect = MIN(expect, [self duration]);
    
    if (last >= expect)
    {
        // we have enough buffer now!
        [self play];
    }
}

- (CMTimeRange)_loadedTimeRange
{
    NSArray *ranges = [_item loadedTimeRanges];
    if ([ranges count] == 0)
    {
        return kCMTimeRangeZero;
    }
    
    NSValue *val = [ranges objectAtIndex:0];
    CMTimeRange range = {0};
    [val getValue:&range];
    
    if (CMTIMERANGE_IS_INVALID(range))
    {
        VBR(0);
        range = kCMTimeRangeZero;
    }
    
    return range;
}

- (void)_cleanUp
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[self player] removeObserver:self forKeyPath:KEY_PATH_STATUS];
    [_item removeObserver:self forKeyPath:KEY_PATH_KEEPUP];
    [_item removeObserver:self forKeyPath:KEY_PATH_BUF_EMPTY];
    [_item removeObserver:self forKeyPath:KEY_PATH_LOADEDRANGE];
}

- (void)dealloc
{
    [self _cleanUp];
}

@end
