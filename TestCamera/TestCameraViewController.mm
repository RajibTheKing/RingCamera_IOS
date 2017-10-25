//@import AVFoundation;
#import "TestCameraViewController.h"
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>
#include <stdio.h>

#include "VideoConverter.hpp"
#include "Constants.h"
#include "MessageProcessor.hpp"
#include "VideoCameraProcessor.h"
#include "VideoSockets.h"

#include <pthread.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <arpa/inet.h>

#include <sstream>
#include <queue>
#include <set>
#include <sys/time.h>
#include "RingCallAudioManager.h"
#include <sstream>
#include "VideoThreadProcessor.h"
#include "TestNeonAssembly.hpp"



#define SSTR( x ) dynamic_cast< std::ostringstream & >( \
( std::ostringstream() << std::dec << x ) ).str()

int iRenderCallTime = 0;
int iRenderFrameCount = 0;
int g_iFpsTime = 0;
string sMyId;
string sFrinedId;
int g_iMyId, g_iFriendId;

VideoCameraProcessor *g_pVideoCameraProcessor;


int iTotalLengthPerSecond = 0;
int counter = 0;
FILE *fp = NULL;
FILE *fpyuv = NULL;

int g_iTargetUser;

@implementation TestCameraViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    MyCustomImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, m_iCameraWidth, m_iCameraHeight)];
    //MyCustomImageView.transform = CGAffineTransformScale(MyCustomImageView.transform, -1.0, 1.0);
    
    _bP2PSocketInitialized = false;
    
    //### VideoTeam: Initialization Procedure...
  
    g_pVideoCameraProcessor = [VideoCameraProcessor GetInstance];
    g_pVideoCameraProcessor.delegate = self;

    //End
    
    session = nil;
    [_targetUserField setEnabled:false];
    g_iTargetUser = 1;
    [self UpdateTargetUser];
    [self UpdateStatusMessage:"Started Application"];
    
    //ActionListener for MyCustomView
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapforRemoteView:)];
    [MyCustomView addGestureRecognizer:singleFingerTap];
    [singleFingerTap release];
    myCustomUIViewState = 0;
    myCustomUIViewHeight = MyCustomView.frame.size.height;
    myCustomUIViewWidth = MyCustomView.frame.size.width;
    myCustomUIViewLocationX = MyCustomView.frame.origin.x;
    myCustomUIViewLocationY = MyCustomView.frame.origin.y;
    
    //ActionListener for SelfView
    UITapGestureRecognizer *singleFingerTapSelfView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapforOwnView:)];
    [SelfView addGestureRecognizer:singleFingerTapSelfView];
    [singleFingerTapSelfView release];
    selfUIViewState = 0;
    selfUIViewHeight = SelfView.frame.size.height;
    selfUIViewWidth = SelfView.frame.size.width;
    selfUIViewLocationX = SelfView.frame.origin.x;
    selfUIViewLocationY = SelfView.frame.origin.y;
    
    
    //NSLayoutConstraint.deactivateConstraints(self.landscapeConstraintsPad);
    
    
    
    
    
    m_iParamSelector = 0;
    params[0] = 100; //Sigma
    params[1] = 1; //Radius
    params[2] = 8; //Den
    params[3] = 0;
    [self UpdateValue];
 
    int nMyCornerRadius = 10;
    
    self.startBtn.layer.cornerRadius = nMyCornerRadius;
    self.targetUserBtn.layer.cornerRadius = nMyCornerRadius;
    self.ChangeResBtn.layer.cornerRadius = nMyCornerRadius;
    self.ldSpeakerBtn.layer.cornerRadius = nMyCornerRadius;
    
    self.CheckCapabilityBtn.layer.cornerRadius = nMyCornerRadius;
    self.startCallInLiveBtn.layer.cornerRadius = nMyCornerRadius;
    self.FilterOnOffButton.layer.cornerRadius = nMyCornerRadius;
    self.plusBtn.layer.cornerRadius = nMyCornerRadius;
    self.minusBtn.layer.cornerRadius = nMyCornerRadius;
    self.paramBtn.layer.cornerRadius = nMyCornerRadius;
    self.endCallBtn.layer.cornerRadius = nMyCornerRadius;
    
    //cout<<"VideoCallProcessor:: VideoAPI->Init --> "<<"lUser = "<<lUserId<<endl;
    
    if(CVideoAPI::GetInstance()->Init(100, "", 1) == 1)
    {
        printf("myVideoAPI Initialized\n");
    }
    else
    {
        printf("myVideoAPI is not Initialized\n");
    }
    
    NSString *nsServerIP = [_IPTextField text];
    string sServerIP = [nsServerIP UTF8String];
    
    CVideoAPI::GetInstance()->InitializeMediaConnectivity(sServerIP /*Server IP*/, 6060 /* Server Signaling Port*/, 1);
    CVideoAPI::GetInstance()->ProcessCommand("register");
    
    Operation[0] = @"Invite";
    Operation[1] = @"Publish";
    Operation[2] = @"View";
    Operation[3] = @"Terminate-All";
    
    m_iOperationSelector = 0;
    
   [[self operationBtn]  setTitle:Operation[m_iOperationSelector] forState:UIControlStateNormal];
    
    [_targetUserBtn addTarget:self action:@selector(targetBtnHoldDownAction) forControlEvents:UIControlEventTouchDown];
    m_brapidFireForTargetUserBtnHold = false;
    m_pTestCameraViewController = self;
    
    TestNeonAssembly testNeonAssembly;
    unsigned char *temporaryRGB = new unsigned char[MAXHEIGHT * MAXWIDTH * 3];
    unsigned char *temporaryRGBoutput = new unsigned char[MAXHEIGHT * MAXWIDTH * 3];
    for(int i=0;i<MAXHEIGHT*MAXWIDTH*3;i++)
    {
        temporaryRGB[i] = rand()%256;
    }
    
    long long startTime = CurrentTimeStamp();
    testNeonAssembly.reference_convert(temporaryRGBoutput, temporaryRGB, MAXHEIGHT * MAXWIDTH);
    printf("reference_convert timeDIff = %lld\n", CurrentTimeStamp() - startTime);
    for(int i=0;i<50;i++){printf("%d ", temporaryRGBoutput[i]);}printf("\n");
    
    startTime = CurrentTimeStamp();
    testNeonAssembly.neon_intrinsic_convert(temporaryRGBoutput, temporaryRGB, MAXHEIGHT * MAXWIDTH);
    printf("neon_intrinsic_convert timeDIff = %lld\n", CurrentTimeStamp() - startTime);
    for(int i=0;i<50;i++){printf("%d ", temporaryRGBoutput[i]);}printf("\n");
    
    startTime = CurrentTimeStamp();
    testNeonAssembly.neon_assembly_convert(temporaryRGBoutput, temporaryRGB, MAXHEIGHT * MAXWIDTH);
    printf("neon_assembly_convert timeDIff = %lld\n", CurrentTimeStamp() - startTime);
    for(int i=0;i<50;i++){printf("%d ", temporaryRGBoutput[i]);}printf("\n");
    
    printf("TheKing--> Check Reverse ARM Assembly\n");
    unsigned char *temporaryArray = new unsigned char[MAXHEIGHT * MAXWIDTH * 3];
    unsigned char *temporaryArrayOut = new unsigned char[MAXHEIGHT * MAXWIDTH * 3];
    int iTempLen = 200;
    for(int i=0;i<iTempLen;i++)temporaryArray[i]=rand()%255;
    for(int i=0;i<iTempLen;i++){printf("%4d ", temporaryArray[i]); if((i+1)%30==0)printf("\n");}printf("\n");
    testNeonAssembly.Reverse_Check_Assembly(temporaryArray, iTempLen, temporaryArrayOut);
    for(int i=0;i<iTempLen;i++){printf("%4d ", temporaryArrayOut[i]); if((i+1)%30==0)printf("\n"); }printf("\n");
    
    int iFrameLen = 1280*720*3/2;
    
    unsigned char *pDest = new unsigned char[iFrameLen];
    unsigned char *pSrc = new unsigned char[iFrameLen];
    unsigned char *pDest2 = new unsigned char[iFrameLen];
    for(int i=0;i<iFrameLen;i++)
    {
        pSrc[i] = rand()%256;
    }
    
    startTime = CurrentTimeStamp();
    testNeonAssembly.Copy_Assembly_Inc(pSrc, pDest, iFrameLen);
    printf("Copy_assembly_convert timeDIff = %lld\n", CurrentTimeStamp() - startTime);
    
    startTime = CurrentTimeStamp();
    testNeonAssembly.Copy_Assembly_Inc(pSrc, pDest2, iFrameLen);
    printf("Copy_assembly_convert timeDIff = %lld\n", CurrentTimeStamp() - startTime);
    
    
    startTime = CurrentTimeStamp();
    memcpy(pDest2, pSrc, iFrameLen);
    printf("memcpy timeDIff = %lld\n", CurrentTimeStamp() - startTime);

    
    
    //for(int i=0;i<iFrameLen;i++){printf("%d ", pSrc[i]);}printf("\n\n\n\n\n\n\n\n");
    //for(int i=0;i<iFrameLen;i++){printf("%d ", pDest[i]);}printf("\n");
    
    
    testNeonAssembly.learn();
    
    unsigned int *pData = new unsigned int[256]; //Always Length is 256
    for(int i=0;i<256;i++)
    {
        pData[i] = rand()%256;
    }
    
    unsigned int *ans = new unsigned int[1];
    for(int i=192;i<212;i++)
    {
        cout<<pData[i]<<" ";
    }
    cout<<endl;
    testNeonAssembly.CalculateSumOfLast64_assembly(pData, ans);
    cout<<"Final Ans = "<<*ans<<endl;
    
    
    
    resolutionList[0] = @"352x288";
    resolutionList[1] = @"640x480";
    resolutionList[2] = @"1280x720";
    resolutionList[3] = @"1920x1080";
    m_iResolutionSelector = 0;
    
}

