//
//  File.swift
//  
//
//  Created by 戴藏龙 on 2024/1/5.
//

import Foundation
import SwiftUI
import TabularData

@available(iOS 17, *)
struct EditNodeSheet: View {
    init(head: Node.Head, completion: ((Node) -> ())? = nil) {
        self.head = head
        self.node = nil
        self._title = .init(initialValue: "")
        self.completion = completion
    }

    init(editing node: Node, completion: ((Node) -> ())? = nil) {
        self.head = node.head
        self.node = node
        self._reducer = .init(initialValue: node.reducer)
        self._title = .init(initialValue: node.title)
        self.completion = completion
    }

    let head: Node.Head

    let node: Node?

    let completion: ((Node) -> ())?

    @State var title: String

    @State var reducer: AnyReducer?

    private var dataFrame: DataFrame? {
        let status = switch head {
        case .node(let node):
            node.status
        case .route(let route):
            route.status
        }
        if case let .finished(.success(dataFrame)) = status {
            return dataFrame
        } else {
            return nil
        }
    }

    var saveValid: Bool {
        title != "" && reducer != nil
    }

    var body: some View {
        NavigationStack {
            List {
                NodeBasicInfoView(title: $title)
            }
            .navigationTitle(node == nil ? "New Node" : "Edit Node")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(!saveValid)
                }
            }
        }
    }

    func save() {
        if let node {
            node.title = title
            node.reducer = reducer!
            completion?(node)
        } else {
            let node = switch head {
            case .node(let node):
                Node(head: node, title: title, reducer: reducer!)
            case .route(let route):
                Node(route: route, title: title, reducer: reducer!)
            }
            completion?(node)
        }
    }

    @Environment(\.dismiss) private var dismiss
}

struct NodeBasicInfoView: View {
    @Binding var title: String

    var body: some View {
        Section {
            TextField("Node Title", text: $title)
        } header: {
            Text("Title")
                .font(.headline)
        }
    }
}

