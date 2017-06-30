//
//  Protocols.swift
//  Inception
//
//  Created by katie lynn on 6/25/17.
//  Copyright © 2017 Palmaya. All rights reserved.
//

import Foundation
import QuartzCore
import CoreVideo

protocol Camera {
    var preview : CALayer { get }
    func record()
}

protocol CameraDelegate: class {
    func process(_ imageBuffer: CVImageBuffer)
}
