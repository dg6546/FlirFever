//
//  ViewController.swift
//  flirFever
//
//  Created by ＭＴ on 30/12/2020.
//

import UIKit
import Vision

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
        DispatchQueue.main.async{
            self.statusText.text.append("Image received\n")
            self.camera.withImage { (image: FLIRThermalImage) in
                let showImage:UIImage!
                let sourceImage:UIImage! = image.getImage()
                let fusion:FLIRFusion! = image.getFusion()
                    fusion.setFusionMode(VISUAL_MODE)
                if self.flip == 1{
                    let flippedImage:UIImage! = UIImage(cgImage: sourceImage.cgImage!,scale:sourceImage.scale,
                        orientation: UIImage.Orientation.upMirrored)
                    showImage = flippedImage
                }else{
                    showImage = image.getImage()
                }
                
                let request = VNDetectFaceRectanglesRequest { [unowned self] request, error in
                    if let error = error {
                        
                    }
                    else {
                        self.handleFaces(with: request)
                    }
                }
                let handler:VNImageRequestHandler
                if self.flip==0{
                    handler = VNImageRequestHandler(cgImage: showImage.cgImage!, options:[:] )
                }
                else{
                    handler = VNImageRequestHandler(cgImage: showImage.cgImage!, orientation:.upMirrored ,options:[:] )
                }
                do {
                    try handler.perform([request])
                }
                catch {
                    
                }
                self.cameraView.image = showImage
                
                /* //test point measurement
                if image.measurements.measurementSpots.count == 0{
                    image.measurements.addSpot(CGPoint(x: Int(image.getWidth())/2, y: Int(image.getHeight())/2))
                }
                let spot = image.measurements.measurementSpots.firstObject as? FLIRMeasurementSpot
                //self.readingLabel.text = spot?.value.value() as? String
                //print(spot?.value.value ?? "nil")
                self.readingLabel.text = "\(String(format: "%.1f", (spot?.value.value)!-273.15+2 ))"
                */
            }
            
        }
    }
             
    
    func handleFaces(with request: VNRequest) {
        cameraView.layer.sublayers?.forEach { layer in
            layer.removeFromSuperlayer()
        }
        guard let observations = request.results as? [VNFaceObservation] else {
            return
        }
        observations.forEach { observation in
            let boundingBox = observation.boundingBox
            let origin:CGPoint
            let size:CGSize

            size = CGSize(width: boundingBox.width * cameraView.bounds.width,
                                  height: boundingBox.height * cameraView.bounds.height)
            origin = CGPoint(x: boundingBox.minX * cameraView.bounds.width,
                                     y: (1 - observation.boundingBox.minY) * cameraView.bounds.height - size.height)
            
            
            
            
            let layer = CAShapeLayer()
            layer.frame = CGRect(origin: origin, size: size)
            layer.borderColor = UIColor.red.cgColor
            layer.borderWidth = 2
            
            cameraView.layer.addSublayer(layer)
        }
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


