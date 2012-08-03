//
//  PRTextAreaCell.m
//  PDFReader
//
//  Created by KO on 12/08/02.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import "PRTextAreaCell.h"

@interface PRTextAreaCell (Private)

/**
 * 与えられた文字列に改行が入っているかどうかを調べる.
 * @param text 文字列
 * @return 改行が入っていればYES
 */
- (BOOL)hasNewLine_:(NSString*)text;

@end

@implementation PRTextAreaCell

@synthesize textView = textView_;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        textView_ = [[UITextView alloc] initWithFrame:CGRectZero];
        textView_.textAlignment = UITextAlignmentCenter;
        textView_.font = [UIFont systemFontOfSize:16.0f];
        textView_.delegate = self;
        [self.contentView addSubview:textView_];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc
{
    [textView_ release], textView_ = nil;
    [super dealloc];
}

#pragma mark - 描画処理

- (void)layoutSubviews 
{
    [super layoutSubviews];
    textView_.frame = CGRectInset(self.contentView.bounds, 40, 0);
    textView_.backgroundColor = self.backgroundColor;
}

#pragma mark - UITextView デリゲート

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range 
                    replacementText:(NSString *)text
{
    // ２行以上入力できないようにする
    if ([self hasNewLine_:text]) {
        return ![self hasNewLine_:textView.text];
    }
    return YES;
}

- (BOOL)hasNewLine_:(NSString*)text
{
    return [text rangeOfCharacterFromSet:[NSCharacterSet 
                                          newlineCharacterSet]].location != NSNotFound;
}

@end
