//
//  NewPostViewController.m
//  dobrochannel
//
//  Created by shdwprince on 8/9/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "NewPostViewController.h"

@interface NewPostViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UIImageView *captchaImageView;
@property (weak, nonatomic) IBOutlet UITextField *captchaTextField;
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentsCollectionView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITextView *inReplyToTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inReplyToTextViewHeightConstraint;
@property (strong, nonatomic) IBOutlet UIView *postItBarButton;

@property NSURLSessionTask *captchaTask;
@property NSMutableArray *attachedImages, *attachedRatings;
@end @implementation NewPostViewController
@synthesize board, thread_identifier;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.attachedImages = [NSMutableArray new];
    self.attachedRatings = [NSMutableArray new];
    self.messageTextView.text = @"";

    [self loadInReplyTo];
    [self loadCaptcha];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) loadInReplyTo {
    if (self.inReplyToIdentifier) {
        self.inReplyToTextView.attributedText = self.inReplyToMessage;
        if ([self.messageTextView.text isEqualToString:@""])
            self.messageTextView.text = [NSString stringWithFormat:@">>%@\n", self.inReplyToIdentifier];
        self.inReplyToTextViewHeightConstraint.constant = 169.f;
    } else {
        self.inReplyToTextViewHeightConstraint.constant = 0.f;
    }
}

- (void) loadCaptcha {
    [[BoardAPI api] requestCaptchaAt:self.board
                      finishCallback:^(UIImage *image) {
                          self.captchaImageView.image = image;
                      }];

    [[BoardAPI api] requestSessionInfoWithFinishCallback:^(NSArray *info) {
        for (NSDictionary *token in info) {
            if ([token[@"token"] isEqualToString:@"no_user_captcha"]) {
                self.captchaTextField.enabled = NO;
                self.captchaTextField.text = @"no need";
            }
        }
    }];
}

- (void) displayErrors:(NSArray *) errors {
    UIAlertController *c = [UIAlertController alertControllerWithTitle:@"Error"
                                                               message:[errors componentsJoinedByString:@"\n"]
                                                        preferredStyle:UIAlertControllerStyleAlert];

    c.popoverPresentationController.sourceRect = self.postItBarButton.frame;
    c.popoverPresentationController.sourceView = self.view;
    [c addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:c animated:YES completion:nil];
}

#pragma mark actions

- (IBAction)postItAction:(id)sender {
    [self.activityIndicator startAnimating];

    NSMutableArray *files = [NSMutableArray new];
    for (int i = 0; i < self.attachedImages.count; i++) {
        [files addObject:@{@"image": self.attachedImages[i][UIImagePickerControllerOriginalImage],
                           @"rating": self.attachedRatings[i], }];
    }

    [[BoardAPI api] postInto:self.thread_identifier
                          at:self.board
                        data:@{
                               @"message": self.messageTextView.text,
                               @"captcha": self.captchaTextField.text,
                               @"password": [UserDefaults postPassword],
                               @"files": files, }
              finishCallback:^(NSArray *errors) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.activityIndicator stopAnimating];

                    if (!errors) {
                        [self performSegueWithIdentifier:@"unwindFromNewPost" sender:nil];
                    } else {
                        [self loadCaptcha];
                        if (!errors.count) {
                            [self displayErrors:@[@"Unknown error"]];
                        } else {
                            [self displayErrors:errors];
                        }
                    }
                });
              }];
}

- (IBAction)addAttachmentAction:(id)sender {
    UIImagePickerController *picker = [UIImagePickerController new];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [self.attachedImages addObject:info];
    [self.attachedRatings addObject:[[[BoardAPI api] ratingsList] firstObject]];

    [self.attachmentsCollectionView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}


# pragma mark attachments view

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    UIImageView *iv = (UIImageView *) [cell viewWithTag:100];
    UILabel *rl = (UILabel *) [cell viewWithTag:101];

    iv.image = self.attachedImages[indexPath.row][UIImagePickerControllerOriginalImage];
    rl.text = self.attachedRatings[indexPath.row];

    return cell;
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.attachedImages.count;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UIAlertController *c = [UIAlertController alertControllerWithTitle:@"Change rating: "
                                                               message:nil
                                                        preferredStyle:UIAlertControllerStyleActionSheet];

    c.popoverPresentationController.sourceRect = collectionView.frame;
    c.popoverPresentationController.sourceView = self.view;

    [[[BoardAPI api] ratingsList] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [c addAction:[UIAlertAction actionWithTitle:obj
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                self.attachedRatings[indexPath.row] = [[BoardAPI api] ratingsList][idx];
                                                [self.attachmentsCollectionView reloadData];
                                            }]];
    }];

    [c addAction:[UIAlertAction actionWithTitle:@"Remove attachment"
                                          style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction * __nonnull action) {
                                            [self.attachedImages removeObjectAtIndex:indexPath.row];
                                            [self.attachedRatings removeObjectAtIndex:indexPath.row];
                                            [self.attachmentsCollectionView reloadData];
                                        }]];

    [c addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                          style:UIAlertActionStyleCancel
                                        handler:nil]];

    [self presentViewController:c animated:YES completion:nil];
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

#pragma mark state restoration

- (void) encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];

    [coder encodeObject:self.messageTextView.text forKey:@"messageTextView.text"];
    [coder encodeObject:self.attachedImages forKey:@"attachedImages"];
    [coder encodeObject:self.attachedRatings forKey:@"attachedRatings"];
    [coder encodeObject:self.inReplyToMessage forKey:@"inReplyToMessage"];
    [coder encodeObject:self.inReplyToIdentifier forKey:@"inReplyToIdentifier"];
    [coder encodeObject:self.thread_identifier forKey:@"thread_identifier"];
}

- (void) decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];

    self.messageTextView.text = [coder decodeObjectForKey:@"messageTextView.text"];
    self.attachedImages = [coder decodeObjectForKey:@"attachedImages"];
    self.attachedRatings = [coder decodeObjectForKey:@"attachedRatings"];
    self.inReplyToMessage = [coder decodeObjectForKey:@"inReplyToMessage"];
    self.inReplyToIdentifier = [coder decodeObjectForKey:@"inReplyToIdentifier"];
    self.thread_identifier = [coder decodeObjectForKey:@"thread_identifier"];

    [self loadInReplyTo];

    [self.attachmentsCollectionView reloadData];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (void) dealloc {
    NSLog(@"DEALLOC");
}

@end
