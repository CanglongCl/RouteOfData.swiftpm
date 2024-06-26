//
//  NodeDisplayView.swift
//
//
//  Created by 戴藏龙 on 2024/1/4.
//

import SwiftUI
import TabularData

@available(iOS 17, *)
struct NodeDisplayView: View {
    @Binding var node: DisplayableNode?

    @State private var editingNode: Node?
    @State private var editingRoute: Route?
    @State private var editingPlotterNode: PlotterNode?
    @State private var creatingNodeWithHead: Head?
    @State private var creatingPlotWithHead: Head?

    var body: some View {
        if let node {
            VStack(alignment: .leading) {
                Text(node.description)
                    .padding(.horizontal)
                DisplayableNodeSwitchView(node: node)
            }
            .navigationTitle(node.title)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showOnBoardingSheet.toggle()
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.orange)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        node.toggleStar()
                    } label: {
                        Image(systemName: node.starred ? "star.fill" : "star")
                            .foregroundStyle(node.starred ? .yellow : .orange)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        switch node {
                        case let .route(route):
                            editingRoute = route
                        case let .node(node):
                            editingNode = node
                        case let .plot(node):
                            editingPlotterNode = node
                        }
                    } label: {
                        Label("Edit", systemImage: "slider.horizontal.3")
                    }
                    .disabled(disableEdit)
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            switch node {
                            case let .route(route):
                                creatingNodeWithHead = .route(route)
                            case let .node(node):
                                creatingNodeWithHead = .node(node)
                            case .plot:
                                break
                            }
                        } label: {
                            Label("Table Operation", systemImage: "tablecells")
                        }
                        Button {
                            switch node {
                            case let .route(route):
                                creatingPlotWithHead = .route(route)
                            case let .node(node):
                                creatingPlotWithHead = .node(node)
                            case .plot:
                                break
                            }
                        } label: {
                            Label("Plot", systemImage: "chart.xyaxis.line")
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .disabled(disableCreat)
                }
            }
            .sheet(item: $editingNode) { node in
                EditNodeSheet(editing: node, completion: { node in
                    self.node = .node(node)
                }, deletion: {
                    self.node = nil
                })
            }
            .sheet(item: $editingRoute) { route in
                EditRouteSheet(route: route)
            }
            .sheet(item: $editingPlotterNode, content: { node in
                EditPlotterNodeView(editing: node) {
                    self.node = nil
                }
            })
            .sheet(item: $creatingNodeWithHead) { head in
                EditNodeSheet(head: head) {
                    self.node = .node($0)
                }
            }
            .sheet(item: $creatingPlotWithHead) { head in
                EditPlotterNodeView(head: head) {
                    self.node = .plot($0)
                }
            }
            .sheet(isPresented: $showOnBoardingSheet, content: {
                OnBoardingSheetView()
            })
        } else {
            ContentUnavailableView("Select a Node First", systemImage: "xmark")
        }
    }

    @State private var showOnBoardingSheet: Bool = false

    var disableCreat: Bool {
        isPlot || !isParentCompleted
    }

    var isParentCompleted: Bool {
        switch node {
        case .route:
            true
        case let .node(node):
            switch node.head {
            case let .node(head):
                if case .finished(.success(_)) = head.status {
                    true
                } else {
                    false
                }
            case let .route(head):
                if case .finished(.success(_)) = head.status {
                    true
                } else {
                    false
                }
            }
        case let .plot(node):
            switch node.head {
            case let .node(head):
                if case .finished(.success(_)) = head.status {
                    true
                } else {
                    false
                }
            case let .route(head):
                if case .finished(.success(_)) = head.status {
                    true
                } else {
                    false
                }
            }
        case nil:
            false
        }
    }

    var disableEdit: Bool {
        !isParentCompleted
    }

    var isPlot: Bool {
        if case .plot = node { true } else { false }
    }
}

@available(iOS 17.0, *)
struct OnBoardingSheetView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            OnBoardingView()
                .toolbar(content: {
                    Button("Done") {
                        dismiss()
                    }
                })
        }
    }
}

@available(iOS 17, *)
struct DisplayableNodeSwitchView: View {
    let node: DisplayableNode

    var body: some View {
        switch node {
        case let .route(route):
            RouteResultDisplayView(route: route)
        case let .node(node):
            NodeResultDisplayView(node: node)
        case let .plot(node):
            PlotNodeDisplayView(node: node)
        }
    }
}

@available(iOS 17, *)
struct PlotNodeDisplayView: View {
    let node: PlotterNode

    var body: some View {
        Group {
            switch node.status {
            case .pending:
                ContentUnavailableView("Pending", systemImage: "xmark.circle", description: Text("Waiting for previous node to finish."))
            case .inProgress:
                ProgressView()
            case let .finished(result):
                switch result {
                case let .success(dataFrame):
                    PlotterView(plotter: node.plotter, dataSet: dataFrame)
                        .padding()
                case let .failure(error):
                    ContentUnavailableView("Error", systemImage: "xmark.circle", description: Text(error.localizedDescription))
                }
            }
        }
        .onReceive(node.belongTo.refreshSubject, perform: { _ in
            refresh.objectWillChange.send()
        })
    }

    @StateObject private var refresh: RefreshViewModel = .init()
}

@available(iOS 17, *)
struct RouteResultDisplayView: View {
    let route: Route
    @StateObject private var refresh: RefreshViewModel = .init()

    var body: some View {
        Group {
            switch route.status {
            case let .finished(result):
                switch result {
                case let .success(dataFrame):
                    DataFrameTableView(dataSet: dataFrame)
                case let .failure(error):
                    ContentUnavailableView("Error", systemImage: "xmark.circle", description: Text(error.localizedDescription))
                }
            case .inProgress:
                ProgressView()
            case .pending:
                ContentUnavailableView("Pending", systemImage: "xmark.circle", description: Text("Waiting for previous node to finish."))
            }
        }
        .onReceive(route.refreshSubject, perform: { _ in
            refresh.objectWillChange.send()
        })
    }
}

@available(iOS 17, *)
struct NodeResultDisplayView: View {
    let node: Node

    @StateObject private var refresh: RefreshViewModel = .init()

    var body: some View {
        if node.isDeleted {
            EmptyView()
        } else {
            Group {
                switch node.status {
                case let .finished(result):
                    switch result {
                    case let .success(dataFrame):
                        DataFrameTableView(dataSet: dataFrame)
                    case let .failure(error):
                        ContentUnavailableView("Error", systemImage: "xmark.circle", description: Text(error.localizedDescription))
                    }
                case .inProgress:
                    ProgressView()
                case .pending:
                    ContentUnavailableView("Pending", systemImage: "xmark.circle", description: Text("Waiting for previous node to finish."))
                }
            }
            .onReceive(node.belongTo.refreshSubject, perform: { _ in
                refresh.objectWillChange.send()
            })
        }
    }
}
