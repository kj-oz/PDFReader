//
//  PRDocumentDetailController.m
//  PDFReader
//
//  Created by KO on 12/03/13.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import "PRDocumentDetailController.h"
#import "PRTextFieldCell.h"
#import "PRSegmentedCell.h"
#import "PRDocument.h"
#import "PRDocumentManager.h"
#import "PRConnector.h"


@interface PRDocumentDetailController (Private)

/**
 * 各種initメソッドから呼びだされる共通の初期化処理.
 */
- (void)init_;

/**
 * アウトレットの解放.
 */
- (void)releaseOutlets_;

/**
 * セクションと行からセルを取得するヘルパメソッド.
 * @param section セクション
 * @param row 行
 * @return セルオブジェクト
 */
- (UITableViewCell*)cellAtSection_:(NSInteger)section row:(NSInteger)row;

@end

@implementation PRDocumentDetailController

@synthesize delegate = delegate_;
@synthesize new = new_;
@synthesize document = document_;

#pragma mark - アクセッサ

- (void)setDocument:(PRDocument*)document 
{
    if (document_ != nil) {
        [document_ release], document_ = nil;
    }
    document_ = [document retain];
    
    if (document != nil) {
        new_ = NO;
    } else {
        new_ = YES;
    }
}

#pragma mark - ヘルパメソッド

- (UITableViewCell*)cellAtSection_:(NSInteger)section row:(NSInteger)row
{
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    UITableViewCell* cell = [tableView_ cellForRowAtIndexPath:indexPath];
    return cell;
}

#pragma mark - 初期化

- (void)init_
{
    new_ = YES;
    url_ = @"";
}

- (id)init
{
    return [self initWithNibName:@"DocumentDetail" bundle:nil];
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
    [cancelButton_ release], cancelButton_ = nil;
    [doneButton_ release], doneButton_ = nil;
}

- (void)dealloc
{
    [self releaseOutlets_];
    [document_ release], document_ = nil;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self releaseOutlets_];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // ナビゲーションバーを半透明化し、フルスクリーン可能に
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    // ナビゲーションアイテムの設定を行う
    if (new_) {
        [self.navigationItem setLeftBarButtonItem:cancelButton_ animated:animated];
        [self.navigationItem setRightBarButtonItem:downloadButton_ animated:animated];
    } else {
        [self.navigationItem setLeftBarButtonItem:cancelButton_ animated:animated];
        [self.navigationItem setRightBarButtonItem:doneButton_ animated:animated];
    }
}

#pragma mark - 回転のサポート

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Action

- (IBAction)cancelAction
{
    // デリゲートに通知する
    if ([delegate_ respondsToSelector:@selector(documentDetailControllerDidCancel:)]) {
        [delegate_ documentDetailControllerDidCancel:self];
    }
}

- (IBAction)doneAction
{
    PRTextFieldCell* cell = nil;

    // タイトル
    cell = (PRTextFieldCell*)[self cellAtSection_:0 row:0];
    document_.title = cell.textField.text;
    if (document_.title.length == 0) {
        // アラートを表示する
        UIAlertView* alert = [[UIAlertView alloc] 
                              initWithTitle:@"文書の変更" 
                              message:@"タイトルを入力して下さい。" 
                              delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert autorelease];
        [alert show];
        return;
    }
    
    // 著者
    cell = (PRTextFieldCell*)[self cellAtSection_:1 row:0];
    document_.author = cell.textField.text;
    
    // 最終更新日
    cell = (PRTextFieldCell*)[self cellAtSection_:2 row:0];
    document_.modDate = cell.textField.text;
    
    // 状態
    PRSegmentedCell* sCell = (PRSegmentedCell*)[self cellAtSection_:3 row:0];
    document_.status = sCell.segmentedCtrl.selectedSegmentIndex;
    
    // デリゲートに通知する
    if ([delegate_ respondsToSelector:@selector(documentDetailControllerDidSave:)]) {
        [delegate_ documentDetailControllerDidSave:self];
    }
}

