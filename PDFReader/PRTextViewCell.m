//
//  PRTextViewCell.m
//  PDFReader
//
//  Created by KO on 12/08/02.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import "PRTextViewCell.h"

@interface PRTextViewCell (Private)

/**
 * 与えられた文字列に改行が入っているかどうかを調べる.
 * @param string 文字列
 * @return 改行が入っていればYES
 */
- (BOOL)hasNewLine_:(NSString*)string;

/**
 * 与えられた文字列にいくつ改行が入っているかを調べる.
 * @param string 文字列
 * @return 改行の数
 */
- (NSInteger)countNewLine_:(NSString*)string;

@end

@implementation PRTextViewCell

@synthesize textView = textView_;
@synthesize maxLine = maxLine_;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        textView_ = [[UITextView alloc] initWithFrame:CGRectZero];
        textView_.textAlignment = UITextAlignmentCenter;
        textView_.font = [UIFont systemFontOfSize:16.0f];
        textView_.delegate = self;
        [self.contentView addSubview:textView_];
        [textView_ release];
        
        maxLine_ = -1;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)dealloc
{
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
    // 指定行以上入力できないようにする
    if (maxLine_ >= 0 && [self hasNewLine_:text]) {
        return [self countNewLine_:textView.text] < maxLine_ - 1;
    }
    return YES;
}

- (BOOL)hasNewLine_:(NSString*)string
{
    return [string rangeOfCharacterFromSet:[NSCharacterSet 
                                          newlineCharacterSet]].location != NSNotFound;
}

- (NSInteger)countNewLine_:(NSString*)string
{
    NSUInteger occurence = 0;
    for (NSInteger i = 0, n = string.length; i < n; i++) {
        if ([string characterAtIndex:i] == '\n') {
            occurence++;
        }
    }
    return occurence;
}

@end
