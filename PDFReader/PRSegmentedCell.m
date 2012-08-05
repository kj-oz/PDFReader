//
//  PRSegmentedCell.m
//  PDFReader
//
//  Created by KO on 12/08/04.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import "PRSegmentedCell.h"

@implementation PRSegmentedCell

@synthesize segmentedCtrl = segmentedCtrl_;

- (id)initWithStyle:(UITableViewCellStyle)style items:(NSArray*)items 
    reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        segmentedCtrl_ = [[UISegmentedControl alloc] initWithItems:items];
        [self.contentView addSubview:segmentedCtrl_];
        [segmentedCtrl_ release];
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

- (void)layoutSubviews {
    [super layoutSubviews];
    segmentedCtrl_.frame = self.contentView.bounds;
}

@end
