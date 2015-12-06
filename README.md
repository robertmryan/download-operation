###Download Operation

This is a sample iOS class for performing downloads of files from a remote server. It consists of a `DownloadOperation` which can be used for creating downloads operations for submission to a `NSOperationQueue`. 

See [class reference](http://robertmryan.github.io/download-operation) for more information and examples on how to use this class. You may also refer to the `ViewController.m` file for a practical example. (Note, in this demonstration, you will have to edit the code to supply the names of the files you wish to download and the URL from which you want to download them.

This was developed in Xcode 4.6.3. This sample project was tested in iOS 5.0 thru iOS 9.1. This project uses ARC.

Note, this uses `NSURLConnection`, and as a result, probably shouldn't be used any more since that's now deprecated. You should use `NSURLSession`-based approach. And `NSURLSession` has `NSURLSessionDownloadTask`, which greatly simplifies the downloading of remote resources in a memory efficient manner.

Robert M. Ryan<br />
31 July 2013
