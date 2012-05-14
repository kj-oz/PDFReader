//
//  KLPVTagView.m
//  KLib PageView
//
//  Created by KO on 11/12/23.
//  Copyright (c) 2011年 KO All rights reserved.
//

#import "KLPVTagView.h"

@implementation KLPVTagView

@synthesize selected = selected_;
@synthesize scale = scale_;

#pragma mark - アクセッサ

- (void)setSelected:(BOOL)selected
{
    selected_ = selected;
    [self setNeedsDisplay];
}

#pragma mark - 初期化

- (id)initWithOrigin:(CGPoint)origin rotation:(NSUInteger)rotation scale:(CGFloat)scale 
                size:(CGSize)size dataSource:(id <KLPVPageViewDataSource>)dataSource
{
    // 拡大されても文字をクリアに表示するため、スケールに関してはAffineTransformは使用せず、大きさなりの描画を行う
    CGRect frame = CGRectMake(origin.x, origin.y, 
                              size.width * scale, size.height * scale);
    self = [super initWithFrame:frame];
    if (self) {
        dataSource_ = dataSource;
        scale_ = scale;
        selected_ = NO;
        
        CGPoint fromPt = CGPointMake(frame.size.width * 0.5, frame.size.height * 0.5);
        CGPoint toPt = CGPointZero;
        switch (rotation) {
            case 0:
                toPt = CGPointMake(fromPt.x, fromPt.y);
                break;
            case 1:
                toPt = CGPointMake(fromPt.y, -fromPt.x);
                break;
            case 2:
                toPt = CGPointMake(-fromPt.x, -fromPt.y);
                break;
            case 3:
                toPt = CGPointMake(-fromPt.y, fromPt.x);
                break;
        }
        CGFloat dx = toPt.x - fromPt.x;
        CGFloat dy = toPt.y - fromPt.y;
        
        // 後から指定する値はその前に設定した変換行列の影響を考慮した値のため、この順番でないと正しい位置に表示されない
        CGAffineTransform at = CGAffineTransformIdentity;
        at = CGAffineTransformTranslate(at, dx, dy);
        // y座標の方向が逆のため、回転も逆
        // NSUIntegerに−をつけるとおかしな数字になるので、実数化してから符号反転
        CGFloat radian = rotation * M_PI / 2.0;
        at = CGAffineTransformRotate(at, -radian);
        self.transform = at;
        
        self.userInteractionEnabled = YES;
        self.clipsToBounds = NO;
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark - 描画処理

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [dataSource_ renderTagView:self WithContext:context];
}

// TagView側でドラッグを処理するには以下を有効にすれば良いが、ScrollViewとの併用は難しいので全てscrollView側で処理
//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    CGPoint pt = [[touches anyObject] locationInView:self];
//    CGPoint prevPt = [[touches anyObject] previousLocationInView:self];
//    self.transform = CGAffineTransformTranslate(self.transform, pt.x - prevPt.x, 0.0);    
//}

@end
