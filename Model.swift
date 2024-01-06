//
//  Model.swift
//  HelmOfData
//
//  Created by 戴藏龙 on 2024/1/3.
//

import Foundation
import TabularData
import SwiftData
import Combine

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
    var refreshSubject: PassthroughSubject<(), Never> = .init()

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
    static func ==(lhs: Node, rhs: Node) -> Bool {
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
        self.reducerData = try! JSONEncoder().encode(reducer)
        self.belongTo = route
        route.headNodes.append(self)
        route.update()
    }

    init(head: Node, title: String, reducer: AnyReducer) {
        self.title = title
        self.reducerData = try! JSONEncoder().encode(reducer)
        self.belongTo = head.belongTo
        self.headNode = head
        head.belongTo.update()
    }

    enum Head: Identifiable {
        case route(Route)
        case node(Node)

        var id: UUID {
            switch self {
            case .route(let route):
                route.id
            case .node(let node):
                node.id
            }
        }
    }

    var head: Head {
        if let headNode {
            .node(headNode)
        } else {
            .route(belongTo)
        }
    }
}

enum Status<T> {
    case pending
    case inProgress(Task<(), Never>)
    case finished(Result<T, Error>)
}

@available(iOS 17, *)
extension Node: Comparable {
    static func < (lhs: Node, rhs: Node) -> Bool {
        lhs.id < rhs.id
    }
}
