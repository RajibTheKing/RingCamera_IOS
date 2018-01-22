
#import <UIKit/UIKit.h>

#import "TestCameraAppDelegate.h"


int main(int argc, char *argv[])
{
	int retVal = 0;
	
    @autoreleasepool {
        NSLog(@"Inside main Function");
        
	    retVal = UIApplicationMain(argc, argv, nil, NSStringFromClass([TestCameraAppDelegate class]));
	}
	return retVal;
}
