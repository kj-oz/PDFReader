//
//  PRTextViewCell.h
//  PDFReader
//
//  Created by KO on 12/08/02.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * 複数行テキスト入力欄となるセル
 */
@interface PRTextViewCell : UITableViewCell <UITextViewDelegate>
{
    // TextViewコントロール
    UITextView* textView_;
    
    // 最大行数（改行記号による行数）
    NSInteger maxLine_;
}

@property (nonatomic, readonly) UITextView* textView;
@property (nonatomic, assign) NSInteger maxLine;

@end
