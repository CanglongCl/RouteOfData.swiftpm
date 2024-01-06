//
//  File.swift
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
        case .multiColumnReducer(let multiColumnReducer):
            return try multiColumnReducer.reduce(dataFrame)
        case .singleColumnReducer(let singleColumnReducer):
            return try singleColumnReducer.reduce(dataFrame)
        }
    }
}

extension IntegerReducer.MultiColumnReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        var dataFrame = dataFrame
        switch self {
        case .add(let p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Int?, rhs: Int?) -> Int? in
                guard let lhs, let rhs else { return nil }
                return lhs + rhs
            }
        case .subtract(let p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Int?, rhs: Int?) -> Int? in
                guard let lhs, let rhs else { return nil }
                return lhs - rhs
            }
        case .multiply(let p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Int?, rhs: Int?) -> Int? in
                guard let lhs, let rhs else { return nil }
                return lhs * rhs
            }
        case .dividedBy(let p):
            try p.validate(dataFrame: dataFrame)
            dataFrame.combineColumns(p.lhsColumn, p.rhsColumn, into: p.intoColumn) { (lhs: Int?, rhs: Int?) -> Double? in
                guard let lhs, let rhs else { return nil }
                return Double(lhs) + Double(rhs)
            }
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

extension IntegerReducer.SingleColumnReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        var dataFrame = dataFrame
        switch self {
        case .add(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                value + p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .subtract(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                value - p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .multiply(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                value * p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .dividedBy(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                Double(value) / Double(p.rhs)
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .equalTo(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                value == p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .moreThan(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                value > p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .lessThan(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                value < p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .moreThanOrEqualTo(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                value >= p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .lessThanOrEqualTo(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                value <= p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .castDouble(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                Double(value)
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .castString(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Int.self].mapNonNil { value in
                String(value)
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .percentage(let p):
            try p.validate(dataFrame: dataFrame)
            let column = dataFrame[p.column, Int.self]
            let sum = column.sum()
            var newColumn = column.mapNonNil { (value: Int) -> Double in
                Double(value) / Double(sum)
            }
            newColumn.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(newColumn)
        case .fillNil(let p):
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


