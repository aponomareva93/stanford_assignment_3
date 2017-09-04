//
//  GraphingView.swift
//  GraphingCalculator
//
//  Created by anna on 23.08.17.
//  Copyright © 2017 anna. All rights reserved.
//

import UIKit

@IBDesignable
class GraphingView: UIView {
    private let axesDrawer = AxesDrawer()
    
    var originSet: CGPoint? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private var origin: CGPoint {
        get {
            return originSet ?? CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        }
        set {
            originSet = newValue
        }
    }
    
    @IBInspectable
    var scale: CGFloat = 40.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var function: ((Double) -> (Double))? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    func changeScale(_ pinchRecognizer: UIPinchGestureRecognizer) {
        switch pinchRecognizer.state {
        case .changed, .ended:
            scale *= pinchRecognizer.scale
            pinchRecognizer.scale = 1
        default:
            break
        }
    }
    
    func moveGraph(_ panRecognizer: UIPanGestureRecognizer) {
        switch panRecognizer.state {
        case .ended, .changed:
            let translation = panRecognizer.translation(in: self)
            origin.x += translation.x
            origin.y += translation.y
            panRecognizer.setTranslation(CGPoint.zero, in: self)
        default:
            break
        }
    }
    
    func changeOrigin(_ tapRecognizer: UITapGestureRecognizer) {
        switch tapRecognizer.state {
        case .changed:
            originSet = tapRecognizer.location(in: self)
        default:
            break
        }
    }
    
    override func draw(_ rect: CGRect) {
        axesDrawer.drawAxes(in: bounds, origin: origin, pointsPerUnit: scale)
        drawGraph(bounds: bounds, origin: origin, scale: scale)
    }
    
    func drawGraph(bounds: CGRect, origin: CGPoint, scale: CGFloat) {
        if function != nil {
            var xGraph, yGraph: CGFloat
            var x, y: Double
            var isFirstPoint = true
            
            //asymptote points
            var oldYGraph: CGFloat = 0.0
            var isAsymptote: Bool {
                return abs(yGraph - oldYGraph) > max(bounds.width, bounds.height) * 1.5
            }
            
            let path = UIBezierPath()
            
            //bounds.size.width * contentScaleFactor - count of pixels
            for i in 0...Int(bounds.size.width * contentScaleFactor) {
                xGraph = CGFloat(i) / contentScaleFactor // current point's x-coordinate
                x = Double((xGraph - origin.x) / scale) // x-coordinate with taking into account origin offset and scale
                
                y = function!(x)
                
                if !y.isFinite {
                    continue
                } else {
                    yGraph = origin.y - CGFloat(y) * scale
                    if isFirstPoint {
                        path.move(to: CGPoint(x: xGraph, y: yGraph))
                        isFirstPoint = false
                    } else {
                        if isAsymptote {
                            isFirstPoint = true
                        } else {
                            path.addLine(to: CGPoint(x: xGraph, y: yGraph))
                        }
                    }
                }
                path.stroke()
            }
        }
    }
}
