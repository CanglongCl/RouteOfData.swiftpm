//
//  GroupByOperationEditor.swift
//
//
//  Created by 戴藏龙 on 2024/1/5.
//

import Foundation
import SwiftUI
import TabularData

@available(iOS 17.0, *)
struct GroupByOperationView: View {
    @State private var builder: OperationBuilder

    init(dataFrame: DataFrame, completion: @escaping (AnyReducer) -> Void) {
        _builder = .init(initialValue: .init())
        self.dataFrame = dataFrame
        self.completion = completion
    }

    init(reducer: GroupByReducer, dataFrame: DataFrame, completion: @escaping (AnyReducer) -> Void) {
        let groupByKeys = reducer.groupKey.intoArray()
        _builder = .init(
            initialValue: .init(
                groupByKeys: groupByKeys,
                aggregationColumn: reducer.operation.column,
                aggregationOperation: reducer.operation.operation)
        )
        self.dataFrame = dataFrame
        self.completion = completion
        switch groupByKeys.count {
        case 0, 1:
            break
        case 2:
            _showSecondGroupKeyEditor = .init(initialValue: true)
        default:
            _showSecondGroupKeyEditor = .init(initialValue: true)
            _showThirdGroupKeyEditor = .init(initialValue: true)
        }
    }

    let dataFrame: DataFrame

    let completion: (AnyReducer) -> Void

    @State var showSecondGroupKeyEditor: Bool = false
    @State var showThirdGroupKeyEditor: Bool = false

    struct GroupKeyPicker: View {
        var dataFrame: DataFrame
        var title: String
        var selection: String?
        var onPick: (GroupByReducer.GroupKey.GroupKeyType) -> ()

        @State private var groupByDateComponent: GroupByReducer.GroupKey.GroupKeyType.GroupByDateKey = .day

