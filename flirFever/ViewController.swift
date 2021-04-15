//
//  ViewController.swift
//  flirFever
//
//  Created by ＭＴ on 30/12/2020.
//

import UIKit
import Vision
import Toast
import AVFoundation
import CoreBluetooth

let envServiceCBUUID = CBUUID(string: "0xFFE0")
let envCharacteristicCBUUID = CBUUID(string: "0xFFE1")

// MARK: keyboard extension
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: bluetooth extension delegate
extension ViewController: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .unknown:
                print("central.state is .unknown")
            case .resetting:
                print("central.state is .resetting")
            case .unsupported:
                print("central.state is .unsupported")
            case .unauthorized:
                print("central.state is .unauthorized")
            case .poweredOff:
                print("central.state is .poweredOff")
            case .poweredOn:
                print("central.state is .poweredOn")
                centralManager.scanForPeripherals(withServices: [envServiceCBUUID])
            @unknown default:
                print("unknown")
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        envPeripheral = peripheral
        envPeripheral.delegate = self
        print(envPeripheral!)
        centralManager.stopScan()
        centralManager.connect(envPeripheral)
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        envPeripheral.discoverServices([envServiceCBUUID])
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        updateBluetoothLabel(connected: false)
    }
}

extension ViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)

        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            print(self.envPeripheral?.readValue(for: characteristic) ?? 0)
          print(characteristic)
            updateBluetoothLabel(connected: true)
            if characteristic.properties.contains(.read) {
                print("\(characteristic.uuid): properties contains .read")
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
            case envCharacteristicCBUUID:
                let data = envData(from: characteristic)
                let envArr = data.components(separatedBy: ",")
                if envArr.count > 1{
                    print(envArr[0])
                    print(envArr[1])
                    print(envArr[2].trimmingCharacters(in: .whitespacesAndNewlines))
                    self.objectDistance = Float(envArr[0])!
                    self.atmosphericTemperature = Float(envArr[1])!
                    self.relativeHumidity = Float(envArr[2])! / 100
                    updateThreeEnvLabel()
                }else{
                    print("Receiving Data")
                }
                
            default:
                print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    private func envData(from characteristic: CBCharacteristic) -> String {
        guard let characteristicData = characteristic.value else { return "" }
        let byteArray:String = String(decoding: characteristicData, as: UTF8.self)
        return byteArray
    }
}


// MARK: class start
class ViewController: UIViewController, FLIRDiscoveryEventDelegate, FLIRDataReceivedDelegate, FLIRRemoteDelegate {
    let camera = FLIRCamera()
    let discovery = FLIRDiscovery()
    var calibration = FLIRCalibration()
    var battery = FLIRBattery()
    let pm = FLIRPaletteManager()
    var flip:Int = 0
    var image = FLIRThermalImage()
    var faceBoxList = [FaceBox]()
    var emissivity:Float = 0.95
    var objectDistance:Float = 1
    var atmosphericTemperature:Float = 27
    var relativeHumidity:Float = 0.5
    var foreheadFrameCounted = 0
    var type = ""
    var reading = 0.0
    var color = UIColor.green
    var photo = UIImage()
    var isShowingResult = false
    var mode = 0
    var player:AVAudioPlayer?
    var centralManager: CBCentralManager!
    var envPeripheral: CBPeripheral!
    //var humanList = [Human]()
    
    @IBOutlet weak var bluetoothLabel: UILabel!
    @IBOutlet weak var chargingLabel: UILabel!
    
    @IBOutlet weak var batteryLabel: UILabel!
    
    @IBOutlet weak var cameraView: UIImageView!
    
    
    @IBOutlet weak var objd_text: UITextField!
    @IBOutlet weak var at_text: UITextField!
    @IBOutlet weak var rh_text: UITextField!
    
    // MARK: UI delegate
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToResult"{
            let resultVC = segue.destination as! ResultViewController
            resultVC.dismiss(animated: false, completion: nil)
            resultVC.type = self.type
            resultVC.temp = self.reading
            resultVC.image = self.photo
            resultVC.color = self.color
            resultVC.mainController = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        definesPresentationContext = true
        // Do any additional setup after loading the view.
        camera.delegate = self
        discovery.delegate = self
        
