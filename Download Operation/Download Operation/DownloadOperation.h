//
//  DownloadOperation.h
//  Movie Downloader
//
//  Created by Robert Ryan on 7/30/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Download Operation

 This is a operation, subclassed from `NSOperation`, performs a download of a file (done atomically) that can be added to a `NSOperationQueue`.

 ##Usage

1. Copy the `DownloadOperation.h` and `DownloadOperation.m` to your project and include the header file in your .m file:
 
        #import "DownloadOperation.h"

2. Create a `NSOperationQueue` for the download operation:

        self.downloadQueue = [[NSOperationQueue alloc] init];
 
3. Give that operation queue some reasonable maximum operation count (enjoy concurrency, but staying clear of the maximum number of network operations that iOS supports:

        self.downloadQueue.maxConcurrentOperationCount = 4;
 
4. Create a download operation:
 
        DownloadOperation *downloadOperation = [[DownloadOperation alloc] initWithURL:url];

5. Optionally, provide that operation block completion and progress blocks:

        downloadOperation.downloadCompletionBlock = ^(DownloadOperation *operation, BOOL success, NSError *error) {
            if (error) {
                NSLog(@"%s: downloadCompletionBlock error: %@", __FUNCTION__, error);
            }
            // do whatever else you want upon completion
        };

        downloadOperation.downloadProgressBlock = ^(DownloadOperation *operation, long long progressContentLength, long long expectedContentLength) {
            CGFloat progress = (expectedContentLength > 0 ? (CGFloat) progressContentLength / (CGFloat) expectedContentLength : (progressContentLength % 1000000l) / 1000000.0f);
            [cell.downloadProgressView setProgress:progress animated:YES];
        }

6. Add the operation to your operation queue to start the operation.

        [self.downloadQueue addOperation:downloadOperation];
 
7. If you need to stop an operation, you can either cancel the individual operation:

        [downloadOperation cancel];
 
    Or you can stop all of the download operations:
 
        [self.downloadQueue addOperation:downloadOperation];


 @note This operates atomically, downloading the file to a temporary file, and then moving the file to the final destination.

 @warning This will replace the file at the destination path.
 */

@interface DownloadOperation : NSOperation

/// @name Block typedefs

/// Download completion block typedef

typedef void (^DownloadCompletionBlock)(DownloadOperation *operation, BOOL success, NSError *error);

/// Download progress block typedef

typedef void (^DownloadProgressBlock)(DownloadOperation *operation, long long progressContentLength, long long expectedContentLength);


/// @name Initialization methods

/** Initialize `Download` operation, downloading from `url`, saving the file to `path`.
 *
 * The operation starts when this operation is added to an operation queue.
 *
 * @param url The remote URL of the file being downloaded.
 *
 * @param path The local filename of the file being downloaded. This should be the full path of the file (both the path and filename) and should be in a directory that the user has permission.
 *
 * If this `nil`, the filename will be taken from the `lastPathComponent` of the URL, and will be stored in the `Documents` folder.
 *
 * @return Download operation
 *
 * @see initWithURL:
 */

- (id)initWithURL:(NSURL *)url path:(NSString *)path;

/** Initialize `Download` operation, downloading from `url`, saving the file to documents folder, using the URL's `lastPathComponent` as the filename.
 *
 * The operation starts when this operation is added to an operation queue.
 *
 * @param url The remote URL of the file being downloaded.
 *
 * @return Download operation
 *
 * @see initWithURL:path:
 */

- (id)initWithURL:(NSURL *)url;

/// @name Properties

/** The remote URL of the file being downloaded. 
 *
 * Generally not set manually, but rather by call to `initWithURL:path:` or `initWithURL:`.
 *
 * @see initWithURL:path:
 * @see initWithURL:
 */

@property (nonatomic, strong) NSURL *url;

/** The local path of the file being downloaded.
 *
 * Generally not set manually, but rather by call to `initWithURL:path:`.
 *
 * @see initWithURL:path:
 */

@property (nonatomic, copy)   NSString *path;

/// Download completion block

@property (nonatomic, copy) DownloadCompletionBlock downloadCompletionBlock;

/// Download progress block

@property (nonatomic, copy) DownloadProgressBlock downloadProgressBlock;

/** Expected content length as reported by server
 *
 * Please note that this is not reliable (most HTTP servers report it, some don't, and in some rare cases, a server might not report an accurate number. This is used for estimation purposes only. Actual completion is determined by the operation's completion, not by reaching the prescribed number of bytes.
 */
@property long long expectedContentLength;

/** Progress content length as determined by bytes received.
 *
 * This is how many bytes received thus far. 
 */
@property long long progressContentLength;

@end
