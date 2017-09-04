//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by anna on 01.07.17.
//  Copyright © 2017 anna. All rights reserved.
//

import Foundation

struct CalculatorBrain {
    
    mutating func addUnaryOperation(named symbol: String, _ operation: @escaping (Double) -> Double, _ errorHandler: @escaping (Double) -> String?) {
        operations[symbol] = Operation.unaryOperation(operation, {symbol + "(" + $0 + ")"}, errorHandler)
    }
    
    private var operationSequence = [expressionObject]()
    
    private enum expressionObject {
        case operand(Double)
        case operation(String)
        case variable(String)
    }
    
    private enum Operation { // operation, its string representation and its error handler
        case constant(Double)
        case unaryOperation((Double) -> Double, (String) -> String, (Double) -> String?)
        case binaryOperation((Double, Double) -> Double, (String, String) -> String, (Double) -> String?)
        case random
        case equals
    }
    
    private var operations: Dictionary<String, Operation> = [
        "π": Operation.constant(Double.pi),
        "e": Operation.constant(M_E),
        "√": Operation.unaryOperation(sqrt, {"√(" + $0 + ")"}, {$0 < 0 ? "Input value must be 0 or greater" : nil}),
        "cos": Operation.unaryOperation(cos, {"cos(" + $0 + ")"}, {_ in nil}),
        "±": Operation.unaryOperation({-$0}, {"-(" + $0 + ")"}, {_ in nil}),
        "×": Operation.binaryOperation({ $0 * $1 }, {$0 + "*" + $1}, {_ in nil}),
        "÷": Operation.binaryOperation({ $0 / $1 }, {$0 + "/" + $1}, {$0 == 0 ? "Input value must be not 0" : nil}),
        "+": Operation.binaryOperation({ $0 + $1 }, {$0 + "+" + $1}, {_ in nil}),
        "-": Operation.binaryOperation({ $0 - $1 }, {$0 + "-" + $1}, {_ in nil}),
        "=": Operation.equals,
        "sin": Operation.unaryOperation(sin, {"sin(" + $0 + ")"}, {_ in nil}),
        "tan": Operation.unaryOperation(tan, {"tan(" + $0 + ")"}, {_ in nil}),
        "ln": Operation.unaryOperation(log, {"log(" + $0 + ")"}, {$0 <= 0 ? "Input value must be 0 or greater" : nil}),
        "log": Operation.unaryOperation(log10, {"log10(" + $0 + ")"}, {$0 <= 0 ? "Input value must be 0 or greater" : nil}),
        "Random": Operation.random
    ]
    
    private struct PendingBinaryOperation{
        let function: (Double, Double) -> Double
        let firstOperand: (Double, String)
        let description: (String, String) -> String
        let errorHandler: (Double) -> String?
        
        func perform(with secondOperand: (Double, String, String?)) -> (Double, String,String?) {
            return (function(firstOperand.0, secondOperand.0), description(firstOperand.1, secondOperand.1), errorHandler(secondOperand.0))
        }
    }
    
    mutating func setOperand(_ operand: Double) {
        operationSequence.append(expressionObject.operand(operand))
    }
    
    mutating func setOperand(variable named: String) {
        operationSequence.append(expressionObject.variable(named))
    }
    
    mutating func setOperation(_ operation: String) {
        operationSequence.append(expressionObject.operation(operation))
    }
    
    func evaluate(using variables: Dictionary<String, Double>? = nil) -> (result: Double?, isPending: Bool, description: String, error: String?) {
        var accumulator: (Double, String, String?)? // value, description, error text
        var pendingBinaryOperation: PendingBinaryOperation?
        
        func performPendingBinaryOperation() {
            if pendingBinaryOperation != nil && accumulator != nil {
                accumulator = pendingBinaryOperation!.perform(with: accumulator!)
                pendingBinaryOperation = nil
            }
        }
        
        var result: Double? {
            get {
                if accumulator != nil {
                    return accumulator!.0
                }
                return nil
            }
        }
        
        var resultIsPending: Bool {
            get {
                if pendingBinaryOperation == nil {
                    return false
                } else {
                    return true
                }
            }
        }
        
        var description: String {
            get {
                if resultIsPending {
                    return pendingBinaryOperation!.description(pendingBinaryOperation!.firstOperand.1, accumulator?.1 ?? String())
                } else {
                    if let unwrappedDescription = accumulator?.1 {
                        return unwrappedDescription
                    }
                    return String()
                }
            }
        }
        
        var error: String? {
            get {
                if accumulator != nil {
                    return accumulator!.2
                }
                return nil
            }
        }
        
        for object in operationSequence {
            switch object {
            case .operand(let operand):
                accumulator = (operand, operand.formatNumber(), nil)
            case .operation(let symbol):
                if let operation = operations[symbol] {
                    switch operation {
                    case .constant(let value):
                        accumulator = (value, symbol, nil)
                    case .unaryOperation(let function, let description, let errorHandler):
                        if accumulator != nil {
                            accumulator = (function(accumulator!.0), description(accumulator!.1), errorHandler(accumulator!.0))
                        }
                    case .binaryOperation(let function, let description, let errorHandler):
                        if accumulator != nil {
                            pendingBinaryOperation = PendingBinaryOperation(function: function, firstOperand: (accumulator!.0, accumulator!.1), description: description, errorHandler: errorHandler)
                            accumulator = nil
                        }
                    case .equals:
                        performPendingBinaryOperation()
                    case .random:
                        accumulator = (Double(arc4random())/Double(UINT32_MAX), "random()", nil)
                    }
                }
            case .variable(let variable):
                if let value = variables?[variable] {
                    accumulator = (value, String(value), nil)
                } else {
                    accumulator = (0, variable, nil)
                }
            }
        }
        
        return (result, resultIsPending, description, error)
    }
    
    var result: Double? {
        get {
            return evaluate().result
        }
    }
    
    var resultIsPending: Bool {
        get {
            return evaluate().isPending
        }
    }
    
    var description: String {
        get {
            return evaluate().description
        }
    }
    
    mutating func undo() { // undo the last operation
        if !operationSequence.isEmpty {
            operationSequence.removeLast()
        }
    }
}

extension Double {
    func formatNumber() -> String {
        let formatter = NumberFormatter()
        if self.truncatingRemainder(dividingBy: 1) == 0 { //format for integers
            formatter.maximumFractionDigits = 0
        } else {    //format for decimals
            formatter.maximumFractionDigits = 4
            formatter.minimumIntegerDigits = 1
        }
        return formatter.string(from: self as NSNumber)!
    }
}
