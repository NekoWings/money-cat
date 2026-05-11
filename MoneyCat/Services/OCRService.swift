import UIKit
import Vision

struct OCRExtractedItem: Identifiable {
    let id = UUID()
    let name: String
    let amount: Decimal
}

enum OCRServiceError: Error, LocalizedError {
    case imageConversionFailed

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "无法读取图片。"
        }
    }
}

final class OCRService {
    func recognizeReceiptItems(from image: UIImage) async throws -> [OCRExtractedItem] {
        guard let cgImage = image.cgImage else {
            throw OCRServiceError.imageConversionFailed
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "ja-JP", "en-US"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([request])

        let lines: [String] = request.results?
            .compactMap { $0.topCandidates(1).first?.string }
            ?? []

        return ReceiptLineParser.parse(lines: lines)
    }
}

enum ReceiptLineParser {
    static func parse(lines: [String]) -> [OCRExtractedItem] {
        lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .compactMap(parseLine)
    }

    private static func parseLine(_ line: String) -> OCRExtractedItem? {
        let normalized = line
            .replacingOccurrences(of: "，", with: ".")
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "元", with: "")
            .replacingOccurrences(of: "円", with: "")

        guard let amountRange = normalized.range(of: #"([0-9]+(?:\.[0-9]{1,2})?)$"#, options: .regularExpression) else {
            return nil
        }

        let amountString = String(normalized[amountRange])
        guard let amount = Decimal(string: amountString), amount > 0 else {
            return nil
        }

        let title = normalized[..<amountRange.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "")

        guard title.count >= 1 else { return nil }

        let blockedKeywords = ["total", "合计", "小计", "税", "change", "cash", "visa", "master"]
        let lower = title.lowercased()
        if blockedKeywords.contains(where: { lower.contains($0) }) {
            return nil
        }

        return OCRExtractedItem(name: title, amount: amount)
    }
}
