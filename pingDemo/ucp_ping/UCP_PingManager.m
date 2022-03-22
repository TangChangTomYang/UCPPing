//
//  UCP_PingManager.m
//  pingDemo
//
//  Created by yangrui on 2022/3/21.
//  Copyright © 2022 yangrui. All rights reserved.
//

#import "UCP_PingManager.h"
#import "UCP_Ping.h"

#include <netdb.h>
#import <arpa/inet.h>
#include <resolv.h>

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>



@interface UCP_PingManager ()<UCP_PingDelegate>
@property(nonatomic, strong) UCP_Ping *ping;
@property(nonatomic, strong) NSMutableDictionary *dicM;
@property(nonatomic, strong) NSMutableString *stringM;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, strong)void(^completeCallback)(BOOL isReachabliluity, NSString *pingInfo);

/// 网络是否是通的
@property(nonatomic, assign)BOOL isReachability;

@end

@implementation UCP_PingManager


-(NSMutableString *)stringM{
    if (!_stringM) {
        _stringM = [NSMutableString stringWithString:@""];
    }
    return _stringM;
}

-(NSMutableDictionary *)dicM{
    if (!_dicM) {
        _dicM = [NSMutableDictionary dictionary];
    }
    return _dicM;
}

-(NSString *)hostName{
    if (_hostName.length == 0) {
        _hostName = @"www.baidu.com";
    }
    return _hostName;
}


-(void)appInfoString:(NSString *)str{
    if (str.length > 0) {
        [self.stringM appendFormat:@"\n%@", str];
//        NSLog(@"%@",str);
    }
}

@synthesize pingCount = _pingCount;
-(NSInteger)pingCount{
    if(_pingCount == 0){
        _pingCount = 1;
    }
    return _pingCount;;
}

-(void)setPingCount:(NSInteger)pingCount{
    _pingCount = pingCount;
    if (_pingCount < 1) {
        _pingCount = 1;
    }
}

-(void)emptyTimer{
    [self.timer invalidate];
    self.timer = nil;
}

