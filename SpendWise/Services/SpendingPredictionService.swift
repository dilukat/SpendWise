//
//  SpendingPredictionService.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-19.
//

import Foundation
import CoreData
import CoreML
import FirebaseAuth

struct MonthlySpending: Identifiable {
    let month: Date
    let total: Double

    var id: Date { month }
}

@MainActor
final class SpendingPredictionService {

    static let shared = SpendingPredictionService()

    private var mlModel: MLModel?

    private init() {
        do {
            let configuration = MLModelConfiguration()
            mlModel = try SpendingPredictionModelV3(
                configuration: configuration
            ).model
        } catch {
            print("Unable to load spending model: \(error.localizedDescription)")
        }
    }

    // MARK: - Fetch Monthly Spending History

    func fetchMonthlySpendingHistory(
        months: Int = 6,
        now: Date = Date()
    ) -> [MonthlySpending] {

        guard months > 0 else { return [] }

        let context = CoreDataService.shared.viewContext
        let calendar = Calendar.current

        guard let currentMonthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now)
        ),
        let firstMonthStart = calendar.date(
            byAdding: .month,
            value: -(months - 1),
            to: currentMonthStart
        ),
        let nextMonthStart = calendar.date(
            byAdding: .month,
            value: 1,
            to: currentMonthStart
        ) else {
            return []
        }

        let request = NSFetchRequest<Expense>(entityName: "Expense")
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            return []
        }

        request.predicate = NSPredicate(
            format: "userID == %@ AND date >= %@ AND date < %@",
            userID,
            firstMonthStart as NSDate,
            nextMonthStart as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: true)
        ]

        do {
            let expenses = try context.fetch(request)
            var spendingByMonth: [Date: Double] = [:]

            for expense in expenses {
                guard let expenseDate = expense.date,
                      let monthStart = calendar.date(
                        from: calendar.dateComponents(
                            [.year, .month],
                            from: expenseDate
                        )
                      ) else {
                    continue
                }

                spendingByMonth[monthStart, default: 0] += expense.amount
            }

            var history: [MonthlySpending] = []

            for offset in 0..<months {
                guard let monthStart = calendar.date(
                    byAdding: .month,
                    value: offset,
                    to: firstMonthStart
                ) else {
                    continue
                }

                history.append(
                    MonthlySpending(
                        month: monthStart,
                        total: spendingByMonth[monthStart] ?? 0
                    )
                )
            }

            return history

        } catch {
            print("History fetch error: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Predict Monthly Spending
    
    func predictMonthlySpending(
        now: Date = Date()
    ) -> Double? {

        let calendar = Calendar.current

        guard let dayRange = calendar.range(
            of: .day,
            in: .month,
            for: now
        ) else {
            return nil
        }

        let daysElapsed = calendar.component(.day, from: now)
        let daysInMonth = dayRange.count

        guard let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now)
        ),
        let nextMonthStart = calendar.date(
            byAdding: .month,
            value: 1,
            to: monthStart
        ) else {
            return nil
        }

        // Fetch actual spending recorded in the current month.
        let request = NSFetchRequest<Expense>(entityName: "Expense")
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            return nil
        }

        request.predicate = NSPredicate(
            format: "userID == %@ AND date >= %@ AND date < %@",
            userID,
            monthStart as NSDate,
            nextMonthStart as NSDate
        )

        let currentSpending: Double

        do {
            let expenses = try CoreDataService.shared.viewContext.fetch(request)
            currentSpending = expenses.reduce(0.0) {
                $0 + $1.amount
            }
        } catch {
            print("Current spending fetch error: \(error.localizedDescription)")
            return nil
        }

        // No spending yet: there is not enough data for a useful forecast.
        guard currentSpending > 0 else {
            return nil
        }

        // Calculate a baseline based on the current spending pace.
        let baselinePrediction =
            (currentSpending / Double(daysElapsed)) * Double(daysInMonth)

        // History order: two months ago, previous month, current month.
        let history = fetchMonthlySpendingHistory(
            months: 3,
            now: now
        )

        guard history.count == 3 else {
            return baselinePrediction
        }

        let twoMonthsAgoSpending = history[0].total
        let previousMonthSpending = history[1].total

        // New users may not have enough recorded history for the ML model.
        // Use the baseline until both previous months have recorded spending.
        guard previousMonthSpending > 0,
              twoMonthsAgoSpending > 0 else {
            print("Using baseline prediction: insufficient spending history.")
            return baselinePrediction
        }

        // Use Core ML when historical spending is available.
        guard let model = mlModel else {
            print("Spending model unavailable. Using baseline prediction.")
            return baselinePrediction
        }

        let inputValues: [String: MLFeatureValue] = [
            "daysElapsed": MLFeatureValue(
                int64: Int64(daysElapsed)
            ),
            "daysInMonth": MLFeatureValue(
                int64: Int64(daysInMonth)
            ),
            "spendingSoFar": MLFeatureValue(
                int64: Int64(currentSpending.rounded())
            ),
            "previousMonthSpending": MLFeatureValue(
                int64: Int64(previousMonthSpending.rounded())
            ),
            "twoMonthsAgoSpending": MLFeatureValue(
                int64: Int64(twoMonthsAgoSpending.rounded())
            )
        ]

        do {
            let provider = try MLDictionaryFeatureProvider(
                dictionary: inputValues
            )

            let prediction = try model.prediction(from: provider)

            guard let output = prediction.featureValue(
                for: "actualMonthlyTotal"
            ) else {
                print("Prediction output missing. Using baseline.")
                return baselinePrediction
            }

            let predictedAmount = output.doubleValue

            guard predictedAmount.isFinite,
                  predictedAmount >= currentSpending else {
                print("Invalid or implausible model prediction. Using baseline.")
                return baselinePrediction
            }

            print("Core ML prediction: \(predictedAmount)")
            return predictedAmount

        } catch {
            print("Prediction error: \(error.localizedDescription)")
            return baselinePrediction
        }
    }
    
    
    
