//
//  PRTagDetailController.m
//  PDFReader
//
//  Created by KO on 12/01/12.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import "PRTagDetailController.h"
#import "PRTextInputCell.h"
#import "PRTag.h"

// 付箋追加/編集画面で最後に選択されたプリセット色のインデックス
static NSUInteger lastSelectedPresetColorIndex_ = 0;

@interface PRTagDetailController (Private)

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

@implementation PRTagDetailController

@synthesize delegate = delegate_;
@synthesize new = new_;
@synthesize tag = tag_;
@synthesize originalColor = originalColor_;

#pragma mark - アクセッサ

- (void)setTag:(PRTag *)tag 
{
    if (tag_ != nil) {
        [tag_ release], tag_ = nil;
    }
    tag_ = [tag retain];
    
    if (tag != nil) {
        NSInteger presetColor = [PRTag findPresetColor:tag_.color];
        if (presetColor < 0) {
            originalColor_ = YES;
            selectedColorRow_ = 0;
        } else {
            originalColor_ = NO;
            selectedColorRow_ = presetColor;
        }
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
    originalColor_ = NO;
    selectedColorRow_ = lastSelectedPresetColorIndex_;
}

- (id)init
{
    return [self initWithNibName:@"TagDetail" bundle:nil];
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
    [tag_ release], tag_ = nil;
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
    if ([delegate_ respondsToSelector:@selector(tagDetailControllerDidCancel:)]) {
        [delegate_ tagDetailControllerDidCancel:self];
    }
}

- (IBAction)doneAction
{
    if (!tag_) {
        tag_ = [[PRTag alloc] init];
        tag_.rotation = 1;
        tag_.origin = CGPointMake(0.0, tag_.size.width);        
    }
    
    PRTextInputCell* textCell = (PRTextInputCell*)[self cellAtSection_:0 row:0];
    tag_.text = textCell.textField.text;
    
    UITableViewCell* colorCell = [self cellAtSection_:1 row:selectedColorRow_];
    tag_.color = colorCell.backgroundColor;
    
    NSInteger selectedPresetColorIndex = selectedColorRow_;
    if (originalColor_) {
        selectedPresetColorIndex--;
    }
    if (selectedPresetColorIndex >= 0) {
        lastSelectedPresetColorIndex_ = selectedPresetColorIndex;
    }
    
    // デリゲートに通知する
    if ([delegate_ respondsToSelector:@selector(tagDetailControllerDidSave:)]) {
        [delegate_ tagDetailControllerDidSave:self];
    }
}

#pragma mark - UITableView データソース

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 1;
        case 1:
            return [PRTag presetColorCount] + (originalColor_ ? 1 : 0);
    }
    return 0;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"ラベル";
        case 1:
            return @"色";
    }
    return nil;
}

- (UITableViewCell*)tableView:(UITableView*)tableView 
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = nil;
    switch (indexPath.section) {
        case 0:
            cell = [tableView_ dequeueReusableCellWithIdentifier:@"TextInputCell"];
            if (!cell) {
                cell = [[PRTextInputCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TextInputCell"];
                [cell autorelease];
            }
            
            PRTextInputCell* tiCell = (PRTextInputCell*)cell;
            tiCell.textField.text = tag_.text;
            tiCell.textField.placeholder = @"ラベル文字列";
            tiCell.textField.keyboardType = UIKeyboardTypeDefault;
            break;
            
        case 1:
            // セルを取得する
            cell = [tableView_ dequeueReusableCellWithIdentifier:@"ColorCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] 
                        initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ColorCell"];
                [cell autorelease];
            }
            
            // セルの値を更新する
            if (originalColor_ && indexPath.row == 0) {
                cell.backgroundColor = tag_.color;
            } else {
                NSUInteger presetIndex = indexPath.row;
                if (originalColor_) {
                    presetIndex--;
                }
                cell.backgroundColor = [PRTag presetColorAtIndex:presetIndex];
            }
            
            if (indexPath.row == selectedColorRow_) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
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

#pragma mark - UITableView デリゲート

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == 1) {
        if (indexPath.row == selectedColorRow_) return;
        
        UITableViewCell* oldCell = [self cellAtSection_:1 row:selectedColorRow_];
        oldCell.accessoryType = UITableViewCellAccessoryNone;
        
        UITableViewCell* newCell = [tableView_ cellForRowAtIndexPath:indexPath];
        newCell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        selectedColorRow_ = indexPath.row;
    }
}

@end
