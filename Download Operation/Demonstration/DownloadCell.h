//
//  DownloadCell.h
//  Download Operation
//
//  Created by Robert Ryan on 7/31/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DownloadCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *downloadCellLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressView;

@end
