//
//  PRShelfListController.m
//  PDFReader
//
//  Created by KO on 12/06/19.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import "PRShelfListController.h"
#import "PRDocumentManager.h"
#import "PRShelf.h"
#import "PRTextInputCell.h"

@interface PRShelfListController (Private)

/**
 * 各種initメソッドから呼びだされる共通の初期化処理.
 */
- (void)init_;

/**
 * アウトレットの解放.
 */
- (void)releaseOutlets_;

/**
 * セルの表示を更新する
 * @param cell セルオブジェクト
 * @param indexPath インデックス
 */
- (void)updateCell_:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;

/**
 * 指定のテキストフィールドの含まれるセルを返す
 * @param textField テキストフィールド
 * @return 指定のテキストフィールドの含まれるセル
 */
- (PRTextInputCell*)findCellForTextField_:(UITextField*)textField;

/**
 * 入力中のテキストフィールドの含まれるセルを返す
 * @return 入力中のテキストフィールドの含まれるセル
 */
- (PRTextInputCell*)findRenamingCell_;

@end


@implementation PRShelfListController

@synthesize delegate = delegate_;
@synthesize selectedShelf = selectedShelf_;

- (void)init_
{
    self.title = NSLocalizedString(@"本棚一覧", nil);
}

- (id)init
{
    adding_ = NO;
    renaming_ = NO;
    selectedShelf_ = nil;
    
    return [self initWithNibName:@"ShelfList" bundle:nil];
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
}

#pragma mark - ビューのライフサイクル

- (void)viewWillAppear:(BOOL)animated
{
    KLDBGPrintMethodName("▼ ");
    [super viewWillAppear:animated];
    
    // テーブルの行の数と本棚の数を比較する
    if ([tableView_ numberOfRowsInSection:0] != [PRDocumentManager sharedManager].shelves.count) {
        // データの再読み込みを行う
        [tableView_ reloadData];
    } else {
        // セルの表示更新を行う
        for (UITableViewCell* cell in [tableView_ visibleCells]) {
            [self updateCell_:cell atIndexPath:[tableView_ indexPathForCell:cell]];
        }
    }
    
    [self updateNavigationItemAnimated_:animated];    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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

#pragma mark - 編集モード

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    // テーブルビューの編集モードを設定する
    [tableView_ setEditing:editing animated:animated];
    
    for (UITableViewCell* cell in [tableView_ visibleCells]) {
        UITextField* tf = ((PRTextInputCell*)cell).textField;
        if (editing) {
            tf.enabled = YES;
        } else {
            if ([tf isFirstResponder]) {
                [tf resignFirstResponder];
            }
            tf.enabled = NO;
        }
    }
    
    // ナビゲーションボタンを更新する
    [self updateNavigationItemAnimated_:animated];
}

#pragma mark - 画面の更新

- (void)updateNavigationItemAnimated_:(BOOL)animated
{
    if (adding_ || renaming_) {
        [self.navigationItem setLeftBarButtonItem:endButton_ animated:animated];
        [self.navigationItem setRightBarButtonItem:nil animated:animated];        
    } else {
        if (self.editing) {
            [self.navigationItem setLeftBarButtonItem:nil animated:animated];
        } else {
            [self.navigationItem setLeftBarButtonItem:addButton_ animated:animated];
        }
        [self.navigationItem setRightBarButtonItem:[self editButtonItem] animated:animated];
    }
}

- (void)updateCell_:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    NSString* text;
    NSArray* shelves = [PRDocumentManager sharedManager].shelves;
    PRShelf* shelf = nil;
    if (indexPath.row == shelves.count) {
        text = @"";
    } else {
        shelf = [shelves objectAtIndex:indexPath.row];
        text = shelf.name;
    }
    UITextField* tf = ((PRTextInputCell*)cell).textField;
    tf.text = text;
    tf.textAlignment = UITextAlignmentCenter;
    tf.returnKeyType = UIReturnKeyDone;
    tf.delegate = self;
    
    // 新規追加時の最終行および編集モード時の2行目以降は編集可、それ以外は編集不可
    if ((adding_ && indexPath.row == shelves.count) || (self.editing && indexPath.row > 0)) {
        tf.enabled = YES;
    } else {
        tf.enabled = NO;
    }
    
    if (shelf == [PRDocumentManager sharedManager].currentShelf) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

#pragma mark - Action

- (IBAction)addAction
{
    // 末尾に行を追加
    adding_ = YES;
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:
                              [tableView_ numberOfRowsInSection:0] inSection:0];
    NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
    [tableView_ beginUpdates];
    [tableView_ insertRowsAtIndexPaths:indexPaths 
                      withRowAnimation:UITableViewRowAnimationBottom];
    [tableView_ endUpdates];
    
    // スクロール
    // endUpdateの前に実行すると、エラー
    [tableView_ scrollToRowAtIndexPath:indexPath 
                      atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
    // フォーカスの設定
    PRTextInputCell* cell = (PRTextInputCell*)[tableView_ cellForRowAtIndexPath:indexPath];
    [cell.textField becomeFirstResponder];
}

- (IBAction)endAction
{
    PRTextInputCell* cell = [self findReanamingCell];
    [cell.textField resignFirstResponder];
}

