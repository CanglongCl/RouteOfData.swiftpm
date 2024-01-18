//
//  File.swift
//  
//
//  Created by 戴藏龙 on 2024/1/4.
//

import Foundation
import SwiftUI
import Charts
import TabularData

class RefreshViewModel: ObservableObject {}

@available(iOS 17, *)
struct RouteDisplayChart: View {
    @StateObject private var refresh: RefreshViewModel = .init()

    let route: Route

    @Binding var selectedNode: DisplayableNode?

    @ViewBuilder func chart(route: Route) -> some View {
        let points = route.getPoints()
        let lines = route.getLines()
        Chart {
            ForEach(lines) { line in
                LineMark(x: .value("x", line.start.x), y: .value("y", line.start.y), series: .value("s", line.id.uuidString))
                    .foregroundStyle(lineColor(line: line))
                LineMark(x: .value("x", line.end.x), y: .value("y", line.end.y), series: .value("s", line.id.uuidString))
                    .foregroundStyle(lineColor(line: line))
            }
            .opacity(0.7)
            ForEach(points) { point in
                PointMark(x: .value("X", point.x), y: .value("Layer", point.y))
                    .symbol {
                        pointSymbol(point)
                    }
            }
        }
        .padding()
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .onTapGesture { location in
                        guard let (x, y): (Double, Double) = proxy.value(at: location) else  {
                            return
                        }
                        withAnimation {
                            selectedNode = points.min { lhs, rhs in
                                lhs.squaredDistanceTo(x: x, y: y) < rhs.squaredDistanceTo(x: x, y: y)
                            }!.referTo
                        }
                    }
            }
        }
    }

    var body: some View {
        chart(route: route)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showExpandCover.toggle()
                } label: {
                    Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                }
            }
        }
        .fullScreenCover(isPresented: $showExpandCover, content: {
            NavigationStack {
                chart(route: route)
                    .navigationTitle(selectedNode?.title ?? "Pick a Node")
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button("Done") {
                                showExpandCover.toggle()
                            }
                        }
                    }
            }
        })
        .navigationTitle(route.name)
    }

    @ViewBuilder
    func pointSymbol(_ point: Point) -> some View {
        var status: Status<DataFrame> {
            switch point.referTo {
            case .route(let route):
                route.status
            case .node(let node):
                node.status
            }
        }
        Group {
            if point.referTo == selectedNode {
                switch point.referTo.starred {
                case true:
                    Image(systemName: "star.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                case false:
                    Rectangle()
                        .frame(width: 20, height: 20)
                }
            } else {
                switch point.referTo.starred {
                case true:
                    Image(systemName: "star.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                case false:
                    Circle()
                        .frame(width: 10, height: 10)
                }
            }
        }
        .foregroundStyle(pointColor(point: point))
        .onReceive(route.refreshSubject, perform: { _ in
            refresh.objectWillChange.send()
        })
    }

    func pointColor(point: Point) -> Color {
        let isSelected = selectedNode == point.referTo
        let status = switch point.referTo {
        case .node(let node):
            node.status
        case .route(let route):
            route.status
        }

        let normalColor: Color = isSelected ? .orange : point.referTo.starred ? .yellow : .blue

        switch status {
        case .pending:
            return .gray
        case .inProgress:
            return .gray
        case .finished(let result):
            switch result {
            case .success:
                return normalColor
            case .failure:
                return .red
            }
        }
    }

    func lineColor(line: Line) -> Color {
        let isSelected = selectedNode == line.start.referTo || selectedNode == line.end.referTo
        let status = switch line.end.referTo {
        case .node(let node):
            node.status
        case .route(let route):
            route.status
        }

        let normalColor: Color = isSelected ? .orange : .blue

        switch status {
        case .pending:
            return .gray
        case .inProgress:
            return .gray
        case .finished(let result):
            switch result {
            case .success:
                return normalColor
            case .failure:
                return .red
            }
        }
    }

    @State private var showExpandCover: Bool = false
}

@available(iOS 17, *)
struct RouteDisplayChartWrapper: View {
    let route: Route?

    @Binding var selectedNode: DisplayableNode?

    var body: some View {
        if let route {
            RouteDisplayChart(route: route, selectedNode: $selectedNode)
        } else {
            ContentUnavailableView("Select A Route First", systemImage: "square.and.arrow.down.fill")
        }
    }
}

@available(iOS 17, *)
extension Node: Pointable {
    func availableSpaceForChildren() -> Double {
        head.availableSpaceForChildren() / Double(head.childrenNumber())
    }
    
    func childrenNumber() -> Int {
        tails.count
    }

    func getPoint() -> Point {
        let headPoint = head.getPoint()
        let index = switch head {
        case .node(let node):
            node.tails.sorted().firstIndex(of: self)!
        case .route(let route):
            route.headNodes.sorted().firstIndex(of: self)!
        }

        let y = headPoint.y - 1
        let x = headPoint.x
        - head.availableSpaceForChildren() / 2
        + Double(1 + index) * head.availableSpaceForChildren() / Double(head.childrenNumber() + 1)
        return Point(id: self.id, x: x, y: y, referTo: convertToDisplayableNode())
    }
    
    func getLine() -> Line? {
        let headPoint = self.head.getPoint()
        let selfPoint = self.getPoint()
        return Line(start: headPoint, end: selfPoint)
    }
}

@available(iOS 17, *)
extension Head: Pointable {
    func childrenNumber() -> Int {
        switch self {
        case let .node(node):
            node.childrenNumber()
        case let .route(route):
            route.childrenNumber()
        }
    }
    
    func availableSpaceForChildren() -> Double {
        switch self {
        case let .node(node):
            node.availableSpaceForChildren()
        case let .route(route):
            route.availableSpaceForChildren()
        }
    }
    
    func getPoint() -> Point {
        switch self {
        case let .node(node):
            node.getPoint()
        case let .route(route):
            route.getPoint()
        }
    }
    
    func getLine() -> Line? {
        switch self {
        case let .node(node):
            node.getLine()
        case let .route(route):
            route.getLine()
        }
    }
}

@available(iOS 17, *)
extension Route: Pointable {
    func availableSpaceForChildren() -> Double {
        1
    }
    
    func childrenNumber() -> Int {
        self.headNodes.count
    }
    
    func getPoint() -> Point {
        Point(id: self.id, x: 0, y: 0, referTo: convertToDisplayableNode())
    }
    
    func getLine() -> Line? {
        nil
    }
}

@available(iOS 17, *)
protocol Pointable {
    func getPoint() -> Point

    func getLine() -> Line?

    func availableSpaceForChildren() -> Double

    func childrenNumber() -> Int
}

@available(iOS 17, *)
struct Point: Identifiable, Equatable {
    static func == (lhs: Point, rhs: Point) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: UUID
    let x: Double
    let y: Double
    let referTo: DisplayableNode

    func squaredDistanceTo(x: Double, y: Double) -> Double {
        pow(x - self.x, 2) + pow(y - self.y, 2)
    }
}

@available(iOS 17, *)
struct Line: Identifiable {
    let id: UUID = UUID()
    let start: Point
    let end: Point
}

@available(iOS 17, *)
extension Route {
    func getPoints() -> [Point] {
        var points: [Point] = [self.getPoint()]
        headNodes.forEach { node in
            points.append(contentsOf: getPointAndChildrenPoint(node: node))
        }
        return points
    }

    func getLines() -> [Line] {
        var lines: [Line] = []
        headNodes.forEach { node in
            lines.append(contentsOf: getLineAndChildrenLine(node: node))
        }
        return lines
    }
}

@available(iOS 17, *)
func getPointAndChildrenPoint(node: Node) -> [Point] {
    guard !node.isDeleted else { return [] }
    var points: [Point] = []
    let isDeleted = node.isDeleted
    points.append(node.getPoint())
    for tail in node.tails {
        points.append(contentsOf: getPointAndChildrenPoint(node: tail))
    }
    return points
}

@available(iOS 17, *)
func getLineAndChildrenLine(node: Node) -> [Line] {
    guard !node.isDeleted else { return [] }
    var lines: [Line] = []
    lines.append(node.getLine()!)
    for tail in node.tails {
        lines.append(contentsOf: getLineAndChildrenLine(node: tail))
    }
    return lines
}
