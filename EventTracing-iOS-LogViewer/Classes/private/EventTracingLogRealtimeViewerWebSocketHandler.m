//
//  EventTracingLogRealtimeViewerWebSocketHandler.m
//  AFNetworking
//
//  Created by dl on 2019/7/26.
//

#import "EventTracingLogRealtimeViewerWebSocketHandler.h"
#import <SocketRocket/SRWebSocket.h>
#import <sys/utsname.h>
#import "ETReachability.h"
#import "EventTracingLogRealtimeViewer.h"

static NSString *kEventTracingLogRealtimeViewerWebSocketHandlerConnectPath = @"kEventTracingLogRealtimeViewerWebSocketHandlerConnectPath";
static NSString *kEventTracingLogRealtimeViewerWebSocketHandlerConnectToken = @"kEventTracingLogRealtimeViewerWebSocketHandlerConnectToken";
static NSString *kEventTracingLogRealtimeViewerWebSocketHandlerEnable = @"kEventTracingLogRealtimeViewerWebSocketHandlerEnable";

@interface EventTracingLogRealtimeViewerWebSocketHandler() <SRWebSocketDelegate>
@property (nonatomic, copy, readwrite) NSString *connectPath;
@property (nonatomic, copy, readwrite) NSString *connectToken;

@property (nonatomic, copy) NSString *connectUrl;
@property (nonatomic, strong) SRWebSocket *webSocket;

@property (nonatomic, strong) NSMutableArray *stockedLogs;

@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSTimer *heartBeatTimer;

@property (nonatomic, assign) NSInteger connectRetryCount;

@property (nonatomic, strong) ETReachability *reachability;

@end

@implementation EventTracingLogRealtimeViewerWebSocketHandler

- (instancetype)init {
    self = [super init];
    if (self) {
        self.stockedLogs = [@[] mutableCopy];
        
        self.queue = [[NSOperationQueue alloc] init];
        [self.queue setMaxConcurrentOperationCount:1];
        self.queue.name = @"com.eventtracing.debug.log_viewer_websocket.q";
        
        _reachability = [ETReachability reachabilityForInternetConnection];
        [_reachability startNotifier];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kETReachabilityChangedNotification object:nil];
    }
    return self;
}

- (void) setupConnectToken:(NSString *)connectToken {
    [[NSUserDefaults standardUserDefaults] setObject:connectToken forKey:kEventTracingLogRealtimeViewerWebSocketHandlerConnectToken];
}

- (void) connect {
    [self connectWithConnectPath:self.connectPath connectToken:self.connectToken];
}

- (void) connectWithConnectPath:(NSString *)connectPath connectToken:(NSString *)connectToken {
    if (!connectToken.length || !connectPath.length) {
        return;
    }
    
    if (self.webSocket.readyState == SR_OPEN) {
        if ([connectPath isEqualToString:self.connectPath] && [connectToken isEqualToString:self.connectToken]) {
            return;
        }
        
        [self _doDisConnect];
    }
    
    self.connectPath = connectPath;
    self.connectToken = connectToken;
    
    self.connectRetryCount = 0;
    [self _doConnect];
}

- (void) disConnect {
    [self switchEnable:NO];
    [self _doDisConnect];
}

