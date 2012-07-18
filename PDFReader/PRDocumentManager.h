//
//  PRDocumentManager.h
//  PDFReader
//
//  Created by KO on 11/10/01.
//  Copyright 2011年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PRShelf;
@class PRDocument;

/**
 * ドキュメントデータを管理するクラス.
 * シングルトンオブジェクトで使用する。
 */
@interface PRDocumentManager : NSObject
{
    // Documentディレクトリーのパス
    NSString* documentDirectory_;
    
    // 本棚の配列
    NSMutableArray* shelves_;
    
    // カレントの本棚
    PRShelf* currentShelf_;         // shelfs_で保持しているためcurrentShelf_はretainしない

    // 現在表示中のドキュメント
    PRDocument* currentDocument_;   // shelfs_で保持しているためcurrentDocument_はretainしない
}

@property (nonatomic, readonly) NSString* documentDirectory;
@property (nonatomic, readonly) NSArray* shelves;
@property (nonatomic, assign) PRShelf* currentShelf;
@property (nonatomic, assign) PRDocument* currentDocument;

/**
 * シングルトンオブジェクトを得る.
 */
+ (PRDocumentManager*)sharedManager;

/**
 * カレントの本棚にドキュメントを追加する.
 * @param document 追加するドキュメント
 */
- (void)addDocument:(PRDocument*)document;

/**
 * ドキュメントをカレントの本棚の指定の位置に挿入する.
 * @param document 挿入するドキュメント
 * @param index 挿入する位置
 */
- (void)insertDocument:(PRDocument*)document atIndex:(NSUInteger)index;

/**
 * 指定のドキュメントを（いずれかの本棚から）削除する.
 * @param document 削除するドキュメント
 */
- (void)removeDocument:(PRDocument*)document;

/**
 * カレントの本棚の指定の位置のドキュメントを削除する.
 * @param index 削除する位置
 */
- (void)removeDocumentAtIndex:(NSUInteger)index;

/**
 * 指定の複数のドキュメントを（いずれかの本棚から）削除する.
 * @param documents 削除する複数のドキュメント
 */
- (void)removeDocuments:(NSArray*)documents;

/**
 * カレントの本棚の指定の位置のドキュメントを別な位置に移動する.
 * @param fromIndex 移動元の位置
 * @param toIndex 移動先の位置
 */
- (void)moveDocumentAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

/**
 * 本棚を追加する.
 * @param shelf 追加する本棚
 */
- (void)addShelf:(PRShelf*)shelf;

/**
 * 本棚を指定の位置に挿入する.
 * @param shelf 挿入する本棚
 * @param index 挿入する位置
 */
- (void)insertShelf:(PRShelf*)shelf atIndex:(NSUInteger)index;

/**
 * 指定の本棚を削除する.属するドキュメントも全て削除される.
 * @param shelf 削除する本棚
 */
- (void)removeShelf:(PRShelf*)document;

/**
 * 指定の位置の本棚を削除する.
 * @param index 削除する位置
 */
- (void)removeShelfAtIndex:(NSUInteger)index;

/**
 * 指定の位置のド本棚を別な位置に移動する.
 * @param fromIndex 移動元の位置
 * @param toIndex 移動先の位置
 */
- (void)moveShelfAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

/**
 * Libraryディレクトリからデータを読み込む.
 */
- (void)load;

/**
 * Libraryディレクトリにデータを書き出す.
 */
- (void)save;

/**
 * 既存のファイルと重複しない名称を返す.
 * @param original 元の名称
 * @return 重複しない名称（元の名称がabc.pdfの場合、abc(n).pdf）
 */
- (NSString*)findUniqName:(NSString*)original;

@end