+ (id)GetInstance
{
    return m_pTestCameraViewController;
}

- (void)setupAVCapture
{
    CALayer *rootLayer;
    rootLayer = [SelfView layer];
    [rootLayer setMasksToBounds:YES];
    [previewLayer setFrame:[rootLayer bounds]];
    [rootLayer addSublayer:previewLayer];
    
}




- (IBAction) startAction:(id)sender
{
    int iRet = 0;
    NSString *nsTargetUser = [_targetUserField text];
    string sTargetUser = [nsTargetUser UTF8String];
    NSString *nsTargetAction = Operation[m_iOperationSelector];
    
    if([nsTargetAction  isEqual: @"Invite"])
    {
        CVideoAPI::GetInstance()->ProcessCommand("invite " + sTargetUser);
        
        [self StartAllThreads];
        iRet = [self InitializeCameraAndMicrophone];
        iRet = [self InitializeAudioVideoEngineForCall];
        
        
        //iRet = [self InitializeAudioVideoEngineForLive];
        
    }
    else if([nsTargetAction  isEqual: @"Publish"])
    {
        CVideoAPI::GetInstance()->ProcessCommand("publish");
        [self StartAllThreads];
        iRet = [self InitializeCameraAndMicrophone];
        iRet = [self InitializeAudioVideoEngineForLive:true];
        
    }
    else if([nsTargetAction  isEqual: @"View"])
    {
        CVideoAPI::GetInstance()->ProcessCommand("view "+ sTargetUser);
        
        [self StartAllThreads];
        iRet = [self InitializeCameraAndMicrophone];
        iRet = [self InitializeAudioVideoEngineForLive:false];
        
        
    }
    else if([nsTargetAction  isEqual: @"Terminate-All"])
    {
        CVideoAPI::GetInstance()->ProcessCommand("terminate-all");
        [self UnInitializeAudioVideoEngine];
        [self UnInitializeCameraAndMicrophone];
        [self CloseAllThreads];
    }
}

