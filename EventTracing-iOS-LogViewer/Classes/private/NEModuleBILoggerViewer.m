////
////  NEModuleLoggerViewer.m
////  AFNetworking
////
////  Created by dl on 2019/7/18.
////
//
//#import <Foundation/Foundation.h>
//#import "EventTracingLogRealtimeViewerWebSocketHandler.h"
//#import <JRSwizzle/JRSwizzle.h>
//#import <SBJson/SBJson.h>
//#import <NEModuleHub/NEModuleHub.h>
//#import <NEURLRouter/NEURLRouter.h>
//#import "EventTracingLogRealtimeViewer+Private.h"
//#import <NEIocProtocols/NMNavigatorProtocol.h>
//
//@interface NEModuleLoggerViewer : NSObject <NEModuleProtocol>
//@end
//
//@implementation NEModuleLoggerViewer
//
//NEModuleRegister(NEModuleLoggerViewer)
//
//- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
//    [NEIoc_Navigator registTarget:@"devtool/bilog_viewer/connect" withNavigatorExecuteBlock:^(id<NMNavigatorParamProtocol>  _Nonnull param, NMNavigatorCallbackBlock  _Nonnull callback) {
//        NSString *ws = param.userInfo[@"ws"];
//
//        [self _doConnectToWs:ws];
//    }];
//
//    [[EventTracingLogRealtimeViewer sharedInstance] tryConnectAtStartupIfNeeded];
//
//    return YES;
//}
//
//- (void)_doConnectToWs:(NSString *)ws {
//    if ([ws isKindOfClass:[NSString class]] && ws.length) {
//        NSString *connectToken = [ws lastPathComponent];
//        NSString *connectPath = [ws stringByDeletingLastPathComponent];
//
//        [[EventTracingLogRealtimeViewer sharedInstance] connectWithPath:connectPath connectToken:connectToken];
//    } else {
//        [[EventTracingLogRealtimeViewer sharedInstance] showToast:@"[埋点校验] 二维码错误，请联系平台开发"];
//    }
//}
//
//@end
