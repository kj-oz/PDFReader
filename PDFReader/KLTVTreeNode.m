//
//  KLTVTreeNode.m
//  KLib TreeView
//
//  Created by KO on 12/02/17.
//  Copyright (c) 2012年 KO All rights reserved.
//

#import "KLTVTreeNode.h"

@interface KLTVTreeNode (Private)

/**
 * 全可視ノードの単純配列が正しくない状態であることを設定（不正化）する.
 */
- (void)invaldate_;

@end    

@implementation KLTVTreeNode

@synthesize data = data_;
@synthesize parent = parent_;
@synthesize expanded = expanded_;
@synthesize valid = valid_;

#pragma mark - アクセッサ

- (void)setExpanded:(BOOL)expanded
{
    expanded_ = expanded;
    [self invaldate_];
}

- (BOOL)isRoot {
	return (!parent_);
}

- (BOOL)hasChild {
	return (children_.count > 0);
}

- (NSUInteger)level {
	if (!parent_) return -1;
	
	return [parent_ level] + 1;
}

- (NSUInteger)visibleDescendantCount {
	NSUInteger cnt = 0;
	
    if (expanded_) {
        for (KLTVTreeNode* child in children_) {
            cnt++;
            if (child.hasChild) {
                cnt += child.visibleDescendantCount;
            }
        }
    }
	return cnt;
}

- (NSArray*)flattenElements {
    NSMutableArray* allElements = [[[NSMutableArray alloc] 
                            initWithCapacity:self.visibleDescendantCount+1] autorelease];
    if (!self.isRoot) {
        [allElements addObject:self];
    }
    
    if (expanded_) {
        for (KLTVTreeNode* child in children_) {
            [allElements addObjectsFromArray:child.flattenElements];
        }
    }
    
    valid_ = YES;
	return allElements;
}

#pragma mark - 初期化

- (id)initWithData:(id)data {
	self = [super init];
	if (self) {
		data_ = data;
        [data_ retain];
		expanded_ = YES;
        valid_ = NO;
	}
	
	return self;
}

- (void) dealloc {
	[children_ release], children_ = nil;
    [data_ release], data_ = nil;
	
	[super dealloc];
}

#pragma mark - 状態の不正化

- (void)invaldate_ 
{
    // ルートノードまでさかのぼって不正化する。
    // 全可視ノードの単純配列が正しいかどうかはルートノードのisValidで判定する。
    if (valid_) {
        valid_ = NO;
        [parent_ invaldate_];        
    }
}

#pragma mark - 子ノードの操作

- (KLTVTreeNode*)childAtIndex:(NSUInteger)index
{
    return [children_ objectAtIndex:index];
}

- (NSUInteger)indexOfChild:(KLTVTreeNode*)child
{
    return [children_ indexOfObject:child];
}

- (void)addChild:(KLTVTreeNode*)child 
{
	if (!children_) {
		children_ = [[NSMutableArray alloc] initWithCapacity:1];
	}
    
	child.parent = self;
	[children_ addObject:child];
    [self invaldate_];
}

- (void)insertChild:(KLTVTreeNode*)child atIndex:(NSUInteger)index
{
	child.parent = self;
	[children_ insertObject:child atIndex:index];
    [self invaldate_];
}

- (void)removeChildAtIndex:(NSUInteger)index
{
    [children_ removeObjectAtIndex:index];
    [self invaldate_];
}

- (void)removeChild:(KLTVTreeNode*)child
{
    [children_ removeObject:child];
    [self invaldate_];
}

- (void)removeChildren:(NSArray*)children
{
    [children_ removeObjectsInArray:children];
    [self invaldate_];
}

- (void)removeAllChildren
{
    [children_ removeAllObjects];
    [self invaldate_];
}

- (void)removeFromParent
{
    [parent_ removeChild:self];
}

@end

