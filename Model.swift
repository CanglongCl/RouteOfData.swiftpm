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

    var allTails: [Tail] {
        headNodes.map { .node($0) } + headPlotterNodes.map { .plot($0) }
    }

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

    var allTails: [Tail] {
        tails.map { .node($0) } + plotterTails.map { .plot($0) }
    }

    @Relationship(deleteRule: .nullify)
    var belongTo: Route

    @Relationship(deleteRule: .nullify, inverse: \Node.tails)
    var headNode: Node?
    @Relationship(deleteRule: .cascade)
    var tails: [Node] = []

    @Relationship(deleteRule: .cascade)
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

    init(from route: Route, title: String, reducer: AnyReducer) {
        self.title = title
        reducerData = try! JSONEncoder().encode(reducer)
        belongTo = route
        route.headNodes.append(self)
        route.update()
    }

    init(from head: Node, title: String, reducer: AnyReducer) {
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

    @Relationship(deleteRule: .nullify, inverse: \Node.plotterTails)
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

    var status: Status<DataFrame> {
        switch head {
        case .route(let route):
            switch route.status {
            case .pending, .inProgress:
                    .pending
            case .finished(let result):
                switch result {
                case .success(let dataSet):
                        .finished(validate(dataSet: dataSet))
                case .failure(_):
                        .pending
                }
            }
        case .node(let node):
            switch node.status {
            case .pending, .inProgress:
                    .pending
            case .finished(let result):
                switch result {
                case .success(let dataSet):
                        .finished(validate(dataSet: dataSet))
                case .failure(_):
                        .pending
                }
            }
        }
    }

    func validate(dataSet: DataFrame) -> Result<DataFrame, Error> {
        guard dataSet.containsColumn(plotter.xAxis) else {
            return .failure(PlotterError.columnNotFound(position: .xAxis, columnName: plotter.xAxis))
        }
        guard dataSet.containsColumn(plotter.yAxis) else {
            return .failure(PlotterError.columnNotFound(position: .yAxis, columnName: plotter.yAxis))
        }
        if let series = plotter.series {
            guard dataSet.containsColumn(series) else {
                return .failure(PlotterError.columnNotFound(position: .series, columnName: series))
            }
        }
        return .success(dataSet)
    }

    var plotter: Plotter  {
        get {
            try! JSONDecoder().decode(Plotter.self, from: plotterData)
        } set {
            plotterData = try! JSONEncoder().encode(newValue)
            DispatchQueue.main.async {
                self.belongTo.update()
            }
        }
    }

    var plotterData: Data

    var starred: Bool = false

    init(from node: Node, title: String, plotter: Plotter) {
        self.belongTo = node.belongTo
        self.plotterData = try! JSONEncoder().encode(plotter)
        self.title = title
        node.plotterTails.append(self)
        node.belongTo.update()
    }

    init(from route: Route, title: String, plotter: Plotter) {
        self.headNode = nil
        self.belongTo = route
        self.plotterData = try! JSONEncoder().encode(plotter)
        self.title = title
        route.headPlotterNodes.append(self)
        route.update()
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
extension PlotterNode: Comparable {
    static func < (lhs: PlotterNode, rhs: PlotterNode) -> Bool {
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

@available(iOS 17, *)
enum Tail: Identifiable, Comparable, Equatable {
    case node(Node)
    case plot(PlotterNode)

    var id: UUID {
        switch self {
        case .node(let node):
            node.id
        case .plot(let plotterNode):
            plotterNode.id
        }
    }
}