- (int)InitializeCameraAndMicrophone
{
    if([self.ResField.text isEqual:@"352x288"])
    {
        m_iCameraHeight = 352;
        m_iCameraWidth = 288;
        
    }
    else if([self.ResField.text isEqual:@"640x480"])
    {
        m_iCameraHeight = 640;
        m_iCameraWidth = 480;
        
    }
    else if([self.ResField.text isEqual:@"1280x720"])
    {
        m_iCameraHeight = 1280;
        m_iCameraWidth = 720;
        
    }
    else
    {
        m_iCameraHeight = 1920;
        m_iCameraWidth = 1080;
    }

    
    g_pVideoCameraProcessor.m_lCameraInitializationStartTime = CurrentTimeStamp();
    
    if(session == nil)
    {
        
        [g_pVideoCameraProcessor InitializeCameraSession:&session
                                        withDeviceOutput:&videoDataOutput
                                               withLayer:&previewLayer
                                              withHeight:&m_iCameraHeight
                                               withWidth:&m_iCameraWidth];
        [self setupAVCapture]; //This Method is needed to Initialize Self View with Camera output
    }
    
    [session startRunning];
    [[RingCallAudioManager sharedInstance] startRecordAndPlayAudio];
    
    g_pVideoCameraProcessor.m_bStartVideoSending = true;
    
    return 1;
}

- (void)UpdateTargetUser
{
    cout<<"Current Friend = "<<g_iTargetUser<<endl;
    ostringstream oss;
    oss.clear();
    oss<<g_iTargetUser;
    string sTargetUser = oss.str();
    
    self.targetUserField.text = @(sTargetUser.c_str());
}

- (IBAction)ChangeResBtnAction:(id)sender
{
    cout<<"TheKing--> Inside ChangeResAction"<<endl;
    NSString *nsRes = self.ResField.text;
    m_iResolutionSelector++;
    m_iResolutionSelector%=4;
    self.ResField.text = resolutionList[m_iResolutionSelector];
}

