//
//  PRAppController.h
//  PDFReader
//
//  Created by KO on 11/10/01.
//  Copyright 2011年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PRDocumentListController;

/**
 * PDFReaderのアプリケーション・コントローラ.
 */
@interface PRAppController : NSObject <UIApplicationDelegate>
{   
    IBOutlet UINavigationController*    documentListNavController_;
    IBOutlet PRDocumentListController*  documentListController_;
    IBOutlet UIWindow*  window_;
}

@property (nonatomic, retain) UIWindow* window;
@property (nonatomic, readonly) PRDocumentListController* documentListController;
@property (nonatomic, readonly) UINavigationController* documentListNavController;

/**
 * シングルトンオブジェクトを得る.
 */
+ (PRAppController*)sharedController;

@end
