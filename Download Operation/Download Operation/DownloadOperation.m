//
//  DownloadOperation.m
//  Movie Downloader
//
//  Created by Robert Ryan on 7/30/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import "DownloadOperation.h"

@interface DownloadOperation () <NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@property (nonatomic, readwrite, getter = isExecuting) BOOL executing;
@property (nonatomic, readwrite, getter = isFinished)  BOOL finished;

@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, weak)   NSURLConnection *connection;
@property (nonatomic, strong) NSString *tempPath;
@property (nonatomic, strong) NSError *error;

@end

@implementation DownloadOperation

@synthesize executing = _executing;
@synthesize finished  = _finished;

- (id)initWithURL:(NSURL *)url path:(NSString *)path {
    self = [super init];
    if (self) {
        _url = url;
        _path = [path copy];

        _executing = NO;
        _finished = NO;

        _expectedContentLength = 0;
        _progressContentLength = 0;
    }
    return self;
}

- (id)initWithURL:(NSURL *)url {
    return [self initWithURL:url path:nil];
}

#pragma mark - NSOperation methods

- (void)start {
    if ([self isCancelled]) {
        self.finished = YES;
        return;
    }

    if (!self.path) {
        NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        self.path = [docsPath stringByAppendingPathComponent:[self.url lastPathComponent]];
    }

    self.tempPath = [self pathForTemporaryFileWithPrefix:@"download"];

    self.executing = YES;

    [self performSelector:@selector(startInNetworkThread) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO];
}

- (void)startInNetworkThread {
    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [connection start];
    self.connection = connection;
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)setExecuting:(BOOL)executing {
    if (executing != _executing) {
        [self willChangeValueForKey:@"isExecuting"];
        _executing = executing;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)setFinished:(BOOL)finished {
    if (finished != _finished) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = finished;
        [self didChangeValueForKey:@"isFinished"];
    }
}

#pragma mark - Download thread methods

+ (void)networkRequestThreadEntryPoint:(id __unused)object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"com.robertmryan.networkthread"];

        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread *)networkRequestThread {
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });

    return _networkRequestThread;
}

#pragma mark - Private methods

- (NSString *)pathForTemporaryFileWithPrefix:(NSString *)prefix {
    NSString *uuidString = [[NSUUID UUID] UUIDString];
    return [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@", prefix, uuidString]];
}

- (BOOL)createFolderForPath:(NSString *)filePath
{
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folder = [filePath stringByDeletingLastPathComponent];
    BOOL isDirectory;

    if (![fileManager fileExistsAtPath:folder isDirectory:&isDirectory]) {
        // if folder doesn't exist, try to create it

        [fileManager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:&error];

        // if fail, report error

        if (error) {
            self.error = error;

            return FALSE;
        }

        // directory successfully created

        return TRUE;
    } else if (!isDirectory) {
        self.error = [NSError errorWithDomain:[NSBundle mainBundle].bundleIdentifier
                                         code:-1
                                     userInfo:@{
                      @"message"  : @"Unable to create directory; file exists by that name",
                      @"function" : @(__FUNCTION__),
                      @"folder"   : folder
                      }];

        return FALSE;
    }

    // directory already existed

    return TRUE;
}

- (BOOL)completeWithSuccess:(BOOL)success
{
    // clean up connection and download steam

    if (!success)
        [self.connection cancel];
    self.connection = nil;

    [self.outputStream close];
    self.outputStream = nil;

    // if download successful, let's save the result, otherwise just get rid of temporary file

    if (success)
        success = [self saveDownloadedFile];
    else
        success = [self removeTemporaryFile];

    // if caller wanted to know about success or failure, then inform it

    if (self.downloadCompletionBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.downloadCompletionBlock(self, success, self.error);
        });
    }

    // finish this operation

    self.executing = NO;
    self.finished = YES;

    return success;
}

- (BOOL)removeTemporaryFile
{
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (self.tempPath) {
        if ([fileManager fileExistsAtPath:self.tempPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.tempPath error:&error];
            if (error)  {
                self.error = error;

                return NO;
            }
        }
    }

    return YES;
}

- (BOOL)saveDownloadedFile {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;

    if (![self createFolderForPath:self.path]) {
        return NO;
    }

    if ([fileManager fileExistsAtPath:self.path]) {
        [fileManager removeItemAtPath:self.path error:&error];
        if (error) {
            self.error = error;

            return NO;
        }
    }

    [fileManager moveItemAtPath:self.tempPath toPath:self.path error:&error];
    if (error) {
        self.error = error;
        
        return NO;
    }
    
    return YES;
}

#pragma mark - NSURLConnectionDataDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([self isCancelled]) {
        [self completeWithSuccess:NO];
        return;
    }

    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (id)response;

        NSInteger statusCode = [httpResponse statusCode];

        if (statusCode == 200) {
            self.expectedContentLength = [response expectedContentLength];
        } else if (statusCode >= 400) {
            self.error = [NSError errorWithDomain:[NSBundle mainBundle].bundleIdentifier
                                             code:statusCode
                                         userInfo:@{
                                                      @"message" : @"bad HTTP response status code",
                                                      @"function": @(__FUNCTION__),
                                                      @"NSHTTPURLResponse" : response
                                                  }];

            [self completeWithSuccess:NO];

            return;
        }
    } else {
        self.expectedContentLength = -1;
    }

    self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.tempPath append:NO];
    [self.outputStream open];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    const uint8_t *buffer = [data bytes];
    NSUInteger bytesRemaining = [data length];
    NSInteger bytesWritten;

    if ([self isCancelled]) {
        [self completeWithSuccess:NO];
        return;
    }

    while (bytesRemaining != 0) {
        bytesWritten = [self.outputStream write:buffer maxLength:bytesRemaining];
        if (bytesWritten < 0) {

            self.error = [NSError errorWithDomain:[NSBundle mainBundle].bundleIdentifier
                                             code:-1
                                         userInfo:@{
                                                    @"message"  : @"Unable to write bytes",
                                                    @"function" : @(__FUNCTION__),
                                                    @"url"      : [self.url absoluteString]
                                                    }];
            
            [self completeWithSuccess:NO];

            return;
        }

        bytesRemaining -= bytesWritten;
        buffer += bytesWritten;
    }

    self.progressContentLength += [data length];

    if (self.downloadProgressBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.downloadProgressBlock(self, self.progressContentLength, self.expectedContentLength);
        });
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.error = error;
    
    [self completeWithSuccess:NO];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.error = nil;

    [self completeWithSuccess:YES];
}

@end
