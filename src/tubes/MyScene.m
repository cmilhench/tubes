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
    int _visibility;
    int _hoops;
    CGFloat _hitpoints;
    CGFloat _maxhealth;
    CFTimeInterval _elapsedTotal;
    SKLabelNode* _scoreLabel;
    SKLabelNode* _healthLabel;
}

#pragma mark -
#pragma mark Initialization methods
#pragma mark -

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        
        self.backgroundColor = [SKColor colorWithRed:0x00/255.0 green:0x00/255.0 blue:0x00/255.0 alpha:0.1];
        
        _contacts = [NSMutableArray array];
        _maxhealth = 5;
        _hitpoints = 5;
        _visibility = 10;
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

#pragma mark -
#pragma mark Helper methods
#pragma mark -

- (void)createScene {
    _world = [self createWorld];
    for (_hoops = 0; _hoops < _visibility; _hoops++) {
        [_world addChild:[self createHoopAtIndex:_hoops]];
    }
    [_world addChild:_camera = [self createCamera]];
    [_world addChild:[self createPlayer]];
    [self addChild:_world];
    [self createHud];
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
    node.fillColor = [SKColor colorWithRed:0x00/255.0 green:0x00/255.0 blue:0x00/255.0 alpha:0.1];
    node.strokeColor = [SKColor colorWithRed:0xEA/255.0 green:0xEB/255.0 blue:0xEA/255.0 alpha:1.0];
    node.position = CGPointMake(0, 0);
    [node.userData setObject:[NSValue valueWithCGPoint:node.position] forKey:@"origin"];
    node.zPosition = -(50 * index);
    node.name = @"hoop";
    [self moveNode:node asSeenFrom:_camera withFocallength:50];
    CGPathRelease(path);
    // add one every 5 hoops, and each time you go past 10 hoops, add another
    // so that by the time you have gone past 50 hoops - add one every single hoop
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
    node.physicsBody.categoryBitMask = ColliderTypeObsticle;
    [node attachDebugRectWithSize:size];
    CGPathRelease(path);
    return node;
}

-(void)createHud {
    _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
    //1
    _scoreLabel.name = @"kScoreHudName";
    _scoreLabel.fontSize = 15;
    //2
    _scoreLabel.fontColor = [SKColor greenColor];
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %04u", 0];
    //3
    _scoreLabel.position = CGPointMake(20 + _scoreLabel.frame.size.width/2,
                                      self.size.height - (20 + _scoreLabel.frame.size.height/2));
    [self addChild:_scoreLabel];
    
    _healthLabel = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
    //4
    _healthLabel.name = @"kHealthHudName";
    _healthLabel.fontSize = 15;
    //5
    _healthLabel.fontColor = [SKColor redColor];
    _healthLabel.text = [NSString stringWithFormat:@"Health: %.1f%%", 100.0f];
    //6
    _healthLabel.position = CGPointMake(self.size.width - _healthLabel.frame.size.width/2 - 20,
                                       self.size.height - (20 + _healthLabel.frame.size.height/2));
    [self addChild:_healthLabel];
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
    _elapsedTotal += elapsedSeconds;
    
    // Accelerate
    if (_velocityZ < 250) {
        _velocityZ += (elapsedSeconds * _accelerationZ);
    }
    
    // Move
    _camera.zPosition -= (elapsedSeconds * _velocityZ);
    // TODO: read imput and apply force
    
    // Perspective
    int visibility = -(50 * _visibility);
    [_world enumerateChildNodesWithName:@"hoop" usingBlock:^(SKNode *node, BOOL *stop) {
        [self moveNode:node asSeenFrom:_camera withFocallength:50];
        // Hide nodes that are behind
        node.hidden = (node.xScale > 1);
        // Remove nodes that are behind, if out of visibility
        if (_camera.zPosition - visibility < node.zPosition) {
            [node removeFromParent];
        }
    }];
    // Create nodes that are infront, if in visibility.
    if (_camera.zPosition + visibility < -(50 * _hoops)) {
        [_world addChild:[self createHoopAtIndex:++_hoops]];
    }
    
    // Collisions at this depts?
    for (int i = 0; i < _contacts.count; i++) {
        SKNode *obsticle = [_contacts objectAtIndex:i];
        CGFloat z = obsticle.parent.zPosition;
        // if contact is at this depth
        int distance = abs(_camera.zPosition - z);
        if (distance <= 5) {
            ((SKShapeNode *)obsticle).fillColor = DeepLilac;
            [_contacts removeObject:obsticle];
            // bounce
            _velocityZ *= -.8;
            // adjust score
            if (_hitpoints-- == 0) {
                // end game 
            }
            _healthLabel.text = [NSString stringWithFormat:@"Health: %.1f%%", _hitpoints/_maxhealth*100];
        }
    }
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %04u", _hoops];

    _last = currentTime;
}

@end
