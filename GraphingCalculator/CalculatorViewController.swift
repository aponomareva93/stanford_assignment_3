//
//  ViewController.swift
//  Calculator
//
//  Created by anna on 30.06.17.
//  Copyright © 2017 anna. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {
    
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var operationsLabel: UILabel!
    @IBOutlet weak var variableValueLabel: UILabel!
    @IBOutlet weak var graphButton: UIButton! {
        didSet {
            graphButton.isEnabled = false
            graphButton.backgroundColor = UIColor.gray
        }
    }
    
    var userIsInTheMiddleOfTyping = false
    private let initialDisplayValue: String = "0"
    private var variables = [String: Double]() // dictionary of variables ( in our case consists just of M)
    private let memoryVariableName = "M"
    
    private let graphSegueIdentifier = "Show Graph"
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var destinationViewController = segue.destination
        if let navigationController = destinationViewController as? UINavigationController {
            destinationViewController = navigationController.visibleViewController ?? destinationViewController
        }
        
        if let graphingVC = destinationViewController as? GraphingViewController,
            let identifier = segue.identifier, identifier == graphSegueIdentifier {
            graphingVC.function = { [weak weakSelf = self] x in
                weakSelf?.variables[(weakSelf?.memoryVariableName)!] = x
                return weakSelf?.brain.evaluate(using: weakSelf?.variables).result ?? 0
            }
            graphingVC.navigationItem.title = "y = " + brain.evaluate(using: variables).description
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == graphSegueIdentifier {
            return !brain.evaluate(using: variables).isPending
        }
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        brain.addUnaryOperation(named: "✅", { [weak weakSelf = self] in
            weakSelf?.display.textColor = UIColor.green
            return sqrt($0)
        }, {$0 < 0 ? "Input value must be 0 or greater" : nil})
        
        variableValueLabel.text = memoryVariableName + " = " // will show "M = "
    }
    
    @IBAction func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle!
        
        if userIsInTheMiddleOfTyping {
            let textCurrentlyInDisplay = display.text!
            if digit == "." && textCurrentlyInDisplay.contains(".") {
                return
            }
            display.text = textCurrentlyInDisplay + digit
        } else {
            if digit == "." {
                display.text = initialDisplayValue + digit
            } else {
                display.text = digit
            }
            userIsInTheMiddleOfTyping = true
        }
    }
    
    var displayValue: Double {
        get {
            return Double(display.text!)!
        }
        set {
            graphButton.isEnabled = true
            graphButton.backgroundColor = brain.evaluate(using: variables).isPending ? UIColor.gray : UIColor.white
            display.text = newValue.formatNumber()
        }
    }

    private var brain = CalculatorBrain()
    
    //calculate result and display it or display an error
    func calculateResult() {
        let calculatingResult = brain.evaluate(using: variables)
        if let result = calculatingResult.result {
            if let errorText = calculatingResult.error {// if we have an error, dispdlay it
                display.text = errorText
            } else {//if we don't have any errors, display result
                displayValue = result
                operationsLabel.text = brain.description + "="
            }
        }
    }
    
    @IBAction func performOperation(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping {
            brain.setOperand(displayValue)
            userIsInTheMiddleOfTyping = false
        }        
        if let mathematicalSymbol = sender.currentTitle {
            brain.setOperation(mathematicalSymbol)
            operationsLabel.text = brain.description + "..."
        }
        calculateResult()
    }
    
    @IBAction func setVariableName(_ sender: UIButton) { // set "M"-variable
        brain.setOperand(variable: memoryVariableName)
    }
    
    @IBAction func setVariableValue(_ sender: UIButton) { // evaluate with the set value of "M"
        variables[memoryVariableName] = displayValue
        variableValueLabel.text = memoryVariableName + " = " + variables[memoryVariableName]!.formatNumber()
        calculateResult()
        userIsInTheMiddleOfTyping = false
    }
    
    @IBAction func clear(_ sender: UIButton) {
        userIsInTheMiddleOfTyping = false
        display.text = initialDisplayValue
        operationsLabel.text = display.text
        variables = Dictionary<String, Double>()
    }
    
    @IBAction func undo(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping { // if we delete digit (like backspace button)
            display.text?.remove(at: display.text!.index(before:display.text!.endIndex))
            if display.text!.isEmpty {
                userIsInTheMiddleOfTyping = false
                display.text = initialDisplayValue
            }
        } else { // if we undo operation
            brain.undo()
            operationsLabel.text = brain.description
            calculateResult()
            
            if brain.description.isEmpty {
                operationsLabel.text = initialDisplayValue
                display.text = initialDisplayValue
            }
        }
    }
}

