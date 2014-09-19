//
//  TBStationAnnotationView.m
//  telobike
//
//  Created by Elad Ben-Israel on 10/15/13.
//  Copyright (c) 2013 Elad Ben-Israel. All rights reserved.
//

#import "TBStationAnnotationView.h"
#import "TBStation.h"
#import "TBObserver.h"

@interface TBStationAnnotationView ()

@property (strong, nonatomic) TBStation* station;
@property (strong, nonatomic) TBObserver *markerImageObserver;

@end
@implementation TBStationAnnotationView

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.station = nil;
}

- (TBStation*)station {
    return (TBStation*)self.annotation;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    CGRect startBounds;
    CGRect endBounds;
    
    if (selected) {
        startBounds = [self deselectedBounds];
        endBounds = [self selectedBounds];
    }
    else {
        startBounds = [self selectedBounds];
        endBounds = [self deselectedBounds];
    }
    
    if (animated) {
        CABasicAnimation* a = [CABasicAnimation animationWithKeyPath:@"bounds"];
        a.fromValue = [NSValue valueWithCGRect:startBounds];
        a.toValue = [NSValue valueWithCGRect:endBounds];
        a.duration = 0.25f;
        a.removedOnCompletion = NO;
        a.fillMode = kCAFillModeForwards;
        a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [self.layer addAnimation:a forKey:@"B"];
    }
    else {
        self.layer.bounds = endBounds;
        [self.layer removeAllAnimations];
    }
}

- (CGRect)selectedBounds {
    CGRect r = CGRectZero;
    r.size = self.station.markerImage.size;
    return r;
}

- (CGRect)deselectedBounds {
    CGRect r = [self selectedBounds];
    r.size.width = 0.5 * r.size.width;
    r.size.height = 0.5 * r.size.height;
    return r;
}

- (void)setAnnotation:(id<MKAnnotation>)annotation {
    [super setAnnotation:annotation];
    self.station = annotation;
    self.markerImageObserver = [TBObserver observerForObject:self.station keyPath:@"lastUpdateTime" block:^{
        self.layer.contents = (id)[self.station.markerImage CGImage];
    }];
    self.layer.bounds = [self deselectedBounds];
}

@end
