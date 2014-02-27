//
//  MyScene.m
//  tubes
//
//  Created by Colin Milhench on 25/02/2014.
//  Copyright (c) 2014 Colin Milhench. All rights reserved.
//

#import "MyScene.h"
#import "SKNode+Debug.h"

/* Constants.h */
typedef enum : uint8_t {
    ColliderTypeNothing         = 0x1 << 1,
    ColliderTypeWall            = 0x1 << 2,
    ColliderTypePlayer          = 0x1 << 3,
    ColliderTypeCamera          = 0x1 << 4,
    ColliderTypeObsticle        = 0x1 << 5
} ColliderType;

#define CarminePink [SKColor colorWithRed:0xEB/255.0 green:0x5C/255.0 blue:0x40/255.0 alpha:1.0]
#define DeepLilac [SKColor colorWithRed:0x99/255.0 green:0x5A/255.0 blue:0xB7/255.0 alpha:1.0]
#define Peridot [SKColor colorWithRed:0xE8/255.0 green:0xDD/255.0 blue:0x00/255.0 alpha:1.0]

@implementation MyScene {
    SKNode *_world;
    SKNode *_camera;
    SKNode *_player;
    NSMutableArray *_contacts;
    CFTimeInterval _last;
    CGFloat _velocityZ;
    CGFloat _accelerationZ;
    int visible;
}

#pragma mark -
#pragma mark Initialization methods
#pragma mark -

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        
        _contacts = [NSMutableArray array];
        _accelerationZ = 50;
        _velocityZ = 10;
        
        [self createScene];
        
        self.physicsWorld.contactDelegate = self;
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        
        // DEBUG - While i'm not reading from user input
        [_camera.physicsBody applyImpulse:CGVectorMake(5, 5)];
        _camera.physicsBody.linearDamping = 0;
        _camera.physicsBody.restitution = 1;
        // /DEBUG
    }
    return self;
}

- (void)createScene {
    _world = [self createWorld];
    for (visible = 0; visible < 10; visible++) {
        [_world addChild:[self createHoopAtIndex:visible]];
    }
    [_world addChild:_camera = [self createCamera]];
    [_world addChild:[self createPlayer]];
    [self addChild:_world];
}

- (SKNode*)createWorld {
    // Create a container node with a position of negative half the width
    // and height so that we have give ouselves a cartesian grid system.
    CGRect rect = CGRectMake(self.size.width/-2, self.size.height/-2, self.size.width, self.size.height);
    SKNode *node = [SKNode node];
    node.position = CGPointMake(self.size.width/2, self.size.height/2);
    node.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect: rect];
    node.physicsBody.dynamic = NO; // unaffected by other physics bodies
    node.physicsBody.friction = 0;
    node.physicsBody.categoryBitMask = ColliderTypeWall;
    [node attachDebugRectWithSize:self.frame.size];
    return node;
}

- (SKNode*)createPlayer {
    CGSize size = CGSizeMake(20, 20);
    CGRect rect = CGRectMake(size.width/-2, size.height/-2,size.width, size.height);
    CGPathRef path = CGPathCreateWithRect(rect, nil);
    SKShapeNode *node = [SKShapeNode node];
    node.path = path;
    node.lineWidth = 0;
    node.fillColor = Peridot;
    node.position = CGPointMake(0, 0);
    node.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:size];
    node.physicsBody.dynamic = YES;
    node.physicsBody.affectedByGravity = NO;
    node.physicsBody.categoryBitMask = ColliderTypePlayer;
    node.physicsBody.collisionBitMask = 0;
    node.physicsBody.contactTestBitMask = ColliderTypeObsticle;  // get a callback
    [node attachDebugRectWithSize:size];
    CGPathRelease(path);
    return node;
}

- (SKNode*)createCamera {
    CGSize size = CGSizeMake(20, 20);
    SKNode *node = [SKNode node];
    node.position = CGPointMake(0, 0);
    node.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:size];
    node.physicsBody.dynamic = YES;
    node.physicsBody.affectedByGravity = NO;
    node.physicsBody.categoryBitMask = ColliderTypePlayer;
    node.physicsBody.collisionBitMask = ColliderTypeWall;
    [node attachDebugRectWithSize:size];
    return node;
}

