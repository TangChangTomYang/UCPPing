//
//  UCP_PingManager.h
//  pingDemo
//
//  Created by yangrui on 2022/3/21.
//  Copyright © 2022 yangrui. All rights reserved.
//

#import <UIKit/UIKit.h>
 

@interface UCP_PingManager : NSObject

/// 默认ping1次
@property(nonatomic, assign) NSInteger pingCount;
/// 默认是baidu.com
@property(nonatomic, copy) NSString *hostName;

-(void)startPingWithCallback:(void(^)(BOOL isReachabliluity,  // 网络是否是通的
                                      NSString *pingInfo))callback;









#pragma mark- 获取时间
+(NSString *)getCurrentDateTime;

#pragma mark- 获取网络运营商信息
+(NSString *)getNetWorkProviderInfo;

#pragma mark- 获取app 信息
+(NSString *)getAppInfo;



#pragma mark- DNS 服务器信息
/// 获取本机DNS服务器
+ (NSMutableArray<NSString *> *)getCurrentDNSServers;

#pragma mark- ip 地址解析
+ (BOOL)getHost:(NSString **)hostPtr
           port:(uint16_t *)portPtr
         family:(sa_family_t *)afPtr
    fromAddress:(NSData *)address;

+ (NSString *)hostFromSockaddr4:(const struct sockaddr_in *)pSockaddr4;

+ (NSString *)hostFromSockaddr6:(const struct sockaddr_in6 *)pSockaddr6;

+ (uint16_t)portFromSockaddr4:(const struct sockaddr_in *)pSockaddr4;

+ (uint16_t)portFromSockaddr6:(const struct sockaddr_in6 *)pSockaddr6;
@end
 
