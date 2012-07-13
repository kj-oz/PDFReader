//
//  KLTVTreeManager.m
//  PDFReader
//
//  Created by KO on 12/02/09.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import "KLTVTreeManager.h"
#import "KLTVTreeNode.h"
#import "KLTVTreeViewCell.h"

@interface KLTVTreeManager (Private)

/**
 * 可視ノードの単純配列を正常な状態にする.
 */
- (void)ensureFlattenedElements_;

@end

@implementation KLTVTreeManager

@synthesize expandedIcon = expandedIcon_;
@synthesize closedIcon = closedIcon_;
@synthesize handleWidth = handleWidth_;
@synthesize levelIndent = levelIndent_;

#pragma mark - アクセッサ

- (NSUInteger)visibleNodeCount 
{
    [self ensureFlattenedElements_];
    return [flattenedElements_ count];
}

- (void)ensureFlattenedElements_
{
    if (!root_.isValid) {
        [flattenedElements_ release], flattenedElements_ = nil;
        flattenedElements_ = [[root_ flattenElements] retain];
    }    
}

#pragma mark - 初期化

- (id)init {
	self = [super init];
	if (self) {
        root_ = [[KLTVTreeNode alloc] initWithData:nil];
        
        // 各種プロパティのデフォルト値
        expandedIcon_ = [[UIImage imageNamed:@"KLTVExpandedNode.png"] retain];
        closedIcon_ = [[UIImage imageNamed:@"KLTVClosedNode.png"] retain];
        handleWidth_ = 44.0;
        levelIndent_ = 32.0;
	}
	return self;
}

- (void) dealloc {
	[flattenedElements_ release], flattenedElements_ = nil;
    [root_ release], root_ = nil;
    [expandedIcon_ release], expandedIcon_ = nil;
    [closedIcon_ release], closedIcon_ = nil;
	
	[super dealloc];
}

#pragma mark - ノード操作

- (KLTVTreeNode*)nodeAtIndex:(NSUInteger)index
{
    [self ensureFlattenedElements_];
    return [flattenedElements_ objectAtIndex:index];
}

- (NSUInteger)indexOfNode:(KLTVTreeNode*)node
{
    [self ensureFlattenedElements_];
    return [flattenedElements_ indexOfObject:node];
}

- (void)addTopNode:(KLTVTreeNode*)node
{
    [root_ addChild:node];
}

- (void)removeTopNode:(KLTVTreeNode*)node
{
    [root_ removeChild:node];
}

- (void)removeTopNodes:(NSArray*)nodes
{
    [root_ removeChildren:nodes];
}

- (void)clear
{
	[flattenedElements_ release], flattenedElements_ = nil;
    [root_ removeAllChildren];
}

#pragma mark - セルの整形

- (void)setupCell:(KLTVTreeViewCell*)cell forNode:(KLTVTreeNode*)node
{
    cell.indent = node.level * levelIndent_;
    UIImage* handleImage = nil;
    if (node.hasChild) {
        handleImage = node.expanded ? expandedIcon_ : closedIcon_;
    }
    [cell setHandleImage:handleImage withWidth:handleWidth_];
}

@end
