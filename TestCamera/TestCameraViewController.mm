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
#include "VideoCallProcessor.h"
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

//#include "InterfaceOfConnectivityEngine.h"

//#include "CustomPrintf.h"



#define USE_CANADA_SERVER

//#define printf(...)
//#define pthread_mutex_lock(...)
//#define pthread_mutex_unlock(...)

#define SSTR( x ) dynamic_cast< std::ostringstream & >( \
( std::ostringstream() << std::dec << x ) ).str()

//bool bStartVideoSending = false;

int iRenderCallTime = 0;
int iRenderFrameCount = 0;

int g_iFpsTime = 0;


string sMyId;
string sFrinedId;
int g_iMyId, g_iFriendId;

CMessageProcessor *pMessageProcessor = new CMessageProcessor();
VideoCallProcessor *g_pVideoCallProcessor;
VideoSockets *g_pVideoSockets;


int iTotalLengthPerSecond = 0;
int counter = 0;
FILE *fp = NULL;
FILE *fpyuv = NULL;

int g_iPort;

@implementation TestCameraViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //CInterfaceOfConnectivityEngine *m_pInterfaceOfConnectivityEngine = new CInterfaceOfConnectivityEngine();

    MyCustomImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, m_iCameraWidth, m_iCameraHeight)];
    //MyCustomImageView.transform = CGAffineTransformScale(MyCustomImageView.transform, -1.0, 1.0);
    
    [_LoginButton setEnabled:false];
    [_ServerCall setEnabled:false];
    
    
    _bP2PSocketInitialized = false;
    
    //g_pVideoSockets = [[VideoSockets alloc] init];
    
    //g_pVideoSockets = [VideoSockets GetInstance];
    g_pVideoSockets = VideoSockets::GetInstance();
    
    //### VideoTeam: Initialization Procedure...
  
    
    g_pVideoCallProcessor = [VideoCallProcessor GetInstance] /*[[VideoCallProcessor alloc] init]*/;
    
    g_pVideoCallProcessor.delegate = self;

    //End
    
    session = nil;
    
    [g_pVideoCallProcessor SetVideoSockets:g_pVideoSockets];
    
    [_PortField setEnabled:false];
    g_iPort = 60008;
    [self UpdatePort];
    [g_pVideoCallProcessor SetFriendPort:g_iPort];
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
    
    
    m_iParamSelector = 0;
    params[0] = 100; //Sigma
    params[1] = 5; //Radius
    params[2] = 8; //Den
    params[3] = 0;
    [self UpdateValue];
 
    int nMyCornerRadius = 10;
    
    self.P2PButton.layer.cornerRadius = nMyCornerRadius;
    self.ChangePort.layer.cornerRadius = nMyCornerRadius;
    self.ChangeResBtn.layer.cornerRadius = nMyCornerRadius;
    self.ldSpeakerBtn.layer.cornerRadius = nMyCornerRadius;
    
    self.CheckCapabilityBtn.layer.cornerRadius = nMyCornerRadius;
    self.startCallInLiveBtn.layer.cornerRadius = nMyCornerRadius;
    self.FilterOnOffButton.layer.cornerRadius = nMyCornerRadius;
    self.plusBtn.layer.cornerRadius = nMyCornerRadius;
    self.minusBtn.layer.cornerRadius = nMyCornerRadius;
    self.paramBtn.layer.cornerRadius = nMyCornerRadius;
    self.endCallBtn.layer.cornerRadius = nMyCornerRadius;
    
    
}

- (void)setupAVCapture
{
    
    CALayer *rootLayer;
    rootLayer = [SelfView layer];
    [rootLayer setMasksToBounds:YES];
    [previewLayer setFrame:[rootLayer bounds]];
    [rootLayer addSublayer:previewLayer];
    
}




- (IBAction) P2PButtonAction:(id)P2PButton
{
    /*
    long long lUserId = 200;
    [g_pVideoCallProcessor Initialize:lUserId];
     */
    if([self.ResField.text isEqual:@"640x480"])
    {
        m_iCameraHeight = 640;
        m_iCameraWidth = 480;
        
    }
    else
    {
        m_iCameraHeight = 352;
        m_iCameraWidth = 288;
        
        
        
    }
    
    g_pVideoCallProcessor.m_lCameraInitializationStartTime = CurrentTimeStamp();
    if(session == nil)
    {
        
        [g_pVideoCallProcessor InitializeCameraSession:&session
                                  withDeviceOutput:&videoDataOutput
                                         withLayer:&previewLayer
                                        withHeight:&m_iCameraHeight
                                         withWidth:&m_iCameraWidth];
        [self setupAVCapture]; //This Method is needed to Initialize Self View with Camera output
    }
    
    [session startRunning];
    
    
    long long lUserId  = 200;
    /*
    NSString *nsRemoteIp = @"192.168.57.113";
    string sRemoteIp([nsRemoteIp UTF8String]);
    InitializeSocketForRemoteUser(sRemoteIp);
    [g_pVideoCallProcessor SetRemoteIP:sRemoteIp];
    */
    
    int iRet = [g_pVideoCallProcessor Initialize:lUserId withServerIP: [_IPTextField text]];
    
    if(iRet == 0)
    {
        [session stopRunning];
    }
    
    [[RingCallAudioManager sharedInstance] startRecordAndPlayAudio];
    

    /*
    if(!_bP2PSocketInitialized)
    {
        printf("Rajib_Check: bindsocketToRemoteData initalization called\n");
        [g_pVideoSockets BindSocketToReceiveRemoteData];
        _bP2PSocketInitialized = true;
    }
    */
    
    //bStartVideoSending = true;
    
    g_pVideoCallProcessor.m_bStartVideoSending = true;
    
    [g_pVideoCallProcessor StartAllThreads];
    //[session startRunning];
    
    [_P2PButton setEnabled:NO];
     
    
    
    
}
- (void)UpdatePort
{
    g_iPort++;
    if(g_iPort>60008)
        g_iPort = 60001;
    if(g_iPort<60001)
        g_iPort = 60008;
    
    cout<<"Current FriendPort = "<<g_iPort<<endl;
    ostringstream oss;
    oss.clear();
    oss<<g_iPort;
    string sPort = oss.str();
    
    self.PortField.text = @(sPort.c_str());
}

