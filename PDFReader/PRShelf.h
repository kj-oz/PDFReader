//
//  PRShelf.h
//  PDFReader
//
//  Created by KO on 12/06/08.
//  Copyright (c) 2012年 KO All rights reserved.
//

#import <Foundation/Foundation.h>

@class PRDocument;

/**
 * 本棚（ドキュメントのコレクション）.
 */
@interface PRShelf : NSObject <NSCoding>
{
    //  本棚のID
    NSString* uid_;
    
    // 本棚の名称
    NSString* name_;

    // ドキュメント配列
    NSMutableArray* documents_;
}

@property (nonatomic, readonly) NSString* uid;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, readonly) NSArray* documents;
@property (nonatomic, readonly) NSUInteger documentCount;

/**
 * 与えられた名称で本棚を初期化.
 * @param name
 */
- (id)initWithName:(NSString*)name;

- (PRDocument*)documentAtIndex:(NSUInteger)index;

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
 * 指定の複数のドキュメントを削除する.
 * @param documents 削除する複数のドキュメント
 */
- (void)removeDocuments:(NSArray*)documentss;

/**
 * 指定の位置のドキュメントを別な位置に移動する.
 * @param fromIndex 移動元の位置
 * @param toIndex 移動先の位置
 */
- (void)moveDocumentAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end
