//
//  File.swift
//  
//
//  Created by 戴藏龙 on 2024/1/4.
//

import Foundation
import TabularData

enum ReducerError: Error {
    case typeUnavailable(columnName: String, columnType: Any.Type, reducerType: Any.Type)
    case columnNotFound(columnName: String)
    case columnsNotFound(columnNames: [String])
}

protocol ReducerProtocol: Codable {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame
}

enum AnyReducer: RawRepresentable, Codable, ReducerProtocol {
    var rawValue: Data {
        try! JSONEncoder().encode(self)
    }

    init?(rawValue: Data) {
        self = try! JSONDecoder().decode(AnyReducer.self, from: rawValue)
    }
    
    typealias RawValue = Data

    case columnReducer(AnyColumnReducer)
    case groupByReducer(GroupByReducer)
    case summary(SummaryReducer)
    case selectReducer(SelectReducer)

    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        print(dataFrame.summary())
        return switch self {
        case .columnReducer(let reducer):
            try reducer.reduce(dataFrame)
        case .groupByReducer(let reducer):
            try reducer.reduce(dataFrame)
        case .summary(let reducer):
            try reducer.reduce(dataFrame)
        case .selectReducer(let reducer):
            try reducer.reduce(dataFrame)
        }
    }
}

enum SummaryReducer: ReducerProtocol {
    case all
    case singleColumn(String)

    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        switch self {
        case .all:
            return dataFrame.summary()
        case .singleColumn(let column):
            guard dataFrame.containsColumn(column) else {
                throw ReducerError.columnNotFound(columnName: column)
            }
            return dataFrame.summary(of: column)
        }
    }
}

enum AnyColumnReducer: Codable, ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        switch self {
        case .boolean(let reducer):
            try reducer.reduce(dataFrame)
        case .integer(let reducer):
            try reducer.reduce(dataFrame)
        case .double(let reducer):
            try reducer.reduce(dataFrame)
        case .date(let reducer):
            try reducer.reduce(dataFrame)
        case .string(let reducer):
            try reducer.reduce(dataFrame)
        }
    }

    case boolean(BooleanReducer)
    case integer(IntegerReducer)
    case double(DoubleReducer)
    case date(DateReducer)
    case string(StringReducer)
}

protocol ReducerResult {}

extension DataFrame: ReducerResult {}

protocol ColumnReducerParameter {
    func validate(dataFrame: DataFrame) throws
}

struct SingleColumnReducerParameter<T>: Codable, ColumnReducerParameter {
    func validate(dataFrame: DataFrame) throws {
        guard dataFrame.containsColumn(column) else {
            throw ReducerError.columnNotFound(columnName: column)
        }
        guard dataFrame.containsColumn(column, T.self) else {
            throw ReducerError.typeUnavailable(columnName: column, columnType: dataFrame[column].wrappedElementType, reducerType: T.self)
        }
    }
    
    var column: String

    var intoColumn: String
}

struct SingleColumnWithParameterReducerParameter<T: Codable>: Codable, ColumnReducerParameter {
    func validate(dataFrame: DataFrame) throws {
        guard dataFrame.containsColumn(column) else {
            throw ReducerError.columnNotFound(columnName: column)
        }
        guard dataFrame.containsColumn(column, T.self) else {
            throw ReducerError.typeUnavailable(columnName: column, columnType: dataFrame[column].wrappedElementType, reducerType: T.self)
        }
    }

    var column: String
    var rhs: T

    var intoColumn: String
}

struct MultiColumnReducerParameter<T>: Codable, ColumnReducerParameter {
    func validate(dataFrame: DataFrame) throws {
        guard dataFrame.containsColumn(lhsColumn) else {
            throw ReducerError.columnNotFound(columnName: lhsColumn)
        }
        guard dataFrame.containsColumn(rhsColumn) else {
            throw ReducerError.columnNotFound(columnName: rhsColumn)
        }
        guard dataFrame[lhsColumn].wrappedElementType == T.self else {
            throw ReducerError.typeUnavailable(columnName: lhsColumn, columnType: dataFrame[lhsColumn].wrappedElementType, reducerType: T.self)
        }
        guard dataFrame[rhsColumn].wrappedElementType == T.self else {
            throw ReducerError.typeUnavailable(columnName: lhsColumn, columnType: dataFrame[rhsColumn].wrappedElementType, reducerType: T.self)
        }
    }

    var lhsColumn: String
    var rhsColumn: String

    var intoColumn: String
}
