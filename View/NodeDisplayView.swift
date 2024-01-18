//
//  NodeDisplayView.swift
//
//
//  Created by 戴藏龙 on 2024/1/4.
//

import SwiftUI

@available(iOS 17, *)
struct NodeDisplayView: View {
    @Binding var node: DisplayableNode?

    @State private var editingNode: Node?
    @State private var editingRoute: Route?
    @State private var creatingNodeWithHead: Head?

    var body: some View {
        if let node {
            DisplayableNodeSwitchView(node: node)
                .navigationTitle(node.title)
                .toolbar {
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
                            }
                        } label: {
                            Label("Edit", systemImage: "slider.horizontal.3")
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            switch node {
                            case let .route(route):
                                creatingNodeWithHead = .route(route)
                            case let .node(node):
                                creatingNodeWithHead = .node(node)
                            }
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                    }
                }
                .sheet(item: $editingNode) { node in
                    EditNodeSheet(editing: node, deletion: {
                        self.node = nil
                    })
                }
                .sheet(item: $editingRoute) { route in
                    EditRouteSheet(route: route)
                }
                .sheet(item: $creatingNodeWithHead) { head in
                    EditNodeSheet(head: head) {
                        self.node = .node($0)
                    }
                }
        } else {
            ContentUnavailableView("Select a Node First", systemImage: "xmark")
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
        }
    }
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
