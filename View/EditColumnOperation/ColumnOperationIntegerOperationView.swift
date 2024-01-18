//
//  ColumnOperationIntegerOperationView.swift
//
//
//  Created by 戴藏龙 on 2024/1/5.
//

import Foundation
import SwiftUI
import TabularData

@available(iOS 17.0, *)
struct ColumnOperationIntegerOperationView: View {
    init(currentColumn: String, dataFrame: DataFrame, completion: @escaping (AnyReducer) -> Void) {
        self.dataFrame = dataFrame
        _builder = .init(initialValue: .init(currentColumn: currentColumn))
        self.completion = completion
    }

    init(integerReducer: IntegerReducer, dataFrame: DataFrame, completion: @escaping (AnyReducer) -> Void) {
        self.dataFrame = dataFrame
        _builder = .init(initialValue: .init(reducer: integerReducer))
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
                                let integerColumns = dataFrame.columns.filter { column in
                                    column.wrappedElementType == Int.self
                                }
                                ForEach(integerColumns, id: \.name) { column in
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
                                    showParameterInput.toggle()
                                } label: {
                                    Text("\(builder.parameter)")
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
                Text("Type: Int")
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
        .alert("Input Parameter", isPresented: $showParameterInput) {
            TextField("Parameter", value: $builder.parameter, formatter: NumberFormatter())
                .keyboardType(.numberPad)
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
                    completion(AnyReducer.columnReducer(.integer(builder.build()!)))
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

    @State private var showParameterInput: Bool = false

    @Observable
    class OperationBuilder {
        var singleOrMulti: AllColumnOperationOption? {
            didSet {
                if singleOrMulti != oldValue {
                    singleColumnOperation = nil
                    multiColumnOperation = nil
                    parameter = 0
                }
            }
        }

        var singleColumnOperation: SingleColumnOperationOption?
        var multiColumnOperation: MultiColumnOperationOption?
        var parameter: Int = 0
        var anotherColumn: String?
        var currentColumn: String
        var intoColumn: String?

        func build() -> IntegerReducer? {
            guard intoColumn != "" else { return nil }
            switch singleOrMulti {
            case .single:
                switch singleColumnOperation {
                case .add:
                    return IntegerReducer.singleColumnReducer(.add(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .subtract:
                    return IntegerReducer.singleColumnReducer(.subtract(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .multiply:
                    return IntegerReducer.singleColumnReducer(.multiply(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .dividedBy:
                    return IntegerReducer.singleColumnReducer(.dividedBy(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .equalTo:
                    return IntegerReducer.singleColumnReducer(.equalTo(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .moreThan:
                    return IntegerReducer.singleColumnReducer(.moreThan(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .lessThan:
                    return IntegerReducer.singleColumnReducer(.lessThan(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .moreThanOrEqualTo:
                    return IntegerReducer.singleColumnReducer(.moreThanOrEqualTo(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .lessThanOrEqualTo:
                    return IntegerReducer.singleColumnReducer(.lessThanOrEqualTo(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .fillNil:
                    return IntegerReducer.singleColumnReducer(.fillNil(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .castDouble:
                    return IntegerReducer.singleColumnReducer(.castDouble(.init(column: currentColumn, intoColumn: intoColumn ?? currentColumn)))
                case .castString:
                    return IntegerReducer.singleColumnReducer(.castString(.init(column: currentColumn, intoColumn: intoColumn ?? currentColumn)))
                case .percentage:
                    return IntegerReducer.singleColumnReducer(.percentage(.init(column: currentColumn, intoColumn: intoColumn ?? currentColumn)))
                case nil:
                    return nil
                }
            case .multi:
                guard let anotherColumn else { return nil }
                switch multiColumnOperation {
                case .add:
                    return IntegerReducer.multiColumnReducer(.add(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
                case .subtract:
                    return IntegerReducer.multiColumnReducer(.subtract(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
                case .multiply:
                    return IntegerReducer.multiColumnReducer(.multiply(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
                case .dividedBy:
                    return IntegerReducer.multiColumnReducer(.dividedBy(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
                case .equalTo:
                    return IntegerReducer.multiColumnReducer(.equalTo(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
                case .moreThan:
                    return IntegerReducer.multiColumnReducer(.moreThan(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
                case .lessThan:
                    return IntegerReducer.multiColumnReducer(.lessThan(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
                case .moreThanOrEqualTo:
                    return IntegerReducer.multiColumnReducer(.moreThanOrEqualTo(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
                case .lessThanOrEqualTo:
                    return IntegerReducer.multiColumnReducer(.lessThanOrEqualTo(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
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

        init(reducer: IntegerReducer) {
            switch reducer {
            case let .multiColumnReducer(reducer):
                switch reducer {
                case let .add(p):
                    currentColumn = p.lhsColumn
                    anotherColumn = p.rhsColumn
                    singleOrMulti = .multi
                    multiColumnOperation = .add
                    if p.intoColumn == p.lhsColumn || p.intoColumn == p.rhsColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .subtract(p):
                    currentColumn = p.lhsColumn
                    anotherColumn = p.rhsColumn
                    singleOrMulti = .multi
                    multiColumnOperation = .subtract
                    if p.intoColumn == p.lhsColumn || p.intoColumn == p.rhsColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .multiply(p):
                    currentColumn = p.lhsColumn
                    anotherColumn = p.rhsColumn
                    singleOrMulti = .multi
                    multiColumnOperation = .multiply
                    if p.intoColumn == p.lhsColumn || p.intoColumn == p.rhsColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .dividedBy(p):
                    currentColumn = p.lhsColumn
                    anotherColumn = p.rhsColumn
                    singleOrMulti = .multi
                    multiColumnOperation = .dividedBy
                    if p.intoColumn == p.lhsColumn || p.intoColumn == p.rhsColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
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
                case let .add(p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .add
                    parameter = p.rhs
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .subtract(p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .subtract
                    parameter = p.rhs
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .multiply(p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .multiply
                    parameter = p.rhs
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .dividedBy(p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .dividedBy
                    parameter = p.rhs
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
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
                case let .castDouble(p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .castDouble
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .castString(p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .castString
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .percentage(p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .percentage
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
                    let integerColumns = dataFrame.columns.filter { column in
                        column.wrappedElementType == Int.self
                    }
                    ForEach(integerColumns, id: \.name) { column in
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
            case .add:
                "+"
            case .subtract:
                "-"
            case .multiply:
                "×"
            case .dividedBy:
                "÷"
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
            case .castDouble:
                "Cast to Double"
            case .castString:
                "Cast to String"
            case .percentage:
                "Calculate Percentage"
            }
        }

        case add
        case subtract
        case multiply
        case dividedBy
        case equalTo
        case moreThan
        case lessThan
        case moreThanOrEqualTo
        case lessThanOrEqualTo
        case fillNil
        case castDouble
        case castString
        case percentage

        var hasParameter: Bool {
            switch self {
            case .castDouble, .castString, .percentage:
                false
            case .add, .subtract, .multiply, .dividedBy, .equalTo, .moreThan, .lessThan, .moreThanOrEqualTo, .lessThanOrEqualTo, .fillNil:
                true
            }
        }
    }

    enum MultiColumnOperationOption: String, CustomStringConvertible, CaseIterable, Identifiable {
        var id: String { rawValue }

        var description: String {
            switch self {
            case .add:
                "+"
            case .subtract:
                "-"
            case .multiply:
                "×"
            case .dividedBy:
                "÷"
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

        case add
        case subtract
        case multiply
        case dividedBy
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
            ColumnOperationIntegerOperationView(currentColumn: "value", dataFrame: try! DataFrame(contentsOfCSVFile: Bundle.main.url(forResource: "air_quality_no2_long", withExtension: "csv")!), completion: { _ in })
        }
    } else {
        EmptyView()
    }
})
