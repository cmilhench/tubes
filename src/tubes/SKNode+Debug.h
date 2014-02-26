//
//  SKNode+Debug
//  tubes
//
//  Created by Colin Milhench on 25/02/2014.
//  Copyright (c) 2014 Colin Milhench. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface SKNode (Debug)

- (void)attachDebugRectWithSize:(CGSize)size;

- (void)attachDebugFrameFromPath:(CGPathRef)path;

@end
