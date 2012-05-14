//
//  KLPVPageView.m
//  KLib PageView
//
//  Created by KO on 12/02/02.
//  Copyright (c) 2012年 KO All rights reserved.
//

#import "KLPVPageView.h"
#import "KLPVTiledView.h"
#import "KLPVTagView.h"

@interface KLPVPageView (Private)

/**
 * 背景となるUIImageViewを構築する.
 * このビューを作っておかないと、拡大・縮小時タイルごとの描画が見えてしまって醜い。
 * @param frame ビューの枠長方形
 * @param scale PDFの描画スケール
 */
- (void)createBackgroundViewWithFrame_:(CGRect)frame scale:(CGFloat)scale;

/**
 * 前景となるPRTiledViewを構築する.
 * @param frame ビューの枠長方形
 */
- (void)createTiledViewWithFrame_:(CGRect)frame;

/**
 * 付箋ビューを描画する.
 */
- (void)createTagViews_;

/**
 * スクロール後の位置を元に、コンテンツの表示対象ページを変更する.
 * コンテンツがスクロールされた際に呼び出される。
 */
- (void)scrollPage_;

/**
 * アニメーションしながら前のページへ移動する.
 */
- (void)moveToPreviousPage_;

/**
 * アニメーションしながら次のページへ移動する.
 */
- (void)moveToNextPage_;

/**
 * 左右フリックを検出し、検出したらページ送りを行う.
 * @return フリックが検出されたかどうか
 */
- (BOOL)checkFlicking_;

/**
 * シングルタップ時の処理を行う.
 * @param touches タッチオブジェクト
 */
- (void)performSingleTapWithTouches_:(NSSet*)touches;

/**
 * ダブルタップ時の処理を行う.
 * @param touches タッチオブジェクト
 */
- (void)performDoubleTapWithTouches_:(NSSet*)touches;

/**
 * タップした点を含む付箋ビューを検索する.
 * @param point タップした座標
 * @return タップした点を含む付箋ビュー
 */
- (KLPVTagView*)findTagViewAtPoint_:(CGPoint)point;

/**
 * タップした座標を求める.
 * @param touches 全タッチオブジェクトのセット
 * @return 全タッチオブジェクトの平均タッチ位置
 */
- (CGPoint)pointOfTouches_:(NSSet*)touches;

/**
 * タッチした位置からページめくりを行う方向を求める.
 * @param touchPosition タッチした位置
 * @return ページめくりの方向、-1:前ページ、0:そのまま、1:次ページ
 */
- (NSInteger)directionToMoveForPoint_:(CGPoint)touchPosition;

/**
 * ページビューを構成する各種ビューを解放する.
 */
- (void)releaseViews_;

@end

@implementation KLPVPageView

@synthesize dataSource = dataSource_;
@synthesize pageDelegate = pageDelegate_;
@synthesize scale = scale_;
@synthesize selectedTagView = selectedTagView_;

#pragma mark - アクセッサ

- (void)setSelectedTagView:(KLPVTagView*)tagView
{
    selectedTagView_.selected = NO;
    selectedTagView_ = tagView;
    selectedTagView_.selected = YES;
    
    // 自身のscrollEnabledをNOにしておかないと、tagのドラッグができない
    self.scrollEnabled = (tagView == nil);
    
    if (tagView) {
        [backgroundView_ bringSubviewToFront:tagView];
        
        [tagView addSubview:editTagButton_];
        editTagButton_.transform = CGAffineTransformMakeScale(scale_, scale_);
        editTagButton_.center = CGPointMake(tagView.bounds.size.width, 
                                            tagView.bounds.size.height / 2);
        [tagView addSubview:deleteTagButton_];
        deleteTagButton_.transform = CGAffineTransformMakeScale(scale_, scale_);
        deleteTagButton_.center = CGPointMake(0, tagView.bounds.size.height / 2);
    }
    
    // dataSourceでも付箋の選択をkeep（画面回転対応）
    [dataSource_ tagViewDidSelect:tagView];
}

- (UIImage*)editTagImage
{
    return [editTagButton_ imageForState:UIControlStateNormal];
}

