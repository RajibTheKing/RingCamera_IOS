//
//  NSMutableArray+QueueAdditions.h
//  ringID
//
//  Created by Mac2 on 10/20/14.
//
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (QueueAdditions)
- (id) pull;
- (void) push:(id)obj;
@end
