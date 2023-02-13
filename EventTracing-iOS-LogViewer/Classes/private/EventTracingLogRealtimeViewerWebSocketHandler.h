//
//  EventTracingLogRealtimeViewerWebSocketHandler.h
//  AFNetworking
//
//  Created by dl on 2019/7/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingLogRealtimeViewerWebSocketHandler : NSObject

@property (nonatomic, copy, readonly) NSString *connectPath;
@property (nonatomic, copy, readonly) NSString *connectToken;
@property (nonatomic, assign, readonly) BOOL enable;

- (void) setupConnectToken:(NSString *)connectToken;

- (void) connect;
- (void) connectWithConnectPath:(NSString *)connectPath connectToken:(NSString *)connectToken;
- (void) disConnect;
- (void) sendClientLogJson:(NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END
