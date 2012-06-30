//
//  PRAppController.m
//  PDFReader
//
//  Created by KO on 11/10/01.
//  Copyright 2011年 KO All rights reserved.
//

#import "PRAppController.h"
#import "PRDocumentManager.h"
#import "PRDocument.h"
#import "PRDocumentListController.h"
#import "PRConnector.h"
#import "PRShelf.h"

@interface PRAppController (Private)

/**
 * ネットワークの状態を更新する.
 */
- (void)updateNetworkActivity_;

/**
 * データを保存する.
 */
- (void)saveData_;

@end

@implementation PRAppController

@synthesize window = window_;
@synthesize documentListController = documentListController_;
@synthesize documentListNavController = documentListNavController_;

#pragma mark - シングルトンオブジェクト

static PRAppController*    sharaedInstance_ = nil;

/**
 * シングルトンオブジェクトを得る.
 */
+ (PRAppController*)sharedController
{
    return sharaedInstance_;
}

#pragma mark - 初期化

- (id)init
{
    self = [super init];
    if (self) {
        sharaedInstance_ = self;
    }
    
    return self;
}

#pragma mark - データの保存

- (void)saveData_
{
    // カレントドキュメントの情報は標準の設定ファイルに保存する
    PRDocumentManager* dm = [PRDocumentManager sharedManager];
    PRDocument* currentDoc = dm.currentDocument;
    if (currentDoc) {
        [[NSUserDefaults standardUserDefaults] 
            setValue:currentDoc.fileName forKey:@"lastDocument"];
        // アプリケーションがバックグランドに移行した場合も呼ばれるので、リリースはせず保存だけ行う
        // （その後、本当の終了時にAppWillTerminateは実行されないように思われる）
        [currentDoc saveContents];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastDocument"];        
    }
    
    // 実データを保存
    [dm save];
}

#pragma mark - 画面の更新

- (void)updateNetworkActivity_
{
    // ネットワークアクティビティを更新する
    [UIApplication sharedApplication].networkActivityIndicatorVisible = 
    [PRConnector sharedConnector].networkAccessing;
}

#pragma mark - UIApplication デリゲート

- (BOOL)application:(UIApplication*)application 
            didFinishLaunchingWithOptions:(NSDictionary*)options
{
    // 他のアプリケーションから起動された場合の対象PDFのURLを得る
    NSURL* url = (NSURL*)[options objectForKey:UIApplicationLaunchOptionsURLKey];
    KLDBGPrint("▼ %s url:%s", KLDBGMethod(), url.path.UTF8String);
    
    // データを読み込む
    PRDocumentManager* dm = [PRDocumentManager sharedManager];
    [dm load];
    
    // 最後に開いていたドキュメントを得る
    dm.currentShelf = [dm.shelves objectAtIndex:0]; 
    if (!url) {
        NSString* lastShelf = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastShelf"];
        if (lastShelf) {
            for (PRShelf* shelf in dm.shelves) {
                if ([shelf.name isEqualToString:lastShelf]) {
                    dm.currentShelf = shelf;
                    break;
                }
            }
        }

        NSString* lastDocument = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastDocument"];
        if (lastDocument) {
            for (PRDocument* doc in dm.currentShelf.documents) {
                if ([doc.fileName isEqualToString:lastDocument]) {
                    dm.currentDocument = doc;
                    break;
                }
            }
        }
    }
    
    // Navigationコントローラのdelegateをドキュメント一覧画面にする
    // （ドキュメント画面から戻ってくるタイミングでイベントを取得するため）
    // viewWillAppear で代用できることが判明したため取りやめ
    // documentListNavController_.delegate = documentListController_;
    
    // ルートコントローラを追加する（ドキュメント一覧画面が表示される）
    CGRect  rect;
    rect = [UIScreen mainScreen].applicationFrame;
    documentListNavController_.view.frame = rect;
    [window_ addSubview:documentListNavController_.view];
    
    // 最後のドキュメントが存在すれば、そのドキュメントを表示
    if (dm.currentDocument) {
        [documentListController_ showDocument:dm.currentDocument animated:NO];
    }
    
    // ウィンドウを表示する
    [window_ makeKeyAndVisible];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url 
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation 
{
    // 他のアプリケーションから呼び出された場合、元々起動していても、新たに起動された場合でもこのメソッドが呼ばれる.
    // application:didFinishLaunchingWithOptions:は、新たに起動された場合のみ呼び出される.
    KLDBGPrint("▼ %s url:%s", KLDBGMethod(), url.path.UTF8String);
    
    // 同じ名称の既存のファイルの存在チェック
    NSString* fileName = url.lastPathComponent;
    NSString* pdfPath = [NSString stringWithFormat:@"%@/%@", 
                         [PRDocumentManager sharedManager].documentDirectory, fileName];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:pdfPath]) {
        // 名称が重複していた場合、XXXX.n.pdfに名称を変更
        NSArray* parts = [fileName componentsSeparatedByString:@"."];
        for (NSInteger i = 1; i < 1000; i++) {
            fileName = [NSString stringWithFormat:@"%@.%d.%@", [parts objectAtIndex:0],
                        i, [parts objectAtIndex:1]];
            pdfPath = [NSString stringWithFormat:@"%@/%@", 
                        [PRDocumentManager sharedManager].documentDirectory, fileName];
            if (![fileManager fileExistsAtPath:pdfPath]) {
                break;
            }
        }
    }
    
    // ファイル移動（他のアプリケーションから呼び出されると Documents/InBoxの下にコピーされている）
    NSError* error = nil;
    [fileManager moveItemAtURL:url toURL:[NSURL fileURLWithPath:pdfPath] error:&error];
    if (error) {
        KLDBGPrint("File Move Error: %s\n", error.localizedDescription.UTF8String);
        return NO;
    }
    
    // ドキュメントとして「新着」本棚に追加
    PRDocumentManager* dm = [PRDocumentManager sharedManager];
    PRDocument* doc = [[PRDocument alloc] initWithPath:pdfPath];
    [doc loadContents];
    [[dm.shelves objectAtIndex:0] addDocument:doc];
    [doc release];
    
    // 他のドキュメントを表示中であれば、一覧まで戻す
    if (dm.currentDocument) {
        [documentListNavController_ popViewControllerAnimated:NO];
    }

    // ドキュメントの表示
    dm.currentShelf = [dm.shelves objectAtIndex:0];
    [documentListController_ showDocument:doc animated:NO];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication*)application
{
    [self saveData_];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // iOS4からは、通常はWillTerminateは呼ばれないで、こちらが呼ばれる
    [self saveData_];
}

@end
