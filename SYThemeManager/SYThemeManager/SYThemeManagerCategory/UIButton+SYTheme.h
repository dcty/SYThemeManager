//
// Created by Ivan on 14-8-27.
//
//


#import <Foundation/Foundation.h>

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


- (void)theme_setTitleColor:(UIColor *)color forState:(UIControlState)state;

@end