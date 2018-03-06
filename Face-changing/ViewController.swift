//
//  ViewController.swift
//  Face-changing
//
//  Created by wzq on 2018/3/6.
//  Copyright © 2018年 wzq. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    private var occlusionNode = SCNNode()
    private var faceNode = SCNNode()
    private var virtualFaceNode = SCNNode()
    private var noface = false
    private var nofacecount = 1
    //
    private let serialQueue = DispatchQueue(label: "com.test.Face-changing.serialSceneKitQueue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard ARFaceTrackingConfiguration.isSupported else { return }
        
        //
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        //debug选项
        // sceneView.debugOptions =  .showWireframe
        
        // 如果要显示摄像头内容需要注释掉
        //sceneView.scene.background.contents = UIColor.black
        
        // ARSCNFaceGeometry
        let device = sceneView.device!
        let maskGeometry = ARSCNFaceGeometry(device: device)!
        // ARSCNFaceGeometry(device: device,fillMesh : flase)!
        //
        // maskGeometry.firstMaterial!.colorBufferWriteMask = []
        maskGeometry.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "opera_0")

        virtualFaceNode.geometry = maskGeometry
        virtualFaceNode.renderingOrder = -1
        resetTracking()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        resetTracking()
    }
    

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    // 重新开始面部追踪
    func resetTracking() {
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
 
    private func setupFaceNodeContent() {
        for child in faceNode.childNodes {
            child.removeFromParentNode()
        }
        faceNode.addChildNode(virtualFaceNode)
    }
    
    // MARK: - ARSCNViewDelegate
    /// ARNodeTracking 開始
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        faceNode = node
        serialQueue.async {
            self.setupFaceNodeContent()
        }
    }
    
    // ARSCNFaceGeometry 更新
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        let geometry = virtualFaceNode.geometry as! ARSCNFaceGeometry
        if faceAnchor.isTracked {
            if noface {
                geometry.firstMaterial?.diffuse.contents = UIImage(named:"opera_\(nofacecount%9)")
                nofacecount += 1
            }
        }
        noface = !faceAnchor.isTracked
        geometry.update(from: faceAnchor.geometry)
    }
    
    
    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
    }
    
    
    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async {
            // 恢复追踪
            self.resetTracking()
        }
    }
}
