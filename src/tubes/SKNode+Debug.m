//
//  SKNode+Debug
//  tubes
//
//  Created by Colin Milhench on 25/02/2014.
//  Copyright (c) 2014 Colin Milhench. All rights reserved.
//

#import "SKNode+Debug.h"

static BOOL kDebugDraw = NO;

@implementation SKNode (Debug)

- (void)attachDebugRectWithSize:(CGSize)size
{
    CGRect pathRect = CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height);
    CGPathRef path = CGPathCreateWithRect(pathRect ,nil);
    [self attachDebugFrameFromPath:path];
    CGPathRelease(path);
}

- (void)attachDebugFrameFromPath:(CGPathRef)path
{
    if (kDebugDraw == NO) return;
    
    SKShapeNode *shape = [SKShapeNode node];
    shape.path = path;
    shape.strokeColor = [SKColor colorWithRed:0xFF/255.0 green:0x00/255.0 blue:0x00/255.0 alpha:1.0];
    shape.lineWidth = 1.0;
    
    [self addChild:shape];
}

@end
