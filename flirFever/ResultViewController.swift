//
//  ResultViewController.swift
//  flirFever
//
//  Created by ＭＴ on 15/4/2021.
//

import UIKit

class ResultViewController: UIViewController{
    var image = UIImage()
    var type:String = ""
    var temp:Double = 0
    var color:UIColor = UIColor.red
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
        }else if type == "without_mask"{
            adviceLabel.text = "Wear a mask!"
            color = UIColor.yellow
        }else if type == "mask_weared_incorrect"{
            adviceLabel.text = "Wear a mask properly!"
            color = UIColor.yellow
        }else{
            adviceLabel.text = ""
            color = UIColor.green
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
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
