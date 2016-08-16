//
//  XPVideoCache.m
//  XPVideoPlayer
//
//  Created by duxiangping on 16/5/20.
//  Copyright © 2016年 duxiangping. All rights reserved.
//

#import "XPVideoCache.h"
#import "FileObject.h"


static  NSString *VideosKey = @"XPVideosmap";
static  NSInteger bytesperread = 4*1024*1024;

@interface XPVideoCache ()

@property (nonatomic, assign)NSInteger currentsize;
@property (nonatomic, assign)NSMutableArray *datas;
@property (nonatomic, strong)NSFileManager *filemanager;
@property (nonatomic, strong)NSString *videodir;
@property (nonatomic, strong)NSMutableDictionary *videodic;
@property (nonatomic, strong)NSMutableArray *filesmap;
@property (nonatomic, strong)NSURL *url;
@end

@implementation XPVideoCache

-(void)setvalueondictionary:(NSMutableDictionary *)dic forurl:(NSURL *)url
{
    NSInteger i;
    NSArray *array = [dic allValues];
    do {
        i = random();
    } while ([array containsObject:[NSString stringWithFormat:@"%ld",i]]);
    
    [dic setObject:[NSString stringWithFormat:@"%ld",i] forKey:[url absoluteString]];
    
}
-(instancetype)initWithURL:(NSURL*)url
{
    if (self = [super init]) {
        _filemanager = [[NSFileManager alloc]init];
        NSString *docpath = [NSHomeDirectory() stringByAppendingString:@"/Documents"];
        self.url = url;
        [self recoverfromfile];
        NSLog(@"%@",_videodic);
        NSLog(@"%@",_filesmap);
        
        NSString *acturalfile = [_videodic objectForKey:[url absoluteString]];
        if(!acturalfile)
        {
            [self setvalueondictionary:_videodic forurl:url];
            acturalfile = [_videodic objectForKey:[url absoluteString]];
        }
        //_videodir = [docpath stringByAppendingString:[NSString stringWithFormat:@"/videocaches/%@",acturalfile]];
        _videodir = [[NSString alloc]initWithFormat:@"%@/videocaches/%@",docpath,acturalfile];
        BOOL isdirector = YES;
        _filemanager = [NSFileManager defaultManager];
        if(![_filemanager fileExistsAtPath:_videodir isDirectory:&isdirector])
        {
            NSError *error = nil;
            [_filemanager createDirectoryAtPath:_videodir withIntermediateDirectories:YES attributes:nil error:&error];
            if(error)
            {
                NSLog(@"%@",error);
                return self;
            }
        }
    }
    return self;
}

