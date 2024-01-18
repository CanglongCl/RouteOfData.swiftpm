//
//  DateReducer.swift
//
//
//  Created by 戴藏龙 on 2024/1/4.
//

import Foundation
import TabularData

enum DateReducer: Codable {
    case multiColumnReducer(MultiColumnReducer)
    case singleColumnReducer(SingleColumnReducer)

    enum MultiColumnReducer: Codable {
        case equalTo(MultiColumnReducerParameter<Date>)
        case moreThan(MultiColumnReducerParameter<Date>)
        case lessThan(MultiColumnReducerParameter<Date>)
        case moreThanOrEqualTo(MultiColumnReducerParameter<Date>)
        case lessThanOrEqualTo(MultiColumnReducerParameter<Date>)
    }

    enum SingleColumnReducer: Codable {
        case equalTo(SingleColumnWithParameterReducerParameter<Date>)
        case moreThan(SingleColumnWithParameterReducerParameter<Date>)
        case lessThan(SingleColumnWithParameterReducerParameter<Date>)
        case moreThanOrEqualTo(SingleColumnWithParameterReducerParameter<Date>)
        case lessThanOrEqualTo(SingleColumnWithParameterReducerParameter<Date>)
        case fillNil(SingleColumnWithParameterReducerParameter<Date>)
    }
}

extension DateReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        switch self {
        case let .multiColumnReducer(multiColumnReducer):
            return try multiColumnReducer.reduce(dataFrame)
        case let .singleColumnReducer(singleColumnReducer):
            return try singleColumnReducer.reduce(dataFrame)
        }
    }
}

extension DateReducer.MultiColumnReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        var dataFrame = dataFrame
        switch self {
        case let .equalTo(p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Int?, rhs: Int?) -> Bool? in
                guard let lhs, let rhs else { return nil }
                return lhs == rhs
            }
        case let .moreThan(p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Int?, rhs: Int?) -> Bool? in
                guard let lhs, let rhs else { return nil }
                return lhs > rhs
            }
        case let .lessThan(p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Int?, rhs: Int?) -> Bool? in
                guard let lhs, let rhs else { return nil }
                return lhs < rhs
            }
        case let .moreThanOrEqualTo(p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Int?, rhs: Int?) -> Bool? in
                guard let lhs, let rhs else { return nil }
                return lhs >= rhs
            }
        case let .lessThanOrEqualTo(p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Int?, rhs: Int?) -> Bool? in
                guard let lhs, let rhs else { return nil }
                return lhs <= rhs
            }
        }
        return dataFrame
    }
}

extension DateReducer.SingleColumnReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        var dataFrame = dataFrame
        switch self {
        case let .equalTo(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Date.self].mapNonNil { value in
                value == p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .moreThan(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Date.self].mapNonNil { value in
                value > p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .lessThan(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Date.self].mapNonNil { value in
                value < p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .moreThanOrEqualTo(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Date.self].mapNonNil { value in
                value >= p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .lessThanOrEqualTo(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Date.self].mapNonNil { value in
                value <= p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .fillNil(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Date.self].map { value in
                (value ?? p.rhs) as Date?
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        }
        return dataFrame
    }
}
