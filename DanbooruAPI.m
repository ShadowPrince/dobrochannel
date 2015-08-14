//
//  DanbooruAPI.m
//  dobrochannel
//
//  Created by shdwprince on 8/12/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "DanbooruAPI.h"

@interface DanbooruAPI ()
@property (weak) NSObject<DanbooruAPIDelegate> *delegate;
@property NSMutableDictionary *imageDownloadTasks;

@property (readonly) NSString *host;

@property NSObject *sync;
@property NSOperationQueue *queue;
@property NSURLSession *session;
@end @implementation DanbooruAPI

- (instancetype) initWithDelegate:(NSObject<DanbooruAPIDelegate> *)delegate {
    self = [super init];
    self.delegate = delegate;
    self.queue = [NSOperationQueue new];
    self.sync = [NSObject new];
    self.imageDownloadTasks = [NSMutableDictionary new];
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    return self;
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context {
    if ([keyPath isEqualToString:@"countOfBytesReceived"]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate imageDownloadingTask:self.imageDownloadTasks[object]
                                       progress:[(NSNumber *) change[@"new"] longLongValue]
                                             of:[(NSURLSessionDownloadTask *) object countOfBytesExpectedToReceive]];
        });
    }
}

- (NSURLSessionTask *) downloadImage:(NSDictionary *)image
        finishCallback:(DanbooruAPIImageDownloadFinishCallback)cb {
    if (!image[@"file_url"])
        return nil;

    NSURL *url = [NSURL URLWithString:[self.host stringByAppendingString:image[@"file_url"]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    NSURLSessionDownloadTask *task = [self.session downloadTaskWithRequest:request
                                                         completionHandler:^(NSURL * location, NSURLResponse * response, NSError * error) {
                                                             dispatch_sync(dispatch_get_main_queue(), ^{
                                                                 cb(location);
                                                             });
                                                         }];
    [task addObserver:self forKeyPath:@"countOfBytesReceived" options:NSKeyValueObservingOptionNew context:nil];
    self.imageDownloadTasks[task] = image;

    [task resume];
    return task;
}

- (NSURLSessionDataTask *) requestThumbnailFor:(NSDictionary *)image
                                finishCallback:(DanbooruAPIThumbnailDownloadFinishCallback)cb {
    if (!image[@"preview_file_url"])
        return nil;

    NSURL *url = [NSURL URLWithString:[self.host stringByAppendingString:image[@"preview_file_url"]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
                                                     if (data) {
                                                         UIImage *image = [[UIImage alloc] initWithData:data];
                                                         cb(image);
                                                     }
                                                }];

    [task resume];
    return task;
}

- (void) requestImagesFor:(NSArray *)tags
                     page:(NSUInteger)page {
    self.isRequesting = YES;

    NSString *url = [NSString stringWithFormat:@"/posts.json"];
    NSDictionary *params = @{@"tags": [tags componentsJoinedByString:@" "],
                             @"limit": @"5",
                             @"page": [NSString stringWithFormat:@"%lu", (long unsigned) page], };

    [self.queue addOperationWithBlock:^{
        NSObject *response = [self requestSyncJSON:url params:params];
        if ([response isKindOfClass:[NSDictionary class]]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.delegate didFailRequest:[(NSDictionary *) response valueForKey:@"message"]];
            });
        } else {
            for (NSDictionary *info in (NSArray *) response) {
                if (![info isKindOfClass:[NSDictionary class]]) {
                    continue;
                }

                if (info)
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self.delegate didReceiveImage:info];
                    });
            }
        }

        dispatch_sync(dispatch_get_main_queue(), ^{
            self.isRequesting = NO;
            [self.delegate didFinishedRequest];
        });
    }];
}

- (NSURLSessionTask *) requestTagsMatching:(NSString *)pattern {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/tags/autocomplete.json?search[name_matches]=%@",
                                       self.host,
                                       [pattern stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:[NSURLRequest requestWithURL:url]
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                     if (data) {
                                                         NSArray *json = [NSJSONSerialization JSONObjectWithData:data
                                                                                                         options:0
                                                                                                           error:nil];
                                                         if (json) {
                                                             dispatch_sync(dispatch_get_main_queue(), ^{
                                                                 [self.delegate didReceiveTags:json];
                                                             });
                                                         }
                                                     }
                                                 }];
    [task resume];
    return task;
}

- (UIImage *) requestThumbnailImage:(NSDictionary *) info {

    NSString *url;
    if (info[@"preview_file_url"]) {
        url = info[@"preview_file_url"];
    } else {
        return nil;
    }

    NSData *imageData = [self requestSync:url params:nil];
    return [UIImage imageWithData:imageData];
}

- (id) requestSyncJSON:(NSString *) urlString
                params:(NSDictionary *) params {
    return [NSJSONSerialization JSONObjectWithData:[self requestSync:urlString params:params]
                                           options:0
                                             error:nil];
}

- (id) requestSync:(NSString *) urlString
            params:(NSDictionary *) params {
    NSMutableString *paramsString = [NSMutableString new];
    [params enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * stop) {
        [paramsString appendString:[NSString stringWithFormat:@"%@=%@&",
                                    key,
                                    [obj stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    }];

    NSURL *url = [NSURL URLWithString:
                  [@[self.host, urlString, @"?", paramsString ? paramsString : @""] componentsJoinedByString:@""]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:nil
                                                     error:nil];

    return data;
}

- (NSString *) host {
    return @"http://danbooru.donmai.us";
}

- (void) dealloc {
    [self.imageDownloadTasks enumerateKeysAndObjectsUsingBlock:^(NSURLSessionDownloadTask *key, NSDictionary *obj, BOOL * stop) {
        [key removeObserver:self forKeyPath:@"countOfBytesReceived"];
        [key cancel];
    }];
}

@end