//
//  EventTracingLogRealtimeViewer.m
//  AFNetworking
//
//  Created by dl on 2019/8/2.
//

#import "EventTracingLogRealtimeViewer.h"
#import "EventTracingLogRealtimeViewerWebSocketHandler.h"

static NSString *kEventTracingLogRealtimeViewerLastUsedTime = @"kEventTracingLogRealtimeViewerLastUsedTime";

@interface EventTracingLogRealtimeViewer ()
@property (nonatomic, strong) EventTracingLogRealtimeViewerWebSocketHandler *webSocketHandler;
@end

@implementation EventTracingLogRealtimeViewerOptions

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    EventTracingLogRealtimeViewerOptions *options = [[EventTracingLogRealtimeViewerOptions alloc] init];
    options.onlyConnectOnWifi = self.onlyConnectOnWifi;
    options.autoConnectOnSetup = self.autoConnectOnSetup;
    
    return options;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _onlyConnectOnWifi = YES;
    }
    return self;
}

@end

@implementation EventTracingLogRealtimeViewer

+ (instancetype) sharedInstance {
    static EventTracingLogRealtimeViewer *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[EventTracingLogRealtimeViewer alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _webSocketHandler = [[EventTracingLogRealtimeViewerWebSocketHandler alloc] init];
    }
    return self;
}

- (void)setupWithOptions:(EventTracingLogRealtimeViewerOptions *)options {
    _options = options.copy;
    
    if (options.autoConnectOnSetup) {
        [self tryConnectAtStartupIfNeeded];
    }
}

- (void)tryConnectAtStartupIfNeeded {
    if (!self.enable || ![self lastUsedNotLongBefore]) {
        return;
    }
    
    [self.webSocketHandler connect];
}

- (void)connectWithPath:(NSString *)connectPath connectToken:(NSString *)connectToken {
    [self.webSocketHandler connectWithConnectPath:connectPath connectToken:connectToken];
    [[NSUserDefaults standardUserDefaults] setObject:@([NSDate date].timeIntervalSince1970) forKey:kEventTracingLogRealtimeViewerLastUsedTime];
}

- (void)disconnect {
    [self.webSocketHandler disConnect];
    [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:kEventTracingLogRealtimeViewerLastUsedTime];
}

- (void) sendLogWithAction:(NSString *)action json:(NSDictionary *)logJson {
    if (self.webSocketHandler.enable) {
        [[NSUserDefaults standardUserDefaults] setObject:@([NSDate date].timeIntervalSince1970) forKey:kEventTracingLogRealtimeViewerLastUsedTime];
    }
    
    if (!action
        || ![action isKindOfClass:[NSString class]]
        || action.length == 0
        || ![logJson isKindOfClass:[NSDictionary class]]) {
        return ;
    }
    
    static NSInteger logIndex = 1;
    NSMutableDictionary *log = @{
        @"action": action,
        @"index": @(logIndex).stringValue,
        @"logTime": @([NSDate date].timeIntervalSince1970),
        @"content": logJson,
        @"logtype": @"ua",
        @"os": @"iPhone",
        @"et": @YES
    }.mutableCopy;
    
    [self.webSocketHandler sendClientLogJson:@{@"action": @"log", @"content": log.copy}];
    logIndex ++;
}

#pragma mark - getters
- (NSString *)connectPath {
    return self.webSocketHandler.connectPath;
}

- (NSString *)connectToken {
    return self.webSocketHandler.connectToken;
}

- (BOOL) lastUsedNotLongBefore {
    // 上次使用距离现在时间少于2分钟，则启动就开启，否则默认不开启
    return [NSDate date].timeIntervalSince1970 - [[[NSUserDefaults standardUserDefaults] valueForKey:kEventTracingLogRealtimeViewerLastUsedTime] doubleValue] < 2 * 60;
}

- (BOOL)enable {
    return self.webSocketHandler.enable;
}

@end
