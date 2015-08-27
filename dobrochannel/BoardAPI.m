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
@property NSMutableDictionary *progressCallbacks;

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
    NSArray *sortedNames = @[@[@"b", @"u", @"rf", @"dt", @"vg", @"r", @"cr", @"lor", @"mu", @"oe", @"s", @"w", @"hr", ],
                             @[@"a", @"ma", @"sw", @"hau", @"azu", ],
                             @[@"tv", @"cp", @"gf", @"bo", @"di", @"vn", @"ve", @"wh", @"fur", @"to", @"bg", @"wn", @"slow", @"mad", ],
                             @[@"d", @"news", ], ];
    NSMutableDictionary *boards = [@{@"b": @[@"Братство", @"Доска обо всем"],
                                     @"u": @[@"Университет", @"Dum docemus, discimus"],
                                     @"rf": @[@"Refuge", @""],
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

                                     @"a": @[@"Аниме", @"", ],
                                     @"ma": @[@"Манга", @"", ],
                                     @"sw": @[@"Spice & Wolf", @"Доска для обсуждения, арта и фанарта по сериалу Волчица и специи", ],
                                     @"hau": @[@"When They Cry", @"Welcome to Rokkenjima", ],
                                     @"azu": @[@"Azumanga Daioh", @"Доска для обсуждения, арта и фанарта по сериалу Адзуманга", ],

                                     @"tv": @[@"Кино", @"", ],
                                     @"cp": @[@"Копипаста", @"Копипаста, макросы и демотивация", ],
                                     @"gf": @[@"Gif/Flash-анимация", @"", ],
                                     @"bo": @[@"Книги", @"", ],
                                     @"di": @[@"Dining room", @"Обсуждение добычи, приготовления и употребления еды", ],
                                     @"vn": @[@"Visual novels", @"", ],
                                     @"ve": @[@"Vehicles", @"", ],
                                     @"wh": @[@"Вархаммер", @"", ],
                                     @"fur": @[@"Фурри", @"", ],
                                     @"bg": @[@"Настольные игры", @"", ],
                                     @"to": @[@"Touhou Project", @"", ],
                                     @"wn": @[@"События в мире", @"Обсуждение политики, событий в мире и интернетах", ],
                                     @"slow": @[@"Слоудоска", @"", ],
                                     @"mad": @[@"Безумие", @"Экспериментальная доска", ],

                                     @"d": @[@"Обсуждение", @"Доска для обсуждения Доброчана", ],
                                     @"news": @[@"Новости", @"Новости Доброчана", ],
                                     } mutableCopy];

    return @{@"sorted_keys": sortedNames, @"data": boards};
}

- (NSArray *) ratingsList {
    return @[@"sfw", @"r-15", @"r-18", @"r-18g"];
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

    return [self requestURL:url
           progressCallback:stateCallback
             finishCallback:^(NSData *data) {
                 UIImage *image = [UIImage imageWithData:data];
                 if (image) {
                     dispatch_sync(dispatch_get_main_queue(), ^{
                         finishCallback(image);
                     });
                 }
             }];
}

- (NSURLSessionTask *) requestCaptchaAt:(NSString *) board
                         finishCallback:(BoardImageDownloadFinishCallback)finishCallback {
    return [self requestImage:[NSString stringWithFormat:@"captcha/%@/%d.png", board, (int) [[NSDate date] timeIntervalSince1970]]
                stateCallback:nil
               finishCallback:finishCallback];
}

- (void) requestSessionInfoWithFinishCallback:(BoardSessionFinishCallback)finishCallback {
    NSURL *url = [self urlFor:@"api/user.json"];

    self.currentTask = [self requestURL:url
                       progressCallback:nil
                         finishCallback:^(NSData *data) {
                             id json = [NSJSONSerialization JSONObjectWithData:data
                                                                       options:0
                                                                         error:nil];
                             dispatch_sync(dispatch_get_main_queue(), ^{
                                 finishCallback([json valueForKey:@"tokens"]);
                                 [self cancelRequest];
                             });
                         }];
}

