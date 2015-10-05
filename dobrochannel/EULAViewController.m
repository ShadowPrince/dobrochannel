//
//  EULAViewController.m
//  dobrochannel
//
//  Created by shdwprince on 9/30/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "EULAViewController.h"

@interface EULAViewController ()

@end@implementation EULAViewController

- (IBAction)acceptAction:(id)sender {
    [[NSUserDefaults standardUserDefaults] setInteger:EULA_VERSION forKey:@"eula"];
    [self performSegueWithIdentifier:@"continueSegue" sender:nil];
}

- (IBAction)declineAction:(id)sender {
    exit(0);
}

@end
