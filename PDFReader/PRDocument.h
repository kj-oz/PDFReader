//
//  PRDocument.h
//  PDFReader
//
//  Created by KO on 11/10/01.
//  Copyright 2011年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * ドキュメントデータ.
 */
@interface PRDocument : NSObject <NSCoding>
{
    // ドキュメントのID
    NSString* uid_;
    
    // PDFドキュメントへの参照
    CGPDFDocumentRef pdfDoc_;
    
    // ページ毎の付箋配列の配列
    NSMutableArray* tagArrays_;
    
    // ドキュメント一覧上で付箋を表示する状態
    BOOL tagOpened_;
    
    // ディレクトリを含まないPDFファイル名
    NSString* fileName_;
    
    // ドキュメントのタイトル
    NSString* title_;
    
    // ドキュメントの著者
    NSString* author_;
    
    // 最終更新日
    NSString* modDate_;
    
    // 総ページ数
    NSUInteger numPages_;
    
    // 最後にアクセスしたページ番号（最初のページが0、一度も開いていない場合-1）
    NSInteger currentPageIndex_;
}

@property (nonatomic, readonly) NSString* uid;
@property (nonatomic, readonly) CGPDFDocumentRef pdfDoc;
@property (nonatomic, readonly) NSMutableArray* tagArrays;
@property (nonatomic, assign) BOOL tagOpened;
@property (nonatomic, copy) NSString* fileName;
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* author;
@property (nonatomic, copy) NSString* modDate;
@property (nonatomic, readonly) NSUInteger numPages;
@property (nonatomic, assign) NSInteger currentPageIndex;

/**
 * 指定のページの付箋の配列を得る.
 * @param pageIndex ページ番号（最初のページが0）
 */
- (NSMutableArray*)tagsAtPageIndex:(NSUInteger)pageIndex;

/**
 * 初出のPDFファイルに対する初期化.
 * @param pdfPath PDFファイルのパス
 */
- (id)initWithPath:(NSString*)pdfPath;

/**
 * ドキュメントの中身を解放する.
 */
- (void)releaseContents;

/**
 * ドキュメントの中身を読み込む.
 */
- (void)loadContents;

/**
 * ドキュメントの中身を書き出す.
 */
- (void)saveContents;

/**
 * PDFファイルが正常に読み込めるかを確認し、ページ数を取得する.
 * @return PDFファイルが正常に読み込めるか
 */
- (BOOL)checkPdf;

@end
