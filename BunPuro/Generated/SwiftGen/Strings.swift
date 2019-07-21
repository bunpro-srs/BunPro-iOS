// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
internal enum L10n {

  internal enum Active {
    /// No
    internal static let no = L10n.tr("Localizable", "active.no")
    /// Yes
    internal static let yes = L10n.tr("Localizable", "active.yes")
  }

  internal enum Copy {
    /// Copy English
    internal static let english = L10n.tr("Localizable", "copy.english")
    /// Copy Japanese
    internal static let japanese = L10n.tr("Localizable", "copy.japanese")
    /// Copy Kana
    internal static let kana = L10n.tr("Localizable", "copy.kana")
    /// Copy Kanji
    internal static let kanji = L10n.tr("Localizable", "copy.kanji")
    /// Copy Meaning
    internal static let meaning = L10n.tr("Localizable", "copy.meaning")
  }

  internal enum Furigana {
    /// Never
    internal static let off = L10n.tr("Localizable", "furigana.off")
    /// Always
    internal static let on = L10n.tr("Localizable", "furigana.on")
    /// WaniKani
    internal static let wanikani = L10n.tr("Localizable", "furigana.wanikani")
  }

  internal enum General {
    /// Cancel
    internal static let cancel = L10n.tr("Localizable", "general.cancel")
  }

  internal enum Kanji {
    internal enum English {
      /// Show English
      internal static let show = L10n.tr("Localizable", "kanji.english.show")
    }
    internal enum Header {
      /// Kanji Readings
      internal static let readings = L10n.tr("Localizable", "kanji.header.readings")
    }
  }

  internal enum Level {
    /// Level %d
    internal static func number(_ p1: Int) -> String {
      return L10n.tr("Localizable", "level.number", p1)
    }
  }

  internal enum Notification {
    internal enum Review {
      /// New Reviews are available.
      internal static let message = L10n.tr("Localizable", "notification.review.message")
      /// You have %d reviews
      internal static func title(_ p1: Int) -> String {
        return L10n.tr("Localizable", "notification.review.title", p1)
      }
    }
  }

  internal enum Review {
    internal enum Edit {
      /// Add to Reviews
      internal static let add = L10n.tr("Localizable", "review.edit.add")
      /// Remove from Reviews
      internal static let remove = L10n.tr("Localizable", "review.edit.remove")
      /// Reset Review Progress
      internal static let reset = L10n.tr("Localizable", "review.edit.reset")
      internal enum Add {
        /// Add
        internal static let short = L10n.tr("Localizable", "review.edit.add.short")
      }
      internal enum Button {
        /// Add to Reviews
        internal static let add = L10n.tr("Localizable", "review.edit.button.add")
        /// Reset/Remove
        internal static let removeReset = L10n.tr("Localizable", "review.edit.button.remove_reset")
      }
      internal enum Remove {
        /// Remove
        internal static let short = L10n.tr("Localizable", "review.edit.remove.short")
      }
      internal enum Reset {
        /// Reset
        internal static let short = L10n.tr("Localizable", "review.edit.reset.short")
      }
    }
  }

  internal enum Reviewtime {
    /// No Reviews
    internal static let `none` = L10n.tr("Localizable", "reviewtime.none")
    /// Now
    internal static let now = L10n.tr("Localizable", "reviewtime.now")
  }

  internal enum Search {
    internal enum Grammar {
      /// Search Grammar
      internal static let placeholder = L10n.tr("Localizable", "search.grammar.placeholder")
      internal enum Scope {
        /// All
        internal static let all = L10n.tr("Localizable", "search.grammar.scope.all")
        /// Learned
        internal static let learned = L10n.tr("Localizable", "search.grammar.scope.learned")
        /// Unlearned
        internal static let unlearned = L10n.tr("Localizable", "search.grammar.scope.unlearned")
      }
    }
  }

  internal enum Settings {
    internal enum Logout {
      /// Logout
      internal static let action = L10n.tr("Localizable", "settings.logout.action")
    }
  }

  internal enum Shortcut {
    internal enum Cram {
      /// Cram time
      internal static let suggetedphrase = L10n.tr("Localizable", "shortcut.cram.suggetedphrase")
      /// Start cramming
      internal static let title = L10n.tr("Localizable", "shortcut.cram.title")
    }
    internal enum Study {
      /// Study time
      internal static let suggetedphrase = L10n.tr("Localizable", "shortcut.study.suggetedphrase")
      /// Start studying
      internal static let title = L10n.tr("Localizable", "shortcut.study.title")
    }
  }

  internal enum State {
    /// Off
    internal static let off = L10n.tr("Localizable", "state.off")
    /// On
    internal static let on = L10n.tr("Localizable", "state.on")
  }

  internal enum Status {
    /// Cram
    internal static let cram = L10n.tr("Localizable", "status.cram")
    /// Last update: %@
    internal static func lastupdate(_ p1: String) -> String {
      return L10n.tr("Localizable", "status.lastupdate", p1)
    }
    /// Loading
    internal static let loading = L10n.tr("Localizable", "status.loading")
    /// Subscribe
    internal static let signup = L10n.tr("Localizable", "status.signup")
    /// Signup for Trial
    internal static let signuptrail = L10n.tr("Localizable", "status.signuptrail")
    /// Study
    internal static let study = L10n.tr("Localizable", "status.study")
  }

  internal enum Subscription {
    /// Yes
    internal static let subscribed = L10n.tr("Localizable", "subscription.subscribed")
    /// Unknown
    internal static let unknown = L10n.tr("Localizable", "subscription.unknown")
    /// No
    internal static let unsubscribed = L10n.tr("Localizable", "subscription.unsubscribed")
  }

  internal enum Tabbar {
    /// Search
    internal static let search = L10n.tr("Localizable", "tabbar.search")
    /// Settings
    internal static let settings = L10n.tr("Localizable", "tabbar.settings")
    /// Status
    internal static let status = L10n.tr("Localizable", "tabbar.status")
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    // swiftlint:disable:next nslocalizedstring_key
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
