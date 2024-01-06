//
//  SwiftUIView.swift
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
    @State private var creatingNodeWithHead: Node.Head?

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
                            case .route(let route):
                                editingRoute = route
                            case .node(let node):
                                editingNode = node
                            }
                        } label: {
                            Label("Edit", systemImage: "slider.horizontal.3")
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            switch node {
                            case .route(let route):
                                creatingNodeWithHead = .route(route)
                            case .node(let node):
                                creatingNodeWithHead = .node(node)
                            }
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                    }
                }
                .sheet(item: $editingNode) { node in
                    EditNodeSheet(editing: node)
                }
                .sheet(item: $editingRoute) { route in
                    AddRouteSheet(route: route)
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
        case .route(let route):
            RouteResultDisplayView(route: route)
        case .node(let node):
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
            case .finished(let result):
                switch result {
                case .success(let dataFrame):
                    DataFrameTableView(dataSet: dataFrame)
                case .failure(let error):
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
                switch node.status  {
                case .finished(let result):
                    switch result {
                    case .success(let dataFrame):
                        DataFrameTableView(dataSet: dataFrame)
                    case .failure(let error):
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
