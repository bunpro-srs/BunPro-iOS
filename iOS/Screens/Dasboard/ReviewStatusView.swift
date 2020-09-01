//
//  Created by Andreas Braun on 24.07.20.
//  Copyright © 2020 Andreas Braun. All rights reserved.
//

import BarChart
import Combine
import CoreData
import SwiftUI

final class ReviewStatusStore: ObservableObject {
    @Published private(set) var lastUpdateDate: Date?
    private var transientLastDate: Date?

    private var subscriptions = Set<AnyCancellable>()

    init() {
        NotificationCenter
            .default
            .publisher(for: DataManager.willBeginUpdating, object: nil)
            .sink { _ in
                self.transientLastDate = self.lastUpdateDate
            }
        .store(in: &subscriptions)

        NotificationCenter
            .default
            .publisher(for: DataManager.didEndUpdating, object: nil)
            .sink { _ in
                self.transientLastDate = Date()
                self.lastUpdateDate = self.transientLastDate
            }
        .store(in: &subscriptions)
    }
}

struct ReviewStatusView: View {
    @ObservedObject private var reviewStore: ReviewStatusStore

    @FetchRequest private var upcomingReviews: FetchedResults<Review>

    @State private var isUnfolded: Bool = true

    private let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()

    private let configuration: ChartConfiguration

    init() {
        self.reviewStore = ReviewStatusStore()
        self.configuration = ChartConfiguration()

        let predicate = NSPredicate(
            format: "%K < %@ AND %K == true",
            #keyPath(Review.nextReviewDate),
            Date().tomorrow.tomorrow.nextMidnight as NSDate,
            #keyPath(Review.complete)
        )

        let fetchRequest = Review.fetchRequest(predicate: predicate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Review.updatedDate), ascending: true)]
        fetchRequest.fetchBatchSize = 25

        _upcomingReviews = FetchRequest(fetchRequest: fetchRequest)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill()
                .layoutPriority(1)
                .foregroundColor(Color(UIColor.secondarySystemFill))
                .frame(idealWidth: 500, idealHeight: 80)

            VStack(alignment: isUnfolded ? .center : .leading) {
                HStack {
                    Text("\(upcomingReviews.count) Reviews")
                        .font(.title)
                        .foregroundColor(.accentColor)
                    Spacer()
                }

                if isUnfolded {
                    BarChartView(config: configuration)
                        .frame(height: 200)
                        .onAppear {
                            configuration.data.color = .accentColor
                            configuration.xAxis.labelsColor = Color(.secondaryLabel)
                            configuration.xAxis.ticksColor = .clear
                            configuration.yAxis.labelsColor = Color(.secondaryLabel)
                            configuration.yAxis.ticksColor = Color(.systemGray4)
                            configuration.yAxis.ticksDash = []
                            configuration.yAxis.minTicksSpacing = 30.0
                            configuration.yAxis.formatter = { value, decimals in
                                String(format: "  %.\(decimals)f", value)
                            }

                            configuration.data.entries = generateEntries()
                        }
                }

                Text(lastUpdatedLocalizedString())
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
            .padding()
            .onReceive(orientationChanged) { _ in
                configuration.objectWillChange.send()
            }
            .onAppear {
                configuration.objectWillChange.send()
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.spring()) {
                            isUnfolded.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .rotationEffect(isUnfolded ? .degrees(90) : .zero)
                    }
                    .padding(24)
                    .background(Color.green)
                }
                Spacer()
            }
        }
    }

    private func lastUpdatedLocalizedString() -> String {
        if let date = reviewStore.lastUpdateDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            dateFormatter.doesRelativeDateFormatting = true

            return "Updated: \(dateFormatter.string(from: date))"
        } else {
            return "Updated: Unknown"
        }
    }

    private func generateEntries() -> [ChartDataEntry] {
        var entries = [ChartDataEntry]()
        for data in 0 ..< 12 {
            let date = Calendar.autoupdatingCurrent.date(
                byAdding: .hour,
                value: data + 1,
                to: Date()
            )!

            let dateFormatter = DateFormatter()
            dateFormatter.setLocalizedDateFormatFromTemplate("H")

            // let value = Double.random(in: 0 ..< 75)
            let value = reviewCount(at: date)
            let newEntry = ChartDataEntry(x: dateFormatter.string(from: date), y: Double(value))
            entries.append(newEntry)
        }
        return entries
    }

    private func reviewCount(at date: Date) -> Int {
        upcomingReviews.reviews(in: date ..< date.inOneHour).count
    }
}
struct ReviewButton_Previews: PreviewProvider {
    static var previews: some View {
        ReviewStatusView()
    }
}
