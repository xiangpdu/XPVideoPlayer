//
//  XPVideoPlayerProvider.h
//  XPVideoPlayer
//
//  Created by duxiangping on 16/5/17.
//  Copyright © 2016年 duxiangping. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface XPVideoPlayerProvider : NSObject<AVAssetResourceLoaderDelegate>

-(instancetype)initWithScheme:(NSString*)scheme;

@end
