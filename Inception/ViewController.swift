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
    private var customView: View!
    private var requests = [VNRequest]()
    private var lastClassification : (identifier: String, confidence: VNConfidence)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupVision()
        
        let camera = CameraDevice()
        camera.delegate = self
        camera.record()
        self.camera = camera
        
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
        let customView = View()
        self.customView = customView
        customView.setupViewWithPreview(camera.preview)
        
        self.view.addSubview(customView)
        
        customView.snp.makeConstraints { make in
            make.width.equalTo(self.view)
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view)
            make.top.equalTo(self.view)
        }
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
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
                self.customView.printLabel.font = UIFont.systemFont(ofSize: 17)
                self.customView.printLabel.text = "... (?)"
                self.lastClassification = nil
                return
            }
            if classification.confidence > 0.5 {
                self.customView.printLabel.font = UIFont.boldSystemFont(ofSize: 17)
            } else if let lastClassification = self.lastClassification, !(lastClassification.identifier == classification.identifier) {
                self.customView.printLabel.font = UIFont.systemFont(ofSize: 17)
            }
            self.customView.printLabel.text = "\(classification.identifier) \(classification.confidence)"
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
    
    // MARK: - Device
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate(alongsideTransition: nil, completion: { _ in
            //maybe put in viewdidlayoutsubviews
            self.camera.setPreviewOrientation(UIApplication.shared.statusBarOrientation)
        })
        
        super.viewWillTransition(to: size, with: coordinator)
    }
}

