//
//  PRDocumentManager.m
//  PDFReader
//
//  Created by KO on 11/10/01.
//  Copyright 2011年 KO All rights reserved.
//

#import "PRDocumentManager.h"
#import "PRShelf.h"
#import "PRDocument.h"

@implementation PRDocumentManager

@synthesize documentDirectory = documentDirectory_;
@synthesize shelves = shelves_;
@synthesize currentShelf = currentShelf_;
@synthesize currentDocument = currentDocument_;

static NSString* kDataFileName = @"PDFReader.dat";

#pragma mark - シングルトンオブジェクト

static PRDocumentManager*    sharaedInstance_ = nil;

+ (PRDocumentManager*)sharedManager
{
    if (!sharaedInstance_) {
        sharaedInstance_ = [[PRDocumentManager alloc] init];
    }
    return sharaedInstance_;
}

#pragma mark - アクセッサ

// 文書本体の保存・解放、読み込みを行うため独自セッターを作成
- (void)setCurrentDocument:(PRDocument *)currentDocument
{
    [currentDocument_ saveContents];
    if (currentDocument != currentDocument_) {
        currentDocument_ = currentDocument;
    }
}

#pragma mark - 初期化

- (id)init
{
    self = [super init];
    if (self) {
        shelves_ = [[NSMutableArray array] retain];
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                    NSUserDomainMask, YES);
        documentDirectory_ = [[paths objectAtIndex:0] copy];
        KLDBGPrint("** Application start **\n");
        KLDBGPrint(" document directory:%s\n", documentDirectory_.UTF8String);
    }
    
    return self;
}

- (void)dealloc
{
    [shelves_ release], shelves_ = nil;
    [documentDirectory_ release], documentDirectory_ = nil;
    
    [super dealloc];
}

#pragma mark - documentの操作

- (void)addDocument:(PRDocument*)document
{
    [currentShelf_ addDocument:document];
}

- (void)insertDocument:(PRDocument*)document atIndex:(NSUInteger)index
{
    [currentShelf_ insertDocument:document atIndex:index];
}

- (void)removeDocument:(PRDocument*)document
{
    [currentShelf_ removeDocument:document];
}

- (void)removeDocumentAtIndex:(NSUInteger)index
{
    [currentShelf_ removeDocumentAtIndex:index];
}

- (void)removeDocuments:(NSArray*)documents
{
    [currentShelf_ removeDocuments:documents];
}

- (void)moveDocumentAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    [currentShelf_ moveDocumentAtIndex:fromIndex toIndex:toIndex];
}

#pragma mark - shelfの操作

- (void)addShelf:(PRDocument*)shelf
{
    if (!shelf) {
        return;
    }
    [shelves_ addObject:shelf];
}

- (void)insertShelf:(PRShelf*)shelf atIndex:(NSUInteger)index
{
    if (!shelf) {
        return;
    }
    if (index > [shelves_ count]) {
        return;
    }
    [shelves_ insertObject:shelf atIndex:index];
}

- (void)removeShelf:(PRShelf*)shelf
{
    [shelves_ removeObject:shelf];
}

- (void)removeShelfAtIndex:(NSUInteger)index
{
    if (index > [shelves_ count] - 1) {
        return;
    }
    [shelves_ removeObjectAtIndex:index];
}

- (void)moveShelfAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    if (fromIndex > [shelves_ count] - 1) {
        return;
    }
    if (toIndex > [shelves_ count]) {
        return;
    }
    
    PRShelf* shelf = [shelves_ objectAtIndex:fromIndex];
    [shelf retain];
    [shelves_ removeObject:shelf];
    [shelves_ insertObject:shelf atIndex:toIndex];
    [shelf release];
}

#pragma mark - 永続化

- (void)load
{
    // Libraryディレクトリの取得
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                         NSUserDomainMask, YES);
    NSString* libraryDirectory = [paths objectAtIndex:0];

    // データファイルの読み込み
    NSError* error;
    NSFileManager* fileManager = [NSFileManager defaultManager];

    NSString* dataPath = [NSString stringWithFormat:@"%@/%@", libraryDirectory, kDataFileName];
    if ([fileManager fileExistsAtPath:dataPath]) {
        NSMutableArray* shelves = [NSKeyedUnarchiver unarchiveObjectWithFile:dataPath];
        if (shelves) {
            [shelves_ setArray:shelves];
        }
    } else {
        PRShelf* shelf = [[PRShelf alloc] initWithName:@"新着"];
        [self addShelf:shelf];
        [shelf release];
    }
    
    // データファイルの内容と実際に存在するPDFファイルとの齟齬の解消
    // Documentディレクトリ下のPDFをチェック
    NSArray* dirArray = [fileManager 
                         contentsOfDirectoryAtPath:documentDirectory_ error:&error];
    
    // 直接dirArray.countを使用すると、Analyze時に２３０行目でgabage value を使おうとしているというメッセージがでる
    NSUInteger len = dirArray.count;
    BOOL docExists[len];
    for (NSUInteger i = 0; i < len; i++) {
        docExists[i] = NO;
    }
    
    for (NSUInteger s = 0; s < shelves_.count; s++) {
        PRShelf* shelf = (PRShelf*)[shelves_ objectAtIndex:s];
        for (NSInteger d = shelf.documentCount - 1; d >= 0; d--) {
            NSString* name = [shelf documentAtIndex:d].fileName;
            BOOL found = NO;
            for (NSUInteger i = 0; i < dirArray.count; i++) {
                if ([name isEqualToString:[dirArray objectAtIndex:i]]) {
                    docExists[i] = YES;
                    found = YES;
                    break;
                }
            }
            if (!found) {
                // ファイルの実体が削除されてしまっている
                [shelf removeDocumentAtIndex:d];
            }
        }
    }
    
    PRShelf* shelf = (PRShelf*)[shelves_ objectAtIndex:0];
    for (NSUInteger i = 0; i < len; i++) {
        if (docExists[i] == NO) {
            NSString* fileName = [dirArray objectAtIndex:i];
            if ([[[fileName pathExtension] lowercaseString] isEqualToString:@"pdf"]) {
                // まだ未登録のPDFを「新着」に追加
                PRDocument* doc = [[PRDocument alloc] initWithPath:
                            [NSString stringWithFormat:@"%@/%@", documentDirectory_, fileName]];
                [shelf addDocument:doc];
                [doc release];
            }
        }
    }
    
    // ドキュメントの付箋定義の読み込み
    for (NSUInteger s = 0; s < shelves_.count; s++) {
        PRShelf* shelf = (PRShelf*)[shelves_ objectAtIndex:s];
        for (PRDocument* doc in shelf.documents) {
            [doc loadContents];
        }
    }
}

- (void)save
{
    // Libraryディレクトリの取得
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                         NSUserDomainMask, YES);
    NSString* libraryDirectory = [paths objectAtIndex:0];
    
    // データファイルの書き出し
    NSString* dataPath = [NSString stringWithFormat:@"%@/%@", libraryDirectory, kDataFileName];
    [NSKeyedArchiver archiveRootObject:shelves_ toFile:dataPath];
}



@end
