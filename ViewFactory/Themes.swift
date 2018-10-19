//
//  Themes.swift
//  ViewFactory
//
//  Created by Sam Rayner on 19/10/2018.
//

import UIKit

enum ThemeTag: String, ViewFactoryTagType {
    case danger
    case warning
    case bordered
    case rounded
}

final class DarkTheme: ViewFactory<ThemeTag> {
    static var shared: DarkTheme = DarkTheme()

    required init() {
        super.init()

        configure(UIView.self) {
            $0.backgroundColor = .black
        }

        configure(UIView.self, tagged: .danger) {
            $0.backgroundColor = .red
        }

        configure(UIView.self, tagged: .warning) {
            $0.backgroundColor = .yellow
        }

        configure(UIButton.self) {
            $0.layer.borderWidth = 10
            $0.layer.borderColor = UIColor.green.cgColor
        }

        configure(UIView.self, tagged: .rounded) {
            $0.layer.cornerRadius = 20
        }
    }
}

final class LightTheme: ViewFactory<ThemeTag> {
    static var shared: LightTheme = LightTheme()

    required init() {
        super.init()

        configure(UIView.self) {
            $0.backgroundColor = .blue
        }

        configure(UIView.self, tagged: .danger) {
            $0.backgroundColor = .magenta
        }

        configure(UIView.self, tagged: .warning) {
            $0.backgroundColor = .yellow
        }

        configure(UIButton.self) {
            $0.layer.borderWidth = 10
            $0.layer.borderColor = UIColor.cyan.cgColor
        }

        configure(UIView.self, tagged: .rounded) {
            $0.layer.cornerRadius = 20
        }
    }
}
