//
//  ExternalVideoProcessingViewController.m
//  TestCamera
//
//  Created by Rajib Chandra Das on 11/18/17.
//

#import "ExternalVideoProcessingViewController.h"


unsigned char h264Data[10000000];

@interface ExternalVideoProcessingViewController ()

@end

@implementation ExternalVideoProcessingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"TheKing--> Inside startThumbnailAction");
    if(CVideoAPI::GetInstance()->Init(100, "", 1) == 1)
    {
        printf("myVideoAPI Initialized\n");
    }
    else
    {
        printf("myVideoAPI is not Initialized\n");
    }
    
    MediatorClass *mediator =  [MediatorClass GetInstance];
    mediator.externalVideoProcessingDelegate = self;
    
    CVideoAPI::GetInstance()->StartExternalVideoProcessingSession();
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)plusBtnAction:(id)sender
{
    int x = [self.positionLabel.text intValue];
    x+=25;
    NSString *strFromInt = [NSString stringWithFormat:@"%d",x];
    [self.positionLabel setText:strFromInt];
    
    
}

- (IBAction)minusBtnAction:(id)sender
{
    int x = [self.positionLabel.text intValue];
    x-=25;
    NSString *strFromInt = [NSString stringWithFormat:@"%d",x];
    [self.positionLabel setText:strFromInt];
}

- (IBAction)startThumbnailAction:(id)sender
{
    //NSString *g_DataFile = [[NSBundle mainBundle] pathForResource:@"Dump_h264_annexb_cut" ofType:@"h264"];
    NSString *g_DataFile = [[NSBundle mainBundle] pathForResource:@"FileDump" ofType:@"h264"];
    
    std::string sFilePath = std::string([g_DataFile UTF8String]);
    NSLog(@"TheKing--> File Path = %s", sFilePath.c_str());
    
    FILE *filePointer = fopen(sFilePath.c_str(), "rb");
    
    long long  iTotalDataLen = [self GetDataLenFromFile:&filePointer];
    
    NSLog(@"TheKing--> iTotalDataLen = %i", iTotalDataLen);
    
    fread(h264Data, iTotalDataLen, 1, filePointer);
    int x = [self.positionLabel.text intValue];
    CVideoAPI::GetInstance()->SendH264EncodedDataToGetThumbnail(h264Data, iTotalDataLen, x);

}

-(long long)GetDataLenFromFile:(FILE **)fp
{
    long long i_size = 0;
    if (*fp != NULL)
    {
        if (!fseek(*fp, 0, SEEK_END))
        {
            i_size = ftell(*fp);
            fseek(*fp, 0, SEEK_SET);
        }
    }
    else
    {
        cout << "file open error\n";
    }
    return i_size;
}
-(void)ProcessBitmapData:(unsigned char *)pBitmapData withHeight:(int)iHeight withWidth:(int)iWidth withLen:(int)dataLen
{
    NSLog(@"TheKing--> ExternalVideoProcessingViewController Process Bitmap Data");
    char* rgba = (char*)malloc(iHeight*iWidth*4);
    int offset=0;
    for(int i=54; (i+3) < dataLen; i+=3)
    {
        rgba[offset++] = pBitmapData[i+2]; //B
        
        rgba[offset++] = pBitmapData[i+1]; //G
        
        rgba[offset++] = pBitmapData[i]; //R
        
        rgba[offset++] = 0; //Alpha
        
        
    }
    
    
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(
                                                       rgba,
                                                       iWidth,
                                                       iHeight,
                                                       8, // bitsPerComponent
                                                       4*iWidth, // bytesPerRow
                                                       colorSpace,
                                                       kCGImageAlphaNoneSkipLast);
    
    CFRelease(colorSpace);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
    
    free(rgba);
    
    UIImage *newUIImage = [UIImage imageWithCGImage:cgImage];
    
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        
        //self.imageView.frame = CGRectMake(0, 0, 100, 100);
        
        
        self.imageView.image = newUIImage;
        
        //[MyCustomView setNeedsDisplay];
        //[uiImageToDraw release];
    
    
    }];
    
    
}




- (void)dealloc {
    [_imageView release];
    [_plusBtn release];
    [_positionLabel release];
    [_minusBtn release];
    
    [super dealloc];
}
@end
