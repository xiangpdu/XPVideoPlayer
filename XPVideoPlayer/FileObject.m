//
//  FileObject.m
//  XPVideoPlayer
//
//  Created by duxiangping on 16/5/23.
//  Copyright © 2016年 duxiangping. All rights reserved.
//

#import "FileObject.h"

@implementation FileObject

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:_number forKey:@"number"];
    [aCoder encodeInteger:_offset forKey:@"offset"];
    [aCoder encodeInteger:_length forKey:@"length"];
}
-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.number = [aDecoder decodeIntegerForKey:@"number"];
        self.offset = [aDecoder decodeIntegerForKey:@"offset"];
        self.length = [aDecoder decodeIntegerForKey:@"length"];
    }
    return self;
}
-(NSString *)description
{
    return  [NSString stringWithFormat:@"number=%ld,offset=%ld,length=%ld",_number,_offset,_length];
}
@end
