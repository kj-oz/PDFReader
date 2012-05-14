//
//  KLPVTiledView.h
//  KLib PageView
//
//  Created by KO on 11/10/08.
//  Copyright 2011年 KO All rights reserved.
//

#import <UIKit/UIKit.h>

#import "KLPVPageViewDataSource.h"

/**
 * ページを必要な範囲だけ効率よくきれいに描画するためのタイルレイヤを使用したビュー.
 */
@interface KLPVTiledView : UIView
{
    // ページのデータを提供するオブジェクト
    id <KLPVPageViewDataSource> dataSource_;  // Assign
    
    // ページのスケール
    CGFloat scale_;
}

/**
 * データ提供オブジェクトを渡す初期化メソッド.
 * @param dataSource データ提供オブジェクト
 * @return TiledView
 */
- (id)initWithFrame:(CGRect)frame dataSource:(id <KLPVPageViewDataSource>)dataSource;

@end