- (IBAction)ChangeResBtnAction:(id)sender
{
    cout<<"TheKing--> Inside ChangeResAction"<<endl;
    NSString *nsRes = self.ResField.text;
    if([nsRes isEqual: @"640x480"])
    {
        cout<<"Setting to Low Resolution"<<endl;
        self.ResField.text = @"352x288";
    }
    else
    {
        cout<<"Setting to High Resolution"<<endl;
        self.ResField.text = @"640x480";
    }
}

- (IBAction)loudSpeakerAction:(id)sender
{
    g_pVideoCallProcessor.m_iLoudSpeakerEnable = 1;
    [_ldSpeakerBtn setEnabled:false];
}
- (IBAction)ChangePort:(id)sender
{
    [self UpdatePort];
    
    [g_pVideoCallProcessor SetFriendPort:g_iPort];

    
}

//bool flagggg = false;

- (IBAction)LoginButtonAction:(id)loginButton
{
    std::set<int>st;
    int xyz = *st.begin();
    printf("maksud------------->%d\n",xyz);

    NSString *nsRemoteIp = _remoteIPTextField.text;
    string sRemoteIp([nsRemoteIp UTF8String]);
    //InitializeSocketForRemoteUser(sRemoteIp);
    
    NSLog(@"Inside Login Button");
    
    int iMyId = [_myIdTextField.text integerValue];
    cout<<"Got MyID = "<<iMyId<<endl;
    
    int iFriendId = [_friendIdTextField.text integerValue];
    cout<<"Got MyID = "<<iFriendId<<endl;
    
    g_iMyId = iMyId;
    g_iFriendId = iFriendId;

    [g_pVideoCallProcessor SetFriendId:g_iFriendId];
    sMyId = SSTR(iMyId);
    sFrinedId = SSTR(iFriendId);
    
#ifndef USE_CANADA_SERVER
    int iLength = 1 + 4 + sMyId.size();
    
    byte* message = (byte*)malloc(iLength);
    
    pMessageProcessor->prepareLoginRequestMessage(sMyId, message);
    
    
    SendPacket(message, iLength);
#else
    
    cout<<"Call_Response Message_Found"<<endl;
    int iLength = 1 + 1 + sMyId.size() + 1 + sFrinedId.size();
    byte* message = (byte*)malloc(iLength);
    
    pMessageProcessor->prepareLoginRequestMessageR(sMyId, sFrinedId, message);
    
    VideoSockets::GetInstance()->SendToVideoSocket(message, iLength);
    
    [g_pVideoCallProcessor Initialize:g_iMyId];
    
#endif
    
}


- (IBAction)StartCallAction:(id)startButton
{
    
    NSString *nsRemoteIp = _remoteIPTextField.text;
    string sRemoteIp([nsRemoteIp UTF8String]);
    //InitializeSocketForRemoteUser(sRemoteIp);
    
    NSLog(@"Inside Login Button");
    
    int iMyId = [_myIdTextField.text integerValue];
    cout<<"Got MyID = "<<iMyId<<endl;
    
    int iFriendId = [_friendIdTextField.text integerValue];
    cout<<"Got MyID = "<<iFriendId<<endl;
    
    g_iMyId = iMyId;
    g_iFriendId = iFriendId;
    
    
    sMyId = SSTR(iMyId);
    sFrinedId = SSTR(iFriendId);
    
    cout<<"Call_Response Message_Found"<<endl;
    int iLength = 1 + 1 + sMyId.size() + 1 + sFrinedId.size();
    byte* message = (byte*)malloc(iLength);
    
    /*
    pMessageProcessor->prepareLoginRequestMessageR(sMyId, sFrinedId, message);
    
    SendToVideoSocket(message, iLength);
    */
    
    g_pVideoCallProcessor.m_bStartVideoSending = true;
    //[g_pVideoCallProcessor Initialize:g_iMyId];
    [g_pVideoCallProcessor StartAllThreads];
    //[self StartCameraSession];
    [session startRunning];
    [[RingCallAudioManager sharedInstance] startRecordAndPlayAudio];
}



