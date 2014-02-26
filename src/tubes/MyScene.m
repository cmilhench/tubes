//
//  MyScene.m
//  tubes
//
//  Created by Colin Milhench on 25/02/2014.
//  Copyright (c) 2014 Colin Milhench. All rights reserved.
//

#import "MyScene.h"
#import "SKShapeNode3.h"

/* Constants.h */

#define CarminePink [SKColor colorWithRed:0xEB/255.0 green:0x5C/255.0 blue:0x40/255.0 alpha:1.0]
#define DeepLilac [SKColor colorWithRed:0x99/255.0 green:0x5A/255.0 blue:0xB7/255.0 alpha:1.0]

@implementation MyScene{
    SKShapeNode3 *_camera;
    CFTimeInterval _last;
    CGVector _velocity;
    CGFloat _velocityZ;
    CGVector _acceleration;
    CGFloat _accelerationZ;
    int visible;
}

#pragma mark -
#pragma mark Initialization methods
#pragma mark -

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        [self createScene];
    }
    return self;
}

- (void)createScene {
    _accelerationZ = 50;
    _velocityZ = 10;
    _velocity.dx = 150;
    _velocity.dy = 150;
    for (visible = 0; visible < 10; visible++) {
        [self addChild:[self createNodeWithIndex:visible]];
    }
    _camera = [self createCameraWithX:(self.size.width/2) Y:(self.size.height/2) Z:0];
    [self addChild:_camera];
}


- (SKShapeNode3 *)createCameraWithX:(float)x Y:(float)y Z:(float)z {
    CGRect rect = CGRectMake(-50/2, -50/2, 50, 50);
    CGPathRef path = CGPathCreateWithRect(rect, nil);
    SKShapeNode3 *node = [SKShapeNode3 node];
    node.path = path;
    node.lineWidth = 0;
    node.fillColor = [SKColor colorWithRed:0x00/255.0 green:0x00/255.0 blue:0xEA/255.0 alpha:1];
    node.z = z;
    node.position = CGPointMake(x, y);
    CGPathRelease(path);
    return node;
}

- (SKNode *)createNodeWithIndex:(int)index {
    float width = self.size.width;
    float height = self.size.height;
    CGRect rect = CGRectMake(-width/2, -height/2, width, height);
    CGPathRef path = CGPathCreateWithRect(rect, nil);
    SKShapeNode3 *node = [SKShapeNode3 node];
    node.path = path;
    node.lineWidth = 1.0;
    node.fillColor = [SKColor colorWithRed:0xEA/255.0 green:0xEB/255.0 blue:0xEA/255.0 alpha:0.1];
    node.strokeColor = [SKColor colorWithRed:0xEA/255.0 green:0xEB/255.0 blue:0xEA/255.0 alpha:1.0];
    node.position = CGPointMake((self.size.width/2), (self.size.height/2));
    [node.userData setObject:[NSValue valueWithCGPoint:node.position] forKey:@"origin"];
    node.z = 50 * index;
    node.zPosition = - node.z;
    node.name = @"particle";
    // add one every 5, and each time you go past 10, add another
    // so that by the time you have gone past 50 - add one every 1
    if (index >= 50 || (index > 0 && index % (int)ceil(5 - index/10) == 0)) {
        [node addChild:[self createOobstacleWithWidth:width/2 andHeight:height/2]];
    }
    [self moveNode:node asSeenFrom:_camera withFocallength:50];
    
    CGPathRelease(path);
    return node;
}

- (SKNode *)createOobstacleWithWidth:(float)width andHeight:(float)height {
    CGRect rect;
    int no = arc4random() % 5;
    switch (no) {
        case 0:
            rect = CGRectMake(0, 0, width, height);
            break;
        case 1:
            rect = CGRectMake(0, -height, width, height);
            break;
        case 2:
            rect = CGRectMake(-width, 0, width, height);
            break;
        case 3:
            rect = CGRectMake(-width, -height, width, height);
            break;
        default:
            rect = CGRectMake(-width/2, -height/4, width, height/2);
            break;
    }
    CGPathRef path = CGPathCreateWithRect(rect, nil);
    SKShapeNode *node = [SKShapeNode node];
    node.path = path;
    node.lineWidth = 0;
    node.fillColor = CarminePink;
    //node.strokeColor = DeepLilac;
    node.name = @"obstacle";
    CGPathRelease(path);
    return node;
}

- (void)moveNode:(SKShapeNode3*)node asSeenFrom:(SKShapeNode3*)camera withFocallength:(float)focallength {
    CGPoint origin = [[node.userData objectForKey:@"origin"] CGPointValue];
    origin.x += (self.size.width/2);
    origin.y += (self.size.height/2);
    CGPoint cartesian = CGPointMake(camera.position.x, camera.position.y);
    cartesian.x -= (self.size.width/2);
    cartesian.y -= (self.size.height/2);
    
    float scale = focallength / MAX(focallength + node.z - camera.z, 0.000000001);
    node.position = CGPointMake(origin.x - cartesian.x * scale, origin.y - cartesian.y * scale);
    node.xScale = scale;
    node.yScale = scale;
}

#pragma mark -
#pragma mark Touch methods
#pragma mark -

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}

#pragma mark -
#pragma mark Game methods
#pragma mark -

-(void)update:(CFTimeInterval)currentTime {
    if (_last == 0) _last = currentTime;
    CFTimeInterval elapsedSeconds = (currentTime - _last);
    
    // Bounce
    if (_camera.position.x < 0 || self.size.width < _camera.position.x ) _velocity.dx *= -1;
    if (_camera.position.y < 0 || self.size.height < _camera.position.y ) _velocity.dy *= -1;
    
    // Accelerate
    if (_velocityZ < 250) {
        _velocityZ += (elapsedSeconds * _accelerationZ);
    }
    _velocity.dx += (elapsedSeconds * _acceleration.dx);
    _velocity.dy += (elapsedSeconds * _acceleration.dy);
    
    // Move
    _camera.z += (elapsedSeconds * _velocityZ);
    _camera.position = CGPointMake(
        _camera.position.x + (elapsedSeconds * _velocity.dx),
        _camera.position.y + (elapsedSeconds * _velocity.dy)
    );
    
    [self enumerateChildNodesWithName:@"particle" usingBlock:^(SKNode *node, BOOL *stop) {
        [self moveNode:(SKShapeNode3 *)node asSeenFrom:_camera withFocallength:50];
        if (node.xScale > 1) {
            [node removeFromParent];
            [self addChild:[self createNodeWithIndex:++visible]];
        }
    }];
    
    _last = currentTime;
}

@end
