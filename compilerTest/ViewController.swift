//
//  ViewController.swift
//  compilerTest
//
//  Created by Jessi Febria on 30/05/21.
//

import UIKit

class ViewController: UIViewController {
    
    
    @IBOutlet weak var codeField: UITextView!
    @IBOutlet weak var outputField: UITextView!
    
    let compilerService = CompilerService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        codeField.delegate = self
        compilerService.delegate = self
        
        let tapper = UITapGestureRecognizer(target: self, action:#selector(endEditing))
        tapper.cancelsTouchesInView = false
        view.addGestureRecognizer(tapper)
        
    }
    
    @IBAction func compilePressed(_ sender: UIButton) {
        let codeTyped = codeField.text
        
        compilerService.compileCode(code: codeTyped!)
        
    }
    
}

extension ViewController : UITextViewDelegate {
    
    @objc func endEditing(){
        DispatchQueue.main.async {
            self.codeField.resignFirstResponder()
        }
    }
    
}

extension ViewController : CompilerServiceDelegate {
    func updateUI(result: String, output: String) {
        outputField.text = "\(result)\n\n\(output)"
    }
    
    
    
}
