//
//  APIConfig.swift
//  LEVEL UP — Phase 2
//
//  Resolves the Anthropic API key at runtime. Two sources, in order:
//    1. ANTHROPIC_API_KEY environment variable (set in Xcode scheme).
//    2. A sandboxed file at Application Support/LevelUp/anthropic_key.txt.
//
//  Returning nil means AI features gracefully degrade with an error
//  message rather than crashing.
//

import Foundation

enum APIConfig {

    static var anthropicAPIKey: String? {
        if let env = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"],
           !env.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return env.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let fm = FileManager.default
        if let appSupport = try? fm.url(for: .applicationSupportDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false) {
            let keyFile = appSupport
                .appendingPathComponent("LevelUp")
                .appendingPathComponent("anthropic_key.txt")
            if let contents = try? String(contentsOf: keyFile, encoding: .utf8) {
                let trimmed = contents.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            }
        }
        return nil
    }
}
