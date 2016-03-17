//
//  ViewController.m
//  (分段下载图片)PartialDownloadPictureDemo
//
//  Created by admin on 16/3/17.
//  Copyright © 2016年 admin. All rights reserved.
//

#import "ViewController.h"
#define DownLoadUrl @"http://tupian.enterdesk.com/2012/1102/gha/5/enterdeskcom%20%2811%29.jpg"
#define kFILE_BLOCK_SIZE (1024) //每次1KB
@interface ViewController ()
{
    long long _totalLength;
    long long _loadedLength;
    NSString *pathFile;
    __weak IBOutlet UIImageView *imageView;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /*
     :根据文件名称和文件后缀获取程序包内容文件的路径
     NSURL *urlKindEditor = [[NSBundlemainBundle]URLForResource:@"simple"withExtension:@"html"subdirectory:@"KindEditor/examples"];
     
     URLForResource:文件名称
     withExtension:文件后缀
     subdirectory:在程序包中的哪个子目录中寻找.
     如果没有找到将会返回nil
     找到后返回如下路径: file://localhost/Users/amarishuyi/Library/Application Support/iPhone Simulator/5.1/Applications/FB0CDABC-D0E2-45FF-AA2C-959E8A65ADB4/SmallDemoList.app/KindEditor/examples/simple.html
     */
    //存放在Assets.xcassets 里面的图片无法通过 [[NSBundle mainBundle]URLForResource:@"test" withExtension:@"jpg"];获取到路径，应该把图片放在根目录上。
    //    NSURL *url = [[NSBundle mainBundle]URLForResource:@"test" withExtension:@"jpg"];
    //    NSLog(@"url ===== %@",url);
    
    //网络图片
    NSURL *url = [NSURL URLWithString:DownLoadUrl];
    
    //获取文件大小
    long long fileSize = [self fileSizeWithURL:url];
    NSLog(@"fileSize ==== %lld",fileSize);
    
}

#pragma mark 获取应用沙盒储存位置
- (NSString *)getSavePath {
    pathFile = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject];
    NSLog(@"path ====%@",pathFile);
    return [pathFile stringByAppendingPathComponent:@"temp.jpg"];
}

-(long long)fileSizeWithURL:(NSURL *)url{
    /*
     1> NSURLRequestUseProtocolCachePolicy = 0, 默认的缓存策略， 如果缓存不存在，直接从服务端获取。如果缓存存在，会根据response中的Cache-Control字段判断下一步操作，如: Cache-Control字段为must-revalidata, 则询问服务端该数据是否有更新，无更新的话直接返回给用户缓存数据，若已更新，则请求服务端.
     
     2> NSURLRequestReloadIgnoringLocalCacheData = 1, 忽略本地缓存数据，直接请求服务端.
     
     3> NSURLRequestIgnoringLocalAndRemoteCacheData = 4, 忽略本地缓存，代理服务器以及其他中介，直接请求源服务端.
     
     4> NSURLRequestReloadIgnoringCacheData = NSURLRequestReloadIgnoringLocalCacheData
     
     5> NSURLRequestReturnCacheDataElseLoad = 2, 有缓存就使用，不管其有效性(即忽略Cache-Control字段), 无则请求服务端.
     
     6> NSURLRequestReturnCacheDataDontLoad = 3, 死活加载本地缓存. 没有就失败. (确定当前无网络时使用)
     
     7> NSURLRequestReloadRevalidatingCacheData = 5, 缓存数据必须得得到服务端确认有效才使用(貌似是NSURLRequestUseProtocolCachePolicy中的一种情况)
     */
    
    
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:2.0f];
    
    //设置为头信息请求,在WEB开发中我们还有另一种请求方法“HEAD”，通过这种请求服务器只会响应头信息，其他数据不会返回给客户端，这样一来整个数据的大小也就可以得到了
    request.HTTPMethod=@"HEAD";
    
    NSURLResponse *response;
    NSError *error;
    //注意这里使用了同步请求，直接将文件大小返回
    NSURLSession *session = [[NSURLSession alloc]init];
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error) {
        NSLog(@"detail error:%@",error.localizedDescription);
    }
    
    //返回文件大小长度
    return response.expectedContentLength;
}


#pragma mark 下载指定块大小的数据
-(void)downloadFile:(NSString *)fileName startByte:(long long)start endByte:(long long)end{
    
    //设定下载range值范围，
    NSString *range=[NSString stringWithFormat:@"Bytes=%lld-%lld",start,end];
    NSLog(@"%@",range);
    //    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[self getDownloadUrl:fileName]];
    NSMutableURLRequest *request= [NSMutableURLRequest requestWithURL:[NSURL URLWithString:DownLoadUrl] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5.0f];
    //通过请求头设置数据请求范围，让服务器根据range值返回相对应部分数据
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    NSURLResponse *response;
    NSError *error;
    //注意这里使用同步请求，避免文件块追加顺序错误
    NSData *data= [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(!error){
        NSLog(@"dataLength=%lld",(long long)data.length);
        [self fileAppend:[self getSavePath] data:data];
    }
    else{
        NSLog(@"detail error:%@",error.localizedDescription);
    }
}

#pragma mark 文件追加
-(void)fileAppend:(NSString *)filePath data:(NSData *)data{
    //对文件进行读写操作使用 NSFileHandle
    //打开filePath地址下的文件用于写入操作，默认已经有文件的情况下才创建到。
    NSFileHandle *fileHandle=[NSFileHandle fileHandleForWritingAtPath:filePath];
    //如果存在文件则追加，否则创建
    if (fileHandle) {
        //将当前文件的偏移量定位到文件的末尾
        [fileHandle seekToEndOfFile];
        //将data写入文件
        [fileHandle writeData:data];
        //关闭文件
        [fileHandle closeFile];
    }else{
        [data writeToFile:filePath atomically:YES];//创建文件
    }
}

#pragma mark 文件下载
-(void)downloadFile{
    //获取总长度
    _totalLength=[self fileSizeWithURL:[NSURL URLWithString:DownLoadUrl]];
    //用于下载进度
    _loadedLength=0;
    
    long long startSize=0;
    long long endSize=0;
    //分段下载
    while(startSize< _totalLength){
        //例如指定bytes=0-1023，然后在服务器端解析Range信息，返回该文件的0到1023之间的数据的数据即可（共1024Byte）
        endSize = startSize + kFILE_BLOCK_SIZE - 1;
        if (endSize>_totalLength) {
            endSize=_totalLength-1;
        }
        [self downloadFile:nil startByte:startSize endByte:endSize];
        
        //更新进度
        _loadedLength += (endSize-startSize)+1;
       
        //        [self updateProgress];
        
        
        startSize += kFILE_BLOCK_SIZE;
        
    }
}

#pragma mark 异步下载文件
- (IBAction)downloadFileAsync {
    if (![[NSFileManager defaultManager]fileExistsAtPath:pathFile]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self downloadFile];
        });
    }else {
        NSLog(@"图片已存在");
       

    }
    
}
- (IBAction)clearPictureCaches {
    
}

@end
