//
//  File.swift
//  
//
//  Created by 戴藏龙 on 2024/2/24.
//

import Foundation
import SwiftUI

@available(iOS 17.0, *)
struct OnBoardingView: View {
    @State var pager: Pager = .init()

    var body: some View {
        TabView(selection: $pager.page) {
            FirstPage()
                .tag(0)
            SecondPage()
                .tag(1)
            ThirdPage()
                .tag(2)
            FourthPage()
                .tag(3)
        }
        .tabViewStyle(.page)
        .environment(pager)
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        OnBoardingView(pager: Pager(page: 3))
    } else {
        EmptyView()
    }
}

@available(iOS 17.0, *)
@Observable
class Pager {
    var page: Int = 0

    init(page: Int) {
        self.page = page
    }

    init() {
        self.page = 0
    }

    func switchToNextPage() {
        page += 1
    }
}

@available(iOS 17.0, *)
private struct FirstPage: View {
    var body: some View {
        OnBoardingPage(title: "About This App") {
            Text(
                """
                Welcome to **Route of Data**!

                Route of Data is a data analysis app that focuses on the processes of data handling and visualization. It boasts a user-friendly interface that simplifies the journey away from repetitive data handling tasks. Whether you're a beginner in data analysis or a seasoned expert, this app enables you to seamlessly automate data processing tasks.

                The inspiration for this software came from my internship experience, where I had to process data with the same structure through repetitive operations every week. Using Excel was time-consuming and inefficient, while Python scripts were overly complex. Route of Data was created in response to these challenges. It not only simplifies the data processing workflow but also significantly reduces the time it takes to prepare reports. **Imagine, with just a few clicks, your data is like cargo loaded onto a truck, efficiently reaching its destination (the analysis result charts) along a preset *Route* (data processing workflow).**

                The core feature of this software is the "Route" function, which allows you to save the entire data processing process so that you can use the same workflow to analyze new data in the future. Simply by changing the data source, you can automatically generate a new analysis report, greatly saving time and effort.
                """
            )
            .multilineTextAlignment(.leading)
            .padding(.horizontal)
        } icon: {
            Image(systemName: "app.gift")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.orange)
        } button: {
            NextButton()
                .padding(.vertical)
        }
    }
}

@available(iOS 17.0, *)
private struct SecondPage: View {
    var body: some View {
        OnBoardingPage(title: "User Interface Introduction 1") {
            Image(.routeOfData1)
                .resizable().scaledToFit()
                .frame(width: 600)
            Text(
                """
                (Never mind! You can come back later if you forget anything. )

                **1. Route Selection**
                Select different "*Routes*", each representing a different data processing process for specific dataset. I've prepare some routes for you to explore but you can also import your own dataset.

                **2. Route Remark**
                Remarks about this Route. Primarily an introduction to the dataset and a guide for exploration. It is recommended to read the Remark and try to follow the guide to explore the data processing method of Route of Data.

                **3. Nodes of Route**
                Each *Node* represents a data processing operation. Clicking on a Node will display the result of that operation on the right side. It is recommended to check all *terminal (bottom) Nodes* of each Route. Meanwhile, *Starred Nodes* are important Nodes, please give them priority attention.

                """
            )
            .multilineTextAlignment(.leading)
            .padding(.horizontal)
        } icon: {
            Image(systemName: "rectangle.3.group")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
        } button: {
            NextButton()
                .padding(.vertical)
        }
    }
}

@available(iOS 17.0, *)
private struct ThirdPage: View {
    var body: some View {
        OnBoardingPage(title: "User Interface Introduction 2") {
            Image(.routeOfData2)
                .resizable().scaledToFit()
                .frame(width: 600)
            Text(
                """
                **1. Node Title**
                Introduces the meaning of the Node's result. Check it first.

                **2. Operation Description**
                Describes the operation performed by this Node on the data from the previous Node.

                **3. Result of the Node**
                The result of the data processing operation, which can be in the form of a table or a chart.

                **4. New or Edit Node**
                Extend a new Node from this Node's basis or edit this Node.
                """
            )
            .multilineTextAlignment(.leading)
            .padding(.horizontal)
        } icon: {
            Image(systemName: "list.bullet.rectangle")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.cyan)
        } button: {
            NextButton()
                .padding(.vertical)
        }
    }
}

@available(iOS 17.0, *)
private struct FourthPage: View {
    var body: some View {
        OnBoardingPage(title: "Ready?") {
            (
                Text(
                    """
                    *Finally, few more tips.*


                    """
                )
                +
                Text("\(Image(systemName: "lightbulb.circle"))")
                    .font(.title)
                    .foregroundColor(.yellow)
                +
                Text("\tTo explore a route, **go over all bottom nodes** (check the node title and result) first. Then check other node to see how the app processes the data.\n\n")
                +
                Text("\(Image(systemName: "magnifyingglass.circle"))")
                    .font(.title)
                    .foregroundColor(.pink)
                +
                Text("\tThen, **explore all example routes** (click bottom on top left to show list) and try exploration challenge in routes' remark. \n\n")
                +
                Text("\(Image(systemName: "rectangle.landscape.rotate"))")
                    .font(.title)
                    .foregroundColor(.blue)
                +
                Text("\tUse **landscape** mode for the best experience.\n\n")
                +
                Text("\(Image(systemName: "questionmark.circle"))")
                    .font(.title)
                    .foregroundColor(.orange)
                +
                Text("\tClick the **question mark** button at any time to return here.\n\n")

            )
            .multilineTextAlignment(.leading)
            .padding(.horizontal)
        } icon: {
            Image(systemName: "flag.checkered.2.crossed")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.orange)
        } button: {
            NextButton.BottomButton(title: "Let's go!") {
                dismiss()
            }
            .padding(.vertical)
        }
    }

    @Environment(\.dismiss) var dismiss
}

@available(iOS 17.0, *)
private struct NextButton: View {
    @Environment(Pager.self) var pager

    var body: some View {
        BottomButton(title: "Next") {
            pager.switchToNextPage()
        }
    }

    @available(iOS 17.0, *)
    struct BottomButton: View {
        let title: String
        let action: () -> ()

        var body: some View {
            Button(title) {
                withAnimation {
                    action()
                }
            }
            .foregroundColor(.blue)
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle)
        }
    }
}

@available(iOS 17.0, *)
private struct OnBoardingPage<M: View, I: View, B: View>: View {
    @Environment(Pager.self) var pager
    let title: AttributedString
    @ViewBuilder
    let message: () -> M
    @ViewBuilder
    let icon: () -> I
    @ViewBuilder
    let button: () -> B

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Spacer()
                    icon()
                    Text(title)
                        .bold()
                        .font(.title)
                        .padding(.vertical)
                    message()
                }
                .padding()
            }
            .scrollIndicatorsFlash(onAppear: true)
            .scrollIndicatorsFlash(trigger: pager.page)
            Spacer()
            button()
                .padding(.bottom)
        }
    }
}
