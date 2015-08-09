//
//  Networking.m
//  dobrochannel
//
//  Created by shdwprince on 7/19/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "BoardAPI.h"

@interface BoardAPI ()
@property NSOperationQueue *oqueue;
@property NSURLSessionDataTask *currentTask;
@property NSURLSession *imageLoadingSession;
@property NSMutableDictionary<NSURLSessionTask *, BoardAPIProgressCallback> *progressCallbacks;

@end @implementation BoardAPI
@synthesize delegate, currentTask;

+ (instancetype) api {
    static BoardAPI *api = nil;

    if (!api)
        api = [[BoardAPI alloc] init];

    return api;
}

- (instancetype) init {
    self = [super init];
    self.oqueue = [[NSOperationQueue alloc] init];

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.requestCachePolicy = NSURLRequestReturnCacheDataElseLoad;

    self.imageLoadingSession = [NSURLSession sessionWithConfiguration:config];
    self.progressCallbacks = [NSMutableDictionary new];

    return self;
}

# pragma mark info and helper methods

- (NSDictionary *) boardsList {
    NSArray *sortedNames = @[@"b",        @"u" ,        @"dt" ,
        @"vg" ,        @"r" ,        @"cr" ,        @"lor",        @"mu" ,        @"oe" ,
        @"s",
                             @"w",        @"hr", @"mad"];
    NSMutableDictionary *boards = [@{@"b": @[@"Братство", @"Доска обо всем"],
                                     @"u": @[@"Университет", @"Dum docemus, discimus"],
                                     @"dt": @[@"Dates and datings", @"Знакомства, встречи, сходочки", ],
                                     @"vg": @[@"Видеоигры", @"", ],
                                     @"r": @[@"Просьбы", @"", ],
                                     @"cr": @[@"Творчество", @"Доска для контента, созданного доброаноном", ],
                                     @"lor": @[@"LOR", @"Доска о программном обеспечении, железе и прочей IT-утвари", ],
                                     @"mu": @[@"Музыка", @"", ],
                                     @"oe": @[@"Oekaki", @"Доска для набросков, мазни и коллективного рисования", ],
                                     @"s": @[@"Li/s/p", @"(defboard li/s/p (:documentation \"Программирование\"))", ],
                                     @"w": @[@"Обои", @"Красивые обои для рабочего стола", ],
                                     @"hr": @[@"Высокое разрешение", @"Картинки в высоком разрешении", ],
                                     @"mad": @[@"Безумие", @"Экспериментальная доска", ],

                                     } mutableCopy];
    return @{@"sorted_keys": sortedNames, @"data": boards};
}

- (NSArray<NSString *> *) ratingsList {
    return @[@"sfw", @"rated", @"r-15", @"r-18", @"r-18g"];
}

