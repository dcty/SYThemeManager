//
// Created by Ivan on 14-8-21.
//
//


#define Title_BG_Color @"Title_BG_Color"
#define Title_Color @"Title_Color"
#define Content_BG_Color @"Content_BG_Color"
#define Content_Color @"Content_Color"

#define THEME_TEXTCOLOR @"textColor"
#define THEME_BACKGROUNDCOLOR @"backgroundColor"
#define THEME_IMAGE @"image"
#define THEME_BACKGROUNDIMAGE @"BackgroundImage"
#define THEME_BUTTON_TITLECOLOR @"ButtonTitleColor"
#define THEME_FONT @"font"

#define SYThemeDidChanged @"SYThemeDidChanged"



//通过 key 获取 值
#define SYThemeColor(key) [[SYThemeManager sharedSYThemeManager] valueForThemeKey:key]

#import <Foundation/Foundation.h>

@interface SYThemeImageCache : NSCache
- (void)cacheImage:(UIImage *)image forKey:(NSString *)key;

+ (SYThemeImageCache *)sharedSYThemeImageCache;
@end

@interface SYThemeManager : NSObject

+ (SYThemeManager *)sharedSYThemeManager;

- (NSString *)themeKeyOfValue:(id)value;

- (id)valueForThemeKey:(NSString *)key;

- (NSBundle *)themeBundle;

/**
*   @brief 监听view，然后根据路径和值来修改 这里的view是弱引用（weak），不用担心crash的问题
*   @param  view    要监听的view
*   @param  keyPath 修改的路径   如 textColor，backgroundColor等
*   @param  value   keyPath的值，内部会通过value找到themeKey
*/
- (void)addObserverForView:(UIView *)view onKeyPath:(NSString *)keyPath value:(id)value;

/**
*   @brief 监听view，然后根据路径和值来修改 这里的view是弱引用（weak），不用担心crash的问题
*   @param  view    要监听的view
*   @param  keyPath 修改的路径   如 textColor，backgroundColor等
*   @param  value   keyPath的值，内部会通过value找到themeKey
*   @param  state   状态  如 UIButton
*/
- (void)addObserverForView:(UIView *)view onKeyPath:(NSString *)keyPath value:(id)value controlState:(UIControlState)state;

/**
*   @brief  清理无效的视图
*/
- (void)removeInvalidView;

/**
*   @brief  自己添加更多的注入,当然不一定需要在这里写
*/
- (void)addCustomUIInject:(void (^)(SYThemeManager *themeManager))block;

@property(copy, nonatomic) NSString *themePath;

@property(nonatomic, strong) dispatch_queue_t syThemeImageQueue;

@end