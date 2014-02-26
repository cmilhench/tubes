//
//  SKNode+Debug
//  tubes
//
//  Created by Colin Milhench on 25/02/2014.
//  Copyright (c) 2014 Colin Milhench. All rights reserved.
//

#import "SKNode+Debug.h"

#define MayaBlue [SKColor colorWithRed:0x87/255.0 green:0xB9/255.0 blue:0xFF/255.0 alpha:1.0]

static BOOL kDebugDraw = YES;

@implementation SKNode (Debug)

- (void)attachDebugRectWithSize:(CGSize)size
{
    CGRect pathRect = CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height);
    CGPathRef path = CGPathCreateWithRect(pathRect ,nil);
    NSLog(@"%fx%f", size.width, size.height);
    [self attachDebugFrameFromPath:path];
    CGPathRelease(path);
}

- (void)attachDebugFrameFromPath:(CGPathRef)path
{
    if (kDebugDraw == NO) return;
    
    SKShapeNode *shape = [SKShapeNode node];
    shape.path = path;
    shape.strokeColor = MayaBlue;
    shape.lineWidth = 1.0;
    
    [self addChild:shape];
}

@end