- (IBAction)loudSpeakerAction:(id)sender
{
    //g_pVideoCameraProcessor.m_iLoudSpeakerEnable = 1;
    
    [[RingCallAudioManager sharedInstance] EnableLoudSpeakerTheKing];
    
    [_ldSpeakerBtn setEnabled:false];
}



- (IBAction)EndCallAction:(id)endButton
{
    //[g_pVideoCameraProcessor CloseAllThreads];
    
    
    NSLog(@"Inside EndCall Button, is now disabled");
    
    /*
    //CVideoAPI::GetInstance()->UnInitializeMediaConnectivity();
    CVideoAPI::GetInstance()->StopAudioCall(200);
    CVideoAPI::GetInstance()->StopVideoCall(200);
    
    [[RingCallAudioManager sharedInstance] stopRecordAndPlayAudio];
    
    [self CloseAllThreads];
    
    
    [session stopRunning];
    [_ldSpeakerBtn setEnabled:true];
    
    //g_pVideoCameraProcessor.m_iLoudSpeakerEnable = 0;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        MyCustomImageView.image = nil;
        MyCustomImageView.frame = MyCustomView.bounds;
        [MyCustomView addSubview:MyCustomImageView];
        [MyCustomView setNeedsDisplay];
        
    }];
    
    [_startBtn setEnabled:YES];
     
    */
    
}

- (IBAction)ChangeTargetUserAction:(id)sender
{
    NSLog(@"%lf", [_rapidFireTimer timeInterval]) ;
    
    [_rapidFireTimer invalidate];
    
    if(m_brapidFireForTargetUserBtnHold == false)
        g_iTargetUser++;
    
    if(g_iTargetUser > 100)
        g_iTargetUser = 1;
    
    [self UpdateTargetUser];
    m_brapidFireForTargetUserBtnHold = false;
    
}




//List of Delegate Methods

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self animateTextField: textField up: YES];
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField: textField up: NO];
}

- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    const int movementDistance = 250; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



-(int)RenderImage:(UIImage *)uiImageToDraw
{
    
    
    @autoreleasepool {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            MyCustomImageView.image = uiImageToDraw;
            int iBoxHeight = MyCustomView.bounds.size.height; //320
            int iBoxWidth = MyCustomView.bounds.size.width; //240
            
            int iImageHeight = uiImageToDraw.size.height;
            int iImageWidth = uiImageToDraw.size.width;
            
            
            
           /* if(iBoxHeight<iBoxWidth)
            {
                float fRatio = MyCustomView.bounds.size.height / iImageHeight;
                
                float fOriginX, fOriginY;
                fOriginX = iBoxWidth/2.0 - iImageWidth * fRatio/2.0;
                fOriginY = 0.0;
                
                MyCustomImageView.frame = CGRectMake(fOriginX, fOriginY, iImageWidth * fRatio, iImageHeight * fRatio);
            }
            else
            {
               
                
                float fRatio = MyCustomView.bounds.size.width / iImageWidth;
                float fOriginX, fOriginY;
                fOriginX = iBoxWidth/2.0 - iImageWidth * fRatio/2.0;
                fOriginY = 0.0;
                
                MyCustomImageView.frame = CGRectMake(fOriginX, fOriginY, iImageWidth * fRatio, iImageHeight * fRatio);
            }*/
            
            
            MyCustomImageView.frame = CGRectMake(0, 0, iBoxWidth, iBoxHeight);
            
            
            [MyCustomView addSubview:MyCustomImageView];
            [MyCustomView setNeedsDisplay];
            [self CalculateFPS];
            [uiImageToDraw release];
            
        }];
        
        return 1; //Success
        
    }
}


- (IBAction)CheckCapabilityAction:(id)sender
{
    NSLog(@"Inside CheckCapabilityAction");
    
    string sLOG_PATH = "Device/log.txt";
    int iDEBUG_INFO = 1;
    if(CVideoAPI::GetInstance()->Init(100, sLOG_PATH.c_str(), iDEBUG_INFO) == 1)
    {
        printf("myVideoAPI Initialized\n");
    }
    else
    {
        printf("myVideoAPI is not Initialized\n");
    }
    
    
    int iRet = CVideoAPI::GetInstance()->CheckDeviceCapability(200, 640, 480,352,288);
    
    NSLog(@"Inside CheckCapabilityAction iRet = %d\n", iRet);
    //
    //[self CheckCapability:100 withHeight:640 withWidth:480 withCheckNumber:1];
    //
}