- (IBAction)EndCallAction:(id)endButton
{
    //[g_pVideoCallProcessor CloseAllThreads];
    
    
    NSLog(@"Inside EndCall Button");
    CVideoAPI::GetInstance()->StopAudioCall(200);
    CVideoAPI::GetInstance()->StopVideoCall(200);
    
    [[RingCallAudioManager sharedInstance] stopRecordAndPlayAudio];
    
    [g_pVideoCallProcessor CloseAllThreads];
    
    
    [session stopRunning];
    [_ldSpeakerBtn setEnabled:true];
    g_pVideoCallProcessor.m_iLoudSpeakerEnable = 0;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        MyCustomImageView.image = nil;
        MyCustomImageView.frame = MyCustomView.bounds;
        [MyCustomView addSubview:MyCustomImageView];
        [MyCustomView setNeedsDisplay];
        
    }];
    
    [_P2PButton setEnabled:YES];
     
    
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
            CalculateFPS();
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
    int role = CALL_NOT_RUNNING;
    
    if(g_iPort == 60001)
    {
        role = PUBLISHER_IN_CALL;
    }
    else
    {
        role = VIEWER_IN_CALL;
    }
    CVideoAPI::GetInstance()->StartCallInLive(200, role);
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
        CVideoAPI::GetInstance()->SetVideoEffect(200, 1);
        [_FilterOnOffButton setTitle:nsFilterOffString forState:UIControlStateNormal];
    }
    else
    {
        CVideoAPI::GetInstance()->SetVideoEffect(200, 0);
        [_FilterOnOffButton setTitle:nsFilterOnString forState:UIControlStateNormal];
    }
    
    
    //
}

- (void)SetCameraResolutionByNotification:(int)iHeight withWidth:(int)iWidth
{
    
    NSLog(@"Inside SetCameraResolutionByNotification %d, %d", iHeight, iWidth);
    
    m_iCameraHeight = iHeight;
    m_iCameraWidth  = iWidth;
    MyCustomImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, m_iCameraWidth, m_iCameraHeight)];
    
    /*[g_pVideoCallProcessor InitializeCameraSession:&session
                                  withDeviceOutput:&videoDataOutput
                                         withLayer:&previewLayer
                                        withHeight:&m_iCameraHeight
                                         withWidth:&m_iCameraWidth];*/
    
    
    [session stopRunning];
    
    if(iHeight==352)
        [session setSessionPreset:AVCaptureSessionPreset352x288];
    if(iHeight == 640)
        [session setSessionPreset:AVCaptureSessionPreset640x480];
    
    [session startRunning];
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
    [_myIdTextField release];
    [_friendIdTextField release];
    [_remoteIPTextField release];
    [_P2PButton release]; //StartCall Button
    [SelfView release];
    [_LoginButton release]; //Login Button
    [_ServerCall release];
    [_ChangePort release];
    [_PortField release];
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
        params[m_iParamSelector]++;
    
    
    [self UpdateValue];
    //CVideoAPI::GetInstance()->TestVideoEffect(200, params, 3);
}

- (IBAction)minusBtnAction:(id)sender
{
    if(m_iParamSelector == 0)
        params[m_iParamSelector]-=10;
    else
        params[m_iParamSelector]--;
    
    if(params[m_iParamSelector] < 0)
        params[m_iParamSelector] = 0;
    
    [self UpdateValue];
    //CVideoAPI::GetInstance()->TestVideoEffect(200, params, 3);
}

- (IBAction)ParamBtnAction:(id)sender
{
    m_iParamSelector++;
    m_iParamSelector%=4;
    
    if(m_iParamSelector == 0) //Sigma
    {
        [_paramBtn setTitle:@"0->Sigma" forState:UIControlStateNormal];
    }
    else if(m_iParamSelector == 1) //Radius
    {
        [_paramBtn setTitle:@"1->Radius" forState:UIControlStateNormal];
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

- (void)UpdateValue
{
    int value = params[m_iParamSelector];
    
    NSString *prefix=@"Value: ";
    NSString *newString = [prefix stringByAppendingFormat:@"%i", value];
    
    [_paramValueLbl setText:newString];
    
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

void CalculateFPS()
{
    
    if(timeGetTime() - iRenderCallTime >= 1000)
    {
        cout<<"\n\n\n--------->>>>>>>> FPS = ("<<iRenderFrameCount<<")\n\n\n";
        string sStatusMessage = "FPS = " + CVideoAPI::GetInstance()->IntegertoStringConvert(iRenderFrameCount);
        [[VideoCallProcessor GetInstance] UpdateStatusMessage:sStatusMessage];
        
        iRenderFrameCount = 0;
        iRenderCallTime = timeGetTime();
        
    }
    iRenderFrameCount++;
}

@end
