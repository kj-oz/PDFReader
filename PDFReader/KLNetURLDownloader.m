//
//  KLNetURLDownloader.m
//  KLib Net
//
//  Created by KO on 12/03/04.
//  Copyright (c) 2012年 KO All rights reserved.
//

#import "KLNetURLDownloader.h"

@interface KLNetURLDownloader (Private)

/**
 * 各種initメソッドから呼びだされる共通の初期化処理.
 */
- (void)init_;

@end

@implementation KLNetURLDownloader

@synthesize delegate = delegate_;
@synthesize urlString = urlString_;
@synthesize networkState = networkState_;
@synthesize expectedSize = expectedSize_;
@synthesize downloadedSize = downloadedSize_;
@synthesize downloadedData = downloadedData_;
@synthesize error = error_;

#pragma mark - 初期化

- (void)init_
{
    networkState_ = KLNetNetworkStateNotConnected;
    expectedSize_ = -1;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self init_];
    }
    return self;
}

- (id)initWithUrl:(NSString *)urlString
{
    self = [super init];
    if (self) {
        [self init_];
        urlString_ = [urlString copy];
    }
    return self;
}

- (void)dealloc
{
    // インスタンス変数を解放する
    [urlString_ release], urlString_ = nil;
    [downloadedData_ release], downloadedData_ = nil;
    [error_ release], error_ = nil;
    delegate_ = nil;
    
    // 親クラスのdeallocを呼び出す
    [super dealloc];
}

#pragma mark - ダウンロード処理

- (void)download
{
    // リクエストオブジェクトの生成
    NSURLRequest* request = nil;
    if (urlString_) {
        NSURL* url = [NSURL URLWithString:urlString_];
        if (url) {
            request = [NSURLRequest requestWithURL:url];
        }
    }
    
    if (!request) {
        return;
    }
    
    [downloadedData_ release], downloadedData_ = nil;
    downloadedData_ = [[NSMutableData data] retain];
    
    // リクエストの送信
    connection_ = [[NSURLConnection 
        connectionWithRequest:request delegate:self] retain];
    
    // ネットワークアクセス状態の設定
    self.networkState = KLNetNetworkStateInProgress;
}

- (void)cancel
{
    // ネットワークアクセスのキャンセル
    [connection_ cancel];
    
    // ダウンロード済みデータの解放
    [downloadedData_ release], downloadedData_ = nil;
    
    // ネットワークアクセス状態の設定
    networkState_ = KLNetNetworkStateCanceled;
    
    // デリゲートに通知
    if ([delegate_ respondsToSelector:@selector(downloaderDidCancel:)]) {
        [delegate_ downloaderDidCancel:self];
    }
    
    // NSURLConnectionオブジェクトを解放
    [connection_ release], connection_ = nil;
}

#pragma mark - NSURLConnection デリゲート

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    expectedSize_ = response.expectedContentLength;
    
    // デリゲートに通知
    if ([delegate_ respondsToSelector:@selector(downloader:didReceiveResponse:)]) {
        [delegate_ downloader:self didReceiveResponse:response];
    }
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    // ダウンロード済みデータを追加
    downloadedSize_ += data.length;
    [downloadedData_ appendData:data];
    
    // デリゲートに通知
    if ([delegate_ respondsToSelector:@selector(downloader:didReceiveData:)]) {
        [delegate_ downloader:self didReceiveData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    networkState_ = KLNetNetworkStateFinished;
    
    // デリゲートに通知
    if ([delegate_ respondsToSelector:@selector(downloaderDidFinishLoading:)]) {
        [delegate_ downloaderDidFinishLoading:self];
    }
   
    // NSURLConnectionオブジェクトを解放
    [connection_ release], connection_ = nil;
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    // エラーオブジェクトの設定
    [error_ release], error_ = nil;
    error_ = [error retain];
    
    // ネットワークアクセス状態の設定
    networkState_ = KLNetNetworkStateError;
    
    // デリゲートに通知
    if ([delegate_ respondsToSelector:@selector(downloader:didFailWithError:)]) {
        [delegate_ downloader:self didFailWithError:error];
    }
    
    // NSURLConnectionオブジェクトを解放
    [connection_ release], connection_ = nil;
}

@end
