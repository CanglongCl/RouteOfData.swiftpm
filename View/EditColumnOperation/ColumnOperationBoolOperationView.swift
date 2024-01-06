//
//  File.swift
//  
//
//  Created by 戴藏龙 on 2024/1/5.
//

import Foundation
import SwiftUI
import TabularData

@available(iOS 17.0, *)
struct ColumnOperationBoolOperationView: View {
    init(currentColumn: String, dataFrame: DataFrame, completion: @escaping (AnyReducer) -> ()) {
        self.dataFrame = dataFrame
        self._builder = .init(initialValue: .init(currentColumn: currentColumn))
        self.completion = completion
    }

    init(boolReducer: BooleanReducer, dataFrame: DataFrame, completion: @escaping (AnyReducer) -> ()) {
        self.dataFrame = dataFrame
        self._builder = .init(initialValue: .init(reducer: boolReducer))
        self.completion = completion
    }

    @State private var builder: OperationBuilder

    let dataFrame: DataFrame

    let completion: (AnyReducer) -> ()

    var body: some View {
        List {
            Section {
                Picker("Operation Type", selection: $builder.singleOrMulti) {
                    ForEach(AllColumnOperationOption.allCases) { type in
                        Text(type.description).tag(type as AllColumnOperationOption?)
                    }
                }
                .pickerStyle(.segmented)
                HStack {
                    Group {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Column")
                                .foregroundStyle(.secondary)
                            Menu {
                                let columns = dataFrame.columns.filter { column in
                                    column.wrappedElementType == Bool.self
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

                        if let singleOrMulti = builder.singleOrMulti {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Operator")
                                    .foregroundStyle(.secondary)
                                switch singleOrMulti {
                                case .single:
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
                                case .multi:
                                    Menu {
                                        ForEach(MultiColumnOperationOption.allCases) { option in
                                            Button(option.description) {
                                                builder.multiColumnOperation = option
                                            }
                                        }
                                    } label: {
                                        Text(builder.multiColumnOperation?.description ?? " ")
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
                            }
                            .padding(.horizontal)
                        }
                        if builder
                            .singleColumnOperation?
                            .hasParameter ?? false {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Parameter")
                                    .foregroundStyle(.secondary)
                                Menu {
                                    Button("True") {
                                        builder.parameter = true
                                    }
                                    Button("False") {
                                        builder.parameter = false
                                    }
                                } label: {
                                    Text(builder.parameter ? "True" : "False")
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
                        anotherColumn()
                    }
                }
            } header: {
                Text("Type: Bool")
                    .font(.headline)
            }
            if builder.singleColumnOperation != .filter {
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
        }
        .alert("Enter Parameter", isPresented: $showParameterInput) {
            TextField("Parameter", value: $builder.parameter, formatter: formatter)
                .keyboardType(.numbersAndPunctuation)
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
                    completion(AnyReducer.columnReducer(.boolean(builder.build()!)))
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
        var singleOrMulti: AllColumnOperationOption? {
            didSet {
                if singleOrMulti != oldValue {
                    singleColumnOperation = nil
                    multiColumnOperation = nil
                }
            }
        }
        var singleColumnOperation: SingleColumnOperationOption?
        var multiColumnOperation: MultiColumnOperationOption?
        var parameter: Bool = false
        var anotherColumn: String?
        var currentColumn: String
        var intoColumn: String?

        func build() -> BooleanReducer? {
            guard intoColumn != "" else { return nil }
            switch singleOrMulti {
            case .single:
                switch singleColumnOperation {
                case .fillNil:
                    return .singleColumnReducer(.fillNil(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .castInt:
                    return .singleColumnReducer(.castInt(.init(column: currentColumn, intoColumn: intoColumn ?? currentColumn)))
                case .not:
                    return .singleColumnReducer(.not(.init(column: currentColumn, intoColumn: intoColumn ?? currentColumn)))
                case .filter:
                    return .singleColumnReducer(.filter(.init(column: currentColumn, intoColumn: intoColumn ?? currentColumn)))
                case nil:
                    return nil
                }
            case .multi:
                guard let anotherColumn else { return nil }
                switch multiColumnOperation {
                case .and:
                    return .multiColumnReducer(.and(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
                case .or:
                    return .multiColumnReducer(.or(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
                case nil:
                    return nil
                }
            case nil:
                return nil
            }
        }

        init(currentColumn: String) {
            self.currentColumn = currentColumn
        }

        init(reducer: BooleanReducer) {
            switch reducer {
            case .multiColumnReducer(let reducer):
                switch reducer {
                case .and(let p):
                    currentColumn = p.lhsColumn
                    anotherColumn = p.rhsColumn
                    singleOrMulti = .multi
                    multiColumnOperation = .and
                    if p.intoColumn == p.lhsColumn || p.intoColumn == p.rhsColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case .or(let p):
                    currentColumn = p.lhsColumn
                    anotherColumn = p.rhsColumn
                    singleOrMulti = .multi
                    multiColumnOperation = .or
                    if p.intoColumn == p.lhsColumn || p.intoColumn == p.rhsColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                }
            case .singleColumnReducer(let reducer):
                switch reducer {
                case .castInt(let p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .castInt
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case .filter(let p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .filter
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case .not(let p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .not
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case .fillNil(let p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .fillNil
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

    @ViewBuilder
    func anotherColumn() -> some View {
        if let singleOrMulti = builder.singleOrMulti,
            case .multi = singleOrMulti {
            VStack(alignment: .leading, spacing: 2) {
                Text("Another Column")
                    .foregroundStyle(.secondary)
                Menu {
                    let columns = dataFrame.columns.filter { column in
                        column.wrappedElementType == Bool.self
                    }
                    ForEach(columns, id: \.name) { column in
                        Button(column.name) {
                            builder.anotherColumn = column.name
                        }
                    }
                } label: {
                    Text(builder.anotherColumn?.uppercased() ?? " ")
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

    enum AllColumnOperationOption: String, CustomStringConvertible, CaseIterable, Identifiable {
        var id: String { self.rawValue }
        var description: String {
            switch self {
            case .single:
                "Single Column"
            case .multi:
                "Multi Columns"
            }
        }

        case single
        case multi
    }

    enum SingleColumnOperationOption: String, CustomStringConvertible, CaseIterable, Identifiable {
        var id: String { self.rawValue }

        var description: String {
            switch self {
            case .not:
                "Not"
            case .castInt:
                "Cast to Int"
            case .filter:
                "Filter if TRUE"
            case .fillNil:
                "Fill Nil with"
            }
        }

        case not
        case fillNil
        case castInt
        case filter

        var hasParameter: Bool {
            switch self {
            case .not, .castInt, .filter:
                false
            case .fillNil:
                true
            }
        }
    }

    enum MultiColumnOperationOption: String, CustomStringConvertible, CaseIterable, Identifiable {
        var id: String { self.rawValue }

        var description: String {
            switch self {
            case .and:
                "And"
            case .or:
                "Or"
            }
        }

        case and
        case or
    }
}

#Preview(body: {
    if #available(iOS 17.0, *) {
        NavigationStack {
            ColumnOperationBoolOperationView(currentColumn: "value", dataFrame: try! DataFrame(contentsOfCSVFile: Bundle.main.url(forResource: "air_quality_no2_long", withExtension: "csv")!), completion: {_ in })
        }
    } else {
        EmptyView()
    }
})
