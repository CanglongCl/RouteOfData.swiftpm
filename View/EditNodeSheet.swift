//
//  File.swift
//  
//
//  Created by 戴藏龙 on 2024/1/5.
//

import Foundation
import SwiftUI
import TabularData

@available(iOS 17, *)
struct EditNodeSheet: View {
    init(head: Node.Head, completion: ((Node) -> ())? = nil) {
        self.head = head
        self.node = nil
        self._title = .init(initialValue: "")
        self.completion = completion
        self.deletion = nil
    }

    init(editing node: Node, completion: ((Node) -> ())? = nil, deletion: @escaping (() -> ())) {
        self.head = node.head
        self.node = node
        self._reducer = .init(initialValue: node.reducer)
        self._title = .init(initialValue: node.title)
        self.completion = completion
        self.deletion = deletion
    }

    let head: Node.Head

    let node: Node?

    let completion: ((Node) -> ())?

    let deletion: (() -> ())?

    @State var title: String

    @State var reducer: AnyReducer?

    private var dataFrame: DataFrame? {
        let status = switch head {
        case .node(let node):
            node.status
        case .route(let route):
            route.status
        }
        if case let .finished(.success(dataFrame)) = status {
            return dataFrame
        } else {
            return nil
        }
    }

    @State private var deletingNode: Bool = false

    var saveValid: Bool {
        title != "" && reducer != nil
    }

    @Environment(\.modelContext) var context

