//
//  ViewController.h
//  sc-ocr
//
//  Created by LI Yi on 7/22/13.
//  Copyright (c) 2013 LI Yi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic)IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *recognizedText;

@end
