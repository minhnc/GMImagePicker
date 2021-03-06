//
//  ViewController.m
//  GMPhotoPicker
//
//  Created by Guillermo Muntaner Perelló on 17/09/14.
//  Copyright (c) 2014 Guillermo Muntaner Perelló. All rights reserved.
//

#import "ViewController.h"
#import "GMImagePickerController.h"

@import UIKit;
@import Photos;


@interface ViewController () <GMImagePickerControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)launchGMImagePicker:(id)sender
{
    NSInteger status = [PHPhotoLibrary authorizationStatus];
    
    if ( status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted ) {
        [self launchUIImagePicker:sender];
        return;
    }
    
    GMImagePickerController *picker = [[GMImagePickerController alloc] init];
    picker.delegate = self;
    picker.title = @"Custom title";
    
    picker.customDoneButtonTitle = @"Finished";
    picker.customCancelButtonTitle = @"Nope";
    picker.customNavigationBarPrompt = @"Take a new photo or select an existing one!";
    
    picker.colsInPortrait = 3;
    picker.colsInLandscape = 5;
    picker.minimumInteritemSpacing = 2.0;
//    picker.maxSelectableAssets = 1;
    
//    picker.allowsMultipleSelection = NO;
//    picker.confirmSingleSelection = YES;
//    picker.confirmSingleSelectionPrompt = @"Do you want to select the image you have chosen?";
    
//    picker.showCameraButton = YES;
//    picker.autoSelectCameraImages = YES;
    
    picker.modalPresentationStyle = UIModalPresentationPopover;

//    picker.mediaTypes = @[@(PHAssetMediaTypeImage)];

//    picker.pickerBackgroundColor = [UIColor blackColor];
//    picker.pickerTextColor = [UIColor whiteColor];
//    picker.toolbarBackgroundColor = [UIColor darkGrayColor];
//    picker.toolbarBarTintColor = [UIColor blackColor];
//    picker.toolbarTextColor = [UIColor whiteColor];
//    picker.toolbarTintColor = [UIColor redColor];
//    picker.navigationBarBackgroundColor = [UIColor darkGrayColor];
//    picker.navigationBarBarTintColor = [UIColor blackColor];
//    picker.navigationBarTextColor = [UIColor whiteColor];
//    picker.navigationBarTintColor = [UIColor redColor];
//    picker.pickerFontName = @"Verdana";
//    picker.pickerBoldFontName = @"Verdana-Bold";
//    picker.pickerFontNormalSize = 14.f;
//    picker.pickerFontHeaderSize = 17.0f;
//    picker.pickerStatusBarStyle = UIStatusBarStyleLightContent;
//    picker.useCustomFontForNavigationBar = YES;
    
//    picker.arrangeSmartCollectionsFirst = YES;
   
    UIPopoverPresentationController *popPC = picker.popoverPresentationController;
    popPC.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popPC.sourceView = _gmImagePickerButton;
    popPC.sourceRect = _gmImagePickerButton.bounds;
//    popPC.backgroundColor = [UIColor blackColor];
    
    [self showViewController:picker sender:nil];
}

- (IBAction)launchUIImagePicker:(id)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popPC = picker.popoverPresentationController;
    popPC.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popPC.sourceView = _uiImagePickerButton;
    popPC.sourceRect = _uiImagePickerButton.bounds;
    
    [self showViewController:picker sender:sender];
}


#pragma mark - UIImagePickerControllerDelegate


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"UIImagePickerController: User ended picking assets");
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"UIImagePickerController: User pressed cancel button");
}

#pragma mark - GMImagePickerControllerDelegate

- (BOOL)assetsPickerController:(GMImagePickerController *)picker shouldSelectAsset:(PHAsset *)asset
{
    /*
    NSUInteger maxSelectableMedia = 10; // TODO
    
    if (maxSelectableMedia == -1) return true;
    
    // show alert gracefully
    if (picker.selectedAssets.count >= maxSelectableMedia)
    {
        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Sorry"
                                            message:[NSString stringWithFormat:@"You can select maximum %ld photos.", (long)maxSelectableMedia]
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action =
        [UIAlertAction actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                               handler:nil];
        
        [alert addAction:action];
        
        [picker presentViewController:alert animated:YES completion:nil];
    }
     */
    
    // limit selection to max
    return (picker.selectedAssets.count < picker.maxSelectableAssets);
}

- (void)assetsPickerController:(GMImagePickerController *)picker didFinishPickingAssets:(NSArray *)assetArray
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    NSLog(@"GMImagePicker: User ended picking assets. Number of selected items is: %lu", (unsigned long)assetArray.count);
    
    PHImageManager *manager = [PHImageManager defaultManager];
    
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    requestOptions.resizeMode   = PHImageRequestOptionsResizeModeNone;
    requestOptions.networkAccessAllowed = YES; // Will download the image from iCloud, if necessary
    requestOptions.synchronous = NO;

    __block NSUInteger imagesCount = 0;
    NSUInteger assetsCount = assetArray.count;
    NSString *tmpDir = NSTemporaryDirectory();
    NSMutableArray *files = [NSMutableArray arrayWithCapacity:assetsCount];
    
    for (PHAsset *asset in assetArray) {
        
        [manager requestImageForAsset:asset
                           targetSize:PHImageManagerMaximumSize
                          contentMode:PHImageContentModeDefault
                              options:requestOptions
                        resultHandler:^void(UIImage *image, NSDictionary *info) {
                            
                            imagesCount++;
                            
                            NSURL *url = [info objectForKey:@"PHImageFileURLKey"];
                            NSString *ext = [url pathExtension];
                            NSString *tmpFile = [tmpDir stringByAppendingPathComponent: [url lastPathComponent]];

                            [files addObject:tmpFile];
                            
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                                if ([ext isEqualToString:@"JPG"]) {
                                    [UIImageJPEGRepresentation(image, 1) writeToFile:tmpFile atomically:YES];
                                } else {
                                    [UIImagePNGRepresentation(image) writeToFile:tmpFile atomically:YES];
                                }
                            });
                            
                            if (imagesCount == assetsCount) {
                                NSLog(@"DONE: %@", files);
                            }
                        }];
    }
}

//Optional implementation:
-(void)assetsPickerControllerDidCancel:(GMImagePickerController *)picker
{
    NSLog(@"GMImagePicker: User pressed cancel button");
}
@end
