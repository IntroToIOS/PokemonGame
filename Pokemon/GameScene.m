//
//  GameScene.m
//  Pokemon
//
//  Created by Richard Freling on 2/11/16.
//  Copyright (c) 2016 Richard Freling. All rights reserved.
//

#import "GameScene.h"

@interface GameScene () <SKPhysicsContactDelegate>
@property (nonatomic) SKSpriteNode * ash;
@property (nonatomic) NSTimeInterval lastSpawnTimeInterval;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@end

static const uint32_t pokeballCategory     =  0x1 << 0;
static const uint32_t pokemonCategory        =  0x1 << 1;

static inline CGPoint rwAdd(CGPoint a, CGPoint b) {
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint rwSub(CGPoint a, CGPoint b) {
    return CGPointMake(a.x - b.x, a.y - b.y);
}

static inline CGPoint rwMult(CGPoint a, float b) {
    return CGPointMake(a.x * b, a.y * b);
}

static inline float rwLength(CGPoint a) {
    return sqrtf(a.x * a.x + a.y * a.y);
}

static inline CGPoint rwNormalize(CGPoint a) {
    float length = rwLength(a);
    return CGPointMake(a.x / length, a.y / length);
}

@implementation GameScene


-(void)didMoveToView:(SKView *)view {
    
    self.physicsWorld.gravity = CGVectorMake(0,0);
    self.physicsWorld.contactDelegate = self;
    
    NSLog(@"Adding Ash");
    self.backgroundColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    self.ash = [SKSpriteNode spriteNodeWithImageNamed:@"ash"];
    //self.ash.position = CGPointMake(500, 400);
    self.ash.position = CGPointMake(self.ash.size.width/2, self.frame.size.height/2);
    [self addChild:self.ash];

}

- (void)addPokemon {
    NSLog(@"Add Pokemon");
    
    // Create sprite
    SKSpriteNode * pokemon = [SKSpriteNode spriteNodeWithImageNamed:@"pikachu"];
    

    int minY = pokemon.size.height / 2;
    int maxY = self.frame.size.height - pokemon.size.height / 2;
    int rangeY = maxY - minY;
    int actualY = minY + (arc4random() % rangeY);
    

    pokemon.position = CGPointMake(self.frame.size.width + pokemon.size.width/2, actualY);
    [self addChild:pokemon];
    
    pokemon.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:pokemon.size];
    pokemon.physicsBody.dynamic = YES;
    pokemon.physicsBody.categoryBitMask = pokemonCategory;
    pokemon.physicsBody.contactTestBitMask = pokeballCategory;
    pokemon.physicsBody.collisionBitMask = 0;
    
    int minDuration = 2.0;
    int maxDuration = 4.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;
    

    SKAction * actionMove = [SKAction moveTo:CGPointMake(-pokemon.size.width/2, actualY) duration:actualDuration];
    SKAction * actionMoveDone = [SKAction removeFromParent];
    [pokemon runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
    
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast {
    self.lastSpawnTimeInterval += timeSinceLast;
    if (self.lastSpawnTimeInterval > 1) {
        self.lastSpawnTimeInterval = 0;
        [self addPokemon];
    }
    
}

- (void)update:(NSTimeInterval)currentTime {

    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    self.lastUpdateTimeInterval = currentTime;
    // one second
    if (timeSinceLast > 1) {
        timeSinceLast = 1.0 / 60.0;
        self.lastUpdateTimeInterval = currentTime;
    }
    
    [self updateWithTimeSinceLastUpdate:timeSinceLast];
    
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    
    SKSpriteNode * pokeball = [SKSpriteNode spriteNodeWithImageNamed:@"pokeball"];
    pokeball.position = self.ash.position;
    
    CGPoint offset = rwSub(location, pokeball.position);
    
    if (offset.x <= 0) return;
    
    [self addChild:pokeball];
    
    pokeball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:pokeball.size.width/2];
    pokeball.physicsBody.dynamic = YES;
    pokeball.physicsBody.categoryBitMask = pokeballCategory;
    pokeball.physicsBody.contactTestBitMask = pokemonCategory;
    pokeball.physicsBody.collisionBitMask = 0;
    pokeball.physicsBody.usesPreciseCollisionDetection = YES;
    
    CGPoint direction = rwNormalize(offset);
    
    CGPoint shootAmount = rwMult(direction, 1000);
    
    CGPoint realDest = rwAdd(shootAmount, pokeball.position);
    
    float velocity = 480.0/1.0;
    float realMoveDuration = self.size.width / velocity;
    SKAction * actionMove = [SKAction moveTo:realDest duration:realMoveDuration];
    SKAction * actionMoveDone = [SKAction removeFromParent];
    [pokeball runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
    
}

- (void)pokeball:(SKSpriteNode *)pokeball didCollideWithPokemon:(SKSpriteNode *)pokemon {
    NSLog(@"Hit");
    [pokeball removeFromParent];
    [pokemon removeFromParent];
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody, *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
    {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else
    {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if ((firstBody.categoryBitMask & pokeballCategory) != 0 &&
        (secondBody.categoryBitMask & pokemonCategory) != 0)
    {
        [self pokeball:(SKSpriteNode *) firstBody.node didCollideWithPokemon:(SKSpriteNode *) secondBody.node];
    }
}






@end
