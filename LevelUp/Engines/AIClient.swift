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

    // MARK: - Milestone Generation

    static func generateMilestones(projectName: String, description: String) async throws -> [String] {
        guard let key = APIConfig.anthropicAPIKey else { throw AIError.missingKey }

        let userPrompt = """
        You are a project planning assistant. Given a project name and description, \
        suggest 5-8 concrete, actionable milestones that would mark meaningful progress. \
        Return ONLY a JSON array of strings, no other text. Example: ["Milestone 1", "Milestone 2"]

        Project: \(projectName)
        Description: \(description.isEmpty ? "No description provided" : description)
        """

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 600,
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

        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArr = obj["content"] as? [[String: Any]],
              let text = contentArr.first(where: { ($0["type"] as? String) == "text" })?["text"] as? String,
              !text.isEmpty
        else {
            throw AIError.emptyResponse
        }

        return try parseMilestoneJSON(text)
    }

    private static func parseMilestoneJSON(_ text: String) throws -> [String] {
        var cleaned = text
        if let fenceRange = cleaned.range(of: "```") {
            cleaned = String(cleaned[fenceRange.upperBound...])
            if cleaned.hasPrefix("json") {
                cleaned = String(cleaned.dropFirst(4))
            }
            if let end = cleaned.range(of: "```") {
                cleaned = String(cleaned[..<end.lowerBound])
            }
        }

        guard let open = cleaned.firstIndex(of: "["),
              let close = cleaned.lastIndex(of: "]"),
              open < close
        else {
            throw AIError.parse("no JSON array found in: \(text)")
        }

        let jsonSlice = String(cleaned[open...close])
        guard let jsonData = jsonSlice.data(using: .utf8) else {
            throw AIError.parse("slice not utf8: \(jsonSlice)")
        }

        let decoded = try JSONDecoder().decode([String].self, from: jsonData)
        return decoded.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    // MARK: - Quick Log (AI Natural Language)

    struct QuickLogResult {
        let type: String
        let confidence: Double
        let summary: String
        let data: [String: Any]
    }

    static func parseQuickLog(input: String, context: String) async throws -> QuickLogResult {
        guard let key = APIConfig.anthropicAPIKey else { throw AIError.missingKey }

        let systemPrompt = """
        You are a quick-log parser for a personal XP tracking app. Parse the user's natural language input into a structured log entry.

        CONTEXT (user's current data):
        \(context)

        RULES:
        1. Match project/course/book/cert names using fuzzy matching against the CONTEXT above. Return the EXACT name from context. If no project matches, set projectName to "" — the entry will be logged as a quick task without a project.
        2. For work: infer actionType from keywords. "deep work"/"focused"/"coding"/"building" → "Deep Work". "meeting"/"call with"/"sync" → "Meeting". "reading"/"researching" → "Research". "admin"/"email"/"organize"/"taxes"/"bills"/"errands" → "Admin". Default to "Other" if unclear.
        3. For gym: ONLY use type "gym" for weight training / split-based workouts (upper, lower, push, pull, legs). Use today's planned split unless the user specifies otherwise. Default intensity to "medium" unless they say easy/light or hard/intense/heavy.
        4. For cardio: ANY non-weight-training physical activity — running, swimming, cycling, HIIT, yoga, walking, sports (cricket, football, basketball, tennis, etc.), hiking, dancing. If the user mentions a sport name or cardio activity, use type "cardio", NOT "gym".
        5. For time: "2 hours"/"2h"/"2hrs" → 2.0. "30 min"/"30m" → 0.5 hours (or 30 minutes for learning). No time for work → 1.0 hours. No time for learning → 30 minutes. No duration for cardio → 30 minutes.
        6. For weight: extract the number in kg.
        7. For food: extract the meal description.
        8. If input is ambiguous or matches nothing, set confidence below 0.5.
        9. For todo/task planning: if the user says "todo", "add task", "remind me to", "plan to", or "need to" — use type "todo". This is a planning item, NOT a work log.

        Return ONLY a JSON object:
        {"type": "work|gym|cardio|learning|weight|food|todo", "confidence": 0.0-1.0, "summary": "human readable confirmation", "data": {...}}

        DATA schemas:
        work: {"projectName": str, "actionType": str, "title": str, "hours": float}
        gym: {"splitDay": str, "intensity": "easy|medium|hard"}
        cardio: {"sport": str, "durationMinutes": int, "intensity": "easy|medium|hard", "distanceKm": float}
        learning: {"learningType": "course|book|certification", "name": str, "durationMinutes": int}
        weight: {"weightKg": float}
        food: {"mealType": "Breakfast|Lunch|Dinner|Snack", "description": str}
        todo: {"title": str}
        """

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 500,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": input]
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

        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArr = obj["content"] as? [[String: Any]],
              let text = contentArr.first(where: { ($0["type"] as? String) == "text" })?["text"] as? String,
              !text.isEmpty
        else {
            throw AIError.emptyResponse
        }

        return try parseQuickLogJSON(text)
    }

    private static func parseQuickLogJSON(_ text: String) throws -> QuickLogResult {
        var cleaned = text
        if let fenceRange = cleaned.range(of: "```") {
            cleaned = String(cleaned[fenceRange.upperBound...])
            if cleaned.hasPrefix("json") { cleaned = String(cleaned.dropFirst(4)) }
            if let end = cleaned.range(of: "```") { cleaned = String(cleaned[..<end.lowerBound]) }
        }

        guard let open = cleaned.firstIndex(of: "{"),
              let close = cleaned.lastIndex(of: "}"),
              open < close
        else {
            throw AIError.parse("no JSON object found in: \(text)")
        }

        let jsonSlice = String(cleaned[open...close])
        guard let jsonData = jsonSlice.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else {
            throw AIError.parse("invalid JSON: \(jsonSlice)")
        }

        let type = dict["type"] as? String ?? "work"
        let confidence = doubleFromAny(dict["confidence"])
        let summary = dict["summary"] as? String ?? "Parsed entry"
        let data = dict["data"] as? [String: Any] ?? [:]

        return QuickLogResult(type: type, confidence: confidence, summary: summary, data: data)
    }

    // MARK: - Helpers

    static func intFromAny(_ value: Any?) -> Int {
        if let i = value as? Int { return i }
        if let d = value as? Double { return Int(d.rounded()) }
        if let s = value as? String, let i = Int(s) { return i }
        if let s = value as? String, let d = Double(s) { return Int(d.rounded()) }
        return 0
    }

    static func doubleFromAny(_ value: Any?) -> Double {
        if let d = value as? Double { return d }
        if let i = value as? Int { return Double(i) }
        if let s = value as? String, let d = Double(s) { return d }
        return 0
    }
}
