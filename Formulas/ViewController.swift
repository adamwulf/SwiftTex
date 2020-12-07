//
//  ViewController.swift
//  Formulas
//
//  Created by Adam Wulf on 12/7/20.
//

import Cocoa
import iosMath
import SwiftTexMac

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let label = MTMathUILabel()
        label.latex = "x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .textBackgroundColor
        label.textColor = .textColor
        label.textAlignment = .center
        self.view.addSubview(label)

        label.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        label.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true

        let source = "x_a + x_b^2"
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = (try? parser.parse()) ?? []

        print(ast)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}
