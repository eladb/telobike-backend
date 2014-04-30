//
//  JVObserver.m
//  Jovie
//
//  Created by Elad Ben-Israel on 4/24/14.
//  Copyright (c) 2014 Jovie Inc. All rights reserved.
//

#import "JVObserver.h"

@interface JVObserver ()

@property (strong, nonatomic) id object;
@property (strong, nonatomic) NSString *keyPath;
@property (strong, nonatomic) void(^block)(void);

@end

@implementation JVObserver

- (instancetype)initWithObject:(id)object keyPath:(NSString *)keyPath block:(void(^)(void))block
{
    if (!object || keyPath.length == 0) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.object = object;
        self.keyPath = keyPath;
        self.block = block;
        [self.object addObserver:self forKeyPath:self.keyPath options:NSKeyValueObservingOptionInitial context:nil];
    }
    return self;
}

+ (instancetype)observerForObject:(id)object keyPath:(NSString *)keyPath block:(void(^)(void))block
{
    return [[JVObserver alloc] initWithObject:object keyPath:keyPath block:block];
}

- (void)dealloc
{
    [self.object removeObserver:self forKeyPath:self.keyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.block) {
        dispatch_async(dispatch_get_main_queue(), self.block);
    }
}

@end