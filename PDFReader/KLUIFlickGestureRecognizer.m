//
//  KLUIFlickGestureRecognizer.m
//  KLib UI
//
//  Created by KO on 12/05/22.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import "KLUIFlickGestureRecognizer.h"

@interface KLUIFlickGestureRecognizer (Private)

/**
 * 各種initメソッドから呼びだされる共通の初期化処理.
 */
- (void)init_;

@end

@implementation KLUIFlickGestureRecognizer

@synthesize permittedDirection = permittedDirection_;

@synthesize direction = direction_;

@synthesize minimumDistance = minmumDistance_;

@synthesize maximumDuration = maximumDuration_;

- (void)init_
{
    minmumDistance_ = 30.0;
    maximumDuration_ = 0.6;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self init_];
    }
    return self;
}

- (id)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self) {
        [self init_];
    }
    return self;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    KLDBGPrintMethodName("▼ ");
    [super touchesBegan:touches withEvent:event];
    
    flickStartPoint_ = [self locationInView:self.view];
    flickStartTime_ = [NSDate timeIntervalSinceReferenceDate];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    KLDBGPrintMethodName("▼ ");
    [super touchesEnded:touches withEvent:event];
    
    // ジェスチャー開始時からの時間と距離
    CGPoint pt = [self locationInView:self.view];
    CGFloat dx = pt.x - flickStartPoint_.x;
    CGFloat dy = pt.y - flickStartPoint_.y;    
    CGFloat dt = [NSDate timeIntervalSinceReferenceDate] - flickStartTime_;
    
    KLDBGPrint(" dx:%.1f dy:%.1f dt:%.3f\n", dx, dy, dt);
    direction_ = 0;
    if (dt > maximumDuration_ || (ABS(dx) < minmumDistance_ && ABS(dy) < minmumDistance_)
                              || (ABS(dx) > minmumDistance_ && ABS(dy) > minmumDistance_)) {
        // 時間が長過ぎる、移動していない、斜めに移動している：認識対象外
    } else {
        if (permittedDirection_ & UISwipeGestureRecognizerDirectionRight && dx > minmumDistance_) {
            direction_ = UISwipeGestureRecognizerDirectionRight;
        } else if (permittedDirection_ & UISwipeGestureRecognizerDirectionLeft && dx < -minmumDistance_) {
            direction_ = UISwipeGestureRecognizerDirectionLeft;
        } else if (permittedDirection_ & UISwipeGestureRecognizerDirectionUp && dy < -minmumDistance_) {
            direction_ = UISwipeGestureRecognizerDirectionUp;
        } else if (permittedDirection_ & UISwipeGestureRecognizerDirectionDown && dy > minmumDistance_) {
            direction_ = UISwipeGestureRecognizerDirectionDown;
        }
    }
    
    KLDBGPrint(" dir:%d\n", direction_);
    if (direction_) {
        self.state = UIGestureRecognizerStateRecognized;
        return;
    }
    
    self.state = UIGestureRecognizerStateFailed;
}

@end
