//
//  KLTVTreeManager.h
//  PDFReader
//
//  Created by KO on 12/02/09.
//  Copyright (c) 2012年 KO All rights reserved.
//

#import <Foundation/Foundation.h>

@class KLTVTreeNode;
@class KLTVTreeViewCell;

/**
 * ツリービューのノード群を管理するクラス.
 */
@interface KLTVTreeManager : NSObject
{
    // ツリービューのルートノード（実データとは結びつかない概念上の最上位ノード）
    KLTVTreeNode* root_;
    
    // 全可視ノードの単純配列
	NSArray* flattenedElements_;
    
    // 展開中のノードの開閉アイコン
    UIImage* expandedIcon_;
    
    // 閉じているノードの開閉アイコン
    UIImage* closedIcon_;
    
    // 開閉アイコンのスペースの幅
    NSUInteger handleWidth_;
    
    // ツリーのⅠレベルのインデント幅
    NSUInteger levelIndent_;
}

@property (nonatomic, retain) UIImage* expandedIcon;
@property (nonatomic, retain) UIImage* closedIcon;
@property (nonatomic, assign) NSUInteger handleWidth;
@property (nonatomic, assign) NSUInteger levelIndent;

/**
 * 可視ノードの数
 */
@property (nonatomic, readonly) NSUInteger visibleNodeCount;

/**
 * 指定のインデックスの可視なノードを得る.
 * @param index 可視なノードの中のインデックス
 * @return ノード
 */
- (KLTVTreeNode*)nodeAtIndex:(NSUInteger)index;

/**
 * 指定のノードに対する（可視なノードの中の）インデックスを得る.
 * @param ノード
 * @return 可視なノードの中のインデックス
 */
- (NSUInteger)indexOfNode:(KLTVTreeNode*)node;

/**
 * 最上位のノードを追加する.
 * @param node ノード
 */
- (void)addTopNode:(KLTVTreeNode*)node;

/**
 * 最上位のノードを削除する.
 * @param node ノード
 */
- (void)removeTopNode:(KLTVTreeNode*)node;

/**
 * 最上位の複数のノードを削除する.
 * @param nodes ノードの配列
 */
- (void)removeTopNodes:(NSArray*)nodes;

/**
 * 全てのノードをクリアする.
 */
- (void)clear;

/**
 * 与えられたセルに対して、与えられたノードの情報を元にツリービューに関する設定（開閉ボタン、インデント）を行う.
 * @param cell ツリービュー用セル
 * @param node ノード
 */
- (void)setupCell:(KLTVTreeViewCell*)cell forNode:(KLTVTreeNode*)node;

@end
