//
//  PRConnector.h
//  PDFReader
//
//  Created by KO on 12/03/04.
//  Copyright (c) 2012年 KO All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString*    PRConnectorDidBeginDownload;
extern NSString*    PRConnectorInProgressDownload;
extern NSString*    PRConnectorDidFinishDownload;

@class PRDocument;
@class KLNetURLDownloader;

/**
 * ネットワークアクセスを管理するクラス.
 * シングルトンオブジェクトで使用する。
 */
@interface PRConnector : NSObject
{
    // ダウンロードオブジェクトと対象ドキュメントのマップ
    // NSMutableDictionaryでは、キーがコピーされる（NSCoyingの実装が必須）ためCF*を使用
    CFMutableDictionaryRef downloaders_;
}

/**
 * ネットワークアクセス中かどうか.
 */
@property (nonatomic, readonly, getter=isNetworkAccessing) BOOL networkAccessing;

/**
 * シングルトンオブジェクトを得る.
 */
+ (PRConnector*)sharedConnector;

/**
 * ドキュメントをダウンロード中のダウンロードオブジェクトを得る.
 * @param doc ドキュメント
 * @return 指定のドキュメントをダウンロードしているダウンロードオブジェクト
 */
- (KLNetURLDownloader*)downloaderForDocument:(PRDocument*)doc;

/**
 * 指定のドキュメントのPDFを与えられたURLからダウンロードする処理を開始する.
 * @param doc ドキュメント
 * @param urlString URL
 */
- (void)downloadDocument:(PRDocument*)doc withUrlString:(NSString*)urlString;

/**
 * 指定のドキュメントのダウンロードを中止する.
 * @param doc ドキュメント
 */
- (void)cancelDownloadDocument:(PRDocument*)doc;

@end
