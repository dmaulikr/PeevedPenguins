//
//  GameScene.swift
//  PeevedPenguins
//
//  Created by Natalia Luzuriaga on 7/7/17.
//  Copyright © 2017 Natalia Luzuriaga. All rights reserved.
//

import SpriteKit

class GameScene: SKScene,SKPhysicsContactDelegate {
    
    //Vars
    var cameraNode:SKCameraNode!
    var buttonRestart: MSButtonNode!
    
    var catapult: SKSpriteNode!
    var catapultArm: SKSpriteNode!
    var cantileverNode: SKSpriteNode!
    var touchNode: SKSpriteNode!
    var penguinJoint: SKPhysicsJointPin?
    
    var cameraTarget: SKSpriteNode?
    
    var touchJoint: SKPhysicsJointSpring?
    
    var countPenguins: Int = 0
    
    var penguinOne: SKSpriteNode!
    var penguinTwo: SKSpriteNode!
    var penguinThree: SKSpriteNode!
    
    var scoreLabel: SKLabelNode!
    var score: Int = 0
    
    
    override func didMove(to view: SKView) {
        //set physics contact delegate
        physicsWorld.contactDelegate = self
        
        //lives connections
        penguinOne = childNode(withName: "penguinOne") as! SKSpriteNode
        penguinTwo = childNode(withName: "penguinTwo") as! SKSpriteNode
        penguinThree = childNode(withName: "penguinThree") as! SKSpriteNode
        
        //scoreLabel connection
        scoreLabel = childNode(withName: "//scoreLabel") as! SKLabelNode
        
        /* Set reference to catapultArm node */
        catapultArm = childNode(withName: "catapultArm") as! SKSpriteNode
        
        //Set reference to catapult node
        catapult = childNode(withName: "catapult") as! SKSpriteNode
        
        //Set reference to cantileverNode
        cantileverNode = childNode(withName: "cantileverNode") as! SKSpriteNode
        
        //Set reference to touchNode
        touchNode = childNode(withName:"touchNode") as! SKSpriteNode
        
        //Create a new Camera
        cameraNode = childNode(withName: "cameraNode") as! SKCameraNode
        self.camera = cameraNode
        
        buttonRestart = childNode(withName: "//buttonRestart") as! MSButtonNode
        
        buttonRestart.selectedHandler = {
            
            guard let scene = GameScene.level(1) else {
                print("Level 1 is missing")
                return
            }
            scene.scaleMode = .aspectFit
            view.presentScene(scene)
        }
        setupCatapult()
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        /* Physics contact delegate implementation */
        /* Get references to the bodies involved in the collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        /* Get references to the physics body parent SKSpriteNode */
        let nodeA = contactA.node as! SKSpriteNode
        let nodeB = contactB.node as! SKSpriteNode
        /* Check if either physics bodies was a seal */
        if contactA.categoryBitMask == 2 || contactB.categoryBitMask == 2 {
            if contact.collisionImpulse > 2.0 {
                /* Kill Seal */
                if contactA.categoryBitMask == 2 { removeSeal(node: nodeA) }
                if contactB.categoryBitMask == 2 { removeSeal(node: nodeB) }
            }
        }
    }
    
    func setupCatapult() {
        /* Pin joint */
        var pinLocation = catapultArm.position
        pinLocation.x += -10
        pinLocation.y += -70
        let catapultJoint = SKPhysicsJointPin.joint(
            withBodyA:catapult.physicsBody!,
            bodyB: catapultArm.physicsBody!,
            anchor: pinLocation)
        physicsWorld.add(catapultJoint)
        
        /* Spring joint catapult arm and cantilever node */
        var anchorAPosition = catapultArm.position
        anchorAPosition.x += 0
        anchorAPosition.y += 50
        let catapultSpringJoint = SKPhysicsJointSpring.joint(withBodyA: catapultArm.physicsBody!, bodyB: cantileverNode.physicsBody!, anchorA: anchorAPosition, anchorB: cantileverNode.position)
        physicsWorld.add(catapultSpringJoint)
        catapultSpringJoint.frequency = 6
        catapultSpringJoint.damping = 0.5
    }
    
