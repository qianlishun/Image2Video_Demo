//
//  ViewController.m
//  VideoComposedTest
//
//  Created by mrq on 16/9/27.
//  Copyright © 2016年 Sonoptek. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
@property (nonatomic,strong) NSArray *imageArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.imageArr = [NSArray array];
    
    NSLog(@"%@",[NSDate date]);
    _imageArr = [NSArray arrayWithObjects:[[UIImage imageNamed:@"IMG_0102"] CGImage],[[UIImage imageNamed:@"IMG_0103"] CGImage],[[UIImage imageNamed:@"IMG_0153"] CGImage],[[UIImage imageNamed:@"IMG_0154"] CGImage],[[UIImage imageNamed:@"IMG_0155"] CGImage],[[UIImage imageNamed:@"IMG_0156"] CGImage],[[UIImage imageNamed:@"IMG_0157"] CGImage],[[UIImage imageNamed:@"IMG_0158"] CGImage], nil];
    
    
    [self testCompressionSession];
    
}

- (void) testCompressionSession

{
    
    
    CGSize size1 = [UIImage imageNamed:@"IMG_0153"].size;
    
    int width = ((int) (size1.width / 16)) * 16;
    int height = ((int) (size1.height / 16)) * 16;
    
    CGSize size = CGSizeMake(width, height);
    
    NSString *betaCompressionDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mov"];
    
    
    
    NSError *error = nil;
    
    
    
    unlink([betaCompressionDirectory UTF8String]);
    
    
    
    //----initialize compression engine
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:betaCompressionDirectory]
                                  
                                                           fileType:AVFileTypeQuickTimeMovie
                                  
                                                              error:&error];
    
    NSParameterAssert(videoWriter);
    
    if(error)
        
        NSLog(@"error = %@", [error localizedDescription]);
    
    
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                                   
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey, nil];
    
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           
                                                           [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    
    
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                     
                                                                                                                     sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    NSParameterAssert(writerInput);
    
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    
    
    
    if ([videoWriter canAddInput:writerInput])
        
        NSLog(@"I can add this input");
    
    else
        
        NSLog(@"i can't add this input");
    
    
    
    [videoWriter addInput:writerInput];
    
    
    
    [videoWriter startWriting];
    
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    
    
    //---
    
    // insert demo debugging code to write the same image repeated as a movie
    
    
    
    
    dispatch_queue_t    dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);
    
    int __block         frame = 0;
    
    
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        
        while ([writerInput isReadyForMoreMediaData])
            
        {
            
            if(++frame >= _imageArr.count * 10)
                
            {
                
                [writerInput markAsFinished];
                
                [videoWriter finishWriting];
                
                
                break;
                
            }
            
            int idx = frame/10;
            
            
            
            CVPixelBufferRef buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:(__bridge CGImageRef)([_imageArr objectAtIndex:idx]) size:size];
            
            if (buffer)
                
            {
                
                if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame, 20)]){
                    
                    NSLog(@"FAIL");
                }
                else{
                    
                    NSLog(@"Success:%d", frame);
                    if (frame == _imageArr.count*10 -1) {
                        NSLog(@"视频保存成功.");
                    }
                }
                CFRelease(buffer);
                
            }
            
        }
        
    }];
    
    NSLog(@"outside for loop");
    
}

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
