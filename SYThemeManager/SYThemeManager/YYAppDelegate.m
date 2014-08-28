//
//  YYAppDelegate.m
//  SYThemeManager
//
//  Created by Ivan Chua on 14-8-21.
//  Copyright (c) 2014 caicode. All rights reserved.
//

#import "YYAppDelegate.h"
#import "SYThemeManager.h"
#import "BILib.h"
#import "StandardPaths.h"
#import "UIImageView+SYTheme.h"
#import "UIButton+SYTheme.h"

@implementation YYAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    [SYThemeManager sharedSYThemeManager];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 50, 200, 20)];
    titleLabel.text = @"我是标题";
    titleLabel.backgroundColor = SYThemeColor(Title_BG_Color);
    titleLabel.textColor = SYThemeColor(Title_Color);
    titleLabel.font = SYThemeFont(FirstFont);
    [self.window addSubview:titleLabel];
    UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 80, 200, 20)];
    contentLabel.text = @"我是内容";
    contentLabel.backgroundColor = SYThemeColor(Content_BG_Color);
    contentLabel.textColor = SYThemeColor(Content_Color);
    [self.window addSubview:contentLabel];

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 110, 30, 30)];
    [imageView setImageWithName:SYThemeImage(Image_First)];
    [self.window addSubview:imageView];

    UIImageView *imageView1 = [[UIImageView alloc] initWithFrame:CGRectMake(50, 110, 80, 30)];
    [imageView1 setImageWithName:SYThemeImage(Image_Test) stretchLeft:30 stretchTop:20];
    [self.window addSubview:imageView1];

    UIButton *button1 = [[UIButton alloc] initWithFrame:CGRectMake(10, 150, 30, 30)];
    [button1 setImageWithName:SYThemeImage(Image_Second) forState:UIControlStateNormal];
    [self.window addSubview:button1];

    UIButton *button2 = [[UIButton alloc] initWithFrame:CGRectMake(50, 150, 80, 30)];
    [button2 setResizeCenterBackgroundImageWithName:SYThemeImage(Image_Test) forState:UIControlStateNormal];
    [button2 setBackgroundImageWithName:SYThemeImage(Image_Test1) stretchLeft:30 stretchTop:20 forState:UIControlStateHighlighted];
    [button2 setTitle:@"test" forState:UIControlStateNormal];
    [button2 theme_setTitleColor:SYThemeColor(Title_Color) forState:UIControlStateNormal];
    [button2 theme_setTitleColor:SYThemeColor(Title_BG_Color) forState:UIControlStateHighlighted];
    [self.window addSubview:button2];

    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithFrame:CGRectMake(0, 110, 100, 30)];
    [segmentedControl insertSegmentWithTitle:@"主题1" atIndex:0 animated:NO];
    [segmentedControl insertSegmentWithTitle:@"主题2" atIndex:1 animated:NO];
    segmentedControl.center = self.window.center;
    segmentedControl.selectedSegmentIndex = 0;
    if ([[SYThemeManager sharedSYThemeManager].themePath rangeOfString:@"First"].location != NSNotFound)
    {
        segmentedControl.selectedSegmentIndex = 0;
    }
    else
    {
        segmentedControl.selectedSegmentIndex = 1;
    }
    [segmentedControl addTarget:self action:@selector(themeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.window addSubview:segmentedControl];

    [[SYThemeManager sharedSYThemeManager] addCustomUIInject:^(SYThemeManager *themeManager) {
        [BILib injectToClass:[UISegmentedControl class] selector:@selector(setTintColor:) postprocess:^(id sender, id value) {
            [themeManager addObserverForView:sender onKeyPath:@"tintColor" value:value];
        }];
    }];

    [segmentedControl setTintColor:SYThemeColor(Title_Color)];

    return YES;
}

- (void)themeChanged:(UISegmentedControl *)segmentedControl
{
    if (segmentedControl.selectedSegmentIndex == 0)
    {
        [SYThemeManager sharedSYThemeManager].themePath = [[NSFileManager defaultManager] pathForResource:@"FirstTheme.json"];
    }
    else
    {
        [SYThemeManager sharedSYThemeManager].themePath = [[NSFileManager defaultManager] pathForResource:@"SecondTheme.json"];
    }
}

@end