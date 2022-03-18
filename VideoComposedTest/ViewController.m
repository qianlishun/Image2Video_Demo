//
//  ViewController.m
//  VideoComposedTest
//
//  Created by mrq on 16/9/27.
//  Copyright © 2016年 Sonoptek. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "PHPhotoLibrary+Custom.h"

@interface ViewController ()
@property (nonatomic,strong) NSArray<NSString*> *array;
@property(nonatomic, strong) UILabel *label;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                
            });
        }
    }];

    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < 100; i++) {
        NSString *string = [NSString stringWithFormat:@"%d",i];
        [array addObject:string];
    }
    self.array = array.copy;
    
    CGSize size = self.view.bounds.size;
    
    int width = ((int) (size.width / 16)) * 16;
    int height = ((int) (size.height / 16)) * 16;
    
    size = CGSizeMake(width, height);

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:1];
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        [self compressionVideo:size];
    }];
    [queue addOperation:op];
}

#pragma mark - make temp image
- (CGImageRef)getTempImage:(int)index{
    
    __block UIImage *img;
    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        self.label.text = self.array[index];
        img = [self screenImageWith:self.view];
    }];
    [[NSOperationQueue mainQueue]addOperation:op];
    
    [op waitUntilFinished];
    
    return img.CGImage;
}

- (UIImage*)screenImageWith:(UIView*)view{
    float scale = 1.0;
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return viewImage;
}

- (UILabel *)label{
    if(!_label){
        _label = [[UILabel alloc]initWithFrame:self.view.bounds];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.font = [UIFont systemFontOfSize:150];
        _label.textColor = [UIColor orangeColor];
        [self.view addSubview:_label];
    }
    return _label;
}

#pragma mark - make video
- (void)compressionVideo:(CGSize)size{
    
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mov"];
    
    
    NSError *error = nil;
    NSUInteger fps = 10;

    NSLog(@"Start building video from defined frames.");
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                  [NSURL fileURLWithPath:path] fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput *videoWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeVideo
                                            outputSettings:videoSettings];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                     sourcePixelBufferAttributes:nil];
    
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    [videoWriter addInput:videoWriterInput];
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    CVPixelBufferRef buffer = NULL;
    
    //convert uiimage to CGImage.
    int frameCount = 0;
    double numberOfSecondsPerFrame = 1.0/fps;
    double frameDuration = fps * numberOfSecondsPerFrame;
    
    
    int i = 0;
    while (1) {
        @autoreleasepool {
            CGImageRef inputImage  = [self getTempImage:i];
            buffer = [self  pixelBufferFromCGImage:inputImage size:size];
            
            BOOL append_ok = NO;
            int j = 0;
            while (!append_ok && j < 20)
            {
                if (adaptor.assetWriterInput.readyForMoreMediaData)
                {
                    //print out status:
                    CMTime frameTime = CMTimeMake(frameCount * frameDuration, (int32_t) fps);
                    append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                    if (!append_ok)
                    {
                        NSError *error = videoWriter.error;
                        if (error != nil)
                        {
                            NSLog(@"Unresolved error %@,%@.", error, [error userInfo]);
                        }
                    }
                }
                else
                {
                NSLog(@"adaptor not ready %d, %d\n", frameCount, j);
                    [NSThread sleepForTimeInterval:0.1];
                }
                j++;
            }
            if (!append_ok){
                NSLog(@"error appending image %d times %d\n, with error.", frameCount, j);
            }
            frameCount++;
            [[NSOperationQueue mainQueue]addOperationWithBlock:^{
                float progress= (float)frameCount/(float)self.array.count;
                NSLog(@"progress %.2f",progress);
            }];
            CVPixelBufferRelease(buffer);
            i++;
            if (i>=self.array.count) {
                break;
            }
        }
    }
    
    //Finish the session:
    [videoWriterInput markAsFinished];
    id  __block  vw = videoWriter;
    id  __block vwip = videoWriterInput;

    [videoWriter finishWritingWithCompletionHandler:^{
        vw = nil;
        vwip = nil;

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // TODO something : Like tips , move the video to the album.

            NSURL *url = [NSURL fileURLWithPath:path];
            PHPhotoLibrary *library = [PHPhotoLibrary sharedPhotoLibrary];
            [library saveVideo:url toAlbum:NSLocalizedString(@"Video", nil) withCompletionBlock:^(NSError *error, NSString *localIdentifier) {
                NSString *msg;
                if (error == nil){
                    msg = NSLocalizedString(@"Video have been saved in album.", nil);
                    self.label.text = msg;
                }
                else {
                    msg = NSLocalizedString(@"Video saved Failure.", nil);
                }
                NSLog(@"%@",msg);
                if ([[NSFileManager defaultManager] removeItemAtPath:path error:&error] != YES)
                    NSLog(@"Unable to delete file: %@", [error localizedDescription]);
            }];
        }];
        
    }];
    
}

#pragma mark - make buffer
- (CVPixelBufferRef )pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size

{
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options, &pxbuffer);
    
    // CVReturn status = CVPixelBufferPoolCreatePixelBuffer(NULL, adaptor.pixelBufferPool, &pxbuffer);
    
    
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    NSParameterAssert(pxdata != NULL);
    
    
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, 4*size.width, rgbColorSpace, kCGImageAlphaPremultipliedFirst);
    
    NSParameterAssert(context);
    
    
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    
    
    
    CGColorSpaceRelease(rgbColorSpace);
    
    CGContextRelease(context);
    
    
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    
    
    return pxbuffer;
    
}



@end
