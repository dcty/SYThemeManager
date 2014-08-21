//
// Created by Ivan on 14-8-21.
//
//


#import <objc/runtime.h>
#import "SYThemeManager.h"
#import "StandardPaths.h"
#import "BILib.h"

#define SY_THEME_PATH  @"SY_THEME_PATH"


@interface WeakRef : NSProxy

@property(weak, nonatomic) id ref;                                //weak 引用对象
@property(copy, nonatomic) NSString *keyPath;                     //要修改的路径，如 backgroundColor textColor 等
@property(assign, nonatomic) UIControlState controlState;         // UIControl 的 状态，如 UIButton

- (id)initWithObject:(id)object;

@end

@interface NSMutableArray (SYTheme)

/**
*   @brief  添加一个带有keyPath的弱引用对象
*   @param  object  WeakRef实例
*   @param  keyPath 路径
*/
- (void)addWeakRefOfObject:(id)object onKeyPath:(NSString *)keyPath;


/**
*   @brief  添加一个带有keyPath的弱引用对象
*   @param  object  WeakRef实例
*   @param  keyPath 路径
*   @param  state   UIControl 的 state
*/
- (void)addWeakRefOfObject:(id)object onKeyPath:(NSString *)keyPath controlState:(UIControlState)state;
@end


// WeakRef.m
@implementation WeakRef

- (id)initWithObject:(id)object
{
    self.ref = object;
    return self;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    invocation.target = self.ref;
    [invocation invoke];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    return [self.ref methodSignatureForSelector:sel];
}

@end

@interface SYThemeImageCache : NSCache
- (void)cacheImage:(UIImage *)image forKey:(NSString *)key;

+ (SYThemeImageCache *)sharedSYThemeImageCache;

@end

@implementation SYThemeImageCache
static SYThemeImageCache *_sharedSYThemeImageCache = nil;

+ (SYThemeImageCache *)sharedSYThemeImageCache
{
    static dispatch_once_t singleton;
    dispatch_once(&singleton, ^{
        _sharedSYThemeImageCache = [[self alloc] init];
        _sharedSYThemeImageCache.totalCostLimit = 1024 * 1000 * 10;     //10M 缓存
    });
    return _sharedSYThemeImageCache;
}

- (void)cacheImage:(UIImage *)image forKey:(NSString *)key
{
    if (image)
    {
        [self setObject:image forKey:key cost:(NSUInteger) (image.size.height * image.size.width * image.scale)];
    }
}

@end

@implementation NSMutableArray (SYTheme)

- (void)addWeakRefOfObject:(id)object onKeyPath:(NSString *)keyPath
{
    [self addWeakRefOfObject:object onKeyPath:keyPath controlState:(UIControlState) -1];
}

- (void)addWeakRefOfObject:(id)object onKeyPath:(NSString *)keyPath controlState:(UIControlState)state
{
    NSAssert(keyPath, @"keyPath不能为空");
    __block BOOL shouldAdd = YES;
    [self enumerateObjectsUsingBlock:^(WeakRef *obj, NSUInteger idx, BOOL *stop) {
        if (obj.ref == object)
        {
            if (obj.controlState != -1)
            {
                if (obj.controlState == state)
                {
                    *stop = YES;
                    shouldAdd = NO;
                }
            }
            else
            {
                *stop = YES;
                shouldAdd = NO;
            }
        }
    }];
    if (shouldAdd)
    {
        WeakRef *weak = [[WeakRef alloc] initWithObject:object];
        weak.controlState = state;
        weak.keyPath = keyPath;
        [self addObject:weak];
    }
}

@end


@interface SYThemeManager ()

@property(nonatomic, strong) NSMutableDictionary *cacheViews;
@property(nonatomic, strong) NSMutableDictionary *themeValues;    //主题的一系列值，到时候读取文件

@end

@implementation SYThemeManager

static SYThemeManager *_sharedSYThemeManager = nil;

+ (SYThemeManager *)sharedSYThemeManager
{
    static dispatch_once_t singleton;
    dispatch_once(&singleton, ^{
        _sharedSYThemeManager = [[self alloc] init];
    });
    return _sharedSYThemeManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.themeValues = [[NSMutableDictionary alloc] init];
        self.cacheViews = [[NSMutableDictionary alloc] init];
        self.syThemeImageQueue = dispatch_queue_create("com.xixiaoyou.themeImage", NULL);
        [self registerInject];
        self.themePath = [[NSUserDefaults standardUserDefaults] stringForKey:SY_THEME_PATH];
        if (!_themePath)
        {
            self.themePath = [[NSFileManager defaultManager] pathForResource:@"FirstTheme.json"];
        }
        [self themeChanged];
    }

    return self;
}

