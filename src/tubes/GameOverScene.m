//
//  GameOverScene.m
//  tubes
//
//  Created by Colin Milhench on 27/02/2014.
//  Copyright (c) 2014 Colin Milhench. All rights reserved.
//

#import "GameOverScene.h"
#import "MyScene.h"

@implementation GameOverScene


#pragma mark -
#pragma mark Initialization methods
#pragma mark -

- (id)initWithSize:(CGSize)size score:(int)score {
    if (self = [super initWithSize:size]) {
        
        SKLabelNode *scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
        scoreLabel.fontSize = 15;
        scoreLabel.fontColor = [SKColor greenColor];
        scoreLabel.text = [NSString stringWithFormat:@"Score: %04u", score];
        scoreLabel.position = CGPointMake(self.size.width/2, self.size.height/2 + 10);
        
        SKLabelNode *infoLabel = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
        infoLabel.fontSize = 15;
        infoLabel.fontColor = [SKColor whiteColor];
        infoLabel.text = @"Tap the screen to try again";
        infoLabel.position = CGPointMake(self.size.width/2, self.size.height/2 - 10);
        
        [self addChild:scoreLabel];
        [self addChild:infoLabel];
    }
    return self;
}

#pragma mark -
#pragma mark Touch methods
#pragma mark -

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    MyScene * myScene = [[MyScene alloc] initWithSize:self.size];
    SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
    [self.view presentScene:myScene transition: reveal];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}

@end
