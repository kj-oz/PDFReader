//
//  KLPVPageViewDelegate.h
//  KLib PageView
//
//  Created by KO on 12/02/02.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * ページビュー上での各種操作に対する処理を行うオブジェクト.
 * 通常はビューコントローラがこの役を担う.
 */
@protocol KLPVPageViewDelegate <NSObject>

/**
 * カレントのページが変更されると呼び出されるメソッド.
 */
- (void)pageViewCurrentPageDidChange;

/**
 * 付箋ビューの編集が指示されると呼び出されるメソッド.
 * @param sender 付箋ビュー
 */
- (void)editTagAction:(id)sender;

/**
 * 付箋ビューの削除が指示されると呼び出されるメソッド.
 * @param sender 付箋ビュー
 */
- (void)deleteTagAction:(id)sender;

/**
 * ページビューの中では解釈されないタップが発生した場合に呼び出されるメソッド.
 * @param touch タッチオブジェクト
 */
- (void)tappedWithTouch:(CGPoint)location;

@end
