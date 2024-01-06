//
//  File.swift
//  
//
//  Created by 戴藏龙 on 2024/1/4.
//

import Foundation
import TabularData

protocol ReducerProtocol: Codable {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame
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

protocol ColumnReducerParameter {}

struct SingleColumnReducerParameter: Codable, ColumnReducerParameter {
    var column: String

    var intoColumn: String
}

struct SingleColumnWithParameterReducerParameter<T: Codable>: Codable, ColumnReducerParameter {
    var column: String
    var rhs: T

    var intoColumn: String
}

struct MultiColumnReducerParameter: Codable, ColumnReducerParameter {
    var lhsColumn: String
    var rhsColumn: String

    var intoColumn: String
}
