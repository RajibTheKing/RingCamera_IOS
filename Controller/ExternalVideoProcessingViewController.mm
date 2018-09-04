//
//  ExternalVideoProcessingViewController.m
//  TestCamera
//
//  Created by Rajib Chandra Das on 11/18/17.
//

#import "ExternalVideoProcessingViewController.h"
#include "VideoEffectsTest.h"
#include "VideoBeautificationerTest.h"
unsigned char h264Data[10000000];

@interface ExternalVideoProcessingViewController ()

@end

@implementation ExternalVideoProcessingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    int arr[100];
    printf("TheKig--> size of array = %d\n", sizeof(arr));
    
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
    
    //CVideoAPI::GetInstance()->StartExternalVideoProcessingSession();
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
    //sFilePath+="Error";
    NSLog(@"TheKing--> File Path = %s", sFilePath.c_str());
    int x = [self.positionLabel.text intValue];
    
    /*
    FILE *filePointer = fopen(sFilePath.c_str(), "rb");
    
    long long  iTotalDataLen = [self GetDataLenFromFile:&filePointer];
    
    NSLog(@"TheKing--> iTotalDataLen = %i", iTotalDataLen);
    
    fread(h264Data, iTotalDataLen, 1, filePointer);
    
    CVideoAPI::GetInstance()->SendH264EncodedDataToGetThumbnail(h264Data, iTotalDataLen, x);
    */
    
    //CVideoAPI::GetInstance()->SendH264EncodedDataFilePathToGetThumbnail(sFilePath, x);
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
    
    [_filterCheck release];
    [super dealloc];
}
- (IBAction)filterCheckAction:(id)sender
{
    CVideoEffectsTest *videoEffectTest = new CVideoEffectsTest();
    
    
    NSString *dataFile = [[NSBundle mainBundle] pathForResource:@"House2_640x360" ofType:@"yuv"];
    NSLog(@"%@",dataFile);
    std::string filePath = std::string([dataFile UTF8String]);
    
    //std::string filePath = "/Users/RajibTheKing/Downloads/liveNew.h264";
    FILE *fpInputFile = fopen(filePath.c_str(), "rb");
    int iHeight = 360;
    int iWidth = 640;
   
    unsigned char inputData[640*480*3/2];
    unsigned char temp[640*480*3/2];
    
    fread(inputData, 1, iHeight*iWidth*3/2, fpInputFile);
    
    
    CVideoBeautificationerTest *beautifyTest = new CVideoBeautificationerTest(iHeight, iWidth, 2);
    
    NSFileHandle *handle;
    NSArray *Docpaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [Docpaths objectAtIndex:0];
    
    NSString *filePathyuv = [documentsDirectory stringByAppendingPathComponent:@"House2_640x360_Sketch_Gray.yuv"];
    char *filePathcharyuv = (char*)[filePathyuv UTF8String];
    FILE *fpOutputFile1 = fopen(filePathcharyuv, "wb");
    
    NSString *filePathyuv2 = [documentsDirectory stringByAppendingPathComponent:@"House2_640x360_Sketch_White.yuv"];
    char *filePathcharyuv2 = (char*)[filePathyuv2 UTF8String];
    FILE *fpOutputFile2 = fopen(filePathcharyuv2, "wb");
    
    NSString *filePathyuv3 = [documentsDirectory stringByAppendingPathComponent:@"House2_640x360_beautify.yuv"];
    char *filePathcharyuv3 = (char*)[filePathyuv3 UTF8String];
    FILE *fpOutputFile3 = fopen(filePathcharyuv3, "wb");
    
    
    
    memcpy(temp, inputData, iHeight * iWidth * 3 / 2);
    videoEffectTest->PencilSketchGrayEffect(temp, iHeight, iWidth);
    fwrite(temp, 1, iHeight*iWidth*3/2, fpOutputFile1);
    
    memcpy(temp, inputData, iHeight * iWidth * 3 / 2);
    videoEffectTest->PencilSketchWhiteEffect(temp, iHeight, iWidth);
    fwrite(temp, 1, iHeight*iWidth*3/2, fpOutputFile2);
    
    
    memcpy(temp, inputData, iHeight * iWidth * 3 / 2);
    beautifyTest->BeautificationFilterNew(temp, iHeight*iWidth*3/2, iHeight, iWidth, iHeight, iWidth, true);
    fwrite(temp, 1, iHeight*iWidth*3/2, fpOutputFile3);
    
    
    fclose(fpInputFile);
    fclose(fpOutputFile1);
    fclose(fpOutputFile2);
    fclose(fpOutputFile3);
    
    NSLog(@"File Write Done");
    
    
    
    
    
    
    
    
}
@end
