//
//  File.swift
//  
//
//  Created by 戴藏龙 on 2024/1/25.
//

import Foundation

protocol NodeDescription {
    var abbreviation: String { get }
    var description: AttributedString { get }
    var shortAbbreviation: String { get }
}

@available(iOS 17, *)
extension DisplayableNode: NodeDescription {
    var abbreviation: String {
        switch self {
        case .route(let route):
            route.abbreviation
        case .node(let node):
            node.reducer.abbreviation
        case .plot(let node):
            node.plotter.abbreviation
        }
    }
    
    var description: AttributedString {
        switch self {
        case .route(let route):
            route.description
        case .node(let node):
            node.reducer.description
        case .plot(let node):
            node.plotter.description
        }
    }
    
    var shortAbbreviation: String {
        switch self {
        case .route(let route):
            route.shortAbbreviation
        case .node(let node):
            node.reducer.shortAbbreviation
        case .plot(let node):
            node.plotter.shortAbbreviation
        }
    }
}

extension Plotter: NodeDescription {
    var abbreviation: String {
        type.description
    }
    
    var description: AttributedString {
        let description: String = switch type {
        case .pie:
            "PIE CHART with angle by **`\(yAxis)`** and sectors by **`\(xAxis)`**"
        default:
            if let series {
                "\(type.description.uppercased()) with **`\(xAxis)`** on x-axis, **`\(yAxis)`** on y-axis and group by **`\(series)`**"
            } else {
                "\(type.description.uppercased()) with **`\(xAxis)`** on x-axis and **`\(yAxis)`** on y-axis"
            }
        }
        return (try? AttributedString(markdown: description)) ?? ""
    }
    
    var shortAbbreviation: String {
        switch type {
        case .line:
            "📈"
        case .bar:
            "📊"
        case .pie:
            "Pie📊"
        case .point:
            "Scat📊"
        }
    }
}

@available(iOS 17, *)
extension Route: NodeDescription {
    var abbreviation: String {
        "Read CSV"
    }
    
    var description: AttributedString {
        (try? AttributedString(markdown: "Read CSV from **`\(url.lastPathComponent)`**")) ?? ""
    }
    
    var shortAbbreviation: String {
        "Read"
    }
}

@available(iOS 17, *)
extension Node: NodeDescription {
    var abbreviation: String {
        reducer.abbreviation
    }
    
    var description: AttributedString {
        reducer.description
    }
    
    var shortAbbreviation: String {
        reducer.shortAbbreviation
    }
}

extension AnyReducer: NodeDescription {
    var shortAbbreviation: String {
        switch self {
        case .columnReducer(let reducer):
            reducer.shortAbbreviation
        case .groupByReducer(let reducer):
            reducer.shortAbbreviation
        case .summary(let reducer):
            reducer.shortAbbreviation
        case .selectReducer(let reducer):
            reducer.shortAbbreviation
        }
    }
    
    var abbreviation: String {
        switch self {
        case .columnReducer(let reducer):
            reducer.abbreviation
        case .groupByReducer(let reducer):
            reducer.abbreviation
        case .summary(let reducer):
            reducer.abbreviation
        case .selectReducer(let reducer):
            reducer.abbreviation
        }
    }
    
    var description: AttributedString {
        switch self {
        case .columnReducer(let reducer):
            reducer.description
        case .groupByReducer(let reducer):
            reducer.description
        case .summary(let reducer):
            reducer.description
        case .selectReducer(let reducer):
            reducer.description
        }
    }
}

extension SelectReducer: NodeDescription {
    var shortAbbreviation: String {
        switch self {
        case .include(let columns):
            "InCol"
        case .exclude(let columns):
            "ExCol"
        }
    }
    
    var abbreviation: String {
        switch self {
        case .include(let columns):
            "Include Columns"
        case .exclude(let columns):
            "Exclude Columns"
        }
    }

