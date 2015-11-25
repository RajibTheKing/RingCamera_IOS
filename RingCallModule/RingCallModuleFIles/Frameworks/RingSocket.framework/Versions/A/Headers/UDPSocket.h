//
//  UDPSocket.h
//  UDPSocket
//
//  Created by Mac-4 on 3/11/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for UDPSocket.
FOUNDATION_EXPORT double UDPSocketVersionNumber;

//! Project version string for UDPSocket.
FOUNDATION_EXPORT const unsigned char UDPSocketVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <UDPSocket/PublicHeader.h>

#import "Socket.h"

@interface UDPSocket : Socket
{
    int p;
}

+		newWithPort: (int)port;

-		init;
-		initWithPort: (int)port;

- (NSData *)	send: (NSData *)data toHost: (NSString *)host Port: (int)port;
- (NSData *)	receiveFrom: (NSString **)host Port: (int *)port Size: (int)sz;
- (void)        bindPortIfNeeded;
- (void)reinitializeSocket;
@end
