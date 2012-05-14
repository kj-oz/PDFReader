//
//  PRPageRenderer.h
//  PDFReader
//
//  Created by KO on 11/10/09.
//  Copyright 2011年 KO All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KLPVPageViewDataSource.h"
#import "KLPVPageViewDelegate.h"

@class KLPVPageView;
@class KLPVTagView;
@class PRTag;

/**
 * PDFの内容をPageViewに提供するオブジェクト.
 */
@interface PRPageController : NSObject <KLPVPageViewDataSource>
{
    // 対象とするページと前後の３ページ分のPDFPageの参照、前、対象、後の順に配列に保持する。
	CGPDFPageRef pdfPages_[3];
    
    // 各ページの枠長方形、ピクセル座標、全体の左上原点
    CGRect pageFrames_[3];
    
    // ３ページ分全体を含む長方形のサイズ、ピクセル座標
    CGSize totalSize_;
    
    // 各ページ用の付箋の配列
    NSMutableArray* tags_[3];
    
    // 付箋ビューをキーに対象の付箋を値として保持するマップ
    CFMutableDictionaryRef tagMaps_;
    
    // 選択されている付箋
    PRTag* selectedTag_;    // Assign
    
    // 選択時に表示するマーク
    UIImage* selectedTagImage_;
    
    // ジャンプ先のページ内座標
    CGPoint targetPoint_;
}

@property (nonatomic, retain) KLPVPageView* view;

/**
 * カレントのページの適切な位置に与えられた付箋を追加する.
 * @param tag
 */
- (void)insertNewTag:(PRTag*)tag;

/**
 * 与えられた付箋に対する指定のページ用の付箋ビューを生成する.
 * @param tag 付箋
 * @param position ページ位置、0=前、1=中央、2=後
 * @param scale PDFの描画スケール
 * @return 生成された付箋ビュー、親ビューへの追加はしていない状態
 */
- (KLPVTagView*)createTagViewOfTag:(PRTag*)tag inPage:(NSUInteger)position scale:(CGFloat)scale;

/**
 * 与えられた付箋ビューに対応する付箋を返す
 * @param tagView 付箋ビュー
 * @return 対応する付箋
 */
- (PRTag*)tagOfTagView:(KLPVTagView*)tagView;

@end

