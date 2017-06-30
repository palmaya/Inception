//
//  ViewController.swift
//  Inception
//
//  Created by katie lynn on 6/25/17.
//  Copyright © 2017 Palmaya. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController, CameraDelegate {
    
    var camera: Camera!
    var previewLayer: CALayer!
    var printLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    fileprivate func setupViews() {
        let label = UILabel()
        self.view.addSubview(label)
        label.snp.makeConstraints { make in
            make.width.equalTo(view)
            make.bottom.equalTo(view)
            make.height.equalTo(75)
        }
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.textAlignment = .center
        self.printLabel = label
        
        let camera = CameraDevice()
        camera.delegate = self
        camera.record()
        self.camera = camera
        
        let previewView = UIView()
        self.view.addSubview(previewView)
        previewView.snp.makeConstraints { make in
            make.width.equalTo(view)
            make.centerX.equalTo(view)
            make.bottom.equalTo(label.snp.top)
            make.top.equalTo(view)
        }
        self.view.setNeedsLayout()
        self.view.layoutSubviews()
        
        let previewLayer = camera.preview
        previewLayer.frame = previewView.frame
        previewView.layer.addSublayer(previewLayer)
        
        self.previewLayer = previewLayer
    }
    
    var lastClassification : VNClassificationObservation?
    
    fileprivate func processResults(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation]
            else { fatalError("huh") }
        
        let sortedResults = results.sorted {$0.confidence > $1.confidence}
        if let classification = sortedResults.first {
            DispatchQueue.main.async {
                if classification.confidence > 0.5 {
                    self.printLabel.font = UIFont.boldSystemFont(ofSize: 17)
                } else if let lastClassification = self.lastClassification, !(lastClassification.identifier == classification.identifier) {
                   self.printLabel.font = UIFont.systemFont(ofSize: 17)
                }
                self.printLabel.text = "\(classification.identifier) : \(classification.confidence)"
                self.lastClassification = classification
            }
        }
    }
    
    // MARK: - Camera Delegate Methods
    
    func process(_ imageBuffer: CVImageBuffer) {
        var model : VNCoreMLModel?
        do {
            model = try VNCoreMLModel(for: Inceptionv3().model)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        if let model = model {
            let request = VNCoreMLRequest(model: model, completionHandler: processResults)
                        
            let requestHandler = VNSequenceRequestHandler()
            do { try requestHandler.perform([request], on: imageBuffer)} catch { print(error)}
        }
    }
}

