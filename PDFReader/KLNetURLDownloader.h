//
//  KLNetURLDownloader.h
//  KLib Net
//
//  Created by KO on 12/03/04.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * ダウンロード中の状態
 */
enum 
{
    KLNetNetworkStateNotConnected = 0,      // 未接続 
    KLNetNetworkStateInProgress,            // ダウンロード中
    KLNetNetworkStateFinished,              // ダウンロード終了
    KLNetNetworkStateError,                 // エラー発生
    KLNetNetworkStateCanceled,              // キャンセルされた
};

/**
 * ファイルのダウンロードを行うクラス.
 */
@interface KLNetURLDownloader : NSObject
{
    // 監視オブジェクトへの参照
    id delegate_; // Assign
    
    // URL文字列
    NSString* urlString_;
    
    // ネットワークの状態
    NSInteger networkState_;
    
    // バックグラウンドタスクのID
    UIBackgroundTaskIdentifier backgroundTaskID_;
    
    // ダウンロード対象のファイルのサイズ
    NSInteger expectedSize_;
    
    // 既にダウンロード済みのデータサイズ
    NSUInteger downloadedSize_;
    
    // コネクションオブジェクト
    NSURLConnection* connection_;
    
    // ダウンロードしたデータ
    NSMutableData* downloadedData_;
    
    // 何らかのエラー発生時のエラーオブジェクト
    NSError* error_;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, readonly) NSString* urlString;
@property (nonatomic, assign) NSInteger networkState;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskID;
@property (nonatomic, readonly) NSInteger expectedSize;
@property (nonatomic, readonly) NSUInteger downloadedSize;
@property (nonatomic, readonly) NSMutableData* downloadedData;
@property (nonatomic, readonly) NSError* error;

/**
 * 指定のURLに対するダウンロードを実行するオブジェクトを得る.
 * @param urlString URL文字列
 * @reaturn ダウンロードオブジェクト
 */
- (id)initWithUrl:(NSString*)urlString;

/**
 * ダウンロードを開始する.
 */
- (void)download;

/**
 * ダウンロードをキャンセルする.
 */
- (void)cancel;

@end

/**
 * ダウンロードの進捗を監視するデリゲート.
 */
@interface NSObject (KLNetURLDownloaderDelegate)

/**
 * リクエストに対する最初のレスポンスが得られたときに呼び出されるメソッド.
 * @param downloader ダウンロードオブジェクト
 * @param response レスポンス
 */
- (void)downloader:(KLNetURLDownloader*)downloader 
            didReceiveResponse:(NSURLResponse*)response;

/**
 * データのある部分を受け取ったときに呼び出されるメソッド.
 * @param downloader ダウンロードオブジェクト
 * @param data データオブジェクト
 */
- (void)downloader:(KLNetURLDownloader*)downloader 
            didReceiveData:(NSData*)data;

/**
 * ダウンロードが正常に終了したときに呼び出されるメソッド.
 * @param downloader ダウンロードオブジェクト
 */
- (void)downloaderDidFinishLoading:(KLNetURLDownloader*)downloader;

/**
 * ダウンロードがエラーで終了したときに呼び出されるメソッド.
 * @param downloader ダウンロードオブジェクト
 * @param error エラーオブジェクト
 */
- (void)downloader:(KLNetURLDownloader*)downloader
            didFailWithError:(NSError*)error;

/**
 * ダウンロードがキャンセルされたときに呼び出されるメソッド. 
 * @param downloader ダウンロードオブジェクト
 */
- (void)downloaderDidCancel:(KLNetURLDownloader*)downloader;

@end
