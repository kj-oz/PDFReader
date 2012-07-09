//
//  PRDocumentListController.m
//  PDFReader
//
//  Created by KO on 11/10/01.
//  Copyright 2011年 KO All rights reserved.
//

#import "PRDocumentListController.h"
#import "KLTVTreeManager.h"
#import "KLTVTreeNode.h"
#import "KLTVTreeViewCell.h"
#import "PRDocumentManager.h"
#import "PRShelf.h"
#import "PRDocument.h"
#import "PRTag.h"
#import "PRDocumentController.h"
#import "KLNetURLDownloader.h"
#import "PRConnector.h"
#import "PRDocumentDetailController.h"
#import "PRShelfListController.h"

#define isDocument(node)        (node.level == 0)

@interface PRDocumentListController (Private)

/**
 * 各種initメソッドから呼びだされる共通の初期化処理.
 */
- (void)init_;

/**
 * アウトレットの解放.
 */
- (void)releaseOutlets_;

/**
 * ツリーを構築する.
 */
- (void)createTree_;

/**
 * 与えられたドキュメントノードに対する付箋ノードを生成する
 * @parama docNode ドキュメントノード
 */
- (void)createTagNodesOfDocumentNode_:(KLTVTreeNode*)docNode;

/**
 * ナビゲーションバーを更新する
 * @param animated アニメーションの有無
 */
- (void)updateNavigationItemAnimated_:(BOOL)animated;

/**
 * セルの表示を更新する.
 * @param cell セルオブジェクト
 * @param indexPath インデックス
 */
