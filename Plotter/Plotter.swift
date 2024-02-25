//
//  Plotter.swift
//
//
//  Created by 戴藏龙 on 2024/1/17.
//

import Foundation
import TabularData

struct Plotter: Codable {
    let type: PlotterType
    let xAxis: String
    let yAxis: String
    let series: String?

    enum PlotterType: Int, Codable, CaseIterable, CustomStringConvertible {
        var description: String {
            switch self {
            case .line:
                "Line Chart"
            case .bar:
                "Bar Chart"
            case .pie:
                "Pie Chart"
            case .point:
                "Scatter Chart"
            }
        }

        case line
        case bar
        case pie
        case point
    }
}

enum PlotterError: Error {
    case columnNotFound(position: Position, columnName: String)

    enum Position {
        case xAxis
        case yAxis
        case series
    }
}

extension PlotterError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .columnNotFound(position: position, columnName: columnName):
            "COLUMN \(columnName) NOT FOUND (\(position))"
        }
    }
}
