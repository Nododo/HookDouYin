//  weibo: http://weibo.com/xiaoqing28
//  blog:  http://www.alonemonkey.com
//
//  douyinDylib.m
//  douyinDylib
//
//  Created by nododo on 2018/12/18.
//  Copyright (c) 2018 nododo. All rights reserved.
//

#import "douyinDylib.h"
#import <CaptainHook/CaptainHook.h>
#import <UIKit/UIKit.h>
#import <Cycript/Cycript.h>
#import <MDCycriptManager.h>
#import "CTBlockDescription.h"
#import "CTObjectiveCRuntimeAdditions.h"

static NSString * const VideoPlayEndedNotiName = @"VideoPlayEndedNotiName";
static NSString * const OpenAutoPlay = @"OpenAutoPlay";

CHConstructor{
    printf(INSERT_SUCCESS_WELCOME);
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        
#ifndef __OPTIMIZE__
        CYListenServer(6666);

        MDCycriptManager* manager = [MDCycriptManager sharedInstance];
        [manager loadCycript:NO];

        NSError* error;
        NSString* result = [manager evaluateCycript:@"UIApp" error:&error];
        NSLog(@"result: %@", result);
        if(error.code != 0){
            NSLog(@"error: %@", error.localizedDescription);
        }
#endif
        
    }];
}


CHDeclareClass(CustomViewController)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"

//add new method
CHDeclareMethod1(void, CustomViewController, newMethod, NSString*, output){
    NSLog(@"This is a new method : %@", output);
}

#pragma clang diagnostic pop

CHOptimizedClassMethod0(self, void, CustomViewController, classMethod){
    NSLog(@"hook class method");
    CHSuper0(CustomViewController, classMethod);
}

CHOptimizedMethod0(self, NSString*, CustomViewController, getMyName){
    //get origin value
    NSString* originName = CHSuper(0, CustomViewController, getMyName);
    
    NSLog(@"origin name is:%@",originName);
    
    //get property
    NSString* password = CHIvar(self,_password,__strong NSString*);
    
    NSLog(@"password is %@",password);
    
    [self newMethod:@"output"];
    
    //set new property
    self.newProperty = @"newProperty";
    NSLog(@"newProperty : %@", self.newProperty);
    //change the value
    return @"nododo";
}

#pragma mark - 关闭弹框

CHDeclareClass(UIViewController)

CHOptimizedMethod3(self, void, UIViewController, presentViewController, UIViewController *, viewControllerToPresent, animated, BOOL, flag, completion, id, completion) {
    if([viewControllerToPresent isKindOfClass:UIAlertController.class]) {
        return;
    }
    CHSuper3(UIViewController, presentViewController, viewControllerToPresent, animated, flag, completion, completion);
}

#pragma mark - 自动播放相关

CHDeclareClass(AWEFeedTableViewController)

CHOptimizedMethod(0, self, BOOL, AWEFeedTableViewController, pureMode) {
    return YES;
}

@interface AWEFeedTableViewController : UIViewController

@property (nonatomic, assign) NSInteger currentPlayIndex;

@end

//- (void)_addNotifications;
CHOptimizedMethod0(self, void, AWEFeedTableViewController, _addNotifications) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNext) name:VideoPlayEndedNotiName object:nil];
    CHSuper0(AWEFeedTableViewController, _addNotifications);
}

CHDeclareMethod0(void, AWEFeedTableViewController, playNext) {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:OpenAutoPlay] == NO) {
        return;
    }
    UITableView *tableView = [self valueForKey:@"_tableView"];
    NSIndexPath *path = [NSIndexPath indexPathForRow:self.currentPlayIndex +1 inSection:0];
    [tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}


CHDeclareClass(AWEVideoPlayerController)

CHOptimizedMethod1(self, void, AWEVideoPlayerController, playerItemDidReachEnd, id, arg1) {
    NSLog(@"--------------------------------");
    [[NSNotificationCenter defaultCenter] postNotificationName:VideoPlayEndedNotiName object:nil];
    CHSuper1(AWEVideoPlayerController, playerItemDidReachEnd, arg1);
}

#pragma mark - 设置界面相关

@interface AWEGeneralSettingViewModel : NSObject

- (id)sectionDataArray;
- (void)setSectionDataArray:(id)arg1;

@end

@interface AWESettingSectionModel : NSObject

@property(retain, nonatomic) NSArray *itemArray;

@end

@interface AWESettingItemModel : NSObject

@property(copy, nonatomic) NSString *title;
@property(nonatomic) long long cellType;
@property(nonatomic) _Bool isSwitchOn;
@property(copy, nonatomic) id switchChangedBlock;