- (void)updateCell_:(KLTVTreeViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;

/**
 * ドキュメント詳細画面を表示する.
 * @param doc 対象ドキュメント、新規ドキュメント追加時はnil
 */
- (void)showDocumentDetailPopover_:(PRDocument*)doc;

/**
 * 本棚一覧画面を表示する.
 * @param reason 本棚一覧を表示する元になったボタン
 */
- (void)showShelfListPopover_:(UIBarButtonItem*)reason;

/**
 * 各種ポップオーバー画面を隠す.
 */
- (void)dismissPopover_;

/**
 * 与えられた条件の複数のインデクスパスの配列を得る.
 * @param row 開始行番号
 * @param count インデクスパスの数
 * @param section 属するセクション
 * @return 指定の開始行から|count|個の連続したインデクスパスの配列を得る
 */
- (NSArray*)createIndexPathsForRowsFrom_:(NSUInteger)row count:(NSUInteger)count 
                               inSection:(NSUInteger)section;

/**
 * 親セルが移動された際に、その子供のセルも合わせて移動する処理を行う.
 * @param args [0]:削除すべきセルのIndexPath配列、[1]:挿入すべきセルのIndexPath配列
 */
- (void)moveChildCellsWithArgs_:(NSArray*)args;

/**
 * PDFダウンロード中にエラーが発生した場合にメッセージを表示し、対象のセルを削除する.
 * @param doc 対象のドキュメント
 * @param message 画面に表示するメッセージ
 */
- (void)handleDownloadingErrorWithDocument_:(PRDocument*)doc message:(NSString*)message;

/**
 * 選択されているドキュメントを削除する.
 */
- (void)removeSelectedDocuments_;

/**
 * 選択されている複数の書類を指定の本棚に移動する.
 * @param shelf 移動先の本棚
 */
- (void)moveSelectedDocumentsToShelf_:(PRShelf*)shelf;

/**
 * 選択されているドキュメントのノードの配列を得る.
 * @return 選択されているドキュメントのノードの配列
 */
- (NSArray*)selectedDocumentNodes_;

/**
 * 選択されているドキュメントの配列を得る.
 * @return 選択されているドキュメントの配列
 */
- (NSArray*)selectedDocuments_;

/**
 * 選択されている行の配列を得る.
 * @return 選択されている行の配列
 */
- (NSArray*)selectedRows_;

/**
 * 選択されているドキュメントを一覧から削除する.
 */
- (void)removeSelectedDocumentsFromTable_;

/**
 * 与えられたドキュメントを表示するセルのインデックスを得る.
 * @param doc ドキュメント
 * @return セルのインデックス
 */
- (NSInteger)indexForDocument_:(PRDocument*)doc;

@end

@implementation PRDocumentListController

@synthesize delegate = delegate_;

#pragma mark - 初期化

- (void)init_
{
}

- (id)init
{
    return [self initWithNibName:@"DocumentList" bundle:nil];
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

- (void)releaseOutlets_
{
    [tableView_ release], tableView_ = nil;
    [addButton_ release], addButton_ = nil;
    [shelfButton_ release], shelfButton_ = nil;
    [deleteButton_ release], deleteButton_ = nil;
    [moveButton_ release], moveButton_ = nil;
    [detailButton_ release], detailButton_ = nil;
    
    // Outletではないが、tableView_と同期しているのでここでrelease
    [treeManager_ release], treeManager_ = nil;
}

- (void)dealloc
{
    [self releaseOutlets_];
    delegate_ = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // ビューの解放
    [super didReceiveMemoryWarning];
    
    // その他のリソースの解放
}

#pragma mark - ドキュメント画面への遷移

- (void)showDocument:(PRDocument*)doc animated:(BOOL)animated
{
    [self showDocument:doc atTag:nil animated:animated];
}

- (void)showDocument:(PRDocument *)doc atTag:(PRTag*)tag animated:(BOOL)animated
{
    KLDBGPrintMethodName("▼ ");
   
    // カレントドキュメントを設定する
    PRDocumentManager* dm = [PRDocumentManager sharedManager];
    dm.currentDocument = doc;
    if (tag) {
        doc.currentPageIndex = tag.page;
    } else if (doc.currentPageIndex < 0) {
        doc.currentPageIndex = 0; 
    }
    
    // コントローラを作成する
    PRDocumentController*  controller;
    controller = [[PRDocumentController alloc] 
                  initWithNibName:@"Document" bundle:[NSBundle mainBundle]];
    controller.delegate = self;
    controller.targetPoint = tag ? tag.center : CGPointZero;
    
    // ナビゲーションコントローラに追加する
    [self.navigationController pushViewController:controller animated:animated];
    [controller release];
}

#pragma mark - ビューのライフサイクル

- (void)viewWillAppear:(BOOL)animated
{
    KLDBGPrintMethodName("▼ ");
    for (UIViewController* ctrl in self.navigationController.viewControllers) {
        KLDBGPrint(" - %s\n", KLDBGClass(ctrl));
    }
    [super viewWillAppear:animated];
    
    // 画面を更新する
    // ナビゲーションバーを非透明化
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.toolbarHidden = YES;
    
    // ドキュメント画面から直接切り替えられたときに、元がフルスクリーン状態の可能性があるため、戻す処理を行う
    self.navigationController.navigationBar.alpha = 1.0;
    [self.navigationController setNavigationBarHidden:NO animated:NO];

    [self updateNavigationItemAnimated_:animated];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    
    // ドキュメント画面から遷移してきた場合（dm.currentDocument != nill）で、そのドキュメントのノードが
    // 開いていれば、そのドキュメントの子ノードを再構築
    // navigationController:willShowViewController:animated:は、このメソッドの後で呼び出されるため
    // タイミングとして間に合わない
    PRDocumentManager* dm = [PRDocumentManager sharedManager];
    self.title = dm.currentShelf.name;
    if (dm.currentDocument) {
        NSInteger index = [self indexForDocument_:dm.currentDocument];
        KLTVTreeNode* docNode = [treeManager_ nodeAtIndex:index];
        
        [docNode removeAllChildren];
        [self createTagNodesOfDocumentNode_:docNode];
        
        // DocumentViewを閉じるタイミングでcurrentDocumentをnilにしたいのだが、「戻る」処理を
        // NavigationControllerに任せるとイベントが発生しないため、ここで処理する
        // （同時に保存処理も行われる）
        dm.currentDocument = nil;
    }

    // テーブルの行の数とツリー上の可視ノードの数を比較する
    if ([tableView_ numberOfRowsInSection:0] != treeManager_.visibleNodeCount) {
        // データの再読み込みを行う
        [tableView_ reloadData];
    } else {
        // 選択されているセルを解除する
        NSIndexPath* indexPath = [tableView_ indexPathForSelectedRow];
        if (indexPath) {
            [tableView_ deselectRowAtIndexPath:indexPath animated:YES];
        }
        
        // セルの表示更新を行う
        for (UITableViewCell* cell in [tableView_ visibleCells]) {
            [self updateCell_:(KLTVTreeViewCell*)cell 
                  atIndexPath:[tableView_ indexPathForCell:cell]];
        }
    }
    
    // 通知の登録
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(connectorDidBeginDownload:) 
                   name:PRConnectorDidBeginDownload object:nil];
    [center addObserver:self selector:@selector(connectorInProgressDownload:) 
                   name:PRConnectorInProgressDownload object:nil];
    [center addObserver:self selector:@selector(connectorDidFinishDownload:) 
                   name:PRConnectorDidFinishDownload object:nil];
}

- (void)createTree_
{
    [treeManager_ clear];
    
    for (PRDocument* doc in [PRDocumentManager sharedManager].currentShelf.documents) {
        KLTVTreeNode* docNode = [[KLTVTreeNode alloc] initWithData:doc];
        docNode.expanded = doc.tagOpened;
        [treeManager_ addTopNode:docNode];
        [docNode release];
        
        [self createTagNodesOfDocumentNode_:docNode];        
    }
}

- (void)createTagNodesOfDocumentNode_:(KLTVTreeNode*)docNode
{
    PRDocument* doc = (PRDocument*)docNode.data;
    for (NSUInteger i = 0, n = doc.numPages; i < n; i++) {
        NSArray* tagArray = [doc.tagArrays objectAtIndex:i];
        for (PRTag* tag in tagArray) {
            KLTVTreeNode* tagNode = [[KLTVTreeNode alloc] initWithData:tag];
            [docNode addChild:tagNode];
            [tagNode release];
        }
    }
}

- (void)viewDidLoad
{
    KLDBGPrintMethodName("▼ ");
    [super viewDidLoad];
    
    // 複数選択を可能に
    tableView_.allowsMultipleSelectionDuringEditing = YES;
    deleteButton_.tintColor = [UIColor redColor];
    
    treeManager_ = [[KLTVTreeManager alloc] init];
    treeManager_.expandedIcon = [UIImage imageNamed:@"expanded.png"];
    treeManager_.closedIcon = [UIImage imageNamed:@"closed.png"];
    treeManager_.levelIndent = 24.0;
    treeManager_.handleWidth = 32.0;
    
    [self createTree_];
}

- (void)viewDidAppear:(BOOL)animated
{
    KLDBGPrintMethodName("▼ ");
    
    // 親クラスのメソッドを呼び出す
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    KLDBGPrintMethodName("▼ ");
}

- (void)viewDidUnload
{
    KLDBGPrintMethodName("▼ ");
    [super viewDidUnload];

    [self releaseOutlets_];
}

#pragma mark - 回転のサポート

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - 編集モード

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    // テーブルビューの編集モードを設定する
    // ボタンのキャプションを日本語にするためには、①PROJECTのLocalizationsにJapaneseを追加、
    // ②info.plistのLocalization native development regionをJapanに設定
    // シミュレータでも日本語にするには、環境設定でInternationalizationを設定
    [tableView_ setEditing:editing animated:animated];
    
    // ナビゲーションボタンを更新する
    [self updateNavigationItemAnimated_:animated];
}

