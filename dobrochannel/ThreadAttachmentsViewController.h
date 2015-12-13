//
//  ThreadAttachmentsViewController.h
//  dobrochannel
//
//  Created by shdwprince on 12/13/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "ShowAttachmentsViewController.h"
#import "BoardAPI.h"
#import "RFQuiltLayout.h"

@interface ThreadAttachmentsViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, RFQuiltLayoutDelegate>

@property NSArray<NSManagedObject *> *attachments;

@end
