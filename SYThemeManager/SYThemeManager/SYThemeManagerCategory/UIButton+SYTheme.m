//
// Created by Ivan on 14-8-27.
//
//


#import <objc/runtime.h>
#import "UIButton+SYTheme.h"
#import "SYThemeManager.h"


@implementation UIButton (SYTheme)


static const char RESIZE_VALUES_DICT;

- (NSMutableDictionary *)resizeValueDict
{
    NSMutableDictionary *dictionary = objc_getAssociatedObject(self, &RESIZE_VALUES_DICT);
    if (!dictionary)
    {
        NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
        [self setResizeValueDict:newDict];
        dictionary = newDict;
    }
    return dictionary;
}

- (void)setResizeValueDict:(NSMutableDictionary *)resizeValueDict
{
    objc_setAssociatedObject(self, &RESIZE_VALUES_DICT, resizeValueDict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (void)setImageWithName:(NSString *)imageName forState:(UIControlState)state
{
    [self setImageWithName:imageName forState:state cache:YES];
}

- (void)setImageWithName:(NSString *)imageName forState:(UIControlState)state cache:(BOOL)cache
{
    dispatch_async([SYThemeManager sharedSYThemeManager].syThemeImageQueue, ^{
        UIImage *image = [[SYThemeImageCache sharedSYThemeImageCache] objectForKey:imageName];
        if (!image)
        {
            image = [[UIImage alloc] initWithContentsOfFile:imageName];
            if (cache)
            {
                [[SYThemeImageCache sharedSYThemeImageCache] cacheImage:image forKey:imageName];
            }
        }
        if (image)
        {
            [[SYThemeManager sharedSYThemeManager] addObserverForView:self onKeyPath:@"image" value:imageName controlState:state];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setImage:image forState:state];
            });
        }
    });

}

- (void)setBackgroundImageWithName:(NSString *)imageName forState:(UIControlState)state
{
    [self setBackgroundImageWithName:imageName stretchLeft:0 stretchTop:0 forState:state cache:YES];
}

- (void)setBackgroundImageWithName:(NSString *)imageName forState:(UIControlState)state cache:(BOOL)cache
{
    [self setBackgroundImageWithName:imageName stretchLeft:0 stretchTop:0 forState:state cache:cache];
}

- (void)setResizeCenterBackgroundImageWithName:(NSString *)imageName forState:(UIControlState)state
{
    [self setResizeCenterBackgroundImageWithName:imageName forState:state cache:YES];
}

- (void)setResizeCenterBackgroundImageWithName:(NSString *)imageName forState:(UIControlState)state cache:(BOOL)cache
{
    dispatch_async([SYThemeManager sharedSYThemeManager].syThemeImageQueue, ^{
        UIImage *image = [[SYThemeImageCache sharedSYThemeImageCache] objectForKey:imageName];
        if (!image)
        {
            image = [[UIImage alloc] initWithContentsOfFile:imageName];
            if (cache)
            {
                [[SYThemeImageCache sharedSYThemeImageCache] cacheImage:image forKey:imageName];
            }
        }
        CGSize imageSize = image.size;
        CGFloat centerX = imageSize.width / 2;
        CGFloat centerY = imageSize.height / 2;
        [self setBackgroundImageWithName:imageName stretchLeft:(NSInteger) centerX stretchTop:(NSInteger) centerY forState:state cache:cache];
    });
}

- (void)setBackgroundImageWithName:(NSString *)imageName stretchLeft:(NSInteger)leftValue stretchTop:(NSInteger)topValue forState:(UIControlState)state
{
    [self setBackgroundImageWithName:imageName stretchLeft:leftValue stretchTop:topValue forState:state cache:YES];
}


- (void)setBackgroundImageWithName:(NSString *)imageName stretchLeft:(NSInteger)leftValue stretchTop:(NSInteger)topValue forState:(UIControlState)state cache:(BOOL)cache
{
    dispatch_async([SYThemeManager sharedSYThemeManager].syThemeImageQueue, ^{
        UIImage *image = [[SYThemeImageCache sharedSYThemeImageCache] objectForKey:imageName];
        if (!image)
        {
            image = [[UIImage alloc] initWithContentsOfFile:imageName];
            if (cache)
            {
                [[SYThemeImageCache sharedSYThemeImageCache] cacheImage:image forKey:imageName];
            }
        }
        if (image)
        {
            [[SYThemeManager sharedSYThemeManager] addObserverForView:self onKeyPath:@"setBackgroundImage" value:imageName controlState:state];
            UIImage *finalImage = image;
            if (leftValue || topValue)
            {
                NSValue *value = (self.resizeValueDict)[@(state)];
                if (!value)
                {
                    value = [NSValue valueWithCGSize:CGSizeMake(leftValue, topValue)];
                    (self.resizeValueDict)[@(state)] = value;
                }
                finalImage = [image stretchableImageWithLeftCapWidth:leftValue topCapHeight:topValue];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setBackgroundImage:finalImage forState:state];
            });
        }
    });
}

- (void)theme_setTitleColor:(UIColor *)color forState:(UIControlState)state
{
    [self setTitleColor:color forState:state];
    [[SYThemeManager sharedSYThemeManager] addObserverForView:self onKeyPath:THEME_BUTTON_TITLECOLOR value:color controlState:state];
}


@end