#pragma mark - 画面の更新

- (void)updateNavigationItemAnimated_:(BOOL)animated
{
    // setLeftBarButtonItems と setLeftBarButtonItem を状況によって使い分けると、setLeftBarButtonItem 
    // 実行時にエラーになるので１つしかない場合も、setLeftBarButtonItems を使用する
    if (self.editing) {
        [self.navigationItem setLeftBarButtonItems:
         [NSArray arrayWithObjects:detailButton_, moveButton_, deleteButton_, nil] animated:animated];
        [self.navigationItem setRightBarButtonItems:
         [NSArray arrayWithObjects:[self editButtonItem], nil] animated:animated];
    } else {
        [self.navigationItem setLeftBarButtonItems:
         [NSArray arrayWithObjects:shelfButton_, nil] animated:animated];
        [self.navigationItem setRightBarButtonItems:
         [NSArray arrayWithObjects:[self editButtonItem], addButton_, nil] animated:animated];
    }
}

- (void)updateCell_:(KLTVTreeViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    KLTVTreeNode* node = [treeManager_ nodeAtIndex:indexPath.row];
    [treeManager_ setupCell:cell forNode:node];
    
    if (isDocument(node)) {
        // ドキュメント
        PRDocument* doc = (PRDocument*)node.data;
        KLNetURLDownloader* downloader = [[PRConnector sharedConnector] 
                                          downloaderForDocument:doc];
        
        cell.textLabel.text = doc.title;
        if (downloader) {
            // ダウンロード中
            CGFloat percent = downloader.downloadedSize > 0 ? 
                (CGFloat)downloader.downloadedSize * 100.0 / (CGFloat)downloader.expectedSize :
                0.0;
            cell.detailTextLabel.text = 
                [NSString stringWithFormat:@"ダウンロード中　%.1f %% ( %d / %d )", 
                percent, downloader.downloadedSize, downloader.expectedSize];
        } else {
            NSMutableString* text = [NSMutableString stringWithCapacity:100];
            if (doc.modDate.length > 0) {
                [text appendFormat:@"%@  ", doc.modDate];
            }
            if (doc.author.length > 0) {
                [text appendFormat:@"%@  ", doc.author];
            }
            [text appendFormat:@"%@  ", doc.fileName];
            if (doc.currentPageIndex >= 0) {
                [text appendFormat:@"%d / ", doc.currentPageIndex + 1];
            }
            [text appendFormat:@"%d ページ", doc.numPages];
            cell.detailTextLabel.text = [text copy];
        }
        // 付箋アイコン削除（これがないと、再利用時にドキュメントノードにも付箋アイコンが現れる）
        cell.imageView.image = nil;
        
    } else {
        // 付箋
        PRTag* tag = (PRTag*)node.data;
        cell.textLabel.text = tag.text;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%dページ", tag.page + 1];
        
        // 付箋アイコン
        UIGraphicsBeginImageContext(CGSizeMake(24.0, 28.0));
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, tag.color.CGColor);
        CGRect rect = CGRectMake(6.0, 0.0, 12.0, 28.0);
        CGContextFillRect(context, rect);
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        cell.imageView.image = image;
    }
    
    // アクセサリの設定
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.editingAccessoryType = UITableViewCellAccessoryNone;

    cell.delegate = self;
}

