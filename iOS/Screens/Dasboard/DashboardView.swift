//
//  Created by Andreas Braun on 19.07.20.
//  Copyright © 2020 Andreas Braun. All rights reserved.
//

import BunProKit
import CoreData
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var settingsStore: SettingsStore

    @State private var isPresentingSettings = false
    @State private var isPresentingReview = false
    @State private var isPresentingSelection = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: true) {
                ReviewStatusView()
                    .padding(.horizontal)
                    .onTapGesture {
                        present(website: .review)
                    }
                LevelsSection()
            }
        }
        .navigationBarTitle("Dashboard")
        .navigationBarItems(
            trailing:
                HStack(spacing: 16) {
                    Button(action: {
                        isPresentingSelection = true
                    }, label: {
                        Image.studentdesk
                            .actionSheet(isPresented: $isPresentingSelection) {
                                ActionSheet(
                                    title: Text(""),
                                    message: nil,
                                    buttons: [
                                        .default(Text("Cram")) {
                                            present(website: .cram)
                                        },
                                        .default(Text("Study")) {
                                            present(website: .study)
                                        },
                                        .cancel()
                                    ]
                                )
                            }
                        }
                    )

                    Button(
                        action: {
                            isPresentingSettings = true
                        }, label: {
                            Image.ellipsisCircle
                                .sheet(isPresented: $isPresentingSettings) {
                                    NavigationView {
                                        SettingsView(settingsStore: settingsStore, isPresenting: $isPresentingSettings)
                                            .navigationBarTitle("Settings")
                                            .navigationBarItems(trailing: CloseButton { isPresentingSettings = false })
                                    }
                                }
                        }
                    )
                }
        )
    }

    private func present(website: Website) {
        guard let presentingViewCtrl = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return }
        Server.add(procedure: WebsiteViewControllerProcedure(presentingViewController: presentingViewCtrl, website: website))
    }
}

struct ActionsSection: View {
    let studyAction: () -> Void
    let cramAction: () -> Void

    var body: some View {
        if #available(iOS 14.0, *) {
            VStack {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))]) {
                    ActionButton(label: "Study", action: studyAction)
                    ActionButton(label: "Cram", action: cramAction)
                }
            }
            .padding()
        } else {
            VStack {
                HStack {
                    ActionButton(label: "Study", action: studyAction)
                    ActionButton(label: "Cram", action: cramAction)
                }
            }
        }
    }
}

struct LevelsSection: View {
    @FetchRequest private var allGrammar: FetchedResults<Grammar>

    var body: some View {
        if #available(iOS 14.0, *) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))]) {
                levelButtons
            }
            .padding()
        } else {
            VStack {
                levelButtons
            }
        }
    }

    private var levelButtons: some View {
        Group {
            allButton
            button(named: "N5", level: "JLPT5")
            button(named: "N4", level: "JLPT4")
            button(named: "N3", level: "JLPT3")
            button(named: "N2", level: "JLPT2")
            button(named: "N1", level: "JLPT1")
        }
    }

    private var allButton: some View {
        NavigationLink(
            destination: Text("All")) {
            LevelButton(
                level:
                    Level(
                        name: "All",
                        completedGrammar: (try? Review.reviews(for: allGrammar.sorted()))?.count ?? 0,
                        totalGrammar: allGrammar.count
                    )
            )
        }
    }

    private func button(named name: String, level: String) -> some View {
        NavigationLink(
            destination: Text(name)) {
            LevelButton(
                level:
                    Level(
                        name: name,
                        completedGrammar: (try? Review.reviews(for: allGrammar.filter { $0.level == level }.sorted()))?.count ?? 0,
                        totalGrammar: allGrammar.filter { $0.level == level }.count
                    )
            )
        }
    }

    init() {
        _allGrammar = FetchRequest(fetchRequest: Grammar.fetchRequest(predicate: Self.allGrammarPredicate))
    }

    private static var allGrammarPredicate: NSPredicate {
        NSPredicate(value: true)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
