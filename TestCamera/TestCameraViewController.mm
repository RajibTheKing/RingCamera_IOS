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
    
    [_LoginButton setEnabled:false];
    [_ServerCall setEnabled:false];
    
    
    _bP2PSocketInitialized = false;
    
    //g_pVideoSockets = [[VideoSockets alloc] init];
    
    g_pVideoSockets = [VideoSockets GetInstance];
    
    //### VideoTeam: Initialization Procedure...
  
    
    g_pVideoCallProcessor = [VideoCallProcessor GetInstance] /*[[VideoCallProcessor alloc] init]*/;
    
    g_pVideoCallProcessor.delegate = self;

    //End
    
    [g_pVideoCallProcessor SetVideoSockets:g_pVideoSockets];
    
    [_PortField setEnabled:false];
    g_iPort = 60008;
    [self UpdatePort];
    [g_pVideoCallProcessor SetFriendPort:g_iPort];
    
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
    
    g_pVideoCallProcessor.m_lCameraInitializationStartTime = GetTimeStamp();
    
    [g_pVideoCallProcessor InitializeCameraSession:&session
                                  withDeviceOutput:&videoDataOutput
                                         withLayer:&previewLayer
                                        withHeight:&m_iCameraHeight
                                         withWidth:&m_iCameraWidth];
    [self setupAVCapture]; //This Method is needed to Initialize Self View with Camera output
    [session startRunning];
    
    
    long long lUserId  = 200;
    NSString *nsRemoteIp = _remoteIPTextField.text;
    string sRemoteIp([nsRemoteIp UTF8String]);
    
    InitializeSocketForRemoteUser(sRemoteIp);
    
    [g_pVideoCallProcessor SetRemoteIP:sRemoteIp];
    
    [g_pVideoCallProcessor Initialize:lUserId];
    
    
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
    
    SendToVideoSocket(message, iLength);
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
    CVideoAPI::GetInstance()->StopVideoCall(200);
    [[RingCallAudioManager sharedInstance] stopRecordAndPlayAudio];
    [g_pVideoCallProcessor CloseAllThreads];
    
    
    [session stopRunning];
    
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
            int iBoxHeight = MyCustomView.bounds.size.height;
            int iBoxWidth = MyCustomView.bounds.size.width;
            
            int iImageHeight = uiImageToDraw.size.height;
            int iImageWidth = uiImageToDraw.size.width;
            
            
            
            if(iBoxHeight<iBoxWidth)
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
            }
            
            
            
            
            
            [MyCustomView addSubview:MyCustomImageView];
            [MyCustomView setNeedsDisplay];
            CalculateFPS();
            [uiImageToDraw release];
            
        }];
        
        return 1; //Success
    }
}

- (void)ReinitializeCameraFromViewController:(int)iHeight withWidth:(int)iWidth
{
    cout<<"Re-initializing Camera From ViewController";
    
    //[session stopRunning];
    //m_iCameraHeight = 352;
    //m_iCameraWidth = 288;
    
    m_iCameraHeight = iHeight;
    m_iCameraWidth = iWidth;
    
    
    //CVideoAPI::GetInstance()->StopVideoCall(200);
    
    //CVideoAPI::GetInstance()->StartVideoCall(200, m_iCameraHeight, m_iCameraWidth);
    
    
    
    MyCustomImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, m_iCameraWidth, m_iCameraHeight)];
    
    
    /*[g_pVideoCallProcessor InitializeCameraSession:&session
                                  withDeviceOutput:&videoDataOutput
                                         withLayer:&previewLayer
                                        withHeight:&m_iCameraHeight
                                         withWidth:&m_iCameraWidth];*/
    
    
    if(iHeight==352)
        [session setSessionPreset:AVCaptureSessionPreset352x288];
    if(iHeight == 640)
        [session setSessionPreset:AVCaptureSessionPreset640x480];
    
    [session startRunning];
}


