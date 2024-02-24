//
//  ReducerError+LocalizedError.swift
//
//
//  Created by 戴藏龙 on 2024/1/25.
//

import Foundation

extension ReducerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .typeUnavailable(columnName: columnName, columnType: columnType, reducerType: reducerType):
            "COLUMN \(columnName)'s TYPE \(String(describing: columnType)) is not match the REQUIRED TYPE \(String(describing: reducerType))"
        case let .columnNotFound(columnName: columnName):
            "COLUMN \(columnName) not found in data frame. "
        case let .columnsNotFound(columnNames: columnNames):
            "COLUMN \(columnNames.map { "**`\($0)`**" }.formatted()) not found in data frame. "
        }
    }
}
