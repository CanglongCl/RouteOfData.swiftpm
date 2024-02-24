import SwiftData
import SwiftUI

@available(iOS 17, *)
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(releaseContainer)
    }
}

@available(iOS 17, *)
@MainActor
let releaseContainer = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Route.self, Node.self, configurations: config)

    insertRoute1(container: container)

    return container
}()

@available(iOS 17, *)
@MainActor
private func insertRoute1(container: ModelContainer) {
    let route1 = Route(name: "Air Quality", url: Bundle.main.url(forResource: "air_quality_no2", withExtension: "csv")!, remark: "The dataset features PM2.5 measurements across various sites over time. Switch the top `Read CSV` node to `air_quality_no2` from example datasets for the same plots without alterations.")
    container.mainContext.insert(route1)
    let node1 = Node(from: route1, title: "Cast date string to date", reducer: .columnReducer(.string(.singleColumnReducer(.tryCastDate(.init(column: "date.utc", rhs: "yyyy-MM-dd HH:mm:ssZ", intoColumn: "date"))))))
    let node11 = Node(from: node1, title: "Get Mean Air Quality Value by Day", reducer: .groupByReducer(.init(groupKey: .two(.any(columnName: "city"), .date(columnName: "date", groupByDateComponent: .day)), operation: .init(column: "value", operation: .double(.mean)))))
    let node111 = PlotterNode(from: node11, title: "Mean Air Quality Value of Each City by Day", plotter: .init(type: .line, xAxis: "date", yAxis: "mean(value)", series: "city"))
    node111.starred = true
    let node12 = Node(from: node1, title: "Get Mean Air Quality Value of Each City", reducer: .groupByReducer(.init(groupKey: .one(.any(columnName: "city")), operation: .init(column: "value", operation: .double(.mean)))))
    let node121 = PlotterNode(from: node12, title: "Mean Air Quality of Each City", plotter: .init(type: .bar, xAxis: "city", yAxis: "mean(value)", series: "city"))
    node121.starred = true
    let node13 = Node(from: node1, title: "Dataset Summary", reducer: .summary(.all))
}
