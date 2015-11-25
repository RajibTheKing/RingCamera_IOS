//
//  IDCallSignalBuffer.m
//  ringID
//
//  Created by Md Shahinur Rahman on 12/24/14.
//
//

#define BUFFER_SIZE 100
#import "IDCallSignalBuffer.h"

@implementation IDCallSignalBuffer
@synthesize callList;


+ (id)sharedInstance {
    
    static id sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}



- (id)init
{
    self = [super init];
    if(self)
    {
        self.callList = [[[NSMutableDictionary alloc] init] autorelease];
        _count = 0;
    }
    return self;
}

- (void)dealloc
{
    self.callList = nil;
    [super dealloc];
}

- (void)enqueue:(id)anObject forKey:(id)key
{
    if (self.count == BUFFER_SIZE) {
        [self dequeue];
    }
    if (key != nil && anObject != nil) {
        [self.callList setObject:anObject forKey:key];
        self.count = self.callList.count;
    }
}

- (void)dequeueForKey:(id)key
{
    if(self.callList.count > 0)
    {
        if ([[self.callList allKeys] containsObject:key]) {
            // contains  key
            [self.callList removeObjectForKey:key];
        }
//        [self.callList removeObjectForKey:key];
        self.count = self.callList.count;
    }
}


- (void)dequeueForIndex:(NSInteger) index
{
    if(self.callList.count > 0)
    {
        if ([[self.callList allKeys] containsObject:[[self.callList allKeys] objectAtIndex:index]]) {
            // contains  key
            [self.callList removeObjectForKey:[[self.callList allKeys] objectAtIndex:index]];
        }
//        [self.callList removeObjectForKey:[[self.callList allKeys] objectAtIndex:index]];
        self.count = self.callList.count;
    }
}


- (void)dequeue
{
    //id obj = nil;
    if(self.callList.count > 0)
    {
        if ([[self.callList allKeys] containsObject:[[self.callList allKeys] firstObject]]) {
            // contains  key
            [self.callList removeObjectForKey:[[self.callList allKeys] firstObject]];
        }
//        [self.callList removeObjectForKey:[[self.callList allKeys] firstObject]];
        self.count = self.callList.count;
    }
    //return obj;
}

- (void)clear
{
    [self.callList removeAllObjects];
    self.count = 0;
}

//-(id) getIncommingCallDTOByIndex:(NSInteger) index
//{
//    id obj = nil;
//    if(self.callList.count > 0 && self.callList.count >= index)
//    {
//        obj = [[[self.callList objectAtIndex:index]retain] autorelease];
//    }
//    return obj;
//}

@end