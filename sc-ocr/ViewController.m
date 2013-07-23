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

#define SCREEN_WIDTH 320.0
#define SCREEN_LENGTH 480.0

#define IMAGE_CROP_AREA_X 20.0
#define IMAGE_CROP_AREA_Y 205.0
#define IMAGE_CROP_AREA_WIDTH 280.0
#define IMAGE_CROP_AREA_LENGTH 50.0

@interface ViewController ()

@end

@implementation ViewController

@synthesize image = _image;
@synthesize recognizedText = _recognizedText;

- (IBAction)beginScan:(UIButton *)sender {
    [self startCameraControllerFromViewController:self usingDelegate:self];
}

- (IBAction)recognize:(UIButton *)sender {
    Tesseract* tesseract = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"chi_sim"];
    [tesseract setImage:[self.image image]];
    [tesseract recognize];
    
    self.recognizedText.text = [tesseract recognizedText];
    
    NSLog(@"%@", [tesseract recognizedText]);
    [tesseract clear];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*UIImage *tag = [self convertImageToGrayScale:[UIImage imageNamed:@"tag_full.jpg"]];
    
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
    [tesseract clear];*/
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (UIImage *)convertImageToGrayScale:(UIImage *)image
{
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    CGContextRef context = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
    
    CGContextDrawImage(context, imageRect, [image CGImage]);
    
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(imageRef);
    
    return newImage;
}

- (BOOL) startCameraControllerFromViewController: (UIViewController*) controller
                                   usingDelegate: (id <UIImagePickerControllerDelegate,
                                                   UINavigationControllerDelegate>) delegate {
    
    if (([UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeCamera] == NO)
        || (delegate == nil)
        || (controller == nil))
        return NO;
    
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    cameraUI.allowsEditing = NO;
    cameraUI.cameraOverlayView = [self cameraOverlayView];
    cameraUI.delegate = delegate;
    
    [controller presentViewController:cameraUI animated:YES completion:nil];
    return YES;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *) picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    UIImage *rotatedImage = [self scaleAndRotateImage:originalImage];
    
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:rotatedImage];
    GPUImageCropFilter *stillImageFilter = [[GPUImageCropFilter alloc] init];
    
    stillImageFilter.cropRegion = CGRectMake(IMAGE_CROP_AREA_X/SCREEN_WIDTH, (IMAGE_CROP_AREA_Y + 20)/SCREEN_LENGTH, IMAGE_CROP_AREA_WIDTH/SCREEN_WIDTH, IMAGE_CROP_AREA_LENGTH/SCREEN_LENGTH);
    [stillImageSource addTarget:stillImageFilter];
    [stillImageSource processImage];
    
    self.image.image = [stillImageFilter imageFromCurrentlyProcessedOutput];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (UIImage *)scaleAndRotateImage:(UIImage *)image {
    int kMaxResolution = 640; // Or whatever
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = roundf(bounds.size.width / ratio);
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = roundf(bounds.size.height * ratio);
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}

- (UIView *)cameraOverlayView
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_LENGTH)];
    
    UIView *rectView = [[UIView alloc]initWithFrame:CGRectMake(IMAGE_CROP_AREA_X, IMAGE_CROP_AREA_Y, IMAGE_CROP_AREA_WIDTH, IMAGE_CROP_AREA_LENGTH)];
    rectView.backgroundColor = [UIColor grayColor];
    rectView.alpha = 0.5f;
    
    [view addSubview:rectView];
    
    return view;
}

@end
