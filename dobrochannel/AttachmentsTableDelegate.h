//
//  AttachmentsTableDelegate.h
//  dobrochannel
//
//  Created by shdwprince on 7/26/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

#import "UserDefaults.h"
#import "BoardAPI.h"

@interface AttachmentsTableDelegate : NSObject <UITableViewDataSource, UITableViewDelegate>
@property NSArray *objects;
@property CGSize parentSize;
@property id target;
@property SEL action;

- (CGFloat) calculatedWidth;

@end
