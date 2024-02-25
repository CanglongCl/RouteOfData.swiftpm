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
    let config: ModelConfiguration
    #if DEBUG
    config = ModelConfiguration(isStoredInMemoryOnly: true)
    #else
    config = ModelConfiguration()
    #endif
    let container = try! ModelContainer(for: Route.self, Node.self, configurations: config)

    insertRouteAirCondition(container: container)
    insertRouteIris(container: container)
    insertRouteMPG(container: container)
    insertRouteApp(container: container)
    insertRouteTips(container: container)
    insertRouteHealthExp(container: container)
    insertRouteTaxis(container: container)

    return container
}()

@available(iOS 17, *)
@MainActor
private func insertRouteAirCondition(container: ModelContainer) {
    let route1 = Route(name: "Air Quality", url: Bundle.main.url(forResource: "air_quality_pm25", withExtension: "csv")!, remark: "The dataset features PM2.5 measurements across various sites over time. Try edit the top **`Read CSV`** node, use **`air_quality_no2`** in example datasets for the same plots but with measurement of NO2.")
    container.mainContext.insert(route1)
    let node1 = Node(from: route1, title: "Cast date string to date", reducer: .columnReducer(.string(.singleColumnReducer(.tryCastDate(.init(column: "date.utc", rhs: "yyyy-MM-dd HH:mm:ssZ", intoColumn: "date"))))))
    let node11 = Node(from: node1, title: "Get Mean Air Quality Value by Day", reducer: .groupByReducer(.init(groupKey: .two(.any(columnName: "city"), .date(columnName: "date", groupByDateComponent: .day)), operation: .init(column: "value", operation: .double(.mean)))))
    let node111 = PlotterNode(from: node11, title: "Mean Air Quality Value of each City by Day", plotter: .init(type: .line, xAxis: "date", yAxis: "mean(value)", series: "city"))
    node111.starred = true
    let node12 = Node(from: node1, title: "Get Mean Air Quality Value of Each City", reducer: .groupByReducer(.init(groupKey: .one(.any(columnName: "city")), operation: .init(column: "value", operation: .double(.mean)))))
    let node121 = PlotterNode(from: node12, title: "Mean Air Quality of Each City", plotter: .init(type: .bar, xAxis: "city", yAxis: "mean(value)", series: "city"))
    node121.starred = true
    let node13 = Node(from: node1, title: "Dataset Summary", reducer: .summary(.all))
}

@available(iOS 17, *)
@MainActor
private func insertRouteIris(container: ModelContainer) {
    let route = Route(name: "Iris", url: Bundle.main.url(forResource: "iris", withExtension: "csv")!, remark: "This datasets consists of 3 different types of irises’ petal and sepal length. Try create a scatter chart to explore the relationship between **`petal_width`** and **`petal_length`** like the given example. ")
    container.mainContext.insert(route)
    let node1 = PlotterNode(from: route, title: "Sepal's length vs sepal's width", plotter: .init(type: .point, xAxis: "sepal_length", yAxis: "sepal_width", series: "species"))
    node1.starred = true
    let node2 = Node(from: route, title: "Summary", reducer: .summary(.all))
    let node3 = Node(from: route, title: "Calculate the average of sepal length", reducer: .groupByReducer(.init(groupKey: .one(.any(columnName: "species")), operation: .init(column: "sepal_length", operation: .double(.mean)))))
    let node31 = PlotterNode(from: node3, title: "Average sepal length of different species", plotter: .init(type: .bar, xAxis: "species", yAxis: "mean(sepal_length)", series: "species"))
    node31.starred = true
}

@available(iOS 17, *)
@MainActor
private func insertRouteMPG(container: ModelContainer) {
    let route = Route(name: "MPG", url: Bundle.main.url(forResource: "mpg", withExtension: "csv")!, remark: "This datasets consists different car model and their features. ")
    container.mainContext.insert(route)
    let node1 = Node(from: route, title: "Calculate mean horsepower", reducer: .groupByReducer(.init(groupKey: .two(.any(columnName: "model_year"), .any(columnName: "origin")), operation: .init(column: "horsepower", operation: .double(.mean)))))
    let node11 = PlotterNode(from: node1, title: "Change of average horsepower in different regions", plotter: .init(type: .line, xAxis: "model_year", yAxis: "mean(horsepower)", series: "origin"))
    node11.starred = true
    let node2 = PlotterNode(from: route, title: "Relationship: fuel consumption and weight", plotter: .init(type: .point, xAxis: "weight", yAxis: "mpg", series: "origin"))
    node2.starred = true
    let node3 = Node(from: route, title: "Calculate new model count in different regions", reducer: .groupByReducer(.init(groupKey: .one(.any(columnName: "origin")), operation: .init(column: "name", operation: .string(.countDifferent)))))
    let node31 = Node(from: node3, title: "Calculate percentage of new model count", reducer: .columnReducer(.integer(.singleColumnReducer(.percentage(.init(column: "aggregate(name)", intoColumn: "aggregate(name)"))))))
    let node311 = PlotterNode(from: node31, title: "Proportion of new model from different regions", plotter: .init(type: .pie, xAxis: "origin", yAxis: "aggregate(name)", series: nil))
    node311.starred = true
}

