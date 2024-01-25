import SwiftData
import SwiftUI
import TabularData

@available(iOS 17, *)
enum DisplayableNode: Equatable {
    case route(Route)
    case node(Node)
    case plot(PlotterNode)

    var title: String {
        switch self {
        case .route:
            "Departure"
        case let .node(node):
            node.title
        case .plot(let node):
            node.title
        }
    }

    func toggleStar() {
        switch self {
        case let .route(route):
            route.starred.toggle()
        case let .node(node):
            node.starred.toggle()
        case .plot(let node):
            node.starred.toggle()
        }
    }

    var starred: Bool {
        switch self {
        case let .route(route):
            route.starred
        case let .node(node):
            node.starred
        case .plot(let node):
            node.starred
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

@available(iOS 17, *)
extension PlotterNode: ConvertibleToDisplayableNode {
    func convertToDisplayableNode() -> DisplayableNode {
        .plot(self)
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
    let node1 = Node(from: route1, title: "A", reducer: .columnReducer(.double(.singleColumnReducer(.add(.init(column: "value", rhs: 20.0, intoColumn: "mappedColumn1"))))))
    let node2 = Node(from: route1, title: "A", reducer: .columnReducer(.string(.singleColumnReducer(.tryCastDate(.init(column: "date.utc", rhs: "yyyy-MM-dd HH:mm:ssZ", intoColumn: "date"))))))
    

    let route2 = Route(name: "Example2", url: Bundle.main.url(forResource: "air_quality_pm25_long", withExtension: "csv")!)

    container.mainContext.insert(route2)

    return container
}()

extension View {
    @ViewBuilder
    func ifNotNil<T>(
        _ t: T?,
        @ViewBuilder modifier: @escaping (Self, T) -> some View
    )
        -> some View
    {
        if let t {
            modifier(self, t)
        } else {
            self
        }
    }
}
