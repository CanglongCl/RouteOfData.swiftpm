//
//  BooleanReducer.swift
//
//
//  Created by 戴藏龙 on 2024/1/4.
//

import Foundation
import TabularData

enum BooleanReducer: Codable {
    case multiColumnReducer(MultiColumnReducer)
    case singleColumnReducer(SingleColumnReducer)

    enum MultiColumnReducer: Codable {
        case and(MultiColumnReducerParameter<Bool>)
        case or(MultiColumnReducerParameter<Bool>)
    }

    enum SingleColumnReducer: Codable {
        case not(SingleColumnReducerParameter<Bool>)
        case castInt(SingleColumnReducerParameter<Bool>)
        case filter(SingleColumnReducerParameter<Bool>)
        case fillNil(SingleColumnWithParameterReducerParameter<Bool>)
    }
}

extension BooleanReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        switch self {
        case let .multiColumnReducer(multiColumnReducer):
            return try multiColumnReducer.reduce(dataFrame)
        case let .singleColumnReducer(singleColumnReducer):
            return try singleColumnReducer.reduce(dataFrame)
        }
    }
}

extension BooleanReducer.MultiColumnReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        var dataFrame = dataFrame
        switch self {
        case let .and(p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Bool?, rhs: Bool?) -> Bool? in
                guard let lhs, let rhs else { return nil }
                return lhs && rhs
            }
        case let .or(p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Bool?, rhs: Bool?) -> Bool? in
                guard let lhs, let rhs else { return nil }
                return lhs || rhs
            }
        }
        return dataFrame
    }
}

extension BooleanReducer.SingleColumnReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        var dataFrame = dataFrame
        switch self {
        case let .not(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Bool.self].mapNonNil { value in
                !value
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .castInt(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Bool.self].mapNonNil { value in
                value ? 1 : 0
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .filter(p):
            try p.validate(dataFrame: dataFrame)
            dataFrame = DataFrame(dataFrame.filter(on: ColumnID(p.column, Bool.self)) { value in
                let value = value ?? false
                return value
            })
        case let .fillNil(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Bool.self].map { value in
                (value ?? p.rhs) as Bool?
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        }
        return dataFrame
    }
}