#pragma mark - UITableView データソース

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [PRDocumentManager sharedManager].shelves.count + (adding_ ? 1 : 0);
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [tableView_ dequeueReusableCellWithIdentifier:@"ShelfListCell"];
    if (!cell) {
        cell = [[PRTextInputCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                      reuseIdentifier:@"ShelfListCell"];
        [cell autorelease];
    }
    
    // セルの値を更新する
    [self updateCell_:cell atIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    return indexPath.row > 0;
}

- (BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
    return indexPath.row > 0;
}

- (NSIndexPath*)tableView:(UITableView*)tableView 
        targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath 
        toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath 
{
    if (proposedDestinationIndexPath.row == 0) {
        return [NSIndexPath indexPathForRow:1 inSection:0];
    } else {
        return proposedDestinationIndexPath;
    }
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)fromIndexPath 
      toIndexPath:(NSIndexPath*)toIndexPath
{
    // 本棚を移動する
    [[PRDocumentManager sharedManager] 
     moveShelfAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
    [[PRDocumentManager sharedManager] save];
}

- (void)tableView:(UITableView*)tableView 
        commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
        forRowAtIndexPath:(NSIndexPath*)indexPath
{
    PRShelf* shelf = [[PRDocumentManager sharedManager].shelves objectAtIndex:indexPath.row];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        deletingRow_ = indexPath.row;
        if (shelf.documentCount > 0) {
            // 削除操作の場合
            // アラートを表示する
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"本棚の削除" 
                    message:[NSString stringWithFormat:
                    @"含まれているドキュメントも同時に削除されます。\n%@を削除してもよろしいですか？", shelf.name]
                    delegate:self cancelButtonTitle:@"いいえ" otherButtonTitles:@"はい", nil];
            [alert autorelease];
            [alert show];
        } else {
            [self removeSelectedShelf_];
        }
    }
}

#pragma mark - UITableView デリゲート

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    selectedShelf_ = [[PRDocumentManager sharedManager].shelves objectAtIndex:indexPath.row];
    
    // デリゲートに通知する
    if ([delegate_ respondsToSelector:@selector(shelfListControllerShelfDidSelect:)]) {
        [delegate_ shelfListControllerShelfDidSelect:self];
    }
}

#pragma mark - UITextField デリゲート

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    KLDBGPrintMethodName("▼ ");
    if (!adding_) {
        renaming_ = YES;
    }
    [self updateNavigationItemAnimated_:YES];        
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    KLDBGPrintMethodName("▼ ");
    [textField resignFirstResponder];
    NSString* text = [textField.text stringByTrimmingCharactersInSet:
                      [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (adding_) {
        // 末尾の行が空なら、行を削除、入力されていれば本棚を追加
        adding_ = NO;
        if (text.length == 0) {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:
                                      [tableView_ numberOfRowsInSection:0]-1 inSection:0];        
            [tableView_ beginUpdates];
            [tableView_ deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                              withRowAnimation:UITableViewRowAnimationBottom];
            [tableView_ endUpdates];
        } else {
            PRShelf* shelf = [[PRShelf alloc] initWithName:text];
            [[PRDocumentManager sharedManager] addShelf:shelf];
            [shelf release];
            textField.enabled = NO;
        }
    } else {
        renaming_ = NO;
        PRTextInputCell* cell = [self findCellForTextField_:textField];
        NSIndexPath* indexPath = [tableView_ indexPathForCell:cell];            
        PRShelf* shelf = [[PRDocumentManager sharedManager].shelves 
                          objectAtIndex:indexPath.row];
        
        if (text.length > 0) {
            if ([text compare:shelf.name] != NSOrderedSame) {
                // 本棚の名称を変更する
                shelf.name = text;
                [[PRDocumentManager sharedManager] save];
            }
        } else {
            textField.text = shelf.name;
        }
    }
    
    // ボタンの更新
    [self updateNavigationItemAnimated_:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    KLDBGPrintMethodName("▼ ");
    [textField resignFirstResponder];
    return YES;
}

- (PRTextInputCell*)findCellForTextField_:(UITextField*)textField
{
    NSInteger nRows = [tableView_ numberOfRowsInSection:0];
    for (NSInteger row = 0; row < nRows; row++) {
        UITableViewCell* cell = [tableView_ cellForRowAtIndexPath:
                                 [NSIndexPath indexPathForRow:row inSection:0]];
        UITextField* tf = ((PRTextInputCell*)cell).textField;
        if (tf == textField) {
            return (PRTextInputCell*)cell;
        }
    }
    return nil;
}

- (PRTextInputCell*)findReanamingCell
{
    NSInteger nRows = [tableView_ numberOfRowsInSection:0];
    for (NSInteger row = 0; row < nRows; row++) {
        UITableViewCell* cell = [tableView_ cellForRowAtIndexPath:
                                 [NSIndexPath indexPathForRow:row inSection:0]];
        UITextField* tf = ((PRTextInputCell*)cell).textField;
        if (tf.isFirstResponder) {
            return (PRTextInputCell*)cell;
        }
    }
    return nil;
}

#pragma mark UIAlertViewデリゲート

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self removeSelectedShelf_];
    }
}

- (void)removeSelectedShelf_
{
    // ドキュメントを削除する
    [[PRDocumentManager sharedManager] removeShelfAtIndex:deletingRow_];
    
    // 情報を保存する
    [[PRDocumentManager sharedManager] save];
    
    // テーブルの行を削除する
    [tableView_ beginUpdates];
    [tableView_ deleteRowsAtIndexPaths:[NSArray arrayWithObject:
                    [NSIndexPath indexPathForRow:deletingRow_ inSection:0]] 
                    withRowAnimation:UITableViewRowAnimationRight];
    [tableView_ endUpdates];
}

@end