-(void)startTimer{
    [self  emptyTimer];
    NSTimeInterval len = (self.pingCount - 1) * 1;
    if (len < 2) {
        len = 2;
    }
//    NSLog(@"time out : %f", len);
    self.timer = [NSTimer scheduledTimerWithTimeInterval:len target:self selector:@selector(timerAction:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

-(void)timerAction:(NSTimer *)timer{
    [self emptyTimer];
    [self stopPing];
}

//@property(nonatomic, assign) NSInteger pingCount;
-(void)startPingWithCallback:(void(^)(BOOL isReachabliluity,  // 网络是否是通的
                                      NSString *pingInfo))callback{
    self.completeCallback = callback;
     
    [self startPing]; 
}

-(void)startPing{
    [self emptyPing];
    [self startTimer];
    
    [self appInfoString:@"---------start ping-------------"];
    [self appInfoString:[NSString stringWithFormat:@"时间-------------\n%@", [UCP_PingManager getCurrentDateTime]]];
    [self appInfoString:[NSString stringWithFormat:@"app信息-------------\n%@", [UCP_PingManager getAppInfo]]];
    [self appInfoString:[NSString stringWithFormat:@"运营商信息-------------\n%@", [UCP_PingManager getNetWorkProviderInfo]]];
    [self appInfoString:@"ping info-------------"];
    
    
    self.isReachability = YES;
    UCP_Ping *ping = [[UCP_Ping alloc] initWithHostName:self.hostName];
    ping.delegate = self;
    ping.addressStyle = UCP_PingAddressStyleICMPv4;
//    ping.addressStyle = UCP_PingAddressStyleICMPv6;
    self.ping = ping;
    
    [self.ping start];
}
 


-(void)emptyPing{
    if (self.ping) {
        [self.ping stop];
        self.ping = nil;
    }
    self.dicM = nil;
    self.stringM = nil;
    [self emptyTimer];
}

-(void)stopPing{
    
    
    [self appInfoString:@"---------stop ping-------------"];
//    [self appInfoString:[NSString stringWithFormat:@"\n receive ping response index: %d timeOut", [indexArr[i] intValue]]];
    
    if (self.dicM.count > 0) {
       NSArray *indexArr = [[self.dicM allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
            double v1 = [obj1 doubleValue];
            double v2 = [obj2 doubleValue];
            
            if (v1 > v2) {
                return NSOrderedDescending;
            }
            else if (v1 < v2) {
                return NSOrderedAscending;
            }
            
            return NSOrderedSame;
        }];
        for (NSInteger i = 0; i < indexArr.count; i++) {
            [self appInfoString:[NSString stringWithFormat:@"\n receive ping response index: %d timeOut", [indexArr[i] intValue]]];
        }
    }
    
    
    
    if (self.completeCallback) {
        self.completeCallback(self.isReachability, self.stringM);
        self.completeCallback = nil;
    }
    [self emptyPing];
}

 


#pragma mark- UCP_PingDelegate
 
/// 当Simple ping 成功启动就会回调这个方法, 你需要在收到后 调用sendPingWithData 发送数据包
- (void)ping:(UCP_Ping *)pinger didStartWithAddress:(NSData *)address{
    NSString *host = nil;
    uint16_t port = 0;
    [UCP_PingManager getHost:&host port:&port family:NULL fromAddress:address];
    [self appInfoString:[NSString stringWithFormat:@"start ping success hostName: %@, ip: %@, port: %d",pinger.hostName, host, port]];
    
    [pinger sendPingWithData:nil];
}

/// 当Simple ping 启动失败就会回调这个方法, 后面没法ping 了
- (void)ping:(UCP_Ping *)pinger didFailWithError:(NSError *)error{
    self.isReachability = NO;
    [self appInfoString:[NSString stringWithFormat:@"start ping fail hostName: %@ \n err:%@",pinger.hostName, error.localizedDescription]];
    [self stopPing];
}





/// 当Simple ping 成功发出一个数据包就会调用这个方法
- (void)ping:(UCP_Ping *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber{
    
    CFAbsoluteTime startTime =CFAbsoluteTimeGetCurrent();
    self.dicM[@(sequenceNumber)] = @(startTime);
    [self appInfoString:[NSString stringWithFormat:@"send ping data success index: %d", sequenceNumber]];
}

/// Simple ping 接收到一个与发出数据包匹配(匹配主要基于 ICMP标识符)的响应, 就会回调此方法
/// packet 是 ICMPHeader 数据
- (void)ping:(UCP_Ping *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber{
    
    NSNumber *key = @(sequenceNumber);
    CFAbsoluteTime startTime = [self.dicM[key] doubleValue];
    CFAbsoluteTime endTime =CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime timeLen = endTime - startTime;
    [self.dicM removeObjectForKey:key];
    
    [self appInfoString:[NSString stringWithFormat:@"receive ping response index: %d, timeLength: %fs", sequenceNumber,timeLen]];
    if(sequenceNumber < self.pingCount-1){
        [pinger sendPingWithData:nil];
    }
    else{
        [self stopPing];
    }
}


/// 当Simple ping发送数据包失败 会回调这个方法
- (void)ping:(UCP_Ping *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error{
    self.isReachability = NO;
    [self appInfoString:[NSString stringWithFormat:@"send ping data fail  index: %d", sequenceNumber]];
    NSNumber *key = @(sequenceNumber);
    [self.dicM removeObjectForKey:key];
}


/// 当Simple ping 收到不匹配的data 时回调此方法
- (void)ping:(UCP_Ping *)pinger didReceiveUnexpectedPacket:(NSData *)packet{
    self.isReachability = NO;
    [self appInfoString:[NSString stringWithFormat:@"receive ping UnexpectedPacket: %@", [UCP_PingManager infoOfICMPHeader:packet]]];
}



#pragma mark-ICMPHeader 解析
+(NSDictionary *)infoOfICMPHeader:(NSData *)data{
    NSDictionary *info = @{};
    struct ICMPHeader header;
    NSInteger headerLen = sizeof(header);
    if (data.length >= headerLen) {
       [data getBytes:&header length:sizeof(header)];
        info = @{
            @"type": @(header.type),
            @"code": @(header.code),
            @"checksum": @(header.checksum),
            @"identifier": @(header.identifier),
            @"sequenceNumber": @(header.sequenceNumber)
        };
    }
    return info;
}


#pragma mark- 获取时间
+(NSString *)getCurrentDateTime{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [NSDate date];
    NSString *time = [formatter stringFromDate:date];
    return time;
}

#pragma mark- 获取网络运营商信息
+(NSString *)getNetWorkProviderInfo{
    NSMutableString *strM = [NSMutableString string];
    
    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netInfo subscriberCellularProvider];
    if (carrier != nil) {
        // 载波名称, eg: 中国移动
        if ([carrier carrierName].length > 0) {
            [strM appendFormat:@"carrierName: %@",[carrier carrierName]];
               
        }
        // 国家编码: eg: cn
        if ([carrier isoCountryCode].length > 0) {
            [strM appendString:@"\n"];
            [strM appendFormat:@"isoCountryCode: %@",[carrier isoCountryCode]];
        }
        // 移动国家代码: eg: 460
        if ([carrier mobileCountryCode].length > 0) {
            [strM appendString:@"\n"];
            [strM appendFormat:@"mobileCountryCode: %@",[carrier mobileCountryCode]];
        }
        // 移动网络代码: eg: 02
        if([carrier mobileNetworkCode].length > 0){
            [strM appendString:@"\n"];
            [strM appendFormat:@"mobileNetworkCode: %@",[carrier mobileNetworkCode]];
        }
    }
    return strM;
}

#pragma mark- 获取app 信息
+(NSString *)getAppInfo{
    NSDictionary *dicBundle = [[NSBundle mainBundle] infoDictionary];
    
    UIDevice *device = [UIDevice currentDevice];
    NSMutableString *strM = [NSMutableString string];
    NSString *app_Name = [dicBundle objectForKey:@"CFBundleName"]; // 1. appName cake
    NSString *app_displaNameName = [dicBundle objectForKey:@"CFBundleDisplayName"]; // 1. appName cake
    NSString *app_Version = [dicBundle objectForKey:@"CFBundleShortVersionString"]; // 2. app 版本1.0.0
    NSString *system_Name = [device systemName]; // 3. 操作系统名字
    NSString *system_Version = [device systemVersion]; // 4. 操作系统版本
    
    
    if (app_Name.length > 0) {
        [strM appendFormat:@"appName: %@",app_Name];
    }
    
    if(app_displaNameName.length > 0){
        if (app_Name.length > 0) {
            [strM appendString:@"\n"];
        }
        [strM appendFormat:@"appDisplaNameName: %@",app_displaNameName];
    }
    if (app_Version.length > 0) {
        [strM appendString:@"\n"];
        [strM appendFormat:@"appVersion: %@",app_Version];
    }
    if (system_Name.length > 0) {
        [strM appendString:@"\n"];
        [strM appendFormat:@"systemName: %@",system_Name];
    }
    if (system_Version.length > 0) {
        [strM appendString:@"\n"];
        [strM appendFormat:@"systemVersion: %@",system_Version];
    }
    return strM;
}



#pragma mark- DNS 服务器信息
/// 获取本机DNS服务器
+ (NSMutableArray<NSString *> *)getCurrentDNSServers{
//    res_state resState = malloc(sizeof(struct __res_state));
//    int ret = res_ninit(resState);
    
    NSMutableArray *dnsServerArrM = @[].mutableCopy;
//    if (ret == 0){
//        for ( int i = 0; i < resState->nscount; i++ ){
//            NSString *dnsServerAddress  = [NSString stringWithUTF8String :  inet_ntoa(resState->nsaddr_list[i].sin_addr)];
//            [dnsServerArrM addObject:dnsServerAddress];
//        }
//    }
//    res_nclose(resState);
    
    return dnsServerArrM;
}

#pragma mark- ip 地址解析
+ (BOOL)getHost:(NSString **)hostPtr
           port:(uint16_t *)portPtr
         family:(sa_family_t *)afPtr
    fromAddress:(NSData *)address{
    if ([address length] >= sizeof(struct sockaddr)){
        
        
        const struct sockaddr *sockaddrX = [address bytes];
        
        if (sockaddrX->sa_family == AF_INET){
            
            if ([address length] >= sizeof(struct sockaddr_in)){
                struct sockaddr_in sockaddr4;
                memcpy(&sockaddr4, sockaddrX, sizeof(sockaddr4));
                
                if (hostPtr) *hostPtr = [self hostFromSockaddr4:&sockaddr4];
                if (portPtr) *portPtr = [self portFromSockaddr4:&sockaddr4];
                if (afPtr)   *afPtr   = AF_INET;
                
                return YES;
            }
        }
        else if (sockaddrX->sa_family == AF_INET6){
            
            if ([address length] >= sizeof(struct sockaddr_in6)){
                struct sockaddr_in6 sockaddr6;
                memcpy(&sockaddr6, sockaddrX, sizeof(sockaddr6));
                
                if (hostPtr) *hostPtr = [self hostFromSockaddr6:&sockaddr6];
                if (portPtr) *portPtr = [self portFromSockaddr6:&sockaddr6];
                if (afPtr)   *afPtr   = AF_INET6;
                
                return YES;
            }
        }
    }
    
    return NO;
}

+ (NSString *)hostFromSockaddr4:(const struct sockaddr_in *)pSockaddr4{
    char addrBuf[INET_ADDRSTRLEN];
    
    if (inet_ntop(AF_INET, &pSockaddr4->sin_addr, addrBuf, (socklen_t)sizeof(addrBuf)) == NULL){
        addrBuf[0] = '\0';
    }
    
    return [NSString stringWithCString:addrBuf encoding:NSASCIIStringEncoding];
}

+ (NSString *)hostFromSockaddr6:(const struct sockaddr_in6 *)pSockaddr6{
    char addrBuf[INET6_ADDRSTRLEN];
    
    if (inet_ntop(AF_INET6, &pSockaddr6->sin6_addr, addrBuf, (socklen_t)sizeof(addrBuf)) == NULL){
        addrBuf[0] = '\0';
    }
    
    return [NSString stringWithCString:addrBuf encoding:NSASCIIStringEncoding];
}

+ (uint16_t)portFromSockaddr4:(const struct sockaddr_in *)pSockaddr4{
    return ntohs(pSockaddr4->sin_port);
}

+ (uint16_t)portFromSockaddr6:(const struct sockaddr_in6 *)pSockaddr6{
    return ntohs(pSockaddr6->sin6_port);
}

@end
