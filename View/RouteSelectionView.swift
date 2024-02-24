//
//  RouteSelectionView.swift
//
//
//  Created by 戴藏龙 on 2024/1/4.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

@available(iOS 17, *)
struct RouteSelectionView: View {
    @Environment(\.modelContext) var context
    @Query(sort: \Route.createdDate) private var routes: [Route]

    @Binding var selectedRoute: Route?
    @Binding var selectedNode: DisplayableNode?

    @State var editingRoute: Route?

    @State var deletingRoute: Route?

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
                        deletingRoute = route
                    } label: {
                        Label("Delete", systemImage: "xmark.bin")
                    }
                    .tint(.red)
                    Button {
                        editingRoute = route
                    } label: {
                        Label("Edit", systemImage: "rectangle.and.pencil.and.ellipsis")
                    }
                    .tint(.orange)
                }
            }
        }
        .confirmationDialog("Delete Confirmation", isPresented: .init(get: { deletingRoute != nil }, set: { newValue in
            if !newValue {
                deletingRoute = nil
            }
        }), actions: {
            Button("Delete", role: .destructive, action: {
                if let deletingRoute {
                    if deletingRoute == selectedRoute {
                        selectedRoute = nil
                        selectedNode = nil
                    }
                    context.delete(deletingRoute)
                }
            })
        })
        .navigationTitle("Routes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    addingRoute.toggle()
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .sheet(item: $editingRoute) { route in
            EditRouteSheet(route: route) { route in
                selectedRoute = route
            }
        }
        .sheet(isPresented: $addingRoute, content: {
            EditRouteSheet { route in
                selectedRoute = route
            }
        })
        .onAppear {
            if selectedRoute == nil {
                selectedRoute = routes.first
            }
        }
    }

    @State private var addingRoute: Bool = false
}

@available(iOS 17, *)
struct EditRouteSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var route: Route?
    let completion: ((Route) -> Void)?

    init(route: Route, completion: ((Route) -> Void)? = nil) {
        self.route = route
        _routeName = .init(initialValue: route.name)
        _file = .init(initialValue: .success(route.url))
        self.completion = completion
    }

    init(completion: ((Route) -> Void)? = nil) {
        route = nil
        if let route {
            _routeName = .init(initialValue: route.name)
            _file = .init(initialValue: .success(route.url))
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
    @State private var routeRemark: String = ""

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
                    TextField("Remark", text: $routeRemark)
                } header: {
                    Text("Remark")
                        .font(.headline)
                }

                Section {
                    switch file {
                    case let .success(url):
                        Label {
                            Text("Current Selection: ")
                                .bold()
                                +
                                Text(url.lastPathComponent)
                        } icon: {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(.green)
                        }
                    case let .failure(error):
                        Label {
                            Text("Error: ")
                                .bold()
                                +
                                Text(error.localizedDescription)
                        } icon: {
                            Image(systemName: "xmark.circle")
                                .foregroundStyle(.red)
                        }
                    case nil:
                        EmptyView()
                    }
                    Menu {
                        let options = [
                            Bundle.main.url(forResource: "air_quality_no2", withExtension: "csv")!,
                            Bundle.main.url(forResource: "air_quality_pm25", withExtension: "csv")!,
                            Bundle.main.url(forResource: "iris", withExtension: "csv")!,
                            Bundle.main.url(forResource: "mpg", withExtension: "csv")!,
                            Bundle.main.url(forResource: "penguins", withExtension: "csv")!,
                            Bundle.main.url(forResource: "taxis", withExtension: "csv")!,
                            Bundle.main.url(forResource: "tips", withExtension: "csv")!,
                            Bundle.main.url(forResource: "healthexp", withExtension: "csv")!,
                            Bundle.main.url(forResource: "car_crashes", withExtension: "csv")!,
                        ]
                        ForEach(options, id: \.self) { url in
                            Button(url.lastPathComponent) {
                                file = .success(url)
                            }
                        }
                    } label: {
                        Label("Choose an Example Data", systemImage: "shippingbox")
                    }
                    Button {
                        showFileImporter.toggle()
                    } label: {
                        Label("Or Select CSV Data from File", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("CSV Data File")
                        .font(.headline)
                } footer: {
                    if case .success = file {
                        Text("When changing datasets, it is recommended to import data with the same structure.")
                    }
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
                            DispatchQueue.main.async {
                                completion?(route)
                            }
                            route.update()
                        } else {
                            let route = Route(name: routeName, url: url, remark: routeRemark)
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
