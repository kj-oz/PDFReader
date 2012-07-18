//
//  PRDocument.m
//  PDFReader
//
//  Created by KO on 11/10/01.
//  Copyright 2011年 KO. All rights reserved.
//

#import "PRDocument.h"
#import "PRDocumentManager.h"
#import "PRTag.h"

void enumratePDFInfo(const char *key, CGPDFObjectRef object, void *info);
void enumratePDFInfo(const char *key, CGPDFObjectRef object, void *info) 
{
    KLDBGPrint("> %s\n", key);
}

@interface PRDocument (Private)

/**
 * PDF文書の文書辞書からメタ情報を得る.
 * @param PDF文書のパス
 * @return 与えられたパスが正しいPDF文書かどうか
 */
- (BOOL)loadDocumentInformation_:(NSString*)pdfPath;

@end

@implementation PRDocument

@synthesize uid = uid_;
@synthesize pdfDoc = pdfDoc_;
@synthesize tagArrays = tagArrays_;
@synthesize tagOpened = tagOpened_;
@synthesize fileName = fileName_;
@synthesize title = title_;
@synthesize author = author_;
@synthesize modDate = modDate_;
@synthesize numPages = numPages_;
@synthesize currentPageIndex = currentPageIndex_;

#pragma mark - アクセッサ

- (NSMutableArray*)tagsAtPageIndex:(NSUInteger)pageIndex
{
    if (pageIndex < numPages_) {
        return [tagArrays_ objectAtIndex:(pageIndex)];
    }
    return nil;
}

#pragma mark - 初期化

// 新規の空のドキュメントの初期化
- (id)init
{
    self = [super init];
    if (self) {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        uid_ = (NSString*)CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
        tagOpened_ = YES;
    }    
    return self;
}

- (id)initWithPath:(NSString*)pdfPath
{
    self = [super init];
    if (self) {
        if ([self loadDocumentInformation_:pdfPath]) {
            CFUUIDRef uuid = CFUUIDCreate(NULL);
            uid_ = (NSString*)CFUUIDCreateString(NULL, uuid);
            CFRelease(uuid);
            tagOpened_ = YES;
        }
    }    
    return self;
}

- (void)releaseContents
{
    CGPDFDocumentRelease(pdfDoc_), pdfDoc_ = nil;
    [tagArrays_ release], tagArrays_ = nil;
}

- (void)dealloc
{
    [self saveContents];
    [self releaseContents];
    [uid_ release], uid_ = nil;
    [fileName_ release], fileName_ = nil;
    [title_ release], title_ = nil;
    [author_ release], author_ = nil;
    [modDate_ release], modDate_ = nil;
    
    [super dealloc];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    if (self) {
        uid_ = [[decoder decodeObjectForKey:@"uid"] retain];
        tagOpened_ = [decoder decodeBoolForKey:@"tagOpened"];
        fileName_ = [[decoder decodeObjectForKey:@"fileName"] retain];
        title_ = [[decoder decodeObjectForKey:@"title"] retain];
        author_ = [[decoder decodeObjectForKey:@"author"] retain];
        modDate_ = [[decoder decodeObjectForKey:@"modDate"] retain];
        currentPageIndex_ = [decoder decodeIntegerForKey:@"currentPageIndex"];
        numPages_ = [decoder decodeIntegerForKey:@"numPages"];
    }    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:uid_ forKey:@"uid"];
    [encoder encodeBool:tagOpened_ forKey:@"tagOpened"];
    [encoder encodeObject:fileName_ forKey:@"fileName"];
    [encoder encodeObject:title_ forKey:@"title"];
    [encoder encodeObject:author_ forKey:@"author"];
    [encoder encodeObject:modDate_ forKey:@"modDate"];
    [encoder encodeInteger:currentPageIndex_ forKey:@"currentPageIndex"];
    [encoder encodeInteger:numPages_ forKey:@"numPages"];
}

#pragma mark - 読み込み・保存

- (void)loadContents
{
    NSString* pdfPath = [NSString stringWithFormat:@"%@/%@", 
                         [PRDocumentManager sharedManager].documentDirectory, fileName_];
    NSURL *pdfUrl = [NSURL fileURLWithPath:pdfPath isDirectory:NO];
    pdfDoc_ = CGPDFDocumentCreateWithURL((CFURLRef)pdfUrl);
    CGPDFDocumentRetain(pdfDoc_);
    
    NSString* annotationPath = [NSString stringWithFormat:@"%@.annotation", pdfPath];

    // 付箋ファイルの読み込み
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:annotationPath]) {
        tagArrays_ = [[NSKeyedUnarchiver unarchiveObjectWithFile:annotationPath] retain];
        for (NSUInteger i = 0 ; i < numPages_; i++) {
            NSArray* tags = [tagArrays_ objectAtIndex:i];
            for (PRTag* tag in tags) {
                tag.page = i;
            }
        }
    } else {
        tagArrays_ = [[NSMutableArray array] retain];
        for (NSUInteger i = 0 ; i < numPages_; i++) {
            [tagArrays_ addObject:[NSMutableArray array]];
        }
    }    
}

- (void)saveContents
{
    NSString* annotationPath = [NSString stringWithFormat:@"%@/%@.annotation", 
                         [PRDocumentManager sharedManager].documentDirectory, fileName_];
    [NSKeyedArchiver archiveRootObject:tagArrays_ toFile:annotationPath];
}

- (BOOL)checkPdf
{
    NSString* pdfPath = [NSString stringWithFormat:@"%@/%@", 
                         [PRDocumentManager sharedManager].documentDirectory, fileName_];
    return [self loadDocumentInformation_:pdfPath];
}

- (BOOL)loadDocumentInformation_:(NSString*)pdfPath
{
    NSURL *pdfUrl = [NSURL fileURLWithPath:pdfPath isDirectory:NO];
    CGPDFDocumentRef pdfDoc = CGPDFDocumentCreateWithURL((CFURLRef)pdfUrl);
    if (!pdfDoc) {
        return NO;
    }

    self.fileName = [pdfPath lastPathComponent];
    numPages_ = CGPDFDocumentGetNumberOfPages(pdfDoc);
    currentPageIndex_ = -1;
    
    CGPDFDictionaryRef dic = CGPDFDocumentGetInfo(pdfDoc);
    
    CGPDFStringRef pdfStr;
    if (CGPDFDictionaryGetString(dic, "Title", &pdfStr)) {
        NSString* str = (NSString*)CGPDFStringCopyTextString(pdfStr);
        self.title = str;
        [str release];
    } else {
        self.title = self.fileName;
    }
    
    if (CGPDFDictionaryGetString(dic, "Author", &pdfStr)) {
        NSString* str = (NSString*)CGPDFStringCopyTextString(pdfStr);
        self.author = str;
        [str release];
    } else {
        self.author = @"";
    }
    
    if (CGPDFDictionaryGetString(dic, "ModDate", &pdfStr)) {
        NSString* str = (NSString*)CGPDFStringCopyTextString(pdfStr);
        self.modDate = [NSString stringWithFormat:@"%@/%@/%@",
                       [str substringWithRange:NSMakeRange(2, 4)],
                       [str substringWithRange:NSMakeRange(6, 2)],
                       [str substringWithRange:NSMakeRange(8, 2)]];
        [str release];
    } else {
        self.modDate = @"";
    }
    
    CGPDFDocumentRelease(pdfDoc);
    return YES;
}

@end