- (IBAction)startCallInLiveAction:(id)sender
{
    /*
    int role = CALL_NOT_RUNNING;
    
    if(g_iPort == 60001)
    {
        role = PUBLISHER_IN_CALL;
    }
    else
    {
        role = VIEWER_IN_CALL;
    }
    
    CVideoAPI::GetInstance()->StartCallInLive(200, role, CALL_IN_LIVE_TYPE_AUDIO_VIDEO);
    
     publisherinvite
     
     */
    
    int iRet = 0;
    NSString *nsTargetUser = [_targetUserField text];
    string sTargetUser = [nsTargetUser UTF8String];
    NSString *nsTargetAction = Operation[m_iOperationSelector];
    
    if([nsTargetAction  isEqual: @"Publish"])
    {
        CVideoAPI::GetInstance()->ProcessCommand("publisherinvite "+sTargetUser);
        //CVideoAPI::GetInstance()->StartCallInLive(200, PUBLISHER_IN_CALL, CALL_IN_LIVE_TYPE_AUDIO_VIDEO);
    }
    else if([nsTargetAction  isEqual: @"View"])
    {
        CVideoAPI::GetInstance()->ProcessCommand("viewerinvite "+sTargetUser);
        //CVideoAPI::GetInstance()->StartCallInLive(200, VIEWER_IN_CALL, CALL_IN_LIVE_TYPE_AUDIO_VIDEO);
    }
    
}

- (IBAction)SetFilterOnOffAction:(id)sender
{
    NSString *nsFilterOnString =  @"SetFilterOn";
    NSString *nsFilterOffString =  @"SetFilterOff";
    
    NSString *nsNow = [_FilterOnOffButton titleForState:UIControlStateNormal];
    NSLog(@"%@", nsNow);
    
    bool flag = [nsNow isEqualToString:nsFilterOnString];
    
    if(flag)
    {
        //CVideoAPI::GetInstance()->SetVideoEffect(200, 1);
        
        [_FilterOnOffButton setTitle:nsFilterOffString forState:UIControlStateNormal];
    }
    else
    {
        //CVideoAPI::GetInstance()->SetVideoEffect(200, 0);
        [_FilterOnOffButton setTitle:nsFilterOnString forState:UIControlStateNormal];
    }
    
    CVideoAPI::GetInstance()->SetBeautification(200, flag);
    //
}

- (IBAction)operationAction:(id)sender
{
    m_iOperationSelector++;
    m_iOperationSelector%=4;
    
    [[self operationBtn]  setTitle:Operation[m_iOperationSelector] forState:UIControlStateNormal];
}

- (void)SetCameraResolutionByNotification:(int)iHeight withWidth:(int)iWidth
{
    
    NSLog(@"Inside SetCameraResolutionByNotification %d, %d", iHeight, iWidth);
    
    m_iCameraHeight = iHeight;
    m_iCameraWidth  = iWidth;
    MyCustomImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, m_iCameraWidth, m_iCameraHeight)];
    
    /*[g_pVideoCameraProcessor InitializeCameraSession:&session
                                  withDeviceOutput:&videoDataOutput
                                         withLayer:&previewLayer
                                        withHeight:&m_iCameraHeight
                                         withWidth:&m_iCameraWidth];*/
    
    if(session != nil)
    {
        [session stopRunning];
        if(iHeight==352)
            [session setSessionPreset:AVCaptureSessionPreset352x288];
        if(iHeight == 640)
            [session setSessionPreset:AVCaptureSessionPreset640x480];
        
        [session startRunning];
    }
    
    
}

- (void)UpdateStatusMessage: (string)sMsg
{
    
    string param = "Status: "; // <-- input
    param+=sMsg;
    NSString* result = [NSString stringWithUTF8String:param.c_str()];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_statusMessage setText:result];
        [_statusMessage setFont:[UIFont systemFontOfSize:8]];
        [_statusMessage setTextColor:[UIColor colorWithRed:255 green:0 blue:0 alpha:255]];
        //[label setFont:[UIFont systemFontOfSize:9]];
    });
    
   
}
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    UITouch *touch1 = [touches anyObject];
    printf("TheKing--> Inside Here %d\n", [touch1 shouldGroupAccessibilityChildren]);
    /*
    CGPoint touchLocation = [touch1 locationInView:self.finalScore];
    CGRect startRect = [[[cup layer] presentationLayer] frame];
    CGRectContainsPoint(startRect, touchLocation);
    
    [UIView animateWithDuration:0.7
                          delay:0.0
                        options:UIViewAnimationCurveEaseOut
                     animations:^{cup.transform = CGAffineTransformMakeScale(1.25, 0.75);}
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:2.0
                                               delay:2.0
                                             options:0
                                          animations:^{cup.alpha = 0.0;}
                                          completion:^(BOOL finished) {
                                              [cup removeFromSuperview];
                                              cup = nil;}];
                     }];
    */
}

