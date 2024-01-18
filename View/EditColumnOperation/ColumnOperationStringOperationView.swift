//
//  ColumnOperationStringOperationView.swift
//
//
//  Created by 戴藏龙 on 2024/1/5.
//

import Foundation
import SwiftUI
import TabularData

@available(iOS 17.0, *)
struct ColumnOperationStringOperationView: View {
    init(currentColumn: String, dataFrame: DataFrame, completion: @escaping (AnyReducer) -> Void) {
        self.dataFrame = dataFrame
        _builder = .init(initialValue: .init(currentColumn: currentColumn))
        self.completion = completion
    }

    init(stringReducer: StringReducer, dataFrame: DataFrame, completion: @escaping (AnyReducer) -> Void) {
        self.dataFrame = dataFrame
        _builder = .init(initialValue: .init(reducer: stringReducer))
        self.completion = completion
    }

    @State private var builder: OperationBuilder

    let dataFrame: DataFrame

    let completion: (AnyReducer) -> Void

    var body: some View {
        List {
            Section {
                HStack {
                    Group {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Column")
                                .foregroundStyle(.secondary)
                            Menu {
                                let columns = dataFrame.columns.filter { column in
                                    column.wrappedElementType == String.self
                                }
                                ForEach(columns, id: \.name) { column in
                                    Button(column.name) {
                                        builder.currentColumn = column.name
                                    }
                                }
                            } label: {
                                Text(builder.currentColumn.uppercased())
                                    .font(.title2)
                                    .bold()
                                    .padding()
                                    .background {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.quinary)
                                            .foregroundStyle(.quaternary)
                                    }
                            }
                        }
                        .padding(.trailing)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Operator")
                                .foregroundStyle(.secondary)
                            Menu {
                                ForEach(SingleColumnOperationOption.allCases) { option in
                                    Button(option.description) {
                                        builder.singleColumnOperation = option
                                    }
                                }
                            } label: {
                                Text(builder.singleColumnOperation?.description ?? " ")
                                    .font(.title2)
                                    .bold()
                                    .padding()
                                    .background {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.quinary)
                                            .foregroundStyle(.quaternary)
                                    }
                            }
                        }
                        .padding(.horizontal)
                        if builder
                            .singleColumnOperation?
                            .hasParameter ?? false
                        {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Parameter")
                                    .foregroundStyle(.secondary)
                                Button {
                                    showParameterInput.toggle()
                                } label: {
                                    Text("\(builder.parameter != "" ? builder.parameter : "(Empty String)")")
                                        .font(.title2)
                                        .bold()
                                        .padding()
                                        .background {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(.quinary)
                                                .foregroundStyle(.quaternary)
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            } header: {
                Text("Type: String")
                    .font(.headline)
            }
            Section {
                Toggle(isOn: intoNewColumn) {
                    Text("Into New Column")
                }
                if let newColumnName = builder.intoColumn {
                    HStack {
                        Text("New Column Name")
                        Spacer()
                        Button {
                            showNewColumnNameInput.toggle()
                        } label: {
                            if newColumnName == "" {
                                Text("Click to Enter New Column Name")
                            } else {
                                Text(newColumnName)
                            }
                        }
                    }
                }
            }
        }
        .alert("Enter Parameter", isPresented: $showParameterInput) {
            TextField("Parameter", text: $builder.parameter)
        }
        .alert("Enter New Column Name", isPresented: $showNewColumnNameInput) {
            let bindingString: Binding<String>? = if let newColumn = builder.intoColumn {
                Binding {
                    newColumn
                } set: { newValue in
                    builder.intoColumn = newValue
                }
            } else {
                nil
            }
            if let bindingString {
                TextField("New Column Name", text: bindingString)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    completion(AnyReducer.columnReducer(.string(builder.build()!)))
                } label: {
                    Text("Done")
                }
                .disabled(builder.build() == nil)
            }
        }
        .navigationTitle("Column Operation")
    }

    @State private var showNewColumnNameInput: Bool = false

    var intoNewColumn: Binding<Bool> {
        .init(get: {
            builder.intoColumn != nil
        }, set: { newValue in
            if newValue {
                builder.intoColumn = ""
            } else {
                builder.intoColumn = nil
            }
        })
    }

    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    @State private var showParameterInput: Bool = false

    @Observable
    class OperationBuilder {
        var singleColumnOperation: SingleColumnOperationOption?
        var parameter: String = ""
        var currentColumn: String
        var intoColumn: String?

        func build() -> StringReducer? {
            guard intoColumn != "" else { return nil }
            switch singleColumnOperation {
            case .fillNil:
                return .singleColumnReducer(.fillNil(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
            case .tryCastInt:
                return .singleColumnReducer(.tryCastInt(.init(column: currentColumn, intoColumn: intoColumn ?? currentColumn)))
            case .tryCastDouble:
                return .singleColumnReducer(.tryCastDouble(.init(column: currentColumn, intoColumn: intoColumn ?? currentColumn)))
            case .tryCastDate:
                return .singleColumnReducer(.tryCastDate(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
            case .equalTo:
                return .singleColumnReducer(.equalTo(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
            case nil:
                return nil
            }
        }

        init(currentColumn: String) {
            self.currentColumn = currentColumn
        }

        init(reducer: StringReducer) {
            switch reducer {
            case let .singleColumnReducer(reducer):
                switch reducer {
                case let .fillNil(p):
                    currentColumn = p.column
                    singleColumnOperation = .fillNil
                    parameter = p.rhs
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .tryCastDate(p):
                    currentColumn = p.column
                    singleColumnOperation = .tryCastDate
                    parameter = p.rhs
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .tryCastInt(p):
                    currentColumn = p.column
                    singleColumnOperation = .tryCastInt
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .tryCastDouble(p):
                    currentColumn = p.column
                    singleColumnOperation = .tryCastDouble
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .equalTo(p):
                    currentColumn = p.column
                    singleColumnOperation = .equalTo
                    parameter = p.rhs
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                }
            }
        }
    }

    enum SingleColumnOperationOption: String, CustomStringConvertible, CaseIterable, Identifiable {
        var id: String { rawValue }

        var description: String {
            switch self {
            case .fillNil:
                "Fill Nil with"
            case .tryCastInt:
                "Try Cast to Int"
            case .tryCastDouble:
                "Try Cast to Double"
            case .tryCastDate:
                "Cast to Date with format"
            case .equalTo:
                "="
            }
        }

        case fillNil
        case tryCastInt
        case tryCastDouble
        case tryCastDate
        case equalTo

        var hasParameter: Bool {
            switch self {
            case .fillNil, .tryCastDate, .equalTo:
                true
            case .tryCastInt, .tryCastDouble:
                false
            }
        }
    }
}

#Preview(body: {
    if #available(iOS 17.0, *) {
        NavigationStack {
            ColumnOperationStringOperationView(currentColumn: "value", dataFrame: try! DataFrame(contentsOfCSVFile: Bundle.main.url(forResource: "air_quality_no2_long", withExtension: "csv")!), completion: { _ in })
        }
    } else {
        EmptyView()
    }
})