- (void) _doConnect {
    self.connectRetryCount ++;
    if (self.connectRetryCount > 3) {
        [self switchEnable:NO];
        return;
    }
    
    [self switchEnable:YES];
    NSURL *connectPathURL = [NSURL URLWithString:self.connectPath];
    NSMutableString *connectPath = [[NSString stringWithFormat:@"%@%@", [connectPathURL host] ?: @"", connectPathURL.path ?: @""] mutableCopy];
    
    // ws://[host]/[connectPath]/[connectToken]/[clientid]
    NSMutableString *wsUrl = [@"ws:" mutableCopy];
    if ([connectPath hasPrefix:@"//"]) {
    } else if ([connectPath hasPrefix:@"/"]) {
        [wsUrl appendString:@"/"];
    } else {
        [wsUrl appendString:@"//"];
    }
    [wsUrl appendString:connectPath];
    [wsUrl appendString:@"/"];
    [wsUrl appendString:self.connectToken];
    [wsUrl appendString:@"/"];
    
    static NSString *clientId = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *kEventTracingLogRealtimeViewerClientId = @"kEventTracingLogRealtimeViewerClientId";
        clientId = [[NSUserDefaults standardUserDefaults] stringForKey:kEventTracingLogRealtimeViewerClientId];
        if (clientId.length == 0) {
            clientId = [NSUUID UUID].UUIDString;
            [[NSUserDefaults standardUserDefaults] setValue:clientId forKey:kEventTracingLogRealtimeViewerClientId];
        }
    });
    [wsUrl appendString:clientId];
    
    [self _doDisConnect];
    self.webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:wsUrl]];
    self.webSocket.delegate = self;
    [self.webSocket setDelegateOperationQueue:self.queue];
    [self.webSocket open];
}

- (void) _doDisConnect {
    self.webSocket.delegate = nil;
    [self.webSocket close];
    [self.webSocket setDelegateOperationQueue:nil];
    self.webSocket = nil;
}

- (void) sendClientLogJson:(NSDictionary *)json {
    NSError *error;
    NSData *logJsonData = [NSJSONSerialization dataWithJSONObject:json
                                                          options:0
                                                            error:&error];
    NSString *logJsonString = [[NSString alloc] initWithData:logJsonData encoding:NSUTF8StringEncoding];
    
    [self.queue addOperationWithBlock:^{
        if (self.webSocket.readyState != SR_OPEN) {
            [self.stockedLogs addObject:logJsonString];
            
            if (self.stockedLogs.count > 300) {
                [self.stockedLogs removeObjectsInRange:NSMakeRange(0, self.stockedLogs.count - 300)];
            }
        } else {
            [self.webSocket sendString:logJsonString error:nil];
        }
    }];
}

#pragma mark - heart beat
- (void)initHeartBeat {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self destoryHeartBeat];
        
        __weak typeof(self) __weak_self = self;
        self.heartBeatTimer = [NSTimer scheduledTimerWithTimeInterval:1000 repeats:YES block:^(NSTimer * _Nonnull timer) {
            __strong typeof(__weak_self) __strong_self = __weak_self;
            [__strong_self.webSocket sendPing:nil error:nil];
        }];
        [[NSRunLoop currentRunLoop] addTimer:self.heartBeatTimer forMode:NSRunLoopCommonModes];
    });
}

- (void) destoryHeartBeat {
    if (self.heartBeatTimer) {
        [self.heartBeatTimer invalidate];
        self.heartBeatTimer = nil;
    }
}

#pragma mark - reconnect
- (void) reconnectIfNeeded {
    if (!self.enable || self.reachability.currentReachabilityStatus != ETNotReachable) {
        return;
    }
    
    if ([EventTracingLogRealtimeViewer sharedInstance].options.onlyConnectOnWifi && self.reachability.currentReachabilityStatus != ETReachableViaWiFi) {
        return;
    }
    
    NSLog(@"[EventTracing Log Realtime][埋点校验] 试重新连接中...");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"et.log.realtime" object:@{@"msg":@"[埋点校验] 尝试重连", @"action":@"alert"}];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.webSocket.readyState != SR_OPEN && self.webSocket.readyState != SR_CONNECTING && self.enable) {
            
            [self _doConnect];
        }
    });
}

