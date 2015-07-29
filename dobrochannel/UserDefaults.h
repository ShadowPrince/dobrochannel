//
//  UserDefaults.h
//  dobrochannel
//
//  Created by shdwprince on 7/29/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserDefaults : NSObject

+ (BOOL) attachmentsViewerLoadFull;
+ (BOOL) contentReaderLoadThumbnails;

+ (BOOL) contentReaderLoadFull;
+ (NSInteger) contentReaderLoadFullMaxSize;

+ (BOOL) showUnrated;
+ (NSInteger) maxRating;

@end
