//
//  ThreadHiderViewController.h
//  dobrochannel
//
//  Created by shdwprince on 12/11/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface ThreadHiderViewController : UIViewController

+ (void) resetThreadHiderStatistics;
+ (NSUInteger) totalHidedObjects;
+ (BOOL) shouldHideThread:(NSManagedObject *) object;

@end