- (IBAction)CheckCapabilityAction:(id)sender
{
    NSLog(@"Inside CheckCapabilityAction");
    
    [self CheckCapability:200 withHeight:640 withWidth:480 withCheckNumber:1];
    
}

- (void)CheckCapabilityAgain
{
    [self CheckCapability:200 withHeight:352 withWidth:288 withCheckNumber:2];
}

- (void)CheckCapability:(long long)llFriendId withHeight:(int)iHeight withWidth:(int)iWidth withCheckNumber:(int)iCheckNumber
{
    cout<<"Inside CheckCapability function iCheckNumber = "<<iCheckNumber<<endl;
    //CVideoAPI::GetInstance()->StopVideoCall(200);
    
    
    m_iCameraHeight = iHeight;
    m_iCameraWidth = iWidth;
    
    if(iCheckNumber == 1)
    {
        [g_pVideoCallProcessor InitializeCameraSession:&session
                                      withDeviceOutput:&videoDataOutput
                                             withLayer:&previewLayer
                                            withHeight:&m_iCameraHeight
                                             withWidth:&m_iCameraWidth];
        
        
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
        
        string sAppSessionId = "12345678";
        int iFriendPort = 60001;
        
        NSString *nsServerIP =  @"38.127.68.60"/*@"192.168.57.151"*/;
        int iRet;
        
        //iRet = (int)CVideoAPI::GetInstance()->CreateSession(llFriendId, (int)1/*Audio*/,  [VideoCallProcessor convertStringIPtoLongLong:nsServerIP], llFriendId);
        //iRet = (int)CVideoAPI::GetInstance()->CreateSession(llFriendId, (int)2/*Video*/,  [VideoCallProcessor convertStringIPtoLongLong:nsServerIP], llFriendId);
        //CVideoAPI::GetInstance()->SetRelayServerInformation(200, (int)1/*Audio*/,  [VideoCallProcessor convertStringIPtoLongLong:nsServerIP], iFriendPort);
        //CVideoAPI::GetInstance()->SetRelayServerInformation(200, (int)2/*Video*/,  [VideoCallProcessor convertStringIPtoLongLong:nsServerIP], iFriendPort);
    
        iRet = CVideoAPI::GetInstance()->CheckDeviceCapability(200, m_iCameraHeight, m_iCameraWidth);
        
        [session startRunning];
    }
    else if(iCheckNumber == 2)
    {
        CVideoAPI::GetInstance()->CheckDeviceCapability(200, m_iCameraHeight, m_iCameraWidth);
        MyCustomImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, m_iCameraWidth, m_iCameraHeight)];
        [session setSessionPreset:AVCaptureSessionPreset352x288];
        [session startRunning];
    }
    
    //[session stopRunning];

    //CVideoAPI::GetInstance()->StopVideoCall(200);
    
    //CVideoAPI::GetInstance()->StartVideoCall(200, m_iCameraHeight, m_iCameraWidth);
    
    //MyCustomImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, m_iCameraWidth, m_iCameraHeight)];
    
    //[session setSessionPreset:AVCaptureSessionPreset352x288];
    
    //[session startRunning];
    
    
    
}
-(void)StopCheckCapability
{
    [session stopRunning];
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
        iRenderFrameCount = 0;
        iRenderCallTime = timeGetTime();
        
    }
    iRenderFrameCount++;
}

long long GetTimeStamp()
{
    namespace sc = std::chrono;
    auto time = sc::system_clock::now(); // get the current time
    auto since_epoch = time.time_since_epoch(); // get the duration since epoch
    // I don't know what system_clock returns
    // I think it's uint64_t nanoseconds since epoch
    // Either way this duration_cast will do the right thing
    auto millis = sc::duration_cast<sc::milliseconds>(since_epoch);
    long long now = millis.count(); // just like java (new Date()).getTime();
    return now;
}

@end
