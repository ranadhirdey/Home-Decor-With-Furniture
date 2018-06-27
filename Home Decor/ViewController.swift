//
//  ViewController.swift
//  Home Decor
//
//  Created by Ranadhir Dey on 14/06/18.
//  Copyright © 2018 ARFactory. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var furnitureButton: UIButton!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var collectionView: UICollectionView!{
        didSet{
            collectionView.delegate = self
            collectionView.dataSource = self
        }
    }
    let config = ARWorldTrackingConfiguration()
    
    let floorImageArray = ["Wood1","Wood2","Wood3","Wood4", "Wood5", "Wood6", "Tile1", "Tile2", "Tile3", "Tile4"]
    lazy var imageName = floorImageArray[0]
    let floodNodeName = "FloorNode"
    
    var furnitureName = "Table"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        config.planeDetection = .horizontal
        sceneView.session.run(config)

        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        
        addTapGesture()
        

    }
    
    fileprivate func createFloorNode(anchor:ARPlaneAnchor) ->SCNNode{
        let floorNode = SCNNode(geometry: SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))) //1
        floorNode.position=SCNVector3(anchor.center.x,0,anchor.center.z)                                               //2
        floorNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: imageName)                                //3
        floorNode.geometry?.firstMaterial?.isDoubleSided = true                                                        //4
        floorNode.eulerAngles = SCNVector3(Double.pi/2,0,0)                                                            //5
        floorNode.name = floodNodeName                                                                                  //6
        return floorNode                                                                                                //7
    }
    
    func addTapGesture(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(sender:)))
        tap.numberOfTapsRequired = 1
        sceneView.addGestureRecognizer(tap)
    }
    
    @objc func tapped(sender: UITapGestureRecognizer){
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        if !hitTest.isEmpty{
            print("Touched on the plane")
            addFurniture(hitTestResult: hitTest.first!)
        }
        else{
            print("Not a plane")
        }
    }
    
    func addFurniture(hitTestResult:ARHitTestResult){
        
        
        
        guard let scene = SCNScene(named: "furnitures.scnassets/\(furnitureName).scn") else{return}
        
        let node = (scene.rootNode.childNode(withName: furnitureName, recursively: false))!
        
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        self.sceneView.scene.rootNode.addChildNode(node)
    }
    
    let furnitureArray = ["Chair","Couch","Table","Vase"]
    
    
    @IBAction func furnitureButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Select Furniture", message: "", preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.sourceView = sender
       
        for furnitureName in furnitureArray{
            let alertAction = UIAlertAction(title: furnitureName, style: .default) {[weak self] (_) in
                self?.furnitureName = furnitureName
            }
            alertController.addAction(alertAction)
        }
        
        present(alertController, animated: true, completion: nil)
    }
    

}


extension ViewController:ARSCNViewDelegate{
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        let planeNode = createFloorNode(anchor: planeAnchor)
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        let planeNode = createFloorNode(anchor: planeAnchor)
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
    }
}

extension ViewController:UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return floorImageArray.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        if let imgVw = cell.viewWithTag(1) as? UIImageView{
            imgVw.image = UIImage(named: floorImageArray[indexPath.row])
            resizeImageInCell(cell, isSelected: imageName == floorImageArray[indexPath.row])
        }
        
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = self.collectionView.cellForItem(at: indexPath)
        
        resizeImageInCell(cell!, isSelected: true)
        
        
        imageName = floorImageArray[indexPath.row]
        collectionView.reloadData()
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = self.collectionView.cellForItem(at: indexPath)
        
        resizeImageInCell(cell!, isSelected: false)
    }
    
    func resizeImageInCell(_ cell:UICollectionViewCell, isSelected:Bool){
        
        cell.layer.cornerRadius = isSelected ? 35 : 20
        cell.layer.masksToBounds = true
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return imageName == floorImageArray[indexPath.row] ? CGSize(width: 70, height: 70) : CGSize(width: 40, height: 40)
    }
    
}
