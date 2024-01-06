import SwiftUI
import TabularData
import SwiftData

@available(iOS 17, *)
enum DisplayableNode: Equatable {
    case route(Route)
    case node(Node)

    var title: String {
        switch self {
        case .route:
            "Read CSV"
        case .node(let node):
            node.title
        }
    }

    func toggleStar() {
        switch self {
        case .route(let route):
            route.starred.toggle()
        case .node(let node):
            node.starred.toggle()
        }
    }

    var starred: Bool {
        get {
            switch self {
            case .route(let route):
                route.starred
            case .node(let node):
                node.starred
            }
        }
    }
}

@available(iOS 17, *)
protocol ConvertibleToDisplayableNode {
    func convertToDisplayableNode() -> DisplayableNode
}

@available(iOS 17, *)
extension Route: ConvertibleToDisplayableNode {
    func convertToDisplayableNode() -> DisplayableNode {
        .route(self)
    }
}

@available(iOS 17, *)
extension Node: ConvertibleToDisplayableNode {
    func convertToDisplayableNode() -> DisplayableNode {
        .node(self)
    }
}

@available(iOS 17.0, *)
struct ContentView: View {
    @State private var selectedRoute: Route?
    @State private var displayingNode: DisplayableNode?

    var body: some View {
        NavigationSplitView {
            RouteSelectionView(selectedRoute: $selectedRoute, selectedNode: $displayingNode)
        } content: {
            RouteDisplayChartWrapper(route: selectedRoute, selectedNode: $displayingNode)
                .onChange(of: selectedRoute, initial: true) { oldValue, newValue in
                    if oldValue != newValue {
                        oldValue?.reinit()
                        selectedRoute?.update()
                        if let newValue {
                            displayingNode = .route(newValue)
                        }
                    }
                }
        } detail: {
            NodeDisplayView(node: $displayingNode)
        }
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        return ContentView()
            .modelContainer(previewContainer)
    } else {
        return EmptyView()
    }
}

@available(iOS 17, *)
@MainActor
let previewContainer = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Route.self, Node.self, configurations: config)

    let route1 = Route(name: "Example", url: Bundle.main.url(forResource: "air_quality_no2_long", withExtension: "csv")!)
    container.mainContext.insert(route1)
    let node1 = Node(route: route1, title: "A", reducer: .columnReducer(.double(.singleColumnReducer(.add(.init(column: "value", rhs: 20.0, intoColumn: "mappedColumn1"))))))
    let node11 = Node(head: node1, title: "A", reducer: .columnReducer(.double(.singleColumnReducer(.add(.init(column: "value", rhs: 20.0, intoColumn: "mappedColumn2"))))))
    let node12 = Node(head: node1, title: "A", reducer: .columnReducer(.integer(.singleColumnReducer(.add(.init(column: "value", rhs: 20, intoColumn: "mappedColumn3"))))))
    let node121 = Node(head: node12, title: "A", reducer: .columnReducer(.integer(.singleColumnReducer(.add(.init(column: "value", rhs: 20, intoColumn: "mappedColumn3"))))))
    let node111 = Node(head: node11, title: "A", reducer: .columnReducer(.double(.singleColumnReducer(.add(.init(column: "value", rhs: 20.0, intoColumn: "mappedColumn4"))))))
    let node1111 = Node(head: node111, title: "A", reducer: .columnReducer(.double(.singleColumnReducer(.add(.init(column: "value", rhs: 20.0, intoColumn: "mappedColumn5"))))))
    let node11111 = Node(head: node1111, title: "A", reducer: .columnReducer(.double(.singleColumnReducer(.add(.init(column: "value", rhs: 20.0, intoColumn: "mappedColumn6"))))))
    let node11112 = Node(head: node1111, title: "A", reducer: .columnReducer(.string(.singleColumnReducer(.tryCastDate(.init(column: "date.utc", rhs: "yyyy-MM-dd HH:mm:ssZ", intoColumn: "date"))))))
    let node111121 = Node(head: node11112, title: "A", reducer: .groupByReducer(.date(.init(groupKeyColumn: "date", aggregationOperation: .init(column: "value", operation: .double(.max)), groupByDateComponent: .month))))
    let node13 = Node(head: node1, title: "A", reducer: .selectReducer(.include(["city", "value"])))
    let node14 = Node(head: node1, title: "A", reducer: .summary(.all))
    let node15 = Node(head: node11, title: "A", reducer: .groupByReducer(.any(.init(groupKeyColumn: "city", aggregationOperation: .init(column: "value", operation: .double(.sum))))))

    let route2 = Route(name: "Example2", url: Bundle.main.url(forResource: "air_quality_pm25_long", withExtension: "csv")!)
    container.mainContext.insert(route2)

    return container
}()

extension View {
    @ViewBuilder
    func ifNotNil<T>(
        _ t: T?,
        @ViewBuilder modifier: @escaping (Self, T) -> some View) 
    -> some View {
        if let t {
            modifier(self, t)
        } else {
            self
        }
    }
}
