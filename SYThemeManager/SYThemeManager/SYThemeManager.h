//
// Created by Ivan on 14-8-21.
//
//


#define Title_BG_Color @"Title_BG_Color"
#define Title_Color @"Title_Color"
#define Content_BG_Color @"Content_BG_Color"
#define Content_Color @"Content_Color"
#define Image_First @"Image_First"
#define Image_Second @"Image_Second"
#define Image_Test @"Image_Test"
#define Image_Test1 @"Image_Test1"

#define SYThemeDidChanged @"SYThemeDidChanged"

//通过 key 获取 值
#define SYThemeValueForKey(key) [[SYThemeManager sharedSYThemeManager] valueForThemeKey:key]

#import <Foundation/Foundation.h>


@interface SYThemeManager : NSObject

+ (SYThemeManager *)sharedSYThemeManager;

- (NSString *)themeKeyOfValue:(id)value;

- (id)valueForThemeKey:(NSString *)key;

/**
*   @brief 监听view，然后根据路径和值来修改 这里的view是弱引用（weak），不用担心crash的问题
*   @param  view    要监听的view
*   @param  keyPath 修改的路径   如 textColor，backgroundColor等
*   @param  value   keyPath的值，内部会通过value找到themeKey
*/
- (void)addObserverForView:(UIView *)view onKeyPath:(NSString *)keyPath forValue:(NSString *)value;

/**
*   @brief 监听view，然后根据路径和值来修改 这里的view是弱引用（weak），不用担心crash的问题
*   @param  view    要监听的view
*   @param  keyPath 修改的路径   如 textColor，backgroundColor等
*   @param  value   keyPath的值，内部会通过value找到themeKey
*   @param  state   状态  如 UIButton
*/
- (void)addObserverForView:(UIView *)view onKeyPath:(NSString *)keyPath forValue:(NSString *)value controlState:(UIControlState)state;

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

@interface UIImageView (SYTheme)

@property(assign, nonatomic) NSInteger stretchLeft;     //image 拉伸的参数
@property(assign, nonatomic) NSInteger stretchTop;      //image 拉伸的参数

/**
*   @brief  通过设置图片名来给UIImageView设置image   默认开启图片缓存，下同
*   @param  imageName   图片名字    这个值，必须用上面定义的宏来获取
*/
- (void)setImageWithName:(NSString *)imageName;

/**
*   @brief  通过设置图片名来给UIImageView设置image
*   @param  imageName   图片名字    这个值，必须用上面定义的宏来获取
*   @param  cache       是否使用图片缓存
*/
- (void)setImageWithName:(NSString *)imageName cache:(BOOL)cache;

/**
*   @brief  通过设置图片名来给UIImageView设置image
*   @param  imageName   图片名字    这个值，必须用上面定义的宏来获取
*   @param  leftValue   图片拉伸参数
*   @param  topValue    图片拉伸参数
*/
- (void)setImageWithName:(NSString *)imageName stretchLeft:(NSInteger)leftValue stretchTop:(NSInteger)topValue;

- (void)setImageWithName:(NSString *)imageName stretchLeft:(NSInteger)leftValue stretchTop:(NSInteger)topValue cache:(BOOL)cache;

@end

@interface UIButton (SYTheme)

@property(strong, nonatomic) NSMutableDictionary *resizeValueDict;

/**
*   @brief  通过设置图片名来给UIButton设置image
*   @param  图片名字    这个值，必须用上面定义的宏来获取
*   @param  state  UIButton的state
*/
- (void)setImageWithName:(NSString *)imageName forState:(UIControlState)state;


- (void)setImageWithName:(NSString *)imageName forState:(UIControlState)state cache:(BOOL)cache;

/**
*   @brief  通过设置图片名来给UIButton设置BackgroundImage
*   @param  图片名字    这个值，必须用上面定义的宏来获取
*   @param  state  UIButton的state
*/
- (void)setBackgroundImageWithName:(NSString *)imageName forState:(UIControlState)state;

- (void)setBackgroundImageWithName:(NSString *)imageName forState:(UIControlState)state cache:(BOOL)cache;

/**
*   @brief  通过设置图片名来给UIButton设置BackgroundImage已image的中心拉伸
*   @param  图片名字    这个值，必须用上面定义的宏来获取
*   @param  state  UIButton的state
*/
- (void)setResizeCenterBackgroundImageWithName:(NSString *)imageName forState:(UIControlState)state;

- (void)setResizeCenterBackgroundImageWithName:(NSString *)imageName forState:(UIControlState)state cache:(BOOL)cache;

/**
*   @brief  通过设置图片名来给UIButton设置BackgroundImage
*   @param  图片名字    这个值，必须用上面定义的宏来获取
*   @param  leftValue   图片拉伸参数
*   @param  topValue    图片拉伸参数
*   @param  state  UIButton的state
*/
- (void)setBackgroundImageWithName:(NSString *)imageName stretchLeft:(NSInteger)leftValue stretchTop:(NSInteger)topValue forState:(UIControlState)state;

- (void)setBackgroundImageWithName:(NSString *)imageName stretchLeft:(NSInteger)leftValue stretchTop:(NSInteger)topValue forState:(UIControlState)state cache:(BOOL)cache;
@end