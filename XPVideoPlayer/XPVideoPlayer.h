//
//  XPVideoPlayer.h
//  XPVideoPlayer
//
//  Created by duxiangping on 16/5/16.
//  Copyright © 2016年 duxiangping. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class AVPlayer;
@class XPVideoPlayer;

@protocol XPVideoPlayerDelegate <NSObject>

@optional
- (void)videoPlayerIsReadyToPlayVideo:(XPVideoPlayer *)videoPlayer;
- (void)videoPlayerDidReachEnd:(XPVideoPlayer *)videoPlayer;
- (void)videoPlayer:(XPVideoPlayer *)videoPlayer timeDidChange:(CMTime)cmTime;
- (void)videoPlayer:(XPVideoPlayer *)videoPlayer loadedTimeRangeDidChange:(float)duration;
- (void)videoPlayerPlaybackBufferEmpty:(XPVideoPlayer *)videoPlayer;
- (void)videoPlayerPlaybackLikelyToKeepUp:(XPVideoPlayer *)videoPlayer;
- (void)videoPlayer:(XPVideoPlayer *)videoPlayer didFailWithError:(NSError *)error;

@end

@interface XPVideoPlayer : NSObject

@property (nonatomic, weak) id<XPVideoPlayerDelegate> delegate;

@property (nonatomic, strong, readonly) AVPlayer *player;

@property (nonatomic, assign, getter=isPlaying, readonly) BOOL playing;
@property (nonatomic, assign, getter=isLooping) BOOL looping;
@property (nonatomic, assign, getter=isMuted) BOOL muted;
@property (nonatomic, assign,getter=isSupportCache)BOOL SupportCache;

- (void)setURL:(NSURL *)URL;
/**
 you must initial playerItem with an AVURLAsset object
*/

- (void)setPlayerItem:(AVPlayerItem *)playerItem;

- (void)setUrlAsset:(AVURLAsset *)asset;

// Playback

- (void)play;
- (void)pause;
- (void)seekToTime:(float)time;
- (void)reset;

// AirPlay

- (void)enableAirplay;
- (void)disableAirplay;
- (BOOL)isAirplayEnabled;

// Time Updates

- (void)enableTimeUpdates; // TODO: need these? no
- (void)disableTimeUpdates;

// Scrubbing

- (void)startScrubbing;
- (void)scrub:(float)time;
- (void)stopScrubbing;

// Volume

- (void)setVolume:(float)volume;
- (void)fadeInVolume;
- (void)fadeOutVolume;

@end