- (void)registerInject
{
    [BILib injectToClass:[UIView class] selector:@selector(setBackgroundColor:) postprocess:^(UIView *view, id value) {
        [self addObserverForView:view onKeyPath:@"backgroundColor" forValue:value];
    }];

    [BILib injectToClass:[UILabel class] selector:@selector(setTextColor:) postprocess:^(UILabel *label, id value) {
        [self addObserverForView:label onKeyPath:@"textColor" forValue:value];
    }];
}

- (void)addCustomUIInject:(void (^)(SYThemeManager *themeManager))block
{
    if (block)
    {
        block(self);
    }
}

- (void)setThemePath:(NSString *)themePath
{
    if (_themePath && ![_themePath isEqualToString:themePath])
    {
        _themePath = themePath;
        [self themeChanged];
    }
    else
    {
        _themePath = themePath;
    }
}


- (NSString *)themeKeyOfValue:(id)value
{
    __block NSString *returnMe = nil;
    [_themeValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([value isKindOfClass:[NSString class]])
        {
            if ([obj isKindOfClass:[NSString class]] && [obj isEqualToString:value])
            {
                returnMe = key;
                *stop = YES;
            }
        }
        else
        {
            if (obj == value)
            {
                returnMe = key;
                *stop = YES;
            }
        }
    }];
    return returnMe;
}

- (id)valueForThemeKey:(NSString *)key
{
    return _themeValues[key];
}

- (void)addObserverForView:(UIView *)view onKeyPath:(NSString *)keyPath forValue:(NSString *)value
{
    NSString *themeKey = [self themeKeyOfValue:value];
    if (themeKey)
    {
        [self cacheView:view onKeyPath:keyPath forKey:themeKey];
    }
}

- (void)cacheView:(UIView *)view onKeyPath:(NSString *)keyPath forKey:(NSString *)key
{
    @synchronized (_cacheViews)
    {
        NSMutableArray *array = [self arrayOfKey:key];
        @synchronized (array)
        {
            [array addWeakRefOfObject:view onKeyPath:keyPath];
        }
    }
}

- (void)addObserverForView:(UIView *)view onKeyPath:(NSString *)keyPath forValue:(NSString *)value controlState:(UIControlState)state
{
    @synchronized (_cacheViews)
    {
        NSString *key = [self themeKeyOfValue:value];
        NSMutableArray *array = [self arrayOfKey:key];
        @synchronized (array)
        {
            [array addWeakRefOfObject:view onKeyPath:keyPath controlState:state];
        }
    }
}

- (void)removeInvalidView
{
    @synchronized (_cacheViews)
    {
        [_cacheViews enumerateKeysAndObjectsWithOptions:NSEnumerationReverse usingBlock:^(id key, id obj, BOOL *stop) {
            NSMutableArray *array = obj;
            NSMutableArray *removeArray = [[NSMutableArray alloc] init];
            for (WeakRef *weak in array)
            {
                if (!weak.ref)
                {
                    [removeArray addObject:weak];
                }
            }
            [array removeObjectsInArray:removeArray];
        }];
    }
}


- (NSMutableArray *)arrayOfKey:(NSString *)key
{
    NSAssert(key, @"key 不能为空");
    NSMutableArray *array = _cacheViews[key];
    if (!array)
    {
        array = [[NSMutableArray alloc] init];
        @synchronized (_cacheViews)
        {
            _cacheViews[key] = array;
        }
    }
    return array;
}

- (void)themeChanged
{
    [_themeValues removeAllObjects];
    [[SYThemeImageCache sharedSYThemeImageCache] removeAllObjects];
    NSData *jsonData = [[NSData alloc] initWithContentsOfFile:_themePath];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
    NSString *bundle = [[dict valueForKey:@"bundle"] lowercaseString];
    if (bundle)
    {
        [dict enumerateKeysAndObjectsUsingBlock:^(id key, NSDictionary *dictionary, BOOL *stop) {
            if ([key isEqualToString:@"color"])
            {
                [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *themeKey, NSString *themeValue, BOOL *stop1) {
                    [_themeValues setValue:[self colorWithHexString:themeValue] forKey:themeKey];
                }];
            }
            else if ([key isEqualToString:@"image"])
            {
                [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *themeKey, NSString *themeValue, BOOL *stop1) {
                    NSString *imagePath = nil;
                    if ([bundle isEqualToString:@"main"])
                    {
                        imagePath = [[NSFileManager defaultManager] pathForResource:themeValue];
                    }
                    [_themeValues setValue:imagePath forKey:themeKey];
                }];
            }
        }];
        @synchronized (_cacheViews)
        {
            //逆向来，优先改变后加入的
            [_cacheViews enumerateKeysAndObjectsWithOptions:NSEnumerationReverse usingBlock:^(id key, id obj, BOOL *stop) {
                NSMutableArray *array = obj;
                @synchronized (array)
                {
                    NSMutableArray *removeArray = [[NSMutableArray alloc] init];
                    for (WeakRef *weak in array)
                    {
                        if (weak.ref)
                        {
                            if ([weak.ref isKindOfClass:[UIImageView class]])
                            {
                                [self handleImageViewWithWeakRef:weak andKey:key];
                            }
                            else if ([weak.ref isKindOfClass:[UIButton class]])
                            {
                                [self handleButtonWithWeakRef:weak andKey:key];
                            }
                            else
                            {
                                [self handleCommonViewWithWeakRef:weak andKey:key];
                            }
                        }
                        else
                        {
                            [removeArray addObject:weak];
                        }
                    }
                    [array removeObjectsInArray:removeArray];
                }
            }];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SYThemeDidChanged object:nil];
    }
}

