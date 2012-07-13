//
//  PRShelfListController.h
//  PDFReader
//
//  Created by KO on 12/06/19.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PRShelf;

/**
 * 本棚一覧画面（ポップオーバー）のコントローラ.
 */
@interface PRShelfListController : UIViewController <UITextFieldDelegate>
{
    // 呼び出し元への参照
    id delegate_; // Assign
    
    // 選択された付箋
    PRShelf* selectedShelf_;
    
    // 新規本棚追加中フラグ
    BOOL adding_;
    
    // 既存本棚の名称変更中フラグ
    BOOL renaming_;
    
    // 削除対象の行
    NSInteger deletingRow_;
    
    IBOutlet UITableView* tableView_;
    IBOutlet UIBarButtonItem* addButton_;
    IBOutlet UIBarButtonItem* endButton_;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, readonly) PRShelf* selectedShelf;

- (IBAction)addAction;
- (IBAction)endAction;

@end

/**
 * 本棚一覧画面のデリゲート
 */
@interface NSObject (PRShelfListControllerDelegate)

/**
 * 本棚一覧画面で本棚が選択された場合に呼び出されるハンドラ.
 * @param controller 本棚一覧画面のコントローラ
 */
- (void)shelfListControllerShelfDidSelect:(PRShelfListController*)controller;

@end
