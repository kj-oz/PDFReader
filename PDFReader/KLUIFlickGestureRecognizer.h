//
//  KLUIFlickGestureRecognizer.h
//  KLib UI
//
//  Created by KO on 12/05/22.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

/**
 * 水平または垂直のフリック操作を認識するためのGestureRecognizer
 */
@interface KLUIFlickGestureRecognizer : UIGestureRecognizer
{
    // フリックを認識する方向 （UISwipeGestureRecognizerDirectionの論理和で指定）
    UISwipeGestureRecognizerDirection permittedDirection_;
    
    // 実際にフリックされた方向
    UISwipeGestureRecognizerDirection direction_;
    
    // フリックと認識する最小の移動距離
    CGFloat minmumDistance_;
    
    // フリックと認識する最大のタッチ時間（秒）
    CGFloat maximumDuration_;
    
    // フリック開始時刻
    NSTimeInterval flickStartTime_;
    
    // フリック開始位置
    CGPoint flickStartPoint_;
}

@property (nonatomic, assign) UISwipeGestureRecognizerDirection permittedDirection;
@property (nonatomic, assign) UISwipeGestureRecognizerDirection direction;
@property (nonatomic, assign) CGFloat minimumDistance;
@property (nonatomic, assign) CGFloat maximumDuration;

@end
