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
    
    private var camera: Camera!
    private var previewLayer: CALayer!
    private var printLabel: UILabel!
    private var requests = [VNRequest]()
    private var lastClassification : (identifier: String, confidence: VNConfidence)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupVision()
        setupViews()
    }
    
    private func setupVision() {
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
            fatalError("Error loading ML model")
        }
        let classificationRequest = VNCoreMLRequest(model: model, completionHandler: self.processResults)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop
        self.requests = [classificationRequest]
    }
    
    private func setupViews() {
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
    
    fileprivate func processResults(request: VNRequest, error: Error?) {
        guard let observations = request.results
            else { fatalError("\(error?.localizedDescription ?? "no results")") }
        
        let classifications = observations[0...4]
            .flatMap({ $0 as? VNClassificationObservation })
            .filter({ $0.confidence > 0.3})
            .map({ (identifier: $0.identifier, confidence: $0.confidence)})
        
        DispatchQueue.main.async {
            guard let classification = classifications.first else {
                self.printLabel.font = UIFont.systemFont(ofSize: 17)
                self.printLabel.text = "... (?)"
                self.lastClassification = nil
                return
            }
            if classification.confidence > 0.5 {
                self.printLabel.font = UIFont.boldSystemFont(ofSize: 17)
            } else if let lastClassification = self.lastClassification, !(lastClassification.identifier == classification.identifier) {
                self.printLabel.font = UIFont.systemFont(ofSize: 17)
            }
            self.printLabel.text = "\(classification.identifier) \(classification.confidence)"
            self.lastClassification = classification
        }
    }
    
    fileprivate func exifOrientationFromDeviceOrientation() -> Int32 {
        let exifOrientation: DeviceOrientation
        enum DeviceOrientation : Int32 {
            case top0ColLeft
            case top0ColRight
            case bottom0ColRight
            case bottom0ColLeft
            case left0ColTop
            case right0ColTop
            case right0ColBottom
            case left0ColBottom
        }
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            exifOrientation = .left0ColBottom
        case .landscapeLeft:
            exifOrientation = .top0ColLeft
        case .landscapeRight:
            exifOrientation = .bottom0ColRight
        default:
            exifOrientation = .right0ColTop
        }
        return exifOrientation.rawValue
    }
    
    // MARK: - Camera Delegate Methods
    
    func process(_ pixelBuffer: CVImageBuffer, cameraIntrinsics: Any? = nil) {
        var requestOptions : [VNImageOption : Any] = [:]
        
        if let cameraIntrinsicData = cameraIntrinsics {
            requestOptions = [.cameraIntrinsics : cameraIntrinsicData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: self.exifOrientationFromDeviceOrientation(), options: requestOptions)
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
}

