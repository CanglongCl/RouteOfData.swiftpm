//
//  AnyReducer+Description.swift
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
        case let .route(route):
            route.abbreviation
        case let .node(node):
            node.reducer.abbreviation
        case let .plot(node):
            node.plotter.abbreviation
        }
    }

    var description: AttributedString {
        switch self {
        case let .route(route):
            route.description
        case let .node(node):
            node.reducer.description
        case let .plot(node):
            node.plotter.description
        }
    }

    var shortAbbreviation: String {
        switch self {
        case let .route(route):
            route.shortAbbreviation
        case let .node(node):
            node.reducer.shortAbbreviation
        case let .plot(node):
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
        case let .columnReducer(reducer):
            reducer.shortAbbreviation
        case let .groupByReducer(reducer):
            reducer.shortAbbreviation
        case let .summary(reducer):
            reducer.shortAbbreviation
        case let .selectReducer(reducer):
            reducer.shortAbbreviation
        }
    }

    var abbreviation: String {
        switch self {
        case let .columnReducer(reducer):
            reducer.abbreviation
        case let .groupByReducer(reducer):
            reducer.abbreviation
        case let .summary(reducer):
            reducer.abbreviation
        case let .selectReducer(reducer):
            reducer.abbreviation
        }
    }

    var description: AttributedString {
        switch self {
        case let .columnReducer(reducer):
            reducer.description
        case let .groupByReducer(reducer):
            reducer.description
        case let .summary(reducer):
            reducer.description
        case let .selectReducer(reducer):
            reducer.description
        }
    }
}

extension SelectReducer: NodeDescription {
    var shortAbbreviation: String {
        switch self {
        case let .include(columns):
            "InCol"
        case let .exclude(columns):
            "ExCol"
        }
    }

    var abbreviation: String {
        switch self {
        case let .include(columns):
            "Include Columns"
        case let .exclude(columns):
            "Exclude Columns"
        }
    }

    var description: AttributedString {
        switch self {
        case let .include(columns):
            (try? AttributedString(markdown: "INCLUDE COLUMNS \(columns.map { "`**\($0)**`" }.formatted())")) ?? ""
        case let .exclude(columns):
            (try? AttributedString(markdown: "EXCLUDE COLUMNS **`\(columns.map { "`**\($0)**`" }.formatted())`**")) ?? ""
        }
    }
}

extension GroupByReducer: NodeDescription {
    var abbreviation: String {
        let aggregationFunctionDescription: String = switch operation.operation {
        case let .bool(op):
            op.description.lowercased()
        case let .integer(op):
            op.description.lowercased()
        case let .double(op):
            op.description.lowercased()
        case let .date(op):
            op.description.lowercased()
        case let .string(op):
            op.description.lowercased()
        }
        return "Group & Get \(aggregationFunctionDescription)"
    }

