//
//  File.swift
//  
//
//  Created by 戴藏龙 on 2024/1/5.
//

import Foundation
import SwiftUI
import TabularData

@available(iOS 17.0, *)
struct GroupByOperationEditView: View {
    let dataFrame: DataFrame
    let completion: (AnyReducer) -> ()

    var body: some View {
        List {
            ForEach(dataFrame.columns, id: \.name) { column in
                NavigationLink {
                    switch String(describing: column.wrappedElementType) {
                    case String(describing: Date.self):
                        DateGroupByOperationView(groupByKey: column.name, dataFrame: dataFrame, completion: completion)
                    default:
                        AnyGroupByOperationView(groupByKey: column.name, dataFrame: dataFrame, completion: completion)
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
        .navigationTitle("Pick Group Key")
    }
}

@available(iOS 17.0, *)
struct AnyGroupByOperationView: View {
    @State private var builder: OperationBuilder

    init(groupByKey: String, dataFrame: DataFrame, completion: @escaping (AnyReducer) -> Void) {
        self._builder = .init(initialValue: .init(groupByKey: groupByKey))
        self.dataFrame = dataFrame
        self.completion = completion
    }

    init(reducer: GroupByParameter, dataFrame: DataFrame, completion: @escaping (AnyReducer) -> Void) {
        self._builder = .init(initialValue: .init(groupByKey: reducer.groupKeyColumn, aggregationColumn: reducer.aggregationOperation.column, aggregationOperation: reducer.aggregationOperation.operation))
        self.dataFrame = dataFrame
        self.completion = completion
    }

    let dataFrame: DataFrame

    let completion: (AnyReducer) -> ()

    var body: some View {
        List {
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
                            Text("With")
                                .foregroundStyle(.secondary)
                            Menu {
                                let allCases: [AggregationOperation] = {
                                    switch String(describing: aggregationType) {
                                    case String(describing: Int.self):
                                        return AggregationOperation.IntegerAggregationOperation.allCases.map({AggregationOperation.integer($0)})
                                    case String(describing: Double.self):
                                        return AggregationOperation.DoubleAggregationOperation.allCases.map({AggregationOperation.double($0)})
                                    case String(describing: Date.self):
                                        return AggregationOperation.DateAggregationOperation.allCases.map({AggregationOperation.date($0)})
                                    case String(describing: Bool.self):
                                        return AggregationOperation.BoolAggregationOperation.allCases.map({AggregationOperation.bool($0)})
                                    case String(describing: String.self):
                                        return AggregationOperation.StringAggregationOperation.allCases.map({AggregationOperation.string($0)})
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
        .navigationTitle("Group By \(builder.groupByKey.uppercased()) & Aggregation")
    }

    var aggregationType: Any.Type? {
        guard let col = builder.aggregationColumn else { return nil }
        return dataFrame.columns.first(where: { column in
            col == column.name
        })?.wrappedElementType
    }

    @Observable
    class OperationBuilder {
        var groupByKey: String
        var aggregationColumn: String? {
            didSet {
                if aggregationColumn != oldValue {
                    aggregationOperation == nil
                }
            }
        }
        var aggregationOperation: AggregationOperation?

        init(groupByKey: String, aggregationColumn: String? = nil, aggregationOperation: AggregationOperation? = nil) {
            self.groupByKey = groupByKey
            self.aggregationColumn = aggregationColumn
            self.aggregationOperation = aggregationOperation
        }

        func build() -> GroupByReducer? {
            guard let aggregationColumn, let aggregationOperation else { return nil }
            return .any(.init(groupKeyColumn: groupByKey, aggregationOperation: .init(column: aggregationColumn, operation: aggregationOperation)))
        }
    }
}

@available(iOS 17.0, *)
struct DateGroupByOperationView: View {
    @State private var builder: OperationBuilder

    init(groupByKey: String, dataFrame: DataFrame, completion: @escaping (AnyReducer) -> Void) {
        self._builder = .init(initialValue: .init(groupByKey: groupByKey))
        self.dataFrame = dataFrame
        self.completion = completion
    }

    init(reducer: GroupByDateParameter, dataFrame: DataFrame, completion: @escaping (AnyReducer) -> Void) {
        self._builder = .init(initialValue: .init(groupByKey: reducer.groupKeyColumn, aggregationColumn: reducer.aggregationOperation.column, aggregationOperation: reducer.aggregationOperation.operation, groupByDateComponent: reducer.groupByDateComponent))
        self.dataFrame = dataFrame
        self.completion = completion
    }

    let dataFrame: DataFrame

    let completion: (AnyReducer) -> ()

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Group by")
                            .foregroundStyle(.secondary)
                        Menu {
                            ForEach(GroupByDateParameter.GroupByKey.allCases) { component in
                                Button {
                                    builder.groupByDateComponent = component
                                } label: {
                                    Text(component.description)
                                }
                            }
                        } label: {
                            Group {
                                if let component = builder.groupByDateComponent {
                                    Text(component.description)
                                } else {
                                    Text("Date Component")
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
                    .padding(.trailing)
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
                    .padding(.horizontal)
                    if let aggregationType {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("With")
                                .foregroundStyle(.secondary)
                            Menu {
                                let allCases: [AggregationOperation] = {
                                    switch String(describing: aggregationType) {
                                    case String(describing: Int.self):
                                        return AggregationOperation.IntegerAggregationOperation.allCases.map({AggregationOperation.integer($0)})
                                    case String(describing: Double.self):
                                        return AggregationOperation.DoubleAggregationOperation.allCases.map({AggregationOperation.double($0)})
                                    case String(describing: Date.self):
                                        return AggregationOperation.DateAggregationOperation.allCases.map({AggregationOperation.date($0)})
                                    case String(describing: Bool.self):
                                        return AggregationOperation.BoolAggregationOperation.allCases.map({AggregationOperation.bool($0)})
                                    case String(describing: String.self):
                                        return AggregationOperation.StringAggregationOperation.allCases.map({AggregationOperation.string($0)})
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
        .navigationTitle("Group By \(builder.groupByKey.uppercased()) & Aggregation")
    }

    var aggregationType: Any.Type? {
        guard let col = builder.aggregationColumn else { return nil }
        return dataFrame.columns.first(where: { column in
            col == column.name
        })?.wrappedElementType
    }

    @Observable
    class OperationBuilder {
        var groupByKey: String
        var aggregationColumn: String? {
            didSet {
                if aggregationColumn != oldValue {
                    aggregationOperation == nil
                }
            }
        }
        var aggregationOperation: AggregationOperation?
        var groupByDateComponent: GroupByDateParameter.GroupByKey?

        init(groupByKey: String, aggregationColumn: String? = nil, aggregationOperation: AggregationOperation? = nil, groupByDateComponent: GroupByDateParameter.GroupByKey? = nil) {
            self.groupByKey = groupByKey
            self.aggregationColumn = aggregationColumn
            self.aggregationOperation = aggregationOperation
            self.groupByDateComponent = groupByDateComponent
        }

        func build() -> GroupByReducer? {
            guard let aggregationColumn, let aggregationOperation, let groupByDateComponent else { return nil }
            return .date(.init(groupKeyColumn: groupByKey, aggregationOperation: .init(column: aggregationColumn, operation: aggregationOperation), groupByDateComponent: groupByDateComponent))
        }
    }
}
