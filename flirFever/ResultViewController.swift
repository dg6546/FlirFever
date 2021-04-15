//
//  ResultViewController.swift
//  flirFever
//
//  Created by ＭＴ on 15/4/2021.
//

import UIKit
import AVFoundation

class ResultViewController: UIViewController{
    var image = UIImage()
    var type:String = ""
    var temp:Double = 0
    var color:UIColor = UIColor.red
    var player:AVAudioPlayer?
    var mainController = UIViewController()
    @IBOutlet weak var adviceLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var resultCameraView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tempLabel.text = NSString(format: "%.1f", self.temp) as String
        if temp > 37.5{ //fever!
            color = UIColor.red
            adviceLabel.text = "FEVER!"
            playSound(type: "alarm")
        }else if type == "without_mask"{
            adviceLabel.text = "Wear a mask!"
            color = UIColor.yellow
            playSound(type: "bad")
        }else if type == "mask_weared_incorrect"{
            adviceLabel.text = "Wear a mask properly!"
            color = UIColor.yellow
            playSound(type: "bad")
        }else{
            adviceLabel.text = ""
            color = UIColor.green
            playSound(type: "good")
        }
        //print("\(type) , \(color) ")
        adviceLabel.textColor = color
        tempLabel.textColor = color
        resultCameraView.image = image
        
     //label == "with_mask" || label == "without_mask" || label == "mask_weared_incorrect"
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        let mc = mainController as! ViewController
        mc.isShowingResult = false
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
    @IBAction func backButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
