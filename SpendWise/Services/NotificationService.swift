//
//  NotificationService.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-20.
//


import Foundation
import UserNotifications

final class NotificationService: NSObject,
                                 UNUserNotificationCenterDelegate {

    static let shared = NotificationService()

    private let notificationCenter =
        UNUserNotificationCenter.current()

    private override init() {
        super.init()
        notificationCenter.delegate = self
    }

    // Request permission to show notifications
    func requestPermission() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
            print(
                "Notification permission error: \(error.localizedDescription)"
            )
            return false
        }
    }

    // Check the current notification permission
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    // Send an immediate local notification
    
    func sendNotification(
        title: String,
        body: String,
        identifier: String
    ) async -> Bool {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        do {
            try await notificationCenter.add(request)
            return true
        } catch {
            print(
                "Notification error: \(error.localizedDescription)"
            )
            return false
        }
    }


    // Display notifications while the app is open
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    
    func checkBudgetThresholds(
        spending: Double,
        budget: Double
    ) async {
        guard budget > 0, spending >= 0 else {
            print("Budget alert skipped: invalid budget or spending.")
            return
        }

        let percentage = spending / budget * 100

        print("Monthly spending: \(spending)")
        print("Monthly budget: \(budget)")
        print("Budget usage: \(percentage)%")

        guard percentage >= 80 else {
            print("Budget alert: 80% threshold not reached.")
            return
        }

        let now = Date()
        let calendar = Calendar.current
        let monthKey =
            "\(calendar.component(.year, from: now))-" +
            "\(calendar.component(.month, from: now))"

        print("Budget threshold reached.")

        if percentage >= 100 {
            await sendThresholdNotification(
                threshold: "100",
                monthKey: monthKey,
                title: "Monthly Budget Reached",
                body: "You have reached or exceeded your monthly spending budget."
            )
        } else {
            await sendThresholdNotification(
                threshold: "80",
                monthKey: monthKey,
                title: "Budget Warning",
                body: "You have used at least 80% of your monthly spending budget."
            )
        }
    }
    
    private func sendThresholdNotification(
        threshold: String,
        monthKey: String,
        title: String,
        body: String
    ) async {
        let defaults = UserDefaults.standard
        let key = "budgetAlert_\(monthKey)_\(threshold)"

        if defaults.bool(forKey: key) {
            print("Budget alert skipped: already recorded for \(key)")
            return
        }

        let settings = await notificationCenter.notificationSettings()

        print("Notification authorization: \(settings.authorizationStatus.rawValue)")
        print("Alert key: \(key)")

        guard settings.authorizationStatus == .authorized ||
              settings.authorizationStatus == .provisional else {
            print("Budget alert skipped: notification permission is not authorized.")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: key,
            content: content,
            trigger: nil
        )

        do {
            try await notificationCenter.add(request)
            defaults.set(true, forKey: key)
            print("Budget notification scheduled successfully: \(title)")
        } catch {
            print("Budget notification scheduling failed: \(error.localizedDescription)")
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async -> Bool {
        guard (0...23).contains(hour),
              (0...59).contains(minute) else {
            return false
        }

        let settings = await notificationCenter.notificationSettings()

        guard settings.authorizationStatus == .authorized ||
              settings.authorizationStatus == .provisional else {
            return false
        }

        let content = UNMutableNotificationContent()
        content.title = "Time to Track Your Spending"
        content.body = "Take a moment to record today's expenses in SpendWise."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "spendwise.daily.reminder",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            return true
        } catch {
            print("Daily reminder scheduling error: \(error.localizedDescription)")
            return false
        }
    }

    func cancelDailyReminder() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["spendwise.daily.reminder"]
        )
    }


}