- (void) postInto:(NSNumber *)threadId
               at:(NSString *)board
             data:(NSDictionary *)_postData
   finishCallback:(BoardPostFinishCallback)callback {
    NSURL *url = [self urlFor:[NSString stringWithFormat:@"%@/post/new.json", board]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";

    // chop files out
    NSArray *files = _postData[@"files"];
    NSMutableDictionary *postData = [_postData mutableCopy];
    [postData removeObjectForKey:@"files"];

    NSMutableDictionary *data = [NSMutableDictionary new];
    [data setValuesForKeysWithDictionary:@{@"task": @"post",
                                           @"scroll_to": @"",
                                           @"goto": @"thread",
                                           @"post_files_count": [NSString stringWithFormat:@"%u", files.count + 1],
                                           @"new_post": @"Отправить",
                                           @"subject": @"",
                                           @"name": @"Анонимус",
                                           @"thread_id": threadId.stringValue,
                                           }];
    [data setValuesForKeysWithDictionary:postData];

    // boundary and headers
    NSString *myboundary = @"------WebKitFormBoundaryf8AVk0gFLWQNUVjP";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",myboundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];

    NSMutableData *HTTPBody = [NSMutableData new];

    // fill HTTPBody with data
    [data enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * stop) {
        [HTTPBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", myboundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [HTTPBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [HTTPBody appendData:[obj dataUsingEncoding:NSUTF8StringEncoding]];
    }];

    // fill HTTPBody with files
    for (int i = 0; i < files.count; i++) {
        NSDictionary *file = files[i];
        NSData *fileData = UIImageJPEGRepresentation(file[@"image"], 0.8f);

        // file data
        [HTTPBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", myboundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [HTTPBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file_%d\"; filename=\"%d.jpg\"\r\n", i+1, i]dataUsingEncoding:NSUTF8StringEncoding]];
        [HTTPBody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [HTTPBody appendData:fileData];
        // file rating
        [HTTPBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", myboundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [HTTPBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",
                               [NSString stringWithFormat:@"file_%d_rating", i+1]] dataUsingEncoding:NSUTF8StringEncoding]];
        [HTTPBody appendData:[file[@"rating"] dataUsingEncoding:NSUTF8StringEncoding]];
    }

    // close boundary
    [HTTPBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", myboundary] dataUsingEncoding:NSUTF8StringEncoding]];
    request.HTTPBody = HTTPBody;

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse * response, NSData * data, NSError * connectionError) {
//                               NSLog(@"%@", response);
//                               NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                               NSURL *successUrl = [self urlFor:[NSString stringWithFormat:@"%@/res/%@.xhtml", board, threadId]];
                               if (![[response URL] isEqual:successUrl]) {
                                   NSArray *errors = [BoardPostResponseParser parseErrorsFromResponseData:data];
                                   callback(errors);
                               } else {
                                   callback(nil);
                               }
                           }];
}

# pragma mark request managing

- (void) cancelRequest:(NSURLSessionTask *)task {
    if (task) {
        if (self.progressCallbacks[task]) {
            [task removeObserver:self forKeyPath:@"countOfBytesReceived"];
            [self.progressCallbacks removeObjectForKey:task];
        }
        [task cancel];
    }
}

- (void) cancelRequest {
    [self cancelRequest:self.currentTask];
    self.currentTask = nil;
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
    [self.delegate didReceivedThread:thread];
}

- (void) didParsedPost:(NSDictionary *)post {
    [self.delegate didReceivedPost:post];
}

- (void) didFinishedParsing {
    [self.delegate didFinishedReceiving];
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

- (NSURLSessionDataTask *) requestURL:(NSURL *) url
                 progressCallback:(BoardAPIProgressCallback) stateCallback
                   finishCallback:(BoardAPIFinishCallback) finishCallback {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDataTask *task = [self.imageLoadingSession
                                  dataTaskWithRequest:request
                                  completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
                                      finishCallback(data);
                                  }];

    if (stateCallback) {
        [self.progressCallbacks setObject:stateCallback forKey:task];
        [task addObserver:self forKeyPath:@"countOfBytesReceived" options:NSKeyValueObservingOptionNew context:nil];
    }

    [task resume];
    return task;
}

- (NSURLSessionTask *) requestURL:(NSURL *) url
                         delegate:(id<NSURLSessionDataDelegate>) ddelegate
                 progressCallback:(BoardAPIProgressCallback) callback {
    NSLog(@"%@", url);
//    url = [NSURL URLWithString:@"http://localhost/0.json"];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:ddelegate
                                                     delegateQueue:nil];

    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:NSTimeIntervalSince1970];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];

    self.currentTask = task;
    if (callback) {
        [self.progressCallbacks setObject:callback forKey:task];
        [task addObserver:self forKeyPath:@"countOfBytesReceived" options:NSKeyValueObservingOptionNew context:nil];
    }

    [task resume];
    return task;
}


@end