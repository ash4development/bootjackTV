//
//  GradientImageView.swift
//  BootjackTV
//
//

import Foundation
import UIKit

class GradientOverlayImageView: UIImageView {
    var colors: [CGColor] = {
        [UIColor.clear.cgColor,
                           UIColor.black.withAlphaComponent(0.9).cgColor,
                           UIColor.black.cgColor]
    }() {
        didSet {
            gradient.colors = colors
        }
    }
    private lazy var gradient: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = colors
        gradient.type = .axial
        gradient.startPoint = CGPoint(x: 1, y: 1)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        layer.addSublayer(gradient)
        return gradient
    }()
    override func layoutSubviews() {
        super.layoutSubviews()
        UIView.performWithoutAnimation {
            self.gradient.frame = bounds
        }
    }
}
class RadialGradientImageView: UIImageView {
    private lazy var pulse: CAGradientLayer = {
        let l = CAGradientLayer()
        l.type = .radial
        
        l.colors = [ UIColor.clear.cgColor,
                     UIColor.black.withAlphaComponent(0.5).cgColor,
                     UIColor.black.cgColor]
        l.locations = [ 0,0.3 , 0.9]
        l.startPoint = CGPoint(x: 0.5, y: 0.5)
        l.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(l)
        return l
    }()
    private lazy var  linear: CAGradientLayer = {
        let l = CAGradientLayer()
        l.type = .axial
        
        l.colors = [ UIColor.clear.cgColor,
                     UIColor.black.withAlphaComponent(0.5).cgColor,
                     UIColor.black.cgColor]
        l.locations = [ 0,0.7 , 1]
        l.startPoint = CGPoint(x: 0.5, y: 0.5)
        l.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(l)
        return l
    }()
    override func layoutSubviews() {
        super.layoutSubviews()
        let maxVal = max(bounds.width, bounds.height)
        let minVal = min(bounds.width, bounds.height)
        UIView.performWithoutAnimation {
            pulse.frame = CGRect(origin: CGPoint(x: 0, y: -minVal), size: CGSize(width: maxVal*1.25, height: maxVal))
            self.linear.frame = bounds
        }
        
    }
}
