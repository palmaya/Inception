//
//  View.swift
//  Inception
//
//  Created by katie lynn on 7/9/17.
//  Copyright © 2017 Palmaya. All rights reserved.
//

import Foundation
import UIKit

class View : UIView {
    
    var printLabel: UILabel!
    private var previewView : UIView!
    private var previewLayer : CALayer!
    
    func setupViewWithPreview(_ previewLayer: CALayer) {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.textAlignment = .center
        self.addSubview(label)
        self.printLabel = label
        
        let previewView = UIView()
        self.addSubview(previewView)
        self.previewView = previewView
        
        previewView.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
        
        updateConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = previewView.bounds
    }
    
    override func updateConstraints() {
        
        previewView.snp.makeConstraints { make in
            make.width.equalTo(self)
            make.centerX.equalTo(self)
            make.bottom.equalTo(self.printLabel.snp.top)
            make.top.equalTo(self)
        }
        
        printLabel.snp.makeConstraints { make in
            make.width.equalTo(self)
            make.bottom.equalTo(self)
            make.height.equalTo(75)
        }
        super.updateConstraints()
    }
}
