//
//  SettingsViewController.m
//  dobrochannel
//
//  Created by shdwprince on 7/29/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()
@property NSArray<NSString *> *ratings;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPickerView *ratingsPicker;
@property (weak, nonatomic) IBOutlet UISwitch *noRatingSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *loadThumbsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *loadFullSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *loadContentFullSwitch;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UISlider *loadContentFullMaxSlider;
@property (weak, nonatomic) IBOutlet UILabel *loadContentFullMaxLabel;
@property NSUInteger switches;
@end @implementation SettingsViewController

- (void) awakeFromNib {
    self.switches = 0;

    self.ratings = [[BoardAPI api] ratingsList];
    NSString *secret = [[NSUserDefaults standardUserDefaults] valueForKey:@"secret"];
    if (!secret)
        self.ratings = [self.ratings subarrayWithRange:NSMakeRange(0, 2)];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    [self.ratingsPicker reloadAllComponents];

    [self.ratingsPicker selectRow:[UserDefaults maxRating] inComponent:0 animated:YES];
    [self.noRatingSwitch setOn:[UserDefaults showUnrated]];
    [self.loadThumbsSwitch setOn:[UserDefaults contentReaderLoadThumbnails]];
    [self.loadFullSwitch setOn:[UserDefaults attachmentsViewerLoadFull]];
    [self.loadContentFullSwitch setOn:[UserDefaults contentReaderLoadFull]];

    NSInteger maxSize = [UserDefaults contentReaderLoadFullMaxSize];
    self.loadContentFullMaxLabel.text = self.loadContentFullMaxLabel.text = [NSString stringWithFormat:@"%dkb", maxSize];
    self.loadContentFullMaxSlider.value = (CGFloat) maxSize / 3000;

    self.passwordField.text = [UserDefaults postPassword];
}

- (IBAction)noRatingSwitch:(UISwitch *)sender {
    self.switches++;

    if (self.switches >= 18) {
        [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"secret"];
    }

    NSNumber *value = [NSNumber numberWithBool:sender.on];

    [[NSUserDefaults standardUserDefaults] setValue:value forKey:@"show_no_rating"];
}

- (IBAction)loadThumbsSwitch:(UISwitch *)sender {
    NSNumber *value = [NSNumber numberWithBool:sender.on];

    [[NSUserDefaults standardUserDefaults] setValue:value forKey:@"cr_load_thumbs"];
}

- (IBAction)loadFullSwitch:(UISwitch *)sender {
    NSNumber *value = [NSNumber numberWithBool:sender.on];
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:@"av_load_full"];
}

- (IBAction)loadContentFullSwitch:(UISwitch *)sender {
    NSNumber *value = [NSNumber numberWithBool:sender.on];
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:@"cr_load_full"];
}

- (IBAction)loadContentFullMaxSizeSlider:(UISlider *)sender {
    NSInteger value = (NSInteger) floor(3000 * sender.value);
    self.loadContentFullMaxLabel.text = [NSString stringWithFormat:@"%dkb", value];
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:value] forKey:@"cr_load_full_max_size"];
}

- (IBAction)passwordValueChange:(id)sender {
    NSLog(@"chaned");
    [[NSUserDefaults standardUserDefaults] setValue:self.passwordField.text forKey:@"post_password"];
}

#pragma mark keyboard

- (void)keyboardWasShown:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

# pragma mark ratings picker

- (NSInteger) pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.ratings count];
}

- (NSInteger) numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView {
    return 1;
}

- (NSString *) pickerView:(nonnull UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.ratings[row];
}

- (void) pickerView:(nonnull UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:row] forKey:@"max_rating"];
}

@end
