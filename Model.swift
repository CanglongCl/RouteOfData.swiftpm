//
//  Model.swift
//  HelmOfData
//
//  Created by 戴藏龙 on 2024/1/3.
//

import Combine
import Foundation
import SwiftData
import TabularData

@available(iOS 17, *)
@Model
class Route {
    var id: UUID = UUID()

    var name: String
    var url: URL {
        didSet {
            update()
        }
    }

    var createdDate: Date = Date()

    var headNodes: [Node] = []

    var headPlotterNodes: [PlotterNode] = []

    var starred: Bool = false

    @Transient
    var status: Status<DataFrame> = .pending {
        didSet {
            DispatchQueue.main.async {
                self.refreshSubject.send(())
            }
        }
    }

    @Transient
    var rerender: Bool = false

    @Transient
    var refreshSubject: PassthroughSubject<Void, Never> = .init()

    func update() {
        if case let .inProgress(task) = status {
            task.cancel()
        }
        let task = Task {
            do {
                let dataFrame = try DataFrame(contentsOfCSVFile: url)
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    status = .finished(.success(dataFrame))
                }
                headNodes.forEach { node in
                    node.update(using: dataFrame)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    status = .finished(.failure(error))
                }
            }
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            status = .inProgress(task)
        }
    }

    func reinit() {
        if case let .inProgress(task) = status {
            task.cancel()
        }
        status = .pending
        headNodes.forEach { node in
            node.reinit()
        }
    }

    init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}

@available(iOS 17, *)
extension Node: Equatable {
    static func == (lhs: Node, rhs: Node) -> Bool {
        lhs.id == rhs.id
    }
}

@available(iOS 17, *)
@Model
class Node {
    var title: String

    var id: UUID = UUID()

    var reducerData: Data

    var starred: Bool = false

    var reducer: AnyReducer {
        get {
            try! JSONDecoder().decode(AnyReducer.self, from: reducerData)
        } set {
            reducerData = try! JSONEncoder().encode(newValue)
            DispatchQueue.main.async {
                self.belongTo.update()
            }
        }
    }

    @Relationship(deleteRule: .nullify)
    var belongTo: Route

    @Relationship(deleteRule: .nullify, inverse: \Node.tails)
    var headNode: Node?
    @Relationship(deleteRule: .cascade)
    var tails: [Node] = []

    @Relationship(deleteRule: .cascade, inverse: \PlotterNode.headNode)
    var plotterTails: [PlotterNode] = []

    @Transient
    var status: Status<DataFrame> = .pending {
        didSet {
            DispatchQueue.main.async {
                self.belongTo.refreshSubject.send(())
            }
        }
    }

    func update(using dataFrame: DataFrame?) {
        guard let dataFrame else {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.status = .pending
            }
            tails.forEach { node in
                node.update(using: nil)
            }
            return
        }
        if case let .inProgress(task) = status {
            task.cancel()
        }
        let task = Task {
            do {
                let dataFrame = try reducer.reduce(dataFrame)
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    status = .finished(.success(dataFrame))
                }
                tails.forEach { node in
                    node.update(using: dataFrame)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    status = .finished(.failure(error))
                }
                tails.forEach { node in
                    node.update(using: nil)
                }
            }
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.status = .inProgress(task)
        }
    }

    func reinit() {
        if case let .inProgress(task) = status {
            task.cancel()
        }
        status = .pending
        tails.forEach { node in
            node.reinit()
        }
    }

    init(route: Route, title: String, reducer: AnyReducer) {
        self.title = title
        reducerData = try! JSONEncoder().encode(reducer)
        belongTo = route
        route.headNodes.append(self)
        route.update()
    }

    init(head: Node, title: String, reducer: AnyReducer) {
        self.title = title
        reducerData = try! JSONEncoder().encode(reducer)
        belongTo = head.belongTo
        headNode = head
        head.belongTo.update()
    }

    var head: Head {
        if let headNode {
            .node(headNode)
        } else {
            .route(belongTo)
        }
    }
}

@available(iOS 17, *)
@Model
class PlotterNode {
    var title: String

    var id: UUID = UUID()

    @Relationship(deleteRule: .nullify)
    var headNode: Node?

    @Relationship(deleteRule: .nullify)
    var belongTo: Route

    var head: Head {
        if let headNode {
            .node(headNode)
        } else {
            .route(belongTo)
        }
    }

    var plotter: Plotter

    init(from node: Node, title: String, plotter: Plotter) {
        headNode = node
        belongTo = node.belongTo
        self.plotter = plotter
        self.title = title
    }

    init(from route: Route, title: String, plotter: Plotter) {
        headNode = nil
        belongTo = route
        self.plotter = plotter
        self.title = title
    }
}

enum Status<T> {
    case pending
    case inProgress(Task<Void, Never>)
    case finished(Result<T, Error>)
}

@available(iOS 17, *)
extension Node: Comparable {
    static func < (lhs: Node, rhs: Node) -> Bool {
        lhs.id < rhs.id
    }
}

@available(iOS 17, *)
enum Head: Identifiable {
    case route(Route)
    case node(Node)

    var id: UUID {
        switch self {
        case let .route(route):
            route.id
        case let .node(node):
            node.id
        }
    }
}
