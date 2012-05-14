//
//  KLTVTreeViewCell.h
//  KLib TreeView
//
//  Created by KO on 12/02/21.
//  Copyright (c) 2012年 KO All rights reserved.
//

#import "KLTVTreeViewCell.h"
#import "KLTVTreeManager.h"
#import "KLTVTreeNode.h"

#define kGapBetweenObject   4.0

@interface KLTVTreeViewCell (Private)

/**
 * 開閉ボタン押下時のイベントハンドラ.
 */
- (void)handleButtonTapped_;

@end

@implementation KLTVTreeViewCell

@synthesize delegate = delegate_;
@synthesize treeContentView = treeContentView_;
@synthesize indent = indent_;

#pragma mark - アクセッサ

// 元々のtextLabelのオーバーライド
- (UILabel*)textLabel
{
    return textLabel_;
}

// 元々のdetailTextLabelのオーバーライド
- (UILabel*)detailTextLabel
{
    return detailTextLabel_;
}

// 元々のimageViewのオーバーライド
- (UIImageView*)imageView
{
    return imageView_;
}

#pragma mark - 初期化

// 標準の初期化メソッドのオーバーライド、styleは何を指定してもSubtitleと同じレイアウトになる
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier 
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // インデントされた領域
        indentedView_ = [[UIView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:indentedView_];        
        
        // contentViewに代わって使用されるコンテナ
        treeContentView_ = [[UIView alloc] initWithFrame:CGRectZero];
        [indentedView_ addSubview:treeContentView_];
		
        // imageView
        imageView_ = [[UIImageView alloc] initWithFrame:CGRectZero];
        [treeContentView_ addSubview:imageView_];
        
        // textラベルの作成
        textLabel_ = [[UILabel alloc] initWithFrame:CGRectZero];
        textLabel_.font = [UIFont boldSystemFontOfSize:16.0f];
        textLabel_.textColor = [UIColor blackColor];
        textLabel_.highlightedTextColor = [UIColor whiteColor];
        [treeContentView_ addSubview:textLabel_];
        
        // detailTextラベルの作成
        detailTextLabel_ = [[UILabel alloc] initWithFrame:CGRectZero];
        detailTextLabel_.font = [UIFont boldSystemFontOfSize:12.0f];
        detailTextLabel_.textColor = [UIColor grayColor];
        detailTextLabel_.highlightedTextColor = [UIColor whiteColor];
        [treeContentView_ addSubview:detailTextLabel_];        
    }
    return self;
}

- (void)dealloc {
	[textLabel_ release], textLabel_ = nil;
    [detailTextLabel_ release], detailTextLabel_ = nil;
    [imageView_ release], imageView_ = nil;
    [handleButton_ release], handleButton_ = nil;
    [treeContentView_ release], treeContentView_ = nil;
    [indentedView_ release], indentedView_ = nil;
	
    [super dealloc];
}

#pragma mark - レイアウト

- (void)setHandleImage:(UIImage *)handleImage withWidth:(CGFloat)handleWidth
{
    handleWidth_ = handleWidth;
    
    if (!handleImage) {
        [handleButton_ removeFromSuperview];
        [handleButton_ release], handleButton_ = nil;
        return;
    }
    
    if (!handleButton_) {
        CGFloat indent = MAX(0, 44.0 - handleWidth);
        handleButton_ = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        handleButton_.frame = CGRectMake(indent, 0.0, handleWidth, 44.0);
        [handleButton_ addTarget:self action:@selector(handleButtonTapped_) 
                forControlEvents:UIControlEventTouchUpInside];
        [indentedView_ addSubview:handleButton_];
    }
    [handleButton_ setImage:handleImage forState:UIControlStateNormal];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // インデント領域
    CGSize boundsSize = self.contentView.bounds.size;
    CGRect frame = CGRectZero;
    frame.origin.x = indent_;
    frame.origin.y = 0.0;
    frame.size.width = boundsSize.width - indent_;
    frame.size.height = boundsSize.height;
    indentedView_.frame = frame;
    
    // 開閉ボタン
    if (handleButton_) {
        frame = handleButton_.frame;
        frame.size.height = boundsSize.height;
        handleButton_.frame = frame;
    }

    // コンテナ
    CGFloat handleW = MAX(44.0, handleWidth_);
    boundsSize = indentedView_.bounds.size;
    frame.origin.x = handleW + kGapBetweenObject;
    frame.origin.y = 0.0;
    frame.size.width = boundsSize.width - frame.origin.x;
    frame.size.height = boundsSize.height;
    treeContentView_.frame = frame;

    // イメージ
    CGFloat nextX = 0.0;
    if (imageView_.image) {
        [imageView_ sizeToFit];
        frame = imageView_.frame;
        frame.origin.x = nextX; 
        frame.origin.y = (boundsSize.height - imageView_.bounds.size.height) * 0.5;
        imageView_.frame = frame;
        
        nextX = CGRectGetMaxX(imageView_.frame) + kGapBetweenObject;
    }
    
    // ラベル
    if (textLabel_.text) {
        CGSize textSize = [textLabel_.text sizeWithFont:textLabel_.font];
        CGSize detailSize = CGSizeZero;
        CGFloat textHeight = textSize.height;
        if (detailTextLabel_.text) {
            detailSize = [detailTextLabel_.text sizeWithFont:detailTextLabel_.font];
            textHeight += detailSize.height + kGapBetweenObject;
        }
        
        frame.origin.x = nextX;
        frame.origin.y = (boundsSize.height - textHeight) * 0.5;
        frame.size.width = treeContentView_.frame.size.width - nextX;
        frame.size.height = textSize.height;
        textLabel_.frame = frame;
        
        if (detailTextLabel_.text) {
            frame.origin.y = CGRectGetMaxY(textLabel_.frame) + kGapBetweenObject;
            frame.size.height = detailSize.height;
            detailTextLabel_.frame = frame;
        }
    }    
}

#pragma mark - アクション

- (void)handleButtonTapped_
{
    UITableView* treeView = (UITableView*)self.superview;
    NSIndexPath* indexPath = [treeView indexPathForCell:self];
    
    // デリゲートに通知する
    if ([delegate_ respondsToSelector:@selector(treeView:didTapHandleAtIndexPath:)]) {
        [delegate_ treeView:treeView didTapHandleAtIndexPath:indexPath];
    }
}

@end