//
//  AppDelegate.m
//  RTMPiOSDemo
//
//  Created by kuenzhang on 16/3/3.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "AppDelegate.h"

#import "TXConfigManager.h"
#import "AppLocalized.h"

#ifdef ENABLE_TRTC
#ifdef ENABLE_PLAY
#import "TRTCCloud.h"
#import "TXLiveBase.h"  //TRTC
#else
#import "TRTCCloud.h"  //TRTC_Smart
#endif
#else
#ifdef LIVE
#import "V2TXLivePremier.h"
#else
#import "TXLiveBase.h"
#endif
#endif

#ifndef UGC_SMART
#import "AppLogMgr.h"
#endif

#import <UserNotifications/UserNotifications.h>
#import <objc/message.h>

#import "AFNetworkReachabilityManager.h"
#import "MainViewController.h"

#ifdef ENABLE_UGC
#import "TXUGCBase.h"
#endif

#if !defined(UGC) && !defined(PLAYER)
#import <ImSDK/ImSDK.h>
#import "LoginViewController.h"
#import "LoginMockViewController.h"
#endif

#if defined(ENTERPRISE) || defined(PROFESSIONAL) || defined(SMART) || defined(TRTC)
#import "Replaykit2Define.h"
#endif

#if defined(PLAYER) || defined(PROFESSIONAL) || defined(ENTERPRISE)
#import "TXLaunchMoviePlayProtocol.h"
#endif

#if defined(ENTERPRISE)
#import "DevOpsCheckManager.h"
#import "ProfileManager.h"
#endif

NSString *helpUrlDb[] = {
    [Help_MLVBLiveRoom] = @"https://cloud.tencent.com/document/product/454/14606",
    [Help_录屏直播]     = @"https://cloud.tencent.com/document/product/454/7883",
    [Help_超级播放器]   = @"https://cloud.tencent.com/document/product/454/18871",
    [Help_视频录制]     = @"https://cloud.tencent.com/document/product/584/9367",
    [Help_特效编辑]     = @"https://cloud.tencent.com/document/product/584/9375",
    [Help_视频拼接]     = @"https://cloud.tencent.com/document/product/584/9370",
    [Help_图片转场] =
        @"https://cloud.tencent.com/document/product/584/"
        @"9375#14.-.E5.9B.BE.E7.89.87.E7.BC.96.E8.BE.91",
    [Help_视频上传]   = @"https://cloud.tencent.com/document/product/584/15534",
    [Help_双人音视频] = @"https://cloud.tencent.com/document/product/454/14617",
    [Help_多人音视频] = @"https://cloud.tencent.com/document/product/454/14617",
    [Help_rtmp推流]   = @"https://cloud.tencent.com/document/product/454/7879",
    [Help_直播播放器] = @"https://cloud.tencent.com/document/product/454/7880",
    [Help_点播播放器] = @"https://cloud.tencent.com/document/product/454/12147",
    [Help_webrtc]     = @"https://cloud.tencent.com/document/product/454/16914",
    [Help_TRTC]       = @"https://cloud.tencent.com/document/product/647/32221",
};

#if !defined(PLAYER) && !defined(UGC)
@interface AppDelegate () <UNUserNotificationCenterDelegate, V2TIMAPNSListener>
#else
@interface AppDelegate () <UNUserNotificationCenterDelegate>
#endif

@property(nonatomic, strong) MainViewController *mainViewController;
@property(nonatomic, strong) NSDictionary *      launchInfo;  //从其他应用打开
@property(nonatomic, assign) BOOL                didLaunched;
@end

@implementation AppDelegate

- (MainViewController *)mainViewController {
    if (!_mainViewController) {
        _mainViewController = [[MainViewController alloc] init];
    }
    return _mainViewController;
}

- (void)clickHelp:(UIButton *)sender {
    NSURL *        helpUrl = [NSURL URLWithString:helpUrlDb[sender.tag]];
    UIApplication *myApp   = [UIApplication sharedApplication];
    if ([myApp canOpenURL:helpUrl]) {
        [myApp openURL:helpUrl];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.didLaunched = YES;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"remove_cache_preference"]) {
        NSFileManager *fm           = [NSFileManager defaultManager];
        NSString *     documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        [fm removeItemAtPath:[documentPath stringByAppendingPathComponent:@"TXUgcSDK.licence"] error:nil];
        [fm removeItemAtPath:[documentPath stringByAppendingPathComponent:@"TXLiveSDK.licence"] error:nil];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"remove_cache_preference"];
    }
    [self registNotificaiton];

    
    [[TXConfigManager shareInstance] loadConfig];
    [[TXConfigManager shareInstance] setLicence];
    [[TXConfigManager shareInstance] setLogConfig];
    [[TXConfigManager shareInstance] initDebug];
    [[TXConfigManager shareInstance] setupBugly];
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(-1000, 0) forBarMetrics:UIBarMetricsDefault];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [[UINavigationBar appearance] setBarTintColor:UIColor.blackColor];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18], NSForegroundColorAttributeName : [UIColor whiteColor]}];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"transparent.png"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[UIImage new]];
#ifdef NOT_LOGIN
    [self showPortalConroller];