- (NSURL *) urlFor:(NSString *)relative {
    NSString *fullUrl = [@"http://dobrochan.com/" stringByAppendingString:relative];

    NSURL *url = [NSURL URLWithString:[fullUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    return url;
}

# pragma mark making requests

- (void) requestThreadsFrom:(NSString *) board
                       page:(NSNumber *) page
              stateCallback: (BoardAPIProgressCallback) callback {
    NSURL *url = [self urlFor:[NSString stringWithFormat:@"%@/%@.json", board, page]];
    [self requestURL:url
            delegate:[[BoardRequestParser alloc] initWithDelegate:self]
    progressCallback:callback];
}

- (void) requestThread:(NSNumber *) threadId
                  from:(NSString *) board
         stateCallback: (BoardAPIProgressCallback) callback {
    NSURL *url = [self urlFor:[NSString stringWithFormat:@"%@/res/%@.json", board, threadId]];

    [self requestURL:url
            delegate:[[BoardRequestParser alloc] initWithDelegate:self]
    progressCallback:callback];
}

- (void) requestNewPostsFrom:(NSNumber *)thread
                          at:(NSString *)board
                       after:(NSNumber *)postId
               stateCallback:(BoardAPIProgressCallback)callback {
    NSURL *url = [self urlFor:[NSString stringWithFormat:@"api/thread/new/%@/%@.json?last_post=%@", board, thread, postId]];

    NSLog(@"%@", url);
    [self requestURL:url
            delegate:[[BoardRequestParser alloc] initWithDelegate:self form:BoardRequestParserPostsForm]
    progressCallback:callback];
}

- (void) requestPost:(NSNumber *)postId
                from:(NSNumber *)threadId
                  at:(NSString *)board
       stateCallback:(BoardAPIProgressCallback)callback {
    NSURL *url = [self urlFor:[NSString stringWithFormat:@"api/post/ref/%@/%@/%@.json", board, threadId, postId]];

    [self requestURL:url
            delegate:[[BoardRequestParser alloc] initWithDelegate:self form:BoardRequestParserPostForm]
    progressCallback:callback];
}

- (NSURLSessionDataTask *) requestImage:(NSString *)path
                          stateCallback:(BoardAPIProgressCallback)stateCallback
                         finishCallback:(BoardImageDownloadFinishCallback)finishCallback {
    NSURL *url = [self urlFor:path];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDataTask *task = [self.imageLoadingSession
                                  dataTaskWithRequest:request
                                  completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
                                      UIImage *image = [UIImage imageWithData:data];
                                      if (image) {
                                          dispatch_sync(dispatch_get_main_queue(), ^{
                                              finishCallback(image);
                                          });
                                      }
                                  }];

    [self.progressCallbacks setObject:stateCallback forKey:task];
    [task addObserver:self forKeyPath:@"countOfBytesReceived" options:NSKeyValueObservingOptionNew context:nil];
    [task resume];
    return task;
}

# pragma mark request managing

- (void) cancelRequest:(NSURLSessionTask *)task {
    if (task) {
        [task removeObserver:self forKeyPath:@"countOfBytesReceived"];
        [self.progressCallbacks removeObjectForKey:task];
        [task cancel];
    }
}

- (void) cancelRequest {
    if (self.currentTask) {
        [self.currentTask removeObserver:self forKeyPath:@"countOfBytesReceived"];
        [self.currentTask cancel];
        [self.progressCallbacks removeObjectForKey:self.currentTask];

        self.currentTask = nil;
    }
}

- (BOOL) isRequesting {
    if (self.currentTask) {
        return
        self.currentTask.state == NSURLSessionTaskStateRunning
        ||
        self.currentTask.state == NSURLSessionTaskStateCanceling;
    } else {
        return NO;
    }
}

#pragma mark thread helpers

- (void) didParsedThread:(NSDictionary *)thread {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.delegate didReceivedThread:thread];
    });
}

- (void) didParsedPost:(NSDictionary *)post {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.delegate didReceivedPost:post];
    });
}

- (void) didFinishedParsing {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.delegate didFinishedReceiving];
    });
}

#pragma mark private helper methods

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context {
    if ([keyPath isEqualToString:@"countOfBytesReceived"]) {
        BoardAPIProgressCallback cb = [self.progressCallbacks objectForKey:object];
        NSURLSessionTask *task = (NSURLSessionTask *) object;

        if (cb)
            dispatch_sync(dispatch_get_main_queue(), ^{
                cb(task.countOfBytesReceived, task.countOfBytesExpectedToReceive);
            });
    }
}

- (NSURLSessionTask *) requestURL:(NSURL *) url
                         delegate:(id<NSURLSessionDataDelegate>) ddelegate
                 progressCallback:(BoardAPIProgressCallback) callback {
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:ddelegate
                                                     delegateQueue:nil];

    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:NSTimeIntervalSince1970];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];

    self.currentTask = task;
    if (callback) {
        [self.progressCallbacks setObject:callback forKey:task];
    }

    [task addObserver:self forKeyPath:@"countOfBytesReceived" options:NSKeyValueObservingOptionNew context:nil];
    [task resume];

    return task;
}


@end
