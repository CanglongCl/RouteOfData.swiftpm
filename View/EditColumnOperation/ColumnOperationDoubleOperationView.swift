//
//  ColumnOperationDoubleOperationView.swift
//
//
//  Created by 戴藏龙 on 2024/1/5.
//

import Foundation
import SwiftUI
import TabularData

@available(iOS 17.0, *)
struct ColumnOperationDoubleOperationView: View {
    init(currentColumn: String, dataFrame: DataFrame, completion: @escaping (AnyReducer) -> Void) {
        self.dataFrame = dataFrame
        _builder = .init(initialValue: .init(currentColumn: currentColumn))
        self.completion = completion
    }

    init(doubleReducer: DoubleReducer, dataFrame: DataFrame, completion: @escaping (AnyReducer) -> Void) {
        self.dataFrame = dataFrame
        _builder = .init(initialValue: .init(reducer: doubleReducer))
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
                                    column.wrappedElementType == Double.self
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
                Text("Type: Double")
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
                    completion(AnyReducer.columnReducer(.double(builder.build()!)))
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
                    parameter = 0.0
                }
            }
        }

        var singleColumnOperation: SingleColumnOperationOption?
        var multiColumnOperation: MultiColumnOperationOption?
        var parameter: Double = 0.0
        var anotherColumn: String?
        var currentColumn: String
        var intoColumn: String?

        func build() -> DoubleReducer? {
            guard intoColumn != "" else { return nil }
            switch singleOrMulti {
            case .single:
                switch singleColumnOperation {
                case .add:
                    return .singleColumnReducer(.add(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .subtract:
                    return .singleColumnReducer(.subtract(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .multiply:
                    return .singleColumnReducer(.multiply(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
                case .dividedBy:
                    return .singleColumnReducer(.dividedBy(.init(column: currentColumn, rhs: parameter, intoColumn: intoColumn ?? currentColumn)))
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
                case .castIntCeil:
                    return .singleColumnReducer(.castIntCeil(.init(column: currentColumn, intoColumn: intoColumn ?? currentColumn)))
                case .castIntFloor:
                    return .singleColumnReducer(.castIntFloor(.init(column: currentColumn, intoColumn: intoColumn ?? currentColumn)))
                case .castString:
                    return .singleColumnReducer(.castString(.init(column: currentColumn, intoColumn: intoColumn ?? currentColumn)))
                case .percentage:
                    return .singleColumnReducer(.percentage(.init(column: currentColumn, intoColumn: intoColumn ?? currentColumn)))
                case nil:
                    return nil
                }
            case .multi:
                guard let anotherColumn else { return nil }
                switch multiColumnOperation {
                case .add:
                    return .multiColumnReducer(.add(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
                case .subtract:
                    return .multiColumnReducer(.subtract(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
                case .multiply:
                    return .multiColumnReducer(.multiply(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
                case .dividedBy:
                    return .multiColumnReducer(.dividedBy(.init(lhsColumn: currentColumn, rhsColumn: anotherColumn, intoColumn: intoColumn ?? currentColumn)))
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

        init(reducer: DoubleReducer) {
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
                case let .castIntCeil(p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .castIntCeil
                    if p.column == p.intoColumn {
                        intoColumn = nil
                    } else {
                        intoColumn = p.intoColumn
                    }
                case let .castIntFloor(p):
                    currentColumn = p.column
                    anotherColumn = p.column
                    singleOrMulti = .single
                    singleColumnOperation = .castIntFloor
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
                    let columns = dataFrame.columns.filter { column in
                        column.wrappedElementType == Double.self
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
            case .castIntCeil:
                "Cast to Int (Round Up)"
            case .castIntFloor:
                "Cast to Int (Round Down)"
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
        case castIntFloor
        case castIntCeil
        case castString
        case percentage

        var hasParameter: Bool {
            switch self {
            case .castIntCeil, .castIntFloor, .castString, .percentage:
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
            ColumnOperationDoubleOperationView(currentColumn: "value", dataFrame: try! DataFrame(contentsOfCSVFile: Bundle.main.url(forResource: "air_quality_no2_long", withExtension: "csv")!), completion: { _ in })
        }
    } else {
        EmptyView()
    }
})
