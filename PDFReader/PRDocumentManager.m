//
//  PRDocumentManager.m
//  PDFReader
//
//  Created by KO on 11/10/01.
//  Copyright 2011年 KO All rights reserved.
//

#import "PRDocumentManager.h"
#import "PRDocument.h"

@interface PRDocumentManager (Private) 

/**
 * 指定の名称のPDFがドキュメントの配列の中に存在しているかを調べる.
 * @param fileName PDFファイル名
 * @return 登録されていればその配列内インデックス、されていなければ-1
 */
- (NSInteger)findDocument_:(NSString*)fileName;

@end

@implementation PRDocumentManager

@synthesize documentDirectory = documentDirectory_;
@synthesize documents = documents_;
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
        documents_ = [[NSMutableArray array] retain];
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
    [documents_ release], documents_ = nil;
    [documentDirectory_ release], documentDirectory_ = nil;
    
    [super dealloc];
}

#pragma mark - documentの操作

- (void)addDocument:(PRDocument*)document
{
    if (!document) {
        return;
    }
    [documents_ addObject:document];
}

- (void)insertDocument:(PRDocument*)document atIndex:(NSUInteger)index
{
    if (!document) {
        return;
    }
    if (index > [documents_ count]) {
        return;
    }
    [documents_ insertObject:document atIndex:index];
}

- (void)removeDocument:(PRDocument*)document
{
    [documents_ removeObject:document];
}

- (void)removeDocumentAtIndex:(NSUInteger)index
{
    if (index > [documents_ count] - 1) {
        return;
    }
    [documents_ removeObjectAtIndex:index];
}

- (void)moveDocumentAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    if (fromIndex > [documents_ count] - 1) {
        return;
    }
    if (toIndex > [documents_ count]) {
        return;
    }
    
    PRDocument* document = [documents_ objectAtIndex:fromIndex];
    [document retain];
    [documents_ removeObject:document];
    [documents_ insertObject:document atIndex:toIndex];
    [document release];
}

#pragma mark - 永続化

- (NSInteger)findDocument_:(NSString*)fileName
{
    for (NSUInteger i = 0; i < documents_.count; i++) {
        if ([fileName isEqualToString:((PRDocument*)[documents_ objectAtIndex:i]).fileName]) {
            return i;
        }
    }
    return -1;
}

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
        NSMutableArray* docs = [NSKeyedUnarchiver unarchiveObjectWithFile:dataPath];
        if (docs) {
            [documents_ setArray:docs];
        }
    }        
    
    // データファイルの内容と実際に存在するPDFファイルとの齟齬の解消
    // Documentディレクトリ下のPDFをチェック
    NSUInteger dataCount = documents_.count;
    BOOL fileExists[dataCount];
    for (NSUInteger i = 0; i < dataCount; i++) {
        fileExists[i] = NO;
    }
    
    NSArray* dirArray = [fileManager 
                         contentsOfDirectoryAtPath:documentDirectory_ error:&error];
    for (NSString* fileName in dirArray) {
        if ([[[fileName pathExtension] lowercaseString] isEqualToString:@"pdf"]) {
            NSInteger index = [self findDocument_:fileName];
            if (index < 0) {
                PRDocument* doc = [[PRDocument alloc] initWithPath:
                            [NSString stringWithFormat:@"%@/%@", documentDirectory_, fileName]];
                [self addDocument:doc];
                [doc release];
            } else {
                fileExists[index] = YES;
            }
        }
    }
    
    for (NSInteger i = dataCount - 1; i >= 0; i--) {
        if (fileExists[i] == NO) {
            [self removeDocumentAtIndex:i];
        }
    }
    
    for (PRDocument* doc in self.documents) {
        [doc loadContents];
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
    [NSKeyedArchiver archiveRootObject:documents_ toFile:dataPath];
}



@end
