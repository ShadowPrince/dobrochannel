//
//  UserDefaults.m
//  dobrochannel
//
//  Created by shdwprince on 7/29/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "UserDefaults.h"

@implementation UserDefaults

+ (BOOL) attachmentsViewerLoadFull {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:@"av_load_full"];

    return value.boolValue;
}

+ (BOOL) contentReaderLoadFull {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:@"cr_load_full"];

    return value.boolValue;
}

+ (NSInteger) contentReaderLoadFullMaxSize {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:@"cr_load_full_max_size"];

    return value.integerValue;
}

+ (BOOL) contentReaderLoadThumbnails {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:@"cr_load_thumbs"];

    return value.boolValue;
}


+ (BOOL) showUnrated {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:@"show_no_rating"];

    return value.boolValue;
}

+ (NSInteger) maxRating {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:@"max_rating"];

    return value.integerValue;
}

@end
