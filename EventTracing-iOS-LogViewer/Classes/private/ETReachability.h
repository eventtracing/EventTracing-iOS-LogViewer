/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Basic demonstration of how to use the SystemConfiguration Reachablity APIs.
 */
 
#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>
 
typedef enum : NSInteger {
    ETNotReachable = 0,
    ETReachableViaWiFi,
    ETReachableViaWWAN
} ETNetworkStatus;
 
#pragma mark IPv6 Support
//Reachability fully support IPv6.  For full details, see ReadMe.md.
 
 
extern NSString *kETReachabilityChangedNotification;
 
/// MARK: 在 apple 的基础上，修改了名字，以防跟业务侧符号冲突
/// MARK: 参见 apple 文档: https://developer.apple.com/library/archive/samplecode/Reachability/Introduction/Intro.html#//apple_ref/doc/uid/DTS40007324-Intro-DontLinkElementID_2
@interface ETReachability : NSObject
 
/*!
 * Use to check the reachability of a given host name.
 */
+ (instancetype)reachabilityWithHostName:(NSString *)hostName;
 
/*!
 * Use to check the reachability of a given IP address.
 */
+ (instancetype)reachabilityWithAddress:(const struct sockaddr *)hostAddress;
 
/*!
 * Checks whether the default route is available. Should be used by applications that do not connect to a particular host.
 */
+ (instancetype)reachabilityForInternetConnection;
 
 
#pragma mark reachabilityForLocalWiFi
//reachabilityForLocalWiFi has been removed from the sample.  See ReadMe.md for more information.
//+ (instancetype)reachabilityForLocalWiFi;
 
/*!
 * Start listening for reachability notifications on the current run loop.
 */
- (BOOL)startNotifier;
- (void)stopNotifier;
 
- (ETNetworkStatus)currentReachabilityStatus;
 
/*!
 * WWAN may be available, but not active until a connection has been established. WiFi may require a connection for VPN on Demand.
 */
- (BOOL)connectionRequired;
 
@end
