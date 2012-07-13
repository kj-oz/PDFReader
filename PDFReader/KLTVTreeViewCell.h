//
//  KLTVTreeViewCell.h
//  KLib TreeView
//
//  Created by KO on 12/02/21.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KLTVTreeManager;

/**
 * テーブルビューをツリービューとして利用する場合に使用するセル用クラス.
 */
@interface KLTVTreeViewCell : UITableViewCell 
{
    // 呼び出し元への参照
    id delegate_; // Assign
    
    // ツリーによってインデントされたビュー
    UIView* indentedView_;
    
    // ツリーを開閉するボタン
    UIButton* handleButton_;

    // 各種のイメージや文字列等を保持するビュー。開閉ハンドルの右側から始まる。（開閉ハンドルは含まない）
    UIView* treeContentView_;
    
    // 主テキストを保持するラベル
	UILabel* textLabel_;
    
    // 補助テキストを保持するラベル
    UILabel* detailTextLabel_;
    
    // 主テキストの左側に表示するアイコン
    UIImageView* imageView_;
    
    // セルの左端から見た、開閉ボタン左端の座標
    CGFloat indent_;
    
    // 開閉ボタン用に確保するスペースの幅
    CGFloat handleWidth_;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, readonly) UIView* treeContentView;
@property (nonatomic, assign) CGFloat indent;

/**
 * 開閉ボタンの状態を設定する.
 * @param handleImage 開閉ボタンに表示するイメージ.
 * @param handleWidth 開閉ボタン用に確保する幅
 */
- (void)setHandleImage:(UIImage *)handleImage withWidth:(CGFloat)handleWidth;

@end

/**
 * ツリービューのノードの開閉に対するデリゲート.
 */
@interface NSObject (KLTVTreeViewDelegate)

/**
 * 開閉ボタン押下時に呼び出される.
 * @param indexPath 対象のセルのindexPath
 */
- (void)treeView:(UITableView*)treeView didTapHandleAtIndexPath:(NSIndexPath*)indexPath;

@end