#pragma mark - others
- (void) sendClientBasicInfo {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appname = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    NSString *appver = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *buildver = [infoDictionary objectForKey:@"CFBundleVersion"];
    NSString *bundleId = [infoDictionary objectForKey:@"CFBundleIdentifier"];
    NSString *deviceName = [[UIDevice currentDevice] systemName];
    NSString *sysver = [[UIDevice currentDevice] systemVersion];
    
    // send client basic info
    NSMutableDictionary *clientInfo = [@{} mutableCopy];
    [clientInfo setObject:@"iOS" forKey:@"platform"];
    [clientInfo setObject:sysver forKey:@"sysVer"];
    [clientInfo setObject:NSStringFromCGSize([UIScreen mainScreen].bounds.size) forKey:@"screenSize"];
    [clientInfo setObject:@([UIScreen mainScreen].scale) forKey:@"screenScale"];
    [clientInfo setObject:appver forKey:@"appVer"];
    [clientInfo setObject:buildver forKey:@"buildVer"];
    [clientInfo setObject:bundleId forKey:@"appBundleId"];
    [clientInfo setObject:appname forKey:@"appName"];
    [clientInfo setObject:deviceName forKey:@"deviceName"];
    [clientInfo setObject:@"iOS" forKey:@"channel"];

    [self.queue addOperationWithBlock:^{
        NSDictionary *json = @{@"action": @"basicInfo", @"content": clientInfo};
        NSError *error;
        NSData *logJsonData = [NSJSONSerialization dataWithJSONObject:json
                                                              options:0
                                                                error:&error];
        NSString *logJsonString = [[NSString alloc] initWithData:logJsonData encoding:NSUTF8StringEncoding];
        [self.webSocket sendString:logJsonString error:nil];
    }];
}

- (void) reachabilityChanged:(NSNotification *)noti {
    [self reconnectIfNeeded];
}

#pragma mark - SRWebSocketDelegate
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    self.connectRetryCount = 0;
    [self sendClientBasicInfo];
    [self initHeartBeat];
    
    // 解决线程同步问题导致的数据越界
    [self.queue addOperationWithBlock:^{
        NSArray *stockedLogs = self.stockedLogs.copy;
        [self.stockedLogs removeAllObjects];
        
        [stockedLogs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.webSocket sendString:obj error:nil];
        }];
    }];
    
    NSLog(@"[EventTracing Log Realtime][埋点校验] ✅ 连接成功");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"et.log.realtime" object:@{@"msg":@"[埋点校验] ✅ 连接成功", @"action":@"alert"}];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"[EventTracing Log Realtime][埋点校验] Failed With Error: %@", error);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"et.log.realtime" object:@{@"msg":@"[埋点校验] ❌ 连接失败", @"action":@"alert"}];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    [self destoryHeartBeat];
    
    /// MARK: https://libwebsockets.org/lws-api-doc-main/html/group__wsclose.html
    /// MARK: LWS_CLOSE_STATUS_NORMAL = 1000
    /// MARK: LWS_CLOSE_STATUS_GOINGAWAY = 1001
    if (code == 1000 || code == 1001) {
        [self disConnect];
    } else {
        [self reconnectIfNeeded];
    }
    NSLog(@"[EventTracing Log Realtime][埋点校验] ✅ ❌ 连接断开, code: %@, reason: %@", @(code), reason);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"et.log.realtime" object:@{@"msg":@"[埋点校验] ✅ ❌ 连接断开", @"action":@"alert"}];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload { }

- (BOOL)webSocketShouldConvertTextFrameToString:(SRWebSocket *)webSocket {
    return YES;
}

#pragma mark - setters & getters
- (void)setConnectPath:(NSString *)connectPath {
    [[NSUserDefaults standardUserDefaults] setObject:connectPath forKey:kEventTracingLogRealtimeViewerWebSocketHandlerConnectPath];
}

- (NSString *)connectPath {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kEventTracingLogRealtimeViewerWebSocketHandlerConnectPath] ?: @"monking.qa.igame.163.com/ws/client";
}

- (void)setConnectToken:(NSString *)connectToken {
    [[NSUserDefaults standardUserDefaults] setObject:connectToken forKey:kEventTracingLogRealtimeViewerWebSocketHandlerConnectToken];
}

- (NSString *)connectToken {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kEventTracingLogRealtimeViewerWebSocketHandlerConnectToken];
}

- (BOOL)enable {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEventTracingLogRealtimeViewerWebSocketHandlerEnable];
}

- (void)switchEnable:(BOOL)enable {
    [[NSUserDefaults standardUserDefaults] setBool:enable forKey:kEventTracingLogRealtimeViewerWebSocketHandlerEnable];
}

@end
