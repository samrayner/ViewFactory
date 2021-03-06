//
//  ViewFactory.swift
//  ViewFactory
//
//  Created by Sam Rayner on 18/10/2018.
//

import UIKit

extension UIView {
    private enum NibViewFactories {
        static var lastApplicationView: UIView?
    }

    @IBInspectable private var factoryTags: String {
        get { return "" }
        set { applyNibViewFactory(tags: tags(from: newValue)) }
    }

    convenience init<T: ViewFactoryTagType>(frame: CGRect = .zero, factory: ViewFactory<T>, tagged tags: Set<T> = []) {
        self.init(frame: frame)
        factory.apply(tags: tags, to: self)
    }

    //swiftlint:disable override_in_extension
    override open func awakeFromNib() {
        super.awakeFromNib()
        if NibViewFactories.lastApplicationView != self {
            applyNibViewFactory()
        }
    }

    private func tags(from string: String) -> Set<String> {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return Set(trimmed.split(separator: " ").map { String($0) })
    }

    private var nibViewFactoryDelegate: NibViewFactoryDelegate? {
        return UIApplication.shared.delegate as? NibViewFactoryDelegate
    }

    private var nibViewFactory: NibViewFactoryType? {
        return nibViewFactoryDelegate?.nibViewFactory(for: self)
    }

    private func applyNibViewFactory(tags: Set<String> = []) {
        NibViewFactories.lastApplicationView = self

        guard let nibViewFactory = nibViewFactory else { return }

        if nibViewFactory.applyToUntaggedNibViews || !tags.isEmpty {
            nibViewFactory.applyToNibView(self, tags: tags)
        }
    }
}

protocol NibViewFactoryType {
    var applyToUntaggedNibViews: Bool { get set }
    func applyToNibView(_ view: UIView, tags strings: Set<String>)
}

protocol NibViewFactoryDelegate: AnyObject {
    func nibViewFactory(for view: UIView) -> NibViewFactoryType?
}

protocol ViewFactoryTagType: Hashable, LosslessStringConvertible {}

extension String: ViewFactoryTagType {}

extension ViewFactoryTagType where Self: RawRepresentable, Self.RawValue == String {
    var description: String {
        return rawValue
    }

    init?(_ description: String) {
        self.init(rawValue: description)
    }
}

extension Set where Element: ViewFactoryTagType {
    func descriptions() -> Set<String> {
        return Set<String>(self.map { $0.description })
    }
}

class ViewFactory<TagType: ViewFactoryTagType>: NibViewFactoryType {
    private struct ConfigBlock {
        let index: Int
        let applyTo: (UIView) -> Void
    }

    var applyToUntaggedNibViews = true
    private let typeLevelTag = "{{TypeLevel}}"
    private var configBlockIndex = 0
    private var configBlocks: [String : [String : [ConfigBlock]]] = [:]

    required init() {}

    private func configBlocks(viewTypeString: String, tags: Set<String>) -> [ConfigBlock] {
        return tags
            .compactMap { configBlocks[viewTypeString]?[$0] }
            .reduce([], +)
            .sorted { $0.index < $1.index }
    }

    private func superclassTypeString(typeString: String) -> String? {
        return superclassTypeString(type: NSClassFromString(typeString))
    }

    private func superclassTypeString(type: AnyClass?) -> String? {
        return type?.superclass()?.description()
    }

    func apply(tags: TagType, to view: UIView) {
        apply(tags: [tags], to: view)
    }

    func apply(tags: Set<TagType> = [], to view: UIView) {
        let stringTags = tags.descriptions().union([typeLevelTag])
        var currentTypeString = "\(type(of: view))"
        var blocks: [ConfigBlock] = []

        while currentTypeString != superclassTypeString(type: UIView.self) {
            blocks = configBlocks(viewTypeString: currentTypeString, tags: stringTags) + blocks
            guard let superTypeString = superclassTypeString(typeString: currentTypeString) else { break }
            currentTypeString = superTypeString
        }

        blocks.forEach { $0.applyTo(view) }
    }

    func applyToNibView(_ view: UIView, tags strings: Set<String>) {
        let tags = Set(strings.compactMap { TagType($0) })
        apply(tags: tags, to: view)
    }

    func configure<T: UIView>(_ viewType: T.Type, tagged tag: TagType, with configuration: @escaping (T) -> Void) {
        configure(viewType, tagged: [tag], with: configuration)
    }

    func configure<T: UIView>(_ viewType: T.Type, tagged tags: Set<TagType> = [], with applyTo: @escaping (T) -> Void) {
        let viewTypeString = "\(viewType)"
        let stringTags = tags.isEmpty ? [typeLevelTag] : tags.descriptions()

        //sort type-level blocks before any tagged blocks (lower specificity)
        let index = tags.isEmpty ? -1 : configBlockIndex

        for tag in stringTags {
            if configBlocks[viewTypeString] == nil { configBlocks[viewTypeString] = [:] }
            if configBlocks[viewTypeString]?[tag] == nil { configBlocks[viewTypeString]?[tag] = [] }

            let configBlock = ConfigBlock(index: index) { view in
                guard let view = view as? T else { return }
                applyTo(view)
            }

            configBlocks[viewTypeString]?[tag]?.append(configBlock)
        }

        configBlockIndex += 1
    }
}