@end

CHDeclareClass(AWESettingsViewModel)

@interface AWESettingsTableViewController : UIViewController

@end

CHDeclareClass(AWESettingsTableViewController)

CHOptimizedMethod0(self, void, AWESettingsTableViewController, refreshView) {
    AWEGeneralSettingViewModel *model = [self valueForKey:@"_viewModel"];
    NSMutableArray *sectionArr = [NSMutableArray arrayWithArray:model.sectionDataArray];
    AWESettingSectionModel *secModel = sectionArr[1];
    NSMutableArray *secArr = [NSMutableArray arrayWithArray:secModel.itemArray];
    AWESettingItemModel *lastItem = secArr.lastObject;


    if(![lastItem.title isEqualToString:@"连续播放"]) {
        AWESettingItemModel *item = [[objc_getClass("AWESettingItemModel") alloc] init];
        item.title = @"连续播放";
        item.cellType = 4;
        item.isSwitchOn = [[NSUserDefaults standardUserDefaults] boolForKey:OpenAutoPlay];
        item.switchChangedBlock = ^(BOOL ison) {
            [[NSUserDefaults standardUserDefaults] setBool:ison forKey:OpenAutoPlay];
        };
        
        [secArr addObject:item];
        secModel.itemArray = secArr;
        [sectionArr replaceObjectAtIndex:1 withObject:secModel];
        [model setSectionDataArray:sectionArr];
        [self setValue:model forKey:@"_viewModel"];
    }
    CHSuper0(AWESettingsTableViewController, refreshView);
}


#pragma mark - 获取block参数相关

//CHDeclareClass(AWEGeneralSettingViewController)

//@interface AWEGeneralSettingViewController : UIViewController
////AWEGeneralSettingViewController AWESettingsTableViewController 为并列子类 hook 了 父类的 refreshView 结果代码执行起来优先hook了  堆栈关系优先出现的AWESettingsTableViewController
//@end
//
//CHDeclareMethod0(void, AWEGeneralSettingViewController, testXXX) {
//    AWEGeneralSettingViewModel *model = [self valueForKey:@"_viewModel"];
//    AWESettingSectionModel *secModel = [(NSArray *)(model.sectionDataArray) firstObject];
//    NSMutableArray *secArr = [NSMutableArray arrayWithArray:secModel.itemArray];
//
//    NSString *tempStr = @"";
//    if (YES) {
//        AWESettingItemModel *testItem = secArr[1];
//
//        id testBlock = testItem.switchChangedBlock;
//        CTBlockDescription *blockDescription = [[CTBlockDescription alloc] initWithBlock:testBlock];
//        const char *expectedArguments[] = {@encode(typeof(testBlock)), @encode(BOOL), @encode(id)};
//        for (int i = 0; i < blockDescription.blockSignature.numberOfArguments; i++) {
//            NSString *argu = [NSString stringWithFormat:@"第%d个参数为 %@", i, [NSString stringWithUTF8String: expectedArguments[i]]];
//            tempStr = [[tempStr stringByAppendingString:argu] stringByAppendingString:@"\n"];
//        }
//        [self performSelector:@selector(showLoadingViewWithTitle:) withObject:tempStr];
//    }
//
//}
//
//CHOptimizedMethod0(self, void, AWEGeneralSettingViewController, viewDidLoad) {
//    [self performSelector:@selector(testXXX) withObject:nil afterDelay:0.5];
//    CHSuper0(AWEGeneralSettingViewController, viewDidLoad);
//}


CHConstructor{
    CHLoadLateClass(CustomViewController);
    CHClassHook0(CustomViewController, getMyName);
    CHClassHook0(CustomViewController, classMethod);
    
    CHLoadLateClass(UIViewController);
    CHHook3(UIViewController, presentViewController, animated, completion);
    
    CHLoadLateClass(AWEFeedTableViewController);
    CHHook0(AWEFeedTableViewController, pureMode);
    CHHook0(AWEFeedTableViewController, _addNotifications);
    
    
    CHLoadLateClass(AWEVideoPlayerController);
    CHHook1(AWEVideoPlayerController, playerItemDidReachEnd);
    
    CHLoadLateClass(AWESettingsTableViewController);
    CHHook0(AWESettingsTableViewController, refreshView);

//    CHLoadLateClass(AWEGeneralSettingViewController);
//    CHHook0(AWEGeneralSettingViewController, viewDidLoad);
//    CHHook0(AWEGeneralSettingViewController, testXXX);
}