//    func testV3Model() {
//        guard let model = mlModel else {
//            print("V3 model is unavailable.")
//            return
//        }
//
//        // Same 13 rows as SpendingTestingDataV3.csv.
//        // Each row: daysElapsed, daysInMonth, spendingSoFar,
//        // previousMonthSpending, twoMonthsAgoSpending, actualMonthlyTotal.
//        let testCases: [(Int64, Int64, Int64, Int64, Int64, Double)] = [
//            (10, 30, 10000, 0, 0, 30000),
//            (20, 30, 20000, 0, 0, 30000),
//            (25, 31, 20000, 0, 0, 24800),
//            (10, 30, 9000, 15000, 18000, 28000),
//            (20, 30, 19000, 15000, 18000, 28000),
//            (15, 31, 21000, 25000, 22000, 45000),
//            (25, 31, 35000, 25000, 22000, 45000),
//            (10, 30, 18000, 40000, 42000, 50000),
//            (20, 30, 34000, 40000, 42000, 50000),
//            (15, 31, 36000, 60000, 55000, 70000),
//            (25, 31, 60000, 60000, 55000, 70000),
//            (10, 30, 4000, 8000, 10000, 12000),
//            (20, 30, 8000, 8000, 10000, 12000)
//        ]
//
//        var mlAbsoluteErrors: [Double] = []
//        var mlSquaredErrors: [Double] = []
//        var mlMaxError: Double = 0
//
//        var baselineAbsoluteErrors: [Double] = []
//        var baselineSquaredErrors: [Double] = []
//        var baselineMaxError: Double = 0
//
//        print("========== V3 vs BASELINE ==========")
//
//        for (index, item) in testCases.enumerated() {
//            let (days, monthDays, spent, previous, older, actual) = item
//
//            let baseline =
//                Double(spent) / Double(days) * Double(monthDays)
//
//            let inputs: [String: MLFeatureValue] = [
//                "daysElapsed": MLFeatureValue(int64: days),
//                "daysInMonth": MLFeatureValue(int64: monthDays),
//                "spendingSoFar": MLFeatureValue(int64: spent),
//                "previousMonthSpending": MLFeatureValue(int64: previous),
//                "twoMonthsAgoSpending": MLFeatureValue(int64: older)
//            ]
//
//            do {
//                let provider = try MLDictionaryFeatureProvider(
//                    dictionary: inputs
//                )
//
//                let prediction = try model.prediction(from: provider)
//
//                guard let output = prediction.featureValue(
//                    for: "actualMonthlyTotal"
//                ) else {
//                    print("Test \(index + 1): missing model output")
//                    return
//                }
//
//                let predicted = output.doubleValue
//
//                guard predicted.isFinite else {
//                    print("Test \(index + 1): invalid prediction")
//                    return
//                }
//
//                let mlError = predicted - actual
//                let baselineError = baseline - actual
//
//                mlAbsoluteErrors.append(abs(mlError))
//                mlSquaredErrors.append(mlError * mlError)
//                mlMaxError = max(mlMaxError, abs(mlError))
//
//                baselineAbsoluteErrors.append(abs(baselineError))
//                baselineSquaredErrors.append(baselineError * baselineError)
//                baselineMaxError = max(
//                    baselineMaxError,
//                    abs(baselineError)
//                )
//
//                print("""
//                Test \(index + 1):
//                  Actual: \(actual)
//                  V3: \(predicted)
//                  Baseline: \(baseline)
//                """)
//
//            } catch {
//                print(
//                    "V3 prediction failed on test \(index + 1): " +
//                    error.localizedDescription
//                )
//                return
//            }
//        }
//
//        let count = Double(testCases.count)
//
//        let mlMAE = mlAbsoluteErrors.reduce(0, +) / count
//        let mlRMSE = sqrt(mlSquaredErrors.reduce(0, +) / count)
//
//        let baselineMAE = baselineAbsoluteErrors.reduce(0, +) / count
//        let baselineRMSE = sqrt(
//            baselineSquaredErrors.reduce(0, +) / count
//        )
//
//        print("========== FINAL METRICS ==========")
//        print("Test cases: \(testCases.count)")
//        print("V3 MAE: \(mlMAE)")
//        print("V3 RMSE: \(mlRMSE)")
//        print("V3 maximum error: \(mlMaxError)")
//        print("-----------------------------------")
//        print("Baseline MAE: \(baselineMAE)")
//        print("Baseline RMSE: \(baselineRMSE)")
//        print("Baseline maximum error: \(baselineMaxError)")
//        print("===================================")
//    }



}

