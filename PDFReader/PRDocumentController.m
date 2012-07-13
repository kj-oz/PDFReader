//
//  PRDocumentController.m
//  PDFReader
//
//  Created by KO on 11/10/01.
//  Copyright 2011年 KO. All rights reserved.
//

#import "PRDocumentController.h"
#import "PRPageController.h"
#import "PRDocumentManager.h"
#import "PRDocument.h"
#import "KLPVPageView.h"
#import "PRTagDetailController.h"
#import "PRTagListController.h"
#import "PRTag.h"
#import "KLPVTagView.h"

@interface PRDocumentController (Private)

/**
 * 各種initメソッドから呼びだされる共通の初期化処理.
 */
- (void)init_;

/**
 * ナビゲーションコントローラのアルファを変化させることでフルスクリーンの設定・解除を行う.
 * @param fullScreen フルスクリーンにするかどうか
 */
- (void)setFullScreen_:(BOOL)fullScreen;

/**
 * 画面をフルスクリーン化する.
 */
- (void)setFullScreen_;

/**
 * ３秒後にナビゲーションバーを透明化するタイマーを開始する.
 * 既にタイマーが動作していた場合、そちらは一度破棄し新たに3秒タイマーを仕掛ける
 */
- (void)startFullScreenTimer_;

/**
 * ナビゲーションバー透明化タイマーが動作中であれば止める.
 */
- (void)stopFullScreenTimer_;

/**
 * ツールバーの設定を行う.
 */
- (void)setupToolbar_;

/**
 * スライダーのvalueChangeのターゲット.
 * @param sender スライダー
 */
- (void)sliderDidSlide_:(id)sender;

/**
 * アクションボタン押下時のターゲット.
 * @param sender アクションボタン
 */
- (void)actionButtonDidPush_:(id)sender;

/**
 * 付箋の追加／編集画面をPopoverで表示する.
 * @param tagView 対象の付箋を表示している付箋ビュー、追加時はnil
 */
- (void)showTagDetailPopoverOfTagView_:(KLPVTagView*)tagView;

/**
 * 付箋の一覧画面をPopoverで表示する.
 * @param sender 表示のきっかけになったボタン
 */
- (void)showTagListPopover_:(id)sender;

/**
 * 各種のPopover画面を強制的に隠す.
 */
- (void)dismissPopover_;

@end

@implementation PRDocumentController

@synthesize delegate = delegate_;

#pragma mark - プロパティ

- (void)setTargetPoint:(CGPoint)targetPoint
{
    pageController_.targetPoint = targetPoint;
}

- (CGPoint)targetPoint
{
    return pageController_.targetPoint;
}

#pragma mark - 初期化

- (void)init_
{
    // 描画オブジェクトを生成し、前回表示していたページを設定
    pageController_ = [[PRPageController alloc] init];
    pageController_.currentPageIndex = 
        [PRDocumentManager sharedManager].currentDocument.currentPageIndex;
}

- (id)init
{
    return [self initWithNibName:@"Document" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self init_];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self init_];
    }
    return self;
}

- (void)dealloc
{
    KLDBGPrintMethodName("▼ ");
    [self stopFullScreenTimer_];

    [pageView_ removeFromSuperview];
    [pageView_ release], pageView_ = nil;
    [pageController_ release], pageController_ = nil;
    [pageSlider_ release], pageSlider_ = nil;
    [pageLabel_ release], pageLabel_ = nil;
    [poController_ release], poController_ = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // ビューの解放
    [super didReceiveMemoryWarning];
    
    // その他のリソースの解放
}

#pragma mark - ビューのライフサイクル

