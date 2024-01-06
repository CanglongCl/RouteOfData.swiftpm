import SwiftUI
import TabularData

let dataSetURL = Bundle.main.url(forResource: "air_quality_no2_long", withExtension: "csv")!

private let dataSet = try! DataFrame(contentsOfCSVFile: dataSetURL)

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            EmptyView()
        } content: {
            EmptyView()
        } detail: {
            DataFrameTableView(dataSet: dataSet)
        }
    }
}

#Preview {
    ContentView()
}