    func removeSeal(node: SKNode) {
        /* Load our particle effect */
        let particles = SKEmitterNode(fileNamed: "Poof")!
        /* Position particles at the Seal node
         If you've moved Seal to an sks, this will need to be
         node.convert(node.position, to: self), not node.position */
        particles.position = node.position
        /* Add particles to scene */
        addChild(particles)
        let wait = SKAction.wait(forDuration: 5)
        let removeParticles = SKAction.removeFromParent()
        let seq = SKAction.sequence([wait, removeParticles])
        particles.run(seq)
        
        /* Play SFX */
        let sound = SKAction.playSoundFileNamed("sfx_seal", waitForCompletion: false)
        self.run(sound)
        
        score += 1
        
        scoreLabel.text = "Score: \(score)"
        
        /* Seal death*/
        /* Create our hero death action */
        let sealDeath = SKAction.run({
            /* Remove seal node from scene */
            node.removeFromParent()
        })
        self.run(sealDeath)
    }
    
    func checkPenguin() {
        guard let cameraTarget = cameraTarget else {
            return
        }
        
        /* Check penguin has come to rest */
        if cameraTarget.physicsBody!.joints.count == 0 && cameraTarget.physicsBody!.velocity.length() < 0.18 {
            resetCamera()
        }
        
        if cameraTarget.position.y < -200 {
            cameraTarget.removeFromParent()
            resetCamera()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        let touch = touches.first!              // Get the first touch
        let location = touch.location(in: self) // Find the location of that touch in this view
        let nodeAtPoint = atPoint(location)     // Find the node at that location
        if nodeAtPoint.name == "catapultArm" {  // If the touched node is named "catapultArm" do...
            touchNode.position = location
            touchJoint = SKPhysicsJointSpring.joint(withBodyA: touchNode.physicsBody!, bodyB: catapultArm.physicsBody!, anchorA: location, anchorB: location)
            physicsWorld.add(touchJoint!)
            
            if countPenguins < 3 {
                self.countPenguins += 1
                let penguin = Penguin()
                addChild(penguin)
                penguin.position.x += self.catapultArm.position.x + 20
                penguin.position.y += self.catapultArm.position.y + 50
                penguin.physicsBody?.usesPreciseCollisionDetection = true
                self.penguinJoint = SKPhysicsJointPin.joint(withBodyA: self.catapultArm.physicsBody!,
                                                       bodyB: penguin.physicsBody!,
                                                       anchor: penguin.position)
                physicsWorld.add(self.penguinJoint!)
                self.cameraTarget = penguin
                
                
                //lives system
                let removePenguins = SKAction.removeFromParent()
                let seq = SKAction.sequence([removePenguins])
                penguinThree.run(seq)
                
                switch countPenguins{
                case 1:
                    penguinThree.run(seq)
                
                case 2:
                    penguinTwo.run(seq)
                    
                case 3:
                    penguinOne.run(seq)
                
                default:
                    print("End Game")
              }
            }
            
            
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        touchNode.position = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touchJoint = touchJoint {
            physicsWorld.remove(touchJoint)
        }
        // Check for a touchJoint then remove it.
        if let touchJoint = touchJoint {
            physicsWorld.remove(touchJoint)
        }
        // Check for a penguin joint then remove it.
        if let penguinJoint = penguinJoint {
            physicsWorld.remove(penguinJoint)
        }
        // Check if there is a penguin assigned to the cameraTarget
        guard let penguin = cameraTarget else {
            return
        }
        // Generate a vector and a force based on the angle of the arm.
        let force: CGFloat = 350
        let r = catapultArm.zRotation
        let dx = cos(r) * force
        let dy = sin(r) * force
        // Apply an impulse at the vector.
        let v = CGVector(dx: dx, dy: dy)
        penguin.physicsBody?.applyImpulse(v)
    }
    
    override func update(_ currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        moveCamera()
        checkPenguin()
    }
    
    /* Make a Class method to load levels */
    class func level(_ levelNumber: Int) -> GameScene? {
        guard let scene = GameScene(fileNamed: "Level_\(levelNumber)") else {
            return nil
        }
        scene.scaleMode = .aspectFit
        return scene
    }
    
    func moveCamera() {
        guard let cameraTarget = cameraTarget else {
            return
        }
        let targetX = cameraTarget.position.x
        let x = clamp(value: targetX, lower: 0, upper: 392)
        cameraNode.position.x = x
    }
    
    func resetCamera() {
        /* Reset camera */
        let cameraReset = SKAction.move(to: CGPoint(x:0, y:camera!.position.y), duration: 1.5)
        let cameraDelay = SKAction.wait(forDuration: 0.5)
        let cameraSequence = SKAction.sequence([cameraDelay,cameraReset])
        cameraNode.run(cameraSequence)
        cameraTarget = nil
    }
}

func clamp<T: Comparable>(value: T, lower: T, upper: T) -> T {
    return min(max(value, lower), upper)
}

extension CGVector {
    public func length() -> CGFloat {
        return CGFloat(sqrt(dx*dx + dy*dy))
    }
}
