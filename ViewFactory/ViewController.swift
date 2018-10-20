//
//  ViewController.swift
//  ViewFactory
//
//  Created by Sam Rayner on 19/10/2018.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let darkView = UIView(frame: CGRect(x: 150, y: 300, width: 100, height: 100),
                              factory: DarkTheme.shared,
                              tagged: [.danger, .bordered, .rounded])
        
        let lightView = UIView(frame: CGRect(x: 150, y: 400, width: 100, height: 100),
                               factory: LightTheme.shared,
                               tagged: [.danger, .bordered, .rounded])

        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 150, y: 100, width: 100, height: 100)
        button.setTitle("Button", for: .normal)

        let darkButton = UIButton(type: .custom)
        darkButton.frame = CGRect(x: 150, y: 200, width: 100, height: 100)
        darkButton.setTitle("Button", for: .normal)
        DarkTheme.shared.apply(tags: .rounded, to: darkButton)

        view.addSubview(darkView)
        view.addSubview(lightView)
        view.addSubview(button)
        view.addSubview(darkButton)
    }
}

