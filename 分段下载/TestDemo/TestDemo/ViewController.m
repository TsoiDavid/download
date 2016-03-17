//
//  ViewController.m
//  TestDemo
//
//  Created by admin on 16/3/17.
//  Copyright © 2016年 admin. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, strong) NSString *tempPath;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    
    
    
    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    NSLog(@"document ==== %@",document);
    
    _tempPath = [document stringByAppendingPathComponent:@"temp.mp4"];
    NSLog(@"tempPath ==== %@",_tempPath);
   
    if ([[NSFileManager defaultManager]fileExistsAtPath:_tempPath]) {
        [[NSFileManager defaultManager]removeItemAtPath:_tempPath error:nil];
        [[NSFileManager defaultManager]createFileAtPath:_tempPath contents:nil attributes:nil];
    }else {
        [[NSFileManager defaultManager]createFileAtPath:_tempPath contents:nil attributes:nil];
    }
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
