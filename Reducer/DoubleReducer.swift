//
//  File.swift
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
        case .multiColumnReducer(let multiColumnReducer):
            return try multiColumnReducer.reduce(dataFrame)
        case .singleColumnReducer(let singleColumnReducer):
            return try singleColumnReducer.reduce(dataFrame)
        }
    }
}

extension DoubleReducer.MultiColumnReducer: ReducerProtocol {
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

extension DoubleReducer.SingleColumnReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        var dataFrame = dataFrame
        switch self {
        case .add(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                value + p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .subtract(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                value - p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .multiply(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                value * p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .dividedBy(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                Double(value) / Double(p.rhs)
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .equalTo(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                value == p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .moreThan(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                value > p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .lessThan(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                value < p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .moreThanOrEqualTo(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                value >= p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .lessThanOrEqualTo(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                value <= p.rhs
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .castString(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                String(value)
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .percentage(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self]
            let sum = column.sum()
            var newColumn = column.mapNonNil { (value: Double) -> Double in
                Double(value) / Double(sum)
            }
            newColumn.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(newColumn)
        case .fillNil(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].map { value in
                (value ?? p.rhs) as Double?
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .castIntFloor(let p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, Double.self].mapNonNil { value in
                Int(floor(value))
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case .castIntCeil(let p):
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

