//
//  DataFrameTableView.swift
//  Helm of Data
//
//  Created by 戴藏龙 on 2024/1/3.
//

import SwiftUI
import TabularData

@available(iOS 17, *)
struct DataFrameTableView: View {
    let dataSet: DataFrame

    @State var numberOfRowToDisplay = 20

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            let gridColumns = dataSet
                .columns
                .map { _ in
                    GridItem(.flexible(minimum: 130, maximum: 150), spacing: 0)
                }
            LazyVGrid(
                columns: gridColumns
            ) {
                let columnNames = dataSet.columns.map(\.name)
                ForEach(dataSet.columns, id: \.name) { column in
                    ColumnNameDisplayView(columnName: column.name, typeName: String(describing: column.wrappedElementType.self))
                        .id("ColumnName: \(column.name)")
                }
                ForEach(columnNames, id: \.self) { columnName in
                    Divider()
                        .id("ColumnNameDivider: \(columnName)")
                }
                ForEach(
                    dataSet.rows,
                    id: \.index
                ) { row in
                    ForEach(columnNames, id: \.self) { columnName in
                        let value = row[columnName]
                        Group {
                            if let value = value as? CustomStringConvertible {
                                ValueDisplayView(value: value)
                            } else {
                                Text("")
                            }
                        }
                        .id("Row\(row.index)Column\(columnName)")
                    }
                    ForEach(columnNames, id: \.self) { columnName in
                        Divider()
                            .id("DividerRow\(row.index)Column\(columnName)")
                    }
                }
            }
        }
    }
}

private struct ValueDisplayView: View {
    let value: CustomStringConvertible
    @State private var fullValuePopover: Bool = false

    var body: some View {
        Text(value.description)
            .lineLimit(1)
            .onTapGesture {
                fullValuePopover = true
            }
            .popover(isPresented: $fullValuePopover, content: {
                Text(value.description)
                    .padding(.horizontal)
            })
            .padding(.horizontal, 10)
    }
}

private struct ColumnNameDisplayView: View {
    let columnName: String
    let typeName: String
    @State private var fullValuePopover: Bool = false

    var body: some View {
        VStack {
            Text(columnName)
                .lineLimit(1)
                .font(.headline)
                .textCase(.uppercase)
            Text(typeName)
                .font(.caption2)
        }
        .onTapGesture {
            fullValuePopover = true
        }
        .popover(isPresented: $fullValuePopover, content: {
            VStack {
                Text(columnName)
                    .lineLimit(1)
                    .font(.headline)
                    .textCase(.uppercase)
                Text("Type: \(typeName)")
                    .font(.footnote)
            }
            .padding(.horizontal)

        })
        .padding(.horizontal, 10)
    }
}