- (IBAction)downloadAction
{
    // 新規の場合空のドキュメントを準備
    if (!document_) {
        document_ = [[PRDocument alloc] init];
    }
    
    PRTextFieldCell* cell = nil;

    // URL
    cell = (PRTextFieldCell*)[self cellAtSection_:0 row:0];
    url_ = cell.textField.text;
    if (url_.length == 0) {
        // アラートを表示する
        UIAlertView* alert = [[UIAlertView alloc] 
                              initWithTitle:@"文書の追加" 
                              message:@"URLを入力して下さい。" 
                              delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert autorelease];
        [alert show];
        return;
    } else if ([[url_ substringFromIndex:url_.length - 3] compare:@"pdf" 
                                                          options:NSCaseInsensitiveSearch] != NSOrderedSame) {
        // アラートを表示する
        UIAlertView* alert = [[UIAlertView alloc] 
                              initWithTitle:@"文書の追加" 
                              message:@"PDFファイルのURLを指定して下さい。" 
                              delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert autorelease];
        [alert show];
        return;
    }
        
    // ファイル名
    document_.fileName = [[PRDocumentManager sharedManager] findUniqName:url_.lastPathComponent];
    
    // ドキュメントのダウンロード開始
    PRConnector* connector = [PRConnector sharedConnector];
    [connector downloadDocument:document_ withUrlString:url_];
    
    // デリゲートに通知する
    if ([delegate_ respondsToSelector:@selector(documentDetailControllerDidSave:)]) {
        [delegate_ documentDetailControllerDidSave:self];
    }
}

#pragma mark - UITableView データソース

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return new_ ? 1 : 5;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return new_ ? @"URL" : @"タイトル";
        case 1:
            return @"作者";
        case 2:
            return @"最終更新日";
        case 3:
            return @"状態";
        case 4:
            return @"ファイル名";
    }
    return nil;
}

- (UITableViewCell*)tableView:(UITableView*)tableView 
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = nil;
    if (indexPath.section == 3) {
        cell = [tableView_ dequeueReusableCellWithIdentifier:@"SegmentedCell"];
        if (!cell) {
            cell = [[PRSegmentedCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                        items:[NSArray arrayWithObjects:@"未読", @"途中", @"読了", nil]
                                        reuseIdentifier:@"SegmentedCell"];
            [cell autorelease];
        }
        
        
        PRSegmentedCell* sCell = (PRSegmentedCell*)cell;
        if (!new_) {
            sCell.segmentedCtrl.selectedSegmentIndex = document_.status;
        } else {
            sCell.segmentedCtrl.selectedSegmentIndex = 0;
        }
    } else {
        cell = [tableView_ dequeueReusableCellWithIdentifier:@"TextInputCell"];
        if (!cell) {
            cell = [[PRTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TextInputCell"];
            [cell autorelease];
        }
        
        PRTextFieldCell* tfCell = (PRTextFieldCell*)cell;
        switch (indexPath.section) {
            case 0:
                if (new_) {
                    tfCell.textField.text = url_;
                    tfCell.textField.keyboardType = UIKeyboardTypeURL;
                    tfCell.textField.placeholder = @"URL";
                } else {
                    tfCell.textField.text = document_.title;
                    tfCell.textField.keyboardType = UIKeyboardTypeDefault;
                    tfCell.textField.placeholder = @"タイトル";
                }
                break;
                
            case 1:
                tfCell.textField.text = document_.author;
                tfCell.textField.keyboardType = UIKeyboardTypeDefault;
                tfCell.textField.placeholder = @"作者";
                break;
                
            case 2:
                tfCell.textField.text = document_.modDate;
                tfCell.textField.keyboardType = UIKeyboardTypeDefault;
                tfCell.textField.placeholder = @"最終更新日";
                break;
                
            case 4:
                tfCell.textField.text = document_.fileName;
                tfCell.textField.keyboardType = UIKeyboardTypeDefault;
                tfCell.textField.placeholder = @"ファイル名";
                tfCell.userInteractionEnabled = false;
                break;
                
        }
        tfCell.textField.delegate = self;
        tfCell.textField.tag = indexPath.section;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
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

#pragma mark - UITextField デリゲート

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    NSInteger next = textField.tag + 1;
    if (next == 3) {
        next = 0;
    }
    
    UITableViewCell* cell = [tableView_ cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:next]];
    PRTextFieldCell* tfCell = (PRTextFieldCell*)cell;
    UITextField* tf = tfCell.textField;
    if ([tf canBecomeFirstResponder]) {
        [tf becomeFirstResponder];
    }
    return YES;
}

@end
