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

    @IBOutlet
    private var stackView: NSStackView?
    var source = "(a_2b_1 - b_2a_1)(a_1b_0 - b_1a_0) - (a_2b_0 - b_2a_0)^2"

    func appendLabelFor(math: String) {
        let label = MTMathUILabel()
        label.latex = math
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .textBackgroundColor
        label.textColor = .textColor
        label.textAlignment = .center
        stackView?.addArrangedSubview(label)

        label.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        label.heightAnchor.constraint(equalToConstant: 60).isActive = true
    }

    override func viewDidLoad() {
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = (try? parser.parse()) ?? []

        let printVisitor = PrintVisitor()
        printVisitor.ignoreSubscripts = false
        let maths = ast.accept(visitor: printVisitor)

        appendLabelFor(math: maths.joined(separator: "\\"))
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // MARK: - Actions

    @IBAction func expandFormula(_ sender: Any?) {
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = (try? parser.parse()) ?? []
        let foil = FoilVisitor()
        foil.singleStep = true
        let printVisitor = PrintVisitor()
        printVisitor.ignoreSubscripts = false
        let maths = ast.accept(visitor: foil).accept(visitor: printVisitor)

        if let math = maths.first {
            source = math

            appendLabelFor(math: source)
        }
    }

}
