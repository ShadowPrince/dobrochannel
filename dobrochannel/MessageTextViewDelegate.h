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
@property NSManagedObject *contextObject;

- (instancetype) initWithTarget:(id) target
                         action:(nullable SEL)action;

@end