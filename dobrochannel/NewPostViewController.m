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
@property (weak, nonatomic) IBOutlet UITextView *previewTextView;
@property (weak, nonatomic) IBOutlet UIImageView *captchaImageView;
@property (weak, nonatomic) IBOutlet UITextField *captchaTextField;
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentsCollectionView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITextView *inReplyToTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inReplyToTextViewHeightConstraint;
@property (strong, nonatomic) IBOutlet UIView *postItBarButton;
@property (weak, nonatomic) IBOutlet UIButton *danbooruButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *postItButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewFixedWidthContraint;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *reportMessageHeightConstraint;
@property (weak, nonatomic) IBOutlet UIButton *reportMessageButton;
@property (weak, nonatomic) IBOutlet UIView *captchaView;

@property UIAlertController *loadingAlertController;
@property BoardMarkupParser *parser;
@property NSOperationQueue *parserQueue;
@property NSURLSessionTask *captchaTask;
@property NSMutableArray *attachedImages, *attachedRatings;
@end @implementation NewPostViewController
@synthesize board, thread_identifier;

- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *captchaViewEmbed = [[NSBundle mainBundle] loadNibNamed:@"CaptchaView" owner:self options:nil][0];
    captchaViewEmbed.frame = CGRectMake(0, 0, self.captchaView.frame.size.width, self.captchaView.frame.size.height);
    [self.captchaView addSubview:captchaViewEmbed];

    self.captchaImageView = [captchaViewEmbed viewWithTag:100];
    self.captchaTextField = [captchaViewEmbed viewWithTag:101];

    self.attachedImages = [NSMutableArray new];
    self.attachedRatings = [NSMutableArray new];
    if (self.messagePlaceholder) {
        self.messageTextView.text = self.messagePlaceholder;
    } else {
        self.messageTextView.text = @"";
    }
    self.previewTextView.text = @"";
    self.parser = [BoardMarkupParser defaultParser];
    self.parserQueue = [NSOperationQueue new];

    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"secret"]) {
        self.danbooruButton.hidden = NO;
    }

    if (![UserDefaults showReportButton]) {
        self.reportMessageButton.hidden = YES;
        self.reportMessageHeightConstraint.constant = 0.f;
    }

    [self loadInReplyTo];
    [self loadCaptcha];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void) viewDidLayoutSubviews {
    self.textViewWidthConstraint.active = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;
    self.textViewFixedWidthContraint.constant = self.view.frame.size.width / 2;
    [super viewDidLayoutSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) loadInReplyTo {
    self.title = [NSString stringWithFormat:@"Reply into %@/%@", self.board, self.thread_identifier];

    if (self.inReplyToIdentifier) {
        self.inReplyToTextView.attributedText = self.inReplyToMessage;
        if ([self.messageTextView.text isEqualToString:@""])
            self.messageTextView.text = [NSString stringWithFormat:@">>%@\n", self.inReplyToIdentifier];
        self.inReplyToTextViewHeightConstraint.constant = 169.f;
    } else {
        self.reportMessageButton.hidden = YES;
        self.inReplyToTextViewHeightConstraint.constant = 0.f;
    }
}

- (void) loadCaptcha {
    [[BoardAPI api] requestCaptchaAt:self.board
                      finishCallback:^(UIImage *image) {
                          self.captchaImageView.image = image;
                      }];

    [[BoardAPI api] requestSessionInfoWithFinishCallback:^(NSDictionary *info) {
        NSLog(@"User info: %@", info);
        for (NSDictionary *token in info[@"tokens"]) {
            if ([token[@"token"] isEqualToString:@"no_user_captcha"]) {
                self.captchaTextField.text = @"no need";
                self.captchaTextField.enabled = NO;
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

- (IBAction)deletePostAction:(id)sender {
    UIViewController *progressbarEmbedController = [self.storyboard instantiateViewControllerWithIdentifier:@"activityEmbed"];
    RMUniversalAlert *alert = [RMUniversalAlert showAlertInViewController:self
                                                                withTitle:@"Deleting post..."
                                                                  message:nil
                                                        cancelButtonTitle:nil
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:nil
                                                                 tapBlock:nil];
    [alert presentViewController:progressbarEmbedController];

    [[BoardAPI api] deletePost:self.inReplyToIdentifier
                    fromThread:self.thread_internal_identifier
                         board:self.board
                finishCallback:^(NSArray *errors) {
                    [alert.alertController dismissViewControllerAnimated:YES completion:nil];

                    if (!errors) {
                        [self performSegueWithIdentifier:@"unwindFromNewPost" sender:nil];
                    } else {
                        if (!errors.count) {
                            [self displayErrors:@[@"Unknown error"]];
                        } else {
                            [self displayErrors:errors];
                        }
                    }
                }];
}

- (IBAction)postItAction:(id)sender {
    UIViewController *progressbarEmbedController = [self.storyboard instantiateViewControllerWithIdentifier:@"progressbarEmbed"];
    RMUniversalAlert *alert = [RMUniversalAlert showAlertInViewController:self
                                                                withTitle:@"Submitting post..."
                                                                  message:nil
                                                        cancelButtonTitle:nil
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:nil
                                                                 tapBlock:nil];
    [alert presentViewController:progressbarEmbedController];

    NSMutableArray *files = [NSMutableArray new];
    for (int i = 0; i < self.attachedImages.count; i++) {
        [files addObject:@{@"image": self.attachedImages[i][UIImagePickerControllerOriginalImage],
                           @"rating": self.attachedRatings[i], }];
    }

    [[BoardAPI api] postInto:self.thread_identifier
                          at:self.board
                        data:@{@"message": self.messageTextView.text,
                               @"captcha": self.captchaTextField.text,
                               @"password": [UserDefaults postPassword],
                               @"files": files, }
            progressCallback:^(long long completed, long long total) {
                UIProgressView *progress = [progressbarEmbedController.view viewWithTag:100];
                progress.progress = (float) completed / total;

            } finishCallback:^(NSArray *errors) {
                  [alert.alertController dismissViewControllerAnimated:YES completion:nil];

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
              }];
}

- (IBAction)addAttachmentAction:(id)sender {
    UIImagePickerController *picker = [UIImagePickerController new];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)addDanbooruAttachmentAction:(id)sender {
    DanbooruPickerViewController *c = [[DanbooruPickerViewController alloc] initWithDelegate:self];

    [self presentViewController:c animated:YES completion:nil];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self.attachedImages addObject:info];
    [self.attachedRatings addObject:[[[BoardAPI api] ratingsList] firstObject]];

    [self.attachmentsCollectionView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) danbooruPicker:(DanbooruPickerViewController *)controller didPickImageAt:(NSURL *)url {
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *image = [[UIImage alloc] initWithData:data];

    [self.attachedImages addObject:@{UIImagePickerControllerOriginalImage: image, }];
    [self.attachedRatings addObject:@"no rating"];
}

- (void) danbooruPicker:(DanbooruPickerViewController *)controller didFinishPicking:(NSInteger)count {
    [self.attachmentsCollectionView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)tapGestureAction:(id)sender {
    [self.view endEditing:YES];
}

- (void) textViewDidChange:(UITextView *)textView {
    [self.parserQueue addOperationWithBlock:^{
        NSAttributedString *str = [self.parser parse:textView.text];
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.previewTextView.attributedText = str;
        });
    }];
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

    [[[BoardAPI api] ratingsList] enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * stop) {
        [c addAction:[UIAlertAction actionWithTitle:obj
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
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
    [coder encodeObject:self.board forKey:@"board"];
}

- (void) decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];

    self.messageTextView.text = [coder decodeObjectForKey:@"messageTextView.text"];
    self.previewTextView.attributedText = [self.parser parse:self.messageTextView.text];
    self.board = [coder decodeObjectForKey:@"board"];
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
    if ([segue.identifier isEqualToString:@"reportSegue"]) {
        NewPostViewController *controller = segue.destinationViewController;
        controller.board = @"mad";
        controller.thread_identifier = @68963;
        controller.messagePlaceholder = [NSString stringWithFormat:@"Reporting >>%@/%@:\n\n", self.board, self.inReplyToIdentifier];
    }

    [super prepareForSegue:segue sender:sender];
}

@end