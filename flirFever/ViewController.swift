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
    
    func imageReceived() {
        DispatchQueue.main.async{
            self.statusText.text.append("Image received\n")
            self.camera.withImage { (image: FLIRThermalImage) in
                self.cameraView.image = image.getImage()
                if image.measurements.measurementSpots.count == 0{
                    image.measurements.addSpot(CGPoint(x: Int(image.getWidth())/2, y: Int(image.getHeight())/2))
                }
                let spot = image.measurements.measurementSpots.firstObject as? FLIRMeasurementSpot
                //self.readingLabel.text = spot?.value.value() as? String
                //print(spot?.value.value ?? "nil")
                self.readingLabel.text = "\(String(format: "%.1f", spot?.value.value ?? 0))"
            }
        }
    }

    
    @IBOutlet weak var cameraView: UIImageView!
    
    @IBOutlet weak var readingLabel: UILabel!
    
    @IBOutlet weak var statusText: UITextView!
    
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


