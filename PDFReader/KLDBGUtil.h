//
//  KLUtilDebug.h
//  KLib Util
//
//  Created by KO on 12/05/03.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#define KLDBGPrint(...)                 printf(__VA_ARGS__)
#define KLDBGPrintMethodName(leader)    printf("%s%s\n", leader, __func__)
#define KLDBGMethod()                   __func__
#define KLDBGPoint(point)               [KLDBGUtil strPoint_:point withPrecision:1]
#define KLDBGSize(size)                 [KLDBGUtil strSize_:size withPrecision:1]
#define KLDBGRect(rect)                 [KLDBGUtil strRect_:rect withPrecision:1]
#define KLDBGClass(obj)                 ((obj).class.description.UTF8String)
#else
#define KLDBGPrint(...)
#define KLDBGPrintMethodName(leader)
#define KLDBGMethod()
#define KLDBGPoint(point)
#define KLDBGSize(size)
#define KLDBGRect(rect)
#define KLDBGClass(obj)
#endif

@interface KLDBGUtil : NSObject

+ (const char*)strPoint_:(CGPoint)point withPrecision:(NSInteger)precision;
+ (const char*)strSize_:(CGSize)size withPrecision:(NSInteger)precision;
+ (const char*)strRect_:(CGRect)point withPrecision:(NSInteger)precision;

@end