        self.hideKeyboardWhenTappedAround()
        objd_text.keyboardType = .decimalPad
        at_text.keyboardType = .decimalPad
        rh_text.keyboardType = .numberPad
        updateThreeEnvLabel()
    }
    
    // MARK: camera delegate
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
            //calibrate()
            self.view.makeToast("Camera connected", duration: 3.0, position: .bottom)
            if discovery.isDiscovering(){
                discovery.stop()
            }
        }

        
    }
    
    func calibrationStateChanged(_ state: Bool) {
        //trash, does not work
    }
    
    func chargingStateChanged(_ state: FLIRChargingState) {
        //trash, does not work
    }
    
    func percentageChanged(_ percent: Int32) {
        //trash, does not work
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
        camera.unsubscribeStream()
        camera.disconnect()
        self.view.makeToast("Camera disconnected", duration: 3.0, position: .bottom)
    }
    
    private func getBattery(){
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { timer in
                let percent = self.battery.getPercentage()
                self.batteryLabel.text = "\(String(percent))"
                let charging = self.battery.getChargingState()
                if charging == FLIRChargingState.MANAGEDCHARGING{
                    self.chargingLabel.isHidden = false
                }else{
                    self.chargingLabel.isHidden = true
                }
            }
        }
    }
    
    @objc private func calibrate(){
            if camera.isConnected(){
                camera.getRemoteControl()?.getCalibration()?.performNUC()
                
            }
    }
    
    // MARK: IBAction
    @IBAction func flipCamera(_ sender: Any) {
        if (flip==0){
            cameraView.transform = CGAffineTransform(scaleX: -1, y: 1)
            flip = 1
        }else{
            flip = 0
            cameraView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    @IBAction func startButtonPressed(_ sender: Any) {
        discovery.start(FLIRCommunicationInterface.lightning)

        //discovery.start(FLIRCommunicationInterface.emulator)
    }
    
    @IBAction func calibrateButtonPressed(_ sender: Any) {
        calibrate()
    }
    
    @IBAction func objd_textChanged(_ sender: UITextField) {
        let currentValue = Float(sender.text!)
        if (currentValue! > 1 || currentValue! < 0) {
            objd_text.text = "1.0"
        }else{
            objd_text.text = String(format: "%.2f", currentValue!)
            self.objectDistance = getRange()
        }
    }
    
    
    @IBAction func at_textChanged(_ sender: UITextField) {
        let currentValue = Float(sender.text!)
        if (currentValue! > 40 || currentValue! < -10) {
            at_text.text = "25.0"
        }else{
            at_text.text = String(format: "%.1f", currentValue!)
            self.atmosphericTemperature = getATemp()
        }
    }
    
    @IBAction func rh_textChanged(_ sender: UITextField) {
        let currentValue = Float(sender.text!)
        if (currentValue! >= 100 || currentValue! <= 0) {
            rh_text.text = "50"
        }else{
            rh_text.text = String(format: "%.0f", currentValue!)
            self.relativeHumidity = getRH()/100
        }
    }
    
    @IBAction func modeSwitch(_ sender: Any) {
        if mode == 0{
            mode = 1
        }else{
            mode = 0
        }
    }
    
    // MARK: AI related
    
    //this one is actually camera's delegate but it includes VNImageRequestHandler
    //so it is better here
    func imageReceived() {
        DispatchQueue.main.async{
            self.cameraView.layer.sublayers?.forEach { layer in
                layer.removeFromSuperlayer()
            }
            self.camera.withImage { (image: FLIRThermalImage) in
                self.faceBoxList = [FaceBox]()
                self.image = image
                image.getParameters()?.emissivity = self.emissivity
                image.getParameters()?.objectDistance = self.objectDistance
                image.getParameters()?.atmosphericTemperature = self.atmosphericTemperature
                image.getParameters()?.relativeHumidity = self.relativeHumidity
                //let para = image.getParameters()
                //print("ems: \(para!.emissivity), D: \(para!.objectDistance), Humid: \(para!.relativeHumidity), temp: \(para!.atmosphericTemperature)")
                let fusion:FLIRFusion! = self.image.getFusion()
                self.image.palette = self.pm.rainbow
                //image.rotate(RotationAngle(rawValue: 0)!)
                fusion.setFusionMode(IR_MODE)
                let irImage:UIImage! = self.image.getImage()
                self.photo = irImage
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
        }
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
                    if observation.confidence > 0.1{ //50% confidence threshold
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
            self.type = label
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
            
            if foreheadBox != CGRect() {
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
                let radius = Int32(Int(max(fBox.midY - fBox.minY, fBox.midX - fBox.minX)))
                //print("x:\(x)  y:\(y) radius:\(radius)")
            
                /* //wait until flir fix their SDK
                image.measurements.addRectangle(foreheadBox)
                let spot = image.measurements.measurementRectangles.firstObject as? FLIRMeasurementRectangle
                */
                
                image.measurements.addCircle(point, radius: radius)
            }else{
                let x = bBox.midX
                let y = bBox.midY
                let point = CGPoint(x: x,y: y)
                let radius = Int32(Int(max(bBox.midY - bBox.minY, bBox.midX - bBox.minX)))
                image.measurements.addCircle(point, radius: radius)
            }
            

            let spot = image.measurements.measurementCircles.firstObject as? FLIRMeasurementCircle
            
            guard let reading = spot?.max.value else{
                return
            }
            
            if reading > self.reading{
                self.reading = reading
            }
            
            tempLabel = UILabel(frame: (CGRect(origin: CGPoint(x: bBox.midX, y: bBox.minY), size: CGSize(width:50,height:20))))
            
            tempLabel.text = "\(String(format: "%.1f", (reading) ))"
            //color
            if !facebox.hasForeheadBox(){
                color = UIColor.gray
                foreheadFrameCounted = 0
            }
            else if reading > 37.5{
                playSound(type: "alarm")
                color = UIColor.red
                foreheadFrameCounted += 1
            }else if label == "without_mask" || label == "mask_weared_incorrect"{
                color = UIColor.yellow
                foreheadFrameCounted += 1
            }else{
                color = UIColor.green
                foreheadFrameCounted += 1
            }
            self.color = color
            
            //count if received 5 consective image with forehead shown
            if foreheadFrameCounted >= 5 && !isShowingResult && mode == 1
            {
                isShowingResult = true
                self.performSegue(withIdentifier: "goToResult", sender: self)
                self.reading = 0
            }else if isShowingResult{
                self.reading = 0
                foreheadFrameCounted = 0
            }else if mode == 0{
                self.reading = 0
                foreheadFrameCounted = 0
            }

            
            foreheadBoxLayer.borderColor = color.cgColor
            faceBoxLayer.borderColor = color.cgColor
            tempLabel.textColor = color
            if flip == 1{
                tempLabel.transform = CGAffineTransform(scaleX: -1, y: 1)
            }
            

            
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
    

    
    lazy var detectionRequest: VNCoreMLRequest = {
        do{
            let model = try VNCoreMLModel(for: mask(configuration: MLModelConfiguration()).model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processDetection(for: request, error: error)
            })
            request.imageCropAndScaleOption = .scaleFit
            return request
        }catch{
            fatalError("Cannot create model")
        }
    }()
    // MARK: Update UI method
    func updateThreeEnvLabel(){
        objd_text.text = NSString(format: "%.2f", self.objectDistance) as String
        at_text.text = NSString(format: "%.2f", self.atmosphericTemperature) as String
        rh_text.text = NSString(format: "%.0f", (self.relativeHumidity)*100) as String
    }
    
    func updateBluetoothLabel(connected:Bool){
        if connected{
            bluetoothLabel.text = "Bluetooth\nConnected"
            bluetoothLabel.textColor = UIColor.green
        }else{
            bluetoothLabel.text = "Bluetooth\nDisconnected"
            bluetoothLabel.textColor = UIColor.red
        }
    }
    
    // MARK:other functions
    func getRange() ->Float{
        let currentValue = Float(objd_text.text!)
        return currentValue!
    }
    func getATemp()->Float{
        let currentValue = Float(at_text.text!)
        return currentValue!
    }
    func getRH()->Float{
        let currentValue = Float(rh_text.text!)
        return currentValue!
    }
    
    
    func rectInsideRect(smallRect: CGRect, bigRect: CGRect) -> Bool {
        return (smallRect.minX >= bigRect.minX && smallRect.minY >= bigRect.minY
                    && smallRect.maxX <= bigRect.maxX && smallRect.maxY <= bigRect.maxY)
    }
    
    func playSound(type:String){
        guard let url = Bundle.main.url(forResource: type, withExtension: "wav") else {return}
        
        do{
            try AVAudioSession.sharedInstance().setCategory(.playback,mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
            guard let player = player else {return}
            
            player.play()
        } catch let error{
            print(error.localizedDescription)
        }
    }
    

    
}

//MARK: FaceBox class
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
    
    func hasForeheadBox() -> Bool{
        if self.foreheadBox.midX != 0{
            return true
        }else{
            return false
        }
    }
    
}


