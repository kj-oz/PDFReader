//
//  PRTextInputCell.m
//  PDFReader
//
//  Created by KO on 12/01/16.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import "PRTextInputCell.h"

@implementation PRTextInputCell

@synthesize textField = textField_;

#pragma mark - 初期化

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        textField_ = [[UITextField alloc] initWithFrame:CGRectZero];
        textField_.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        textField_.clearButtonMode = UITextFieldViewModeWhileEditing;
        [self.contentView addSubview:textField_];
        
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
    [textField_ release], textField_ = nil;
    [super dealloc];
}

#pragma mark - 描画処理

- (void)layoutSubviews {
    [super layoutSubviews];
    textField_.frame = CGRectInset(self.contentView.bounds, 10, 0);
}

@end