    var description: AttributedString {
        switch self {
        case .include(let columns):
            (try? AttributedString(markdown: "INCLUDE COLUMNS **`\(columns.formatted())`**")) ?? ""
        case .exclude(let columns):
            (try? AttributedString(markdown: "EXCLUDE COLUMNS **`\(columns.formatted())`**")) ?? ""
        }
    }
}

extension GroupByReducer: NodeDescription {
    var abbreviation: String {
        let aggregationFunctionDescription: String = switch operation.operation {
        case .bool(let op):
            op.description.lowercased()
        case .integer(let op):
            op.description.lowercased()
        case .double(let op):
            op.description.lowercased()
        case .date(let op):
            op.description.lowercased()
        case .string(let op):
            op.description.lowercased()
        }
        return "Group & Get \(aggregationFunctionDescription)"
    }
    
    var description: AttributedString {
        let groupKeyDescriptions: [String] = groupKey.intoArray().map { type in
            switch type {
            case .any(let columnName):
                columnName
            case .date(let columnName, let groupByDateComponent):
                "\(columnName) (by \(groupByDateComponent.description.lowercased()))"
            }
        }
        let aggregationFunctionDescription: String = switch operation.operation {
        case .bool(let op):
            op.description.lowercased()
        case .integer(let op):
            op.description.lowercased()
        case .double(let op):
            op.description.lowercased()
        case .date(let op):
            op.description.lowercased()
        case .string(let op):
            op.description.lowercased()
        }
        let aggregationDescription: String = "AGGREGATION on **`\(operation.column)`** with FUNCTION **`\(aggregationFunctionDescription)`**"
        return (try? AttributedString(markdown: "GROUP BY **`\(groupKeyDescriptions.formatted())`** and \(aggregationDescription)")) ?? ""
    }
    
    var shortAbbreviation: String {
        "Gp&Agg"
    }
}

extension SummaryReducer: NodeDescription {
    var abbreviation: String {
        "Summary"
    }
    
    var description: AttributedString {
        switch self {
        case .all:
            "SUMMARY Table"
        case .singleColumn(let column):
            (try? AttributedString(markdown: "SUMMARY COLUMN **`\(column)`**")) ?? ""
        }
    }
    
    var shortAbbreviation: String {
        "Summ"
    }
}

