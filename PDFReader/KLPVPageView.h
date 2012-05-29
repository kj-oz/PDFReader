//
//  KLPageView.h
//  KLib PageView
//
//  Created by KO on 12/02/02.
//  Copyright (c) 2012年 KO All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KLPVPageViewDataSource.h"
#import "KLPVPageViewDelegate.h"

@class KLPVTiledView;
@class KLPVTagView;

/**
 * 各種ドキュメントの横スクロール型のページ表示を実現するビュー.
 * UIScrollViewを継承し、ページ送りと拡大縮小を可能にする。縮小の下限はページ幅が画面の幅一杯になるサイズ。
 * コンテンツとして、スムースなページ送りを実現するため前後のページも含んだ３ページ分のデータを描画したビューを保持する。
 * このビューは、特定のスケールで描画した画像を拡大・縮小して表示するが、中央のカレントのページのみ、表示スケールなりの
 * 細密な描画を行うTiledViewで２重に持つ。
 * 背景のImageによって、拡大・縮小後のTileViewの再描画時のちらつきを抑える。
 * 任意のページに付箋を複数追加することが出来る。現在(2012/04)のところページの左辺に90度回転した付箋をつけることのみ
 * 可能。付箋の移動／編集／削除も可能。
 * 
 * UIScrollViewをサブクラス化したのは、layoutSubviewsをオーバーライドするため。
 */
@interface KLPVPageView : UIScrollView <UIScrollViewDelegate>
{
    // ページのデータを提供するオブジェクト
    id <KLPVPageViewDataSource> dataSource_;  // Assign
    
    // ページに対する各種操作の処理を受け持つオブジェクト
    id <KLPVPageViewDelegate> pageDelegate_;  // Assign
    
	// スケールに応じて精細な描画を行うタイルレイヤを利用したビュー
    KLPVTiledView* tiledView_;
	
	// 初期化時に中心のページが画面幅いっぱいになるようなスケールで描画された３ページ分の画像を保持するビュー
	UIImageView* backgroundView_;
    
	// 縮小の下限時のスケール（ページ幅=画面幅となる）
    CGFloat minScale_;
    
    // ドキュメントのスケール
	CGFloat scale_;
    
    // 現在選択されている付箋ビュー
    KLPVTagView* selectedTagView_;        // Assign
    
    // 付箋ビューのドラッグを開始したかどうか
    BOOL dragTagStarted_;
    
    // 選択されている付箋ビューを動かせる範囲
    // 付箋ビューは左辺にのみ付き、上下にのみ移動可能な前提
    CGFloat dragTagLimit_[2];
    
    // 付箋が実際に移動したかどうか
    BOOL tagMoved_;
    
    // シングルタップとして扱っていいかどうかを判定するフラグ
    // タッチ開始時にNO、タッチ終了時にYESに設定して0.3秒後の処理開始を待つ
    // 続けてタップされると、NOとなりダブルタップと認識される
    BOOL singleTapped_;
    
    // ダブルタップを待っている状態かどうかのフラグ
    // タッチの開始位置が付箋ビュー上だった場合にYESに設定する
    BOOL waitDoubleTap_;
    
    // 付箋の編集／削除を指示するためのUI
    UIButton* editTagButton_;
    UIButton* deleteTagButton_;
}

@property (nonatomic, assign) id <KLPVPageViewDataSource> dataSource;
@property (nonatomic, assign) id <KLPVPageViewDelegate> pageDelegate;
@property (nonatomic, readonly) CGFloat scale;
@property (nonatomic, assign) KLPVTagView* selectedTagView;
@property (nonatomic, assign) UIImage* editTagImage;
@property (nonatomic, assign) UIImage* deleteTagImage;

/**
 * データ提供オブジェクトを渡す初期化メソッド.
 * @param frame ビューの枠長方形
 * @param renderer データ提供オブジェクト
 * @return 付箋ビュー
 */
- (id)initWithFrame:(CGRect)frame dataSource:(id <KLPVPageViewDataSource>)dataSource;

/**
 * スクロール、拡大・縮小の対象となるコンテンツを初期化する.
 * backgroundViewはこのメソッドの中でのみ作成する.（拡大・縮小されても再構築しない）
 */
- (void)renderPageWithInitialLayout;

/**
 * 新規の付箋ビューを追加し、選択状態にする.
 * @param tagView 追加する付箋ビュー
 */
- (void)addTagView:(KLPVTagView*)tagView;

@end
