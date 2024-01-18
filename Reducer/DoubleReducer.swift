//
//  DoubleReducer.swift
//
//
//  Created by 戴藏龙 on 2024/1/4.
//

import Foundation
import TabularData

enum DoubleReducer: Codable {
    case multiColumnReducer(MultiColumnReducer)
    case singleColumnReducer(SingleColumnReducer)

    enum MultiColumnReducer: Codable {
        case add(MultiColumnReducerParameter<Double>)
        case subtract(MultiColumnReducerParameter<Double>)
        case multiply(MultiColumnReducerParameter<Double>)
        case dividedBy(MultiColumnReducerParameter<Double>)
        case equalTo(MultiColumnReducerParameter<Double>)
        case moreThan(MultiColumnReducerParameter<Double>)
        case lessThan(MultiColumnReducerParameter<Double>)
        case moreThanOrEqualTo(MultiColumnReducerParameter<Double>)
        case lessThanOrEqualTo(MultiColumnReducerParameter<Double>)
    }

    enum SingleColumnReducer: Codable {
        case add(SingleColumnWithParameterReducerParameter<Double>)
        case subtract(SingleColumnWithParameterReducerParameter<Double>)
        case multiply(SingleColumnWithParameterReducerParameter<Double>)
        case dividedBy(SingleColumnWithParameterReducerParameter<Double>)
        case equalTo(SingleColumnWithParameterReducerParameter<Double>)
        case moreThan(SingleColumnWithParameterReducerParameter<Double>)
        case lessThan(SingleColumnWithParameterReducerParameter<Double>)
        case moreThanOrEqualTo(SingleColumnWithParameterReducerParameter<Double>)
        case lessThanOrEqualTo(SingleColumnWithParameterReducerParameter<Double>)
        case castIntFloor(SingleColumnReducerParameter<Double>)
        case castIntCeil(SingleColumnReducerParameter<Double>)
        case castString(SingleColumnReducerParameter<Double>)
        case fillNil(SingleColumnWithParameterReducerParameter<Double>)
        case percentage(SingleColumnReducerParameter<Double>)
    }
}

extension DoubleReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        switch self {
        case let .multiColumnReducer(multiColumnReducer):
            return try multiColumnReducer.reduce(dataFrame)
        case let .singleColumnReducer(singleColumnReducer):
            return try singleColumnReducer.reduce(dataFrame)
        }
    }
}

extension DoubleReducer.MultiColumnReducer: ReducerProtocol {
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

extension DoubleReducer.SingleColumnReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        var dataFrame = dataFrame
        switch self {
        case let .add(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                value + p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .subtract(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                value - p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .multiply(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                value * p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .dividedBy(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                Double(value) / Double(p.rhs)
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .equalTo(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                value == p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .moreThan(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                value > p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .lessThan(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                value < p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .moreThanOrEqualTo(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                value >= p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .lessThanOrEqualTo(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                value <= p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .castString(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                String(value)
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .percentage(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self]
            let sum = column.sum()
            var newColumn = column.mapNonNil { (value: Double) -> Double in
                Double(value) / Double(sum)
            }
            newColumn.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(newColumn)
        case let .fillNil(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].map { value in
                (value ?? p.rhs) as Double?
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .castIntFloor(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                Int(floor(value))
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .castIntCeil(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                Int(ceil(value))
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        }
        return dataFrame
    }
}
