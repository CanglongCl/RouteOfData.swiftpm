//
//  HeaderReducer.swift
//
//
//  Created by 戴藏龙 on 2024/1/5.
//

import Foundation
import TabularData

enum SelectReducer: ReducerProtocol {
    func reduce(_ dataFrame: DataFrame) throws -> DataFrame {
        var dataFrame = dataFrame
        let currentColumns = dataFrame.columns.map(\.name)
        switch self {
        case let .include(columnsToReduce):
            let columnNotFound = columnsToReduce.filter { columnToSelect in
                !currentColumns.contains(columnToSelect)
            }
            guard columnNotFound.isEmpty else {
                throw ReducerError.columnsNotFound(columnNames: columnNotFound)
            }
            dataFrame = DataFrame(columns: dataFrame.columns.filter { column in
                columnsToReduce.contains(column.name)
            })
        case let .exclude(columnsToReduce):
            let columnNotFound = columnsToReduce.filter { columnToSelect in
                !currentColumns.contains(columnToSelect)
            }
            guard columnNotFound.isEmpty else {
                throw ReducerError.columnsNotFound(columnNames: columnNotFound)
            }
            dataFrame = DataFrame(columns: dataFrame.columns.filter { column in
                !columnsToReduce.contains(column.name)
            })
        }
        return dataFrame
    }

    case include([String])
    case exclude([String])
}
