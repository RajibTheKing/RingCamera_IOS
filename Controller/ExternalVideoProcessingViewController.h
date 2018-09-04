//
//  ExternalVideoProcessingViewController.h
//  TestCamera
//
//  Created by Rajib Chandra Das on 11/18/17.
//

#import <UIKit/UIKit.h>
#import "VideoAPI.hpp"
@interface ExternalVideoProcessingViewController : UIViewController<ExternalVideoProcessingVCDelegate>
@property (retain, nonatomic) IBOutlet UIButton *filterCheck;
@property (retain, nonatomic) IBOutlet UIImageView *imageView;
@property (retain, nonatomic) IBOutlet UIButton *plusBtn;
@property (retain, nonatomic) IBOutlet UILabel *positionLabel;
- (IBAction)filterCheckAction:(id)sender;
@property (retain, nonatomic) IBOutlet UIButton *minusBtn;
- (IBAction)plusBtnAction:(id)sender;
- (IBAction)minusBtnAction:(id)sender;
- (IBAction)startThumbnailAction:(id)sender;
@end
