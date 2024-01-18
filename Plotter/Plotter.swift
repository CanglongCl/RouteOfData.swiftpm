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

    enum PlotterType: Codable {
        case line
        case bar
        case pie
        case point
    }
}

@available(iOS 17.0, *)
@Observable
class PlotterBuilder {
    var plotterType: Plotter.PlotterType?
    var xAxis: String?
    var yAxis: String?
    let series: String? = nil

    func build() -> Plotter? {
        guard let plotterType, let xAxis, let yAxis else { return nil }
        return Plotter(type: plotterType, xAxis: xAxis, yAxis: yAxis, series: series)
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
