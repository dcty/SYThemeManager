//
// Created by Ivan on 14-8-21.
//
//


#import <objc/runtime.h>
#import "SYThemeManager.h"
#import "StandardPaths.h"
#import "BILib.h"
#import "UIButton+SYTheme.h"
#import "UIImageView+SYTheme.h"
#import "UIColor+SYTheme.h"

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
            self.themePath = [[NSBundle mainBundle] pathForResource:@"FirstTheme" ofType:@"json"];
        }
        [self themeChanged];
    }

    return self;
}

- (void)registerInject
{
    [BILib injectToClass:[UIView class] selector:@selector(setBackgroundColor:) postprocess:^(UIView *view, id value) {
        [self addObserverForView:view onKeyPath:THEME_BACKGROUNDCOLOR value:value];
    }];

    [BILib injectToClassWithNames:@[@"UITextField", @"UITextView", @"UILabel"] methodNames:@[@"setFont:", @"setTextColor:"] postprocess:^(UIView *view, id value) {
        if ([value isKindOfClass:[UIFont class]])
        {
            [self addObserverForView:view onKeyPath:THEME_FONT value:value];
        }
        else if ([value isKindOfClass:[UIColor class]])
        {
            [self addObserverForView:view onKeyPath:THEME_TEXTCOLOR value:value];
        }
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
    [[NSUserDefaults standardUserDefaults] setObject:_themePath forKey:SY_THEME_PATH];
    [[NSUserDefaults standardUserDefaults] synchronize];
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

- (void)addObserverForView:(UIView *)view onKeyPath:(NSString *)keyPath value:(id)value
{
    [self addObserverForView:view onKeyPath:keyPath value:value controlState:(UIControlState) -1];
}


- (void)addObserverForView:(UIView *)view onKeyPath:(NSString *)keyPath value:(id)value controlState:(UIControlState)state
{
    @synchronized (_cacheViews)
    {
        NSString *key = nil;
        if ([keyPath isEqualToString:THEME_IMAGE])
        {
            key = value;
        }
        else
        {
            key = [self themeKeyOfValue:value];
        }
        if (key)
        {
            NSMutableArray *array = [self arrayOfKey:key];
            @synchronized (array)
            {
                [array addWeakRefOfObject:view onKeyPath:keyPath controlState:state];
            }
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
                    [_themeValues setValue:[UIColor colorWithHexString:themeValue] forKey:themeKey];
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
            else if ([key isEqualToString:@"font"])
            {
                [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *themeKey, NSDictionary *fontDict, BOOL *stop1) {
                    BOOL bold = [fontDict[@"FontStyle"] boolValue];
                    int fontSize = [fontDict[@"FontSize"] intValue];
                    UIFont *font = nil;
                    if (bold)
                    {
                        font = [UIFont boldSystemFontOfSize:fontSize];
                    }
                    else
                    {
                        font = [UIFont systemFontOfSize:fontSize];
                    }
                    [_themeValues setValue:font forKey:themeKey];
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
    if ([weak.keyPath isEqualToString:THEME_IMAGE])
    {
        [imageView setImageWithName:key stretchLeft:imageView.stretchLeft stretchTop:imageView.stretchTop];
    }
    else if ([weak.keyPath isEqualToString:THEME_BACKGROUNDCOLOR])
    {
        [self handleCommonViewWithWeakRef:weak andKey:key];
    }
}

- (void)handleButtonWithWeakRef:(WeakRef *)weak andKey:(NSString *)key
{
    UIButton *button = (UIButton *) weak.ref;
    if ([weak.keyPath isEqualToString:THEME_IMAGE])
    {
        [button setImageWithName:[self themeValueForKey:key] forState:weak.controlState];
    }
    else if ([weak.keyPath isEqualToString:THEME_BACKGROUNDIMAGE])
    {
        NSValue *value = (button.resizeValueDict)[@(weak.controlState)];
        CGSize size = value.CGSizeValue;
        [button setBackgroundImageWithName:[self themeValueForKey:key] stretchLeft:(NSInteger) size.height stretchTop:(NSInteger) size.width forState:weak.controlState];
    }
    else if ([weak.keyPath isEqualToString:THEME_BACKGROUNDCOLOR])
    {
        [self handleCommonViewWithWeakRef:weak andKey:key];
    }
    else if ([weak.keyPath isEqualToString:THEME_BUTTON_TITLECOLOR])
    {
        [button theme_setTitleColor:[self themeValueForKey:key] forState:weak.controlState];
    }
}

- (NSBundle *)themeBundle
{
    if ([_themePath rangeOfString:@"First"].location != NSNotFound)
    {
        return [NSBundle mainBundle];
    }
    else
    {
        return [[NSBundle alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"night" ofType:@"bundle"]];
    }
}

@end