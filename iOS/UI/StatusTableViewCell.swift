//
//  Created by Andreas Braun on 06.04.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

final class StatusTableViewCell: UITableViewCell {
    @IBOutlet private var reviewStatusLabel: UILabel!
    @IBOutlet private var reviewStatusNextDateLabel: UILabel!
    @IBOutlet private var reviewStatusLastUpdatedLabel: UILabel!

    @IBOutlet private var reviewNextHourLabel: UILabel!
    @IBOutlet private var reviewNextHourCountLabel: UILabel!
    @IBOutlet private var reviewTomorrowLabel: UILabel!
    @IBOutlet private var reviewTomorrowCountLabel: UILabel!

    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true

        return formatter
    }()

    var isUpdating: Bool = false {
        didSet { isUpdating ? activityIndicatorView.startAnimating() : activityIndicatorView.stopAnimating() }
    }

    var nextReviewsCount: Int = 0

    var nextReviewDate: Date? {
        didSet {
            guard let date = nextReviewDate else { reviewStatusNextDateLabel.text = " "; return }

            if date > Date() {
                reviewStatusLabel.textColor = .label
                reviewStatusLabel.text = L10n.Reviewtime.none
                reviewStatusNextDateLabel.text = dateFormatter.string(from: date)
            } else {
                reviewStatusLabel.textColor = tintColor
                // swiftlint:disable:next dynamic_string_reference
                reviewStatusLabel.text = String.localizedStringWithFormat(NSLocalizedString("reviewtime.next", comment: "The"), nextReviewsCount)
                reviewStatusNextDateLabel.text = L10n.Reviewtime.now
            }
        }
    }
    var lastUpdateDate: Date? {
        didSet {
            guard let date = lastUpdateDate else { reviewStatusLastUpdatedLabel.text = " "; return }
            reviewStatusLastUpdatedLabel.text = "Updated: " + dateFormatter.string(from: date)
        }
    }

    var nextHourReviewCount: Int? {
        didSet {
            guard let nextHourReviewCount = correctedNextHourReviewCount else { reviewNextHourCountLabel.text = " "; return }
            reviewNextHourCountLabel.text = "+\(nextHourReviewCount)"
        }
    }
    private var correctedNextHourReviewCount: Int? {
        guard let nextHourReviewCount = nextHourReviewCount else { return nil }

        let offset = nextReviewDate != nil ? nextReviewDate! > Date() ? 0 : nextReviewsCount : 0
        let difference = nextHourReviewCount - offset

        return difference > 0 ? difference : 0
    }

    var nextDayReviewCount: Int? {
        didSet {
            guard let nextDayReviewCount = correctedNextDayReviewCount else { reviewTomorrowCountLabel.text = " "; return }
            reviewTomorrowCountLabel.text = "+\(nextDayReviewCount)"
        }
    }
    private var correctedNextDayReviewCount: Int? {
        guard let nextDayReviewCount = nextDayReviewCount else { return nil }

        let offset = nextReviewDate != nil ? nextReviewDate! > Date() ? 0 : nextReviewsCount : 0
        let difference = nextDayReviewCount - (correctedNextHourReviewCount ?? 0) - offset

        return difference > 0 ? difference : 0
    }
}
