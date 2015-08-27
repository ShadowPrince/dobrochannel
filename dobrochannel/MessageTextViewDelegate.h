//
//  PostTextView.h
//  dobrochannel
//
//  Created by shdwprince on 7/30/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "BoardMarkupParser.h"

@interface MessageTextViewDelegate : NSObject <UITextViewDelegate>
@property NSManagedObject* __nullable contextObject;

- (instancetype) initWithTarget:(nonnull id) target
                         action:(nonnull SEL)action;

- (void) fireActionWith:(NSString *) identifier contextObject:(NSManagedObject *) context;

@end