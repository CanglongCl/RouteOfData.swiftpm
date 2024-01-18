//
//  IntegerReducer.swift
//
//
//  Created by 戴藏龙 on 2024/1/4.
//

import Foundation
import TabularData

enum IntegerReducer: Codable {
    case multiColumnReducer(MultiColumnReducer)
    case singleColumnReducer(SingleColumnReducer)

    enum MultiColumnReducer: Codable {
        case add(MultiColumnReducerParameter<Int>)
        case subtract(MultiColumnReducerParameter<Int>)
        case multiply(MultiColumnReducerParameter<Int>)
        case dividedBy(MultiColumnReducerParameter<Int>)
        case equalTo(MultiColumnReducerParameter<Int>)
        case moreThan(MultiColumnReducerParameter<Int>)
        case lessThan(MultiColumnReducerParameter<Int>)
        case moreThanOrEqualTo(MultiColumnReducerParameter<Int>)
        case lessThanOrEqualTo(MultiColumnReducerParameter<Int>)
    }

    enum SingleColumnReducer: Codable {
        case add(SingleColumnWithParameterReducerParameter<Int>)
        case subtract(SingleColumnWithParameterReducerParameter<Int>)
        case multiply(SingleColumnWithParameterReducerParameter<Int>)
        case dividedBy(SingleColumnWithParameterReducerParameter<Int>)
        case equalTo(SingleColumnWithParameterReducerParameter<Int>)
        case moreThan(SingleColumnWithParameterReducerParameter<Int>)
        case lessThan(SingleColumnWithParameterReducerParameter<Int>)
        case moreThanOrEqualTo(SingleColumnWithParameterReducerParameter<Int>)
        case lessThanOrEqualTo(SingleColumnWithParameterReducerParameter<Int>)
        case castDouble(SingleColumnReducerParameter<Int>)
        case castString(SingleColumnReducerParameter<Int>)
        case percentage(SingleColumnReducerParameter<Int>)
        case fillNil(SingleColumnWithParameterReducerParameter<Int>)
    }
}

extension IntegerReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        switch self {
        case let .multiColumnReducer(multiColumnReducer):
            return try multiColumnReducer.reduce(dataFrame)
        case let .singleColumnReducer(singleColumnReducer):
            return try singleColumnReducer.reduce(dataFrame)
        }
    }
}

extension IntegerReducer.MultiColumnReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        var dataFrame = dataFrame
        switch self {
        case let .add(p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Int?, rhs: Int?) -> Int? in
                guard let lhs, let rhs else { return nil }
                return lhs + rhs
            }
        case let .subtract(p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Int?, rhs: Int?) -> Int? in
                guard let lhs, let rhs else { return nil }
                return lhs - rhs
            }
        case let .multiply(p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Int?, rhs: Int?) -> Int? in
                guard let lhs, let rhs else { return nil }
                return lhs * rhs
            }
        case let .dividedBy(p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Int?, rhs: Int?) -> Double? in
                guard let lhs, let rhs else { return nil }
                return Double(lhs) + Double(rhs)
            }
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

extension IntegerReducer.SingleColumnReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        var dataFrame = dataFrame
        switch self {
        case let .add(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                value + p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .subtract(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                value - p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .multiply(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                value * p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .dividedBy(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                Double(value) / Double(p.rhs)
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .equalTo(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                value == p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .moreThan(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                value > p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .lessThan(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                value < p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .moreThanOrEqualTo(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                value >= p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .lessThanOrEqualTo(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                value <= p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .castDouble(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                Double(value)
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .castString(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                String(value)
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .percentage(p):
            try p.validate(dataFrame: dataFrame)
            let column = dataFrame[p.column, Int.self]
            let sum = column.sum()
            var newColumn = column.mapNonNil { (value: Int) -> Double in
                Double(value) / Double(sum)
            }
            newColumn.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(newColumn)
        case let .fillNil(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].map { value in
                (value ?? p.rhs) as Int?
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        }
        return dataFrame
    }
}
