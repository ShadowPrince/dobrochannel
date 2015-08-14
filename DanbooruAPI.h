//
//  DanbooruAPI.h
//  dobrochannel
//
//  Created by shdwprince on 8/12/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^DanbooruAPIImageDownloadFinishCallback) (NSURL *);
typedef void (^DanbooruAPIThumbnailDownloadFinishCallback) (UIImage *);

@protocol DanbooruAPIDelegate <NSObject>

- (void) didReceiveImage:(NSDictionary *) info;

- (void) didFinishedRequest;
- (void) didFailRequest:(NSString *) msg;

- (void) didReceiveTags:(NSArray *) array;

- (void) imageDownloadingTask:(NSDictionary *) image
                     progress:(long long) completed
                           of:(long long) total;

@end

@interface DanbooruAPI : NSObject
@property BOOL isRequesting;

- (instancetype) initWithDelegate:(NSObject<DanbooruAPIDelegate> *) delegate;

- (void) requestImagesFor:(NSArray *) tags
                     page:(NSUInteger) page;
- (NSURLSessionDataTask *) requestThumbnailFor:(NSDictionary *) image
                                finishCallback:(DanbooruAPIThumbnailDownloadFinishCallback) cb;
- (NSURLSessionTask *) requestTagsMatching:(NSString *) pattern;

- (NSURLSessionTask *) downloadImage:(NSDictionary *) image
                      finishCallback:(DanbooruAPIImageDownloadFinishCallback) cb;

@end
