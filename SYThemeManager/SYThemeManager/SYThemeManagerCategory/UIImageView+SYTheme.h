//
// Created by Ivan on 14-8-27.
//
//


#import <Foundation/Foundation.h>

@interface UIImageView (SYTheme)

@property(assign, nonatomic) NSInteger stretchLeft;     //image 拉伸的参数
@property(assign, nonatomic) NSInteger stretchTop;      //image 拉伸的参数
@property(assign, nonatomic) NSInteger highlighted_stretchLeft;     //image 拉伸的参数
@property(assign, nonatomic) NSInteger highlighted_stretchTop;      //image 拉伸的参数

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

/**
*   @brief  设置高亮image
*/
- (void)setHighlightedImageWithName:(NSString *)imageName stretchLeft:(NSInteger)leftValue stretchTop:(NSInteger)topValue;

- (void)setHighlightedImageWithName:(NSString *)imageName stretchLeft:(NSInteger)leftValue stretchTop:(NSInteger)topValue cache:(BOOL)cache;

@end