    var description: AttributedString {
        let groupKeyDescriptions: [String] = groupKey.intoArray().map { type in
            switch type {
            case let .any(columnName):
                columnName
            case let .date(columnName, groupByDateComponent):
                "\(columnName) (by \(groupByDateComponent.description.lowercased()))"
            }
        }
        let aggregationFunctionDescription: String = switch operation.operation {
        case let .bool(op):
            op.description.lowercased()
        case let .integer(op):
            op.description.lowercased()
        case let .double(op):
            op.description.lowercased()
        case let .date(op):
            op.description.lowercased()
        case let .string(op):
            op.description.lowercased()
        }
        let aggregationDescription = "AGGREGATION on **`\(operation.column)`** with FUNCTION **`\(aggregationFunctionDescription)`**"
        return (try? AttributedString(markdown: "GROUP BY \(groupKeyDescriptions.map { "**`\($0)`**" }.formatted()) and \(aggregationDescription)")) ?? ""
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
        case let .singleColumn(column):
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
            case let .multiColumnReducer(reducer):
                switch reducer {
                case let .and(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** AND **`\(p.rhsColumn)`**"
                case let .or(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** OR **`\(p.rhsColumn)`**"
                }
            case let .singleColumnReducer(reducer):
                switch reducer {
                case let .not(p):
                    "**`\(p.intoColumn)`** = NOT **`\(p.column)`**"
                case let .castInt(p):
                    "**`\(p.intoColumn)`** = CAST **`\(p.column)`** into INT"
                case let .filter(p):
                    "FILTER by **`\(p.column)`**"
                case let .fillNil(p):
                    "**`\(p.intoColumn)`** = FILL NIL **`\(p.column)`** with **`\(p.rhs)`**"
                }
            }
        case let .integer(reducer):
            switch reducer {
            case let .multiColumnReducer(reducer):
                switch reducer {
                case let .add(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** + **`\(p.rhsColumn)`**"
                case let .subtract(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** - **`\(p.rhsColumn)`**"
                case let .multiply(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** × **`\(p.rhsColumn)`**"
                case let .dividedBy(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** ÷ **`\(p.rhsColumn)`**"
                case let .equalTo(p):
                    "**`\(p.intoColumn)`** = IF **`\(p.lhsColumn)`** IS EQUAL TO **`\(p.rhsColumn)`**"
                case let .moreThan(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** > **`\(p.rhsColumn)`**"
                case let .lessThan(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** < **`\(p.rhsColumn)`**"
                case let .moreThanOrEqualTo(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** ≥ **`\(p.rhsColumn)`**"
                case let .lessThanOrEqualTo(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** ≤ **`\(p.rhsColumn)`**"
                }
            case let .singleColumnReducer(reducer):
                switch reducer {
                case let .add(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** + **`\(p.rhs)`**"
                case let .subtract(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** - **`\(p.rhs)`**"
                case let .multiply(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** × **`\(p.rhs)`**"
                case let .dividedBy(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** ÷ **`\(p.rhs)`**"
                case let .equalTo(p):
                    "**`\(p.intoColumn)`** = IF **`\(p.column)`** IS EQUAL TO **`\(p.rhs)`**"
                case let .moreThan(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** > **`\(p.rhs)`**"
                case let .lessThan(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** < **`\(p.rhs)`**"
                case let .moreThanOrEqualTo(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** ≥ **`\(p.rhs)`**"
                case let .lessThanOrEqualTo(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** ≤ **`\(p.rhs)`**"
                case let .castDouble(p):
                    "**`\(p.intoColumn)`** = CAST **`\(p.column)`** into DOUBLE"
                case let .castString(p):
                    "**`\(p.intoColumn)`** = CAST **`\(p.column)`** into STRING"
                case let .percentage(p):
                    "**`\(p.intoColumn)`** = ROW PERCENTAGE of TOTAL from **`\(p.column)`**"
                case let .fillNil(p):
                    "**`\(p.intoColumn)`** = FILL NIL **`\(p.column)`** with **`\(p.rhs)`**"
                }
            }
        case let .double(reducer):
            switch reducer {
            case let .multiColumnReducer(reducer):
                switch reducer {
                case let .add(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** + **`\(p.rhsColumn)`**"
                case let .subtract(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** - **`\(p.rhsColumn)`**"
                case let .multiply(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** × **`\(p.rhsColumn)`**"
                case let .dividedBy(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** ÷ **`\(p.rhsColumn)`**"
                case let .equalTo(p):
                    "**`\(p.intoColumn)`** = IF **`\(p.lhsColumn)`** IS EQUAL TO **`\(p.rhsColumn)`**"
                case let .moreThan(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** > **`\(p.rhsColumn)`**"
                case let .lessThan(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** < **`\(p.rhsColumn)`**"
                case let .moreThanOrEqualTo(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** ≥ **`\(p.rhsColumn)`**"
                case let .lessThanOrEqualTo(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** ≤ **`\(p.rhsColumn)`**"
                }
            case let .singleColumnReducer(reducer):
                switch reducer {
                case let .add(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** + **`\(p.rhs)`**"
                case let .subtract(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** - **`\(p.rhs)`**"
                case let .multiply(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** × **`\(p.rhs)`**"
                case let .dividedBy(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** ÷ **`\(p.rhs)`**"
                case let .equalTo(p):
                    "**`\(p.intoColumn)`** = IF **`\(p.column)`** IS EQUAL TO **`\(p.rhs)`**"
                case let .moreThan(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** > **`\(p.rhs)`**"
                case let .lessThan(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** < **`\(p.rhs)`**"
                case let .moreThanOrEqualTo(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** ≥ **`\(p.rhs)`**"
                case let .lessThanOrEqualTo(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** ≤ **`\(p.rhs)`**"
                case let .castIntCeil(p):
                    "**`\(p.intoColumn)`** = CAST **`\(p.column)`** into DOUBLE (round up)"
                case let .castIntFloor(p):
                    "**`\(p.intoColumn)`** = CAST **`\(p.column)`** into DOUBLE (round down)"
                case let .castString(p):
                    "**`\(p.intoColumn)`** = CAST **`\(p.column)`** into STRING"
                case let .percentage(p):
                    "**`\(p.intoColumn)`** = ROW PERCENTAGE of TOTAL from **`\(p.column)`**"
                case let .fillNil(p):
                    "**`\(p.intoColumn)`** = FILL NIL **`\(p.column)`** with **`\(p.rhs)`**"
                }
            }
        case let .date(reducer):
            switch reducer {
            case let .multiColumnReducer(reducer):
                switch reducer {
                case let .equalTo(p):
                    "**`\(p.intoColumn)`** = IF **`\(p.lhsColumn)`** IS EQUAL TO **`\(p.rhsColumn)`**"
                case let .moreThan(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** > **`\(p.rhsColumn)`**"
                case let .lessThan(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** < **`\(p.rhsColumn)`**"
                case let .moreThanOrEqualTo(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** ≥ **`\(p.rhsColumn)`**"
                case let .lessThanOrEqualTo(p):
                    "**`\(p.intoColumn)`** = **`\(p.lhsColumn)`** ≤ **`\(p.rhsColumn)`**"
                }
            case let .singleColumnReducer(reducer):
                switch reducer {
                case let .equalTo(p):
                    "**`\(p.intoColumn)`** = IF **`\(p.column)`** IS EQUAL TO **`\(p.rhs)`**"
                case let .moreThan(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** > **`\(p.rhs)`**"
                case let .lessThan(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** < **`\(p.rhs)`**"
                case let .moreThanOrEqualTo(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** ≥ **`\(p.rhs)`**"
                case let .lessThanOrEqualTo(p):
                    "**`\(p.intoColumn)`** = **`\(p.column)`** ≤ **`\(p.rhs)`**"
                case let .fillNil(p):
                    "**`\(p.intoColumn)`** = FILL NIL **`\(p.column)`** with **`\(p.rhs)`**"
                }
            }
        case let .string(reducer):
            switch reducer {
            case let .singleColumnReducer(reducer):
                switch reducer {
                case let .equalTo(p):
                    "**`\(p.intoColumn)`** = IF **`\(p.column)`** IS EQUAL TO **`\(p.rhs)`**"
                case let .fillNil(p):
                    "**`\(p.intoColumn)`** = FILL NIL **`\(p.column)`** with **`\(p.rhs)`**"
                case let .tryCastInt(p):
                    "**`\(p.intoColumn)`** = TRY CAST **`\(p.column)`** into INT"
                case let .tryCastDouble(p):
                    "**`\(p.intoColumn)`** = TRY CAST **`\(p.column)`** into DOUBLE"
                case let .tryCastDate(p):
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
            case let .multiColumnReducer(reducer):
                switch reducer {
                case let .and(p):
                    "And"
                case let .or(p):
                    "Or"
                }
            case let .singleColumnReducer(reducer):
                switch reducer {
                case let .not(p):
                    "Not"
                case let .castInt(p):
                    "Cast Int"
                case let .filter(p):
                    "Filter"
                case let .fillNil(p):
                    "Fill Nil"
                }
            }
        case let .integer(reducer):
            switch reducer {
            case let .multiColumnReducer(reducer):
                switch reducer {
                case let .add(p):
                    "Add"
                case let .subtract(p):
                    "Subtract"
                case let .multiply(p):
                    "Multiply"
                case let .dividedBy(p):
                    "Divide By"
                case let .equalTo(p):
                    "If Equal To"
                case let .moreThan(p):
                    "More Than"
                case let .lessThan(p):
                    "Less Than"
                case let .moreThanOrEqualTo(p):
                    "More Than or Equal To"
                case let .lessThanOrEqualTo(p):
                    "Less Than or Equal To"
                }
            case let .singleColumnReducer(reducer):
                switch reducer {
                case let .add(p):
                    "Add"
                case let .subtract(p):
                    "Subtract"
                case let .multiply(p):
                    "Multiply"
                case let .dividedBy(p):
                    "Divide By"
                case let .equalTo(p):
                    "If Equal To"
                case let .moreThan(p):
                    "More Than"
                case let .lessThan(p):
                    "Less Than"
                case let .moreThanOrEqualTo(p):
                    "More Than or Equal To"
                case let .lessThanOrEqualTo(p):
                    "Less Than or Equal To"
                case let .castDouble(p):
                    "Cast Double"
                case let .castString(p):
                    "Cast String"
                case let .percentage(p):
                    "Percentage"
                case let .fillNil(p):
                    "Fill Nil"
                }
            }
        case let .double(reducer):
            switch reducer {
            case let .multiColumnReducer(reducer):
                switch reducer {
                case let .add(p):
                    "Add"
                case let .subtract(p):
                    "Subtract"
                case let .multiply(p):
                    "Multiply"
                case let .dividedBy(p):
                    "Divide By"
                case let .equalTo(p):
                    "If Equal To"
                case let .moreThan(p):
                    "More Than"
                case let .lessThan(p):
                    "Less Than"
                case let .moreThanOrEqualTo(p):
                    "More Than or Equal To"
                case let .lessThanOrEqualTo(p):
                    "Less Than or Equal To"
                }
            case let .singleColumnReducer(reducer):
                switch reducer {
                case let .add(p):
                    "Add"
                case let .subtract(p):
                    "Subtract"
                case let .multiply(p):
                    "Multiply"
                case let .dividedBy(p):
                    "Divide By"
                case let .equalTo(p):
                    "If Equal To"
                case let .moreThan(p):
                    "More Than"
                case let .lessThan(p):
                    "Less Than"
                case let .moreThanOrEqualTo(p):
                    "More Than or Equal To"
                case let .lessThanOrEqualTo(p):
                    "Less Than or Equal To"
                case let .castIntCeil(p):
                    "Round Up"
                case let .castIntFloor(p):
                    "Round Down"
                case let .castString(p):
                    "Cast String"
                case let .percentage(p):
                    "Percentage"
                case let .fillNil(p):
                    "Fill Nil"
                }
            }
        case let .date(reducer):
            switch reducer {
            case let .multiColumnReducer(reducer):
                switch reducer {
                case let .equalTo(p):
                    "If Equal To"
                case let .moreThan(p):
                    "More Than"
                case let .lessThan(p):
                    "Less Than"
                case let .moreThanOrEqualTo(p):
                    "More Than or Equal To"
                case let .lessThanOrEqualTo(p):
                    "Less Than or Equal To"
                }
            case let .singleColumnReducer(reducer):
                switch reducer {
                case let .equalTo(p):
                    "If Equal To"
                case let .moreThan(p):
                    "More Than"
                case let .lessThan(p):
                    "Less Than"
                case let .moreThanOrEqualTo(p):
                    "More Than or Equal To"
                case let .lessThanOrEqualTo(p):
                    "Less Than or Equal To"
                case let .fillNil(p):
                    "Fill Nil"
                }
            }
        case let .string(reducer):
            switch reducer {
            case let .singleColumnReducer(reducer):
                switch reducer {
                case let .equalTo(p):
                    "If Equal To"
                case let .fillNil(p):
                    "Fill Nil"
                case let .tryCastInt(p):
                    "Try Cast Int"
                case let .tryCastDouble(p):
                    "Try Cast Double"
                case let .tryCastDate(p):
                    "Try Cast Date"
                }
            }
        }
    }

    var shortAbbreviation: String {
        switch self {
        case let .boolean(reducer):
            switch reducer {
            case let .multiColumnReducer(reducer):
                switch reducer {
                case let .and(p):
                    "And"
                case let .or(p):
                    "Or"
                }
            case let .singleColumnReducer(reducer):
                switch reducer {
                case let .not(p):
                    "Not"
                case let .castInt(p):
                    "->Int"
                case let .filter(p):
                    "Filter"
                case let .fillNil(p):
                    "FiNil"
                }
            }
        case let .integer(reducer):
            switch reducer {
            case let .multiColumnReducer(reducer):
                switch reducer {
                case let .add(p):
                    "+"
                case let .subtract(p):
                    "-"
                case let .multiply(p):
                    "×"
                case let .dividedBy(p):
                    "÷"
                case let .equalTo(p):
                    "=="
                case let .moreThan(p):
                    ">"
                case let .lessThan(p):
                    "<"
                case let .moreThanOrEqualTo(p):
                    "≥"
                case let .lessThanOrEqualTo(p):
                    "≤"
                }
            case let .singleColumnReducer(reducer):
                switch reducer {
                case let .add(p):
                    "+"
                case let .subtract(p):
                    "-"
                case let .multiply(p):
                    "×"
                case let .dividedBy(p):
                    "÷"
                case let .equalTo(p):
                    "=="
                case let .moreThan(p):
                    ">"
                case let .lessThan(p):
                    "<"
                case let .moreThanOrEqualTo(p):
                    "≥"
                case let .lessThanOrEqualTo(p):
                    "≤"
                case let .castDouble(p):
                    "->Double"
                case let .castString(p):
                    "->String"
                case let .percentage(p):
                    "%"
                case let .fillNil(p):
                    "FiNil"
                }
            }
        case let .double(reducer):
            switch reducer {
            case let .multiColumnReducer(reducer):
                switch reducer {
                case let .add(p):
                    "+"
                case let .subtract(p):
                    "-"
                case let .multiply(p):
                    "×"
                case let .dividedBy(p):
                    "÷"
                case let .equalTo(p):
                    "=="
                case let .moreThan(p):
                    ">"
                case let .lessThan(p):
                    "<"
                case let .moreThanOrEqualTo(p):
                    "≥"
                case let .lessThanOrEqualTo(p):
                    "≤"
                }
            case let .singleColumnReducer(reducer):
                switch reducer {
                case let .add(p):
                    "+"
                case let .subtract(p):
                    "-"
                case let .multiply(p):
                    "×"
                case let .dividedBy(p):
                    "÷"
                case let .equalTo(p):
                    "=="
                case let .moreThan(p):
                    ">"
                case let .lessThan(p):
                    "<"
                case let .moreThanOrEqualTo(p):
                    "≥"
                case let .lessThanOrEqualTo(p):
                    "≤"
                case let .castIntCeil(p):
                    "Round↑"
                case let .castIntFloor(p):
                    "Round↓"
                case let .castString(p):
                    "->String"
                case let .percentage(p):
                    "%"
                case let .fillNil(p):
                    "FiNil"
                }
            }
        case let .date(reducer):
            switch reducer {
            case let .multiColumnReducer(reducer):
                switch reducer {
                case let .equalTo(p):
                    "=="
                case let .moreThan(p):
                    ">"
                case let .lessThan(p):
                    "<"
                case let .moreThanOrEqualTo(p):
                    "≥"
                case let .lessThanOrEqualTo(p):
                    "≤"
                }
            case let .singleColumnReducer(reducer):
                switch reducer {
                case let .equalTo(p):
                    "--"
                case let .moreThan(p):
                    ">"
                case let .lessThan(p):
                    "<"
                case let .moreThanOrEqualTo(p):
                    "≥"
                case let .lessThanOrEqualTo(p):
                    "≤"
                case let .fillNil(p):
                    "FiNil"
                }
            }
        case let .string(reducer):
            switch reducer {
            case let .singleColumnReducer(reducer):
                switch reducer {
                case let .equalTo(p):
                    "=="
                case let .fillNil(p):
                    "FiNil"
                case let .tryCastInt(p):
                    "->Int"
                case let .tryCastDouble(p):
                    "->Double"
                case let .tryCastDate(p):
                    "->Date"
                }
            }
        }
    }
}
