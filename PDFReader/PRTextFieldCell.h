//
//  PRTextFieldCell.h
//  PDFReader
//
//  Created by KO on 12/01/16.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * テキスト入力欄となるセル
 */
@interface PRTextFieldCell : UITableViewCell
{
    // TextFieldコントロール
    UITextField* textField_;
}

@property (nonatomic, readonly) UITextField* textField;

@end
