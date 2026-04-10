//
//  AIClient.swift
//  LEVEL UP — Phase 2
//
//  Thin async wrapper around the Anthropic Messages API. Currently
//  exposes one call: `analyzeMeal(_:)` which asks Claude to return a
//  JSON macro estimate for a natural-language meal description.
//
//  Zero dependencies — plain URLSession + Codable. The app sandbox
//  needs `com.apple.security.network.client` for this to work.
//

import Foundation

// MARK: - Meal estimate payload

struct MealEstimate: Codable, Equatable {
    var calories: Int
    var protein: Int
    var carbs: Int
    var fats: Int
    var description: String
}

// MARK: - Client

enum AIClient {

    enum AIError: LocalizedError {
        case missingKey
        case badStatus(Int, String)
        case emptyResponse
        case parse(String)

        var errorDescription: String? {
            switch self {
            case .missingKey:
                return "No Anthropic API key. Set ANTHROPIC_API_KEY in the Xcode scheme or drop the key into ~/Library/Containers/com.yashodev.LevelUp/Data/Library/Application Support/LevelUp/anthropic_key.txt."
            case .badStatus(let code, let body):
                return "Anthropic API returned HTTP \(code): \(body)"
            case .emptyResponse:
                return "Anthropic API returned no content."
            case .parse(let detail):
                return "Could not parse AI response: \(detail)"
            }
        }
    }

    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let model = "claude-sonnet-4-6"

    // MARK: Public API

    static func analyzeMeal(_ description: String) async throws -> MealEstimate {
        guard let key = APIConfig.anthropicAPIKey else { throw AIError.missingKey }

        let userPrompt = "Analyze this meal and return ONLY a JSON object with these fields: calories (Int), protein (Int), carbs (Int), fats (Int), description (String). Meal: \(description)"

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 400,
            "messages": [
                ["role": "user", "content": userPrompt]
            ]
        ]

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)

        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let bodyText = String(data: data, encoding: .utf8) ?? "<binary>"
            throw AIError.badStatus(http.statusCode, bodyText)
        }

        // Anthropic response shape: { content: [ { type: "text", text: "..." }, ... ] }
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArr = obj["content"] as? [[String: Any]],
              let text = contentArr.first(where: { ($0["type"] as? String) == "text" })?["text"] as? String,
              !text.isEmpty
        else {
            throw AIError.emptyResponse
        }

        return try parseMealJSON(text)
    }

    // MARK: - JSON extraction

    /// Pulls a MealEstimate out of Claude's text content. Handles markdown
    /// code fences and any prose surrounding the JSON object.
    private static func parseMealJSON(_ text: String) throws -> MealEstimate {
        // Strip ```json ... ``` fences if present.
        var cleaned = text
        if let fenceRange = cleaned.range(of: "```") {
            // Drop anything before the first fence, then the fence marker itself.
            cleaned = String(cleaned[fenceRange.upperBound...])
            if cleaned.hasPrefix("json") {
                cleaned = String(cleaned.dropFirst(4))
            }
            if let end = cleaned.range(of: "```") {
                cleaned = String(cleaned[..<end.lowerBound])
            }
        }

        // Extract substring between first `{` and last `}`.
        guard let open = cleaned.firstIndex(of: "{"),
              let close = cleaned.lastIndex(of: "}"),
              open < close
        else {
            throw AIError.parse("no JSON object found in: \(text)")
        }

        let jsonSlice = String(cleaned[open...close])
        guard let jsonData = jsonSlice.data(using: .utf8) else {
            throw AIError.parse("slice not utf8: \(jsonSlice)")
        }

        do {
            return try JSONDecoder().decode(MealEstimate.self, from: jsonData)
        } catch {
            // Fall back to a more forgiving parse — Claude occasionally
            // returns numbers as strings or includes extra keys.
            if let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                let cals = intFromAny(dict["calories"])
                let prot = intFromAny(dict["protein"])
                let carb = intFromAny(dict["carbs"])
                let fats = intFromAny(dict["fats"])
                let desc = (dict["description"] as? String) ?? ""
                return MealEstimate(calories: cals, protein: prot, carbs: carb, fats: fats, description: desc)
            }
            throw AIError.parse("\(error.localizedDescription) — slice: \(jsonSlice)")
        }
    }

    private static func intFromAny(_ value: Any?) -> Int {
        if let i = value as? Int { return i }
        if let d = value as? Double { return Int(d.rounded()) }
        if let s = value as? String, let i = Int(s) { return i }
        if let s = value as? String, let d = Double(s) { return Int(d.rounded()) }
        return 0
    }
}
