//
//  PRDocumentController.h
//  PDFReader
//
//  Created by KO on 11/10/01.
//  Copyright 2011年 KO All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KLPVPageViewDelegate.h"

@class PRPageController;
@class KLPVPageView;

/**
 * ドキュメント画面のコントローラ.
 */
@interface PRDocumentController : UIViewController 
                <KLPVPageViewDelegate, UIPopoverControllerDelegate, UIAlertViewDelegate>
{
    // 呼び出し元への参照
    id delegate_; // Assign
    
    // ページ間のスクロール、拡大・縮小をサポートするビュー
    KLPVPageView* pageView_;
    
    // PDFの内容と各種注記の描画処理を行うオブジェクト
    PRPageController* pageController_;
    
    // フルスクリーン状態かどうかのフラグ
    BOOL fullScreen_;
    
    // フルスクリーン切換え用タイマ
    NSTimer* fullScreenTimer_;
    
    // ページ変更用スライダー
    UISlider* pageSlider_;
    
    // スライダーをスライド中かどうかのフラグ
    BOOL sliding_;
    
    // ページ番号表示ラベル
    UILabel* pageLabel_;
    
    IBOutlet UIBarButtonItem* addButton_;
    UIPopoverController* poController_;
}

@property (nonatomic, assign) id delegate;

// ページ初期表示時の表示対象位置
@property (nonatomic, assign) CGPoint targetPoint;

- (IBAction)addTagAction:(id)sender;

@end