//
//  SwiftUIView.swift
//  
//
//  Created by 戴藏龙 on 2024/1/18.
//

import SwiftUI
import TabularData

@available(iOS 17, *)
struct EditPlotterNodeView: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) private var dismiss

    init(head: Head, completion: ((PlotterNode) -> Void)? = nil) {
        self.head = head
        self.node = nil
        self._title = .init(initialValue: "")
        self.completion = completion
        self.deletion = nil
        self._plotterBuilder = .init(initialValue: .init())
    }

    init(editing node: PlotterNode, completion: ((PlotterNode) -> Void)? = nil, deletion: @escaping (() -> Void)) {
        self.head = node.head
        self.node = node
        self._plotterBuilder = .init(initialValue: .init(node.plotter))
        self._title = .init(initialValue: node.title)
        self.completion = completion
        self.deletion = deletion
    }

    let head: Head

    let node: PlotterNode?

    let completion: ((PlotterNode) -> Void)?

    let deletion: (() -> Void)?

    @State var title: String

    @State var plotterBuilder: PlotterBuilder

    @State var deletingNode: Bool = false

    private var dataFrame: DataFrame? {
        let status = switch head {
        case let .node(node):
            node.status
        case let .route(route):
            route.status
        }
        if case let .finished(.success(dataFrame)) = status {
            return dataFrame
        } else {
            return nil
        }
    }

    var saveValid: Bool {
        plotterBuilder.build() != nil
    }

    var body: some View {
        if let dataFrame {
            NavigationStack {
                List {
                    Section {
                        TextField("Plot Title", text: $title)
                    } header: {
                        Text("Title")
                            .font(.headline)
                    }
                    Section {
                        let columns = dataFrame.columns
                        Picker("Plot Type", selection: $plotterBuilder.plotterType) {
                            if plotterBuilder.plotterType == nil {
                                Text("Not selected")
                                    .tag(nil as Plotter.PlotterType?)
                            }
                            ForEach(Plotter.PlotterType.allCases, id: \.rawValue) { type in
                                Text(type.description)
                                    .tag(type as Plotter.PlotterType?)
                            }
                        }
                        Picker("Y Axis", selection: $plotterBuilder.yAxis) {
                            if plotterBuilder.yAxis == nil {
                                Text("Not selected")
                                    .tag(nil as String?)
                            }
                            ForEach(columns, id: \.name) { column in
                                ColumnItem(name: column.name, type: column.wrappedElementType)
                                    .tag(column.name as String?)
                            }
                        }

                        if plotterBuilder.plotterType != .pie {
                            Picker("X Axis", selection: $plotterBuilder.xAxis) {
                                if plotterBuilder.xAxis == nil {
                                    Text("Not selected")
                                        .tag(nil as String?)
                                }
                                ForEach(columns, id: \.name) { column in
                                    ColumnItem(name: column.name, type: column.wrappedElementType)
                                        .tag(column.name as String?)
                                }
                            }
                            Picker("Series (Optional)", selection: $plotterBuilder.series) {
                                Text("No Series")
                                    .tag(nil as String?)
                                ForEach(columns, id: \.name) { column in
                                    ColumnItem(name: column.name, type: column.wrappedElementType)
                                        .tag(column.name as String?)
                                }
                            }
                        } else {
                            Picker("Series", selection: $plotterBuilder.xAxis) {
                                if plotterBuilder.xAxis == nil {
                                    Text("Not selected")
                                        .tag(nil as String?)
                                }
                                ForEach(columns, id: \.name) { column in
                                    ColumnItem(name: column.name, type: column.wrappedElementType)
                                        .tag(column.name as String?)
                                }
                            }
                        }
                    }
                    if node != nil {
                        Section {
                            Button("Delete Node") {
                                deletingNode.toggle()
                            }
                        }
                    }
                }
                .navigationTitle(node == nil ? "New Plot from Current Node" : "Edit Plot")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Save") {
                            save()
                            dismiss()
                        }
                        .disabled(!saveValid)
                    }
                }
            }
            .confirmationDialog("Deletion Confirmation", isPresented: $deletingNode) {
                Button("Delete", role: .destructive) {
                    dismiss()
                    if let deletingNode = node {
                        switch head {
                        case let .node(node):
                            node.plotterTails.removeAll { node in
                                node == deletingNode
                            }
                            node.belongTo.refreshSubject.send(())
                        case let .route(route):
                            route.headPlotterNodes.removeAll { node in
                                node == deletingNode
                            }
                            route.refreshSubject.send(())
                        }
                        deletion?()
                    }
                }
                Button("Cancel", role: .cancel) {
                    deletingNode.toggle()
                }
            }
        } else {
            // TODO: fallback
        }
    }

    func save() {
        if let node {
            node.title = title
            node.plotter = plotterBuilder.build()!
            completion?(node)
        } else {
            let node = switch head {
            case let .node(node):
                PlotterNode(from: node, title: title, plotter: plotterBuilder.build()!)
            case let .route(route):
                PlotterNode(from: route, title: title, plotter: plotterBuilder.build()!)
            }
            completion?(node)
        }
    }

    struct ColumnItem: View {
        let name: String
        let type: Any.Type

        var body: some View {
            VStack(alignment: .leading) {
                Text(name)
                Text(String(describing: type))
            }
        }
    }
}

@available(iOS 17.0, *)
@Observable
class PlotterBuilder {
    var plotterType: Plotter.PlotterType?
    var xAxis: String?
    var yAxis: String?
    var series: String? = nil

    func build() -> Plotter? {
        guard let plotterType, let xAxis, let yAxis else { return nil }
        return Plotter(type: plotterType, xAxis: xAxis, yAxis: yAxis, series: series)
    }

    init() {}

    init(_ plotter: Plotter) {
        self.plotterType = plotter.type
        self.xAxis = plotter.xAxis
        self.yAxis = plotter.yAxis
        self.series = plotter.series
    }
}