- (UIImage*)deleteTagImage
{
    return [deleteTagButton_ imageForState:UIControlStateNormal];
}

- (void)setEditTagImage:(UIImage *)editTagImage
{
    [editTagButton_ setImage:editTagImage forState:UIControlStateNormal];
}

- (void)setDeleteTagImage:(UIImage *)deleteTagImage
{
    [deleteTagButton_ setImage:deleteTagImage forState:UIControlStateNormal];
}

#pragma mark - 描画処理関係

- (void)createBackgroundViewWithFrame_:(CGRect)frame scale:(CGFloat)scale
{
    // 既存の参照を解放
    [backgroundView_ removeFromSuperview];
    [backgroundView_ release];
    backgroundView_ = nil;
    
    // 画像への描画
    UIGraphicsBeginImageContext(frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [dataSource_ renderPagesWithContext:context scale:scale];
    UIImage *backgroundImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // ビューの生成、追加
    backgroundView_ = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundView_.frame = frame;
    backgroundView_.contentMode = UIViewContentModeScaleAspectFit;
    backgroundView_.opaque = NO;
    backgroundView_.autoresizesSubviews = YES;
    
    // tagView側でドラッグを処理するには、以下を有効にする必要があるが、肝心のスクロールができなくなってしまうため、
    // 全てスクロールビュー側で処理する
    // backgroundView_.userInteractionEnabled = YES;
    // backgroundView_.multipleTouchEnabled = YES;
    
    [self addSubview:backgroundView_];
    [self sendSubviewToBack:backgroundView_];
}

- (void)createTiledViewWithFrame_:(CGRect)frame
{
	[tiledView_ removeFromSuperview];
	[tiledView_ release];
    tiledView_ = nil;
    
    tiledView_ = [[KLPVTiledView alloc] initWithFrame:frame dataSource:dataSource_];
    tiledView_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleRightMargin;
    [backgroundView_ addSubview:tiledView_];
}

- (void)createTagViews_
{
    // 既存の参照を解放
    KLPVTagView* tagView;
    for (id obj in backgroundView_.subviews) {
        if ([obj isKindOfClass:[KLPVTagView class]]) {
            tagView = (KLPVTagView*)obj;
            [tagView removeFromSuperview];
        }
    }
    selectedTagView_ = nil;
    
    // ビューの生成、追加
    KLPVTagView* selected = nil;
    NSArray* tagViews = [dataSource_ createTagViewsOfPagesWithScale:scale_];
    for (tagView in tagViews) {
        [backgroundView_ addSubview:tagView];
        if (tagView.selected) {
            selected = tagView;
        }
    }
    
    // 付箋の選択を復元（回転時に選択が外れてしまうため）
    self.selectedTagView = selected;
}

- (void)renderPageWithInitialLayout
{
    KLDBGPrint("▼ %s size:%s\n", KLDBGMethod(), KLDBGSize(self.frame.size));
    CGRect cpFrame = dataSource_.currentPageFrame;
    
    // PDFの表示サイズの決定
    minScale_ = self.frame.size.width / cpFrame.size.width;
    scale_ = minScale_;
    self.minimumZoomScale = 1.0;
    self.maximumZoomScale = 4.0 / scale_;
    CGRect bvFrame = CGRectMake(0.0, 0.0, dataSource_.totalSize.width * scale_, 
                                dataSource_.totalSize.height * scale_);
    // 画面の高さ方向の中央に表示したい箇所のbvFrame内の位置
    CGFloat cy = (cpFrame.origin.y + dataSource_.targetPoint.y) * scale_;
    self.contentOffset = CGPointMake(cpFrame.origin.x * scale_, cy - self.frame.size.height * 0.5);
    self.contentSize = bvFrame.size;    
    
    // 背景画像の作成
    [self createBackgroundViewWithFrame_:bvFrame scale:scale_];
    
    // 適切なサイズとスケールのページビューの描画
    CGRect tvFrame = CGRectMake(cpFrame.origin.x * scale_, cpFrame.origin.y * scale_, 
                                cpFrame.size.width * scale_, cpFrame.size.height * scale_);
    [self createTiledViewWithFrame_:tvFrame];
    [self createTagViews_];
}

- (void)scrollPage_
{
    KLDBGPrintMethodName("▼ ");
    // ページの左右端のいずれに合わせるか。0=左、1=右
    NSInteger dir = 0;    
    
    // 現在のページ番号を保存
    NSInteger oldIndex = dataSource_.currentPageIndex;    
    NSInteger newIndex = oldIndex;
    
    // コンテンツのオフセットを取得
    // UIScrollView.contentOffsetは、スクロールビューの左上角のコンテンツの左上角を原点とした場合のピクセル座標
    // 実数の整数への丸め誤差が発生するため、判定位置を１ピクセル緩める
    CGPoint offset = self.contentOffset;
    if (offset.x <= 1) {
        // 前のページの左端へ移動
        newIndex--;
        dir = 0;
    } else if (offset.x <= dataSource_.previousPageFrame.size.width * scale_ - 
               self.frame.size.width + 1) {
        // 前のページの右端へ移動
        newIndex--;
        dir = 1;
    }
    if (offset.x >= dataSource_.totalSize.width * scale_ - self.frame.size.width - 1) {
        // 次のページの右端へ移動
        newIndex++;
        dir = 1;
    } else if (offset.x >= dataSource_.nextPageFrame.origin.x * scale_ - 1) {
        // 次のページの左端へ移動
        newIndex++;
        dir = 0;
    }
    
    // ページ遷移には不十分でも、移動量がある程度あれば、まず十分な移動量になるまでアニメーションでスクロールする。
    if (newIndex == oldIndex) {
        if (offset.x <= dataSource_.previousPageFrame.size.width * scale_ - 
            self.frame.size.width * 0.2) {
            // 前のページへ移動
            [self moveToPreviousPage_];
            return;
        }
        if (offset.x >= dataSource_.nextPageFrame.origin.x * scale_ - 
            self.frame.size.width * 0.8) {
            // 次のページへ移動
            [self moveToNextPage_];
            return;
        }
    }
    
    // ページ番号の範囲をチェック
    if (newIndex < 0) {
        newIndex = 0;
    }
    NSUInteger pageNumber = dataSource_.numPages;
    if (newIndex >= pageNumber) {
        newIndex = pageNumber - 1;
    }
    
    if (newIndex == oldIndex) {
        return;
    }
    
    // 背景画像は最小スケールで生成し、必要なサイズまで引き伸ばし
    KLDBGPrint("▽ %s willScroll\n", __func__);
    
    dataSource_.currentPageIndex = newIndex;
    [pageDelegate_ pageViewCurrentPageDidChange];
    
    CGRect cpFrame = dataSource_.currentPageFrame;
    minScale_ = self.frame.size.width / cpFrame.size.width;
    CGFloat scale = minScale_;
    CGRect imageRect = CGRectMake(0.0, 0.0, dataSource_.totalSize.width * scale, 
                                  dataSource_.totalSize.height * scale);
    [self createBackgroundViewWithFrame_:imageRect scale: scale];
    
    CGRect bvFrame = CGRectMake(0.0, 0.0, dataSource_.totalSize.width * scale_, 
                                dataSource_.totalSize.height * scale_);
    backgroundView_.frame = bvFrame;
    
    // コンテンツの新たなオフセットの算定
    CGPoint newOffset = CGPointZero;
    if (dir == 0) {
        newOffset.x = cpFrame.origin.x * scale_;
    } else {
        newOffset.x = dataSource_.nextPageFrame.origin.x * scale_ - self.frame.size.width;
    }
    
    // ページにより高さが異なる場合、ます高さの中心を保ったままページ遷移を行う。
    // cy：現在のスクロールビュー上端のコンテンツの高さの中心からの高さ
    CGFloat cy = self.contentSize.height * 0.5 - offset.y;
    newOffset.y = bvFrame.size.height * 0.5 - cy;
    self.contentOffset = newOffset;
    self.contentSize = bvFrame.size;
    
    // 前景タイルレイヤの作成
    bvFrame = CGRectMake(cpFrame.origin.x * scale_, cpFrame.origin.y * scale_, 
                         cpFrame.size.width * scale_, cpFrame.size.height * scale_);
    [self createTiledViewWithFrame_:bvFrame];
    [self createTagViews_];
    
    // ページ幅が画面幅以下にならない様にminimumZoomScaleを設定
    if (scale_ > minScale_) {
        self.minimumZoomScale = minScale_ / scale_;
    } else {
        // もし既になっている場合は、下限値まで拡大
        [self setZoomScale:(minScale_ / scale_)];
        self.minimumZoomScale = 1.0;        
    }
}

- (void)moveToPreviousPage_
{
    KLDBGPrintMethodName("▼ ");
    CGPoint offset = self.contentOffset;
    offset.x = MAX(dataSource_.previousPageFrame.size.width * scale_ - 
                   self.frame.size.width, 0);
    [self setContentOffset:offset animated:YES];    
}

- (void)moveToNextPage_
{
    KLDBGPrintMethodName("▼ ");
    CGPoint offset = self.contentOffset;
    offset.x = MIN(dataSource_.nextPageFrame.origin.x * scale_, 
                   dataSource_.totalSize.width * scale_ - self.frame.size.width);
    [self setContentOffset:offset animated:YES];
}

- (void)addTagView:(KLPVTagView *)tagView
{
    [backgroundView_ addSubview:tagView];
    self.selectedTagView = tagView;
    
    CGRect r = [backgroundView_ convertRect:tagView.bounds fromView:tagView];
    [self scrollRectToVisible:r animated:true];
}

#pragma mark - 初期化

- (id)initWithFrame:(CGRect)frame dataSource:(id <KLPVPageViewDataSource>)dataSource
{
    self = [super initWithFrame:frame];
    if (self) {
        dataSource_ = dataSource;
        self.delegate = self;
        
        // 付箋ビュー選択時に表示されるボタンを予め生成しておく.
        // スクロールを有効にするため、ボタンのイベントは使用しない.
        // UIButtonTypeCustomを使用するとうまく画像が表示されないため、ダミーでUIButtonTypeContactAddを使用
        UIImage* editImage = [UIImage imageNamed:@"KLPVEditTag.png"];
        editTagButton_ = [[UIButton buttonWithType:UIButtonTypeContactAdd] retain];
        [editTagButton_ setImage:editImage forState:UIControlStateNormal];
        UIImage* deleteImage = [UIImage imageNamed:@"KLPVDeleteTag.png"];
        deleteTagButton_ = [[UIButton buttonWithType:UIButtonTypeContactAdd] retain];
        [deleteTagButton_ setImage:deleteImage forState:UIControlStateNormal];
        
        // subView側でドラッグを処理するためには以下有効にする必要がある（但しスクロールができなくなる）
        // self.canCancelContentTouches = NO;
    }
    return self;
}

/**
 * ビューの参照の解放
 */
- (void)releaseViews_
{
    [tiledView_ removeFromSuperview];
    [tiledView_ release], tiledView_ = nil;
    [backgroundView_ removeFromSuperview];
	[backgroundView_ release], backgroundView_ = nil;
}

- (void)dealloc
{
    [self releaseViews_];
    [editTagButton_ release], editTagButton_ = nil;
    [deleteTagButton_ release], deleteTagButton_ = nil;
    
    [super dealloc];
}

#pragma mark - UIScrollView オーバーライド

// コンテンツの２つのビューの位置を同期する。
// また、ページ高さがビューの高さに満たない場合に、中央寄せを行う。
- (void)layoutSubviews 
{
    //KLDBGPrintMethodName("▼ ");
    
    CGSize boundsSize = self.bounds.size;
    CGRect frame = backgroundView_.frame;
    
    // 高さの調整
    CGPoint offset = self.contentOffset;
    if (frame.size.height < boundsSize.height) {
        offset.y = -(boundsSize.height - frame.size.height) / 2;
    } else if (offset.y < 0.0) {
        offset.y = 0.0;
    } else if (offset.y + boundsSize.height > frame.size.height) {
        offset.y = frame.size.height - boundsSize.height;
    }
    self.contentOffset = offset;    
    
    // LayoutSubViewの動作を調べる際のデバッグコード
    // debugPrint(" offset %s\n", KLDBGPoint(self.contentOffset));
    // debugPrint(" size %s\n", KLDBGSize(self.contentSize));
    // debugPrint(" scale  %.3f\n", self.contentSize.height / renderer_.totalSize.height);
    // CGAffineTransform tr = backgroundView_.transform;
    // debugPrint(" bg afn %.3f %.3f %.3f %.3f %.1f %.1f\n", tr.a, tr.b, tr.c, tr.d, tr.tx, tr.ty);
    
	// 手動でcontentScaleFactorを1.0に設定しておく。これを省くと、CATiledLayerとハイレゾ・スクリーンの組み合せで
    // 半分のサイズで描画されてしまう。
	tiledView_.contentScaleFactor = 1.0;
}

#pragma mark - タップ処理の実現

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
    singleTapped_ = NO;
    waitDoubleTap_ = NO;
    if (selectedTagView_) {
        // 付箋ビューが選択状態（スクロールはoff）の場合
        if (touches.count == 1 && 
                (CGRectContainsPoint(editTagButton_.bounds,
                        [[touches anyObject] locationInView:editTagButton_]) ||
                CGRectContainsPoint(deleteTagButton_.bounds,
                        [[touches anyObject] locationInView:deleteTagButton_]))) {
           // 編集ボタン／削除ボタン上であれば、Beganでは何もせずに様子見
           KLDBGPrint("◆ buttonTouchBegan\n");        
           return;
        }
        if (touches.count == 1 && 
                CGRectContainsPoint(selectedTagView_.bounds, 
                        [[touches anyObject] locationInView:selectedTagView_])) {
            // 選択された付箋上であれば、ドラッグ移動の開始フラグをたてる
            dragTagStarted_ = YES;
            tagMoved_ = NO;
            CGRect pageFrame = [dataSource_ pageFrameOfPosition:selectedTagView_.tag];
            dragTagLimit_[0] = CGRectGetMinY(pageFrame) * scale_;
            dragTagLimit_[1] = CGRectGetMaxY(pageFrame) * scale_;
        } else {
            // それ以外の箇所の場合は、現在の付箋ビューの選択状態を解除したいが、
            // ここで解除してしまうと、解除とページ送りが同時に発生してしまうため、Endで解除する
            return;
        }
    }
    
    // 新たな付箋ビューを選択（ダブルタップ）しようとしている可能性があるか判定する
    CGPoint pt = [[touches anyObject] locationInView:self];
    KLPVTagView* tagView = [self findTagViewAtPoint_:pt];
    if (tagView) {
        waitDoubleTap_ = YES;
        return;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (dragTagStarted_) {
        // 付箋ビューのドラッグ移動中のみ移動が有効
        // 以下、付箋は90度回転していて、上下にしか移動できないことが前提
        CGPoint pt = [[touches anyObject] locationInView:selectedTagView_];
        CGPoint prevPt = [[touches anyObject] previousLocationInView:selectedTagView_];
        CGFloat dx = pt.x - prevPt.x;
        
        CGRect tagFrame = [backgroundView_ convertRect:selectedTagView_.bounds 
                                              fromView:selectedTagView_];
        CGFloat dxMin = -(dragTagLimit_[1] - CGRectGetMaxY(tagFrame));
        CGFloat dxMax = -(dragTagLimit_[0] - CGRectGetMinY(tagFrame));
        if (dx < dxMin) dx = dxMin;
        if (dx > dxMax) dx = dxMax;
        if (fabsf(dx) > 0.1) {
            tagMoved_ = YES;
            selectedTagView_.transform = 
            CGAffineTransformTranslate(selectedTagView_.transform, dx, 0.0);
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // ドラッグの場合はScrollViewで処理されてしまいここにこない
    if (dragTagStarted_) {
        // drag開始状態の後始末
        if (tagMoved_) {
            [dataSource_ tagViewDidMove:selectedTagView_];
        }
        dragTagStarted_ = NO;
    } else if ([[touches anyObject] tapCount] < 2) {
        // 最初のタップの場合
        singleTapped_ = YES;
        if (waitDoubleTap_) {
            // 付箋ビュー上であれば、ダブルタップの可能性があるので、0.3秒待つ
            [self performSelector:@selector(performSingleTapWithTouches_:) 
                       withObject:touches afterDelay:0.3F];
        } else {
            // それ以外は直接シングルタップ処理を実行
            [self performSingleTapWithTouches_:touches];
        }
    } else {
        // ２度目のタップの場合
        [self performDoubleTapWithTouches_:touches];
    }
}

- (void)performSingleTapWithTouches_:(NSSet*)touches
{
    if (!singleTapped_) return;
    
    if (!self.dragging) {
        if (self.selectedTagView) {
            // 付箋ビューが選択状態の場合、編集ボタン／削除ボタンが押下されたかをチェック
            if (touches.count == 1 && CGRectContainsPoint(editTagButton_.bounds,
                                                          [[touches anyObject] locationInView:editTagButton_])) {
                [pageDelegate_ editTagAction:editTagButton_];
                return;
            }
            if (touches.count == 1 && CGRectContainsPoint(deleteTagButton_.bounds,
                                                          [[touches anyObject] locationInView:deleteTagButton_])) {
                [pageDelegate_ deleteTagAction:deleteTagButton_];
                return;
            }
            
            // それ以外の箇所の場合は、(Beginで保留した)現在の付箋ビューの選択状態を解除する
            self.selectedTagView = nil;
            [editTagButton_ removeFromSuperview];
            [deleteTagButton_ removeFromSuperview];
            return;
        }
        
        // ページの左右端部の場合はページ送り、それ以外はビューコントローラに委譲する.
        CGPoint pt = [self pointOfTouches_:touches];        
        switch ([self directionToMoveForPoint_:pt]) {
            case -1:
                [self moveToPreviousPage_];
                break;
            case 1:
                [self moveToNextPage_];
                break;
            default:
                [pageDelegate_ tappedWithTouch:[touches anyObject]]; 
                break;
        }
        return;
    }		
}

- (void)performDoubleTapWithTouches_:(NSSet *)touches
{
    CGPoint pt = [[touches anyObject] locationInView:self];
    KLPVTagView* tagView = [self findTagViewAtPoint_:pt];
    if (tagView) {
        self.selectedTagView = tagView;
        return;
    }
    
    singleTapped_ = YES;
    [self performSingleTapWithTouches_:touches];
}

- (KLPVTagView*)findTagViewAtPoint_:(CGPoint)point
{
    NSUInteger n = backgroundView_.subviews.count;
    for (NSInteger i = n - 1; i >= 0; i--) {
        UIView* subView = [backgroundView_.subviews objectAtIndex:i];
        if ([subView class] == [KLPVTagView class]) {
            KLPVTagView* tagView = (KLPVTagView*)subView;
            CGRect frame = [self convertRect:tagView.bounds fromView:tagView];
            if (CGRectContainsPoint(frame, point)) {
                return tagView;
            }
        }
    }
    return nil;
}

- (CGPoint)pointOfTouches_:(NSSet*)touches
{
    CGPoint result = CGPointZero;
    for (UITouch* touch in touches) {
        CGPoint touchPt = [touch locationInView:self.superview];
        result.x += touchPt.x;
        result.y += touchPt.y;
    }
    NSUInteger n = touches.count;
    result.x /= n;
    result.y /= n;
    return result;
}

- (NSInteger)directionToMoveForPoint_:(CGPoint)touchPosition
{
    CGSize size = self.bounds.size;
    if (touchPosition.y > size.height * 0.2 && touchPosition.y < size.height * 0.8) {
        if (touchPosition.x < size.width * 0.2) {
            return -1;
        } else if (touchPosition.x > size.width * 0.8) {
            return 1;
        }
    }
    return 0;
}

#pragma mark - UIScrollView デリゲート

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    KLDBGPrint("▼ %s zooming:%d\n", KLDBGMethod(), self.zooming);
//    printf("◆ scrollViewWillBeginDragging zooming:%d\n", self.zooming);
    
    // ズーム時にも（scrollViewWillBeginZoomingの後で）呼び出されるので、その場合フリック検出はしない
    if (self.zooming) {
        flickDetecting_ = NO;
    } else {
        flickDetecting_ = YES;
        flickStartPoint_ = [self contentOffset];
        flickStartTime_ = [NSDate timeIntervalSinceReferenceDate];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView 
                  willDecelerate:(BOOL)decelerate
{
    KLDBGPrint("▼ %s zooming:%d\n", KLDBGMethod(), (int)decelerate);
//    printf("◆ scrollViewDidEndDragging %d\n", (int)decelerate);
    
    // スクロールされたらscrollPage_を呼び出す
    if (!decelerate) {
        // decelerate == NO はズーム時のため、フリックチェックは行わない
        [self scrollPage_];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView
{
    KLDBGPrintMethodName("▼ ");
    if ([self checkFlicking_]) {
        return;
    }
    [self scrollPage_];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    KLDBGPrintMethodName("▼ ");
    [self scrollPage_];
}

- (BOOL)checkFlicking_
{
    BOOL flicked = NO;
    if (flickDetecting_) {
        flickDetecting_ = NO;
        CGPoint pt = [self contentOffset];
        CGFloat dx = -(pt.x - flickStartPoint_.x);
        CGFloat dt = [NSDate timeIntervalSinceReferenceDate] - flickStartTime_;
        
        if (dt < 0.6 && (dx > 30 || dx < -30)) {
            // 左右フリック
            if (dx < 0) {
                [self moveToNextPage_];
            } else {
                [self moveToPreviousPage_];
            }
            flicked = YES;
        }
        KLDBGPrint("▽ %s dt:%.2f dx:%.0f %d\n", KLDBGMethod(), dt, dx, flicked);
    }
    return flicked;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    // ここでは背景画像のビューを返す.タイルレイヤは背景画像のsubview.
    return backgroundView_;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    KLDBGPrint("▼ %s pdfScale:%.3f\n", KLDBGMethod(), scale_);
//    printf("◆ scrollViewWillBeginZooming\n");
//    printf(" pdfScale %.3f\n", scale_);
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView 
                       withView:(UIView *)view atScale:(CGFloat)scale
{
    // ズーム終了後にタイルレイヤビューを再構築する
    KLDBGPrintMethodName("▼ ");
    
    // 新たなスケールでのPDFのスケールとビューのサイズを求める
    scale_ *= scale;
    KLDBGPrint(" scale %.3f pdfScale:%.3f\n", scale, scale_);
//    printf(" scale    %.3f\n", scale);
//    printf(" pdfScale %.3f\n", scale_);
    
    // ページ幅が画面幅以下にならない様にminimumZoomScaleを設定
    self.minimumZoomScale = minScale_ / scale_;
    self.maximumZoomScale = 4.0 / scale_;
    
    // zoom時に設定されたtransformをクリアして標準の状態に戻す
    // 　tileViewを一度中心座標を合わせて見た目の大きさのビューを作り、それに逆スケールのtransformをかける方法でも
    // 　対応可能だが、様々な部分が複雑になりそうなので、こちらの方策をとる
    CGRect bvFrame = backgroundView_.frame;
    backgroundView_.transform = CGAffineTransformMakeScale(1.0, 1.0);
    backgroundView_.frame = bvFrame;
    
    // タイルレイヤの解放および構築
    // 古いtiledView_はここで解放する（scrollViewWillBeginZooming で解放すると画面が乱れる）
    // 　サンプル ZoomingPDFViewer では、直前のtiledView_自体は解放せず、１回前のtiledView_を
    // 　scrollViewWillBeginZoomingで解放しているが、ここでtiledView_自体を直接解放しても挙動はほとんど
    // 　変わらないためシンプルなこの方式を採用
    CGRect cpFrame = dataSource_.currentPageFrame;
    CGRect tvFrame = CGRectMake(cpFrame.origin.x * scale_, cpFrame.origin.y * scale_, 
                                cpFrame.size.width * scale_, cpFrame.size.height * scale_);
    [self createTiledViewWithFrame_:tvFrame];
    [self createTagViews_];
}

@end