- (id)themeValueForKey:(NSString *)key
{
    return [_themeValues valueForKey:key];
}

- (void)handleCommonViewWithWeakRef:(WeakRef *)weak andKey:(NSString *)key
{
    [weak.ref setValue:[self themeValueForKey:key] forKeyPath:weak.keyPath];
}


- (void)handleImageViewWithWeakRef:(WeakRef *)weak andKey:(NSString *)key
{
    UIImageView *imageView = (UIImageView *) weak.ref;
    if ([weak.keyPath isEqualToString:@"image"])
    {
        [imageView setImageWithName:[self themeValueForKey:key] stretchLeft:imageView.stretchLeft stretchTop:imageView.stretchTop];
    }
    else if ([weak.keyPath isEqualToString:@"backgroundColor"])
    {
        [self handleCommonViewWithWeakRef:weak andKey:key];
    }
}

- (void)handleButtonWithWeakRef:(WeakRef *)weak andKey:(NSString *)key
{
    UIButton *button = (UIButton *) weak.ref;
    if ([weak.keyPath isEqualToString:@"image"])
    {
        [button setImageWithName:[self themeValueForKey:key] forState:weak.controlState];
    }
    else if ([weak.keyPath isEqualToString:@"setBackgroundImage"])
    {
        NSValue *value = (button.resizeValueDict)[@(weak.controlState)];
        CGSize size = value.CGSizeValue;
        [button setBackgroundImageWithName:[self themeValueForKey:key] stretchLeft:(NSInteger) size.height stretchTop:(NSInteger) size.width forState:weak.controlState];
    }
    else if ([weak.keyPath isEqualToString:@"backgroundColor"])
    {
        [self handleCommonViewWithWeakRef:weak andKey:key];
    }
}

- (UIColor *)colorWithHexString:(id)hexString
{
    if (![hexString isKindOfClass:[NSString class]] || [hexString length] == 0)
    {
        return [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
    }

    const char *s = [hexString cStringUsingEncoding:NSASCIIStringEncoding];
    if (*s == '#')
    {
        ++s;
    }
    unsigned long long value = (unsigned long long int) strtoll(s, nil, 16);
    int r, g, b, a;
    switch (strlen(s))
    {
        case 2:
        {
            // xx
            r = g = b = (int) value;
            a = 255;
            break;
        }
        case 3:
        {
            // RGB
            r = (int) ((value & 0xf00) >> 8);
            g = (int) ((value & 0x0f0) >> 4);
            b = (int) ((value & 0x00f) >> 0);
            r = r * 16 + r;
            g = g * 16 + g;
            b = b * 16 + b;
            a = 255;
            break;
        }
        case 6:
        {
            // RRGGBB
            r = (int) ((value & 0xff0000) >> 16);
            g = (int) ((value & 0x00ff00) >> 8);
            b = (int) ((value & 0x0000ff) >> 0);
            a = 255;
            break;
        }
        default:
        {
            // RRGGBBAA
            r = (int) ((value & 0xff000000) >> 24);
            g = (int) ((value & 0x00ff0000) >> 16);
            b = (int) ((value & 0x0000ff00) >> 8);
            a = (int) ((value & 0x000000ff) >> 0);
            break;
        }
    }
    return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:a / 255.0f];
}


@end

@implementation UIImageView (SYTheme)

static const char STRETCH_LEFT;
static const char STRETCH_TOP;

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
    [[SYThemeManager sharedSYThemeManager] addObserverForView:self onKeyPath:@"image" forValue:imageName];
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


@end

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
            [[SYThemeManager sharedSYThemeManager] addObserverForView:self onKeyPath:@"image" forValue:imageName controlState:state];
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
            [[SYThemeManager sharedSYThemeManager] addObserverForView:self onKeyPath:@"setBackgroundImage" forValue:imageName controlState:state];
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


@end