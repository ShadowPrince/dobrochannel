//
//  DanbooruPickerViewController.h
//  dobrochannel
//
//  Created by shdwprince on 8/12/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DanbooruAPI.h"

#import "ImageCollectionViewCell.h"
#import "SearchSuggestionTableViewCell.h"

@class DanbooruPickerViewController;

@protocol DanbooruPickerDelegate <NSObject>
- (void) danbooruPicker:(DanbooruPickerViewController *) controller didPickImageAt:(NSURL *) url;
- (void) danbooruPicker:(DanbooruPickerViewController *)controller didFinishPicking:(NSInteger) count;

@end

@interface DanbooruPickerViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, DanbooruAPIDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

- (instancetype) initWithDelegate:(NSObject<DanbooruPickerDelegate> *) delegate;
@end