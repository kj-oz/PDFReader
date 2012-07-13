//
//  PRConnector.m
//  PDFReader
//
//  Created by KO on 12/03/04.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import "PRConnector.h"
#import "KLNetURLDownloader.h"

NSString* PRConnectorDidBeginDownload = @"PRConnectorDidBeginDownload";
NSString* PRConnectorInProgressDownload = @"PRConnectorInProgressDownload";
NSString* PRConnectorDidFinishDownload = @"PRConnectorDidFinishDownload";

@interface PRConnector (Private)

/**
 * ダウンロードオブジェクトがダウンロードしている対象のドキュメントオブジェクトを返す.
 * @param downloader 対象のダウンロードオブジェクト
 * @return ダウンロードオブジェクトがダウンロード中のドキュメントオブジェクト
 */
- (PRDocument*)documentForDownloader_:(KLNetURLDownloader*)downloader;

/**
 * ダウンロードに進捗があったことを通知する.
 * @param downloader 対象のダウンロードオブジェクト
 */
- (void)notifyDownloadProgressWithDownloader_:(KLNetURLDownloader*)downloader;

/**
 * ダウンロードの状態に変化があったことを通知する.
 * @param downloader 対象のダウンロードオブジェクト
 */
- (void)notifyDownloadStatusWithDownloader_:(KLNetURLDownloader*)downloader;

@end

@implementation PRConnector

#pragma mark - シングルトンオブジェクト

static PRConnector* sharedInstance_ = nil;

+ (PRConnector*)sharedConnector
{
    // インスタンスを作成する
    if (!sharedInstance_) {
        sharedInstance_ = [[PRConnector alloc] init];
    }
    
    return sharedInstance_;
}

#pragma mark - アクセサ

- (BOOL)isNetworkAccessing
{
    return CFDictionaryGetCount(downloaders_) > 0;
}

- (KLNetURLDownloader*)downloaderForDocument:(PRDocument*)doc
{
    return CFDictionaryGetValue(downloaders_, doc);
}

- (PRDocument*)documentForDownloader_:(KLNetURLDownloader*)downloader
{
    NSInteger count = CFDictionaryGetCount(downloaders_);
    PRDocument* docs[count];
    CFDictionaryGetKeysAndValues(downloaders_, (const void**)docs, NULL);
    for (NSInteger i = 0; i < count; i++) {
        KLNetURLDownloader* dl = CFDictionaryGetValue(downloaders_, docs[i]);
        if (dl == downloader) {
            return docs[i];
        }
    }
    return nil;
}

#pragma mark - 初期化

- (id)init
{
    self = [super init];
    if (self) {
        const CFDictionaryKeyCallBacks keyCB = kCFTypeDictionaryKeyCallBacks;
        const CFDictionaryValueCallBacks valCB = kCFTypeDictionaryValueCallBacks;
        downloaders_ = CFDictionaryCreateMutable(NULL, 0, &keyCB, &valCB);
    }
    
    return self;
}

- (void)dealloc
{
    CFDictionaryRemoveAllValues(downloaders_);
    CFRelease(downloaders_), downloaders_ = nil;
    
    // 親クラスのdeallocを呼び出す
    [super dealloc];
}

#pragma mark - ダウンロード

- (void)downloadDocument:(PRDocument*)doc withUrlString:(NSString*)urlString
{
    if (!CFDictionaryGetValue(downloaders_, doc)) {
        // 現在のネットワークアクセス状況を取得
        NSInteger downloderCount = CFDictionaryGetCount(downloaders_);
        if (!downloderCount) {
            [self willChangeValueForKey:@"networkAccessing"];
        }
        
        KLNetURLDownloader* downloader = [[KLNetURLDownloader alloc] initWithUrl:urlString];
        downloader.delegate = self;
        CFDictionarySetValue(downloaders_, doc, downloader);
        [downloader release];
        [downloader download];
    
        if (!downloderCount) {
            [self didChangeValueForKey:@"networkAccessing"];
        }
        
        // userInfoの作成
        NSMutableDictionary* userInfo;
        userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:downloader forKey:@"downloader"];
        [userInfo setObject:doc forKey:@"document"];
        
        // 通知
        [[NSNotificationCenter defaultCenter] 
         postNotificationName:PRConnectorDidBeginDownload
         object:self userInfo:userInfo];
    }
}

- (void)cancelDownloadDocument:(PRDocument*)doc
{
    KLNetURLDownloader* downloader = CFDictionaryGetValue(downloaders_, doc);
    if (downloader) {
        [downloader cancel];
    }
}

#pragma mark - KLNetURLDownloader デリゲート

- (void)downloader:(KLNetURLDownloader*)downloader 
            didReceiveResponse:(NSURLResponse*)response
{
    [self notifyDownloadProgressWithDownloader_:downloader];
}

- (void)downloader:(KLNetURLDownloader*)downloader 
    didReceiveData:(NSData*)data
{
    [self notifyDownloadProgressWithDownloader_:downloader];
}

- (void)downloaderDidFinishLoading:(KLNetURLDownloader*)downloader
{
    [self notifyDownloadStatusWithDownloader_:downloader];
}

- (void)downloader:(KLNetURLDownloader*)downloader
  didFailWithError:(NSError*)error
{
    [self notifyDownloadStatusWithDownloader_:downloader];
}

- (void)downloaderDidCancel:(KLNetURLDownloader*)downloader
{
    [self notifyDownloadStatusWithDownloader_:downloader];
}

- (void)notifyDownloadProgressWithDownloader_:(KLNetURLDownloader*)downloader 
{
    // userInfoの作成
    NSMutableDictionary* userInfo;
    userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:downloader forKey:@"downloader"];
    [userInfo setObject:[self documentForDownloader_:downloader] forKey:@"document"];
    
    // 通知
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:PRConnectorInProgressDownload
     object:self userInfo:userInfo];
}

- (void)notifyDownloadStatusWithDownloader_:(KLNetURLDownloader*)downloader
{
    // 現在のネットワークアクセス状況を取得
    NSInteger downloderCount = CFDictionaryGetCount(downloaders_);
    if (downloderCount == 1) {
        [self willChangeValueForKey:@"networkAccessing"];
    }
    
    // userInfoの作成
    NSMutableDictionary* userInfo;
    userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:downloader forKey:@"downloader"];
    PRDocument* doc = [self documentForDownloader_:downloader];
    [userInfo setObject:doc forKey:@"document"];
    
    // networkAccessingの値の変更を通知する
    CFDictionaryRemoveValue(downloaders_, doc);
    if (downloderCount == 1) {
        [self didChangeValueForKey:@"networkAccessing"];
    }
    
    // 通知する
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:PRConnectorDidFinishDownload 
     object:self userInfo:userInfo];
}

@end
