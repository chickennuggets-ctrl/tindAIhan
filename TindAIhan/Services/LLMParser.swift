//
//  LLMParser.swift
//  TindAIhan
//

import Foundation
import Observation

#if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
import MLX
import MLXLLM
import MLXLMCommon
#endif

/// Parser that turns Taglish speech/text into structured utang ledger entries.
/// Supports on-device MLX LLM (when package is linked) and a fast,
/// zero-dependency offline heuristic parser for natural Taglish sentences.
@Observable
final class LLMParser {
    #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
    private var container: ModelContainer?
    #endif

    private(set) var isReady = true
    private(set) var status = "Parser ready"

    private let systemPrompt = """
    You extract sari-sari store credit (utang) entries from Taglish sentences.
    Reply with ONLY one JSON object, no markdown, no explanation:
    {"name": "<customer>", "items": [{"item": "<item>", "qty": <integer>}]}
    Convert number words to integers (isa=1, dalawa=2, tatlo=3, apat=4, lima=5).
    Example input: Utang ni Pedro, isang bigas tsaka dalawang itlog
    Example output: {"name":"Pedro","items":[{"item":"bigas","qty":1},{"item":"itlog","qty":2}]}
    """

    init() {
        self.isReady = true
        self.status = "Parser ready"
    }

    func load() async {
        #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
        status = "Loading language model…"
        do {
            container = try await LLMModelFactory.shared.loadContainer(
                configuration: LLMRegistry.qwen2_5_1_5b
            ) { progress in
                Task { @MainActor in
                    self.status = "Downloading model: \(Int(progress.fractionCompleted * 100))%"
                }
            }
            isReady = true
            status = "Language model ready (MLX)"
        } catch {
            isReady = true
            status = "Offline parser active"
        }
        #else
        isReady = true
        status = "Offline parser ready"
        #endif
    }

    func parse(_ text: String) async throws -> ParsedUtang {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "TindAIhan", code: 1, userInfo: [NSLocalizedDescriptionKey: "Walang text na ipinasok."])
        }

        #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
        if let container {
            do {
                let prompt = systemPrompt
                let raw: String = try await container.perform { context in
                    let input = try await context.processor.prepare(input: UserInput(messages: [
                        ["role": "system", "content": prompt],
                        ["role": "user", "content": trimmed]
                    ]))
                    let result = try MLXLMCommon.generate(
                        input: input,
                        parameters: GenerateParameters(temperature: 0),
                        context: context
                    ) { tokens in tokens.count >= 160 ? .stop : .more }
                    return result.output
                }
                return try Self.extractJSON(from: raw)
            } catch {
                return try Self.heuristicParse(trimmed)
            }
        }
        #endif

        return try Self.heuristicParse(trimmed)
    }

    /// Extract JSON block from LLM output
    static func extractJSON(from raw: String) throws -> ParsedUtang {
        guard let start = raw.firstIndex(of: "{"),
              let end = raw.lastIndex(of: "}"),
              start <= end else {
            throw NSError(domain: "TindAIhan", code: 2, userInfo: [NSLocalizedDescriptionKey: "Model did not return JSON"])
        }
        let jsonSubstring = raw[start...end]
        guard let data = String(jsonSubstring).data(using: .utf8) else {
            throw NSError(domain: "TindAIhan", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON encoding"])
        }
        return try JSONDecoder().decode(ParsedUtang.self, from: data)
    }

    /// Smart offline heuristic parser for natural Taglish sari-sari utterances
    static func heuristicParse(_ input: String) throws -> ParsedUtang {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Extract Customer Name
        var customerName = "Suki"
        let lower = text.lowercased()

        let namePrefixes = [
            "utang ni ", "utang kay ", "palista kay ", "palista ni ",
            "para kay ", "kay ", "ni "
        ]

        var foundPrefixRange: Range<String.Index>?
        for prefix in namePrefixes {
            if let r = lower.range(of: prefix) {
                foundPrefixRange = r
                break
            }
        }

        if let range = foundPrefixRange {
            let remainder = text[range.upperBound...]
            let parts = remainder.components(separatedBy: CharacterSet(charactersIn: ",:-"))
            let candidate = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let words = candidate.split(separator: " ")

            var nameWords: [String] = []
            for w in words {
                let wLower = w.lowercased()
                if isQuantityWord(wLower) || Int(w) != nil {
                    break
                }
                nameWords.append(String(w))
            }

            if !nameWords.isEmpty {
                customerName = nameWords.joined(separator: " ").capitalized
                if let idx = text.range(of: nameWords.joined(separator: " "))?.upperBound {
                    text = String(text[idx...])
                }
            }
        } else if text.contains(":") || text.contains("-") || text.contains(",") {
            let delimiter = text.contains(":") ? ":" : (text.contains("-") ? "-" : ",")
            let comps = text.components(separatedBy: delimiter)
            if comps.count > 1 {
                let candidate = comps[0].trimmingCharacters(in: .whitespacesAndNewlines)
                if !candidate.isEmpty && candidate.count < 30 {
                    customerName = candidate.capitalized
                    text = comps.dropFirst().joined(separator: ",")
                }
            }
        }

        // 2. Parse Items and Quantities
        var cleanedItems = text
        for conj in [" tsaka ", " saka ", " at saka ", " at ", " and ", " + "] {
            cleanedItems = cleanedItems.replacingOccurrences(of: conj, with: ", ", options: .caseInsensitive)
        }

        let itemSegments = cleanedItems.components(separatedBy: ",")
        var lines: [ParsedUtang.Line] = []

        for seg in itemSegments {
            let trimmed = seg.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            var qty = 1
            var itemTokens: [String] = []
            let words = trimmed.split(separator: " ").map(String.init)

            var i = 0
            while i < words.count {
                let word = words[i]
                let lowerWord = word.lowercased()

                if let num = parseQuantity(lowerWord) {
                    qty = num
                    if i + 1 < words.count {
                        let nextWord = words[i + 1].lowercased()
                        if ["na", "ng", "piraso", "pirasong", "kilo", "kilos", "pack", "packs", "can", "cans"].contains(nextWord) {
                            i += 1
                        }
                    }
                } else if !["ng", "muna", "paki", "pakilista", "po", "daw", "tsaka", "saka"].contains(lowerWord) {
                    itemTokens.append(word)
                }
                i += 1
            }

            let itemName = itemTokens.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !itemName.isEmpty {
                lines.append(ParsedUtang.Line(item: itemName.lowercased(), qty: max(1, qty)))
            }
        }

        if lines.isEmpty {
            lines.append(ParsedUtang.Line(item: input, qty: 1))
        }

        return ParsedUtang(name: customerName, items: lines)
    }

    private static func isQuantityWord(_ word: String) -> Bool {
        parseQuantity(word) != nil
    }

    private static func parseQuantity(_ word: String) -> Int? {
        if let direct = Int(word) { return direct }
        switch word {
        case "isa", "isang", "uno": return 1
        case "dalawa", "dalawang", "dos": return 2
        case "tatlo", "tatlong", "tres": return 3
        case "apat", "apat na", "kwatro": return 4
        case "lima", "limang", "singko": return 5
        case "anim", "anim na": return 6
        case "pito", "pitong": return 7
        case "walo", "walong": return 8
        case "siyam", "siyam na": return 9
        case "sampu", "sampung", "diyes": return 10
        case "labing-isa", "labingisa": return 11
        case "labindalawa": return 12
        case "dosenang", "dosena": return 12
        case "beinte", "dalawampu": return 20
        default: return nil
        }
    }
}
