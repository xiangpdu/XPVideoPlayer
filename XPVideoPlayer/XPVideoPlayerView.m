//
//  XPVideoPlayerView.m
//  XPVideoPlayer
//
//  Created by duxiangping on 16/5/16.
//  Copyright © 2016年 duxiangping. All rights reserved.
//

#import "XPVideoPlayerView.h"
#import "XPVideoPlayer.h"

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@interface XPVideoPlayerView () <XPVideoPlayerDelegate>
{
    BOOL _isControlsHidding;
    BOOL _isPlayingForSlider;
    BOOL _isAnimatingToolbar;
    
    CGPoint _firstPoint;
}
@property(nonatomic, strong) UIView *controlBarView;
@property(nonatomic, strong) UILabel *currentTimeLabel;
@property(nonatomic, strong) UILabel *totalTimeLabel;
@property(nonatomic, strong) UISlider *progressSlider;
@property(nonatomic, strong) UIButton *fullscreenButton;
@property(nonatomic, strong) UIButton *playButton;
@property(nonatomic, strong) UIButton *pauseButton;

@property(nonatomic, strong) UISlider *volumeSlider;

@property (nonatomic, assign) CGFloat moveTouchY;
@property (nonatomic, assign) CGFloat moveTouchX;
@end

@implementation XPVideoPlayerView

- (void)dealloc
{
    [self detachPlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    _player = [[XPVideoPlayer alloc] init];
    _player.looping = NO;
    
    [self setupViews];
    
    [self attachPlayer];
    
    // Sing tap to paly or pause
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playerViewTaped:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    tapGestureRecognizer.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:tapGestureRecognizer];
    
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    for (UIView *aView in [volumeView subviews]) {
        if ([aView.class.description isEqualToString:@"MPVolumeSlider"]) {
            self.volumeSlider = (UISlider *)aView;
            break;
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)setupViews
{
    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playButton setImage:[UIImage imageNamed:@"VideoPlayerPlay"] forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(actionPlay:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.playButton];
    
    self.pauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.pauseButton setImage:[UIImage imageNamed:@"VideoPlayerPause"] forState:UIControlStateNormal];
    [self.pauseButton addTarget:self action:@selector(actionPause:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.pauseButton];
    self.pauseButton.hidden = YES;
    
    self.controlBarView = [[UIView alloc] init];
    self.controlBarView.backgroundColor = [UIColor colorWithRed:0/255 green:0/255 blue:0/255 alpha:0.75];
    self.controlBarView.autoresizesSubviews = YES;
    [self addSubview:self.controlBarView];
    
    self.progressSlider = [[UISlider alloc] init];
    self.progressSlider.minimumTrackTintColor = [UIColor colorWithRed:0.96 green:0.34 blue:0.34 alpha:1];
    self.progressSlider.maximumTrackTintColor = [UIColor lightGrayColor];
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"VideoProgressThumb"] forState:UIControlStateNormal];
    [self.progressSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.progressSlider addTarget:self action:@selector(progressSliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside];
    [self.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpOutside];
    self.progressSlider.minimumValue = 0.f;
    self.progressSlider.continuous = YES;
    self.progressSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    [self.controlBarView addSubview:self.progressSlider];
    
    self.currentTimeLabel = [[UILabel alloc] init];
    self.currentTimeLabel.textColor = [UIColor colorWithRed:0.9 green:0.91 blue:0.91 alpha:1];
    self.currentTimeLabel.font = [UIFont systemFontOfSize:12.f];
    self.currentTimeLabel.text = @"00:00";
    self.currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    self.currentTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleRightMargin;
    [self.controlBarView addSubview:self.currentTimeLabel];
    
    self.totalTimeLabel = [[UILabel alloc] init];
    self.totalTimeLabel.textColor = [UIColor colorWithRed:0.9 green:0.91 blue:0.91 alpha:1];
    self.totalTimeLabel.font = [UIFont systemFontOfSize:12.f];
    self.totalTimeLabel.text = @"00:00";
    self.totalTimeLabel.textAlignment = NSTextAlignmentCenter;
    self.totalTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleLeftMargin;
    [self.controlBarView addSubview:self.totalTimeLabel];
    
    self.fullscreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.fullscreenButton setImage:[UIImage imageNamed:@"VideoFullscreen"] forState:UIControlStateNormal];
    [self.fullscreenButton addTarget:self action:@selector(actionSwitchToFullscreen:) forControlEvents:UIControlEventTouchUpInside];
    [self.controlBarView addSubview:self.fullscreenButton];
    
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor blackColor];
}

