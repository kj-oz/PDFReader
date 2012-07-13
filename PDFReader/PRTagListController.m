//
//  PRTagListController.m
//  PDFReader
//
//  Created by KO on 12/02/26.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import "PRTagListController.h"
#import "PRDocumentManager.h"
#import "PRDocument.h"
#import "PRTag.h"

@interface PRTagListController (Private)

/**
 * 各種initメソッドから呼びだされる共通の初期化処理.
 */
- (void)init_;

/**
 * アウトレットの解放.
 */
- (void)releaseOutlets_;

/**
 * 付箋の配列を構築する.
 */
- (void)createTags_;

/**
 * セルの表示を更新する
 * @param cell セルオブジェクト
 * @param indexPath インデックス
 */
- (void)updateCell_:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;

@end

@implementation PRTagListController

@synthesize delegate = delegate_;
@synthesize selectedTag = selectedTag_;

- (void)init_
{
    self.title = NSLocalizedString(@"付箋一覧", nil);
}

- (id)init
{
    return [self initWithNibName:@"TagList" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self init_];
    }
    return self;
}

- (void)releaseOutlets_
{
    [tableView_ release], tableView_ = nil;
    
    // Outletではないが、tableView_と同期しているのでここでrelease
    [tags_ release], tags_ = nil;
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

#pragma mark - ビューのライフサイクル

- (void)viewWillAppear:(BOOL)animated
{
    KLDBGPrintMethodName("▼ ");
    [super viewWillAppear:animated];
    
    // テーブルの行の数と付箋の数を比較する
    [self createTags_];
    if ([tableView_ numberOfRowsInSection:0] != tags_.count) {
        // データの再読み込みを行う
        [tableView_ reloadData];
    } else {
        // セルの表示更新を行う
        for (UITableViewCell* cell in [tableView_ visibleCells]) {
            [self updateCell_:cell atIndexPath:[tableView_ indexPathForCell:cell]];
        }
    }
    
}

- (void)createTags_
{
    [tags_ removeAllObjects];
    
    PRDocument* doc = [PRDocumentManager sharedManager].currentDocument;
    for (NSUInteger i = 0, n = doc.numPages; i < n; i++) {
        NSArray* tagArray = [doc.tagArrays objectAtIndex:i];
        [tags_ addObjectsFromArray:tagArray];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    tags_ = [[NSMutableArray alloc] init];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [self releaseOutlets_];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)updateCell_:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    PRTag* tag = [tags_ objectAtIndex:indexPath.row];
    cell.textLabel.text = tag.text;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%dページ", tag.page + 1];
    
    // 付箋アイコン
    UIGraphicsBeginImageContext(CGSizeMake(44.0, 24.0));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, tag.color.CGColor);
    CGRect rect = CGRectMake(26.0, 0.0, 12.0, 24.0);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    cell.imageView.image = image;
    
    // アクセサリの設定
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

#pragma mark - UITableView データソース

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return tags_.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [tableView_ dequeueReusableCellWithIdentifier:@"TagListCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"TagListCell"];
        
        [cell autorelease];
    }
    
    // セルの値を更新する
    [self updateCell_:cell atIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
    return NO;
}

#pragma mark - UITableView デリゲート

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    selectedTag_ = [tags_ objectAtIndex:indexPath.row];
    
    // デリゲートに通知する
    if ([delegate_ respondsToSelector:@selector(tagListControllerTagDidSelect:)]) {
        [delegate_ tagListControllerTagDidSelect:self];
    }
}

@end
