//
//  IDCallSignalBuffer.h
//  ringID
//
//  Created by Md Shahinur Rahman on 12/24/14.
//
//

#import <Foundation/Foundation.h>

@interface IDCallSignalBuffer : NSObject

+ (IDCallSignalBuffer *) sharedInstance;

- (void)enqueue:(id)anObject forKey:(id)key;
- (void)dequeueForKey:(id)key;
- (void)dequeueForIndex:(NSInteger) index;
- (void)dequeue;
- (void)clear;

@property (nonatomic, assign) NSInteger count;
@property (nonatomic, strong) NSMutableDictionary *callList;

@end