extension AnyColumnReducer: NodeDescription {
    var description: AttributedString {
        let description: String = switch self {
        case let .boolean(reducer):
            switch reducer {
            case .multiColumnReducer(let reducer):
                switch reducer {
                case .and(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** AND **`\(p.rhsColumn)`**"
                case .or(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** OR **`\(p.rhsColumn)`**"
                }
            case .singleColumnReducer(let reducer):
                switch reducer {
                case .not(let p):
                    "**`\(p.intoColumn)`** = NOT **`\(p.column)`**"
                case .castInt(let p):
                    "**`\(p.intoColumn)`** = CAST **`\(p.column)`** into INT"
                case .filter(let p):
                    "FILTER by **`\(p.column)`**"
                case .fillNil(let p):
                    "**`\(p.intoColumn)`** = FILL NIL **`\(p.column)`** with **`\(p.rhs)`**"
                }
            }
        case let .integer(reducer):
            switch reducer {
            case .multiColumnReducer(let reducer):
                switch reducer {
                case .add(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** + **`\(p.rhsColumn)`**"
                case .subtract(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** - **`\(p.rhsColumn)`**"
                case .multiply(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** × **`\(p.rhsColumn)`**"
                case .dividedBy(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** ÷ **`\(p.rhsColumn)`**"
                case .equalTo(let p):
                    "**`\(p.intoColumn)`** = IF **`\(p.lhsColumn)`** IS EQUAL TO **`\(p.rhsColumn)`**"
                case .moreThan(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** > **`\(p.rhsColumn)`**"
                case .lessThan(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** < **`\(p.rhsColumn)`**"
                case .moreThanOrEqualTo(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** ≥ **`\(p.rhsColumn)`**"
                case .lessThanOrEqualTo(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** ≤ **`\(p.rhsColumn)`**"
                }
            case .singleColumnReducer(let reducer):
                switch reducer {
                case .add(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** + **`\(p.rhs)`**"
                case .subtract(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** - **`\(p.rhs)`**"
                case .multiply(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** × **`\(p.rhs)`**"
                case .dividedBy(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** ÷ **`\(p.rhs)`**"
                case .equalTo(let p):
                    "**`\(p.intoColumn)`** = IF **`\(p.column)`** IS EQUAL TO **`\(p.rhs)`**"
                case .moreThan(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** > **`\(p.rhs)`**"
                case .lessThan(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** < **`\(p.rhs)`**"
                case .moreThanOrEqualTo(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** ≥ **`\(p.rhs)`**"
                case .lessThanOrEqualTo(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** ≤ **`\(p.rhs)`**"
                case .castDouble(let p):
                    "**`\(p.intoColumn)`** = CAST **`\(p.column)`** into DOUBLE"
                case .castString(let p):
                    "**`\(p.intoColumn)`** = CAST **`\(p.column)`** into STRING"
                case .percentage(let p):
                    "**`\(p.intoColumn)`** = ROW PERCENTAGE of TOTAL from **`\(p.column)`**"
                case .fillNil(let p):
                    "**`\(p.intoColumn)`** = FILL NIL **`\(p.column)`** with **`\(p.rhs)`**"
                }
            }
        case let .double(reducer):
            switch reducer {
            case .multiColumnReducer(let reducer):
                switch reducer {
                case .add(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** + **`\(p.rhsColumn)`**"
                case .subtract(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** - **`\(p.rhsColumn)`**"
                case .multiply(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** × **`\(p.rhsColumn)`**"
                case .dividedBy(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** ÷ **`\(p.rhsColumn)`**"
                case .equalTo(let p):
                    "**`\(p.intoColumn)`** = IF **`\(p.lhsColumn)`** IS EQUAL TO **`\(p.rhsColumn)`**"
                case .moreThan(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** > **`\(p.rhsColumn)`**"
                case .lessThan(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** < **`\(p.rhsColumn)`**"
                case .moreThanOrEqualTo(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** ≥ **`\(p.rhsColumn)`**"
                case .lessThanOrEqualTo(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** ≤ **`\(p.rhsColumn)`**"
                }
            case .singleColumnReducer(let reducer):
                switch reducer {
                case .add(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** + **`\(p.rhs)`**"
                case .subtract(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** - **`\(p.rhs)`**"
                case .multiply(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** × **`\(p.rhs)`**"
                case .dividedBy(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** ÷ **`\(p.rhs)`**"
                case .equalTo(let p):
                    "**`\(p.intoColumn)`** = IF **`\(p.column)`** IS EQUAL TO **`\(p.rhs)`**"
                case .moreThan(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** > **`\(p.rhs)`**"
                case .lessThan(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** < **`\(p.rhs)`**"
                case .moreThanOrEqualTo(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** ≥ **`\(p.rhs)`**"
                case .lessThanOrEqualTo(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** ≤ **`\(p.rhs)`**"
                case .castIntCeil(let p):
                    "**`\(p.intoColumn)`** = CAST **`\(p.column)`** into DOUBLE (round up)"
                case .castIntFloor(let p):
                    "**`\(p.intoColumn)`** = CAST **`\(p.column)`** into DOUBLE (round down)"
                case .castString(let p):
                    "**`\(p.intoColumn)`** = CAST **`\(p.column)`** into STRING"
                case .percentage(let p):
                    "**`\(p.intoColumn)`** = ROW PERCENTAGE of TOTAL from **`\(p.column)`**"
                case .fillNil(let p):
                    "**`\(p.intoColumn)`** = FILL NIL **`\(p.column)`** with **`\(p.rhs)`**"
                }
            }
        case let .date(reducer):
            switch reducer {
            case .multiColumnReducer(let reducer):
                switch reducer {
                case .equalTo(let p):
                    "**`\(p.intoColumn)`** = IF **`\(p.lhsColumn)`** IS EQUAL TO **`\(p.rhsColumn)`**"
                case .moreThan(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** > **`\(p.rhsColumn)`**"
                case .lessThan(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** < **`\(p.rhsColumn)`**"
                case .moreThanOrEqualTo(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** ≥ **`\(p.rhsColumn)`**"
                case .lessThanOrEqualTo(let p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** ≤ **`\(p.rhsColumn)`**"
                }
            case .singleColumnReducer(let reducer):
                switch reducer {
                case .equalTo(let p):
                    "**`\(p.intoColumn)`** = IF **`\(p.column)`** IS EQUAL TO **`\(p.rhs)`**"
                case .moreThan(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** > **`\(p.rhs)`**"
                case .lessThan(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** < **`\(p.rhs)`**"
                case .moreThanOrEqualTo(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** ≥ **`\(p.rhs)`**"
                case .lessThanOrEqualTo(let p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** ≤ **`\(p.rhs)`**"
                case .fillNil(let p):
                    "**`\(p.intoColumn)`** = FILL NIL **`\(p.column)`** with **`\(p.rhs)`**"
                }
            }
        case let .string(reducer):
            switch reducer {
            case .singleColumnReducer(let reducer):
                switch reducer {
                case .equalTo(let p):
                    "**`\(p.intoColumn)`** = IF **`\(p.column)`** IS EQUAL TO **`\(p.rhs)`**"
                case .fillNil(let p):
                    "**`\(p.intoColumn)`** = FILL NIL **`\(p.column)`** with **`\(p.rhs)`**"
                case .tryCastInt(let p):
                    "**`\(p.intoColumn)`** = TRY CAST **`\(p.column)`** into INT"
                case .tryCastDouble(let p):
                    "**`\(p.intoColumn)`** = TRY CAST **`\(p.column)`** into DOUBLE"
                case .tryCastDate(let p):
                    "**`\(p.intoColumn)`** = TRY CAST **`\(p.column)`** as DATE with FORMAT **`\(p.rhs)`**"
                }
            }
        }
        return (try? AttributedString(markdown: description)) ?? ""
    }

    var abbreviation: String {
        switch self {
        case let .boolean(reducer):
            switch reducer {
            case .multiColumnReducer(let reducer):
                switch reducer {
                case .and(let p):
                    "And"
                case .or(let p):
                    "Or"
                }
            case .singleColumnReducer(let reducer):
                switch reducer {
                case .not(let p):
                    "Not"
                case .castInt(let p):
                    "Cast Int"
                case .filter(let p):
                    "Filter"
                case .fillNil(let p):
                    "Fill Nil"
                }
            }
        case let .integer(reducer):
            switch reducer {
            case .multiColumnReducer(let reducer):
                switch reducer {
                case .add(let p):
                    "Add"
                case .subtract(let p):
                    "Subtract"
                case .multiply(let p):
                    "Multiply"
                case .dividedBy(let p):
                    "Divide By"
                case .equalTo(let p):
                    "If Equal To"
                case .moreThan(let p):
                    "More Than"
                case .lessThan(let p):
                    "Less Than"
                case .moreThanOrEqualTo(let p):
                    "More Than or Equal To"
                case .lessThanOrEqualTo(let p):
                    "Less Than or Equal To"
                }
            case .singleColumnReducer(let reducer):
                switch reducer {
                case .add(let p):
                    "Add"
                case .subtract(let p):
                    "Subtract"
                case .multiply(let p):
                    "Multiply"
                case .dividedBy(let p):
                    "Divide By"
                case .equalTo(let p):
                    "If Equal To"
                case .moreThan(let p):
                    "More Than"
                case .lessThan(let p):
                    "Less Than"
                case .moreThanOrEqualTo(let p):
                    "More Than or Equal To"
                case .lessThanOrEqualTo(let p):
                    "Less Than or Equal To"
                case .castDouble(let p):
                    "Cast Double"
                case .castString(let p):
                    "Cast String"
                case .percentage(let p):
                    "Percentage"
                case .fillNil(let p):
                    "Fill Nil"
                }
            }
        case let .double(reducer):
            switch reducer {
            case .multiColumnReducer(let reducer):
                switch reducer {
                case .add(let p):
                    "Add"
                case .subtract(let p):
                    "Subtract"
                case .multiply(let p):
                    "Multiply"
                case .dividedBy(let p):
                    "Divide By"
                case .equalTo(let p):
                    "If Equal To"
                case .moreThan(let p):
                    "More Than"
                case .lessThan(let p):
                    "Less Than"
                case .moreThanOrEqualTo(let p):
                    "More Than or Equal To"
                case .lessThanOrEqualTo(let p):
                    "Less Than or Equal To"
                }
            case .singleColumnReducer(let reducer):
                switch reducer {
                case .add(let p):
                    "Add"
                case .subtract(let p):
                    "Subtract"
                case .multiply(let p):
                    "Multiply"
                case .dividedBy(let p):
                    "Divide By"
                case .equalTo(let p):
                    "If Equal To"
                case .moreThan(let p):
                    "More Than"
                case .lessThan(let p):
                    "Less Than"
                case .moreThanOrEqualTo(let p):
                    "More Than or Equal To"
                case .lessThanOrEqualTo(let p):
                    "Less Than or Equal To"
                case .castIntCeil(let p):
                    "Round Up"
                case .castIntFloor(let p):
                    "Round Down"
                case .castString(let p):
                    "Cast String"
                case .percentage(let p):
                    "Percentage"
                case .fillNil(let p):
                    "Fill Nil"
                }
            }
        case let .date(reducer):
            switch reducer {
            case .multiColumnReducer(let reducer):
                switch reducer {
                case .equalTo(let p):
                    "If Equal To"
                case .moreThan(let p):
                    "More Than"
                case .lessThan(let p):
                    "Less Than"
                case .moreThanOrEqualTo(let p):
                    "More Than or Equal To"
                case .lessThanOrEqualTo(let p):
                    "Less Than or Equal To"
                }
            case .singleColumnReducer(let reducer):
                switch reducer {
                case .equalTo(let p):
                    "If Equal To"
                case .moreThan(let p):
                    "More Than"
                case .lessThan(let p):
                    "Less Than"
                case .moreThanOrEqualTo(let p):
                    "More Than or Equal To"
                case .lessThanOrEqualTo(let p):
                    "Less Than or Equal To"
                case .fillNil(let p):
                    "Fill Nil"
                }
            }
        case let .string(reducer):
            switch reducer {
            case .singleColumnReducer(let reducer):
                switch reducer {
                case .equalTo(let p):
                    "If Equal To"
                case .fillNil(let p):
                    "Fill Nil"
                case .tryCastInt(let p):
                    "Try Cast Int"
                case .tryCastDouble(let p):
                    "Try Cast Double"
                case .tryCastDate(let p):
                    "Try Cast Date"
                }
            }
        }
    }

    var shortAbbreviation: String {
        switch self {
        case let .boolean(reducer):
            switch reducer {
            case .multiColumnReducer(let reducer):
                switch reducer {
                case .and(let p):
                    "And"
                case .or(let p):
                    "Or"
                }
            case .singleColumnReducer(let reducer):
                switch reducer {
                case .not(let p):
                    "Not"
                case .castInt(let p):
                    "->Int"
                case .filter(let p):
                    "Filter"
                case .fillNil(let p):
                    "FiNil"
                }
            }
        case let .integer(reducer):
            switch reducer {
            case .multiColumnReducer(let reducer):
                switch reducer {
                case .add(let p):
                    "+"
                case .subtract(let p):
                    "-"
                case .multiply(let p):
                    "×"
                case .dividedBy(let p):
                    "÷"
                case .equalTo(let p):
                    "=="
                case .moreThan(let p):
                    ">"
                case .lessThan(let p):
                    "<"
                case .moreThanOrEqualTo(let p):
                    "≥"
                case .lessThanOrEqualTo(let p):
                    "≤"
                }
            case .singleColumnReducer(let reducer):
                switch reducer {
                case .add(let p):
                    "+"
                case .subtract(let p):
                    "-"
                case .multiply(let p):
                    "×"
                case .dividedBy(let p):
                    "÷"
                case .equalTo(let p):
                    "=="
                case .moreThan(let p):
                    ">"
                case .lessThan(let p):
                    "<"
                case .moreThanOrEqualTo(let p):
                    "≥"
                case .lessThanOrEqualTo(let p):
                    "≤"
                case .castDouble(let p):
                    "->Double"
                case .castString(let p):
                    "->String"
                case .percentage(let p):
                    "%"
                case .fillNil(let p):
                    "FiNil"
                }
            }
        case let .double(reducer):
            switch reducer {
            case .multiColumnReducer(let reducer):
                switch reducer {
                case .add(let p):
                    "+"
                case .subtract(let p):
                    "-"
                case .multiply(let p):
                    "×"
                case .dividedBy(let p):
                    "÷"
                case .equalTo(let p):
                    "=="
                case .moreThan(let p):
                    ">"
                case .lessThan(let p):
                    "<"
                case .moreThanOrEqualTo(let p):
                    "≥"
                case .lessThanOrEqualTo(let p):
                    "≤"
                }
            case .singleColumnReducer(let reducer):
                switch reducer {
                case .add(let p):
                    "+"
                case .subtract(let p):
                    "-"
                case .multiply(let p):
                    "×"
                case .dividedBy(let p):
                    "÷"
                case .equalTo(let p):
                    "=="
                case .moreThan(let p):
                    ">"
                case .lessThan(let p):
                    "<"
                case .moreThanOrEqualTo(let p):
                    "≥"
                case .lessThanOrEqualTo(let p):
                    "≤"
                case .castIntCeil(let p):
                    "Round↑"
                case .castIntFloor(let p):
                    "Round↓"
                case .castString(let p):
                    "->String"
                case .percentage(let p):
                    "%"
                case .fillNil(let p):
                    "FiNil"
                }
            }
        case let .date(reducer):
            switch reducer {
            case .multiColumnReducer(let reducer):
                switch reducer {
                case .equalTo(let p):
                    "=="
                case .moreThan(let p):
                    ">"
                case .lessThan(let p):
                    "<"
                case .moreThanOrEqualTo(let p):
                    "≥"
                case .lessThanOrEqualTo(let p):
                    "≤"
                }
            case .singleColumnReducer(let reducer):
                switch reducer {
                case .equalTo(let p):
                    "--"
                case .moreThan(let p):
                    ">"
                case .lessThan(let p):
                    "<"
                case .moreThanOrEqualTo(let p):
                    "≥"
                case .lessThanOrEqualTo(let p):
                    "≤"
                case .fillNil(let p):
                    "FiNil"
                }
            }
        case let .string(reducer):
            switch reducer {
            case .singleColumnReducer(let reducer):
                switch reducer {
                case .equalTo(let p):
                    "=="
                case .fillNil(let p):
                    "FiNil"
                case .tryCastInt(let p):
                    "->Int"
                case .tryCastDouble(let p):
                    "->Double"
                case .tryCastDate(let p):
                    "->Date"
                }
            }
        }
    }
}