@available(iOS 17, *)
@MainActor
private func insertRouteTips(container: ModelContainer) {
    let route = Route(name: "Tips", url: Bundle.main.url(forResource: "tips", withExtension: "csv")!, remark: "This dataset contains each tip received from a waiter for a few months. Try find the sum of tips in different **`time`** by aggregation from the top node and then draw a bar chart for it. ")
    container.mainContext.insert(route)
    let node1 = Node(from: route, title: "Calculate average tip of different weekday", reducer: .groupByReducer(.init(groupKey: .one(.any(columnName: "day")), operation: .init(column: "tip", operation: .double(.mean)))))
    let node11 = PlotterNode(from: node1, title: "Average tip in different weekday", plotter: .init(type: .bar, xAxis: "day", yAxis: "mean(tip)", series: "day"))
    node11.starred = true
    let node2 = PlotterNode(from: route, title: "Relationship: Tip and Total Bill", plotter: .init(type: .point, xAxis: "total_bill", yAxis: "tip", series: "time"))
    let node3 = Node(from: route, title: "Calculate Total Paid", reducer: .columnReducer(.double(.multiColumnReducer(.add(.init(lhsColumn: "total_bill", rhsColumn: "tip", intoColumn: "total_paid"))))))
    let node31 = PlotterNode(from: node3, title: "Total Paid in Different Weekday", plotter: .init(type: .bar, xAxis: "day", yAxis: "total_paid", series: "sex"))
}

@available(iOS 17, *)
@MainActor
private func insertRouteHealthExp(container: ModelContainer) {
    let route = Route(name: "Health Expectation", url: Bundle.main.url(forResource: "healthexp", withExtension: "csv")!, remark: "This dataset displays the life expectancy and health spending in countries across years.")
    container.mainContext.insert(route)
    let node1 = Node(from: route, title: "Calculate total spending", reducer: .groupByReducer(.init(groupKey: .two(.any(columnName: "Country"), .any(columnName: "Year")), operation: .init(column: "Spending_USD", operation: .double(.sum)))))
    let node11 = PlotterNode(from: node1, title: "Total Spending in Different Countries", plotter: .init(type: .bar, xAxis: "Country", yAxis: "sum(Spending_USD)", series: "Country"))
    node11.starred = true
    let node12 = PlotterNode(from: node1, title: "Changes of Spending in Different Countries", plotter: .init(type: .line, xAxis: "Year", yAxis: "sum(Spending_USD)", series: "Country"))
    node12.starred = true
    let node2 = Node(from: route, title: "Calculate life expatiation", reducer: .groupByReducer(.init(groupKey: .two(.any(columnName: "Country"), .any(columnName: "Year")), operation: .init(column: "Life_Expectancy", operation: .double(.mean)))))
    let node22 = PlotterNode(from: node2, title: "Changes of Life Expectation in Different Countries", plotter: .init(type: .line, xAxis: "Year", yAxis: "mean(Life_Expectancy)", series: "Country"))
    node22.starred = true
    let node3 = Node(from: route, title: "Calculate if year is 2020", reducer: .columnReducer(.integer(.singleColumnReducer(.equalTo(.init(column: "Year", rhs: 2020, intoColumn: "Year"))))))
    let node31 = Node(from: node3, title: "Filter: only 2020 year's data", reducer: .columnReducer(.boolean(.singleColumnReducer(.filter(.init(column: "Year", intoColumn: "Year"))))))
    let node311 = PlotterNode(from: node31, title: "Life Expectancy in 2020", plotter: Plotter(type: .bar, xAxis: "Country", yAxis: "Life_Expectancy", series: "Country"))
    node311.starred = true
    let node312 = PlotterNode(from: node31, title: "Health Spending in 2020", plotter: Plotter(type: .bar, xAxis: "Country", yAxis: "Spending_USD", series: "Country"))
    node312.starred = true
}

