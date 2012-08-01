//
//  PRTag.m
//  PDFReader
//
//  Created by KO on 11/12/13.
//  Copyright (c) 2011年 KO. All rights reserved.
//

#import "PRTag.h"

static CGFloat presetColors_[][4] = {
    { 1.0, 0.0, 0.0, 1.0 },
    { 1.0, 1.0, 0.0, 1.0 },
    { 0.0, 1.0, 0.0, 1.0 },
    { 0.0, 1.0, 1.0, 1.0 },
    { 0.0, 0.0, 1.0, 1.0 },
    { 1.0, 0.0, 1.0, 1.0 }
};

#define kColorElementTolerance          0.001
#define compareColorElement(a, b)       (a < b - kColorElementTolerance ? -1 : \
                                            a > b + kColorElementTolerance ? 1 : 0)

#define kDefaultTabColorHeight  8.0
#define kDefaultTabHeight       32.0
#define kDefaultTabWidth        96.0
#define kDefaultTabFontSize     9.0

@implementation PRTag

@synthesize uid = uid_;
@synthesize page = page_;
@synthesize origin = origin_;
@synthesize size = size_;
@synthesize colorHeight = colorHeight_;
@synthesize color = color_;
@synthesize text = text_;
@synthesize fontSize = fontSize_;
@synthesize rotation = rotation_;

#pragma mark - クラスメソッド

+ (NSInteger)findPresetColor:(UIColor*)color
{
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    NSUInteger n = sizeof(presetColors_) / sizeof(presetColors_[0]);
    for (NSUInteger i = 0; i < n; i++) {
        if (!compareColorElement(red, presetColors_[i][0]) && 
            !compareColorElement(green, presetColors_[i][1]) &&
            !compareColorElement(blue, presetColors_[i][2]) && 
            !compareColorElement(alpha, presetColors_[i][3])) {
            return i;
        }
    }
    return -1;
}

+ (UIColor*)presetColorAtIndex:(NSUInteger)index
{
    return [UIColor colorWithRed:presetColors_[index][0] green:presetColors_[index][1] 
                            blue:presetColors_[index][2] alpha:presetColors_[index][3]];
}

+ (NSUInteger)presetColorCount
{
    return sizeof(presetColors_) / sizeof(presetColors_[0]);
}

#pragma mark - プロパティ

- (CGPoint)center
{
    CGFloat dx = size_.width * 0.5;
    CGFloat dy = size_.height * 0.5;
    CGPoint center = CGPointMake(dx, dy);
    switch (rotation_) {
        case 1:
            center = CGPointMake(dy, -dx);
            break;
        case 2:
            center = CGPointMake(-dx, -dy);
            break;
        case 3:
            center = CGPointMake(-dy, dx);
            break;
    }
    center.x += origin_.x;
    center.y += origin_.y;
    
    return center;
}

- (void)setText:(NSString*)text
{
    if (text_ == nil || [text_ compare:text] != NSOrderedSame) {
        [text_ release], text_ = nil;
        text_ = [[text copy] retain];
    }
}

#pragma mark - 初期化

// 新規の空の付箋の初期化
- (id)init
{
    self = [super init];
    if (self) {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        uid_ = (NSString*)CFUUIDCreateString(NULL, uuid);
        
        // デフォルト値
        colorHeight_ = kDefaultTabColorHeight;
        size_ = CGSizeMake(kDefaultTabWidth, kDefaultTabHeight);
        fontSize_ = kDefaultTabFontSize;
        CFRelease(uuid);
    }    
    return self;
}

- (void)dealloc
{
    [uid_ release], uid_ = nil;
    [text_ release], text_ = nil;
    
    [super dealloc];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        uid_ = [[decoder decodeObjectForKey:@"uid"] retain];
        origin_ = CGPointMake([decoder decodeFloatForKey:@"origin.x"],
                              [decoder decodeFloatForKey:@"origin.y"]);
        colorHeight_ = [decoder decodeFloatForKey:@"colorWidth"];
        size_ = CGSizeMake([decoder decodeFloatForKey:@"size.width"],
                              [decoder decodeFloatForKey:@"size.height"]);
        CGFloat red = [decoder decodeFloatForKey:@"color.red"];
        CGFloat green = [decoder decodeFloatForKey:@"color.green"];
        CGFloat blue = [decoder decodeFloatForKey:@"color.blue"];
        CGFloat alpha = [decoder decodeFloatForKey:@"color.alpha"];
        color_ = [[UIColor alloc] initWithRed:red green:green blue:blue alpha:alpha];
        text_ = [[decoder decodeObjectForKey:@"text"] retain];
        fontSize_ = [decoder decodeFloatForKey:@"fontSize"];
        rotation_ = [decoder decodeIntegerForKey:@"rotation"];
    }    
    return self;    
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:uid_ forKey:@"uid"];
    [encoder encodeFloat:origin_.x forKey:@"origin.x"];
    [encoder encodeFloat:origin_.y forKey:@"origin.y"];
    [encoder encodeFloat:colorHeight_ forKey:@"colorWidth"];
    [encoder encodeFloat:size_.width forKey:@"size.width"];
    [encoder encodeFloat:size_.height forKey:@"size.height"];
    CGFloat red, green, blue, alpha;
    [color_ getRed:&red green:&green blue:&blue alpha:&alpha];
    [encoder encodeFloat:red forKey:@"color.red"];
    [encoder encodeFloat:green forKey:@"color.green"];
    [encoder encodeFloat:blue forKey:@"color.blue"];
    [encoder encodeFloat:alpha forKey:@"color.alpha"];    
    [encoder encodeObject:text_ forKey:@"text"];
    [encoder encodeFloat:fontSize_ forKey:@"fontSize"];
    [encoder encodeInteger:rotation_ forKey:@"rotation"];
}

@end
