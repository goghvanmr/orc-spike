//
//  ViewController.m
//  sc-ocr
//
//  Created by LI Yi on 7/22/13.
//  Copyright (c) 2013 LI Yi. All rights reserved.
//

#import "ViewController.h"

#import "Tesseract.h"
#import "GPUImage.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize image = _image;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    UIImage *tag = [self convertImageToGrayScale:[UIImage imageNamed:@"tag_full.jpg"]];
    
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:tag];
    GPUImageLuminanceThresholdFilter *stillImageFilter = [[GPUImageLuminanceThresholdFilter alloc] init];

    stillImageFilter.threshold = 0.40;
    [stillImageSource addTarget:stillImageFilter];
    [stillImageSource processImage];
    
    UIImage *imageWithAppliedThreshold = [stillImageFilter imageFromCurrentlyProcessedOutput];
    
    [_image setImage:imageWithAppliedThreshold];
    
    Tesseract* tesseract = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"eng"];
    [tesseract setImage:imageWithAppliedThreshold];
    [tesseract recognize];
    
    NSLog(@"%@", [tesseract recognizedText]);
    [tesseract clear];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *)convertImageToGrayScale:(UIImage *)image
{
    // Create image rectangle with current image width/height
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    // Grayscale color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    // Create bitmap content with current image size and grayscale colorspace
    CGContextRef context = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
    
    // Draw image into current context, with specified rectangle
    // using previously defined context (with grayscale colorspace)
    CGContextDrawImage(context, imageRect, [image CGImage]);
    
    // Create bitmap image info from pixel data in current context
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    // Create a new UIImage object
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    
    // Release colorspace, context and bitmap information
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(imageRef);
    
    // Return the new grayscale image
    return newImage;
}

@end
