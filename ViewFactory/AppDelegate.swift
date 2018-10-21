//
//  AppDelegate.swift
//  ViewFactory
//
//  Created by Sam Rayner on 19/10/2018.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
}

extension AppDelegate: ViewFactoryDelegate {
    func nibViewFactory(for view: UIView) -> NibViewFactoryType {
        return LightTheme.shared
    }
}
