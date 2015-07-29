//
//  AttachmentsTableDelegate.m
//  dobrochannel
//
//  Created by shdwprince on 7/26/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "AttachmentsTableDelegate.h"

@implementation AttachmentsTableDelegate

- (UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cellx"];
    CGFloat statusLabelFontSize = 7.f;
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cellx"];

        UIImageView *iv = [[UIImageView alloc] init];
        iv.tag = 111;
        [cell addSubview:iv];

        UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        aiv.tag = 112;
        [cell addSubview:aiv];

        UILabel *sl = [[UILabel alloc] init];
        sl.font = [UIFont systemFontOfSize:statusLabelFontSize];
        sl.tag = 113;
        [cell addSubview:sl];
    }
    NSManagedObject *attachment = self.objects[indexPath.row];

    UIImageView *iv = (UIImageView *) [cell viewWithTag:111];
    UIActivityIndicatorView *aiv = (UIActivityIndicatorView *) [cell viewWithTag:112];
    UILabel *sl = (UILabel *) [cell viewWithTag:113];


    sl.frame = CGRectMake(0,
                          0,
                          self.parentSize.width,
                          [[UIFont systemFontOfSize:statusLabelFontSize] lineHeight]);
    iv.frame = CGRectMake(0,
                          sl.frame.size.height + 1.f,
                          self.parentSize.width,
                          [self attachmentHeight:attachment] - sl.frame.size.height + 1.f);
    aiv.frame = CGRectMake(0,
                           0,
                           self.parentSize.width,
                           [self attachmentHeight:attachment]);

    //@TODO: move view code somewhere

    NSString *type = [attachment valueForKey:@"type"];
    NSNumber *weight = [attachment valueForKey:@"weight"];

    if ([type isEqualToString:@"image"]) {
        CGSize size = ((NSValue *) [attachment valueForKey:@"size"]).CGSizeValue;

        sl.text = [NSString stringWithFormat:@"%@, %dx%d",
                   [NSByteCountFormatter stringFromByteCount:weight.longLongValue countStyle:NSByteCountFormatterCountStyleFile],
                   (int) size.width,
                   (int) size.height];
    } else {
        sl.text = [NSString stringWithFormat:@"%@, %@",
                   [NSByteCountFormatter stringFromByteCount:weight.longLongValue countStyle:NSByteCountFormatterCountStyleFile],
                   type];
    }

    iv.image = nil;
    aiv.hidden = NO;
    if ([UserDefaults contentReaderLoadThumbnails])
        [aiv startAnimating];

    NSString *src = [attachment valueForKey:@"thumb_src"];

    BOOL weight_lesser_limit = weight.integerValue <= [UserDefaults contentReaderLoadFullMaxSize] * 1024;
    BOOL is_image = [type isEqualToString:@"image"];
    if (is_image && weight_lesser_limit && [UserDefaults contentReaderLoadFull]) {
        src = [attachment valueForKey:@"src"];
    }

    if ([UserDefaults contentReaderLoadThumbnails])
        [[BoardAPI api] requestImage:src
                       stateCallback:^(long long processed, long long total) {

                       } finishCallback:^(UIImage *i) {
                           iv.image = i;
                           [aiv stopAnimating];
                           aiv.hidden = YES;
                       }];


    return cell;
}

- (CGFloat) tableView:(nonnull UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [self attachmentHeight:self.objects[indexPath.row]] + 2.f;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger) section {
    return [self.objects count];
}

- (CGFloat) calculatedWidth {
    CGFloat max_height = 0.f;
    CGFloat margin = [self.objects count] > 1 ? 15.f : 2.f; // 2.f is spacing in tableView:heightForRowAtIndexPath:

    for (NSManagedObject *attachment in self.objects) {
        CGFloat height = [self attachmentHeight:attachment];
        if (max_height < height)
            max_height = height;
    }

    return max_height + margin;
}

- (CGFloat) attachmentHeight:(NSManagedObject *) attachment {
    CGSize size = ((NSValue *) [attachment valueForKey:@"thumb_size"]).CGSizeValue;
    CGFloat ratio = self.parentSize.width / size.width;

    return size.height * ratio;
}

- (void) tableView:(nonnull UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    [self.target performSelector:self.action
                      withObject:[self.objects arrayByAddingObject:[NSNumber numberWithInteger:indexPath.row]]];
}

@end
