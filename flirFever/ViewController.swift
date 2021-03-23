//
//  ViewController.swift
//  flirFever
//
//  Created by ＭＴ on 30/12/2020.
//

import UIKit
import Vision
import Toast

class ViewController: UIViewController, FLIRDiscoveryEventDelegate, FLIRDataReceivedDelegate, FLIRRemoteDelegate {
    let camera = FLIRCamera()
    let discovery = FLIRDiscovery()
    var calibration = FLIRCalibration()
    var battery = FLIRBattery()
    let pm = FLIRPaletteManager()
    var flip:Int = 0
    var image = FLIRThermalImage()
    var faceBoxList = [FaceBox]()

    
    //var humanList = [Human]()
    
    @IBOutlet weak var chargingLabel: UILabel!
    
    @IBOutlet weak var batteryLabel: UILabel!
    
    @IBOutlet weak var cameraView: UIImageView!
    
    
    func cameraFound(_ cameraIdentity: FLIRIdentity) {
        if cameraIdentity.cameraType() == FLIRCameraType.flirOne{
            
            DispatchQueue.global(qos: .default).async(execute: { [self] in
                do{
                    try camera.connect(cameraIdentity)
                    
                }catch{
                    self.view.makeToast("Unable to connect camera", duration: 3.0, position: .bottom)
                    return
                }
                DispatchQueue.main.async(execute: { [self] in
                    discovery.stop()
                    
                    //macbook(the sdk...)debug delegate method
                    //it is better if these delegate can work on iphone
                    self.camera.getRemoteControl()?.delegate = self
                    self.camera.getRemoteControl()?.getBattery()?.subscribePercentage()
                    self.camera.getRemoteControl()?.getBattery()?.subscribeChargingState()
                    self.camera.getRemoteControl()?.getCalibration()?.subscribeCalibrationState()
                    
                    
                    calibration = (camera.getRemoteControl()?.getCalibration())!
                    battery = (camera.getRemoteControl()?.getBattery())!
                    getBattery()
                        do{
                            try camera.subscribeStream()
                        }catch{
                            self.view.makeToast("Unable to subscribe to stream", duration: 3.0, position: .bottom)
                            return
                        }
                    })
                })
            calibrate()
            self.view.makeToast("Camera connected", duration: 3.0, position: .bottom)
        }

        
    }
    
    func calibrationStateChanged(_ state: Bool) {
        //trash, does not work
    }
    
    func chargingStateChanged(_ state: FLIRChargingState) {
        //trash, does not working
    }
    
    func percentageChanged(_ percent: Int32) {
        //trash, does not working
    }
    
    
    func discoveryError(_ error: String, netServiceError nsnetserviceserror: Int32, on iface: FLIRCommunicationInterface) {
        self.view.makeToast("Cannot find camera.", duration: 3.0, position: .bottom)
    }
    
    func onDisconnected(_ camera: FLIRCamera, withError error: Error?) {
        camera.unsubscribeStream()
        self.camera.getRemoteControl()?.getCalibration()?.unsubscribeCalibrationState()
        self.camera.getRemoteControl()?.getBattery()?.unsubscribePercentage()
        self.camera.getRemoteControl()?.getBattery()?.unsubscribeChargingState()
        self.view.makeToast("Camera disconnected", duration: 3.0, position: .bottom)
    }
    
