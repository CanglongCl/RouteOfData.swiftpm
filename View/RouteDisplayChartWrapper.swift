//
//  RouteDisplayChartWrapper.swift
//
//
//  Created by 戴藏龙 on 2024/1/4.
//

import Charts
import Foundation
import SwiftUI
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
                    .annotation {
                        if point.referTo == selectedNode {
                            Text(point.referTo.abbreviation)
                                .font(.caption)
                        } else {
                            Text(point.referTo.shortAbbreviation)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
            }
        }
        .padding()
        .chartOverlay { proxy in
            GeometryReader { _ in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .onTapGesture { location in
                        guard let (x, y): (Double, Double) = proxy.value(at: location) else {
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
        VStack(alignment: .leading) {
            Text(route.remark)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
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
        }
        .navigationTitle(route.name)
    }

    @ViewBuilder
    func pointSymbol(_ point: Point) -> some View {
        var status: Status<DataFrame> {
            switch point.referTo {
            case let .route(route):
                route.status
            case let .node(node):
                node.status
            case let .plot(node):
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
        case let .node(node):
            node.status
        case let .route(route):
            route.status
        case let .plot(node):
            node.status
        }

        let normalColor: Color = isSelected ? .orange : point.referTo.starred ? .yellow : .blue

        switch status {
        case .pending:
            return .gray
        case .inProgress:
            return .gray
        case let .finished(result):
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
        case let .node(node):
            node.status
        case let .route(route):
            route.status
        case let .plot(node):
            node.status
        }

        let normalColor: Color = isSelected ? .orange : .blue

        switch status {
        case .pending:
            return .gray
        case .inProgress:
            return .gray
        case let .finished(result):
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
extension PlotterNode: Pointable {
    func getPoint() -> Point {
        let headPoint = head.getPoint()
        let index = switch head {
        case let .node(node):
            node.allTails.sorted().firstIndex(of: .plot(self))!
        case let .route(route):
            route.allTails.sorted().firstIndex(of: .plot(self))!
        }

        let y = headPoint.y - 1
        let x = headPoint.x
            - head.availableSpaceForChildren() / 2
            + Double(1 + index) * head.availableSpaceForChildren() / Double(head.childrenNumber() + 1)
        return Point(id: id, x: x, y: y, referTo: convertToDisplayableNode())
    }

    func getLine() -> Line? {
        let headPoint = head.getPoint()
        let selfPoint = getPoint()
        return Line(start: headPoint, end: selfPoint)
    }

    func availableSpaceForChildren() -> Double {
        head.availableSpaceForChildren()
    }

    func childrenNumber() -> Int {
        0
    }
}

@available(iOS 17, *)
extension Node: Pointable {
    func availableSpaceForChildren() -> Double {
        head.availableSpaceForChildren() / Double(head.childrenNumber())
    }

    func childrenNumber() -> Int {
        allTails.count
    }

    func getPoint() -> Point {
        let headPoint = head.getPoint()
        let index = switch head {
        case let .node(node):
            node.allTails.sorted().firstIndex(of: .node(self))!
        case let .route(route):
            route.allTails.sorted().firstIndex(of: .node(self))!
        }

        let y = headPoint.y - 1
        let x = headPoint.x
            - head.availableSpaceForChildren() / 2
            + Double(1 + index) * head.availableSpaceForChildren() / Double(head.childrenNumber() + 1)
        return Point(id: id, x: x, y: y, referTo: convertToDisplayableNode())
    }

    func getLine() -> Line? {
        let headPoint = head.getPoint()
        let selfPoint = getPoint()
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
        allTails.count
    }

    func getPoint() -> Point {
        Point(id: id, x: 0, y: 0.25, referTo: convertToDisplayableNode())
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
    let id: UUID = .init()
    let start: Point
    let end: Point
}

@available(iOS 17, *)
extension Route {
    func getPoints() -> [Point] {
        var points: [Point] = [getPoint()]
        headNodes.forEach { node in
            points.append(contentsOf: getPointAndChildrenPoint(node: node))
        }
        headPlotterNodes.forEach { node in
            points.append(node.getPoint())
        }
        return points
    }

    func getLines() -> [Line] {
        var lines: [Line] = []
        headNodes.forEach { node in
            lines.append(contentsOf: getLineAndChildrenLine(node: node))
        }
        headPlotterNodes.forEach { node in
            if let line = node.getLine() {
                lines.append(line)
            }
        }
        return lines
    }
}

@available(iOS 17, *)
func getPointAndChildrenPoint(node: Node) -> [Point] {
    guard !node.isDeleted else { return [] }
    var points: [Point] = []
    points.append(node.getPoint())
    for tail in node.tails {
        points.append(contentsOf: getPointAndChildrenPoint(node: tail))
    }
    for tail in node.plotterTails {
        points.append(tail.getPoint())
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
    for tail in node.plotterTails {
        if let line = tail.getLine() {
            lines.append(line)
        }
    }
    return lines
}