@available(iOS 17, *)
@MainActor
private func insertRouteTaxis(container: ModelContainer) {
    let route = Route(name: "Taxis", url: Bundle.main.url(forResource: "taxis", withExtension: "csv")!, remark: "This dataset contains a series of taxi orders.")
    container.mainContext.insert(route)
    let nodep1 = Node(from: route, title: "Cast date string to date", reducer: .columnReducer(.string(.singleColumnReducer(.tryCastDate(.init(column: "pickup", rhs: "yyyy-MM-dd HH:mm:ss", intoColumn: "pickup"))))))
    let nodep11 = Node(from: nodep1, title: "Cast date string to date", reducer: .columnReducer(.string(.singleColumnReducer(.tryCastDate(.init(column: "dropoff", rhs: "yyyy-MM-dd HH:mm:ss", intoColumn: "dropoff"))))))
    let node1 = Node(from: nodep11, title: "Get total earn by day", reducer: .groupByReducer(.init(groupKey: .two(.date(columnName: "pickup", groupByDateComponent: .day), .any(columnName: "payment")), operation: .init(column: "fare", operation: .double(.sum)))))
    let node11 = PlotterNode(from: node1, title: "Total Earn from varies Payment by Day", plotter: .init(type: .line, xAxis: "pickup", yAxis: "sum(fare)", series: "payment"))
    node11.starred = true
    let node2 = Node(from: nodep11, title: "Calculate if customer gave tip", reducer: .columnReducer(.double(.singleColumnReducer(.moreThan(.init(column: "tip", rhs: 0.0, intoColumn: "with_tip"))))))
    let node21 = Node(from: node2, title: "Filter: order with tip", reducer: .columnReducer(.boolean(.singleColumnReducer(.filter(.init(column: "with_tip", intoColumn: "with_tip"))))))
    let node211 = PlotterNode(from: node21, title: "Relationship: Tip and Distance", plotter: .init(type: .point, xAxis: "distance", yAxis: "tip", series: nil))
    node211.starred = true
    let node22 = Node(from: node2, title: "Get Mean Distance", reducer: .groupByReducer(.init(groupKey: .one(.any(columnName: "with_tip")), operation: .init(column: "distance", operation: .double(.mean)))))
    let node221 = PlotterNode(from: node22, title: "Average Distance with tips versus without tips", plotter: .init(type: .bar, xAxis: "with_tip", yAxis: "mean(distance)", series: "with_tip"))
    node221.starred = true
    let node3 = Node(from: nodep11, title: "Get total earn by day", reducer: .groupByReducer(.init(groupKey: .one(.date(columnName: "pickup", groupByDateComponent: .day)), operation: .init(column: "fare", operation: .double(.sum)))))
    let node31 = PlotterNode(from: node3, title: "Total Earn by Day", plotter: .init(type: .line, xAxis: "pickup", yAxis: "sum(fare)", series: nil))
    node31.starred = true
    let node4 = Node(from: nodep11, title: "Get total earn by payment", reducer: .groupByReducer(.init(groupKey: .one(.any(columnName: "payment")), operation: .init(column: "fare", operation: .double(.sum)))))
    let node41 = Node(from: node4, title: "Fill nil with other", reducer: .columnReducer(.string(.singleColumnReducer(.fillNil(.init(column: "payment", rhs: "other", intoColumn: "payment"))))))
    let node411 = PlotterNode(from: node41, title: "Total Earn by Payment Method", plotter: .init(type: .pie, xAxis: "payment", yAxis: "sum(fare)", series: nil))
    node411.starred = true
}

@available(iOS 17, *)
@MainActor
private func insertRouteApp(container: ModelContainer) {
    let route = Route(name: "App Revenue", url: Bundle.main.url(forResource: "app_financial_report", withExtension: "csv")!, remark: "This dataset shows the revenue of my apps in October 2023, exported from App Store Connect.")
    container.mainContext.insert(route)
    let node1 = Node(from: route, title: "Drop some columns", reducer: .selectReducer(.include(["Quantity", "Partner Share", "Country Of Sale", "Sales or Return"])))
    let node11 = Node(from: node1, title: "Calculate if a row is sale", reducer: .columnReducer(.string(.singleColumnReducer(.equalTo(.init(column: "Sales or Return", rhs: "S", intoColumn: "Sales or Return"))))))
    let node111 = Node(from: node11, title: "Filter: Sales", reducer: .columnReducer(.boolean(.singleColumnReducer(.filter(.init(column: "Sales or Return", intoColumn: ""))))))
    let node1111 = Node(from: node111, title: "Cast Quantity to double for calculation", reducer: .columnReducer(.integer(.singleColumnReducer(.castDouble(.init(column: "Quantity", intoColumn: "Quantity"))))))
    let node11111 = Node(from: node1111, title: "Calculate total earned", reducer: .columnReducer(.double(.multiColumnReducer(.add(.init(lhsColumn: "Quantity", rhsColumn: "Partner Share", intoColumn: "total_earned"))))))
    let node111111 = Node(from: node11111, title: "Calculate total earn by Region", reducer: .groupByReducer(.init(groupKey: .one(.any(columnName: "Country Of Sale")), operation: .init(column: "total_earned", operation: .double(.sum)))))
    let node1111111 = PlotterNode(from: node111111, title: "Total Earned by Region", plotter: .init(type: .pie, xAxis: "Country Of Sale", yAxis: "sum(total_earned)", series: nil))
    node1111111.starred = true
}
