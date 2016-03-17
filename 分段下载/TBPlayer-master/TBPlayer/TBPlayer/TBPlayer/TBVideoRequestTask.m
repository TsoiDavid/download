//
//  TBVideoRequestTask.m
//  avplayerSavebufferData
//
//  Created by qianjianeng on 15/9/18.
//  Copyright (c) 2015年 qianjianeng. All rights reserved.
//

#import "TBVideoRequestTask.h"

@interface TBVideoRequestTask () <NSURLConnectionDataDelegate, AVAssetResourceLoaderDelegate>

@property (nonatomic, strong) NSURL           *url;
@property (nonatomic        ) NSUInteger      offset;

@property (nonatomic        ) NSUInteger      videoLength;
@property (nonatomic, strong) NSString        *mimeType;

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableArray  *taskArr;

@property (nonatomic, assign) NSUInteger      downLoadingOffset;
@property (nonatomic, assign) BOOL            once;

@property (nonatomic, strong) NSFileHandle    *fileHandle;
@property (nonatomic, strong) NSString        *tempPath;

@end

@implementation TBVideoRequestTask

- (instancetype)init
{
    self = [super init];
    if (self) {
        _taskArr = [NSMutableArray array];
        /*
         iPhone会为每一个应用程序生成一个私有目录，这个目录位于：
         /Users/sundfsun2009/Library/Application Support/iPhone Simulator/User/Applications下，
         并随即生成一个数字字母串作为目录名，在每一次应用程序启动时，这个字母数字串都是不同于上一次。
         
         所以通常使用Documents目录进行数据持久化的保存，而这个Documents目录可以通过：
         NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserdomainMask，YES) 得到。
         */
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
        //stringByAppendingPathComponent就是将前面的路径格式和后面的普通的字符串格式链接在一起，并且以路径格式返回，在document文件夹下面创建一个临时temp.mp4路径，并根据路径创建文件。
        _tempPath =  [document stringByAppendingPathComponent:@"temp.mp4"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:_tempPath]) {
            //如果该路径有文件，删除。
            [[NSFileManager defaultManager] removeItemAtPath:_tempPath error:nil];
            //创建新的文件。
            [[NSFileManager defaultManager] createFileAtPath:_tempPath contents:nil attributes:nil];
            
        } else {
            [[NSFileManager defaultManager] createFileAtPath:_tempPath contents:nil attributes:nil];
        }
        
    }
    return self;
}

- (void)setUrl:(NSURL *)url offset:(NSUInteger)offset
{
    _url = url;
    _offset = offset;
    
    //如果建立第二次请求，先移除原来文件，再创建新的
    if (self.taskArr.count >= 1) {
        [[NSFileManager defaultManager] removeItemAtPath:_tempPath error:nil];
        [[NSFileManager defaultManager] createFileAtPath:_tempPath contents:nil attributes:nil];
    }
    
    _downLoadingOffset = 0;
    
    //NSURL 和 NSURLComponents 的不同之处在于，URL component属性是 readwrite 的。它提供了安全直接的方法来修改URL的各个部分：
    NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    actualURLComponents.scheme = @"http";
    
    ////请求这个地址， timeoutInterval:10 设置为10s超时：请求时间超过10s会被认为连接不上，连接超时
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[actualURLComponents URL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];
    
    if (offset > 0 && self.videoLength > 0) {
        [request addValue:[NSString stringWithFormat:@"bytes=%ld-%ld",(unsigned long)offset, (unsigned long)self.videoLength - 1] forHTTPHeaderField:@"Range"];
    }

    [self.connection cancel];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [self.connection setDelegateQueue:[NSOperationQueue mainQueue]];
    [self.connection start];
       
}



- (void)cancel
{
    [self.connection cancel];
    
}


#pragma mark -  NSURLConnection Delegate Methods


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _isFinishLoad = NO;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;

    NSDictionary *dic = (NSDictionary *)[httpResponse allHeaderFields] ;
    
    NSString *content = [dic valueForKey:@"Content-Range"];
    NSArray *array = [content componentsSeparatedByString:@"/"];
    NSString *length = array.lastObject;
    
    NSUInteger videoLength;
    
    if ([length integerValue] == 0) {
        videoLength = (NSUInteger)httpResponse.expectedContentLength;
    } else {
        videoLength = [length integerValue];
    }
    
    self.videoLength = videoLength;
    self.mimeType = @"video/mp4";
    

    if ([self.delegate respondsToSelector:@selector(task:didReceiveVideoLength:mimeType:)]) {
        [self.delegate task:self didReceiveVideoLength:self.videoLength mimeType:self.mimeType];
    }
    
    [self.taskArr addObject:connection];
    
    
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:_tempPath];
    
   
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    
    [self.fileHandle seekToEndOfFile];
    
    [self.fileHandle writeData:data];

    _downLoadingOffset += data.length;
    
    
    if ([self.delegate respondsToSelector:@selector(didReceiveVideoDataWithTask:)]) {
        [self.delegate didReceiveVideoDataWithTask:self];
    }
    
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
    
    if (self.taskArr.count < 2) {
        _isFinishLoad = YES;
        
        //这里自己写需要保存数据的路径
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
        NSString *movePath =  [document stringByAppendingPathComponent:@"保存数据.mp4"];

        BOOL isSuccess = [[NSFileManager defaultManager] copyItemAtPath:_tempPath toPath:movePath error:nil];
        if (isSuccess) {
            NSLog(@"rename success");
        }else{
            NSLog(@"rename fail");
        }
        NSLog(@"----%@", movePath);
    }
    
    if ([self.delegate respondsToSelector:@selector(didFinishLoadingWithTask:)]) {
        [self.delegate didFinishLoadingWithTask:self];
    }
    
}

//网络中断：-1005
//无网络连接：-1009
//请求超时：-1001
//服务器内部错误：-1004
//找不到服务器：-1003
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (error.code == -1001 && !_once) {      //网络超时，重连一次
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self continueLoading];
        });
    }
    if ([self.delegate respondsToSelector:@selector(didFailLoadingWithTask:WithError:)]) {
        [self.delegate didFailLoadingWithTask:self WithError:error.code];
    }
    if (error.code == -1009) {
        NSLog(@"无网络连接");
    }
}


- (void)continueLoading
{
    _once = YES;
    NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:_url resolvingAgainstBaseURL:NO];
    actualURLComponents.scheme = @"http";
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[actualURLComponents URL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];
    
    [request addValue:[NSString stringWithFormat:@"bytes=%ld-%ld",(unsigned long)_downLoadingOffset, (unsigned long)self.videoLength - 1] forHTTPHeaderField:@"Range"];
    
    
    [self.connection cancel];
     self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [self.connection setDelegateQueue:[NSOperationQueue mainQueue]];
    [self.connection start];
}

- (void)clearData
{
    [self.connection cancel];
    //移除文件
    [[NSFileManager defaultManager] removeItemAtPath:_tempPath error:nil];
    
    
    
}
@end
