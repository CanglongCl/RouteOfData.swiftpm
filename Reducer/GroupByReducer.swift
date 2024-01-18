//
//  GroupByReducer.swift
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
            case let .any(p):
                let groupBy = dataFrame.grouped(by: p.groupKeyColumn)
                let column = p.aggregationOperation.column
                return (groupBy, column, p.aggregationOperation.operation, p.aggregationOperation)
            case let .date(p):
                let groupBy = dataFrame.grouped(by: p.groupKeyColumn) { (key: Date?) -> Date? in
                    guard let key else { return nil }
                    let calendar = Calendar.current
                    let component = calendar.dateComponents([.day, .month, .year], from: key)
                    switch p.groupByDateComponent {
                    case .day:
                        return calendar.date(from: DateComponents(year: component.year, month: component.month, day: component.day))
                    case .month:
                        return calendar.date(from: DateComponents(year: component.year, month: component.month))
                    case .year:
                        return calendar.date(from: DateComponents(year: component.year))
                    }
                }
                let column = p.aggregationOperation.column
                return (groupBy, column, p.aggregationOperation.operation, p.aggregationOperation)
            }
        }()
        try validator.validate(dataFrame)
        switch operation {
        case let .integer(operation):
            let columnID = ColumnID(column, Int.self)
            switch operation {
            case .sum:
                dataFrame = groupBy.sums(columnID)
            case .max:
                dataFrame = groupBy.maximums(columnID)
            case .min:
                dataFrame = groupBy.minimums(columnID)
            }
        case let .double(operation):
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
        case let .date(operation):
            let columnID = ColumnID(column, Date.self)
            switch operation {
            case .max:
                dataFrame = groupBy.maximums(columnID)
            case .min:
                dataFrame = groupBy.minimums(columnID)
            }
        case let .bool(operation):
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
        case let .string(operation):
            let columnID = ColumnID(column, String.self)
            switch operation {
            case .countDifferent:
                dataFrame = groupBy.aggregated(on: columnID, transform: { slice in
                    slice.distinct().count
                })
            }
        }
        return dataFrame
    }

    case any(GroupByParameter)
    case date(GroupByDateParameter)
}

struct GroupByParameter: Codable {
    var groupKeyColumn: String
    var aggregationOperation: AggregationOperationParameter
}

struct GroupByDateParameter: Codable {
    var groupKeyColumn: String
    var aggregationOperation: AggregationOperationParameter

    var groupByDateComponent: GroupByKey

    enum GroupByKey: String, Codable, CustomStringConvertible, CaseIterable, Identifiable {
        var description: String {
            switch self {
            case .year:
                "Year"
            case .month:
                "Month"
            case .day:
                "Day"
            }
        }

        var id: String { rawValue }

        case day
        case month
        case year
    }
}

struct AggregationOperationParameter: Codable {
    var column: String
    var operation: AggregationOperation

    var type: Any.Type {
        switch operation {
        case .integer:
            Int.self
        case .double:
            Double.self
        case .date:
            Date.self
        case .bool:
            Bool.self
        case .string:
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

enum AggregationOperation: Codable, Hashable, CustomStringConvertible {
    case integer(IntegerAggregationOperation)
    case double(DoubleAggregationOperation)
    case date(DateAggregationOperation)
    case bool(BoolAggregationOperation)
    case string(StringAggregationOperation)

    var description: String {
        switch self {
        case let .integer(integerAggregationOperation):
            integerAggregationOperation.description
        case let .double(doubleAggregationOperation):
            doubleAggregationOperation.description
        case let .date(dateAggregationOperation):
            dateAggregationOperation.description
        case let .bool(boolAggregationOperation):
            boolAggregationOperation.description
        case let .string(stringAggregationOperation):
            stringAggregationOperation.description
        }
    }

    enum IntegerAggregationOperation: Codable, Hashable, CaseIterable, CustomStringConvertible {
        var description: String {
            switch self {
            case .sum:
                "Sum"
            case .max:
                "Max"
            case .min:
                "Min"
            }
        }

        case sum
        case max
        case min
    }

    enum DoubleAggregationOperation: Codable, Hashable, CaseIterable, CustomStringConvertible {
        case sum
        case max
        case min
        case mean

        var description: String {
            switch self {
            case .sum:
                "Sum"
            case .max:
                "Max"
            case .min:
                "Min"
            case .mean:
                "Mean"
            }
        }
    }

    enum DateAggregationOperation: Codable, Hashable, CaseIterable, CustomStringConvertible {
        case max
        case min

        var description: String {
            switch self {
            case .max:
                "Max"
            case .min:
                "Min"
            }
        }
    }

    enum BoolAggregationOperation: Codable, Hashable, CaseIterable, CustomStringConvertible {
        case sum

        var description: String {
            switch self {
            case .sum:
                "Sum"
            }
        }
    }

    enum StringAggregationOperation: Codable, Hashable, CaseIterable, CustomStringConvertible {
        case countDifferent

        var description: String {
            switch self {
            case .countDifferent:
                "Count Different"
            }
        }
    }
}
