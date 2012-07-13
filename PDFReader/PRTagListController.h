//
//  PRTagListController.h
//  PDFReader
//
//  Created by KO on 12/02/26.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PRTag;

/**
 * 付箋一覧画面（ポップオーバー）のコントローラ.
 */
@interface PRTagListController : UIViewController
{
    // 呼び出し元への参照
    id delegate_; // Assign
    
    // ドキュメントに属する全付箋の配列
    NSMutableArray* tags_;
    
    // 選択された付箋
    PRTag* selectedTag_;
    
    IBOutlet UITableView* tableView_;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, readonly) PRTag* selectedTag;

@end

/**
 * 付箋一覧画面のデリゲート
 */
@interface NSObject (PRTagListControllerDelegate)

/**
 * 付箋一覧画面で付箋が選択された場合に呼び出されるハンドラ.
 * @param controller 付箋一覧画面のコントローラ
 */
- (void)tagListControllerTagDidSelect:(PRTagListController*)controller;

@end
