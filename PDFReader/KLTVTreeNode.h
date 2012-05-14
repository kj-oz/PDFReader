//
//  KLTVTreeNode.h
//  KLib TreeView
//
//  Created by KO on 12/02/17.
//  Copyright (c) 2012年 KO All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KLTVTreeNode.h"

/**
 * ツリービューの各要素を抽象化したデータ.
 * ルートノード（実データとは結びつかない概念上の最上位ノード）以下にツリー状に実ノードを保持する.
 */
@interface KLTVTreeNode : NSObject 
{
    // 実際のデータ
	id data_;
    
    // 親ノード
	KLTVTreeNode *parent_;      // Assign
    
    // 子ノード
	NSMutableArray *children_;
    
    // 展開されているか（子がない場合もYES）
	BOOL expanded_;
    
    // 全可視ノードの単純配列が正しい状態かどうか
    BOOL valid_;
}

@property (nonatomic, retain) id data;
@property (nonatomic, retain) KLTVTreeNode *parent;
@property (nonatomic, getter = isExpanded) BOOL expanded;
@property (nonatomic, readonly, getter = isValid) BOOL valid;

/**
 * 自分がルートノードかどうか.
 */
@property (nonatomic, readonly) BOOL isRoot;

/**
 * 子供が存在するかどうか.
 */
@property (nonatomic, readonly) BOOL hasChild;

/**
 * ツリー内でのレベル、ルートノードは-1、最上位ノードが0
 */
@property (nonatomic, readonly) NSUInteger level;

/**
 * 可視の状態の全子孫ノード数（自分自身は含まない）
 */
@property (nonatomic, readonly) NSUInteger visibleDescendantCount;

/**
 * 自分とその可視の子孫を全て含む単純配列
 */
@property (nonatomic, readonly) NSArray* flattenElements;

/**
 * 与えられた実データでノードを初期化する.
 * @param data 実データ
 * @return ノード
 */
- (id)initWithData:(id)data;

/**
 * 指定の位置の子ノードを得る.
 * @param index 位置
 * @return 子ノード
 */
- (KLTVTreeNode*)childAtIndex:(NSUInteger)index;

/**
 * 指定の子ノードの位置を得る.
 * @param child 子ノード
 * @return 位置
 */
- (NSUInteger)indexOfChild:(KLTVTreeNode*)child;

/**
 * 子のノードを兄弟の末尾に追加する.
 * @param child 子ノード
 */
- (void)addChild:(KLTVTreeNode*)child;

/**
 * 子のノードを指定の位置に追加する.
 * @param child 子ノード
 * @param index 追加位置
 */
- (void)insertChild:(KLTVTreeNode*)child atIndex:(NSUInteger)index;

/**
 * 指定の位置の子ノードを除外する.
 * 他にそのノードがどこからも参照されていなければ、そのノードはdeallocされる.
 * @param index 位置
 */
- (void)removeChildAtIndex:(NSUInteger)index;

/**
 * 指定の子ノードを除外する.
 * 他にそのノードがどこからも参照されていなければ、そのノードはdeallocされる.
 * @param child 子ノード
 */
- (void)removeChild:(KLTVTreeNode*)child;

/**
 * 全ての子ノードを除外する.
 * 他にそれらのノードがどこからも参照されていなければ、それらのノードはdeallocされる.
 */
- (void)removeAllChildren;

/**
 * 親ノードから除外する.
 * 他に自分自身がどこからも参照されていなければ、deallocされる.
 */
- (void)removeFromParent;

@end
