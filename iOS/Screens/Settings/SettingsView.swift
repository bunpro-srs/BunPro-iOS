//
//  Created by Andreas Braun on 19.07.20.
//  Copyright © 2020 Andreas Braun. All rights reserved.
//

import BunProKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore

    @SwiftUI.State private var isPresentingAbout: Bool = false
    @SwiftUI.State private var isPresentingPrivacy: Bool = false
    @SwiftUI.State private var isPresentingTerms: Bool = false

    @Binding var isPresenting: Bool

    var furiganaDisplayMode: Binding<String> {
        Binding(
            get: { settingsStore.furiganaDisplayMode.localizedString },
            set: { settingsStore.furiganaDisplayMode = BunProKit.FuriganaMode(localizedString: $0) }
        )
    }

    var userInterfaceStyle: Binding<String> {
        Binding(
            get: { settingsStore.uiAppearanceMode.localizedTitle },
            set: { settingsStore.uiAppearanceMode = UserDefaults.UserInterfaceStyle(localizedTitle: $0) }
        )
    }

    init(settingsStore: SettingsStore, isPresenting: Binding<Bool>) {
        self.settingsStore = settingsStore
        _isPresenting = isPresenting
    }

    var body: some View {
        Form {
            ReviewConfigurationSection(
                furiganaDisplayModes: SettingsStore.furiganaDisplayModes,
                selectedFuriganaDisplayMode: furiganaDisplayMode,
                areTranslationsHidden: $settingsStore.areTranslationsHidden,
                isAutomaticAdvancementActive: $settingsStore.isAutomaticAdvancementActive
            )

            Section {
                communityButton
                categoryButton(category: .about, isPresenting: $isPresentingAbout)
                contactButton
                categoryButton(category: .privacy, isPresenting: $isPresentingPrivacy)
                categoryButton(category: .terms, isPresenting: $isPresentingTerms)
            }

            AppConfigurationSection(
                appearanceModes: SettingsStore.appearanceModes,
                selectedAppearance: userInterfaceStyle
            )

            Section {
                Button(LocalizedStringKey.Settings.logout) {
                    isPresenting = false
                    Server.logout()
                }
                .foregroundColor(.white)
                .listRowBackground(Color.red)
            }
        }
    }

    private var communityButton: some View {
        Group {
            if #available(iOS 14.0, *) {
                SwiftUI.Link(LocalizedStringKey.Settings.community, destination: Links.community)
            } else {
                Button(LocalizedStringKey.Settings.community) {
                    UIApplication.shared.open(Links.community, options: [:], completionHandler: nil)
                }
            }
        }
    }

    private var contactButton: some View {
        Group {
            if #available(iOS 14.0, *) {
                SwiftUI.Link(LocalizedStringKey.Settings.contact, destination: Links.contact)
            } else {
                Button(LocalizedStringKey.Settings.contact) {
                    UIApplication.shared.open(Links.contact, options: [:], completionHandler: nil)
                }
            }
        }
    }

    private func categoryButton(category: InformationView.Category, isPresenting: Binding<Bool>) -> some View {
        Button(category.localizedTitle) {
            isPresenting.wrappedValue = true
        }
        .sheet(isPresented: isPresenting) {
            InformationView(isPresenting: isPresenting, category: category)
        }
    }
}

private struct ReviewConfigurationSection: View {
    var furiganaDisplayModes: [String]
    var selectedFuriganaDisplayMode: Binding<String>
    var areTranslationsHidden: Binding<Bool>
    var isAutomaticAdvancementActive: Binding<Bool>

    var body: some View {
        Section {
            Picker(LocalizedStringKey.Settings.Configuration.furigana, selection: selectedFuriganaDisplayMode) {
                ForEach(furiganaDisplayModes, id: \.self) { mode in
                    Text(mode).tag(mode)
                }
            }
            Toggle(LocalizedStringKey.Settings.Configuration.hideTranslation, isOn: areTranslationsHidden)
            Toggle(LocalizedStringKey.Settings.Configuration.automaticAdvancement, isOn: isAutomaticAdvancementActive)
        }
    }
}

private struct AppConfigurationSection: View {
    var appearanceModes: [String]
    var selectedAppearance: Binding<String>

    var body: some View {
        Section {
            Picker(LocalizedStringKey.Settings.Configuration.userInterfaceAppearance, selection: selectedAppearance) {
                ForEach(appearanceModes, id: \.self) { mode in
                    Text(mode).tag(mode)
                }
            }
        }
    }
}