- (void)layoutSubviews
{
    self.controlBarView.frame = CGRectMake(0, CGRectGetHeight(self.frame)-44, CGRectGetWidth(self.frame), 44);
    if(_isControlsHidding){
        self.controlBarView.frame = CGRectMake(0, CGRectGetHeight(self.frame), CGRectGetWidth(self.frame), 44);
    }
    
    [self.currentTimeLabel sizeToFit];
    CGRect frame = self.currentTimeLabel.frame;
    frame.origin.x = 10;
    frame.origin.y = (CGRectGetHeight(self.controlBarView.frame)-CGRectGetHeight(self.currentTimeLabel.frame))/2;
    frame.size.width += 5;
    self.currentTimeLabel.frame = frame;
    
    self.fullscreenButton.frame = CGRectMake(CGRectGetWidth(self.controlBarView.frame)-5-24, 0, 24, CGRectGetHeight(self.controlBarView.frame));
    
    [self.totalTimeLabel sizeToFit];
    frame = self.totalTimeLabel.frame;
    frame.origin.x = CGRectGetMinX(self.fullscreenButton.frame) - 5 - frame.size.width;
    frame.origin.y = (CGRectGetHeight(self.controlBarView.frame)-CGRectGetHeight(self.totalTimeLabel.frame))/2;
    frame.size.width += 5;
    self.totalTimeLabel.frame = frame;
    
    self.progressSlider.frame = CGRectMake(CGRectGetMaxX(self.currentTimeLabel.frame)+5, 0, CGRectGetMinX(self.totalTimeLabel.frame)-CGRectGetMaxX(self.currentTimeLabel.frame)-5*2, CGRectGetHeight(self.controlBarView.frame));
    
    self.playButton.frame = CGRectMake((CGRectGetWidth(self.frame)-44.f)/2, (CGRectGetHeight(self.frame)-44.f)/2, 44.f, 44.f);
    self.pauseButton.frame = self.playButton.frame;
    
    [super layoutSubviews];
}

#pragma mark - Actions

- (void)orientationChanged:(NSNotification *)notification
{
    [self setNeedsLayout];
}

- (void)actionSwitchToFullscreen:(id)sender
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerViewWantsFullscreen:)]){
        [self.delegate videoPlayerViewWantsFullscreen:self];
    }
}

- (void)progressSliderValueChanged:(UISlider *)sender
{
    [self updateCurrentTimeLabel:sender.value];
    
    CMTime time = CMTimeMakeWithSeconds(sender.value, _player.player.currentItem.currentTime.timescale);
    
    [_player.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        
    }];
}

- (void)progressSliderTouchDown:(UISlider *)sender
{
    _isPlayingForSlider = _player.isPlaying;
    if(_isPlayingForSlider){
        [_player pause];
    }
}

- (void)progressSliderTouchEnded:(UISlider *)sender
{
    if(_isPlayingForSlider){
        [_player play];
    }
}

- (void)actionPlay:(id)sender
{
    self.playButton.hidden = YES;
    self.pauseButton.hidden = NO;
    [_player play];
    
    [self performSelector:@selector(hideControls) withObject:nil afterDelay:3.f];
}

- (void)actionPause:(id)sender
{
    self.playButton.hidden = NO;
    self.playButton.alpha = 1.f;
    self.pauseButton.hidden = YES;
    self.pauseButton.alpha = 1.f;
    [_player pause];
}

