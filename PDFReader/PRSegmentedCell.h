//
//  PRSegmentedCell.h
//  PDFReader
//
//  Created by KO on 12/08/04.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * セグメントコントロールによる選択を行うセル
 */
@interface PRSegmentedCell : UITableViewCell
{
    // Segmentedコントロール
    UISegmentedControl* segmentedCtrl_;
}

@property (nonatomic, readonly) UISegmentedControl* segmentedCtrl;

/**
 * 指定の文字列配列で初期化されたセグメントコントロールで初期化する.
 * @param style セルスタイル
 * @param items 選択肢となる文字配列
 * @param reuseIdentifier 再利用ID
 * @return 初期化されたセグメントコントロール入りセル
 */
- (id)initWithStyle:(UITableViewCellStyle)style items:(NSArray*)items reuseIdentifier:(NSString *)reuseIdentifier;

@end