- (SKNode*)createHoopAtIndex:(int)index {
    CGSize size = self.size;
    CGRect rect = CGRectMake(size.width/-2, size.height/-2,size.width, size.height);
    CGPathRef path = CGPathCreateWithRect(rect, nil);
    SKShapeNode *node = [SKShapeNode node];
    node.path = path;
    node.lineWidth = 1.0;
    node.fillColor = [SKColor colorWithRed:0xEA/255.0 green:0xEB/255.0 blue:0xEA/255.0 alpha:0.1];
    node.strokeColor = [SKColor colorWithRed:0xEA/255.0 green:0xEB/255.0 blue:0xEA/255.0 alpha:1.0];
    node.position = CGPointMake(0, 0);
    [node.userData setObject:[NSValue valueWithCGPoint:node.position] forKey:@"origin"];
    node.zPosition = -(50 * index);
    node.name = @"hoop";
    [self moveNode:node asSeenFrom:_camera withFocallength:50];
    CGPathRelease(path);
    // add one every 5, and each time you go past 10, add another
    // so that by the time you have gone past 50 - add one every 1
    if (index >= 50 || (index > 0 && index % (int)ceil(5 - index/10) == 0)) {
        int scale = 4;
        int i = arc4random() % (scale * scale);
        SKNode *obsticle = [self createObsticle:scale];
        CGFloat x = ((i/scale)+.5)*(size.width/scale);
        CGFloat y = ((i%scale)+.5)*(size.height/scale);
        obsticle.position = CGPointMake(size.width/-2 + x, size.height/-2 + y);
        [node addChild:obsticle];
    }
    return node;
}

- (SKNode*)createObsticle:(int)scale {
    CGSize size = CGSizeMake(self.size.width/scale, self.size.height/scale);
    CGRect rect = CGRectMake(size.width/-2, size.height/-2,size.width, size.height);
    CGPathRef path = CGPathCreateWithRect(rect, nil);
    SKShapeNode *node = [SKShapeNode node];
    node.path = path;
    node.lineWidth = 0;
    node.fillColor = CarminePink;
    node.position = CGPointMake(size.width*1.5, size.height*-1.5);
    node.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:size];
    node.physicsBody.dynamic = NO;
    node.physicsBody.affectedByGravity = NO;
    node.physicsBody.categoryBitMask = ColliderTypeNothing;
    [node attachDebugRectWithSize:size];
    CGPathRelease(path);
    return node;
}

- (void)moveNode:(SKNode*)node asSeenFrom:(SKNode*)camera withFocallength:(float)focallength {
    CGPoint origin = [[node.userData objectForKey:@"origin"] CGPointValue];
    CGFloat nodeZ = -node.zPosition;
    CGFloat cameraZ = -camera.zPosition;
    
    float scale = focallength / MAX(focallength + nodeZ - cameraZ, 0.000000001);
    node.position = CGPointMake(origin.x - camera.position.x * scale, origin.y - camera.position.y * scale);
    
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
#pragma mark Collision methods
#pragma mark -

-(void)didBeginContact:(SKPhysicsContact *)contact {
    if (contact.bodyA.categoryBitMask & ColliderTypePlayer
        && contact.bodyB.categoryBitMask & ColliderTypeObsticle) {
        SKNode *obsticle = contact.bodyB.node;
        [_contacts addObject:obsticle];
    }
}

-(void)didEndContact:(SKPhysicsContact *)contact {
    if (contact.bodyA.categoryBitMask & ColliderTypePlayer
        && contact.bodyB.categoryBitMask & ColliderTypeObsticle) {
        SKNode *obsticle = contact.bodyB.node;
        [_contacts removeObject:obsticle];
    }
}

#pragma mark -
#pragma mark Game loop
#pragma mark -

-(void)update:(CFTimeInterval)currentTime {
    if (_last == 0) _last = currentTime;
    CFTimeInterval elapsedSeconds = (currentTime - _last);
    
    // Accelerate
    if (_velocityZ < 250) {
        _velocityZ += (elapsedSeconds * _accelerationZ);
    }
    
    // Move
    _camera.zPosition -= (elapsedSeconds * _velocityZ);
    // TODO: read imput and apply force
    
    // Perspective
    [_world enumerateChildNodesWithName:@"hoop" usingBlock:^(SKNode *node, BOOL *stop) {
        [self moveNode:node asSeenFrom:_camera withFocallength:50];
        
        if (_camera.zPosition - node.zPosition <= 20) {
            for (int i=0; i< node.children.count; i++) {
                ((SKNode*)[node.children objectAtIndex:i]).physicsBody.categoryBitMask = ColliderTypeObsticle;
            }
        }
        
        if (node.xScale > 1.5) {
            [node removeFromParent];
            [_world addChild:[self createHoopAtIndex:++visible]];
        }
    }];
    
    // Collisions at this depts?
    for (int i = 0; i < _contacts.count; i++) {
        SKNode *obsticle = [_contacts objectAtIndex:i];
        CGFloat z = obsticle.parent.zPosition;
        if (_camera.zPosition - z <= 20) {
            NSLog(@"COLLISION");
            ((SKShapeNode *)obsticle).fillColor = DeepLilac;
        }
    }
    
    _last = currentTime;
}

@end
