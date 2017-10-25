

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#include <pthread.h>

#include "RingBuffer.hpp"
#include <stdio.h>
#include "VideoCameraProcessor.h"
#include "Common.hpp"


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
    
    int myCustomUIViewState, myCustomUIViewHeight, myCustomUIViewWidth, myCustomUIViewLocationX, myCustomUIViewLocationY;
    int selfUIViewState, selfUIViewHeight, selfUIViewWidth, selfUIViewLocationX, selfUIViewLocationY;
    
    int m_iParamSelector;
    int params[4];
    NSString *Operation[20];
    int m_iOperationSelector;
    
    NSString *resolutionList[4];
    int m_iResolutionSelector;
    bool m_brapidFireForTargetUserBtnHold;
}
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *Constraint_SelfView_Height;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *Constraints_SelfView_Width;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *Constraints_SelfView_LeftPadding;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *Constraints_SelfView_TopPadding;

@property (retain, nonatomic) IBOutlet NSLayoutConstraint *Constraint_CustomView_Height;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *Constraints_CustomView_Width;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *Constraints_CustomView_LeftPadding;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *Constraints_CustomView_TopPadding;


@property (nonatomic,strong) id delegate;
@property (retain, nonatomic) IBOutlet UIButton *resetBtn;

@property (retain, nonatomic) IBOutlet UIButton *LoginButton;
@property (retain, nonatomic) IBOutlet UIButton *startBtn;

@property (retain, nonatomic) IBOutlet UIButton *targetUserBtn;
@property (retain, nonatomic) IBOutlet UITextField *targetUserField;

@property (retain, nonatomic) IBOutlet UIButton *ChangeResBtn;
@property (retain, nonatomic) IBOutlet UIView *myRealView;
@property (retain, nonatomic) IBOutlet UIButton *ldSpeakerBtn;

@property bool bEncodeThreadActive;
@property bool bP2PSocketInitialized;
@property (retain, nonatomic) IBOutlet UILabel *ResLabel;
@property (retain, nonatomic) IBOutlet UITextField *ResField;
@property (retain, nonatomic) IBOutlet UIButton *CheckCapabilityBtn;
@property (retain, nonatomic) IBOutlet UILabel *statusMessage;
@property (retain, nonatomic) IBOutlet UITextField *IPTextField;
@property (retain, nonatomic) IBOutlet UIButton *startCallInLiveBtn;
@property (retain, nonatomic) IBOutlet UIButton *FilterOnOffButton;
@property (retain, nonatomic) IBOutlet UIButton *plusBtn;
@property (retain, nonatomic) IBOutlet UIButton *minusBtn;
@property (retain, nonatomic) IBOutlet UIButton *paramBtn;
@property (retain, nonatomic) IBOutlet UILabel *paramValueLbl;
@property (retain, nonatomic) IBOutlet UIButton *endCallBtn;
@property (retain, nonatomic) IBOutlet UIButton *operationBtn;
@property (retain, nonatomic) IBOutlet UILabel *UserIDLabel;

@property (retain, nonatomic) NSTimer *rapidFireTimer;


+ (id)GetInstance;

- (void)setupAVCapture;
- (void)teardownAVCapture;
- (IBAction)plusBtnAction:(id)sender;
- (IBAction)minusBtnAction:(id)sender;
- (IBAction)ParamBtnAction:(id)sender;


- (IBAction)resetBtnAction:(id)sender;
- (IBAction)startAction:(id)sender;
- (IBAction) EndCallAction:(id)endButton;
- (IBAction)ChangeTargetUserAction:(id)sender;

- (IBAction)ChangeResBtnAction:(id)sender;
- (IBAction)loudSpeakerAction:(id)sender;

- (void)SetCameraResolutionByNotification:(int)iHeight withWidth:(int)iWidth;
- (IBAction)CheckCapabilityAction:(id)sender;
- (IBAction)makeSenderAction:(id)sender;
- (IBAction)makeReceiverAction:(id)sender;
- (IBAction)startCallInLiveAction:(id)sender;
- (IBAction)SetFilterOnOffAction:(id)sender;
- (IBAction)operationAction:(id)sender;

- (void)UpdateValue;


void WriteToFile(byte *pData);
unsigned int timeGetTime();

- (void)UpdateTargetUser;
- (void)UpdateStatusMessage: (string)sMsg;
- (int)InitializeAudioVideoEngineForCall;
- (int)InitializeAudioVideoEngineForLive: (bool)isPublisher;
- (int)InitializeCameraAndMicrophone;
- (int)UnInitializeAudioVideoEngine;
- (int)UnInitializeCameraAndMicrophone;

- (void)StartAllThreads;
- (void)CloseAllThreads;
+(long long)convertStringIPtoLongLong:(NSString *)ipAddr;
- (void) CalculateFPS;

- (void) UpdateUserID:(string)sValue;

- (void)targetBtnHoldDownAction;


@end

static TestCameraViewController *m_pTestCameraViewController = nil;



