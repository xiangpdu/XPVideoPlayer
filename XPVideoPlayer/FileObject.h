//
//  FileObject.h
//  XPVideoPlayer
//
//  Created by duxiangping on 16/5/23.
//  Copyright © 2016年 duxiangping. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileObject : NSObject<NSCoding>

@property(nonatomic, assign)NSInteger number;
@property(nonatomic, assign)NSInteger offset;
@property(nonatomic, assign)NSInteger length;

@end
