//
//  ViewController.m
//  pingDemo
//
//  Created by yangrui on 2022/3/21.
//  Copyright © 2022 yangrui. All rights reserved.
//

#import "ViewController.h"
#import "UCP_PingManager.h"

@interface ViewController ()
@property(nonatomic, strong) UCP_PingManager *pingMgr;
@end

@implementation ViewController

 
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}
 
 
 
- (IBAction)startBtnClick:(id)sender {
//    [self startPing];
    self.pingMgr = [[UCP_PingManager alloc] init];
//    self.pingMgr.pingCount = 2;
    
    
    [self.pingMgr startPingWithCallback:^(BOOL isReachablility, NSString *pingInfo) {
        NSLog(@"isReachablility : %d",isReachablility);
        NSLog(@"pingInfo : %@",pingInfo);
    }];
}


- (IBAction)stopBtnClick:(id)sender {
//    [self stopPing];
    
    
    
}




@end
