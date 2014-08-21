//
//  BIItemManager.m
//
//  Created by ToKoRo on 2013-03-04.
//

#import "BIItemManager.h"
#import "BIItem.h"

static BIItemManager* sharedInstance = nil;

@interface BIItemManager ()
@property (strong) NSMutableDictionary* items;
@end 

@implementation BIItemManager

#pragma mark - Public Interface

- (BIItem*)itemForMethodName:(NSString*)methodName forClass:(Class)class
{
  return [self.items objectForKey:[self keyForMethodName:methodName forClass:class]];
}

- (void)setItem:(BIItem*)item forMethodName:(NSString*)methodName forClass:(Class)class
{
  [self.items setObject:item forKey:[self keyForMethodName:methodName forClass:class]];
}

- (void)removeItemForMethodName:(NSString*)methodName forClass:(Class)class {
  [self removeItemForKey:[self keyForMethodName:methodName forClass:class]];
}

- (void)clear
{
  for (NSString *key in [self.items allKeys]) {
      [self removeItemForKey:key];
  }
}

#pragma mark - Memory Management

- (id)init
{
  if ((self = [super init])) {
    self.items = [NSMutableDictionary dictionary];
  }
  return self;
}

#pragma mark - Private Methods

- (NSString*)keyForMethodName:(NSString*)methodName forClass:(Class)class
{
  return [NSString stringWithFormat:@"%@::%@", NSStringFromClass(class), methodName];
}

- (void)removeItemForKey:(NSString*)key {
  BIItem *item = [self.items objectForKey:key];
  if (!item)
    return;
  [item restoreOriginal];
  [self.items removeObjectForKey:key];
}

#pragma mark - Singleton
  
+ (BIItemManager*)sharedInstance
{
  @synchronized(self) {
    if (nil == sharedInstance) {
      [self new];
    }
  }
  return sharedInstance;
}

+ (id)allocWithZone:(NSZone*)zone
{
  @synchronized(self) {
    if (nil == sharedInstance) {
      sharedInstance = [super allocWithZone:zone];
      return sharedInstance;
    }
  }
  return nil;
}

- (id)copyWithZone:(NSZone*)zone
{
  return self;
}

@end
