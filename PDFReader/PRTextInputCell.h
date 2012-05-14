//
//  PRTextInputCell.h
//  PDFReader
//
//  Created by KO on 12/01/16.
//  Copyright (c) 2012年 KO All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * テキスト入力欄となるセル
 */
@interface PRTextInputCell : UITableViewCell
{
    UITextField* textField_;
}

@property (nonatomic, retain) UITextField* textField;

@end
