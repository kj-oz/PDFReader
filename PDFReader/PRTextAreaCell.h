//
//  PRTextAreaCell.h
//  PDFReader
//
//  Created by KO on 12/08/02.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PRTextAreaCell : UITableViewCell <UITextViewDelegate>
{
    UITextView* textView_;
}

@property (nonatomic, retain) UITextView* textView;

@end