-(void)handleSingleTapforRemoteView:(UITapGestureRecognizer *)sender
{
    //here you can use sender.view to get the touched view
    float screenHeight, screenWidth;
    screenHeight = [[UIScreen mainScreen] bounds].size.height;
    screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    printf("TheKing--> Inside Here expandActivity, H:W --> %f:%f\n", screenHeight, screenWidth);
    
    if(myCustomUIViewState == 0)
    {
        CGRect newFrame = MyCustomView.frame;
        newFrame = CGRectMake( 0, 0, screenWidth, screenHeight);
        [MyCustomView setFrame:newFrame];
        
        [_myRealView bringSubviewToFront:MyCustomView];
        myCustomUIViewState = 1;
    }
    else
    {
        CGRect newFrame = MyCustomView.frame;
        newFrame = CGRectMake(myCustomUIViewLocationX, myCustomUIViewLocationY, myCustomUIViewWidth, myCustomUIViewHeight);
        [MyCustomView setFrame:newFrame];
        myCustomUIViewState = 0;
        
        
    }
    
}


-(void)handleSingleTapforOwnView:(UITapGestureRecognizer *)sender
{
    //here you can use sender.view to get the touched view
    float screenHeight, screenWidth;
    screenHeight = [[UIScreen mainScreen] bounds].size.height;
    screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    printf("TheKing--> Inside Here expandActivity, H:W --> %f:%f\n", screenHeight, screenWidth);
    if(selfUIViewState == 0)
    {
        CGRect newFrame = SelfView.frame;
        newFrame = CGRectMake( 0, 0, screenWidth, screenHeight);
        [SelfView setFrame:newFrame];
        
        [_myRealView bringSubviewToFront:SelfView];
        [self setupAVCapture];
        selfUIViewState = 1;
    }
    else
    {
        CGRect newFrame = SelfView.frame;
        newFrame = CGRectMake(selfUIViewLocationX, selfUIViewLocationY, selfUIViewWidth, selfUIViewHeight);
        [SelfView setFrame:newFrame];
        [self setupAVCapture];
        selfUIViewState = 0;
    }
    
}



- (void)dealloc
{
    [self teardownAVCapture];
    [helloText release];
    [MyCustomView release];
    [MyCustomImageView release];
    [MyCustomView release];
    [randomTextField release];
    [MyCustomView release];
    [SelfView release];
    [_LoginButton release]; //Login Button
    [_ChangeResBtn release];
    [_ResLabel release];
    [_ResField release];
    [_CheckCapabilityBtn release];
    [_statusMessage release];
    [_IPTextField release];
    [_myRealView release];
    [_ldSpeakerBtn release];
    [_startCallInLiveBtn release];
    [_FilterOnOffButton release];
    [_plusBtn release];
    [_minusBtn release];
    [_paramBtn release];
    [_paramValueLbl release];
    [_endCallBtn release];
    [_startBtn release];
    [_targetUserBtn release];
    [_targetUserField release];
    [_operationBtn release];
    [_Constraint_SelfView_Height release];
    [_Constraints_SelfView_Width release];
    [_Constraints_SelfView_LeftPadding release];
    [_Constraints_SelfView_TopPadding release];
    [_UserIDLabel release];
    [_resetBtn release];
    [super dealloc];
}

- (void)teardownAVCapture
{
    [videoDataOutput release];
    if (videoDataOutputQueue)
        dispatch_release(videoDataOutputQueue);
    [previewLayer removeFromSuperlayer];
    [previewLayer release];
}






- (IBAction)plusBtnAction:(id)sender
{
    if(m_iParamSelector == 0)
        params[m_iParamSelector]+=10;
    else
    {
        if(params[m_iParamSelector] == 0)
            params[m_iParamSelector] = 1;
        else
            params[m_iParamSelector] = 0;
    }
    
    
    [self UpdateValue];
}

- (IBAction)minusBtnAction:(id)sender
{
    if(m_iParamSelector == 0)
        params[m_iParamSelector]-=10;
    else
    {
        if(params[m_iParamSelector] == 0)
            params[m_iParamSelector] = 1;
        else
            params[m_iParamSelector] = 0;
    }
    
    [self UpdateValue];
}

- (IBAction)ParamBtnAction:(id)sender
{
    m_iParamSelector++;
    m_iParamSelector%=2;
    
    if(m_iParamSelector == 0) //Sigma
    {
        [_paramBtn setTitle:@"0->Sigma" forState:UIControlStateNormal];
    }
    else if(m_iParamSelector == 1) //Radius
    {
        [_paramBtn setTitle:@"1->SharpnessEnable" forState:UIControlStateNormal];
    }
    else if(m_iParamSelector == 2) //Div
    {
        [_paramBtn setTitle:@"2->Div" forState:UIControlStateNormal];
    }
    else if(m_iParamSelector == 3) //abcd
    {
        [_paramBtn setTitle:@"3->abcd" forState:UIControlStateNormal];
    }
    
    [self UpdateValue];
}

