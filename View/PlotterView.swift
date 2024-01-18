//
//  PlotterView.swift
//
//
//  Created by 戴藏龙 on 2024/1/17.
//

import Charts
import SwiftUI
import TabularData

@available(iOS 17, *)
struct PlotterView: View {
    let plotter: Plotter
    let dataSet: DataFrame

    var body: some View {
        Chart(dataSet.rows, id: \.index) { row in
            if let series = plotter.series,
               let seriesValue = row[series] as? CustomStringConvertible
            {
                mark(row)
                    .foregroundStyle(by: .value(series, seriesValue.description))
            } else {
                mark(row)
            }
        }
    }

//    @ChartContentBuilder
//    func mark(_ row: DataFrame.Row) -> some ChartContent {
//        if let x = row[plotter.xAxis] as? Double {
//            if let y = row[plotter.yAxis] as? Double {
//                getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
//            } else if let y = row[plotter.yAxis] as? Int {
//                getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
//            } else if let y = row[plotter.yAxis] as? Date {
//                getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
//            } else if let y = row[plotter.yAxis] as? CustomStringConvertible {
//                getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y.description)
//            }
//        } else if let x = row[plotter.xAxis] as? Int {
//            if let y = row[plotter.yAxis] as? Double {
//                getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
//            } else if let y = row[plotter.yAxis] as? Int {
//                getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
//            } else if let y = row[plotter.yAxis] as? Date {
//                getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
//            } else if let y = row[plotter.yAxis] as? CustomStringConvertible {
//                getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y.description)
//            }
//        } else if let x = row[plotter.xAxis] as? Date {
//            if let y = row[plotter.yAxis] as? Double {
//                getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
//            } else if let y = row[plotter.yAxis] as? Int {
//                getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
//            } else if let y = row[plotter.yAxis] as? Date {
//                getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
//            } else if let y = row[plotter.yAxis] as? CustomStringConvertible {
//                getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y.description)
//            }
//        } else if let x = row[plotter.xAxis] as? CustomStringConvertible {
//            if let y = row[plotter.yAxis] as? Double {
//                getMark(xName: plotter.xAxis, x: x.description, yName: plotter.yAxis, y: y)
//            } else if let y = row[plotter.yAxis] as? Int {
//                getMark(xName: plotter.xAxis, x: x.description, yName: plotter.yAxis, y: y)
//            } else if let y = row[plotter.yAxis] as? Date {
//                getMark(xName: plotter.xAxis, x: x.description, yName: plotter.yAxis, y: y)
//            } else if let y = row[plotter.yAxis] as? CustomStringConvertible {
//                getMark(xName: plotter.xAxis, x: x.description, yName: plotter.yAxis, y: y.description)
//            }
//        }
//    }

    @ChartContentBuilder
    func mark(_ row: DataFrame.Row) -> some ChartContent {
        let x = row[plotter.xAxis]
        let y = row[plotter.yAxis]
        switch (x, y) {
        case let (x, y) as (Double, Double):
            getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
        case let (x, y) as (Double, Int):
            getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
        case let (x, y) as (Double, Date):
            getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
        case let (x, y) as (Double, CustomStringConvertible):
            getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y.description)
        case let (x, y) as (Int, Double):
            getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
        case let (x, y) as (Int, Int):
            getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
        case let (x, y) as (Int, Date):
            getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
        case let (x, y) as (Int, CustomStringConvertible):
            getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y.description)
        case let (x, y) as (Date, Double):
            getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
        case let (x, y) as (Date, Int):
            getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
        case let (x, y) as (Date, Date):
            getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y)
        case let (x, y) as (Date, CustomStringConvertible):
            getMark(xName: plotter.xAxis, x: x, yName: plotter.yAxis, y: y.description)
        case let (x, y) as (CustomStringConvertible, Double):
            getMark(xName: plotter.xAxis, x: x.description, yName: plotter.yAxis, y: y)
        case let (x, y) as (CustomStringConvertible, Int):
            getMark(xName: plotter.xAxis, x: x.description, yName: plotter.yAxis, y: y)
        case let (x, y) as (CustomStringConvertible, Date):
            getMark(xName: plotter.xAxis, x: x.description, yName: plotter.yAxis, y: y)
        case let (x, y) as (CustomStringConvertible, CustomStringConvertible):
            getMark(xName: plotter.xAxis, x: x.description, yName: plotter.yAxis, y: y.description)
        case (_, _):
            getMark(xName: plotter.xAxis, x: "\(String(describing: x))", yName: plotter.yAxis, y: "\(String(describing: y))")
        }
    }

    @ChartContentBuilder
    func getMark<X: Plottable, Y: Plottable>(xName: String, x: X, yName: String, y: Y) -> some ChartContent {
        switch plotter.type {
        case .line:
            LineMark(x: .value(xName, x), y: .value(yName, y))
        case .bar:
            BarMark(x: .value(xName, x), y: .value(yName, y))
        case .pie:
            SectorMark(angle: .value(yName, y))
                .foregroundStyle(by: .value(xName, x))
        case .point:
            PointMark(x: .value(xName, x), y: .value(yName, y))
        }
    }
}

#Preview {
    let dataSet = try! DataFrame(contentsOfCSVFile: Bundle.main.url(forResource: "air_quality_pm25_long", withExtension: "csv")!)
    if #available(iOS 17, *) {
        return PlotterView(plotter: .init(type: .bar, xAxis: "city", yAxis: "value", series: "country"), dataSet: dataSet)
    } else {
        return EmptyView()
    }
}


//extension DataFrame.Row {
//  func renderedComponent(plotter: Plotter) -> some ChartContent {
//    let x = self[plotter.xAxis]
//    let y = self[plotter.yAxis]
//    let xPlottable = x as? (any Plottable) ?? String(describing: x)
//    let yPlottable = y as? (any Plottable) ?? String(describing: y)
//    return AnyChartContent(
//      getMark(plotter: plotter, xName: plotter.xAxis, x: xPlottable, yName: plotter.yAxis, y: yPlottable)
//    )
//  }
//
//  @ChartContentBuilder
//  func getMark<X: Plottable, Y: Plottable>(plotter: Plotter, xName: String, x: X, yName: String, y: Y) -> some ChartContent {
//      switch plotter.type {
//      case .line:
//          LineMark(x: .value(xName, x), y: .value(yName, y))
//      case .bar:
//          BarMark(x: .value(xName, x), y: .value(yName, y))
//      case .pie:
//          SectorMark(angle: .value(yName, y))
//              .foregroundStyle(by: .value(xName, x))
//      case .point:
//          PointMark(x: .value(xName, x), y: .value(yName, y))
//      }
//  }
//}
