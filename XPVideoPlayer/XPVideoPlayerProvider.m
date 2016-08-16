//
//  XPVideoPlayerProvider.m
//  XPVideoPlayer
//
//  Created by duxiangping on 16/5/17.
//  Copyright © 2016年 duxiangping. All rights reserved.
//

#import "XPVideoPlayerProvider.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "XPVideoCache.h"

static NSInteger maxsizeperresponse = 1024*1024*4;

@interface XPVideoPlayerProvider ()<AVAssetResourceLoaderDelegate,NSURLSessionDataDelegate>
@property (nonatomic, strong)NSString *acturalscheme;
@property (nonatomic, strong)NSURLSessionDataTask *datatask;
@property (nonatomic, strong)NSURLSession *session;
@property (nonatomic, strong)NSMutableURLRequest *request;
@property (nonatomic, strong)NSMutableData *datacontainer;
@property (nonatomic, assign)NSInteger offset;
@property (nonatomic, strong)NSMutableArray *prerequests;
@property (nonatomic, assign)NSInteger currentnumberofblock;
@property (nonatomic, assign)NSInteger videolength;
@property (nonatomic, strong)NSURL *acturalurl;
@property (nonatomic, assign)NSInteger loadingoffset;
@property (nonatomic, strong)XPVideoCache *cache;
@property (nonatomic, assign)BOOL fired;
@end


@implementation XPVideoPlayerProvider

-(instancetype)initWithScheme:(NSString *)scheme
{
    if (self = [super init]) {
        self.acturalscheme = scheme;
        self.videolength = 0;
        _prerequests = [[NSMutableArray alloc]init];
        _fired = NO;
    }
    return self;
}

-(void)setupsessionforrange:(NSRange)range
{
    NSLog(@"setupsessionforrange:%ld,%ld",range.location,range.length);
    _loadingoffset = range.location;
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    _request = [NSMutableURLRequest requestWithURL:self.acturalurl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20];
    [_request addValue:[NSString stringWithFormat:@"bytes=%ld-%ld",range.location ,range.location + range.length -1] forHTTPHeaderField:@"Range"];
    _datatask = [_session dataTaskWithRequest:self.request];
}

-(void)firedatatask
{
    if(self.datatask)
    {
        [self.datatask resume];
        _fired = YES;
    }
}
-(void)canceldatatask
{
    if(self.datatask)
    {
        [self.datatask cancel];
        _fired = NO;
    }
}
-(NSInteger)GetVideoLength:(NSHTTPURLResponse *)response
{
    NSDictionary *dic = [response allHeaderFields];
    NSString * str = dic[@"Content-Range"];
    NSArray *array = [str componentsSeparatedByString:@"/"];
    NSString *length = array.lastObject;
    if([length integerValue] == 0) return response.expectedContentLength;
    [[NSUserDefaults standardUserDefaults] setInteger:length.integerValue forKey:_acturalurl.absoluteString];
    return length.integerValue;
}

-(NSURL *)GetacturalURL:(NSURL *)url
{
    NSURLComponents *component = [[NSURLComponents alloc]initWithURL:url resolvingAgainstBaseURL:NO];
    component.scheme = self.acturalscheme;
    return component.URL;
}

