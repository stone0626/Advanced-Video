//
//  BroadcastViewController.swift
//  Agora-Screen-Sharing-iOS
//
//  Created by GongYuhua on 2017/8/1.
//  Copyright © 2018 Agora. All rights reserved.
//

import UIKit
import SpriteKit
import ReplayKit

class BroadcastViewController: UIViewController {

    @IBOutlet weak var sceneView: SKView!
    
    fileprivate weak var broadcastActivityVC: RPBroadcastActivityViewController?
    fileprivate weak var broadcastController: RPBroadcastController?
    fileprivate weak var cameraPreview: UIView?
    
    private var isBroadcasting = false {
        didSet {
            if let button = broadcastButton as? UIButton {
                button.setImage(isBroadcasting ? #imageLiteral(resourceName: "btn_broadcasting") : #imageLiteral(resourceName: "btn_join"), for: .normal)
            }
        }
    }
    
    private lazy var broadcastButton: UIView! = {
        if #available(iOS 12.0, *) {
            let frame = CGRect(x: 0, y:view.frame.size.height - 60, width: 60, height: 60)
            let systemBroadcastPicker = RPSystemBroadcastPickerView(frame: frame)
            systemBroadcastPicker.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin]
            systemBroadcastPicker.preferredExtension = Bundle.main.bundleIdentifier! + ".Broadcast"
            return systemBroadcastPicker
        }
        else {
            let appBroadcastButton = UIButton(type: .custom)
            appBroadcastButton.frame = CGRect(x: 10, y:view.frame.size.height - 50, width: 40, height: 40)
            appBroadcastButton.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin]
            appBroadcastButton.setImage(#imageLiteral(resourceName: "btn_join"), for: .normal)
            appBroadcastButton.addTarget(self, action: #selector(doBroadcastPressed), for: .touchUpInside)
            return appBroadcastButton
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(broadcastButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Used to trigger the allowing network dialog when first run, only for cellphones sold in China
        let url = URL(string: "https://www.agora.io")
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        let dataTask = session.dataTask(with: url!)
        dataTask.resume()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let scene = GameScene(size: sceneView.bounds.size)
        scene.scaleMode = .resizeFill
        sceneView.presentScene(scene)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParentViewController {
            if isBroadcasting {
                isBroadcasting = false
                stopReplayKitBroadcasting()
            }
        }
    }
    
    @objc func doBroadcastPressed(_ sender: UIButton) {
        isBroadcasting = !isBroadcasting
        
        if isBroadcasting {
            startReplayKitBroadcasting()
        } else {
            stopReplayKitBroadcasting()
        }
    }
}

private extension BroadcastViewController {
    func startReplayKitBroadcasting() {
        guard RPScreenRecorder.shared().isAvailable else {
            return
        }
        
        RPScreenRecorder.shared().isCameraEnabled = true
        RPScreenRecorder.shared().isMicrophoneEnabled = true
        
        // Broadcast Pairing
        let bundleID = Bundle.main.bundleIdentifier!
        RPBroadcastActivityViewController.load(withPreferredExtension: bundleID + ".BroadcastUI") { (broadcastActivityViewController, _) in
            self.presentBroadcastActivityVC(broadcastActivityVC: broadcastActivityViewController)
        }
    }
    
    func presentBroadcastActivityVC(broadcastActivityVC: RPBroadcastActivityViewController?) {
        guard let broadcastActivityVC = broadcastActivityVC else {
            return
        }
        broadcastActivityVC.delegate = self
        if UIDevice.current.userInterfaceIdiom == .pad {
            broadcastActivityVC.modalPresentationStyle = .popover
            broadcastActivityVC.popoverPresentationController?.sourceView = broadcastButton
            broadcastActivityVC.popoverPresentationController?.sourceRect = broadcastButton.frame
            broadcastActivityVC.popoverPresentationController?.permittedArrowDirections = .down
        }
        present(broadcastActivityVC, animated: true, completion: nil)
        
        self.broadcastActivityVC = broadcastActivityVC
    }
    
    func stopReplayKitBroadcasting() {
        if let broadcastController = broadcastController {
            broadcastController.finishBroadcast(handler: { (error) in
                
            })
        }
        
        if let cameraPreview = cameraPreview {
            cameraPreview.removeFromSuperview()
        }
    }
}

extension BroadcastViewController: RPBroadcastActivityViewControllerDelegate {
    func broadcastActivityViewController(_ broadcastActivityViewController: RPBroadcastActivityViewController, didFinishWith broadcastController: RPBroadcastController?, error: Error?) {
        DispatchQueue.main.async { [unowned self] in
            if let broadcastActivityVC = self.broadcastActivityVC {
                broadcastActivityVC.dismiss(animated: true, completion: nil)
            }
            
            self.broadcastController = broadcastController
            
            if let broadcastController = broadcastController {
                broadcastController.startBroadcast(handler: { (error) in
                    if let error = error {
                        print("startBroadcastWithHandler error: \(error.localizedDescription)")
                    } else {
                        DispatchQueue.main.async {
                            if let cameraPreview = RPScreenRecorder.shared().cameraPreviewView {
                                cameraPreview.frame = CGRect(x: 8, y: 28, width: 120, height: 180)
                                self.view.addSubview(cameraPreview)
                                self.cameraPreview = cameraPreview
                            }
                        }
                    }
                })
            }
        }
    }
}
