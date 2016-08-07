

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#include <pthread.h>

#include "RingBuffer.hpp"
#include <stdio.h>
#include "VideoCallProcessor.h"
#include "common.h"


@interface TestCameraViewController : UIViewController <UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, UITextFieldDelegate, ViewControllerDelegate>
{
    AVCaptureSession *session;
	IBOutlet UIView *previewView;
	IBOutlet UISegmentedControl *camerasControl;
	AVCaptureVideoPreviewLayer *previewLayer;
	AVCaptureVideoDataOutput *videoDataOutput;
	BOOL detectFaces;
	dispatch_queue_t videoDataOutputQueue;
	BOOL isUsingFrontFacingCamera;
    IBOutlet UITextField *helloText;
    IBOutlet UIImageView *MyCustomImageView;
    IBOutlet UITextField *randomTextField;
    IBOutlet UIView *MyCustomView;
    RingBuffer<byte> *pEncodeBuffer;
    pthread_t tRenderThread;
    int iRenderThreadID;

    
    IBOutlet UIView *SelfView;
    int m_iCameraWidth;
    int m_iCameraHeight;
    int m_iRenderWidth;
    int m_iRenderHeight;
    
}

@property (nonatomic,strong) id delegate;

@property (retain, nonatomic) IBOutlet UIButton *LoginButton;
@property (retain, nonatomic) IBOutlet UIButton *P2PButton;
@property (retain, nonatomic) IBOutlet UITextField *myIdTextField;
@property (retain, nonatomic) IBOutlet UITextField *friendIdTextField;
@property (retain, nonatomic) IBOutlet UITextField *remoteIPTextField;
@property (retain, nonatomic) IBOutlet UIButton *ServerCall;

@property (retain, nonatomic) IBOutlet UIButton *ChangePort;
@property (retain, nonatomic) IBOutlet UITextField *PortField;

@property (retain, nonatomic) IBOutlet UIButton *ChangeResBtn;

@property bool bEncodeThreadActive;
@property bool bP2PSocketInitialized;
@property (retain, nonatomic) IBOutlet UILabel *ResLabel;
@property (retain, nonatomic) IBOutlet UITextField *ResField;
@property (retain, nonatomic) IBOutlet UIButton *CheckCapabilityBtn;
@property (retain, nonatomic) IBOutlet UILabel *statusMessage;
@property (retain, nonatomic) IBOutlet UITextField *IPTextField;

- (void)setupAVCapture;
- (void)teardownAVCapture;

- (IBAction) LoginButtonAction:(id)loginButton;
- (IBAction) StartCallAction:(id)startButton;
- (IBAction) EndCallAction:(id)endButton;
- (IBAction) P2PButtonAction:(id)P2PButton;
- (IBAction)ChangePort:(id)sender;
- (IBAction)ChangeResBtnAction:(id)sender;

- (void)SetCameraResolutionByNotification:(int)iHeight withWidth:(int)iWidth;
- (IBAction)CheckCapabilityAction:(id)sender;


void WriteToFile(byte *pData);
unsigned int timeGetTime();
void CalculateFPS();
long long GetTimeStamp();
- (void)UpdatePort;
- (void)UpdateStatusMessage: (string)sMsg;


@end



