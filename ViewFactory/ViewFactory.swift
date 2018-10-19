//
//  ViewFactory.swift
//  ViewFactory
//
//  Created by Sam Rayner on 18/10/2018.
//

import UIKit

extension UIView {
    @IBInspectable private var factoryTags: String {
        set { accessibilityIdentifier = newValue }
        get { return accessibilityIdentifier ?? "" }
    }

    fileprivate var factoryTagSet: Set<String> {
        set { factoryTags = newValue.joined(separator: " ") }
        get { return Set(factoryTags.split(separator: " ").map({ String($0) })) }
    }

    convenience init<T: ViewFactoryTagType>(frame: CGRect = .zero, factory: ViewFactory<T>, tagged tags: Set<T> = []) {
        self.init(frame: frame)
        factory.applyTags(tags, to: self)
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        if let nibViewFactory = (UIApplication.shared.delegate as? ViewFactoryDelegate)?.nibViewFactory,
            nibViewFactory.applyToUntaggedNibViews {
            nibViewFactory.apply(to: self)
        }
    }
}

protocol ViewFactoryType {
    var applyToUntaggedNibViews: Bool { get set }
    func apply(to: UIView)
}

protocol ViewFactoryDelegate {
    var nibViewFactory: ViewFactoryType { get }
}

protocol ViewFactoryTagType: Hashable, CustomStringConvertible {}

extension String: ViewFactoryTagType {}

extension ViewFactoryTagType where Self: RawRepresentable, Self.RawValue == String {
    var description: String {
        return rawValue
    }
}

private extension Set where Element: ViewFactoryTagType {
    func rawValues() -> Set<String> {
        return Set<String>(self.map { $0.description })
    }
}

class ViewFactory<TagType: ViewFactoryTagType>: ViewFactoryType {
    private struct ConfigBlock {
        let index: Int
        let applyTo: (UIView) -> ()
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

    func apply(to view: UIView) {
        let tags = view.factoryTagSet.union([typeLevelTag])
        var currentTypeString = "\(type(of: view))"
        var blocks: [ConfigBlock] = []

        while currentTypeString != superclassTypeString(type: UIView.self) {
            blocks = configBlocks(viewTypeString: currentTypeString, tags: tags) + blocks
            guard let superTypeString = superclassTypeString(typeString: currentTypeString) else { break }
            currentTypeString = superTypeString
        }

        blocks.forEach { $0.applyTo(view) }
    }

    func tagView(_ view: UIView, with tag: TagType) {
        tagView(view, with: [tag])
    }

    func tagView(_ view: UIView, with tags: Set<TagType>) {
        view.factoryTagSet.formUnion(tags.rawValues())
    }

    func applyTags(_ tag: TagType, to view: UIView) {
        return applyTags([tag], to: view)
    }

    func applyTags(_ tags: Set<TagType>, to view: UIView) {
        tagView(view, with: tags)
        apply(to: view)
    }

    func configure<T: UIView>(_ viewType: T.Type, tagged tag: TagType, with configuration: @escaping (T) -> ()) {
        configure(viewType, tagged: [tag], with: configuration)
    }

    func configure<T: UIView>(_ viewType: T.Type, tagged tags: Set<TagType> = [], with applyTo: @escaping (T) -> ()) {
        let viewTypeString = "\(viewType)"
        let factoryTags = tags.isEmpty ? [typeLevelTag] : tags.rawValues()

        //sort type-level blocks before any tagged blocks (lower specificity)
        let index = tags.isEmpty ? -1 : configBlockIndex

        for tag in factoryTags {
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