        var body: some View {
            VStack {
                HStack {
                    Text(title)
                    Spacer()
                    Menu {
                        ForEach(dataFrame.columns, id: \.name) { column in
                            Button(column.name) {
                                if column.wrappedElementType == Date.self {
                                    onPick(.date(columnName: column.name, groupByDateComponent: groupByDateComponent))
                                } else {
                                    onPick(.any(columnName: column.name))
                                }
                            }
                        }
                    } label: {
                        Group {
                            if let selection {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selection)
                                        .font(.title2)
                                        .bold()
                                }
                            } else {
                                Text("Column")
                                    .font(.title2)
                                    .bold()
                            }
                        }
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.quinary)
                                .foregroundStyle(.quaternary)
                        }
                    }
                    if let selection, dataFrame[selection].wrappedElementType == Date.self {
                        Menu {
                            ForEach(GroupByReducer.GroupKey.GroupKeyType.GroupByDateKey.allCases) { type in
                                Button(type.description) {
                                    groupByDateComponent = type
                                    onPick(.date(columnName: selection, groupByDateComponent: type))
                                }
                            }
                        } label: {
                            Group {
                                Text(groupByDateComponent.description)
                                    .font(.title2)
                                    .bold()
                            }
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.quinary)
                                    .foregroundStyle(.quaternary)
                            }
                        }
                    }
                }
            }
        }
    }

    var body: some View {
        List {
            Section {
                GroupKeyPicker(dataFrame: dataFrame, title: "Group Key", selection: builder.groupByKeys[safe: 0]?.columnName) { type in
                    if builder.groupByKeys.indices.contains(0) {
                        builder.groupByKeys[0] = type
                    } else {
                        builder.groupByKeys.append(type)
                    }
                }
                if showSecondGroupKeyEditor {
                    GroupKeyPicker(dataFrame: dataFrame, title: "Group Key 2", selection: builder.groupByKeys[safe: 1]?.columnName) { type in
                        if builder.groupByKeys.indices.contains(1) {
                            builder.groupByKeys[1] = type
                        } else {
                            builder.groupByKeys.append(type)
                        }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            if builder.groupByKeys.indices.contains(1) {
                                builder.groupByKeys.remove(at: 1)
                            }
                            if showThirdGroupKeyEditor {
                                showThirdGroupKeyEditor = false
                            } else {
                                showSecondGroupKeyEditor = false 
                            }
                        }
                    }
                } else {
                    Button {
                        showSecondGroupKeyEditor.toggle()
                    } label: {
                        Label("More Group Key", systemImage: "plus.circle")
                    }
                }
                if showThirdGroupKeyEditor {
                    GroupKeyPicker(dataFrame: dataFrame, title: "Group Key 3", selection: builder.groupByKeys[safe: 2]?.columnName) { type in
                        if builder.groupByKeys.indices.contains(2) {
                            builder.groupByKeys[2] = type
                        } else {
                            builder.groupByKeys.append(type)
                        }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            if builder.groupByKeys.indices.contains(2) {
                                builder.groupByKeys.remove(at: 2)
                            }
                            showSecondGroupKeyEditor = false
                        }
                    }
                } else if showSecondGroupKeyEditor {
                    Button {
                        showThirdGroupKeyEditor.toggle()
                    } label: {
                        Label("More Group Key", systemImage: "plus.circle")
                    }
                }
            }
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("On")
                            .foregroundStyle(.secondary)
                        Menu {
                            ForEach(dataFrame.columns, id: \.name) { column in
                                Button {
                                    builder.aggregationColumn = column.name
                                } label: {
                                    Text("\(column.name.uppercased()) (\(String(describing: column.wrappedElementType)))")
                                }
                            }
                        } label: {
                            Group {
                                if let aggregationType, let currentColumn = builder.aggregationColumn {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(currentColumn) ")
                                            .font(.title2)
                                            .bold()
                                            + Text(String(describing: aggregationType))
                                            .font(.caption2)
                                    }
                                } else {
                                    Text("Column")
                                        .font(.title2)
                                        .bold()
                                }
                            }
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.quinary)
                                    .foregroundStyle(.quaternary)
                            }
                        }
                    }
                    .padding(.trailing)
                    if let aggregationType {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Aggregate with")
                                .foregroundStyle(.secondary)
                            Menu {
                                let allCases: [AggregationOperation] = {
                                    switch String(describing: aggregationType) {
                                    case String(describing: Int.self):
                                        return AggregationOperation.IntegerAggregationOperation.allCases.map { AggregationOperation.integer($0) }
                                    case String(describing: Double.self):
                                        return AggregationOperation.DoubleAggregationOperation.allCases.map { AggregationOperation.double($0) }
                                    case String(describing: Date.self):
                                        return AggregationOperation.DateAggregationOperation.allCases.map { AggregationOperation.date($0) }
                                    case String(describing: Bool.self):
                                        return AggregationOperation.BoolAggregationOperation.allCases.map { AggregationOperation.bool($0) }
                                    case String(describing: String.self):
                                        return AggregationOperation.StringAggregationOperation.allCases.map { AggregationOperation.string($0) }
                                    default:
                                        return []
                                    }
                                }()
                                ForEach(allCases, id: \.hashValue) { operation in
                                    Button(operation.description) {
                                        builder.aggregationOperation = operation
                                    }
                                }
                            } label: {
                                Group {
                                    if let aggregationOperation = builder.aggregationOperation {
                                        Text(aggregationOperation.description)
                                    } else {
                                        Text("Function")
                                    }
                                }
                                .font(.title2)
                                .bold()
                                .padding()
                                .background {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.quinary)
                                        .foregroundStyle(.quaternary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            } header: {
                Text("Aggregation")
                    .font(.headline)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    completion(AnyReducer.groupByReducer(builder.build()!))
                } label: {
                    Text("Done")
                }
                .disabled(builder.build() == nil)
            }
        }
    }

    var aggregationType: Any.Type? {
        guard let col = builder.aggregationColumn else { return nil }
        return dataFrame.columns.first(where: { column in
            col == column.name
        })?.wrappedElementType
    }

    @Observable
    class OperationBuilder {
        var groupByKeys: [GroupByReducer.GroupKey.GroupKeyType] = []

        var aggregationColumn: String? {
            didSet {
                if aggregationColumn != oldValue {
                    aggregationOperation == nil
                }
            }
        }

        var aggregationOperation: AggregationOperation?

        init(groupByKeys: [GroupByReducer.GroupKey.GroupKeyType] = [], aggregationColumn: String? = nil, aggregationOperation: AggregationOperation? = nil) {
            self.groupByKeys = groupByKeys
            self.aggregationColumn = aggregationColumn
            self.aggregationOperation = aggregationOperation
        }

        func build() -> GroupByReducer? {
            guard let aggregationColumn, let aggregationOperation else { return nil }
            guard !groupByKeys.isEmpty else { return nil }
            let groupKey: GroupByReducer.GroupKey = switch groupByKeys.count {
            case 1:
                GroupByReducer.GroupKey.one(groupByKeys[0])
            case 2:
                GroupByReducer.GroupKey.two(groupByKeys[0], groupByKeys[1])
            default:
                GroupByReducer.GroupKey.three(groupByKeys[0], groupByKeys[1], groupByKeys[2])
            }
            return GroupByReducer(groupKey: groupKey, operation: .init(column: aggregationColumn, operation: aggregationOperation))
        }
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
