//
//  EventTracingLogRealtimeViewer.h
//  AFNetworking
//
//  Created by dl on 2019/8/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingLogRealtimeViewerOptions : NSObject <NSCopying>
@property(nonatomic, assign) BOOL onlyConnectOnWifi;    // default: YES
@property(nonatomic, assign) BOOL autoConnectOnSetup;   // default: YES
@end

@interface EventTracingLogRealtimeViewer : NSObject

@property(nonatomic, assign, readonly) BOOL enable;
@property(nonatomic, strong, readonly) EventTracingLogRealtimeViewerOptions *options;

+ (instancetype)sharedInstance;

- (void)setupWithOptions:(EventTracingLogRealtimeViewerOptions *)options;

- (void)connectWithPath:(NSString *)connectPath connectToken:(NSString *)connectToken;
- (void)disconnect;

- (void)sendLogWithAction:(NSString *)action json:(NSDictionary *)logJson;

@end

NS_ASSUME_NONNULL_END
