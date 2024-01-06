//
//  SwiftUIView.swift
//  
//
//  Created by 戴藏龙 on 2024/1/4.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@available(iOS 17, *)
struct RouteSelectionView: View {
    @Query(sort: \Route.createdDate) private var routes: [Route]

    @Binding var selectedRoute: Route?

    @State var editingRoute: Route?

    var body: some View {
        List(routes, selection: $selectedRoute) { route in
            NavigationLink(value: route) {
                VStack(alignment: .leading) {
                    Text(route.name)
                        .font(.headline)
                    Text(route.url.lastPathComponent)
                    Text("Created at \(route.createdDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        editingRoute = route
                    } label: {
                        Label("Edit", systemImage: "rectangle.and.pencil.and.ellipsis")
                    }
                    .tint(.orange)
                }
            }
        }
        .navigationTitle("Routes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                PopAddRouteSheetButton(route: nil) {
                    Image(systemName: "plus.circle")
                } completion: { route in
                    selectedRoute = route
                }
            }
        }
        .sheet(item: $editingRoute) { route in
            AddRouteSheet(route: route) { route in
                selectedRoute = route
            }
        }
        .onAppear {
            if selectedRoute == nil {
                selectedRoute = routes.first
            }
        }
    }
}

@available(iOS 17, *)
struct PopAddRouteSheetButton<L: View>: View {
    @State var showSheet: Bool = false

    let completion: ((Route) -> ())?

    init(route: Route?, @ViewBuilder label: @escaping () -> L, completion: ((Route) -> ())? = nil) {
        self.label = label
        self.route = route
        self.completion = completion
    }
    let route: Route?
    let label: () -> L

    var body: some View {
        Button {
            showSheet.toggle()
        } label: {
            label()
        }
        .sheet(isPresented: $showSheet, content: {
            AddRouteSheet(route: route)  { route in
                completion?(route)
            }
        })
    }
}

@available(iOS 17, *)
struct AddRouteSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var route: Route?
    let completion: ((Route) -> ())?

    init(route: Route?, completion: ((Route) -> ())? = nil) {
        self.route = route
        if let route {
            self._routeName = .init(initialValue: route.name)
            self._file = .init(initialValue: .success(route.url))
        }
        self.completion = completion
    }

    @State private var file: Result<URL, Error>? {
        didSet {
            if case let .some(.success(url)) = file, routeName.isEmpty {
                routeName = url
                    .deletingPathExtension()
                    .lastPathComponent
                    .replacingOccurrences(of: "_", with: " ")
                    .uppercased()
            }
        }
    }
    @State private var showFileImporter: Bool = false

    @State private var routeName: String = ""

    private var validate: Bool {
        if case .some(.success(_)) = file {
            routeName != ""
        } else {
            false
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Route Name", text: $routeName)
                } header: {
                    Text("Route Name")
                        .font(.headline)
                }

                Section {
                    switch file {
                    case .success(let url):
                        Text("Current Selection: ")
                            .bold()
                        +
                        Text(url.lastPathComponent)
                    case .failure(let error):
                        Text("Error: ")
                            .bold()
                        +
                        Text(error.localizedDescription)
                    case nil:
                        EmptyView()
                    }
                    Button {
                        showFileImporter.toggle()
                    } label: {
                        switch file {
                        case .success(_):
                            Label {
                                Text("Select another CSV Data from File")
                            } icon: {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(.green)
                            }
                        case .failure(_):
                            Label {
                                Text("Re-Try: Select CSV Data from File")
                            } icon: {
                                Image(systemName: "xmark.circle")
                                    .foregroundStyle(.red)
                            }
                        case nil:
                            Button {
                                showFileImporter.toggle()
                            } label: {
                                Label("Select CSV Data from File", systemImage: "square.and.arrow.down")
                            }
                        }
                    }
                    Menu {
                        let options = [
                            Bundle.main.url(forResource: "air_quality_no2_long", withExtension: "csv")!,
                            Bundle.main.url(forResource: "air_quality_pm25_long", withExtension: "csv")!
                        ]
                        ForEach(options, id: \.self) { url in
                            Button(url.lastPathComponent) {
                                file = .success(url)
                            }
                        }
                    } label: {
                        Label("Or Use an Example Data", systemImage: "shippingbox")
                    }
                } header: {
                    Text("CSV Data File")
                        .font(.headline)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        guard case let .some(.success(url)) = file else {
                            dismiss(); return
                        }
                        if let route {
                            route.name = routeName
                            route.url = url
                            completion?(route)
                        } else {
                            let route = Route(name: routeName, url: url)
                            context.insert(route)
                            completion?(route)
                        }
                        dismiss()
                    }
                    .disabled(!validate)
                }
            }
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [UTType(filenameExtension: "csv")!]) { result in
                file = result
            }
            .navigationTitle(route == nil ? "New Route" : "Edit Route")
        }
    }
}
