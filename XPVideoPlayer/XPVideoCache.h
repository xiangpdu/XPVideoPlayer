//
//  XPVideoCache.h
//  XPVideoPlayer
//
//  Created by duxiangping on 16/5/20.
//  Copyright © 2016年 duxiangping. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XPVideoCache : NSObject
/**this integer indicates the size of video block*/
@property (nonatomic, assign)NSInteger blocksize;
/**write to file when the total data size much than this integer*/
@property (nonatomic, assign)NSInteger maxsize;

-(instancetype)initWithURL:(NSURL*)url;

-(NSData *)requestdatawithoffset:(NSInteger)offset andlength:(NSInteger)length;
-(BOOL)cachedata:(NSData*)data withoffset:(NSInteger)offset;

@end
