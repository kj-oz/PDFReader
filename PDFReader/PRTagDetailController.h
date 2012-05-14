//
//  PRTagDetailController.h
//  PDFReader
//
//  Created by KO on 12/01/12.
//  Copyright (c) 2012年 KO All rights reserved.
//

#import <UIKit/UIKit.h>

@class PRTag;

/**
 * 付箋追加／編集画面（ポップオーバー）のコントローラ.
 */
@interface PRTagDetailController : UIViewController
{
    // 呼び出し元への参照
    id delegate_; // Assign
    
    // 追加か編集か
    BOOL new_;
    
    // 対象のTabデータ
    PRTag* tag_;
    
    // 色セクションで選択されている行の番号
    // 通常はプリセット色のインデックスと一致するが、既存Tabに独自色が設定されている場合先頭に独自色が追加される
    NSUInteger selectedColorRow_;
    
    // 既存Tabで独自色が定義されているか
    BOOL originalColor_;
    
    IBOutlet UITableView* tableView_;
    IBOutlet UIBarButtonItem* cancelButton_;
    IBOutlet UIBarButtonItem* doneButton_;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, readonly, getter = isNew) BOOL new;
@property (nonatomic, retain) PRTag* tag;
@property (nonatomic, readonly, getter = hasOriginalColor) BOOL originalColor;

- (IBAction)cancelAction;
- (IBAction)doneAction;

@end

/**
 * 付箋追加／編集画面のデリゲート
 * 確定、キャンセルを監視する
 */
@interface NSObject (PRTagDetailControllerDelegate)

/**
 * 付箋追加／編集画面がキャンセルされた場合に呼び出されるハンドラ.
 * @param controller 付箋追加／編集画面のコントローラ
 */
- (void)tagDetailControllerDidCancel:(PRTagDetailController*)controller;

/**
 * 付箋追加／編集画面で確定ボタンが押された場合に呼び出されるハンドラ.
 * @param controller 付箋追加／編集画面のコントローラ
 */
- (void)tagDetailControllerDidSave:(PRTagDetailController*)controller;

@end
