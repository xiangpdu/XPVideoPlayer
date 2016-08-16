//
//  ViewController.m
//  XPVideoPlayer
//
//  Created by duxiangping on 16/5/16.
//  Copyright © 2016年 duxiangping. All rights reserved.
//

#import "ViewController.h"
#import "XPVideoPlayerView.h"
#import "XPVideoPlayer.h"

@interface ViewController ()<XPVideoPlayerViewDelegate>

@property(strong,nonatomic)XPVideoPlayerView *VView;

@property(nonatomic, assign) CGRect originFrame;
@property(nonatomic, assign) BOOL isFullscreenMode;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    _VView = [[XPVideoPlayerView alloc]init];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    _VView = [[XPVideoPlayerView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight([[UIApplication sharedApplication]statusBarFrame])+CGRectGetHeight(self.navigationController.navigationBar.frame), CGRectGetWidth(self.view.frame), CGRectGetWidth(self.view.frame)*9/16)];
    _VView.delegate = self;
    
    [_VView setVideoFillMode:AVLayerVideoGravityResizeAspect];
    XPVideoPlayer * player = [[XPVideoPlayer alloc]init];
    [player enableTimeUpdates];
    [player enableAirplay];
    [player setURL:[NSURL URLWithString:@"https://dn-xpdu.qbox.me/A%20Shaw%20way%20to%20fly%20Alexander%20technique..Butterfly%20lesson%201.mp4"]];
    //http://zyvideo1.oss-cn-qingdao.aliyuncs.com/zyvd/7c/de/04ec95f4fd42d9d01f63b9683ad0
    [player setSupportCache:YES];
    
    [_VView setPlayer:player];
    [player play];
    [_VView setFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:_VView];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if(UIInterfaceOrientationIsPortrait(fromInterfaceOrientation)){
        self.originFrame = self.VView.frame;
        self.VView.frame = [[UIApplication sharedApplication].keyWindow frame];
        self.isFullscreenMode = YES;
        [self.VView removeFromSuperview];
        [[UIApplication sharedApplication].keyWindow addSubview:self.VView];
        
    }else if(UIInterfaceOrientationIsLandscape(fromInterfaceOrientation) && UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        self.VView.frame = self.originFrame;
        self.isFullscreenMode = NO;
        [self.VView removeFromSuperview];
        [self.view addSubview:self.VView];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    UIInterfaceOrientation fromInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if(UIInterfaceOrientationIsPortrait(fromInterfaceOrientation)){
            self.originFrame = self.VView.frame;
            self.VView.frame = [[UIApplication sharedApplication].keyWindow frame];
        }else if(UIInterfaceOrientationIsLandscape(fromInterfaceOrientation) && UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
            self.VView.frame = self.originFrame;
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if(UIInterfaceOrientationIsPortrait(fromInterfaceOrientation)){
            self.isFullscreenMode = YES;
            [self.VView removeFromSuperview];
            
            [[UIApplication sharedApplication].keyWindow addSubview:self.VView];
        }else if(UIInterfaceOrientationIsLandscape(fromInterfaceOrientation) && UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
            self.isFullscreenMode = NO;
            [self.VView removeFromSuperview];
            [self.view addSubview:self.VView];
        }
    }];
}

- (void)videoPlayerViewWantsFullscreen:(XPVideoPlayerView *)videoPlayerView
{
    NSNumber *value = @(UIInterfaceOrientationLandscapeLeft);
    if(self.isFullscreenMode){
        value = @(UIInterfaceOrientationPortrait);
    }
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
