//
//  PRTag.h
//  PDFReader
//
//  Created by KO on 11/12/13.
//  Copyright (c) 2011年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 付箋の情報.
 */
@interface PRTag : NSObject <NSCoding>
{
    // 付箋のID
    NSString* uid_;
    
    // 属するページ
    NSUInteger page_;
    
    // 付箋の位置（水平の場合の左上角のページ原点からの位置）
    CGPoint origin_;
    
    // 付箋のサイズ（水平の場合の枠サイズ）
    CGSize size_;
    
    // 付箋の外側の色の帯の高さ
    CGFloat colorHeight_;
    
    // 付箋の外側の帯の色
    UIColor* color_;
    
    // 付箋の文字列
    NSString* text_;
    
    // 付箋の文字列のサイズ
    CGFloat fontSize_;
    
    // 付箋の回転（0:水平（上が外側）、1:左が外側、2:下が外側、3:右が外側)
    NSUInteger rotation_;
}

@property (nonatomic, readonly) NSString* uid;
@property (nonatomic, assign) NSUInteger page;
@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat colorHeight;
@property (nonatomic, retain) UIColor* color;
@property (nonatomic, copy) NSString* text;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, assign) NSUInteger rotation;

// 付箋中央の位置（ページ原点から）
@property (nonatomic, readonly) CGPoint center;

/**
 * 指定の色と一致するプリセット色を返す.
 * @param color 色
 * @return プリセット色のインデックス、見つからない場合-1
 */
+ (NSInteger)findPresetColor:(UIColor*)color;

/**
 * 指定のインデックスのプリセット色を返す.
 * @param index インデックス
 * @return 色
 */
+ (UIColor*)presetColorAtIndex:(NSUInteger)index;

/**
 * プリセット色の数を返す.
 * @return プリセット色の数
 */
+ (NSUInteger)presetColorCount;

@end
