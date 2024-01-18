//
//  StringReducer.swift
//
//
//  Created by 戴藏龙 on 2024/1/4.
//

import Foundation
import TabularData

enum StringReducer: Codable {
    case singleColumnReducer(SingleColumnReducer)

    enum SingleColumnReducer: Codable {
        case tryCastInt(SingleColumnReducerParameter<String>)
        case tryCastDouble(SingleColumnReducerParameter<String>)
        case fillNil(SingleColumnWithParameterReducerParameter<String>)
        case tryCastDate(SingleColumnWithParameterReducerParameter<String>)
        case equalTo(SingleColumnWithParameterReducerParameter<String>)
    }
}

extension StringReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        switch self {
        case let .singleColumnReducer(singleColumnReducer):
            return try singleColumnReducer.reduce(dataFrame)
        }
    }
}

extension StringReducer.SingleColumnReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        var dataFrame = dataFrame
        switch self {
        case let .tryCastInt(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, String.self].mapNonNil { value in
                Int(value)
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .tryCastDouble(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, String.self].mapNonNil { value in
                Double(value)
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .fillNil(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, String.self].map { value in
                (value ?? p.rhs) as String?
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .tryCastDate(p):
            try p.validate(dataFrame: dataFrame)
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = p.rhs
            var column = dataFrame[p.column, String.self].map { value in
                guard let value else { return nil as Date? }
                return dateFormatter.date(from: value)
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        case let .equalTo(p):
            try p.validate(dataFrame: dataFrame)
            var column = dataFrame[p.column, String.self].map { value in
                (value == p.rhs) as Bool?
            }
            column.name = p.intoColumn
            dataFrame.insertOrReplaceIfExists(column)
        }
        return dataFrame
    }
}