    func cameraLost(_ cameraIdentity: FLIRIdentity) {
        camera.disconnect()
        self.view.makeToast("Camera disconnected", duration: 3.0, position: .bottom)
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
            self.cameraView.layer.sublayers?.forEach { layer in
                layer.removeFromSuperlayer()
            }
            self.camera.withImage { (image: FLIRThermalImage) in
                self.faceBoxList = [FaceBox]()
                self.image = image
                let fusion:FLIRFusion! = self.image.getFusion()
                self.image.palette = self.pm.iron
                //image.rotate(RotationAngle(rawValue: 0)!)
                fusion.setFusionMode(IR_MODE)
                let irImage:UIImage! = self.image.getImage()
                fusion.setFusionMode(VISUAL_MODE)
                let colorImage:UIImage! = self.image.getImage()
                image.setTemperatureUnit(TemperatureUnit(rawValue: 0)!)
                
                let orientation = CGImagePropertyOrientation(rawValue: UInt32(colorImage.imageOrientation.rawValue))
                
                let handler = VNImageRequestHandler(cgImage: colorImage.cgImage!, orientation: orientation! )
                do {
                    try handler.perform([self.detectionRequest])
                }catch{
                    fatalError("cannot perform request")
                }
                self.cameraView.image = irImage
                self.getTempDraw()
                
            }
                
                
                
                
                
                
                
                
                /*
                    //fusion.setFusionMode(VISUAL_MODE)
                
                
                var bBoxList = [CGRect]()
//                if self.flip == 1{
//                    let flippedImage:UIImage! = UIImage(cgImage: sourceImage.cgImage!,scale:sourceImage.scale,
//                        orientation: UIImage.Orientation.upMirrored)
//                    showImage = flippedImage
//                }else{
//                    showImage = image.getImage()
//                }
                let request = VNDetectFaceRectanglesRequest { [unowned self] request, error in
                    if error != nil {
                        
                    }
                    else {
                         bBoxList = self.handleFaces(with: request)
                    }
                }
                let handler:VNImageRequestHandler
                //handler = VNImageRequestHandler(cgImage: colorImage.cgImage!, options:[:] )
                handler = VNImageRequestHandler(cgImage: colorImage.cgImage!, options:[:] )
//                if self.flip==0{
//                    handler = VNImageRequestHandler(cgImage: showImage.cgImage!, options:[:] )
//                }
//                else{
//                    handler = VNImageRequestHandler(cgImage: showImage.cgImage!, orientation:.upMirrored ,options:[:] )
//                }
                do {
                    try handler.perform([request])
                }
                catch {
                    
                }
                if (bBoxList.count != 0) {
                    bBoxList.forEach{bBox in
                        let x = bBox.midX
                        let y = bBox.midY
                        let point = CGPoint(x: x,y: y)
                        let bBoxCenterPoint = CGPoint(x: bBox.size.width/2 + bBox.origin.x, y: bBox.origin.y)
                        let circlePath = UIBezierPath(arcCenter: point, radius: CGFloat(Int((y-bBox.minY)*1.2)), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
                        image.measurements.addCircle(point, radius: Int32(Int((y-bBox.minY)*1.2)))
                        let label = UILabel(frame: (CGRect(origin: bBoxCenterPoint, size: CGSize(width:50,height:20))))
                        let spot  = image.measurements.measurementCircles.firstObject as? FLIRMeasurementCircle
                        guard let reading = spot?.max.value else{
                            return
                        }
                        
                        let color:UIColor
                        //reading = reading  - 273
                        if reading > 37.5{
                            color = UIColor.red
                        }else{
                            color = UIColor.green
                        }
                        let shapeLayer = CAShapeLayer()
                        shapeLayer.path = circlePath.cgPath
                            
                        // Change the fill color
                        shapeLayer.fillColor = UIColor.clear.cgColor
                        // You can change the stroke color
                        shapeLayer.strokeColor = color.cgColor
                        // You can change the line width
                        shapeLayer.lineWidth = 3.0
                            
                        self.cameraView.layer.addSublayer(shapeLayer)
                        
                        label.textColor = color
                        
                        label.text = "\(String(format: "%.1f", (reading) ))"
                        self.cameraView.addSubview(label)
                    }

                }
                                
                
                //fusion.setFusionMode(IR_MODE)
                self.cameraView.image = irImage
                
                 //test point measurement
                if image.measurements.measurementSpots.count == 0{
                    image.measurements.addSpot(CGPoint(x: Int(image.getWidth())/2, y: Int(image.getHeight())/2))
                }
                let spot = image.measurements.measurementSpots.firstObject as? FLIRMeasurementSpot
                //self.readingLabel.text = spot?.value.value() as? String
                //print(spot?.value.value ?? "nil")
                self.readingLabel.text = "\(String(format: "%.1f", (spot?.value.value)!-273.15+2 ))"
                
            }*/
            
        }
    }
    
    func rectInsideRect(smallRect: CGRect, bigRect: CGRect) -> Bool {
        return (smallRect.minX >= bigRect.minX && smallRect.minY >= bigRect.minY
                    && smallRect.maxX <= bigRect.maxX && smallRect.maxY <= bigRect.maxY)
    }
    
    //called after finish detection request
    func processDetection(for request: VNRequest, error: Error?){
        
        //see if there is any result
        guard let observations = request.results as? [VNRecognizedObjectObservation] else {return}
        
        for observation in observations{
                //get class label
                let label: String? = observation.labels.first?.identifier
                if (label == "with_mask" || label == "without_mask" || label == "mask_weared_incorrect"){
                    if observation.confidence > 0.5{ //50% confidence threshold
                        //add a new face box
                        let newFaceBox = FaceBox(box: observation.boundingBox, label: label!)
                        faceBoxList.append(newFaceBox)
                    }
                }else if (label == "forehead"){
                    if observation.confidence > 0.3{ //50% confidence threshold
                        //find which box does this forehead belongs to
                        for facebox in faceBoxList{
                            if ( rectInsideRect( smallRect: observation.boundingBox,bigRect: facebox.getBox())){
                                facebox.setForeheadBox(foreheadBox: observation.boundingBox)
                                break
                            }
                        }
                    }
                }
            
        }
    }
    
    //get temp and draw
    func getTempDraw(){
        for facebox in faceBoxList{
            let boundingBox = facebox.getBox()
            let foreheadBox = facebox.getForeheadBox()
            let foreheadBoxLayer = CAShapeLayer()
            let label = facebox.getLabel()
            var tempLabel = UILabel()
            var color:UIColor = UIColor.green
            
            //create facebox layer
            let size = CGSize(width: boundingBox.width * cameraView.bounds.width,
                                  height: boundingBox.height * cameraView.bounds.height)
            let origin = CGPoint(x: boundingBox.minX * cameraView.bounds.width,
                             y: (1 - boundingBox.minY) * cameraView.bounds.height - size.height)
            
            let bBox = getBoundingRectAfterRotation(rect: CGRect(origin: origin, size: size), angle: .pi/2)
            
            let faceBoxLayer = CAShapeLayer()
            faceBoxLayer.frame = bBox
            faceBoxLayer.borderWidth = 2
            
                //create forehead box layer
                let size2 = CGSize(width: foreheadBox.width * cameraView.bounds.width,
                                      height: foreheadBox.height * cameraView.bounds.height)
                let origin2 = CGPoint(x: foreheadBox.minX * cameraView.bounds.width,
                                 y: (1 - foreheadBox.minY) * cameraView.bounds.height - size2.height)
                
                
                //Dunno why but no need rotation
                let fBox = CGRect(origin: origin2, size: size2)
                
                
                foreheadBoxLayer.frame = fBox

                foreheadBoxLayer.borderWidth = 2
                
                
                //get forehead reading
                
                let x = fBox.midX
                let y = fBox.midY
                let point = CGPoint(x: x,y: y)
                let radius = Int32(Int(max(fBox.midY - fBox.minY, fBox.midX - fBox.minX)*1.2))
                //print("x:\(x)  y:\(y) radius:\(radius)")
            
                /* //wait until flir fix their SDK
                image.measurements.addRectangle(foreheadBox)
                let spot = image.measurements.measurementRectangles.firstObject as? FLIRMeasurementRectangle
                */
                
                image.measurements.addCircle(point, radius: radius)
                let spot = image.measurements.measurementCircles.firstObject as? FLIRMeasurementCircle
                
                guard let reading = spot?.max.value else{
                    return
                }
                
                tempLabel = UILabel(frame: (CGRect(origin: CGPoint(x: bBox.midX, y: bBox.minY), size: CGSize(width:50,height:20))))
                
                tempLabel.text = "\(String(format: "%.1f", (reading) ))"
                //color
                if fBox.midX == 0{
                    color = UIColor.gray
                }
                else if reading > 37.5{
                    color = UIColor.red
                }else if label == "without_mask" || label == "mask_weared_incorrect"{
                    color = UIColor.yellow
                }

            
            foreheadBoxLayer.borderColor = color.cgColor
            faceBoxLayer.borderColor = color.cgColor
            tempLabel.textColor = color
            
            

            
            //add all sublayer
            cameraView.layer.addSublayer(faceBoxLayer)
            cameraView.layer.addSublayer(foreheadBoxLayer)
            self.cameraView.addSubview(tempLabel)
        }
    }
    
    func getBoundingRectAfterRotation(rect: CGRect, angle: Float) -> CGRect {

        let newWidth : Float = Float(rect.size.width) * abs(cosf(angle)) + Float(rect.size.height) * abs(sinf(angle))

     

        let newHeight : Float = Float(rect.size.height) * abs(cosf(angle)) + Float(rect.size.width) * abs(sinf(angle))

     

     let newX : Float = Float(rect.origin.x) + ((Float(rect.size.width) - newWidth) / 2);

     let newY : Float = Float(rect.origin.y) + ((Float(rect.size.height) - newHeight) / 2);

        let rotatedRect : CGRect = CGRect(x: CGFloat(newX), y: CGFloat(newY), width: CGFloat(newWidth), height: CGFloat(newHeight))

     return rotatedRect

     }
    
    /*
    func handleFaces(with request: VNRequest) -> [CGRect] {
        cameraView.layer.sublayers?.forEach { layer in
            layer.removeFromSuperlayer()
        }
        var bBoxList = [CGRect]()
        guard let observations = request.results as? [VNFaceObservation] else {
            return []
        }
        observations.forEach { observation in
            let boundingBox = observation.boundingBox
            let origin:CGPoint
            let size:CGSize
            size = CGSize(width: boundingBox.width * cameraView.bounds.width,
                                  height: boundingBox.height * cameraView.bounds.height)
            origin = CGPoint(x: boundingBox.minX * cameraView.bounds.width,
                                     y: (1 - observation.boundingBox.minY) * cameraView.bounds.height - size.height)
            
            //let bBox = CGRect(origin: origin, size: size)
            
            let bBox = getBoundingRectAfterRotation(rect: CGRect(origin: origin, size: size), angle: .pi/2)
            
            
            //let layer = CAShapeLayer()
            //layer.frame = bBox
            //layer.borderColor = UIColor.red.cgColor
            //layer.borderWidth = 2
            
            //cameraView.layer.addSublayer(layer)
            
            
            bBoxList.append(bBox)
        }
        return bBoxList
    }
       */

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        camera.delegate = self
        discovery.delegate = self
    }

    
    @IBAction func startButtonPressed(_ sender: Any) {
        discovery.start(FLIRCommunicationInterface.lightning)

        //discovery.start(FLIRCommunicationInterface.emulator)
    }
    
    @IBAction func calibrateButtonPressed(_ sender: Any) {
        calibrate()
    }
    
    @objc private func calibrate(){
            if camera.isConnected(){
                camera.getRemoteControl()?.getCalibration()?.performNUC()
                
            }
    }
    
    lazy var detectionRequest: VNCoreMLRequest = {
        do{
            let model = try VNCoreMLModel(for: mask().model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processDetection(for: request, error: error)
            })
            request.imageCropAndScaleOption = .scaleFit
            return request
        }catch{
            fatalError("Cannot create model")
        }
    }()



    /*
    private func changeChargingLabel(state2 : FLIRChargingState){
        guard let state2 = self.camera.getRemoteControl()?.getBattery()?.getChargingState() else {return}
        if (state2 == FLIRChargingState(rawValue: 1)){
            chargingLabel.text = "Not charging"
        }else if (state2 == FLIRChargingState(rawValue: 2)){
            chargingLabel.text = "Charging"
        }
    }*/
    
    private func getBattery(){
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { timer in
                let percent = self.battery.getPercentage()
                self.batteryLabel.text = "\(String(percent))"
            }
        }
    }
    
    
}

class FaceBox{
    private var box = CGRect()
    private var label = String()
    private var foreheadBox = CGRect()
    
    init(box: CGRect, label:String) {
        self.box = box
        self.label = label
    }
    
    func setForeheadBox(foreheadBox:CGRect){
        self.foreheadBox = foreheadBox
    }
    
    func getBox() -> CGRect{
        return self.box
    }
    
    func getForeheadBox() -> CGRect{
        return self.foreheadBox
    }
    
    func getLabel() -> String{
        return self.label
    }
    
}


/*
class Human: Equatable{
    var uid: UUID
    var faceBox: CGRect
    var foreheadBox: CGRect
    var temp: Float
    var tag: String
    
    init(uid:UUID) {
        self.uid = uid
        self.faceBox =  CGRect()
        self.foreheadBox = CGRect()
        self.temp = Float()
        self.tag = String()
    }
    
    static func ==(lhs: Human, rhs: Human) -> Bool {
        return lhs.uid == rhs.uid
    }
}
*/
