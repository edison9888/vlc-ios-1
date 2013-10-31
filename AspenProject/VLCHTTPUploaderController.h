//
//  VLCHTTPUploaderViewController.h
//  VLC for iOS
//
//  Created by Jean-Baptiste Kempf on 19/05/13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import <UIKit/UIKit.h>

@class HTTPServer;

@interface VLCHTTPUploaderController : NSObject

@property (nonatomic, readonly) HTTPServer *httpServer;

- (BOOL)changeHTTPServerState:(BOOL)state;
- (NSString *)currentIPAddress;

@end
