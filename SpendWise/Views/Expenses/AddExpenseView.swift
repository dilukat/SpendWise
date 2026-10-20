//
//  AddExpenseView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-09.
//

import SwiftUI
import PhotosUI
import CoreLocation

struct AddExpenseView: View {

    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = ExpenseViewModel()
    @State private var selectedReceipt: PhotosPickerItem?
    @State private var receiptImage: UIImage?
    @State private var isLoadingReceipt = false
    @State private var recognizedReceiptText: [String] = []
    @State private var ocrErrorMessage = ""
    
    @State private var extractedMerchant: String?
    @State private var extractedAmount: Double?
    @State private var extractedDate: Date?
    
    @StateObject private var locationService = LocationService.shared
    @State private var locationMessage = ""

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                // MARK: - Header

                VStack(alignment: .leading, spacing: 6) {

                    Text("Add Expense")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.spendWiseText)

                    Text("Record your spending quickly and easily.")
                        .font(.subheadline)
                        .foregroundStyle(Color.spendWiseSecondaryText)
                }
                
                
                // MARK: - Receipt Image

                VStack(alignment: .leading, spacing: 12) {

                    Text("Receipt")
                        .font(.headline)
                        .foregroundStyle(Color.spendWiseText)

                    PhotosPicker(
                        selection: $selectedReceipt,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack(spacing: 12) {
                            Image(systemName: "receipt")
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Choose Receipt")
                                    .font(.headline)

                                Text("Select a receipt photo to scan")
                                    .font(.caption)
                                    .foregroundStyle(
                                        Color.spendWiseSecondaryText
                                    )
                            }

                            Spacer()

                            Image(systemName: "photo")
                        }
                        .foregroundStyle(Color.spendWiseTeal)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.spendWiseCard)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    Color.spendWiseBorder,
                                    lineWidth: 1
                                )
                        )
                    }
                    
                    if let receiptImage {
                        Image(uiImage: receiptImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 12)
                            )

                        Button(role: .destructive) {
                            selectedReceipt = nil
                            self.receiptImage = nil
                        } label: {
                            Label(
                                "Remove Receipt",
                                systemImage: "trash"
                            )
                        }
                    }

                    if isLoadingReceipt {
                        ProgressView("Loading receipt...")
                    }
                    
                    Button {
                        guard let receiptImage else { return }

                        Task {
                            recognizedReceiptText = []
                            ocrErrorMessage = ""
                            isLoadingReceipt = true

                            defer {
                                isLoadingReceipt = false
                            }

                            do {
                                recognizedReceiptText =
                                    try await ReceiptOCRService.shared
                                        .recognizeText(in: receiptImage)

                                let details = ReceiptDetailsExtractor.extract(
                                    from: recognizedReceiptText
                                )

                                extractedMerchant = details.merchant
                                extractedAmount = details.amount
                                extractedDate = details.date

                                if recognizedReceiptText.isEmpty {
                                    ocrErrorMessage =
                                        "No text found. Try a clearer receipt image."
                                }
                            } catch {
                                ocrErrorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        Label(
                            "Scan Receipt Text",
                            systemImage: "text.viewfinder"
                        )
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.spendWiseTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(receiptImage == nil || isLoadingReceipt)

                    
                    if !recognizedReceiptText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recognized Text")
                                .font(.headline)
                                .foregroundStyle(Color.spendWiseText)

                            ForEach(
                                Array(recognizedReceiptText.enumerated()),
                                id: \.offset
                            ) { _, line in
                                Text(line)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.spendWiseSecondaryText)
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )
                            }
                        }
                        .padding()
                        .background(Color.spendWiseCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    
                    if extractedMerchant != nil ||
                       extractedAmount != nil ||
                       extractedDate != nil {

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Extracted Details")
                                .font(.headline)
                                .foregroundStyle(Color.spendWiseText)

                            if let extractedMerchant {
                                Label(
                                    "Merchant: \(extractedMerchant)",
                                    systemImage: "storefront"
                                )
                            }

                            if let extractedAmount {
                                Label(
                                    "Amount: Rs. \(extractedAmount, specifier: "%.2f")",
                                    systemImage: "banknote"
                                )
                            }

                            if let extractedDate {
                                Label(
                                    "Date: \(extractedDate.formatted(date: .abbreviated, time: .omitted))",
                                    systemImage: "calendar"
                                )
                            }

                            Text("Please verify these suggestions before using them.")
                                .font(.caption)
                                .foregroundStyle(Color.spendWiseSecondaryText)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.spendWiseCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }


                    if !ocrErrorMessage.isEmpty {
                        Text(ocrErrorMessage)
                            .font(.subheadline)
                            .foregroundStyle(Color.spendWiseDanger)
                    }
                    
                    
                    Button {
                        if let extractedMerchant {
                            viewModel.merchant = extractedMerchant
                        }

                        if let extractedAmount {
                            viewModel.amount = String(
                                format: "%.2f",
                                extractedAmount
                            )
                        }
                    } label: {
                        Label(
                            "Use Extracted Details",
                            systemImage: "arrow.down.doc"
                        )
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.spendWiseTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }


                    
                }


                // MARK: - Amount

                VStack(alignment: .leading, spacing: 10) {

                    Text("Amount")
                        .font(.headline)
                        .foregroundStyle(Color.spendWiseText)

                    HStack {

                        Text("Rs.")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.spendWiseSecondaryText)

                        TextField("0.00", text: $viewModel.amount)
                            .font(.title)
                            .fontWeight(.bold)
                            .keyboardType(.decimalPad)
                    }
                    .padding()
                    .background(Color.spendWiseCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color.spendWiseBorder,
                                lineWidth: 1
                            )
                    )
                }

                // MARK: - Category

                VStack(alignment: .leading, spacing: 10) {

                    Text("Category")
                        .font(.headline)
                        .foregroundStyle(Color.spendWiseText)

                    Picker("Category", selection: $viewModel.category) {

                        ForEach(
                            viewModel.categories,
                            id: \.self
                        ) { category in

                            Text(category)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.spendWiseCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color.spendWiseBorder,
                                lineWidth: 1
                            )
                    )
                }

                // MARK: - Merchant

                VStack(alignment: .leading, spacing: 10) {

                    Text("Merchant")
                        .font(.headline)
                        .foregroundStyle(Color.spendWiseText)

                    TextField(
                        "Merchant name (optional)",
                        text: $viewModel.merchant
                    )
                    .padding()
                    .background(Color.spendWiseCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color.spendWiseBorder,
                                lineWidth: 1
                            )
                    )
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Expense Location")
                        .font(.headline)
                        .foregroundColor(.spendWiseText)

                    Button {
                        locationMessage = "Getting your location..."
                        locationService.requestCurrentLocation()
                    } label: {
                        HStack {
                            Image(systemName: "location.fill")

                            Text("Capture Current Location")

                            Spacer()

                            Image(systemName: "arrow.clockwise")
                        }
                        .foregroundColor(.spendWiseTeal)
                        .padding()
                        .background(Color.spendWiseCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .onChange(of: locationService.currentLocation) { _, newLocation in
                        guard let newLocation else { return }

                        viewModel.latitude = newLocation.coordinate.latitude
                        viewModel.longitude = newLocation.coordinate.longitude

                        locationMessage = "Location captured successfully."
                    }

                    if let location = locationService.currentLocation {
                        Text(
                            "Latitude: \(location.coordinate.latitude.formatted(.number.precision(.fractionLength(4))))\nLongitude: \(location.coordinate.longitude.formatted(.number.precision(.fractionLength(4))))"
                        )
                        .font(.caption)
                        .foregroundColor(.spendWiseSecondaryText)
                    } else if !locationMessage.isEmpty {
                        Text(locationMessage)
                            .font(.caption)
                            .foregroundColor(.spendWiseSecondaryText)
                    }
                }
                .padding(.vertical, 8)
                

                // MARK: - Error

                if !viewModel.errorMessage.isEmpty {

                    Text(viewModel.errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(Color.spendWiseDanger)
                }

                // MARK: - Save Button

                Button {

                    viewModel.receiptData = receiptImage?.jpegData(
                        compressionQuality: 0.8
                    )

                    viewModel.saveExpense()

                    NotificationCenter.default.post(
                        name: Notification.Name("ExpenseDidChange"),
                        object: nil
                    )
                    

                } label: {

                    Text("Save Expense")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.spendWiseTeal)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 14)
                        )
                }
            }
            .padding()
        }
        
        .task(id: selectedReceipt) {
            
            recognizedReceiptText = []
            ocrErrorMessage = ""
            extractedMerchant = nil
            extractedAmount = nil
            extractedDate = nil
            
            guard let selectedReceipt else {
                receiptImage = nil
                return
            }

            isLoadingReceipt = true
            defer { isLoadingReceipt = false }

            do {
                if let data = try await selectedReceipt.loadTransferable(
                    type: Data.self
                ),
                let image = UIImage(data: data) {
                    receiptImage = image
                }
            } catch {
                print(
                    "Receipt image loading error: \(error.localizedDescription)"
                )
            }
        }
        
        .background(Color.spendWiseBackground)
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Expense Saved",
            isPresented: $viewModel.showSuccessMessage
        ) {

            Button("Done") {

                dismiss()
            }

        } message: {

            Text("Your expense was saved successfully.")
        }
        
    }
}

#Preview {
    AddExpenseView()
}
