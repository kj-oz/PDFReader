//
//  PRDocumentDetailController.h
//  PDFReader
//
//  Created by KO on 12/03/13.
//  Copyright (c) 2012年 KO All rights reserved.
//

#import <UIKit/UIKit.h>

@class PRDocument;

/**
 * ドキュメント追加／編集画面（ポップオーバー）のコントローラ.
 */
@interface PRDocumentDetailController : UIViewController <UITextFieldDelegate>
{
    // 呼び出し元への参照
    id delegate_; // Assign
    
    // 追加か編集か
    BOOL new_;
    
    // 対象のDocumnet
    PRDocument* document_;
    
    // ダウンロード元URL
    NSString* url_;
    
    IBOutlet UITableView* tableView_;
    IBOutlet UIBarButtonItem* cancelButton_;
    IBOutlet UIBarButtonItem* doneButton_;
    IBOutlet UIBarButtonItem* downloadButton_;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, readonly, getter = isNew) BOOL new;
@property (nonatomic, retain) PRDocument* document;

- (IBAction)cancelAction;
- (IBAction)doneAction;
- (IBAction)downloadAction;

@end

/**
 * ドキュメント追加／編集画面のデリゲート
 * 確定、キャンセルを監視する
 */
@interface NSObject (PRDocumnetDetailControllerDelegate)

/**
 * ドキュメント追加／編集画面がキャンセルされた場合に呼び出されるハンドラ.
 * @param controller ドキュメント追加／編集画面のコントローラ
 */
- (void)documentDetailControllerDidCancel:(PRDocumentDetailController*)controller;

/**
 * ドキュメント追加／編集画面で確定（ダウンロード）ボタンが押された場合に呼び出されるハンドラ.
 * @param controller ドキュメント追加／編集画面のコントローラ
 */
- (void)documentDetailControllerDidSave:(PRDocumentDetailController*)controller;

@end