#pragma mark - Action

- (IBAction)addAction
{
    [self showDocumentDetailPopover_:nil];
}

- (void)showDocumentDetailPopover_:(PRDocument*)doc;
{
    // コントローラを作成する
    PRDocumentDetailController*  controller;
    controller = [[PRDocumentDetailController alloc] init];
    controller.delegate = self;
    controller.document = doc;
    [controller autorelease];
    
    // 独自のナビゲーションコントローラに追加する
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:controller];
    [navController autorelease];
    
    // Popoverとして表示
    CGFloat height = doc ? 360 : 90;
    controller.contentSizeForViewInPopover = CGSizeMake(320.0, height);
    poController_ = [[UIPopoverController alloc]
                     initWithContentViewController:navController];
    poController_.delegate = self;
    
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    if (doc) {
        // 編集時はセルからのPopover
        NSInteger index = [self indexForDocument_:doc];
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        UITableViewCell* cell = [tableView_ cellForRowAtIndexPath:indexPath];
        CGRect frame = cell.contentView.bounds;
        [poController_ presentPopoverFromRect:frame inView:cell.contentView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        // 追加時はナビゲーションバーのボタンからのPopover
        [poController_ presentPopoverFromBarButtonItem:addButton_ permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (IBAction)shelfAction
{
    [self showShelfListPopover_:shelfButton_];
}

- (void)showShelfListPopover_:(UIBarButtonItem*)reason
{
    shelfListReason_ = reason;
    
    // コントローラを作成する
    PRShelfListController*  controller;
    controller = [[PRShelfListController alloc] init];
    controller.delegate = self;
    [controller autorelease];
    
    // 独自のナビゲーションコントローラに追加する
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:controller];
    [navController autorelease];
    
    // Popoverとして表示
    CGFloat height = 320;
    controller.contentSizeForViewInPopover = CGSizeMake(320.0, height);
    poController_ = [[UIPopoverController alloc]
                     initWithContentViewController:navController];
    poController_.delegate = self;
    
    // ナビゲーションバーのボタンからのPopover
    // ナビゲーションバーのenabledをNoにしないと、Popoverを表示したままナビゲーションバーの操作ができてしまう.
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    [poController_ presentPopoverFromBarButtonItem:reason permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)deleteAction
{
    // アラートを表示する
    NSString* target = [tableView_ indexPathsForSelectedRows].count == 1 ? 
                @"選択されているPDF" : @"選択されている複数のPDF";
    UIAlertView* alert = [[UIAlertView alloc] 
                          initWithTitle:@"PDFの削除" 
                          message:[NSString stringWithFormat:@"%@を削除してもよろしいですか？", target]
                          delegate:self
                          cancelButtonTitle:@"いいえ" otherButtonTitles:@"はい", nil];
    [alert autorelease];
    [alert show];
}

- (IBAction)moveAction
{
    [self showShelfListPopover_:moveButton_];
}

- (IBAction)detailAction
{
    NSIndexPath* indexPath = [tableView_ indexPathForSelectedRow];
    KLTVTreeNode* node = [treeManager_ nodeAtIndex:indexPath.row];
    PRDocument* doc = (PRDocument*)node.data;
    [self showDocumentDetailPopover_:doc];
}

#pragma mark - UITableView データソース

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [treeManager_ visibleNodeCount];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [tableView_ dequeueReusableCellWithIdentifier:@"DocumentListCell"];
    if (!cell) {
        cell = [[KLTVTreeViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DocumentListCell"];
        
        [cell autorelease];
    }
    
    // セルの値を更新する
    [self updateCell_:(KLTVTreeViewCell*)cell atIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    return YES;
}

- (void)tableView:(UITableView*)tableView 
        commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
        forRowAtIndexPath:(NSIndexPath*)indexPath
{
    //TODO 後で全てコメントアウト
    KLTVTreeNode* node = [treeManager_ nodeAtIndex:indexPath.row];
    
    // 削除操作の場合
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (isDocument(node)) {
            // 実際のファイルの削除
            PRDocument* doc = (PRDocument*)node.data;
            NSString* path = [NSString stringWithFormat:@"%@/%@", 
                              [PRDocumentManager sharedManager].documentDirectory, doc.fileName];
            NSError* error;
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            
            // ドキュメントを削除する
            [[PRDocumentManager sharedManager] removeDocumentAtIndex:indexPath.row];
            
            // 情報を保存する
            [[PRDocumentManager sharedManager] save];
        } else {
            PRDocument* doc = (PRDocument*)node.parent.data;
            [doc.tagArrays removeObject:node.data];
            
            [doc saveContents];
        }
        
        // 先にノードを削除しないと、以下の処理でエラーになる
        [node removeFromParent];
        
        // テーブルの行を削除する
        [tableView_ beginUpdates];
        [tableView_ deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                          withRowAnimation:UITableViewRowAnimationRight];
        [tableView_ endUpdates];
    }
}

- (BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
    KLTVTreeNode* node = [treeManager_ nodeAtIndex:indexPath.row];
    return isDocument(node);
}

- (void)tableView:(UITableView*)tableView 
        moveRowAtIndexPath:(NSIndexPath*)fromIndexPath 
        toIndexPath:(NSIndexPath*)toIndexPath
{
    // fromがtoよりも小さい場合、toにはfromが抜けた後のindexが入っている
    // KLDBGPrint("from %d to %d\n", fromIndexPath.row, toIndexPath.row);
    NSInteger fromIndex = fromIndexPath.row;
    NSInteger toIndex = toIndexPath.row;
    if (fromIndex == toIndex) {
        // 同じ位置で放した場合
        return;
    }
    
    if (fromIndex < toIndex) {
        // ノードは未更新なので、fromを抜く前のインデックスで指定する
        // fromのノードを実際に抜くと子ノードまで同時に抜けて意図する結果にならない
        toIndex++;
    }
    NSUInteger count = treeManager_.visibleNodeCount;
        
    // ドキュメントを移動する
    [[PRDocumentManager sharedManager] 
     moveDocumentAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
    [[PRDocumentManager sharedManager] save];
    
    // ツリーのノードを移動する
    KLTVTreeNode* node = [treeManager_ nodeAtIndex:fromIndex];
    KLTVTreeNode* parent = node.parent;
    KLTVTreeNode* toNode = nil;
    if (toIndex < count) {
        toNode = [treeManager_ nodeAtIndex:toIndex];
    }
    if (toNode == node) return;
    
    // ノードを一度抜く
    [node retain];
    [node removeFromParent];    
    
    // 新たな位置に挿入
    if (toIndex == count) {
        [parent addChild:node];
    } else {
        NSUInteger index = [parent indexOfChild:toNode];
        [parent insertChild:node atIndex:index];
    }
    [node release];
    
    // 子のセルの同時移動
    if (node.expanded) {
        //  この時点では、親セルも実際には移動していない
        // for (int i = 0, n = treeManager_.visibleNodeCount; i < n; i++) {
        //    UITableViewCell* cell = [tableView_ 
        //      cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        //    KLDBGPrint("%s\n", cell.textLabel.text.UTF8String);
        // }
        NSInteger fromTop = -1;
        NSInteger toTop = -1;
        NSUInteger descendantCount = node.visibleDescendantCount;
        
        if (fromIndex < toIndex) {
            fromTop = fromIndex;
            toTop = toIndex - descendantCount;
        } else {
            fromTop = fromIndex + 1;
            toTop = toIndex + 1;
        }
        
        NSArray* fromIndexes = [self createIndexPathsForRowsFrom_:fromTop
                count:descendantCount inSection:0];
        NSArray* toIndexes = [self createIndexPathsForRowsFrom_:toTop
                count:descendantCount inSection:0];
        
        // ここではまだ親のセルの移動が完了していないので、完了後に子の移動を実行できるよう
        // delayを挿入
        NSArray* args = [NSArray arrayWithObjects:fromIndexes, toIndexes, nil];
        [self performSelector:@selector(moveChildCellsWithArgs_:) 
                   withObject:args afterDelay:0.3F];
    }
}

- (void)moveChildCellsWithArgs_:(NSArray*)args
{
    //  ここでは、親セルだけは移動済み
    // for (int i = 0, n = treeManager_.visibleNodeCount; i < n; i++) {
    //    UITableViewCell* cell = [tableView_ 
    //      cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    //    KLDBGPrint("%s\n", cell.textLabel.text.UTF8String);
    // }
    NSArray* fromIndexes = [args objectAtIndex:0];
    NSArray* toIndexes = [args objectAtIndex:1];
    
    [tableView_ beginUpdates];
    [tableView_ deleteRowsAtIndexPaths:fromIndexes 
                      withRowAnimation:UITableViewRowAnimationRight];
    [tableView_ insertRowsAtIndexPaths:toIndexes
                      withRowAnimation:UITableViewRowAnimationRight];
    [tableView_ endUpdates];
}

#pragma mark - UITableView デリゲート

// 編集時でも選択可能にしたが、付箋の行は選択できなくしたいため、このメソッドを実装
- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    KLTVTreeNode* node = [treeManager_ nodeAtIndex:indexPath.row];
    if (tableView_.isEditing && !isDocument(node)) {
        return nil;
    }
    return indexPath;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    KLTVTreeNode* node = [treeManager_ nodeAtIndex:indexPath.row];
    if (tableView_.isEditing) {
        detailButton_.enabled = [tableView_ indexPathsForSelectedRows].count == 1;
    } else {
        if (isDocument(node)) {
            PRDocument* doc = (PRDocument*)node.data;
            [self showDocument:doc animated:YES];    
        } else {
            PRDocument* doc = (PRDocument*)node.parent.data;
            PRTag* tag = (PRTag*)node.data;
            [self showDocument:doc atTag:tag animated:YES];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView_.isEditing) {
        detailButton_.enabled = [tableView_ indexPathsForSelectedRows].count == 1;
    }
}

- (NSIndexPath*)tableView:(UITableView*)tableView 
        targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath 
{
    // sourceがdestinationよりも小さい場合、destinationにはsourceが抜けた後のindexが入っている
    NSUInteger newIndex = -1;
    NSInteger fromIndex = sourceIndexPath.row;
    NSInteger toIndex = proposedDestinationIndexPath.row;
    if (fromIndex <= toIndex) {
        // ノードの参照はsourceを抜く前のインデックスで指定する
        toIndex++;
    }
    
    KLTVTreeNode* node = nil;
    NSInteger count = treeManager_.visibleNodeCount;
    if (toIndex < count) {
        node = [treeManager_ nodeAtIndex:toIndex];
    }
    if (!node || isDocument(node)) {
        newIndex = toIndex;
    } else {
        if (fromIndex < toIndex) {
            // 次のドキュメントを探す
            int i;
            for (i = toIndex + 1; i < count; i++) {
                KLTVTreeNode* work = [treeManager_ nodeAtIndex:i];
                if (isDocument(work)) {
                    break;
                }
            }
            newIndex = i;
        } else {
            newIndex = [treeManager_ indexOfNode:node.parent];
        }
    }
    
    KLDBGPrint(" from %d to %d -> %d\n", fromIndex, toIndex, newIndex);
    if (newIndex > fromIndex) {
        newIndex--;
    }
    return [NSIndexPath indexPathForRow:newIndex inSection:sourceIndexPath.section];    
}

#pragma mark - UITreeView デリゲート

- (void)treeView:(UITableView *)treeView didTapHandleAtIndexPath:(NSIndexPath *)indexPath
{
    KLTVTreeNode* node = [treeManager_ nodeAtIndex:indexPath.row];
    NSUInteger descendantCount = 0;
    if (node.isExpanded) {
        descendantCount = node.visibleDescendantCount;
    }
    node.expanded = !node.isExpanded;
    if (node.isExpanded) {
        descendantCount = node.visibleDescendantCount;
    }
    PRDocument* doc = (PRDocument*)node.data;
    doc.tagOpened = node.isExpanded;
    [[PRDocumentManager sharedManager] save];    
    
    [tableView_ beginUpdates];
    KLTVTreeViewCell* cell = (KLTVTreeViewCell*)[tableView_ cellForRowAtIndexPath:indexPath];
    [self updateCell_:cell atIndexPath:indexPath];
    
    NSArray* indexes = [self createIndexPathsForRowsFrom_:indexPath.row+1
                                 count:descendantCount inSection:indexPath.section];
    if (node.expanded) {
        [tableView_ insertRowsAtIndexPaths:indexes 
                          withRowAnimation:UITableViewRowAnimationRight];
    } else {
        [tableView_ deleteRowsAtIndexPaths:indexes 
                          withRowAnimation:UITableViewRowAnimationRight];        
    }
    [tableView_ endUpdates];
}

- (NSArray*)createIndexPathsForRowsFrom_:(NSUInteger)row count:(NSUInteger)count inSection:(NSUInteger)section
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        [array addObject:[NSIndexPath indexPathForRow:row + i inSection:section]];
    }
    return array;
}

#pragma mark - PRDocumentDetailControllerデリゲート

- (void)documentDetailControllerDidCancel:(PRDocumentDetailController*)controller
{
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
}

- (void)documentDetailControllerDidSave:(PRDocumentDetailController *)controller
{
    if (controller.isNew) {
        // ダウンロードが開始された状態でここにくる
        // ここでは何もしない
    } else {
        [[PRDocumentManager sharedManager] save];
        
        // セルの値を更新する
        NSInteger index = [self indexForDocument_:controller.document];
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        UITableViewCell* cell = [tableView_ cellForRowAtIndexPath:indexPath];
        [self updateCell_:(KLTVTreeViewCell*)cell atIndexPath:indexPath];
    }
    
    // コントローラを隠す
    [self dismissPopover_];
}

#pragma mark - PRShelfListControllerデリゲート

- (void)shelfListControllerShelfDidSelect:(PRShelfListController*)controller
{
    if (shelfListReason_ == shelfButton_) {
        [PRDocumentManager sharedManager].currentShelf = controller.selectedShelf;
        self.title = controller.selectedShelf.name;
        [self createTree_];
        [tableView_ reloadData];
    } else {
        [self moveSelectedDocumentsToShelf_:controller.selectedShelf];
    }
    
    // コントローラを隠す
    [self dismissPopover_];
}

#pragma mark - PRConnector 通知

- (void)connectorDidBeginDownload:(NSNotification*)notification
{
    KLDBGPrintMethodName("▽ ");

    // ダウンロードオブジェクトを取得する
    PRDocument* doc = [[notification userInfo] objectForKey:@"document"];
    [[PRDocumentManager sharedManager] addDocument:doc];
    
    // ツリーへのノードの追加
    KLTVTreeNode* docNode = [[KLTVTreeNode alloc] initWithData:doc];
    [treeManager_ addTopNode:docNode];
    [docNode release];

    // セルの追加
    NSInteger index = [tableView_ numberOfRowsInSection:0];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
    
    [tableView_ insertRowsAtIndexPaths:indexPaths 
                      withRowAnimation:UITableViewRowAnimationBottom];
}

- (void)connectorInProgressDownload:(NSNotification*)notification
{
    // ドキュメントを取得する
    PRDocument* doc = [[notification userInfo] objectForKey:@"document"];
    // KLNetURLDownloader* downloader = [[notification userInfo] objectForKey:@"downloader"];
    // KLDBGPrint(" downloaded %d\n", downloader.downloadedSize);
    
    // 対象セルの検索
    NSInteger index = [self indexForDocument_:doc];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    [self updateCell_:(KLTVTreeViewCell*)[tableView_ cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
}

- (void)connectorDidFinishDownload:(NSNotification*)notification
{
    // ダウンロードオブジェクトとドキュメントを取得する
    KLNetURLDownloader*  downloader = 
        [[notification userInfo] objectForKey:@"downloader"];
    PRDocument* doc = [[notification userInfo] objectForKey:@"document"];    
    
    // ダウンロード時のエラー
    if (downloader.networkState == KLNetNetworkStateCanceled) {
        NSString* message = [NSString stringWithFormat:
                             @"ファイル%@のダウンロードがキャンセルされました。", doc.fileName];
        [self handleDownloadingErrorWithDocument_:doc message:message];
    } else if (downloader.networkState == KLNetNetworkStateError) {
        NSString* message = [NSString stringWithFormat:
                             @"ファイル%@のダウンロードでエラーが発生しました。\nエラー%d：%@", 
                             doc.fileName, downloader.error.code,
                             downloader.error.localizedDescription];
        [self handleDownloadingErrorWithDocument_:doc message:message];
    }
    
    // ファイルの保存
    NSString* dirPath = [PRDocumentManager sharedManager].documentDirectory;
    NSString* pdfPath = [NSString stringWithFormat:@"%@/%@", dirPath, doc.fileName];
    NSData* data = downloader.downloadedData;
    NSError* error;
    if (![data writeToFile:pdfPath options:NSDataWritingAtomic error:&error]) {
        NSString* message = [NSString stringWithFormat:
                             @"ファイル%@の保存時にエラーが発生しました。\nエラー%d：%@", 
                             doc.fileName, downloader.error.code,
                             downloader.error.localizedDescription];
        [self handleDownloadingErrorWithDocument_:doc message:message];
    }
    
    // docのリフレッシュ
    if (![doc checkPdf]) {
        NSString* message = [NSString stringWithFormat:
                             @"ファイル%@は正常なPDFではありません。", doc.fileName];
        [self handleDownloadingErrorWithDocument_:doc message:message];
    }
    [doc loadContents];
    [[PRDocumentManager sharedManager] save];
    
    // 対象セルの検索
    NSInteger index = [self indexForDocument_:doc];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    [self updateCell_:(KLTVTreeViewCell*)[tableView_ cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
}
      
- (void)handleDownloadingErrorWithDocument_:(PRDocument*)doc message:(NSString*)message
{
    // アラートを表示する
    UIAlertView* alert = [[UIAlertView alloc] 
                       initWithTitle:@"ダウンロード" message:message delegate:nil
                       cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert autorelease];
    [alert show];
     
    // 対象セルの検索
    NSInteger index = [self indexForDocument_:doc];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    // ドキュメントを削除する
    [[PRDocumentManager sharedManager] removeDocument:doc];

    // 先にノードを削除しないと、以下の処理でエラーになる
    [treeManager_ removeTopNode:[treeManager_ nodeAtIndex:index]];

    // テーブルの行を削除する
    [tableView_ beginUpdates];
    [tableView_ deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                   withRowAnimation:UITableViewRowAnimationRight];
    [tableView_ endUpdates];
}                             

#pragma mark UIPopoverControllerデリゲート

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    // ここで元に戻す
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [poController_ release], poController_ = nil;
}

#pragma mark UIAlertViewデリゲート

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self removeSelectedDocuments_];
    }
}

#pragma mark - ヘルパメソッド

- (void)removeSelectedDocuments_
{
    NSArray* docs = [self selectedDocuments_];
    
    // 実体を削除する
    for (PRDocument* doc in docs) {
        NSString* path = [NSString stringWithFormat:@"%@/%@", 
                          [PRDocumentManager sharedManager].documentDirectory, doc.fileName];
        NSError* error;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    }
            
    // ドキュメントオブジェクトの削除
    [self removeSelectedDocumentsFromTable_];
}

- (void)moveSelectedDocumentsToShelf_:(PRShelf*)shelf
{
    NSArray* docs = [self selectedDocuments_];
    
    // 実体を移動する
    for (PRDocument* doc in docs) {
        [shelf addDocument:doc];
    }
    
    // ドキュメントオブジェクトの削除
    [self removeSelectedDocumentsFromTable_];
}

- (NSArray*)selectedDocumentNodes_
{
    NSArray* indexPaths = [tableView_ indexPathsForSelectedRows];
    NSMutableArray* nodes = [NSMutableArray array];
    for (NSIndexPath* indexPath in indexPaths) {
        KLTVTreeNode* node = [treeManager_ nodeAtIndex:indexPath.row];
        if (isDocument(node)) {
            [nodes addObject:node];
        }
    }    
    return nodes;
}

- (NSArray*)selectedDocuments_
{
    NSArray* indexPaths = [tableView_ indexPathsForSelectedRows];
    NSMutableArray* docs = [NSMutableArray array];
    for (NSIndexPath* indexPath in indexPaths) {
        KLTVTreeNode* node = [treeManager_ nodeAtIndex:indexPath.row];
        if (isDocument(node)) {
            [docs addObject:node.data];
        }
    }    
    return docs;
}

- (NSArray*)selectedRows_
{
    NSArray* indexPaths = [tableView_ indexPathsForSelectedRows];
    NSMutableArray* rows = [NSMutableArray array];
    for (NSIndexPath* indexPath in indexPaths) {
        [rows addObject:indexPath];
        KLTVTreeNode* node = [treeManager_ nodeAtIndex:indexPath.row];
        if (isDocument(node) && node.expanded) {
            NSUInteger descendantCount = node.visibleDescendantCount;
            NSArray* indexes = [self createIndexPathsForRowsFrom_:indexPath.row+1
                                                            count:descendantCount inSection:indexPath.section];
            [rows addObjectsFromArray:indexes];
        }
    }    
    return rows;
}

- (void)removeSelectedDocumentsFromTable_
{
    NSArray* indexPaths = [self selectedRows_];
    NSArray* nodes = [self selectedDocumentNodes_];    
    NSArray* docs = [self selectedDocuments_];
    
    // ドキュメントを削除する
    [[PRDocumentManager sharedManager] removeDocuments:docs];
    [[PRDocumentManager sharedManager] save];
    
    // 先にノードを削除しないと、以下の処理でエラーになる
    [treeManager_ removeTopNodes:nodes];
    
    // テーブルの行を削除する
    [tableView_ beginUpdates];
    [tableView_ deleteRowsAtIndexPaths:indexPaths
                      withRowAnimation:UITableViewRowAnimationRight];
    [tableView_ endUpdates];
}

- (NSInteger)indexForDocument_:(PRDocument*)doc
{
    for (NSInteger i = 0, n = treeManager_.visibleNodeCount; i < n; i++) {
        KLTVTreeNode* node = [treeManager_ nodeAtIndex:i];
        if (isDocument(node) && node.data == doc) {
            return i;
        }
    }
    return -1;
}

@end
