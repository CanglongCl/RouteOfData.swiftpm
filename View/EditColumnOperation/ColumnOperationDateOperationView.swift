//
//  ColumnOperationDateOperationView.swift
//
//
//  Created by 戴藏龙 on 2024/1/5.
//

import Foundation
import SwiftUI
import TabularData

@available(iOS 17.0, *)
struct ColumnOperationDateOperationView: View {
    init(currentColumn: String, dataFrame: DataFrame, completion: @escaping (AnyReducer) -> Void) {
        self.dataFrame = dataFrame
        _builder = .init(initialValue: .init(currentColumn: currentColumn))
        self.completion = completion
    }

    init(dateReducer: DateReducer, dataFrame: DataFrame, completion: @escaping (AnyReducer) -> Void) {
        self.dataFrame = dataFrame
        _builder = .init(initialValue: .init(reducer: dateReducer))
        self.completion = completion
    }

    @State private var builder: OperationBuilder

    let dataFrame: DataFrame

    let completion: (AnyReducer) -> Void

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
                                    column.wrappedElementType == Date.self
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
                            .hasParameter ?? false
                        {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Parameter")
                                    .foregroundStyle(.secondary)
                                Button {
                                    popDatePicker.toggle()
                                } label: {
                                    Text(builder.parameter.formatted(date: .numeric, time: .standard))
                                        .font(.title2)
                                        .bold()
                                        .padding()
                                        .background {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(.quinary)
                                                .foregroundStyle(.quaternary)
                                        }
                                }
                                .popover(isPresented: $popDatePicker) {
                                    DatePicker(selection: $builder.parameter) {
                                        EmptyView()
                                    }
                                    .datePickerStyle(.graphical)
                                    .frame(width: 500, height: 500)
                                }
                            }
                            .padding(.horizontal)
                        }
                        anotherColumn()
                    }
                }
            } header: {
                Text("Type: Date")
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
                    completion(AnyReducer.columnReducer(.date(builder.build()!)))
                } label: {
                    Text("Done")
                }
                .disabled(builder.build() == nil)
            }
        }
        .navigationTitle("Column Operation")
    }

    @State private var popDatePicker: Bool = false
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
        var parameter: Date = .now
        var anotherColumn: String?
        var currentColumn: String
        var intoColumn: String?

        func build() -> DateReducer? {
            guard intoColumn != "" else { return nil }
            switch singleOrMulti {
            case .single:
                switch singleColumnOperation {
                case .equalTo:
                    return .singleColumnReducer(.equalTo(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .moreThan:
                    return .singleColumnReducer(.moreThan(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .lessThan:
                    return .singleColumnReducer(.lessThan(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .moreThanOrEqualTo:
                    return .singleColumnReducer(.moreThanOrEqualTo(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .lessThanOrEqualTo:
                    return .singleColumnReducer(.lessThanOrEqualTo(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .fillNil:
                    return .singleColumnReducer(.fillNil(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case nil:
                    return nil
                }
            case .multi:
                guard let anotherColumn else { return nil }
                switch multiColumnOperation {
                case .equalTo:
                    return .multiColumnReducer(.equalTo(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
                case .moreThan:
                    return .multiColumnReducer(.moreThan(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
                case .lessThan:
                    return .multiColumnReducer(.lessThan(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
                case .moreThanOrEqualTo:
                    return .multiColumnReducer(.moreThanOrEqualTo(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
                case .lessThanOrEqualTo:
                    return .multiColumnReducer(.lessThanOrEqualTo(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
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

        init(reducer: DateReducer) {
            switch reducer {
            case let .multiColumnReducer(reducer):
                switch reducer {
                case let .equalTo(p):
                    currentColumn = p.lhsColumn
                    anotherColumn = p.rhsColumn
                    singleOrMulti = .multi
                    multiColumnOperation = .equalTo
                    if p.intoColumn == p.lhsColumn || p.intoColumn == p.rhsColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .moreThan(p):
                    currentColumn = p.lhsColumn
                    anotherColumn = p.rhsColumn
                    singleOrMulti = .multi
                    multiColumnOperation = .moreThan
                    if p.intoColumn == p.lhsColumn || p.intoColumn == p.rhsColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .lessThan(p):
                    currentColumn = p.lhsColumn
                    anotherColumn = p.rhsColumn
                    singleOrMulti = .multi
                    multiColumnOperation = .lessThan
                    if p.intoColumn == p.lhsColumn || p.intoColumn == p.rhsColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .moreThanOrEqualTo(p):
                    currentColumn = p.lhsColumn
                    anotherColumn = p.rhsColumn
                    singleOrMulti = .multi
                    multiColumnOperation = .moreThanOrEqualTo
                    if p.intoColumn == p.lhsColumn || p.intoColumn == p.rhsColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .lessThanOrEqualTo(p):
                    currentColumn = p.lhsColumn
                    anotherColumn = p.rhsColumn
                    singleOrMulti = .multi
                    multiColumnOperation = .lessThanOrEqualTo
                    if p.intoColumn == p.lhsColumn || p.intoColumn == p.rhsColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                }
            case let .singleColumnReducer(reducer):
                switch reducer {
                case let .equalTo(p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .equalTo
                    parameter = p.rhs
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .moreThan(p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .moreThan
                    parameter = p.rhs
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .lessThan(p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .lessThan
                    parameter = p.rhs
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .moreThanOrEqualTo(p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .moreThanOrEqualTo
                    parameter = p.rhs
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .lessThanOrEqualTo(p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .lessThanOrEqualTo
                    parameter = p.rhs
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .fillNil(p):
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
           case .multi = singleOrMulti
        {
            VStack(alignment: .leading, spacing: 2) {
                Text("Another Column")
                    .foregroundStyle(.secondary)
                Menu {
                    let columns = dataFrame.columns.filter { column in
                        column.wrappedElementType == Date.self
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
        var id: String { rawValue }
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
        var id: String { rawValue }

        var description: String {
            switch self {
            case .equalTo:
                "="
            case .moreThan:
                ">"
            case .lessThan:
                "<"
            case .moreThanOrEqualTo:
                ">="
            case .lessThanOrEqualTo:
                "<="
            case .fillNil:
                "Fill Nil with"
            }
        }

        case equalTo
        case moreThan
        case lessThan
        case moreThanOrEqualTo
        case lessThanOrEqualTo
        case fillNil

        var hasParameter: Bool {
            true
        }
    }

    enum MultiColumnOperationOption: String, CustomStringConvertible, CaseIterable, Identifiable {
        var id: String { rawValue }

        var description: String {
            switch self {
            case .equalTo:
                "="
            case .moreThan:
                ">"
            case .lessThan:
                "<"
            case .moreThanOrEqualTo:
                ">="
            case .lessThanOrEqualTo:
                "<="
            }
        }

        case equalTo
        case moreThan
        case lessThan
        case moreThanOrEqualTo
        case lessThanOrEqualTo
    }
}

#Preview(body: {
    if #available(iOS 17.0, *) {
        NavigationStack {
            ColumnOperationDateOperationView(currentColumn: "value", dataFrame: try! DataFrame(contentsOfCSVFile: Bundle.main.url(forResource: "air_quality_no2_long", withExtension: "csv")!), completion: { _ in })
        }
    } else {
        EmptyView()
    }
})
