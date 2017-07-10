//
//  Protocols.swift
//  Inception
//
//  Created by katie lynn on 6/25/17.
//  Copyright © 2017 Palmaya. All rights reserved.
//

import Foundation
import UIKit
import CoreVideo

protocol Camera {
    var preview : CALayer { get }
    func record()
    func setPreviewOrientation(_ orientation: UIInterfaceOrientation)
}

protocol CameraDelegate: class {
    func process(_ pixelBuffer: CVImageBuffer, cameraIntrinsics: Any?)
}
