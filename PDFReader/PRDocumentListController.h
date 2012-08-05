//
//  PRDocumentListController.h
//  PDFReader
//
//  Created by KO on 11/10/01.
//  Copyright 2011年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KLTVTreeManager;
@class PRDocument;
@class PRTag;
@class PRShelf;

/**
 * ドキュメント一覧画面のコントローラ.
 */
@interface PRDocumentListController : UIViewController <UIPopoverControllerDelegate>
{
    // 呼び出し元への参照
    id delegate_; // Assign
    
    // ツリー情報管理オブジェクト
    KLTVTreeManager* treeManager_;
    
    // 本棚リスト表示の元になったボタン
    UIBarButtonItem* shelfListReason_;
    
    IBOutlet UITableView* tableView_;
    IBOutlet UIBarButtonItem* addButton_;
    IBOutlet UIBarButtonItem* shelfButton_;
    IBOutlet UIBarButtonItem* deleteButton_;
    IBOutlet UIBarButtonItem* moveButton_;
    IBOutlet UIBarButtonItem* detailButton_;    
    
    UIPopoverController* poController_;
}

@property (nonatomic, assign) id delegate;

- (IBAction)addAction;
- (IBAction)shelfAction;
- (IBAction)deleteAction;
- (IBAction)moveAction;
- (IBAction)detailAction;

/**
 * 指定のステータスのラベルの色を返す.
 * @param status ドキュメントのステータス
 * @return 色
 */
+ (UIColor*)labelColorAtStatus:(NSUInteger)status;

/**
 * （カレントの本棚に含まれる）指定のドキュメントをドキュメント画面で表示する.
 * @param doc 対象ドキュメント
 * @param animated アニメーションを伴うかどうか
 */
- (void)showDocument:(PRDocument*)doc animated:(BOOL)animated;

/**
 * （カレントの本棚に含まれる）指定のドキュメントの指定のページをドキュメント画面で表示する.
 * @param doc 対象ドキュメント
 * @param tag 対象付箋
 * @param animated アニメーションを伴うかどうか
 */
- (void)showDocument:(PRDocument*)doc atTag:(PRTag*)tag animated:(BOOL)animated;

/**
 * カレントの本棚を変更する.
 * @param shelf 本棚
 */
- (void)changeShelf:(PRShelf*)shelf;

@end
