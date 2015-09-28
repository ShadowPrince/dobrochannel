//
//  UserDefaults.m
//  dobrochannel
//
//  Created by shdwprince on 7/29/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "UserDefaults.h"

@implementation UserDefaults

+ (NSArray *) listOfBannedPosts {
    static NSArray *list = nil;

    if (!list) {
        NSString *str = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://shadowprince.github.io/dobrochannel/apple_banned_posts.txt"]
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];

        list = [str componentsSeparatedByString:@"\n"];
        if (!list)
            list = @[];
    }

    return list;
}

+ (void) setupDefaultValues {
    NSString *pwd = [[[NSProcessInfo processInfo] globallyUniqueString] substringToIndex:8];

    NSDictionary *defaultValues = @{@"initial_setup": @YES,
                                    @"av_load_full": @YES,
                                    @"cr_load_full": @NO,
                                    @"cr_load_full_max_size": @333,
                                    @"cr_load_thumbs": @YES,
                                    @"cr_show_no_rating": @NO,
                                    @"post_password": pwd,
                                    };

    [defaultValues enumerateKeysAndObjectsUsingBlock:^(id  key, id  obj, BOOL * stop) {
        if (![[NSUserDefaults standardUserDefaults] valueForKey:key]) {
            [[NSUserDefaults standardUserDefaults] setValue:obj forKey:key];
        }
    }];
}

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

+ (NSString *) postPassword {
    return (NSString *) [[NSUserDefaults standardUserDefaults] valueForKey:@"post_password"];
}

@end