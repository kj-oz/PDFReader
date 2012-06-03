
//
//  PRPageRenderer.m
//  PDFReader
//
//  Created by KO on 11/10/09.
//  Copyright 2011年 KO All rights reserved.
//

#import "PRPageController.h"
#import "PRDocumentManager.h"
#import "PRDocument.h"
#import "KLPVPageView.h"
#import "KLPVTagView.h"
#import "PRTag.h"

// 付箋間、付箋とページ端との間のスペース
#define kTabMargin  32.0

// 付箋（の位置）を比較する関数、付箋のソートに使用する
// ※ 全ての付箋がページ左辺上に配置されていることが前提
NSInteger compareTag(id a, id b, void* context);
NSInteger compareTag(id a, id b, void* context)
{
    PRTag* ta = (PRTag*)a;
    PRTag* tb = (PRTag*)b;
    if (ta.origin.y < tb.origin.y)
        return NSOrderedAscending;
    else if (ta.origin.y > tb.origin.y)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

@interface PRPageController (Private)

/**
 * 保持しているページの内容を与えられたContextに描画する.
 * 座標系の原点はページの左上、スケールも描画サイズに応じて設定されているものとする.
 * @param context 対象のContext
 * @param position ページ位置、0=前、1=中央、2=後
 */
- (void)renderPageWithContext_:(CGContextRef)context page:(NSUInteger)position;

/**
 * 新たな付箋に対する適切な位置を探し出す.
 * 各ページの付箋は原則的に位置が上にあるものから順にソートして配列に保持している.
 * @param newTab 追加される付箋
 * @return 配列に挿入する際のインデックス
 */
- (NSUInteger)findAvailableSpaceForTag_:(PRTag*)newTab;

/**
 * 指定されたページの付箋の配列を、原点のY座標をもとにソートし直す.
 * @param position ページ位置、0=前、1=中央、2=後
 */
- (void)sortTagsInPage_:(NSUInteger)position;

@end

@implementation PRPageController

@synthesize view = view_;
@synthesize totalSize = totalSize_;
@synthesize targetPoint = targetPoint_;

#pragma mark - アクセッサ

- (CGRect) previousPageFrame
{
    return pageFrames_[0];
}
- (CGRect) currentPageFrame
{
    return pageFrames_[1];
}
- (CGRect) nextPageFrame
{
    return pageFrames_[2];
}

- (CGRect)pageFrameOfPosition:(NSUInteger)position
{
    return pageFrames_[position];
}

- (void)setCurrentPageIndex:(NSUInteger)index
{    
    for (NSUInteger i = 0; i < 3; i++) {
        CGPDFPageRelease(pdfPages_[i]), pdfPages_[i] = nil;
        [tags_[i] release], tags_[i] = nil;
    }
    CFDictionaryRemoveAllValues(tagMaps_);
    
    PRDocument* doc = [PRDocumentManager sharedManager].currentDocument;
    doc.currentPageIndex = index;
    CGPDFDocumentRef pdfDoc = doc.pdfDoc;
    
    // pdfPage_とitems_の設定
    if (index > 0) {
        pdfPages_[0] = CGPDFDocumentGetPage(pdfDoc, index);
        CGPDFPageRetain(pdfPages_[0]);
        tags_[0] = [doc tagsAtPageIndex:(index - 1)];
        [tags_[0] retain];
    }
    pdfPages_[1] = CGPDFDocumentGetPage(pdfDoc, index + 1);
    CGPDFPageRetain(pdfPages_[1]);
    tags_[1] = [doc tagsAtPageIndex:index];
    [tags_[1] retain];
    if (index < doc.numPages - 1) {
        pdfPages_[2] = CGPDFDocumentGetPage(pdfDoc, index + 2);
        CGPDFPageRetain(pdfPages_[2]); 
        tags_[2] = [doc tagsAtPageIndex:(index + 1)];
        [tags_[2] retain];
    }
    
    // totalSize_とpositions_の算定
    totalSize_ = CGSizeZero;
    for (NSUInteger i = 0; i < 3; i++) {
        if (pdfPages_[i]) {
            pageFrames_[i] = CGPDFPageGetBoxRect(pdfPages_[i], kCGPDFMediaBox);
            totalSize_.height = MAX(totalSize_.height, pageFrames_[i].size.height);
        } else {
            pageFrames_[i] = CGRectNull;
        }
    }
    
    for (NSUInteger i = 0; i < 3; i++) {
        pageFrames_[i].origin.y = (totalSize_.height - pageFrames_[i].size.height) * 0.5;
        if (i) {
            pageFrames_[i].origin.x = pageFrames_[i-1].origin.x + pageFrames_[i-1].size.width;
        } else {
            pageFrames_[i].origin.x = 0;
        }
    }
    totalSize_.width = pageFrames_[2].origin.x + pageFrames_[2].size.width;
}

- (NSUInteger)currentPageIndex
{
    return [PRDocumentManager sharedManager].currentDocument.currentPageIndex;
}

- (NSUInteger)numPages
{
    return [PRDocumentManager sharedManager].currentDocument.numPages;
}

#pragma mark - 初期化

- (id)init
{
    self = [super init];
    if (self) {
        const CFDictionaryKeyCallBacks keyCB = kCFTypeDictionaryKeyCallBacks;
        const CFDictionaryValueCallBacks valCB = kCFTypeDictionaryValueCallBacks;
        tagMaps_ = CFDictionaryCreateMutable(NULL, 0, &keyCB, &valCB);
        selectedTagImage_ = [[UIImage imageNamed:@"move.png"] retain];
        pixelScale_ = [UIScreen mainScreen].scale;
    }
    return self;
}

- (void)dealloc
{
    for (NSUInteger i = 0; i < 3; i++) {
        CGPDFPageRelease(pdfPages_[i]), pdfPages_[i] = nil;
        [tags_[i] release], tags_[i] = nil;
    }
    CFDictionaryRemoveAllValues(tagMaps_);
    CFRelease(tagMaps_), tagMaps_ = nil;
    [selectedTagImage_ release], selectedTagImage_ = nil;

    [view_ release], view_ = nil;
    [super dealloc];    
}

#pragma mark - KLPVPageView データソース

// backgroundViewへの描画
- (void)renderPagesWithContext:(CGContextRef)context scale:(CGFloat)scale
{    
    CGContextSaveGState(context);
    CGContextScaleCTM(context, scale, scale);

    for (NSUInteger i = 0; i < 3; i++) {
        if (pdfPages_[i]) {
            CGPoint origin = pageFrames_[i].origin;            
            CGContextTranslateCTM(context, origin.x, origin.y);
            [self renderPageWithContext_:context page:i];
            CGContextTranslateCTM(context, -origin.x, -origin.y);
        }
    }
    CGContextRestoreGState(context);
}

// tiledViewへの描画
- (void)renderCurrentPageWithContext:(CGContextRef)context scale:(CGFloat)scale
{    
    CGContextSaveGState(context);
    CGContextScaleCTM(context, scale, scale);
    
    [self renderPageWithContext_:context page:1];

    CGContextRestoreGState(context);
}

- (void)renderPageWithContext_:(CGContextRef)context page:(NSUInteger)position
{    
    CGSize size = pageFrames_[position].size;
    
    // 背景を白で塗りつぶす
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGRect rect = CGRectMake(0.0, 0.0, size.width, size.height);
    CGContextFillRect(context, rect);
    
    // ページ外形
    CGContextSetRGBStrokeColor(context, 0.8, 0.8, 0.8, 1.0);
    CGContextStrokeRect(context, rect);
    
    // PDFの座標系が左下原点、Y軸が上向きなので、座標系をひっくり返す
    CGContextTranslateCTM(context, 0.0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // PDFの描画
    CGContextDrawPDFPage(context, pdfPages_[position]);
    
    // 座標系を標準の向きに戻す
    CGContextTranslateCTM(context, 0.0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
}

- (NSArray*)createTagViewsOfPagesWithScale:(CGFloat)scale
{
    NSMutableArray* result = [NSMutableArray array];
    CFDictionaryRemoveAllValues(tagMaps_);
    for (NSUInteger i = 0; i < 3; i++) {
        for (PRTag* tag in tags_[i]) {
            KLPVTagView* tagView = [self createTagViewOfTag:tag inPage:i scale:scale];
            [result addObject:tagView];
            if (tag == selectedTag_) {
                tagView.selected = YES;
            }
        }
    }
    return result;
}

- (void)renderTagView:(KLPVTagView*)tagView WithContext:(CGContextRef)context
{
    PRTag* tag = CFDictionaryGetValue(tagMaps_, tagView);
    CGFloat scale = tagView.scale;
    
    // 背景を白で塗りつぶす
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGRect r = CGRectMake(0.0, 0.0, tag.size.width * scale, tag.size.height * scale);
    CGContextFillRect(context, r);
    
    // ヘッダー
    CGColorRef c = tag.color.CGColor;
    CGContextSetFillColorWithColor(context, c);
    r = CGRectMake(0.0, 0.0, tag.size.width * scale, tag.colorHeight * scale);
    CGContextFillRect(context, r);
    
    // テキスト
    CGSize area = CGSizeMake(tag.size.width * scale, 
                             (tag.size.height - tag.colorHeight) * scale);
    CGSize size = [tag.text sizeWithFont:[UIFont systemFontOfSize:tag.fontSize * scale] constrainedToSize:area lineBreakMode:UILineBreakModeTailTruncation];
    r = CGRectMake(0.0, tag.colorHeight * scale + (area.height - size.height) / 2,
                   area.width, size.height);
    CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1.0);
    [tag.text drawInRect:r withFont:[UIFont systemFontOfSize:tag.fontSize * scale] 
           lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentCenter];
    
    // 選択されている場合は、マークを表示
    if (tagView.selected) {
        double x = (tag.size.width - selectedTagImage_.size.width) * scale * 0.5;
        double y = (tag.size.height - selectedTagImage_.size.height) * scale * 0.5;
        r = CGRectMake(x, y, 
                selectedTagImage_.size.width * scale, selectedTagImage_.size.height * scale);
        [selectedTagImage_ drawInRect:r];
    }
    
    // 枠線
    // 4周に線が出るように寸法を調整
    CGFloat w = 0.1 / pixelScale_;
    r = CGRectMake(0, 0, tag.size.width * scale - w, tag.size.height * scale - w);
    CGContextSetRGBStrokeColor(context, 0.6, 0.6, 0.6, 1.0);
    CGContextSetLineWidth(context, 1.0 / pixelScale_);
    CGContextStrokeRect(context, r);
}

- (void)tagViewDidMove:(KLPVTagView *)tagView
{
    // tagViewがドラッグ移動された際に呼び出される
    PRTag* tag = CFDictionaryGetValue(tagMaps_, tagView);
    CGFloat scale = tagView.scale;
    NSUInteger position = tagView.tag;
    CGPoint pageOrigin = pageFrames_[position].origin;    
    CGPoint scaledPoint = [tagView convertPoint:CGPointZero toView:tagView.superview];
    CGPoint point = CGPointMake(scaledPoint.x / scale, scaledPoint.y / scale);
    tag.origin = CGPointMake(point.x - pageOrigin.x, point.y - pageOrigin.y);
    
    // 新たな位置で付箋をソートし直す
    [self sortTagsInPage_:position];
    [[PRDocumentManager sharedManager].currentDocument saveContents];
}

- (void)tagViewDidSelect:(KLPVTagView *)tagView
{
    if (tagView) {
        selectedTag_ = CFDictionaryGetValue(tagMaps_, tagView);
    } else {
        selectedTag_ = nil;
    }
}

- (void)sortTagsInPage_:(NSUInteger)position
{
    [tags_[position] sortUsingFunction:compareTag context:nil];
}

- (void)deleteTagView:(KLPVTagView *)tagView
{
    PRTag* tag = CFDictionaryGetValue(tagMaps_, tagView);
    [tags_[tagView.tag] removeObjectIdenticalTo:tag];
    [[PRDocumentManager sharedManager].currentDocument saveContents];

    CFDictionaryRemoveValue(tagMaps_, tagView);
    [tagView removeFromSuperview];
}

#pragma mark - 付箋ビューと付箋の管理

- (void)insertNewTag:(PRTag*)tag
{
    PRDocument* doc = [PRDocumentManager sharedManager].currentDocument;
    tag.page = doc.currentPageIndex;
    
    NSUInteger index = [self findAvailableSpaceForTag_:tag];
    [tags_[1] insertObject:tag atIndex:index];
}

- (NSUInteger)findAvailableSpaceForTag_:(PRTag*)newTab
{
    // ページと付箋の間、付箋と付箋の間で、新規の付箋の幅＋余白分の間隔のある場所を探す
    // カレントページの左辺でのみ検索する
    // tags_[1]が高さ方向でソートされているのが前提
    CGFloat startValue = 0.0;     // 空きスペースの起点
    CGFloat endValue = -1.0;      // 空きスペースの終点
    CGFloat neededSpace = newTab.size.width + kTabMargin * 2.0;   // 必要な空き
    CGFloat upperY;               // 新規付箋の外形の上端（付箋内部では右端）
    PRTag* topTag = nil;        // 既存の最上部の付箋、空きが見つからなければこれと少しずらして重ねて配置    
    NSInteger found = -1;             // 挿入位置の次の既存付箋のインデックス
    
    NSUInteger i, n;
    for (i = 0, n = tags_[1].count; i < n; i++) {
        PRTag* tag = [tags_[1] objectAtIndex:i];
        if (tag.rotation != 1) continue;
        // もし左辺以外の付箋が混じっていても無視する
        
        if (!topTag) {
            topTag = tag;
        }
        endValue = tag.origin.y - tag.size.width;
        if (endValue - startValue > neededSpace) {
            found = i;
            upperY = startValue + kTabMargin;
            break;
        }
        startValue = tag.origin.y;
    }
    if (found < 0) {
        // ここまでで空きが見つかっていない場合、ページの下端までに空きがないか検討
        endValue = pageFrames_[1].size.height;
        if (!topTag || endValue - startValue > neededSpace) {
            found = i;
            upperY = startValue + kTabMargin;        
        } else {
            // 最上部の付箋と重ねて表示（マージンの半分以上ずらす）
            CGFloat top = topTag.origin.y - topTag.size.width;
            if (top < kTabMargin * 1.5) {
                found = 1;
                upperY = top + kTabMargin * 0.5;
            } else {
                found = 0;
                upperY = kTabMargin;
            }
        }
    }
    
    newTab.origin = CGPointMake(0.0, upperY + newTab.size.width);
    return found;
}

- (KLPVTagView*)createTagViewOfTag:(PRTag*)tag inPage:(NSUInteger)position scale:(CGFloat)scale
{
    // tagの位置は既に確定しているものとする
    CGRect frame = pageFrames_[position];
    CGPoint origin = CGPointMake((frame.origin.x + tag.origin.x) * scale, 
                                 (frame.origin.y + tag.origin.y) * scale);
    KLPVTagView* tagView = [[KLPVTagView alloc] initWithOrigin:origin 
                                                  rotation:tag.rotation scale:scale size:tag.size dataSource:self];
    [tagView autorelease];
    tagView.tag = position;
    CFDictionarySetValue(tagMaps_, tagView, tag);
    
    return tagView;
}

- (PRTag*)tagOfTagView:(KLPVTagView*)tagView
{
    if (tagView) {
        return CFDictionaryGetValue(tagMaps_, tagView);
    } else {
        return nil;
    }
}

@end
