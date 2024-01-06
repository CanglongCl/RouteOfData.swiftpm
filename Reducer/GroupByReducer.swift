//
//  File.swift
//  
//
//  Created by 戴藏龙 on 2024/1/4.
//

import Foundation
import TabularData

enum GroupByReducer: Codable, ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        var dataFrame = dataFrame
        let (groupBy, column, operation, validator) = {
            switch self {
            case .boolean(let p):
                let groupBy = dataFrame.grouped(by: p.groupKeyColumn)
                let column = p.aggregationOperation.column
                return (groupBy, column, p.aggregationOperation.operation, p.aggregationOperation)
            case .integer(let p):
                let groupBy = dataFrame.grouped(by: p.groupKeyColumn)
                let column = p.aggregationOperation.column
                return (groupBy, column, p.aggregationOperation.operation, p.aggregationOperation)
            case .double(let p):
                let groupBy = dataFrame.grouped(by: p.groupKeyColumn)
                let column = p.aggregationOperation.column
                return (groupBy, column, p.aggregationOperation.operation, p.aggregationOperation)
            case .date(let p):
                let groupBy = dataFrame.grouped(by: p.groupKeyColumn, timeUnit: p.groupByDateComponent.component)
                let column = p.aggregationOperation.column
                return (groupBy, column, p.aggregationOperation.operation, p.aggregationOperation)
            case .string(let p):
                let groupBy = dataFrame.grouped(by: p.groupKeyColumn)
                let column = p.aggregationOperation.column
                return (groupBy, column, p.aggregationOperation.operation, p.aggregationOperation)
            }
        }()
        try validator.validate(dataFrame)
        switch operation {
        case .integer(let operation):
            let columnID = ColumnID(column, Int.self)
            switch operation {
            case .sum:
                dataFrame = groupBy.sums(columnID)
            case .max:
                dataFrame = groupBy.maximums(columnID)
            case .min:
                dataFrame = groupBy.minimums(columnID)
            }
        case .double(let operation):
            let columnID = ColumnID(column, Double.self)
            switch operation {
            case .sum:
                dataFrame = groupBy.sums(columnID)
            case .max:
                dataFrame = groupBy.maximums(columnID)
            case .min:
                dataFrame = groupBy.minimums(columnID)
            case .mean:
                dataFrame = groupBy.means(columnID)
            }
        case .date(let operation):
            let columnID = ColumnID(column, Date.self)
            switch operation {
            case .max:
                dataFrame = groupBy.maximums(columnID)
            case .min:
                dataFrame = groupBy.minimums(columnID)
            }
        case .bool(let operation):
            let columnID = ColumnID(column, Bool.self)
            switch operation {
            case .sum:
                dataFrame = groupBy.aggregated(on: columnID, transform: { slice in
                    slice.map { value in
                        value ?? false ? 1 : 0
                    }
                    .sum()
                })
            }
        case .string(let operation):
            let columnID = ColumnID(column, Bool.self)
            switch operation {
            case .countDifferent:
                dataFrame = groupBy.aggregated(on: columnID, transform: { slice in
                    slice.distinct().count
                })
            }
        }
        return dataFrame
    }

    case boolean(GroupByParameter)
    case integer(GroupByParameter)
    case double(GroupByParameter)
    case date(GroupByDateParameter)
    case string(GroupByParameter)
}

struct GroupByParameter: Codable {
    var groupKeyColumn: String
    var aggregationOperation: AggregationOperationParameter
}

struct GroupByDateParameter: Codable {
    var groupKeyColumn: String
    var aggregationOperation: AggregationOperationParameter

    var groupByDateComponent: GroupByKey

    enum GroupByKey: Codable {
        case year
        case month
        case day

        var component: Calendar.Component {
            switch self {
            case .year:
                Calendar.Component.year
            case .month:
                Calendar.Component.month
            case .day:
                Calendar.Component.day
            }
        }
    }
}

struct AggregationOperationParameter: Codable {
    var column: String
    var operation: AggregationOperation

    var type: Any.Type {
        switch operation {
        case .integer(_):
            Int.self
        case .double(_):
            Double.self
        case .date(_):
            Date.self
        case .bool(_):
            Bool.self
        case .string(_):
            String.self
        }
    }

    func validate(_ dataFrame: DataFrame) throws {
        guard dataFrame.containsColumn(column) else {
            throw ReducerError.columnNotFound(columnName: column)
        }
        guard dataFrame[column].wrappedElementType == type else {
            throw ReducerError.typeUnavailable(columnName: column, columnType: dataFrame[column].wrappedElementType, reducerType: type)
        }
    }
}

enum AggregationOperation: Codable {
    case integer(IntegerAggregationOperation)
    case double(DoubleAggregationOperation)
    case date(DateAggregationOperation)
    case bool(BoolAggregationOperation)
    case string(StringAggregationOperation)

    enum IntegerAggregationOperation: Codable {
        case sum
        case max
        case min
    }

    enum DoubleAggregationOperation: Codable {
        case sum
        case max
        case min
        case mean
    }

    enum DateAggregationOperation: Codable {
        case max
        case min
    }

    enum BoolAggregationOperation: Codable {
        case sum
    }

    enum StringAggregationOperation: Codable {
        case countDifferent
    }
}




