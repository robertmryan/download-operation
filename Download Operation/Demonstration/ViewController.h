//
//  ViewController.h
//  Download Operation
//
//  Created by Robert Ryan on 7/31/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

- (IBAction)touchUpInsideCancelButton:(id)sender;

@end