- (void)playerViewTaped:(UITapGestureRecognizer *)recognizer
{
    if(_isControlsHidding){
        [self showControls];
    }else{
        [self hideControls];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    _firstPoint = [touch locationInView:self];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //    [super touchesMoved:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint p1 = [touch locationInView:self];
    CGPoint p2 = [touch previousLocationInView:self];
    CGFloat dy = p1.y - p2.y;
    CGFloat dx = p1.x - p2.x;
    
    if (fabs(dy) > fabs(dx)) {
        // For volume change
        self.moveTouchY = self.moveTouchY + dy;
        if (self.moveTouchY > 10.0) {
            self.moveTouchY = 0;
            self.volumeSlider.value = self.volumeSlider.value - 1.0/16.0;
        }else if (self.moveTouchY < -10.0) {
            self.moveTouchY = 0;
            self.volumeSlider.value = self.volumeSlider.value + 1.0/16.0;
        }
    }else {
        // For progress change
        self.moveTouchX = self.moveTouchX + dx;
        
        CGFloat deltaProgress = MAX(1.f, self.progressSlider.maximumValue/CGRectGetWidth(self.frame));
        
        if (self.moveTouchX > 10.0) {
            [self.player pause];
            
            self.moveTouchX = 0;
            CGFloat progress = self.progressSlider.value + deltaProgress;
            [self.progressSlider setValue:progress animated:YES];
            
        }else if (self.moveTouchX < -10.0) {
            [self.player pause];
            
            self.moveTouchX = 0;
            CGFloat progress = self.progressSlider.value - deltaProgress;
            [self.progressSlider setValue:progress animated:YES];
        }
        
        //        NSLog(@"deltaProgress: %f", deltaProgress);
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //    [super touchesEnded:touches withEvent:event];
    [self progressSliderValueChanged:self.progressSlider];
}

- (void)updateButtonState
{
    if(self.player.isPlaying){
        self.playButton.hidden = YES;
        self.pauseButton.hidden = NO;
    }else{
        self.playButton.hidden = NO;
        self.pauseButton.hidden = YES;
    }
}

- (void)updateCurrentTimeLabel:(Float64)value
{
    self.currentTimeLabel.text = [self textWithSeconds:value];
    [self setNeedsLayout];
}

#pragma mark - Public API

- (void)setPlayer:(XPVideoPlayer *)player
{
    if (_player == player)
    {
        return;
    }
    
    [self detachPlayer];
    
    _player = player;
    
    [self attachPlayer];
}

- (void)setVideoFillMode:(NSString *)fillMode
{
    AVPlayerLayer *playerLayer = (AVPlayerLayer*)[self layer];
    playerLayer.videoGravity = fillMode;
}

#pragma mark - Private API

- (void)attachPlayer
{
    if (_player)
    {
        _player.delegate = self;
        
        [(AVPlayerLayer *)[self layer] setPlayer:_player.player];
    }
}

- (void)detachPlayer
{
    if (_player && _player.delegate == self)
    {
        _player.delegate = nil;
    }
    
    [(AVPlayerLayer *)[self layer] setPlayer:nil];
}

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (void)hideControls
{
    _isAnimatingToolbar = YES;
    [UIView animateWithDuration:0.3f animations:^{
        CGRect frame = self.controlBarView.frame;
        frame.origin.y = CGRectGetHeight(self.frame);
        self.controlBarView.frame = frame;
        self.controlBarView.alpha = 0.3f;
        
        self.playButton.alpha = 0.3f;
        self.pauseButton.alpha = 0.3f;
    } completion:^(BOOL finished) {
        _isControlsHidding = YES;
        self.controlBarView.hidden = YES;
        
        self.playButton.hidden = YES;
        self.pauseButton.hidden = YES;
        
        _isAnimatingToolbar = NO;
    }];
}

- (void)showControls
{
    _isAnimatingToolbar = YES;
    [UIView animateWithDuration:0.3f animations:^{
        CGRect frame = self.controlBarView.frame;
        frame.origin.y = CGRectGetHeight(self.frame)-CGRectGetHeight(frame);
        self.controlBarView.frame = frame;
        self.controlBarView.alpha = 1.f;
        
        self.playButton.alpha = 1.f;
        self.pauseButton.alpha = 1.f;
    } completion:^(BOOL finished) {
        _isControlsHidding = NO;
        self.controlBarView.hidden = NO;
        
        [self updateButtonState];
        
        _isAnimatingToolbar = NO;
    }];
}

#pragma mark - VideoPlayerDelegate

- (void)videoPlayerIsReadyToPlayVideo:(XPVideoPlayer *)videoPlayer
{
    CMTime duration = _player.player.currentItem.duration;
    double durationSec = CMTimeGetSeconds(duration);
    self.progressSlider.maximumValue = durationSec;
    self.currentTimeLabel.text = @"00:00";
    self.totalTimeLabel.text = [self textWithSeconds:durationSec];
    
    self.playButton.hidden = YES;
    self.pauseButton.hidden = NO;
    
    [self performSelector:@selector(hideControls) withObject:nil afterDelay:3.f];
}

- (void)videoPlayerDidReachEnd:(XPVideoPlayer *)videoPlayer
{
    [self actionPause:nil];
}

- (void)videoPlayer:(XPVideoPlayer *)videoPlayer timeDidChange:(CMTime)cmTime
{
    CMTime duration = _player.player.currentItem.duration;
    Float64 durationSec = CMTimeGetSeconds(duration);
    Float64 current = CMTimeGetSeconds(cmTime);
    self.currentTimeLabel.text = [self textWithSeconds:current];
    self.totalTimeLabel.text = [self textWithSeconds:durationSec];
    [self.progressSlider setValue:current animated:YES];
    if(! _isAnimatingToolbar){
        [self setNeedsLayout];
    }
    
}

- (void)videoPlayer:(XPVideoPlayer *)videoPlayer loadedTimeRangeDidChange:(float)duration
{
    
}

- (void)videoPlayerPlaybackBufferEmpty:(XPVideoPlayer *)videoPlayer
{
    NSLog(@"---videoPlayerPlaybackBufferEmpty");
}

- (void)videoPlayer:(XPVideoPlayer *)videoPlayer didFailWithError:(NSError *)error
{
    [self actionPause:nil];
}

#pragma mark - Helpers

- (NSString *)textWithSeconds:(Float64)sec
{
    int totalSeconds = (int)sec;
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    if(totalSeconds>3600)
        return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
    else{
        minutes = totalSeconds / 60;
        return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
    }
}

@end
