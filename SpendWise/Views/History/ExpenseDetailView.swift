//
//  ExpenseDetailView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-13.
//

import SwiftUI
import UIKit
import MapKit

struct ExpenseDetailView: View {
    let expense: Expense

    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Expense amount
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.left.circle.fill")
                        .font(.system(size: 54))
                        .foregroundColor(Color.spendWiseTeal)

                    Text("Expense Amount")
                        .font(.headline)
                        .foregroundColor(Color.spendWiseSecondaryText)

                    Text(
                        (expense.amount as NSNumber),
                        formatter: currencyFormatter
                    )
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(Color.spendWiseText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color.spendWiseCard)
                .cornerRadius(20)

                // Expense details
                VStack(spacing: 0) {
                    detailRow(
                        title: "Category",
                        value: expense.category ?? "Uncategorized",
                        icon: "tag"
                    )

                    Divider()

                    detailRow(
                        title: "Merchant",
                        value: (expense.merchant ?? "").isEmpty
                            ? "Not provided"
                            : expense.merchant ?? "",
                        icon: "storefront"
                    )

                    Divider()

                    detailRow(
                        title: "Date",
                        value: (expense.date ?? Date()).formatted(
                            date: .long,
                            time: .omitted
                        ),
                        icon: "calendar"
                    )

                    Divider()

                    detailRow(
                        title: "Time",
                        value: (expense.date ?? Date()).formatted(
                            date: .omitted,
                            time: .shortened
                        ),
                        icon: "clock"
                    )

//                    Divider()
//
//                    detailRow(
//                        title: "Expense ID",
//                        value: expense.expenseID ?? "Unavailable",
//                        icon: "number"
//                    )
                }
                .padding(.horizontal)
                .background(Color.spendWiseCard)
                .cornerRadius(16)
                
                
                if let coordinate = expenseCoordinate {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Expense Location")
                            .font(.headline)
                            .foregroundColor(Color.spendWiseText)

                        Map(
                            initialPosition: .region(
                                MKCoordinateRegion(
                                    center: coordinate,
                                    span: MKCoordinateSpan(
                                        latitudeDelta: 0.01,
                                        longitudeDelta: 0.01
                                    )
                                )
                            )
                        ) {
                            Marker(
                                expense.merchant?.isEmpty == false
                                    ? expense.merchant!
                                    : "Expense Location",
                                coordinate: coordinate
                            )
                        }
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Label(
                            "Location saved with this expense",
                            systemImage: "location.fill"
                        )
                        .font(.caption)
                        .foregroundColor(Color.spendWiseSecondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.spendWiseCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                
                if let receiptData = expense.receiptData,
                   let savedReceiptImage = UIImage(data: receiptData) {

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Receipt")
                            .font(.headline)
                            .foregroundStyle(Color.spendWiseText)

                        Image(uiImage: savedReceiptImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 320)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 12)
                            )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.spendWiseCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }


                // Delete button
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label(
                        "Delete Expense",
                        systemImage: "trash"
                    )
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .background(Color.spendWiseCard)
                .cornerRadius(12)
            }
            .padding()
        }
        .background(Color.spendWiseBackground)
        .navigationTitle("Expense Details")
        .navigationBarTitleDisplayMode(.inline)

        // Edit button
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    EditExpenseView(expense: expense)
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(Color.spendWiseTeal)
                }
                .accessibilityLabel("Edit Expense")
            }
        }

        .onDisappear {
            NotificationCenter.default.post(
                name: Notification.Name("ExpenseDidChange"),
                object: nil
            )
        }
        
        // Delete confirmation
        .confirmationDialog(
            "Delete this expense?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Expense", role: .destructive) {
                ExpenseViewModel().deleteExpense(expense)

                NotificationCenter.default.post(
                    name: Notification.Name("ExpenseDidChange"),
                    object: nil
                )

                dismiss()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private var expenseCoordinate: CLLocationCoordinate2D? {
        let latitude = expense.latitude
        let longitude = expense.longitude

        // Zero coordinates mean no location was captured.
        guard !(latitude == 0 && longitude == 0),
              latitude.isFinite,
              longitude.isFinite,
              (-90...90).contains(latitude),
              (-180...180).contains(longitude) else {
            return nil
        }

        return CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "LKR"
        formatter.locale = Locale(identifier: "en_LK")
        return formatter
    }

    private func detailRow(
        title: String,
        value: String,
        icon: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color.spendWiseTeal)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color.spendWiseSecondaryText)

                Text(value)
                    .font(.body)
                    .foregroundColor(Color.spendWiseText)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
    }
}

#Preview {
    NavigationStack {
        Text("Select an expense from History to view its details.")
            .navigationTitle("Expense Details")
    }
}
