//
//  ViewController.m
//  Download Operation
//
//  Created by Robert Ryan on 7/31/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import "ViewController.h"
#import "DownloadOperation.h"
#import "DownloadCell.h"

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *downloads;
@property (nonatomic, strong) NSOperationQueue *downloadQueue;

@end

@implementation ViewController

#warning You will want to replace filenames and URL below

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.downloadQueue = [[NSOperationQueue alloc] init];
    self.downloadQueue.maxConcurrentOperationCount = 4;

    self.downloads = [NSMutableArray array];

    NSArray *filenames = @[@"as17-134-20380.jpg", @"as17-140-21497.jpg", @"as17-148-22727.jpg"];
    
    for (NSString *filename in filenames)  {
        NSString *urlString = [@"http://spaceflight.nasa.gov/gallery/images/apollo/apollo17/hires" stringByAppendingPathComponent:filename];
        NSURL *url = [NSURL URLWithString:urlString];
        
        DownloadOperation *downloadOperation = [[DownloadOperation alloc] initWithURL:url];

        // create downloadCompletionBlock that removes row from table

        downloadOperation.downloadCompletionBlock = ^(DownloadOperation *operation, BOOL success, NSError *error) {
            if (error) {
                NSLog(@"%s: downloadCompletionBlock error: %@", __FUNCTION__, error);
            }
            NSInteger row = [self.downloads indexOfObject:operation];
            if (row == NSNotFound) return;
            [self.downloads removeObjectAtIndex:row];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationMiddle];
        };

        // create progress block that updates progress view in cell (if its visible)
        
        downloadOperation.downloadProgressBlock = ^(DownloadOperation *operation, long long progressContentLength, long long expectedContentLength) {
            NSInteger row = [self.downloads indexOfObject:operation];
            if (row == NSNotFound) return;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            DownloadCell *cell = (id)[self.tableView cellForRowAtIndexPath:indexPath];
            if (cell) {
                CGFloat progress = (expectedContentLength > 0 ? (CGFloat) progressContentLength / (CGFloat) expectedContentLength : (progressContentLength % 1000000l) / 1000000.0f);
                [cell.downloadProgressView setProgress:progress animated:YES];
            }
        };
        [self.downloads addObject:downloadOperation];
        [self.downloadQueue addOperation:downloadOperation];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.downloads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    DownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    DownloadOperation *operation = self.downloads[indexPath.row];
    cell.downloadCellLabel.text = [operation.url lastPathComponent];
    CGFloat progress = (operation.expectedContentLength > 0 ? operation.progressContentLength / operation.expectedContentLength : (operation.progressContentLength % 1000000l) / 1000000.0f);
    [cell.downloadProgressView setProgress:progress];

    return cell;
}

#pragma mark - Buttons

- (IBAction)touchUpInsideCancelButton:(id)sender {
    [self.downloadQueue cancelAllOperations];
    [self.downloads removeAllObjects];
    [self.tableView reloadData];
}
@end
