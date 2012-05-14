//
//  PRDocumentDetailController.m
//  PDFReader
//
//  Created by KO on 12/03/13.
//  Copyright (c) 2012年 KO All rights reserved.
//

#import "PRDocumentDetailController.h"
#import "PRTextInputCell.h"
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
        doneButton_.title = @"ダウンロード";
    }
    [self.navigationItem setLeftBarButtonItem:cancelButton_ animated:animated];
    [self.navigationItem setRightBarButtonItem:doneButton_ animated:animated];
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
    // 新規の場合空のドキュメントを準備
    if (!document_) {
        document_ = [[PRDocument alloc] init];
    }
    
    // URL
    if (new_) {
        PRTextInputCell* urlCell = (PRTextInputCell*)[self cellAtSection_:0 row:0];
        url_ = urlCell.textField.text;
        // URLが入力されていることをチェック
        if (url_.length == 0) {
            // アラートを表示する
            UIAlertView* alert = [[UIAlertView alloc] 
                                  initWithTitle:@"文書の追加" 
                                  message:@"URLを入力して下さい。" 
                                  delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert autorelease];
            [alert show];
            return;
        }
    }        
    
    // タイトル
    NSInteger section = new_ ? 1 : 0;
    PRTextInputCell* titleCell = (PRTextInputCell*)[self cellAtSection_:section row:0];
    document_.title = titleCell.textField.text;
    // タイトルが入力されていることをチェック
    if (document_.title.length == 0) {
        NSString* header = new_ ? @"文書の追加" : @"文書の変更";
        // アラートを表示する
        UIAlertView* alert = [[UIAlertView alloc] 
                              initWithTitle:header 
                              message:@"タイトルを入力して下さい。" 
                              delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert autorelease];
        [alert show];
        return;
    }
    
    // ファイル名
    if (new_) {
        PRTextInputCell* fileNameCell = (PRTextInputCell*)[self cellAtSection_:2 row:0];
        document_.fileName = fileNameCell.textField.text;

        // ファイル名が入力されていることをチェック
        if (document_.fileName.length == 0) {
            // アラートを表示する
            UIAlertView* alert = [[UIAlertView alloc] 
                                  initWithTitle:@"文書の追加" 
                                  message:@"ファイル名を入力して下さい。" 
                                  delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert autorelease];
            [alert show];
            return;
        }

        // 同じ名称の既存のファイルの存在チェック
        NSString* pdfPath = [NSString stringWithFormat:@"%@/%@", 
                    [PRDocumentManager sharedManager].documentDirectory, document_.fileName];
        
        NSFileManager* fileManager = [NSFileManager defaultManager];
        if (new_ && [fileManager fileExistsAtPath:pdfPath]) {
            // アラートを表示する
            UIAlertView* alert = [[UIAlertView alloc] 
                        initWithTitle:@"文書の追加" 
                        message:@"既に存在するファイル名です。別な名前を指定して下さい。" 
                        delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert autorelease];
            [alert show];
            return;
        }

        // ドキュメントのダウンロード開始
        PRConnector* connector = [PRConnector sharedConnector];
        [connector downloadDocument:document_ withUrlString:url_];
    }    

    // デリゲートに通知する
    if ([delegate_ respondsToSelector:@selector(documentDetailControllerDidSave:)]) {
        [delegate_ documentDetailControllerDidSave:self];
    }
}

#pragma mark - UITableView データソース

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return new_ ? 3 : 2;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    if (!new_) {
        section++;
    }
    switch (section) {
        case 0:
            return @"URL";
        case 1:
            return @"タイトル";
        case 2:
            return @"ファイル名";
    }
    return nil;
}

- (UITableViewCell*)tableView:(UITableView*)tableView 
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [tableView_ dequeueReusableCellWithIdentifier:@"TextInputCell"];
    if (!cell) {
        cell = [[PRTextInputCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TextInputCell"];
        [cell autorelease];
    }
    
    PRTextInputCell* tiCell = (PRTextInputCell*)cell;
    NSInteger section = new_ ? indexPath.section : indexPath.section + 1;
    switch (section) {
        case 0:
            tiCell.textField.text = url_;
            tiCell.textField.keyboardType = UIKeyboardTypeURL;
            tiCell.textField.delegate = self;
            tiCell.textField.placeholder = @"URL";
            break;
            
        case 1:
            tiCell.textField.text = document_.title;
            tiCell.textField.keyboardType = UIKeyboardTypeDefault;
            tiCell.textField.placeholder = @"タイトル";
            break;
            
        case 2:
            tiCell.textField.text = document_.fileName;
            tiCell.textField.keyboardType = UIKeyboardTypeDefault;
            if (!new_) {
                tiCell.textField.enabled = NO;
            }
            tiCell.textField.placeholder = @"ファイル名";
            break;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
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

- (void)textFieldDidEndEditing:(UITextField*)textField
{
    // 他のセルが空の状態でURLを入力した場合、タイトルとファイル名にもその名称が設定される
    NSString* url = textField.text;
    if (url.length > 0) {
        NSString* fileName = url.lastPathComponent;
        UITableViewCell* cell = [self cellAtSection_:1 row:0];
        PRTextInputCell* tiCell = (PRTextInputCell*)cell;
        if (tiCell.textField.text.length == 0) {
            tiCell.textField.text = fileName;
        }
        cell = [self cellAtSection_:2 row:0];
        tiCell = (PRTextInputCell*)cell;
        if (tiCell.textField.text.length == 0) {
            tiCell.textField.text = fileName;
        }
    }
}

@end