-(NSData *)requestdatawithoffset:(NSInteger)offset andlength:(NSInteger)length
{
    NSLog(@"%@",_filesmap);
    NSData *data = nil;
    if (length == 0) {
        return nil;
    }
    for (int i=0;i<_filesmap.count; i++) {
        FileObject *object = _filesmap[i];
        if (offset >= object.offset && offset < object.offset + object.length) {
            NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:[_videodir stringByAppendingString:[NSString stringWithFormat:@"/%ld",object.number]]];
            NSLog(@"%@",_videodir);
            NSLog(@"%ld",object.number);
            if (handle == nil) {
                NSLog(@"file not existed");
            }
            [handle seekToFileOffset:(offset - object.offset)];
            data = [handle readDataOfLength:length];
            [handle closeFile];
            break;
        }
    }
    return  data;
}
-(BOOL)newfilewithdata:(NSData*)data andoffset:(NSInteger)offset
{
    NSLog(@"create new file");
    NSLog(@"%@",_filesmap);
    NSInteger number;
    BOOL existed;
    do {
        existed = NO;
        number = random();
        for (int i=0; i<_filesmap.count; i++) {
            FileObject *object = _filesmap[i];
            if (object.number == number) {
                existed = YES;
                break;
            }
        }
        
    } while (existed);
    
    FileObject *newfile = [[FileObject alloc]init];
    newfile.number = number;
    newfile.offset = offset;
    newfile.length = data.length;
    
    BOOL issuccess = [_filemanager createFileAtPath:[_videodir stringByAppendingString:[NSString stringWithFormat:@"/%ld",number]] contents:data attributes:nil];
    if (!issuccess) {
        NSLog(@"create file failed");
        return NO;
    }
    else
    {
        [_filesmap addObject:newfile];
    }
    return YES;
}
-(BOOL)cachedata:(NSData *)data withoffset :(NSInteger)offset
{
    NSLog(@"cachedatawithoffset:%ld",offset);
    int i;
    for (i=0; i<_filesmap.count; i++) {
        FileObject *object = _filesmap[i];
        if (object.offset + object.length == offset) {
            NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:[_videodir stringByAppendingString:[NSString stringWithFormat:@"/%ld",object.number]]];
            [handle seekToEndOfFile];
            [handle writeData:data];
            [handle closeFile];
            object.length += data.length;
            break;
        }
    }
    if (i == _filesmap.count) {
        BOOL issuc = [self newfilewithdata:data andoffset:offset];
        if(!issuc) return NO;
    }
    [self storetofile];
    return YES;
}
-(void)checkandmerge
{
    [_filesmap sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [(FileObject*)obj1 offset] - [(FileObject*)obj2 offset];
    }];
    for (int i=1; i<_filesmap.count; i++) {
        FileObject *a = _filesmap[i-1];
        FileObject *b = _filesmap[i];
        if (a.offset+a.length == b.offset) {
            BOOL issuccess = [self mergefile:a.number andfile:b.number];
            if(issuccess)
            {
                a.length += b.length;
                [_filesmap removeObjectAtIndex:i];
            }
        }
    }
}
-(bool)mergefile:(NSInteger)afile andfile:(NSInteger)bfile
{
    NSFileHandle *ahandle = [NSFileHandle fileHandleForWritingAtPath:[_videodir stringByAppendingString:[NSString stringWithFormat:@"/%ld",afile]]];
    NSFileHandle *bhandle = [NSFileHandle fileHandleForReadingAtPath:[_videodir stringByAppendingString:[NSString stringWithFormat:@"/%ld",bfile]]];
    if(ahandle == nil || bhandle == nil) return NO;
    [ahandle seekToEndOfFile];
    NSData *data = [bhandle readDataOfLength:bytesperread];
    while (data) {
        [ahandle writeData:data];
        data = [bhandle readDataOfLength:bytesperread];
    }
    NSError *error = nil;
    [_filemanager removeItemAtPath:[_videodir stringByAppendingString:[NSString stringWithFormat:@"/%ld",bfile]] error:&error];
    if (error) {
        NSLog(@"%@",error);
        return NO;
    }
    [ahandle closeFile];
    [bhandle closeFile];
    
    int i=0,j=0;
    for (int p=0; p<_filesmap.count; p++) {
        FileObject *object = _filesmap[p];
        if(object.number == afile) i=p;
        if(object.number == bfile) j=p;
    }
    
    FileObject *a = _filesmap[i];
    FileObject *b = _filesmap[j];
    a.length += b.length;
    [_filesmap removeObject:b];
    return YES;
}

-(void)recoverfromfile
{
    NSLog(@"recoverfromfile");
    NSDictionary *dic = [[NSUserDefaults standardUserDefaults]objectForKey:VideosKey];
    if(!dic) {
        _videodic  = [[NSMutableDictionary alloc]init];
        _filesmap  = [[NSMutableArray alloc]init];
    }
    else
    {
        _videodic = [[NSMutableDictionary alloc]initWithDictionary:dic];
        _filesmap = [[NSMutableArray alloc]init];
        NSString *acturalvideokey = [_videodic objectForKey:[self.url absoluteString]];
        if(acturalvideokey == nil) return;
        NSArray *array = [[NSUserDefaults standardUserDefaults]objectForKey:acturalvideokey];
        if(array)
        {
            for (int i=0; i<[array count]; i++) {
                FileObject *object = [NSKeyedUnarchiver unarchiveObjectWithData:array[i]];
                [_filesmap addObject:object];
            }
        }
    }
    
}

-(void)storetofile
{
    NSMutableArray *mutablearray = [[NSMutableArray alloc]init];
    for (int i=0; i < [self.filesmap count]; i++) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_filesmap[i]];
        [mutablearray addObject:data];
    }
    NSArray *array = [[NSArray alloc]initWithArray:mutablearray];
    
    NSString *acturalvideokey = [_videodic objectForKey:[self.url absoluteString]];
    
    [[NSUserDefaults standardUserDefaults]setObject:array forKey:acturalvideokey];
    
    [[NSUserDefaults standardUserDefaults]setObject:_videodic forKey:VideosKey];
}

@end
