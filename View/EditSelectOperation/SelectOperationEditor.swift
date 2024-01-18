//
//  SelectOperationEditor.swift
//
//
//  Created by 戴藏龙 on 2024/1/6.
//

import Foundation
import SwiftUI
import TabularData

@available(iOS 17.0, *)
struct SelectOperationEditView: View {
    let dataFrame: DataFrame
    let completion: (AnyReducer) -> Void

    init(reducer: SelectReducer? = nil, dataFrame: DataFrame, completion: @escaping (AnyReducer) -> Void) {
        self.dataFrame = dataFrame
        self.completion = completion
        if let reducer {
            switch reducer {
            case let .include(columns):
                _selectType = .init(initialValue: .include)
                _columns = .init(initialValue: columns)
            case let .exclude(columns):
                _selectType = .init(initialValue: .exclude)
                _columns = .init(initialValue: columns)
            }
        } else {
            _selectType = .init(initialValue: .include)
            _columns = .init(initialValue: [])
        }
    }

    enum SelectType: String, CaseIterable, Identifiable, CustomStringConvertible {
        var id: String { rawValue }

        case include
        case exclude

        var description: String {
            switch self {
            case .include:
                "Include"
            case .exclude:
                "Exclude"
            }
        }
    }

    @State var selectType: SelectType
    @State var columns: [String]

    var body: some View {
        List {
            Picker("Select Type", selection: $selectType) {
                ForEach(SelectType.allCases) { type in
                    Text(type.description).tag(type)
                }
            }
            .pickerStyle(.segmented)
            ForEach(dataFrame.columns, id: \.name) { column in
                let isSelected: Bool = columns.contains(column.name)
                Button {
                    if isSelected {
                        columns.removeAll { col in
                            col == column.name
                        }
                    } else {
                        columns.append(column.name)
                    }
                } label: {
                    Label {
                        Text(column.name)
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "checkmark.circle")
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    completion(AnyReducer.selectReducer(builded!))
                } label: {
                    Text("Done")
                }
                .disabled(builded == nil)
            }
        }
        .navigationTitle("Summary")
    }

    var builded: SelectReducer? {
        guard !columns.isEmpty else { return nil }
        switch selectType {
        case .include:
            return .include(columns)
        case .exclude:
            return .exclude(columns)
        }
    }
}
