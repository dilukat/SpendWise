//
//  ReceiptOCRService.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-19.
//

import Foundation
import Vision
import UIKit

enum ReceiptOCRError: LocalizedError {
    case imageUnavailable
    case recognitionFailed

    var errorDescription: String? {
        switch self {
        case .imageUnavailable:
            return "Unable to read the selected receipt image."
        case .recognitionFailed:
            return "Unable to recognize text in this receipt."
        }
    }
}

final class ReceiptOCRService {

    static let shared = ReceiptOCRService()

    private init() {}

    func recognizeText(in image: UIImage) async throws -> [String] {

        guard let cgImage = image.cgImage else {
            throw ReceiptOCRError.imageUnavailable
        }

        return try await Task.detached(
            priority: .userInitiated
        ) {
            let request = VNRecognizeTextRequest()

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            // English language default.
            request.recognitionLanguages = ["en-US"]

            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                options: [:]
            )

            try handler.perform([request])

            guard let observations = request.results else {
                throw ReceiptOCRError.recognitionFailed
            }

            return observations.compactMap {
                $0.topCandidates(1).first?.string
            }
        }.value
    }
}
