//
//  File.swift
//  
//
//  Created by 戴藏龙 on 2024/1/6.
//

import Foundation
import SwiftUI
import TabularData

@available(iOS 17.0, *)
struct SummaryOperationEditView: View {
    let dataFrame: DataFrame
    let completion: (AnyReducer) -> ()

    init(reducer: SummaryReducer? = nil, dataFrame: DataFrame, completion: @escaping (AnyReducer) -> Void) {
        self.dataFrame = dataFrame
        self.completion = completion
        if let reducer {
            switch reducer {
            case .all:
                self._summaryType = .init(initialValue: .all)
                self._singleSummaryColumn = .init(initialValue: "")
            case .singleColumn(let column):
                self._summaryType = .init(initialValue: .singleColumn)
                self._singleSummaryColumn = .init(initialValue: column)
            }
        } else {
            self._summaryType = .init(initialValue: .all)
            self._singleSummaryColumn = .init(initialValue: "")
        }
    }

    enum SummaryType: String, CaseIterable, Identifiable, CustomStringConvertible {
        var id: String { self.rawValue }

        case all
        case singleColumn

        var description: String {
            switch self {
            case .all:
                "All"
            case .singleColumn:
                "A Specific Column"
            }
        }
    }

    @State var summaryType: SummaryType
    @State var singleSummaryColumn: String

    var body: some View {
        List {
            Picker("For", selection: $summaryType) {
                ForEach(SummaryType.allCases) { type in
                    Text(type.description).tag(type)
                }
            }
            .pickerStyle(.segmented)
            if case .singleColumn = summaryType {
                Picker("Column", selection: $singleSummaryColumn) {
                    ForEach(dataFrame.columns, id: \.name) { column in
                        Text(column.name)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    completion(AnyReducer.summary(builded!))
                } label: {
                    Text("Done")
                }
                .disabled(builded == nil)
            }
        }
        .navigationTitle("Summary")
    }

    var builded: SummaryReducer? {
        switch summaryType {
        case .all:
            return .all
        case .singleColumn:
            if singleSummaryColumn == "" {
                return nil
            } else {
                return .singleColumn(singleSummaryColumn)
            }
        }
    }
}