- (IBAction)resetBtnAction:(id)sender {
    CVideoAPI::GetInstance()->ProcessCommand("terminate-all");
    CVideoAPI::GetInstance()->UnInitializeMediaConnectivity();
    
    CVideoAPI::GetInstance()->StopAudioCall(200);
    CVideoAPI::GetInstance()->StopVideoCall(200);
    
    [[RingCallAudioManager sharedInstance] stopRecordAndPlayAudio];
    
    [self CloseAllThreads];
    
    
    [session stopRunning];
    [_ldSpeakerBtn setEnabled:true];
    
    //g_pVideoCameraProcessor.m_iLoudSpeakerEnable = 0;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        MyCustomImageView.image = nil;
        MyCustomImageView.frame = MyCustomView.bounds;
        [MyCustomView addSubview:MyCustomImageView];
        [MyCustomView setNeedsDisplay];
        
    }];
    
    
    NSString *nsServerIP = [_IPTextField text];
    string sServerIP = [nsServerIP UTF8String];
    CVideoAPI::GetInstance()->InitializeMediaConnectivity(sServerIP /*Server IP*/, 6060 /* Server Signaling Port*/, 1);
    
    
    
}

- (void)UpdateValue
{
    int value = params[m_iParamSelector];
    
    NSString *prefix=@"Value: ";
    NSString *newString = [prefix stringByAppendingFormat:@"%i", value];
    
    [_paramValueLbl setText:newString];
    
    CVideoAPI::GetInstance()->TestVideoEffect(200, params, 2);
    
}



//VideoTeam: Utility Functions
unsigned int timeGetTime()
{
    struct timeval now;
    gettimeofday(&now, NULL);
    return now.tv_sec * 1000 + now.tv_usec/1000;
}

void WriteToFile(byte *pData)
{
    
    if(counter == 1)
    {
        NSFileHandle *handle;
        NSArray *Docpaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [Docpaths objectAtIndex:0];
        NSString *filePathyuv = [documentsDirectory stringByAppendingPathComponent:@"NextDataCheck.yuv"];
        handle = [NSFileHandle fileHandleForUpdatingAtPath:filePathyuv];
        char *filePathcharyuv = (char*)[filePathyuv UTF8String];
        fpyuv = fopen(filePathcharyuv, "wb");
    }
    
    if(counter <= 500)
    {
        printf("Writing to yuv");
        fwrite(pData, 1, 352 * 288 * 3 /2, fpyuv);
    }

}

-(void) CalculateFPS
{
    
    if(timeGetTime() - iRenderCallTime >= 1000)
    {
        cout<<"\n\n\n--------->>>>>>>> FPS = ("<<iRenderFrameCount<<")\n\n\n";
        string sStatusMessage = "FPS = " + CVideoAPI::GetInstance()->IntegertoStringConvert(iRenderFrameCount);
        
        [self UpdateStatusMessage:sStatusMessage];
        
        iRenderFrameCount = 0;
        iRenderCallTime = timeGetTime();
        
    }
    iRenderFrameCount++;
}

- (int)InitializeAudioVideoEngineForCall
{
    //If We need Call
    
    int iRet;
    long long sessionID = 200;
    
    
    
    cout<<"Here height and width = "<<m_iCameraHeight<<", "<<m_iCameraWidth<<endl;
    
    std::string sDevice = getDeviceModel();
    int iDeviceCapability = 207;
    if(sDevice == "iPhone7,2")
    {
        iDeviceCapability = 205;
    }
    else if(sDevice == "iPod5,1")
    {
        iDeviceCapability = 208;
    }
    
    cout<<"Device Model --> "<<sDevice<<endl;
    
    CVideoAPI::GetInstance()->SetDeviceCapabilityResults(iDeviceCapability, 640, 480, 352, 288);

    iRet = CVideoAPI::GetInstance()->StartAudioCall(sessionID, SERVICE_TYPE_CALL, ENTITY_TYPE_CALLER, true);
    iRet = CVideoAPI::GetInstance()->StartVideoCall(sessionID, m_iCameraHeight, m_iCameraWidth, SERVICE_TYPE_CALL, ENTITY_TYPE_CALLER, /*NetworkType*/ 0, /*bIsAudioOnlyLive*/false);
    
    NSLog(@"StartVideoCaLL returned, iRet = %d", iRet);
    return iRet;
}

