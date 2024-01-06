//
//  File.swift
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
        case .multiColumnReducer(let multiColumnReducer):
            return try multiColumnReducer.reduce(dataFrame)
        case .singleColumnReducer(let singleColumnReducer):
            return try singleColumnReducer.reduce(dataFrame)
        }
    }
}

extension DateReducer.MultiColumnReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        var dataFrame = dataFrame
        switch self {
        case .equalTo(let p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Int?, rhs: Int?) -> Bool? in
                guard let lhs, let rhs else { return nil }
                return lhs == rhs
            }
        case .moreThan(let p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Int?, rhs: Int?) -> Bool? in
                guard let lhs, let rhs else { return nil }
                return lhs > rhs
            }
        case .lessThan(let p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Int?, rhs: Int?) -> Bool? in
                guard let lhs, let rhs else { return nil }
                return lhs < rhs
            }
        case .moreThanOrEqualTo(let p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Int?, rhs: Int?) -> Bool? in
                guard let lhs, let rhs else { return nil }
                return lhs >= rhs
            }
        case .lessThanOrEqualTo(let p):
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
        case .equalTo(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Date.self].mapNonNil { value in
                value == p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .moreThan(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Date.self].mapNonNil { value in
                value > p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .lessThan(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Date.self].mapNonNil { value in
                value < p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .moreThanOrEqualTo(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Date.self].mapNonNil { value in
                value >= p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .lessThanOrEqualTo(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Date.self].mapNonNil { value in
                value <= p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .fillNil(let p):
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