#else
    [self showLoginController];
#endif
    
    [self.window makeKeyAndVisible];
#ifndef ENABLE_TRTC
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
#endif
#if !defined(PLAYER) && !defined(UGC)
    // 自定义 APP 未读数
    [[V2TIMManager sharedInstance] setAPNSListener:self];
#endif
    // For ReplayKit2. 使用 UNUserNotificationCenter 来管理通知
    if ([UIDevice currentDevice].systemVersion.floatValue >= 11.0) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        //监听回调事件
        center.delegate = self;

        // iOS 10 使用以下方法注册，才能得到授权
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge)
                              completionHandler:^(BOOL granted, NSError *_Nullable error){
                                  // Enable or disable features based on authorization.
                              }];
    }
    if (!self.didLaunched && [(NSString *)self.launchInfo[@"protocol"] isEqualToString:@"v4vodplay"]) {
        self.didLaunched = YES;
        [self playVideoFromLaunchInfo:self.launchInfo];
    }
    return YES;
}

#pragma mark - 从其他应用拉起
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    NSMutableDictionary *params = [self getParamsFromURL:url.query].mutableCopy;
    self.launchInfo             = params.copy;
    if (self.didLaunched) {
        [self playVideoFromLaunchInfo:self.launchInfo];
    }
    return YES;
}

- (NSDictionary *)getParamsFromURL:(NSString *)queryStr {
    NSArray *paramPairs = [queryStr componentsSeparatedByString:@"&"];
    if ([paramPairs count] == 0) {
        return @{};
    }
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:10];
    for (NSString *str in paramPairs) {
        NSArray *pairs = [str componentsSeparatedByString:@"="];
        if ([pairs count] == 2) {
            [params setValue:pairs[1] forKey:pairs[0]];
        }
    }
    return params.copy;
}

#pragma mark - 扫码拉起APP播放视频
- (void)playVideoFromLaunchInfo:(NSDictionary *)launchInfo {
#if defined(PLAYER) || defined(PROFESSIONAL) || defined(ENTERPRISE)
    __weak UINavigationController *rootVC = (UINavigationController *)self.window.rootViewController;
    if (launchInfo && [rootVC isKindOfClass:[UINavigationController class]]) {
        if ([self findClass:NSClassFromString(@"LoginViewController") InNav:rootVC]) {
            //登录流程，等待，这里不作处理，登录成功后showPortalConroller中主动调用这个函数
        } else if ([self findClass:NSClassFromString(@"MoviePlayerViewController") InNav:rootVC]) {
            ///已有播放器
            id<TXLaunchMoviePlayProtocol> vc       = (id<TXLaunchMoviePlayProtocol>)[self findVCWith:NSClassFromString(@"MoviePlayerViewController") InNav:rootVC];
            __weak __typeof(self)         weakSelf = self;
            [vc startPlayVideoFromLaunchInfo:self.launchInfo
                                    complete:^(BOOL succ) {
                                        weakSelf.launchInfo = nil;
                                    }];
        } else {
            id vc = [[NSClassFromString(@"MoviePlayerViewController") alloc] init];
            if (vc) {
                __weak __typeof(self) weakSelf = self;
                [(id<TXLaunchMoviePlayProtocol>)vc startPlayVideoFromLaunchInfo:self.launchInfo
                                                                       complete:^(BOOL succ) {
                                                                           weakSelf.launchInfo = nil;
                                                                           if (succ) {
                                                                               [rootVC pushViewController:vc animated:NO];
                                                                           }
                                                                       }];
            } else {
                NSLog(@"current version not support super player, so cannot play video");
            }
        }
    }
#endif
}

- (UIViewController *)findVCWith:(Class)aclass InNav:(UINavigationController *)nav {
    for (UIViewController *vc in nav.viewControllers) {
        if ([vc isKindOfClass:aclass]) {
            return vc;
        }
    }
    return nil;
}

- (BOOL)findClass:(Class)aclass InNav:(UINavigationController *)nav {
    UIViewController *vc = [self findVCWith:aclass InNav:nav];
    return vc != nil;
}

#pragma mark -

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
#if defined(ENTERPRISE) || defined(PROFESSIONAL) || defined(SMART)
    if (notification.request.content.userInfo.allKeys.count > 0) {
        if ([notification.request.content.userInfo[kReplayKit2UploadingKey] isEqualToString:kReplayKit2Stop]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kCocoaNotificationNameReplayKit2Stop object:nil];
        }
    }
