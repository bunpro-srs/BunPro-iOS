//
//  Created by Andreas Braun on 19.07.20.
//  Copyright © 2020 Andreas Braun. All rights reserved.
//

import BunProKit
import Combine
import Foundation

final class SettingsStore: ObservableObject {
    @Published var furiganaDisplayMode: BunProKit.FuriganaMode = .wanikani
    @Published var areTranslationsHidden: Bool = false
    @Published var isAutomaticAdvancementActive: Bool = false
    @Published var uiAppearanceMode: UserDefaults.UserInterfaceStyle = .system

    static var furiganaDisplayModes: [String] = BunProKit.FuriganaMode.allCases.map { $0.localizedString }
    static var appearanceModes: [String] = UserDefaults.UserInterfaceStyle.allCases.map { $0.localizedTitle }

    private var subscriptions = Set<AnyCancellable>()

    init() {
        self.update()

        $furiganaDisplayMode
            .sink { [weak self] _ in self?.updateSettings() }
            .store(in: &subscriptions)
        $areTranslationsHidden
            .sink { [weak self] _ in self?.updateSettings() }
            .store(in: &subscriptions)
        $isAutomaticAdvancementActive
            .sink { [weak self] _ in self?.updateSettings() }
            .store(in: &subscriptions)
        $uiAppearanceMode
            .assign(to: \.userInterfaceStyle, on: UserDefaults.standard)
            .store(in: &subscriptions)
    }

    private func update() {
        if let account = Account.currentAccount {
            self.furiganaDisplayMode = BunProKit.FuriganaMode(string: account.furiganaMode ?? "") ?? .wanikani
            self.areTranslationsHidden = account.englishMode
            self.isAutomaticAdvancementActive = account.bunnyMode
        }

        uiAppearanceMode = UserDefaults.standard.userInterfaceStyle
    }

    private func updateSettings() {
        let settings = SetSettingsProcedure.Settings(
            furigana: furiganaDisplayMode,
            english: areTranslationsHidden ? .yes : .no,
            bunnyMode: isAutomaticAdvancementActive
        )

        AppDelegate.dataManager?.updateSettings(settings)
    }
}