    var body: some View {
        if let dataFrame {
            NavigationStack {
                List {
                    NodeBasicInfoView(title: $title)

                    EditReducerButton(dataFrame: dataFrame, reducer: $reducer) { reducer in
                        self.reducer = reducer
                    }

                    if node != nil {
                        Section {
                            Button("Delete Node") {
                                deletingNode.toggle()
                            }
                        }
                    }
                }
                .navigationTitle(node == nil ? "New Node from Current Node" : "Edit Node")
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
                        case .node(let node):
                            node.tails.removeAll { node in
                                node == deletingNode
                            }
                            node.belongTo.refreshSubject.send(())
                        case .route(let route):
                            route.headNodes.removeAll { node in
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
            // TODO: fall back
            EmptyView()
        }
    }

    func save() {
        if let node {
            node.title = title
            node.reducer = reducer!
            completion?(node)
        } else {
            let node = switch head {
            case .node(let node):
                Node(head: node, title: title, reducer: reducer!)
            case .route(let route):
                Node(route: route, title: title, reducer: reducer!)
            }
            completion?(node)
        }
    }

    @Environment(\.dismiss) private var dismiss
}
@available(iOS 17.0, *)
struct NodeBasicInfoView: View {
    @Binding var title: String

    var body: some View {
        Section {
            TextField("Node Title", text: $title)
        } header: {
            Text("Title")
                .font(.headline)
        }
    }
}

@available(iOS 17.0, *)
struct EditReducerButton: View {
    let dataFrame: DataFrame
    @Binding var reducer: AnyReducer?

    @State private var showEditReducerView: Bool = false

    let completion: (AnyReducer) -> ()

    var body: some View {
        Section {
            Button {
                showEditReducerView.toggle()
            } label: {
                if let reducer {
                    Text(String(describing: reducer))
                } else {
                    Text("Tap to Set Operation")
                }
            }
        } header: {
            Text("Operation")
                .font(.headline)
        }
        .sheet(isPresented: $showEditReducerView, content: {
            if let reducer {
                EditReducerView(oldReducer: reducer, dataFrame: dataFrame, completion: completion)
            } else {
                NewReducerSheetView(dataFrame: dataFrame, completion: completion)
            }
        })
    }
}

@available(iOS 17.0, *)
struct EditReducerView: View {
    let oldReducer: AnyReducer
    let dataFrame: DataFrame
    let completion: (AnyReducer) -> ()

    var body: some View {
        NavigationStack {
            Group {
                switch oldReducer {
                case .columnReducer(let columnReducer):
                    switch columnReducer {
                    case .boolean(let booleanReducer):
                        ColumnOperationBoolOperationView(boolReducer: booleanReducer, dataFrame: dataFrame, completion: completeAndDismiss)
                    case .integer(let integerReducer):
                        ColumnOperationIntegerOperationView(integerReducer: integerReducer, dataFrame: dataFrame, completion: completeAndDismiss)
                    case .double(let doubleReducer):
                        ColumnOperationDoubleOperationView(doubleReducer: doubleReducer, dataFrame: dataFrame, completion: completeAndDismiss)
                    case .date(let dateReducer):
                        ColumnOperationDateOperationView(dateReducer: dateReducer, dataFrame: dataFrame, completion: completeAndDismiss)
                    case .string(let stringReducer):
                        ColumnOperationStringOperationView(stringReducer: stringReducer, dataFrame: dataFrame, completion: completeAndDismiss)
                    }
                case .groupByReducer(let groupByReducer):
                    switch groupByReducer {
                    case .any(let groupByParameter):
                        AnyGroupByOperationView(reducer: groupByParameter, dataFrame: dataFrame, completion: completeAndDismiss)
                    case .date(let groupByDateParameter):
                        DateGroupByOperationView(reducer: groupByDateParameter, dataFrame: dataFrame, completion: completeAndDismiss)
                    }
                case .summary(let summaryReducer):
                    SummaryOperationEditView(reducer: summaryReducer, dataFrame: dataFrame, completion: completeAndDismiss)
                case .selectReducer(let selectReducer):
                    SelectOperationEditView(reducer: selectReducer, dataFrame: dataFrame, completion: completeAndDismiss)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    func completeAndDismiss(_ reducer: AnyReducer) {
        completion(reducer)
        dismiss()
    }

    @Environment(\.dismiss) var dismiss
}

@available(iOS 17.0, *)
struct NewReducerSheetView: View {
    init(dataFrame: DataFrame, completion: @escaping (AnyReducer) -> ()) {
        self.dataFrame = dataFrame
        self.completion = completion
    }

    let dataFrame: DataFrame

    let completion: (AnyReducer) -> ()

    var body: some View {
        NavigationStack {
            List {
                ForEach(ReducerType.allCases) { type in
                    NavigationLink {
                        switch type {
                        case .columnOperation:
                            ColumnOperationSelectColumnView(dataFrame: dataFrame, completion: completeAndDismiss)
                        case .groupByAndAggregation:
                            GroupByOperationEditView(dataFrame: dataFrame, completion: completeAndDismiss)
                        case .summary:
                            SummaryOperationEditView(dataFrame: dataFrame, completion: completeAndDismiss)
                        case .select:
                            SelectOperationEditView(dataFrame: dataFrame, completion: completeAndDismiss)
                        }
                    } label: {
                        Text(type.description)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Choose Operation Type")
        }
    }

    func completeAndDismiss(_ reducer: AnyReducer) {
        completion(reducer)
        dismiss()
    }

    enum ReducerType: String, CaseIterable, CustomStringConvertible, Identifiable {
        case select
        case summary
        case columnOperation
        case groupByAndAggregation

        var id: String { self.rawValue }

        var description: String {
            switch self {
            case .columnOperation:
                "Column Operation"
            case .groupByAndAggregation:
                "Group & Aggregation"
            case .summary:
                "Summary"
            case .select:
                "Select Columns"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
}
@available(iOS 17.0, *)
struct ColumnOperationSelectColumnView: View {
    let dataFrame: DataFrame
    let completion: (AnyReducer) -> ()

    var body: some View {
        List {
            ForEach(dataFrame.columns, id: \.name) { column in
                NavigationLink {
                    switch String(describing: column.wrappedElementType) {
                    case String(describing: Int.self):
                        ColumnOperationIntegerOperationView(currentColumn: column.name, dataFrame: dataFrame, completion: completion)
                    case String(describing: Double.self):
                        ColumnOperationDoubleOperationView(currentColumn: column.name, dataFrame: dataFrame, completion: completion)
                    case String(describing: Date.self):
                        ColumnOperationDateOperationView(currentColumn: column.name, dataFrame: dataFrame, completion: completion)
                    case String(describing: Bool.self):
                        ColumnOperationBoolOperationView(currentColumn: column.name, dataFrame: dataFrame, completion: completion)
                    case String(describing: String.self):
                        ColumnOperationStringOperationView(currentColumn: column.name, dataFrame: dataFrame, completion: completion)
                    default:
                        ContentUnavailableView("Error", systemImage: "xmark.circle", description: Text("No operation available for \(String(describing: column.wrappedElementType))"))
                    }
                } label: {
                    VStack(alignment: .leading) {
                        Text(column.name)
                            .lineLimit(1)
                            .font(.headline)
                            .textCase(.uppercase)
                        Text(String(describing: column.wrappedElementType))
                            .font(.caption2)
                    }
                }
            }
        }
        .navigationTitle("Pick a Column")
    }
}