-(void)handprerequestswithdata:(NSData*)data
{
    for (int i=0; i<_prerequests.count; i++) {
        AVAssetResourceLoadingRequest *request = _prerequests[i];
        if (request.dataRequest.currentOffset >= _loadingoffset && request.dataRequest.currentOffset < _loadingoffset +data.length) {
            NSInteger offset = request.dataRequest.currentOffset-_loadingoffset;
            NSInteger length1 = request.dataRequest.requestedLength - (request.dataRequest.currentOffset-request.dataRequest.requestedOffset);
            NSInteger length2 = data.length - offset;
            NSRange range = NSMakeRange(offset, MIN(length1, length2));
            [request.dataRequest respondWithData:[data subdataWithRange:range]];
            NSData * pdata = nil;
            do {
                pdata = [self.cache requestdatawithoffset:request.dataRequest.currentOffset andlength:MIN(request.dataRequest.requestedLength - (request.dataRequest.currentOffset-request.dataRequest.requestedOffset), maxsizeperresponse)];
                if(pdata)
                {
                    [request.dataRequest respondWithData:pdata];
                }
            } while (pdata);
            
            if (request.dataRequest.currentOffset == request.dataRequest.requestedLength + request.dataRequest.requestedOffset) {
                [self fillInContentInformation:request.contentInformationRequest];
                [request finishLoading];
                [_prerequests removeObject:request];
            }
        }
        
    }
}
-(void)handlecurrentrequest:(AVAssetResourceLoadingRequest*)loadingrequest
{
    NSInteger offset = loadingrequest.dataRequest.currentOffset;
    NSInteger length = loadingrequest.dataRequest.requestedLength;
    while (loadingrequest.dataRequest.requestedOffset + length >offset) {
        NSInteger currentlength = length - offset + loadingrequest.dataRequest.requestedOffset;
        NSData *data = [self.cache requestdatawithoffset:offset andlength:MIN(currentlength, maxsizeperresponse)];
        if (data == nil) {
            break;
        }
        [loadingrequest.dataRequest respondWithData:data];
        offset = loadingrequest.dataRequest.currentOffset;
    }
    
    if (offset >= loadingrequest.dataRequest.requestedOffset + loadingrequest.dataRequest.requestedLength) {
        [self fillInContentInformation:loadingrequest.contentInformationRequest];
        [loadingrequest finishLoading];
        [_prerequests removeObject:loadingrequest];
        return;
    }
    if (_fired==NO || offset - _loadingoffset > 1024*1024 || offset < _loadingoffset ) {
        NSRange range = NSMakeRange(offset, length - (loadingrequest.dataRequest.currentOffset-loadingrequest.dataRequest.requestedOffset));
        _loadingoffset = offset;
        [self canceldatatask];
        [self setupsessionforrange:range];
        [self firedatatask];
    }
}

#pragma mark  - avassetresourceloaderdelegate methods

- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest
{
    NSString *mimeType = @"video/mp4";
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = self.videolength;
}

-(BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"shouldWaitForLoadingOfRequestedResource");
    NSLog(@"%lld",loadingRequest.dataRequest.requestedOffset);
    NSLog(@"%ld" ,loadingRequest.dataRequest.requestedLength);
    if (self.acturalurl == nil) {
        self.acturalurl = [self GetacturalURL:[loadingRequest request].URL];
        self.cache = [[XPVideoCache alloc]initWithURL:self.acturalurl];
        self.videolength = [[NSUserDefaults standardUserDefaults]integerForKey:_acturalurl.absoluteString];
    }
    [self.prerequests addObject:loadingRequest];
    [self handlecurrentrequest:loadingRequest];
    return YES;
}

-(BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForRenewalOfRequestedResource:(AVAssetResourceRenewalRequest *)renewalRequest
{
    NSLog(@"shouldWaitForRenewalOfRequestedResource");
    return YES;
}

-(void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"didCancelLoadingRequest");
    [self.prerequests removeObject:loadingRequest];
}

-(void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)authenticationChallenge
{
    NSLog(@"shouldWaitForRenewalOfRequestedResource");

}
-(BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForResponseToAuthenticationChallenge:(NSURLAuthenticationChallenge *)authenticationChallenge
{
    NSLog(@"shouldWaitForRenewalOfRequestedResource");

    return YES;
}
#pragma mark - session protocol methods

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    //NSLog(@"didReceiveData:%ld",data.length);
    //NSLog(@"loadingoffset:%ld",_loadingoffset);
    if (self.videolength == 0) {
        self.videolength = [self GetVideoLength:(NSHTTPURLResponse*)dataTask.response];
        [[NSUserDefaults standardUserDefaults]setInteger:self.videolength forKey:_acturalurl.absoluteString];
    }
    [self handprerequestswithdata:data];
    BOOL isok = [self.cache cachedata:data withoffset:_loadingoffset];
    if(isok) _loadingoffset +=data.length;
    else NSLog(@"cache data failed,please check the code");
    data = nil;
}
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    _fired = NO;
    AVAssetResourceLoadingRequest *loadingrequest = [_prerequests lastObject];
    if (loadingrequest) {
//        NSInteger currentoffset = loadingrequest.dataRequest.currentOffset;
//        NSInteger requestedoffset = loadingrequest.dataRequest.requestedOffset;
//        NSInteger length = loadingrequest.dataRequest.requestedLength;
//        NSRange range = NSMakeRange(currentoffset, length - (currentoffset - requestedoffset));
//        [self canceldatatask];
//        [self setupsessionforrange:range];
//        [self firedatatask];
        [self handlecurrentrequest:loadingrequest];
    }
    
    NSLog(@"%@",error);
}
@end