- (int)InitializeAudioVideoEngineForLive:(bool)isPublisher
{
    //If We need Live
    int iRet;
    long long sessionID = 200;
    
    if(isPublisher)
        iRet = CVideoAPI::GetInstance()->StartAudioCall(sessionID, SERVICE_TYPE_LIVE_STREAM, ENTITY_TYPE_PUBLISHER, true);
    else
        iRet = CVideoAPI::GetInstance()->StartAudioCall(sessionID, SERVICE_TYPE_LIVE_STREAM, ENTITY_TYPE_VIEWER, true);
    
    
    if(isPublisher)
        iRet = CVideoAPI::GetInstance()->StartVideoCall(sessionID,m_iCameraHeight, m_iCameraWidth, SERVICE_TYPE_LIVE_STREAM, ENTITY_TYPE_PUBLISHER, /*NetworkType*/ 0, /*bIsAudioOnlyLive*/false);
    else
        iRet = CVideoAPI::GetInstance()->StartVideoCall(sessionID,m_iCameraHeight, m_iCameraWidth, SERVICE_TYPE_LIVE_STREAM, ENTITY_TYPE_VIEWER, /*NetworkType*/ 0, /*bIsAudioOnlyLive*/false);
    
    return iRet;
}



- (void)StartAllThreads
{
    VideoThreadProcessor *pVideoThreadProcessor = [VideoThreadProcessor GetInstance];
    
    pVideoThreadProcessor.bRenderThreadActive = true;
    pVideoThreadProcessor.bEncodeThreadActive = true;
    pVideoThreadProcessor.bEventThreadActive = true;
    
    
    /*dispatch_queue_t EncoderQ = dispatch_queue_create("EncoderQ",DISPATCH_QUEUE_CONCURRENT);
     dispatch_async(EncoderQ, ^{
     [m_pVTP EncodeThread];
     });*/
    
    
    dispatch_queue_t RenderThreadQ = dispatch_queue_create("RenderThreadQ",DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(RenderThreadQ, ^{
        [[VideoThreadProcessor GetInstance] RenderThread];
    });
    
    dispatch_queue_t EventThreadQ = dispatch_queue_create("EventThreadQ",DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(EventThreadQ, ^{
        [[VideoThreadProcessor GetInstance] EventThread];
    });
}

- (void)CloseAllThreads
{
    VideoThreadProcessor *pVideoThreadProcessor = [VideoThreadProcessor GetInstance];
    
    pVideoThreadProcessor.bRenderThreadActive = false;
    pVideoThreadProcessor.bEncodeThreadActive = false;
    pVideoThreadProcessor.bEventThreadActive = false;
    
    //VideoSockets::GetInstance()->StopDataReceiverThread();
    //CVideoAPI::GetInstance()->StopVideoCallV(m_lUserId);
    //CVideoAPI::GetInstance()->ReleaseV();
    
}

- (int)UnInitializeAudioVideoEngine
{
    //CVideoAPI::GetInstance()->UnInitializeMediaConnectivity();
    CVideoAPI::GetInstance()->StopAudioCall(200);
    CVideoAPI::GetInstance()->StopVideoCall(200);
    
    return 1;
    
}
- (int)UnInitializeCameraAndMicrophone
{
    
    
    [[RingCallAudioManager sharedInstance] stopRecordAndPlayAudio];
    [_ldSpeakerBtn setEnabled:true];
    [session stopRunning];
    [session release];
    session = nil;
    
    
    //g_pVideoCameraProcessor.m_iLoudSpeakerEnable = 0;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        MyCustomImageView.image = nil;
        MyCustomImageView.frame = MyCustomView.bounds;
        [MyCustomView addSubview:MyCustomImageView];
        [MyCustomView setNeedsDisplay];
        
    }];
    
    return 1;
}


+(long long)convertStringIPtoLongLong:(NSString *)ipAddr
{
    struct in_addr addr;
    long long ip = 0;
    if (inet_aton([ipAddr UTF8String], &addr) != 0)
    {
        ip = addr.s_addr;
    }
    return ip;
}

- (void) UpdateUserID:(string)sValue
{
    @autoreleasepool {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSString* labelValue = [NSString stringWithUTF8String:sValue.c_str()];
            [_UserIDLabel setText:labelValue];
        }];
    }
    
    
}

- (void)targetBtnHoldDownAction
{
    NSLog(@"Inside Khashi");
    _rapidFireTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(rapidFireForTargetUserBtnHold) userInfo:nil repeats:YES];
}

- (void)rapidFireForTargetUserBtnHold
{
    m_brapidFireForTargetUserBtnHold = true;
    g_iTargetUser--;
    if(g_iTargetUser<1)
        g_iTargetUser = 100;
    
    [self UpdateTargetUser];
    
}

@end