#endif
    // 处理完成后条用 completionHandler ，用于指示在前台显示通知的形式
    completionHandler(UNNotificationPresentationOptionSound + UNNotificationPresentationOptionBadge + UNAuthorizationOptionAlert);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    if (response.notification.request.content.userInfo.allKeys.count > 0) {
        //        NSUserDefaults *defaults = [[NSUserDefaults alloc]
        //        initWithSuiteName:kReplayKit2AppGroupId]; if
        //        ([response.notification.request.content.userInfo[kReplayKit2UploadingKey]
        //        isEqualToString:kReplayKit2Uploading]) {
        //            [defaults setObject:kReplayKit2Uploading
        //            forKey:kReplayKit2UploadingKey]; [defaults synchronize];
        //        }
    }
    completionHandler();
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state.
    // This can occur for certain types of temporary interruptions (such as an
    // incoming phone call or SMS message) or when the user quits the application
    // and it begins the transition to the background state. Use this method to
    // pause ongoing tasks, disable timers, and throttle down OpenGL ES frame
    // rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate
    // timers, and store enough application state information to restore your
    // application to its current state in case it is terminated later. If your
    // application supports background execution, this method is called instead of
    // applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state;
    // here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the
    // application was inactive. If the application was previously in the
    // background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if
    // appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - 通知相关方法
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"error: %@", error);
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    self.deviceToken = deviceToken;
}

- (void)registNotificaiton {
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

#pragma mark - 登录跳转方法
- (void)showPortalConroller {
    UINavigationController *nav        = nil;
    nav                                = [[UINavigationController alloc] initWithRootViewController:self.mainViewController];
    self.window.rootViewController     = nav;
    [self playVideoFromLaunchInfo:self.launchInfo];
    
    // 检测是否需要更新
    [self checkAppUpdateVersion];
}

/// @brief 检测版本更新
/// @note  检查蓝盾版本更新 - 需在对应的config.plist文件配置needCheckDevOpsVersion 默认为NO 不触发
- (void)checkAppUpdateVersion {
#if defined(ENTERPRISE)
    if ([[TXConfigManager shareInstance] isRelease]) {
        // 检查商店版本更新
        NSString *appStoreID = @"1152295397";
        [self checkStoreVersion:appStoreID];
    } else if ([[TXConfigManager shareInstance] needCheckDevOpsVersion]) {
        // 工具包 - 开启检查蓝盾构建新版本
        NSString *userId = [[ProfileManager shared] curUserID];
        [DevOpsCheckManager checkUpdateWithUserId:userId];
    }
#endif
}

- (void)showLoginController {
#ifndef NOT_LOGIN
    LoginViewController *vc;
    if ([TXConfigManager shareInstance].isRelease) {
        vc = [[LoginViewController alloc] init];
    } else {
        vc = [[LoginMockViewController alloc] init];
    }
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:vc];
#endif
}

#pragma mark - 推送设置回调
- (uint32_t)onSetAPPUnreadCount {
    return 0;
}

#pragma mark - 检测商店版本
- (void)checkStoreVersion:(NSString *)appID {
    NSString *            url     = [NSString stringWithFormat:@"https://itunes.apple.com/cn/lookup?id=%@", appID];
    NSURLRequest *        request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLSession *        session = [NSURLSession sharedSession];
    __weak __typeof(self) wself   = self;
    NSURLSessionDataTask *task    = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
                                                NSError *err;
                                                if (!data || data.length == 0) {
                                                    NSLog(@"====== no store data ======");
                                                    return;
                                                }
                                                NSDictionary *remoteDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&err];
                                                if (err) {
                                                    NSLog(@"====== no store info ======");
                                                    return;
                                                }
                                                NSArray *array = [remoteDic objectForKey:@"results"];
                                                if (array.count < 1) {
                                                    return;
                                                }
                                                NSDictionary *appInfo         = [array firstObject];
                                                NSString *    appStoreVersion = [appInfo objectForKey:@"version"];
                                                NSLog(@"====== store version info: %@ ======", appStoreVersion);
                                                BOOL result = [wself compareVersion:appStoreVersion];
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    if (result) {
                                                        [wself showUpdateAlertController:appID];
                                                    }
                                                });
                                            }];
    [task resume];
}

- (BOOL)compareVersion:(NSString *)appStoreVersion {
    NSString *    currentVersion = [TXAppInfo appVersion];
    NSLog(@"====== current version is %@ ======", currentVersion);
    return [appStoreVersion compare:currentVersion options:NSNumericSearch] == NSOrderedDescending;
}

- (void)showUpdateAlertController:(NSString *)appID {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:TRTCLocalize(@"Demo.TRTC.LiveRoom.prompt")
                                                                             message:TRTCLocalize(@"Demo.TRTC.Home.newversionpublic")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *    sureAction      = [UIAlertAction actionWithTitle:TRTCLocalize(@"Demo.TRTC.Home.updatenow")
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *_Nonnull action) {
                                                           [self openAppStore:appID];
                                                       }];
    UIAlertAction *    cancelAction    = [UIAlertAction actionWithTitle:TRTCLocalize(@"Demo.TRTC.Home.later") style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:sureAction];
    [alertController addAction:cancelAction];
    if (self.window.rootViewController) {
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)openAppStore:(NSString *)appID {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/us/app/id%@?ls=1&mt=8", appID]];
    [[UIApplication sharedApplication] openURL:url];
}
@end
