//
//  PRDocumentManager.h
//  PDFReader
//
//  Created by KO on 11/10/01.
//  Copyright 2011年 KO All rights reserved.
//

#import <Foundation/Foundation.h>

@class PRDocument;

/**
 * ドキュメントデータを管理するクラス.
 * シングルトンオブジェクトで使用する。
 */
@interface PRDocumentManager : NSObject
{
    // Documentディレクトリーのパス
    NSString* documentDirectory_;
    
    // ドキュメント配列
    NSMutableArray* documents_;
    
    // 現在表示中のドキュメント
    PRDocument* currentDocument_;   // documents_で保持しているためcurrentDocument_はretainしない
}

@property (nonatomic, readonly) NSString* documentDirectory;
@property (nonatomic, readonly) NSArray* documents;
@property (nonatomic, assign) PRDocument* currentDocument;

/**
 * シングルトンオブジェクトを得る.
 */
+ (PRDocumentManager*)sharedManager;

/**
 * ドキュメントを追加する.
 * @param document 追加するドキュメント
 */
- (void)addDocument:(PRDocument*)document;

/**
 * ドキュメントを指定の位置に挿入する.
 * @param document 挿入するドキュメント
 * @param index 挿入する位置
 */
- (void)insertDocument:(PRDocument*)document atIndex:(NSUInteger)index;

/**
 * 指定のドキュメントを削除する.
 * @param document 削除するドキュメント
 */
- (void)removeDocument:(PRDocument*)document;

/**
 * 指定の位置のドキュメントを削除する.
 * @param index 削除する位置
 */
- (void)removeDocumentAtIndex:(NSUInteger)index;

/**
 * 指定の位置のドキュメントを別な位置に移動する.
 * @param fromIndex 移動元の位置
 * @param toIndex 移動先の位置
 */
- (void)moveDocumentAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

/**
 * Libraryディレクトリからデータを読み込む.
 */
- (void)load;

/**
 * Libraryディレクトリにデータを書き出す.
 */
- (void)save;

@end
