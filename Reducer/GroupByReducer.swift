//
//  GroupByReducer.swift
//
//
//  Created by 戴藏龙 on 2024/1/4.
//

import Foundation
import TabularData

struct GroupByReducer: Codable, ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        switch groupKey {
        case let .one(groupKeyType):
            try groupKeyType.validate(dataFrame)
        case let .two(groupKeyType, groupKeyType2):
            try groupKeyType.validate(dataFrame)
            try groupKeyType2.validate(dataFrame)
        case let .three(groupKeyType, groupKeyType2, groupKeyType3):
            try groupKeyType.validate(dataFrame)
            try groupKeyType2.validate(dataFrame)
            try groupKeyType3.validate(dataFrame)
        }

        try operation.validate(dataFrame)

        var dataFrame = dataFrame

        switch groupKey {
        case let .one(groupKeyType):
            dataFrame = groupKeyType.reduce(dataFrame)
        case let .two(groupKeyType, groupKeyType2):
            dataFrame = groupKeyType.reduce(dataFrame)
            dataFrame = groupKeyType2.reduce(dataFrame)
        case let .three(groupKeyType, groupKeyType2, groupKeyType3):
            dataFrame = groupKeyType.reduce(dataFrame)
            dataFrame = groupKeyType2.reduce(dataFrame)
            dataFrame = groupKeyType3.reduce(dataFrame)
        }

        let groupBy: any RowGroupingProtocol = switch groupKey {
        case let .one(groupKeyType):
            dataFrame.grouped(by: groupKeyType.columnName)
        case let .two(groupKeyType, groupKeyType2):
            switch groupKeyType {
            case .any(columnName: _):
                switch groupKeyType2 {
                case .any(columnName: _):
                    dataFrame.grouped(by: ColumnID(groupKeyType.columnName, String.self), ColumnID(groupKeyType2.columnName, String.self))
                case .date(columnName: _, groupByDateComponent: _):
                    dataFrame.grouped(by: ColumnID(groupKeyType.columnName, String.self), ColumnID(groupKeyType2.columnName, Date.self))
                }
            case .date(columnName: _, groupByDateComponent: _):
                switch groupKeyType2 {
                case .any(columnName: _):
                    dataFrame.grouped(by: ColumnID(groupKeyType.columnName, Date.self), ColumnID(groupKeyType2.columnName, String.self))
                case .date(columnName: _, groupByDateComponent: _):
                    dataFrame.grouped(by: ColumnID(groupKeyType.columnName, Date.self), ColumnID(groupKeyType2.columnName, Date.self))
                }
            }
        case let .three(groupKeyType, groupKeyType2, groupKeyType3):
            switch groupKeyType {
            case .any(columnName: _):
                switch groupKeyType2 {
                case .any(columnName: _):
                    switch groupKeyType3 {
                    case .any(columnName: _):
                        dataFrame.grouped(by: ColumnID(groupKeyType.columnName, String.self), ColumnID(groupKeyType2.columnName, String.self), ColumnID(groupKeyType3.columnName, String.self))
                    case .date(columnName: _, groupByDateComponent: _):
                        dataFrame.grouped(by: ColumnID(groupKeyType.columnName, String.self), ColumnID(groupKeyType2.columnName, String.self), ColumnID(groupKeyType3.columnName, Date.self))
                    }
                case .date(columnName: _, groupByDateComponent: _):
                    switch groupKeyType3 {
                    case .any(columnName: _):
                        dataFrame.grouped(by: ColumnID(groupKeyType.columnName, String.self), ColumnID(groupKeyType2.columnName, Date.self), ColumnID(groupKeyType3.columnName, String.self))
                    case .date(columnName: _, groupByDateComponent: _):
                        dataFrame.grouped(by: ColumnID(groupKeyType.columnName, String.self), ColumnID(groupKeyType2.columnName, Date.self), ColumnID(groupKeyType3.columnName, Date.self))
                    }
                }
            case .date(columnName: _, groupByDateComponent: _):
                switch groupKeyType2 {
                case .any(columnName: _):
                    switch groupKeyType3 {
                    case .any(columnName: _):
                        dataFrame.grouped(by: ColumnID(groupKeyType.columnName, Date.self), ColumnID(groupKeyType2.columnName, String.self), ColumnID(groupKeyType3.columnName, String.self))
                    case .date(columnName: _, groupByDateComponent: _):
                        dataFrame.grouped(by: ColumnID(groupKeyType.columnName, Date.self), ColumnID(groupKeyType2.columnName, String.self), ColumnID(groupKeyType3.columnName, Date.self))
                    }
                case .date(columnName: _, groupByDateComponent: _):
                    switch groupKeyType3 {
                    case .any(columnName: _):
                        dataFrame.grouped(by: ColumnID(groupKeyType.columnName, Date.self), ColumnID(groupKeyType2.columnName, Date.self), ColumnID(groupKeyType3.columnName, String.self))
                    case .date(columnName: _, groupByDateComponent: _):
                        dataFrame.grouped(by: ColumnID(groupKeyType.columnName, Date.self), ColumnID(groupKeyType2.columnName, Date.self), ColumnID(groupKeyType3.columnName, Date.self))
                    }
                }
            }
        }

        let column = operation.column
        let operation = operation.operation

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

    let groupKey: GroupKey
    let operation: AggregationOperationParameter

    enum GroupKey: Codable {
        case one(GroupKeyType)
        case two(GroupKeyType, GroupKeyType)
        case three(GroupKeyType, GroupKeyType, GroupKeyType)

        func intoArray() -> [GroupKeyType] {
            switch self {
            case let .one(groupKeyType):
                [groupKeyType]
            case let .two(groupKeyType, groupKeyType2):
                [groupKeyType, groupKeyType2]
            case let .three(groupKeyType, groupKeyType2, groupKeyType3):
                [groupKeyType, groupKeyType2, groupKeyType3]
            }
        }

        enum GroupKeyType: Codable {
            case any(columnName: String)
            case date(columnName: String, groupByDateComponent: GroupByDateKey)

            var columnName: String {
                switch self {
                case let .any(columnName):
                    columnName
                case let .date(columnName, _):
                    columnName
                }
            }

            func reduce(_ dataFrame: DataFrame) -> DataFrame {
                var dataFrame = dataFrame
                switch self {
                case let .any(columnName):
                    let elements = dataFrame[columnName].map { element -> String? in
                        guard let element else { return nil }
                        if let element = element as? CustomStringConvertible {
                            return element.description
                        } else {
                            return String(describing: element)
                        }
                    }
                    let column = Column(name: columnName, contents: elements)
                    dataFrame.insertOrReplaceIfExists(column)
                case let .date(columnName, groupByDateComponent):
                    let calendar = Calendar.current
                    var column = dataFrame[ColumnID(columnName, Date.self)].map { date -> Date? in
                        guard let date else { return nil }
                        let component = calendar.dateComponents([.day, .month, .year], from: date)
                        switch groupByDateComponent {
                        case .day:
                            return calendar.date(from: DateComponents(year: component.year, month: component.month, day: component.day))
                        case .month:
                            return calendar.date(from: DateComponents(year: component.year, month: component.month))
                        case .year:
                            return calendar.date(from: DateComponents(year: component.year))
                        }
                    }
                    column.name = columnName
                    dataFrame.insertOrReplaceIfExists(column)
                }
                return dataFrame
            }

            enum GroupByDateKey: String, Codable, CustomStringConvertible, CaseIterable, Identifiable {
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

            func validate(_ dataFrame: DataFrame) throws {
                switch self {
                case let .any(columnName):
                    guard dataFrame.containsColumn(columnName) else {
                        throw ReducerError.columnNotFound(columnName: columnName)
                    }
                case let .date(columnName, _):
                    guard dataFrame.containsColumn(columnName) else {
                        throw ReducerError.columnNotFound(columnName: columnName)
                    }
                    guard dataFrame.containsColumn(columnName, Date.self) else {
                        throw ReducerError.typeUnavailable(columnName: columnName, columnType: dataFrame[columnName].wrappedElementType, reducerType: Date.self)
                    }
                }
            }
        }
    }
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
