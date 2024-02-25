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
    @State private var pager: Pager = .init()

    var body: some View {
        TabView(selection: $pager.page) {
            FirstPage()
                .tag(0)
        }
        .tabViewStyle(.page)
        .environment(pager)
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        OnBoardingView()
    } else {
        EmptyView()
    }
}

@available(iOS 17.0, *)
@Observable
class Pager {
    var page: Int = 0

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

                This app is a bookkeeping app based on the **Double-Entry Accounting** method, designed to help users learn and simplify this powerful financial tool so that everyone can use it to manage their finances without prior knowledge of accounting.

                DebitCredit is **easy to use**, even for those without any accounting knowledge. In addition, we also aims to **educate** users about this powerful financial management tool.
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
private struct NextButton: View {
    @Environment(Pager.self) var pager

    var body: some View {
        BottomButton(title: "Next") {
            pager.switchToNextPage()
        }
    }

    @available(iOS 17.0, *)
    private struct BottomButton: View {
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

private struct OnBoardingPage<M: View, I: View, B: View>: View {
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
            Spacer()
            button()
                .padding(.bottom)
        }
    }
}
