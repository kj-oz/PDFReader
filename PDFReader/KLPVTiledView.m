//
//  KLPVTiledView.m
//  KLib PageView
//
//  Created by KO on 11/10/08.
//  Copyright 2011年 KO All rights reserved.
//

#import "KLPVTiledView.h"
#import <QuartzCore/QuartzCore.h>
#import "KLPVPageViewDataSource.h"

@implementation KLPVTiledView

#pragma mark - 初期化

- (id)initWithFrame:(CGRect)frame dataSource:(id <KLPVPageViewDataSource>)dataSource
{
    KLDBGPrintMethodName("▼ ");

    self = [super initWithFrame:frame];
    if (self) {
		CATiledLayer* tiledLayer = (CATiledLayer*)[self layer];
        // （サンプル ZoomingPDFViewer のコメントから）
		// levelsOfDetailとlevelsOfDetailBiasで異なるズームレベルでレイヤがどう描画されるかが決定される
		// これはビューがズームされている途中だけ影響する
		// ズームが終了すれば適切なサイズとスケールでKLPVTiledViewが再生成される 
        tiledLayer.levelsOfDetail = 1;
		tiledLayer.levelsOfDetailBias = 0;
        
        CGFloat scale = [UIScreen mainScreen].scale;
		tiledLayer.tileSize = CGSizeMake(512.0 * scale, 512.0 * scale);
        
        dataSource_ = dataSource;
        
        // ビューの実サイズとデータ提供オブジェクトの保持するページの実サイズから、ページのスケールを算定
        scale_ = frame.size.width / dataSource_.currentPageFrame.size.width;

        KLDBGPrint(" frame:%.1f page:%.1f scale:%.3f\n", 
               frame.size.width, dataSource_.currentPageFrame.size.width, scale_);
    }
    return self;
}

- (void)dealloc {    
    [super dealloc];
}

#pragma mark - 描画処理

+ (Class)layerClass {
    // レイヤクラスとしてCATiledLayerを返す
	return [CATiledLayer class];
}

- (void)drawRect:(CGRect)r
{
    // -drawRect:の存在によってCALayerの描画し直しを行うかどうかが決定されるので、空のメソッドを実装する
}

- (void)drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
    // 実際の描画処理はデータ提供オブジェクトに委譲する
    [dataSource_ renderCurrentPageWithContext:context scale:scale_];
}

@end