- (void)viewDidLoad
{
    KLDBGPrintMethodName("▼ ");
    KLDBGPrint(" orientation:%s size:%s\n", 
               UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? "Landscape" : "Portrate", 
               KLDBGSize(self.view.bounds.size));

    [super viewDidLoad];
    [self.view setAutoresizesSubviews:YES];
    
    // ステータスバーを半透明にし、コンテンツを画面一杯に描画可能にするよう試みた。
    // UIKit詳解には、viewWillAppearで呼ぶように書いてあるがpageViewのサイズに影響すると思われるためここで記述。
    // しかしどうやらiPadではステータスバーの半透明化はできないらしいのでコメントアウト
    // [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
    // self.wantsFullScreenLayout = YES;
    
    // pageView_は画面の回転時に必要なため、コントローラ参照を保持する
    pageView_ = [[KLPVPageView alloc] initWithFrame:self.view.frame dataSource:pageController_];
    [self.view addSubview:pageView_];
    
    // pageView_の設定
    pageView_.autoresizingMask = 
        UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    pageView_.showsVerticalScrollIndicator = NO;
    pageView_.showsHorizontalScrollIndicator = NO;
    pageView_.bouncesZoom = YES;
    pageView_.decelerationRate = UIScrollViewDecelerationRateFast;
    pageView_.delegate = pageView_;
    pageView_.backgroundColor = [UIColor grayColor];
    
    // pageView(scrollView)のdelegateは自分自身のため、別の変数を設けて設定。singleTapを取得するため
    pageView_.pageDelegate = self;

    // 予めデバイスが水平の状態の場合、初回以外はdidRotateFomInterfaceOrientationが呼ばれないため
    // Viewの初期化時に横対応をしておく必要がある
    // ここではorientationは横、frameは縦の状態だが、viewWillApearではframeも横になるので、
    // pageView_のコンテンツの初期化はviewWillApearで行う（pageViewも同じ方向になっている）
    // [pageView_ renderPageWithInitialLayout];
   
    // タッチ検出のために色を付ける
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidUnload
{
    KLDBGPrintMethodName("▼ ");
    [super viewDidUnload];
    [addButton_ release], addButton_ = nil;
    
    [pageView_ removeFromSuperview];
    [pageView_ release], pageView_ = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    KLDBGPrintMethodName("▼ ");
    KLDBGPrint(" orientation:%s size:%s\n", 
               UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? "Landscape" : "Portrate", 
               KLDBGSize(self.view.bounds.size));
    
    [super viewWillAppear:animated];
    fullScreen_ = NO;
    sliding_ = NO;
    
    // ナビゲーションバーを半透明化し、フルスクリーン可能に
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.toolbarHidden = NO;
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    self.navigationController.toolbar.translucent = YES;
    
    // ナビゲーションアイテムの設定を行う
    [self.navigationItem setRightBarButtonItem:addButton_ animated:animated];

    // ツールバーの設定
    [self setupToolbar_];
    
    // 予めデバイスが水平の状態への対応でここで実施（viewDidLoad参照）
    // pageView_のコンテンツの描画
    [pageView_ renderPageWithInitialLayout];
    
    // タイマー開始
    [self startFullScreenTimer_];
}

- (void)viewWillDisppear:(BOOL)animated
{
    KLDBGPrintMethodName("▼ ");
    [super viewWillDisappear:animated];

    // タイマー後始末（今回は３秒後に自動的に消えるけれど、、、）
    [self stopFullScreenTimer_];
}

#pragma mark - フルスクリーン化

- (void)setFullScreen_:(BOOL)fullScreen
{
    fullScreen_ = fullScreen;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    self.navigationController.navigationBar.alpha = fullScreen ? 0.0 : 1.0;
    self.navigationController.toolbar.alpha = fullScreen ? 0.0 : 1.0;
    [UIView commitAnimations];
    
    if (!fullScreen) {
        [self startFullScreenTimer_];
        
        // フルスクリーン状態で回転させた後でフルスクリーンを解除するとナビゲーションバーの位置がおかしくなるバグ対応
        [self.navigationController setNavigationBarHidden:YES animated:NO];
        [self.navigationController setToolbarHidden:YES animated:NO];
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [self.navigationController setToolbarHidden:NO animated:NO];
    }
}

- (void)setFullScreen_
{
    // スタート時retainしたため、ここでリリース
    [fullScreenTimer_ release], fullScreenTimer_ = nil;
    [self setFullScreen_:YES];
}

- (void)startFullScreenTimer_
{
    [self stopFullScreenTimer_];
    fullScreenTimer_ = [NSTimer scheduledTimerWithTimeInterval:3.0f target:self 
                            selector:@selector(setFullScreen_:) userInfo:nil repeats:NO];
    // Timerを中断する処理を確実にするために、参照を保持しておく
    // （タイマー処理を実行した瞬間にreleaseされてしまう）
    [fullScreenTimer_ retain];
}

- (void)stopFullScreenTimer_
{
    if ([fullScreenTimer_ isValid]) {
        [fullScreenTimer_ invalidate];
    }
    [fullScreenTimer_ release], fullScreenTimer_ = nil;
}

#pragma mark - 回転のサポート

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    KLDBGPrintMethodName("▼ ");
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation 
{
    KLDBGPrintMethodName("▼ ");
    KLDBGPrint(" orientation:%s size:%s\n", 
               UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? "Landscape" : "Portrate", 
               KLDBGSize(self.view.bounds.size));

    // 回転が発生したら、カレントのページで表示を初期化
    [pageView_ renderPageWithInitialLayout];
    
    // ツールバーのスライダーの長さを調整
    CGFloat width = self.view.bounds.size.width - pageLabel_.bounds.size.width - 40 * 3;
    pageSlider_.bounds = CGRectMake(0.0, 0.0, width, pageSlider_.bounds.size.height);
}

#pragma mark - Action

- (IBAction)addTagAction:(id)sender
{
    [self showTagDetailPopoverOfTagView_:nil];
}

#pragma mark - ツールバー

- (void)setupToolbar_
{
    PRDocument* doc = [PRDocumentManager sharedManager].currentDocument;
    
    // ページ数/総ページ数の表示
    pageLabel_ = [[UILabel alloc] init];
    pageLabel_.textAlignment = UITextAlignmentCenter;
    pageLabel_.textColor = [UIColor whiteColor];
    pageLabel_.backgroundColor = [UIColor clearColor];
    pageLabel_.text = @"000/000";
    [pageLabel_ sizeToFit];
    pageLabel_.text = [NSString stringWithFormat:@"%d/%d", doc.currentPageIndex + 1, doc.numPages];
    UIBarButtonItem* labelItem = [[[UIBarButtonItem alloc] 
                                    initWithCustomView:pageLabel_] autorelease];

    // スペーサーの作成
    UIBarButtonItem* spacer = [[[UIBarButtonItem alloc]
                                initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];

    // スライダーの作成
    CGFloat width = self.view.bounds.size.width - pageLabel_.bounds.size.width - 40 - 32 * 2;
                        // actionItem.width は0を返すため適当な値(40)で代用 + スペーサ２個分
    pageSlider_ = [[UISlider alloc] init];
    pageSlider_.bounds = CGRectMake(0.0, 0.0, width, pageSlider_.bounds.size.height);
    [pageSlider_ addTarget:self action:@selector(sliderDidSlide_:) 
     forControlEvents:UIControlEventValueChanged];
    pageSlider_.minimumValue = 1;
    pageSlider_.maximumValue = doc.numPages;
    pageSlider_.value = doc.currentPageIndex + 1;
    UIBarButtonItem* sliderItem = [[[UIBarButtonItem alloc] 
                                    initWithCustomView:pageSlider_] autorelease];
    
    // アクションボタンの作成
    UIImage* image = [UIImage imageNamed:@"taglist.png"];
    UIBarButtonItem* actionItem = [[[UIBarButtonItem alloc] 
                                    initWithImage:image style:UIBarButtonItemStylePlain
                                    target:self action:@selector(actionButtonDidPush_:)] 
                                   autorelease];

    // ツールバーへの追加
    NSArray* items = [NSArray arrayWithObjects:labelItem, spacer, 
                      sliderItem, spacer, actionItem, nil];
    [self setToolbarItems:items];    
}

- (void)sliderDidSlide_:(id)sender
{
    sliding_ = YES;
    pageController_.currentPageIndex = pageSlider_.value - 1;
    [pageView_.pageDelegate pageViewCurrentPageDidChange];
    [pageView_ renderPageWithInitialLayout];
    [self startFullScreenTimer_];
    sliding_ = NO;
}

- (void)actionButtonDidPush_:(id)sender
{
    [self showTagListPopover_:sender];
}

- (void)showTagListPopover_:(id)sender
{
    // コントローラを作成する
    PRTagListController* controller;
    controller = [[PRTagListController alloc] init];
    controller.delegate = self;
    [controller autorelease];
    
    // 独自のナビゲーションコントローラに追加する
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:controller];
    [navController autorelease];
    
    // Popoverとして表示
    controller.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
    poController_ = [[UIPopoverController alloc]
                     initWithContentViewController:navController];
    poController_.delegate = self;
    
    // ナビゲーションバーのボタンからのPopover
    self.navigationController.toolbar.userInteractionEnabled = NO;
    [poController_ presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
    // Popover表示中はナビゲーションバーを消さない
    [self stopFullScreenTimer_];
}

#pragma mark - KLPVPageView デリゲート

- (void)pageViewCurrentPageDidChange
{
    PRDocument* doc = [PRDocumentManager sharedManager].currentDocument;
    if (!sliding_) {
        // 手でスライダーをスライドさせているのでなければ、スライダーの値を変更
        pageSlider_.value = doc.currentPageIndex + 1;
    }
    
    pageLabel_.text = [NSString stringWithFormat:@"%d/%d", 
                       doc.currentPageIndex + 1, doc.numPages];
}

- (void)editTagAction:(id)sender
{
    [self showTagDetailPopoverOfTagView_:pageView_.selectedTagView];
}

- (void)showTagDetailPopoverOfTagView_:(KLPVTagView*)tagView
{
    // コントローラを作成する
    PRTagDetailController* controller;
    controller = [[PRTagDetailController alloc] init];
    controller.delegate = self;
    controller.tag = [pageController_ tagOfTagView:tagView];
    [controller autorelease];
    
    // 独自のナビゲーションコントローラに追加する
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:controller];
    [navController autorelease];
    
    // Popoverとして表示
    CGFloat height = 140.0 + [PRTag presetColorCount] * 44.0;
    if (tagView && controller.hasOriginalColor) {
        height += 44.0;
    }
    controller.contentSizeForViewInPopover = CGSizeMake(320.0, height);
    poController_ = [[UIPopoverController alloc]
                     initWithContentViewController:navController];
    poController_.delegate = self;
    
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    if (tagView) {
        // 編集時はtagViewからのPopover
        CGRect frame = [pageView_ convertRect:tagView.bounds fromView:tagView];
        [poController_ presentPopoverFromRect:frame inView:pageView_ permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        // 追加時はナビゲーションバーのボタンからのPopover
        [poController_ presentPopoverFromBarButtonItem:addButton_ permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    
    // Popover表示中はナビゲーションバーを消さない
    [self stopFullScreenTimer_];
}

- (void)deleteTagAction:(id)sender
{
    // アラートを表示する
    UIAlertView* alert = [[UIAlertView alloc] 
                          initWithTitle:@"付箋の削除" 
                          message:@"選択されている付箋を削除してもよろしいですか？" 
                          delegate:self
                          cancelButtonTitle:@"いいえ" otherButtonTitles:@"はい", nil];
    [alert autorelease];
    [alert show];
}

- (void)tappedWithTouch:(UITouch *)touch
{
    KLDBGPrintMethodName("▼ ");
    if (fullScreen_) {
        // フルスクリーンの状態であれば、ナビゲーションバーを表示
        [self setFullScreen_:NO];
    } else {
        // そうでなければ、ナビゲーションバー消去のタイマーを延長
        [self startFullScreenTimer_];
    }
}

#pragma mark - PRTagDetailControllerデリゲート

- (void)tagDetailControllerDidCancel:(PRTagDetailController*)controller
{
    KLDBGPrintMethodName("▼ ");

    // コントローラを隠す
    [self dismissPopover_];
}

- (void)tagDetailControllerDidSave:(PRTagDetailController *)controller
{
    KLDBGPrintMethodName("▼ ");

    if (controller.isNew) {
        [pageController_ insertNewTag:controller.tag];
        KLPVTagView* tagView = [pageController_ createTagViewOfTag:controller.tag 
                                                    inPage:1 
                                                     scale:pageView_.scale];
        [pageView_ addTagView:(KLPVTagView*)tagView];
    } else {
        [pageView_.selectedTagView setNeedsDisplay];
    }
    [[PRDocumentManager sharedManager].currentDocument saveContents];
    
    // コントローラを隠す
    [self dismissPopover_];
}

- (void)dismissPopover_
{
    // コントローラを隠す
    [poController_ dismissPopoverAnimated:YES];
    [poController_ release], poController_ = nil;
    
    // 強制的にdismissした場合、PopoverのpopoverControllerDidDismissPopover:は呼び出されない
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [self startFullScreenTimer_];
}

#pragma mark PRTagListController デリゲート

- (void)tagListControllerTagDidSelect:(PRTagListController*)controller
{
    pageController_.currentPageIndex = controller.selectedTag.page;
    pageController_.targetPoint = controller.selectedTag.center;
    [pageView_ renderPageWithInitialLayout];
    
    // コントローラを隠す
    [self dismissPopover_];
}

#pragma mark UIPopoverControllerデリゲート

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    KLDBGPrintMethodName("▼ ");

    // コントローラを隠す
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.navigationController.toolbar.userInteractionEnabled = YES;
    [poController_ release], poController_ = nil;
    
    [self startFullScreenTimer_];
}

#pragma mark UIAlertViewデリゲート

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        KLPVTagView* tagView = pageView_.selectedTagView;
        pageView_.selectedTagView = nil;
        [pageController_ deleteTagView:tagView];
    }
}

@end
