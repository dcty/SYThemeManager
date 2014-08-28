//
// Created by Ivan on 14-8-27.
//
//


#import <objc/runtime.h>
#import "UIImageView+SYTheme.h"
#import "SYThemeManager.h"


@implementation UIImageView (SYTheme)

static const char STRETCH_LEFT;
static const char HIGHLIGHTEDSTRETCH_LEFT;
static const char STRETCH_TOP;
static const char HIGHLIGHTEDSTRETCH_TOP;

- (NSInteger)stretchLeft
{
    return [objc_getAssociatedObject(self, &STRETCH_LEFT) integerValue];
}

- (void)setStretchLeft:(NSInteger)stretchLeft
{
    objc_setAssociatedObject(self, &STRETCH_LEFT, @(stretchLeft), OBJC_ASSOCIATION_RETAIN);
}

- (NSInteger)stretchTop
{
    return [objc_getAssociatedObject(self, &STRETCH_TOP) integerValue];
}

- (void)setStretchTop:(NSInteger)stretchTop
{
    objc_setAssociatedObject(self, &STRETCH_TOP, @(stretchTop), OBJC_ASSOCIATION_RETAIN);
}

- (NSInteger)highlighted_stretchLeft
{
    return [objc_getAssociatedObject(self, &HIGHLIGHTEDSTRETCH_LEFT) integerValue];
}

- (void)setHighlighted_stretchLeft:(NSInteger)highlighted_stretchLeft
{
    objc_setAssociatedObject(self, &HIGHLIGHTEDSTRETCH_LEFT, @(highlighted_stretchLeft), OBJC_ASSOCIATION_RETAIN);
}

- (NSInteger)highlighted_stretchTop
{
    return [objc_getAssociatedObject(self, &HIGHLIGHTEDSTRETCH_TOP) integerValue];;
}

- (void)setHighlighted_stretchTop:(NSInteger)highlighted_stretchTop
{
    objc_setAssociatedObject(self, &HIGHLIGHTEDSTRETCH_TOP, @(highlighted_stretchTop), OBJC_ASSOCIATION_RETAIN);
}


- (void)setImageWithName:(NSString *)imageName
{
    [self setImageWithName:imageName cache:YES];
}

- (void)setImageWithName:(NSString *)imageName cache:(BOOL)cache
{
    [self setImageWithName:imageName stretchLeft:0 stretchTop:0 cache:cache];
}


- (void)setImageWithName:(NSString *)imageName stretchLeft:(NSInteger)leftValue stretchTop:(NSInteger)topValue
{
    [self setImageWithName:imageName stretchLeft:leftValue stretchTop:topValue cache:YES];
}


- (void)setImageWithName:(NSString *)imageName stretchLeft:(NSInteger)leftValue stretchTop:(NSInteger)topValue cache:(BOOL)cache
{
    UIImage *image = [[SYThemeImageCache sharedSYThemeImageCache] objectForKey:imageName];
    if (!image)
    {
        image = [[UIImage alloc] initWithContentsOfFile:imageName];
        if (cache)
        {
            [[SYThemeImageCache sharedSYThemeImageCache] cacheImage:image forKey:imageName];
        }
    }
    [[SYThemeManager sharedSYThemeManager] addObserverForView:self onKeyPath:@"image" value:imageName];
    if (leftValue || topValue)
    {
        self.stretchLeft = leftValue;
        self.stretchTop = topValue;
        self.image = [image stretchableImageWithLeftCapWidth:leftValue topCapHeight:topValue];
    }
    else
    {
        self.image = image;
    }
}

- (void)setHighlightedImageWithName:(NSString *)imageName stretchLeft:(NSInteger)leftValue stretchTop:(NSInteger)topValue
{
    [self setHighlightedImageWithName:imageName stretchLeft:leftValue stretchTop:topValue cache:YES];
}

- (void)setHighlightedImageWithName:(NSString *)imageName stretchLeft:(NSInteger)leftValue stretchTop:(NSInteger)topValue cache:(BOOL)cache
{
    UIImage *image = [[SYThemeImageCache sharedSYThemeImageCache] objectForKey:imageName];
    if (!image)
    {
        image = [[UIImage alloc] initWithContentsOfFile:imageName];
        if (cache)
        {
            [[SYThemeImageCache sharedSYThemeImageCache] cacheImage:image forKey:imageName];
        }
    }
    [[SYThemeManager sharedSYThemeManager] addObserverForView:self onKeyPath:@"image" value:imageName];
    if (leftValue || topValue)
    {
        self.stretchLeft = leftValue;
        self.stretchTop = topValue;
        self.highlightedImage = [image stretchableImageWithLeftCapWidth:leftValue topCapHeight:topValue];
    }
    else
    {
        self.highlightedImage = image;
    }
}


@end