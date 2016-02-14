//
//  UserDefaults.h
//  dobrochannel
//
//  Created by shdwprince on 7/29/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserDefaults : NSObject

+ (void) setupDefaultValues;

+ (BOOL) attachmentsViewerLoadFull;
+ (BOOL) attachmentsViewLoadFull;;
+ (BOOL) contentReaderLoadThumbnails;

+ (BOOL) contentReaderLoadFull;
+ (NSInteger) contentReaderLoadFullMaxSize;

+ (BOOL) showUnrated;
+ (NSInteger) maxRating;
+ (float) textSize;

+ (NSString *) postPassword;

+ (NSArray *) listOfBannedPosts;
+ (NSNumber *) supportThreadNumber;
+ (BOOL) showReportButton;
+ (BOOL) enhanced;

@end