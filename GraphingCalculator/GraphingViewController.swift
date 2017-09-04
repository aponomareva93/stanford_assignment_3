//
//  ViewController.swift
//  GraphingCalculator
//
//  Created by anna on 23.08.17.
//  Copyright © 2017 anna. All rights reserved.
//

import UIKit

class GraphingViewController: UIViewController {
    
    @IBOutlet weak var graphingView: GraphingView! {
        didSet {
            //pinching - change scale
            let pinchRecognizer = UIPinchGestureRecognizer(target: graphingView, action: #selector(GraphingView.changeScale(_:)))
            graphingView.addGestureRecognizer(pinchRecognizer)
            
            //panning - move graph
            let panRecognizer = UIPanGestureRecognizer(target: graphingView, action: #selector(GraphingView.moveGraph(_:)))
            graphingView.addGestureRecognizer(panRecognizer)
            
            //double-tapping - move graph origin
            let tapRecognizer = UITapGestureRecognizer(target: graphingView, action: #selector(GraphingView.changeOrigin(_:)))
            tapRecognizer.numberOfTapsRequired = 2
            graphingView.addGestureRecognizer(tapRecognizer)
            
            updateUI()
        }
    }
    
    var function: ((Double) -> (Double))? {
        didSet {
            updateUI()
        }
    }
    
    func updateUI() {
        graphingView?.function = function
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

