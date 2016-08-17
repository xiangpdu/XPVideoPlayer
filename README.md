# XPVideoPlayer

使用AVPlayer自定义播放器，重写网络请求部分，实现边下边播

# usage
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
    [player setSupportCache:YES];
    
    [_VView setPlayer:player];
    [player play];
    [_VView setFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:_VView];
}
