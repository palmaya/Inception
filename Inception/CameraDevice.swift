//
//  Camera.swift
//  Inception
//
//  Created by katie lynn on 6/25/17.
//  Copyright © 2017 Palmaya. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class CameraDevice : NSObject, Camera, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    fileprivate var device : AVCaptureDevice?
    fileprivate var session : AVCaptureSession?
    fileprivate var input : AVCaptureInput?
    fileprivate var output : AVCaptureOutput?
    fileprivate let previewLayer : AVCaptureVideoPreviewLayer
    
    weak var delegate : CameraDelegate?
    
    var preview : CALayer {
        return previewLayer
    }
    
    override init() {
        self.previewLayer = AVCaptureVideoPreviewLayer()
        super.init()
        
        if let device = findBackFacingCamera(), let input = try? AVCaptureDeviceInput(device: device) {
            setup(device)
            let session = AVCaptureSession()
            session.sessionPreset = .high
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                print("Error adding device input to the capture session.")
            }
            self.previewLayer.session = session
            self.session = session
            self.input = input
            self.device = device
        } else {
            print("Error with video capture device.")
        }
    }
    
    fileprivate func findBackFacingCamera() -> AVCaptureDevice? {
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: .video, position: .back)
        for device in discoverySession.devices {
            if device.hasTorch {
                return device
            }
        }
        return discoverySession.devices.first
    }
    
    fileprivate func setup(_ device: AVCaptureDevice) {
        do { try device.lockForConfiguration() } catch { print(error)}
        
        if device.isFocusModeSupported(.continuousAutoFocus) {
        let focusPoint = CGPoint(x: 0.5, y: 0.5)
        device.focusPointOfInterest = focusPoint
        device.focusMode = .continuousAutoFocus
        } else {
            print("Video capture device doesn't support continuous autofocus mode.")
        }
        
        if device.hasTorch, device.isTorchModeSupported(.auto) {
            device.torchMode = .auto
        } else {
            print("Video capture device doesn't support auto torch mode.")
        }
        device.unlockForConfiguration()
    }
    
    func record() {
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        let queue = DispatchQueue(label: "com.palmaya.videocapture")
        
        videoDataOutput.setSampleBufferDelegate(self, queue: queue)
        if let session = session, session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
        }  else {
            print("Error adding video data output to the capture session.")
        }
        self.output = videoDataOutput
        
        let mediaType = AVMediaType.video
        AVCaptureDevice.requestAccess(for: mediaType) { granted in
            if granted {
                self.session?.startRunning()
            } else {
                print("Access denied for video capture.")
            }
        }
    }
    
    func setPreviewOrientation(_ orientation: UIInterfaceOrientation) {
        var captureVideoOrientation : AVCaptureVideoOrientation
        
        switch orientation {
        case .unknown:
            return
        case .portrait:
            captureVideoOrientation = .portrait
        case .portraitUpsideDown:
            captureVideoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            captureVideoOrientation = .landscapeLeft
        case .landscapeRight:
            captureVideoOrientation = .landscapeRight
        }
        
        if let connection = self.previewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = captureVideoOrientation
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate Methods
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer : CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil)
        delegate?.process(pixelBuffer, cameraIntrinsics: cameraIntrinsicData)
    }
}
