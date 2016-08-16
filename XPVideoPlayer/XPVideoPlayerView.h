//
//  XPVideoPlayerView.h
//  XPVideoPlayer
//
//  Created by duxiangping on 16/5/16.
//  Copyright © 2016年 duxiangping. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


@class XPVideoPlayer;
@class XPVideoPlayerView;

@protocol XPVideoPlayerViewDelegate <NSObject>

@optional
- (void)videoPlayerViewWantsFullscreen:(XPVideoPlayerView *)videoPlayerView;

@end

@interface XPVideoPlayerView : UIView

@property (nonatomic, weak) id<XPVideoPlayerViewDelegate> delegate;

@property (nonatomic, strong) XPVideoPlayer *player;

- (void)setVideoFillMode:(NSString *)fillMode;

@end