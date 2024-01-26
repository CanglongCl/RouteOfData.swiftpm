//
//  File.swift
//  
//
//  Created by 戴藏龙 on 2024/1/25.
//

import Foundation

extension ReducerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .typeUnavailable(columnName: let columnName, columnType: let columnType, reducerType: let reducerType):
            "COLUMN \(columnName)'s TYPE \(String(describing: columnType)) is not match the REQUIRED TYPE \(String(describing: reducerType))"
        case .columnNotFound(columnName: let columnName):
            "COLUMN \(columnName) not found in data frame. "
        case .columnsNotFound(columnNames: let columnNames):
            "COLUMN \(columnNames.formatted()) not found in data frame. "
        }
    }
}
