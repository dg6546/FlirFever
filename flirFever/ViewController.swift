//
//  ViewController.swift
//  flirFever
//
//  Created by ＭＴ on 30/12/2020.
//

import UIKit

class ViewController: UIViewController, FLIRDiscoveryEventDelegate, FLIRDataReceivedDelegate {
    let camera = FLIRCamera()
    let discovery = FLIRDiscovery()
    var flip:Int = 0
    @IBOutlet weak var cameraView: UIImageView!
    
    @IBOutlet weak var readingLabel: UILabel!
    
    @IBOutlet weak var statusText: UITextView!
    func cameraFound(_ cameraIdentity: FLIRIdentity) {
        if cameraIdentity.cameraType() == FLIRCameraType.flirOne{
            
            DispatchQueue.global(qos: .default).async(execute: { [self] in
                do{
                    try camera.connect(cameraIdentity)
                }catch{
                    fatalError("Unable to connect camera")
                }
                DispatchQueue.main.async(execute: { [self] in
                    discovery.stop()
                        do{
                            try camera.subscribeStream()
                        }catch{
                            fatalError("Unable to subscribe to stream")
                        }
                    })
                })
//            do{
//                try camera.connect(cameraIdentity)
//                statusText.text.append("Camera connected\n")
//                self.discovery.stop()
//                try self.camera.subscribeStream()
//                statusText.text.append("Camera subscribed\n")
//            }catch let error as NSError {
//                statusText.text.append("\(error)")
//            }
        }
    }
    
    func discoveryError(_ error: String, netServiceError nsnetserviceserror: Int32, on iface: FLIRCommunicationInterface) {
        NSLog("Error %s", error)
    }
    
    func onDisconnected(_ camera: FLIRCamera, withError error: Error?) {
        camera.unsubscribeStream()
    }
    
    func cameraLost(_ cameraIdentity: FLIRIdentity) {
        camera.disconnect()
    }
    
    @IBAction func Flip(_ sender: Any) {
        
        if (flip==0){
            flip = 1
        }else{
            flip = 0
        }
    }
    func imageReceived() {
        DispatchQueue.global(qos: .default).async(execute: { [self] in
            do{
                self.camera.withImage({ (image:FLIRThermalImage!) in
                let fusion:FLIRFusion! = image.getFusion()
                    fusion.setFusionMode(VISUAL_MODE)
                if self.flip==1 {
                    let sourceImage:UIImage! = image.getImage()
                    let flippedImage:UIImage! = UIImage(cgImage: sourceImage.cgImage!,
                                                            scale:sourceImage.scale,
                                                            orientation: UIImage.Orientation.upMirrored)
                    self.cameraView.image = flippedImage
                }else{
                    self.cameraView.image = image.getImage()
                }

                    if image.measurements.measurementSpots.count==0{
                        image.measurements.addSpot(CGPoint.init(x: Int(image.getWidth())/2, y: Int(image.getHeight())/2))
                    }

                    let spot:FLIRMeasurementSpot! = image.measurements.measurementSpots.firstObject as? FLIRMeasurementSpot
                    self.readingLabel.text = String(format:"%.1f",spot.value)
            })
            }
        })
            
    }

    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        camera.delegate = self
        discovery.delegate = self
    }

    
    @IBAction func startButtonPressed(_ sender: Any) {
        discovery.start(FLIRCommunicationInterface.lightning)
        statusText.text.append("Start camera discovery\n")
        //discovery.start(FLIRCommunicationInterface.emulator)
    }
    
    
}


