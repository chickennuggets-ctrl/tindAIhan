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
            // Tagalog
            "pabili po para kay ", "pabili kay ", "lista kay ", "lista ni ",
            "utang ni ", "utang kay ", "palista kay ", "palista ni ",
            "para kay ", "kay ", "ni ",
            // English
            "credit for ", "credit to ", "credit of ",
            "debt of ", "debt for ", "charge to ",
            "put on tab for ", "tab for ", "tab of ",
            "list for ", "utang of ", "utang for ", "for "
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

        // Check if starts with Filipino honorifics: Aling, Mang, Kuya, Ate, Tita, Tito, Nanay, Tatay, Ka, Lola, Lolo, Mr, Mrs
        if customerName == "Suki" {
            let honorifics = ["aling ", "mang ", "kuya ", "ate ", "tita ", "tito ", "nanay ", "tatay ", "ka ", "lola ", "lolo ", "mr. ", "mr ", "mrs. ", "mrs "]
            for h in honorifics {
                if text.lowercased().hasPrefix(h) {
                    let words = text.split(separator: " ").map(String.init)
                    var nameParts: [String] = []
                    for w in words {
                        let wLower = w.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ",:-"))
                        if isQuantityWord(wLower) || Int(wLower) != nil {
                            break
                        }
                        nameParts.append(w.trimmingCharacters(in: CharacterSet(charactersIn: ",:-")))
                    }
                    if !nameParts.isEmpty {
                        customerName = nameParts.joined(separator: " ").capitalized
                        if let idx = text.range(of: nameParts.joined(separator: " "))?.upperBound {
                            text = String(text[idx...])
                        }
                    }
                    break
                }
            }
        }

        // Check if leading word is a customer name before the first quantity word (e.g. "Pedro 2 itlog" or "Pedro 2 eggs")
        if customerName == "Suki" {
            let words = text.split(separator: " ").map(String.init)
            if words.count >= 2 {
                let firstWord = words[0].trimmingCharacters(in: CharacterSet(charactersIn: ",:-"))
                let secondWord = words[1].lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ",:-"))
                if (isQuantityWord(secondWord) || Int(secondWord) != nil) && !isQuantityWord(firstWord.lowercased()) {
                    customerName = firstWord.capitalized
                    text = words.dropFirst().joined(separator: " ")
                }
            }
        }

        // Check trailing name (e.g. "2 itlog tsaka 1 bigas ni Aling Nena" or "two eggs and one rice for John")
        if customerName == "Suki" {
            for suffix in [" para kay ", " kay ", " ni ", " for ", " credit to ", " debt of "] {
                if let r = text.lowercased().range(of: suffix, options: .backwards) {
                    let candidate = text[r.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                    let words = candidate.split(separator: " ")
                    if !words.isEmpty && words.count <= 3 {
                        customerName = candidate.capitalized
                        text = String(text[..<r.lowerBound])
                        break
                    }
                }
            }
        }

        // 2. Parse Items and Quantities
        var cleanedItems = text
        for conj in [" tsaka ", " saka ", " at saka ", " at ", " and ", " plus ", " + ", " & ", " with "] {
            cleanedItems = cleanedItems.replacingOccurrences(of: conj, with: ", ", options: .caseInsensitive)
        }

        let itemSegments = cleanedItems.components(separatedBy: ",")
        var lines: [ParsedUtang.Line] = []

        let unitCounters = [
            "na", "ng", "piraso", "pirasong", "kilo", "kilong", "kilos", "kg", "kgs",
            "pack", "packs", "can", "cans", "lata", "latang", "bote", "boteng",
            "balot", "sachet", "sachets", "kaban", "piece", "pieces", "pcs", "pc",
            "bottle", "bottles", "box", "boxes", "bar", "bars", "bag", "bags"
        ]

        let fillerWords = [
            "ng", "muna", "paki", "pakilista", "po", "daw", "raw", "tsaka", "saka", "at",
            "naman", "nga", "pala", "please", "of", "and", "also", "the", "a", "an"
        ]

        for seg in itemSegments {
            let trimmed = seg.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            var qty = 1
            var itemTokens: [String] = []
            let words = trimmed.split(separator: " ").map(String.init)

            var i = 0
            while i < words.count {
                let word = words[i].trimmingCharacters(in: CharacterSet(charactersIn: ",.-"))
                let lowerWord = word.lowercased()

                if let num = parseQuantity(lowerWord) {
                    qty = num
                    if i + 1 < words.count {
                        let nextWord = words[i + 1].lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ",.-"))
                        if unitCounters.contains(nextWord) {
                            i += 1
                        }
                    }
                } else if !fillerWords.contains(lowerWord) {
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
        // Tagalog / Spanish
        case "isa", "isang", "uno": return 1
        case "dalawa", "dalawang", "dos": return 2
        case "tatlo", "tatlong", "tres": return 3
        case "apat", "apat na", "kwatro": return 4
        case "lima", "limang", "singko": return 5
        case "anim", "anim na", "sais": return 6
        case "pito", "pitong", "syete": return 7
        case "walo", "walong", "otso": return 8
        case "siyam", "siyam na", "nuwebe": return 9
        case "sampu", "sampung", "diyes": return 10
        case "labing-isa", "labingisa", "onse": return 11
        case "labindalawa", "dose", "dosena", "dosenang": return 12
        case "labintatlo", "trese": return 13
        case "labing-apat", "katorse": return 14
        case "labinlima", "kinse": return 15
        case "dalawampu", "dalawampung", "beinte": return 20
        case "tatlumpu", "trenta": return 30
        case "apatnapu", "kwarenta": return 40
        case "limampu", "singkwenta": return 50
        case "daan", "isang daan", "sandaan": return 100

        // English
        case "one", "single": return 1
        case "two", "pair": return 2
        case "three": return 3
        case "four": return 4
        case "five": return 5
        case "six": return 6
        case "seven": return 7
        case "eight": return 8
        case "nine": return 9
        case "ten": return 10
        case "eleven": return 11
        case "twelve", "dozen": return 12
        case "thirteen": return 13
        case "fourteen": return 14
        case "fifteen": return 15
        case "twenty": return 20
        case "thirty": return 30
        case "forty": return 40
        case "fifty": return 50
        case "hundred", "one hundred": return 100
        default: return nil
        }
    }
}
