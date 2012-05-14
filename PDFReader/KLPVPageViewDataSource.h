//
//  KLPVPageViewDataSource.h
//  KLib PageView
//
//  Created by KO on 12/02/02.
//  Copyright (c) 2012年 KO All rights reserved.
//

#import <Foundation/Foundation.h>

@class KLPVTagView;

/**
 * PageViewに対して必要なデータを提供するオブジェクト.
 */
@protocol KLPVPageViewDataSource <NSObject>

// PageViewの中央ページに表示するページの番号（最初のページが0）
@property (nonatomic, assign) NSUInteger currentPageIndex;

// ページの初期表示時の表示対象の座標（付箋の中央、等）
@property (nonatomic, assign) CGPoint targetPoint;

// ページ数
@property (nonatomic, readonly) NSUInteger numPages;

// 前後のページを含む３ページ分全体を含む長方形のサイズ、ピクセル座標
@property (nonatomic, readonly) CGSize totalSize;

// totalSizeの長方形の左上を原点とした場合の各ページの枠長方形、ピクセル座標.
@property (nonatomic, readonly) CGRect previousPageFrame;
@property (nonatomic, readonly) CGRect currentPageFrame;
@property (nonatomic, readonly) CGRect nextPageFrame;

/**
 * 指定の位置のページの枠長方形を返す.
 * @param position ページ位置、0=前、1=中央、2=後
 * @return ページの枠長方形
 */
- (CGRect)pageFrameOfPosition:(NSUInteger)position;

/**
 * 保持している3ページの内容を与えられたContextに描画する.
 * 原点は|totalSize|長方形の左上にあるものとする.
 * @param context 対象のContext
 * @param scale 描画スケール
 */
- (void)renderPagesWithContext:(CGContextRef)context scale:(CGFloat)scale;

/**
 * 保持している中央ページの内容を与えられたContextに描画する.
 * 原点は中央ページの左上にあるものとする.
 * @param context 対象のContext
 * @param scale 描画スケール
 */
- (void)renderCurrentPageWithContext:(CGContextRef)context scale:(CGFloat)scale;

/**
 * 保持している3ページに対する付箋ビューを生成する.
 * 選択されている付箋に対応する付箋ビューが含まれていた場合には、その付箋ビューのselectedはYESに設定される
 * @param scale ページの描画スケール
 * @return 生成された付箋ビューの配列、親ビューへの追加はしていない状態
 */
- (NSArray*)createTagViewsOfPagesWithScale:(CGFloat)scale;

/**
 * 与えられた付箋ビューの内容を|context|に対して描画する.
 * 原点は付箋ビューの左上にあるものとする.
 * @param tagView 付箋ビュー
 * @param context 対象のContext
 */
- (void)renderTagView:(KLPVTagView*)tagView WithContext:(CGContextRef)context;

/**
 * 付箋ビューのドラッグ移動後に呼び出される.
 * 与えられた付箋ビューに対応する付箋の位置情報の更新などを行う.
 * @param tagView 付箋ビュー
 */
- (void)tagViewDidMove:(KLPVTagView*)tagView;

/**
 * 付箋ビューの選択後に呼び出される.
 * @param tagView 付箋ビュー
 */
- (void)tagViewDidSelect:(KLPVTagView*)tagView;

/**
 * 与えられた付箋ビューを削除する.
 * @param tagView 付箋ビュー
 */
- (void)deleteTagView:(KLPVTagView*)tagView;

@end
