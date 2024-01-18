//
//  Utility.swift
//  Helm of Data
//
//  Created by 戴藏龙 on 2024/1/3.
//

import Foundation
import TabularData

extension DataFrame.Rows: RandomAccessCollection {}

extension DataFrame {
    mutating func insertOrReplaceIfExists<T>(_ column: Column<T>) {
        if columns.map(\.name).contains(column.name) {
            replaceColumn(column.name, with: column)
        } else {
            append(column: column)
        }
    }
}
