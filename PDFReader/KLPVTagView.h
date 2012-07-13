//
//  KLPVTagView.h
//  KLib PageView
//
//  Created by KO on 11/12/23.
//  Copyright (c) 2011年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "KLPVPageViewDataSource.h"

/**
 * ページに添付する付箋を表現するビュー.
 */
@interface KLPVTagView : UIView
{
    // PageViewのデータを提供するオブジェクト
    id <KLPVPageViewDataSource> dataSource_;      // Assign
    
    // 描画スケール（拡大時に描画が荒くならないように、画面のスケールに応じて描画内容を更新する）
    CGFloat scale_;
    
    // 選択されているかどうか
    BOOL selected_;
}

@property (nonatomic, readonly) CGFloat scale;
@property (nonatomic, assign) BOOL selected;

/**
 * 指定の位置、大きさ、回転、縮尺の付箋ビューを初期化する.
 * @param origin 親ビューの座標系上での原点
 * @param rotation 回転（0:水平（上が外側）、1:左が外側、2:下が外側、3:右が外側)
 * @param scale 縮尺
 * @param size 親ビューの座標系上でのサイズ
 * @param dataSource データ提供オブジェクト
 * @return 付箋ビュー
 */
- (id)initWithOrigin:(CGPoint)origin rotation:(NSUInteger)rotation scale:(CGFloat)scale 
                size:(CGSize)size dataSource:(id <KLPVPageViewDataSource>)dataSource; 

@end
