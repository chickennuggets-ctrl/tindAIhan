# TindAIhan 🏪

**AppBuildersPH Hackathon 2026** · iOS (SwiftUI) · 100% on-device AI

TindAIhan digitizes the sari-sari store *listahan*. The owner speaks in Taglish
("Utang ni Pedro, isang bigas tsaka dalawang itlog") and the app logs it, with no
cloud, no subscription, and no mobile data needed.

## How it works

| Step | Tech | Where it runs |
|---|---|---|
| Record voice (16 kHz WAV) | AVFoundation | on-device |
| Speech to text | [WhisperKit](https://github.com/argmaxinc/WhisperKit) (Whisper on Core ML) | on-device |
| Text to structured JSON | [MLX Swift](https://github.com/ml-explore/mlx-swift-examples) + Qwen2.5-1.5B (4-bit) | on-device GPU |
| Storage | SwiftData | on-device |

```
mic -> WAV -> Whisper -> Taglish text -> LLM -> JSON -> SwiftData -> SwiftUI ledger
```

## Requirements
- Mac with Xcode 16+
- **Physical iPhone**, iOS 17+ (6 GB RAM or more recommended). MLX does not run in the Simulator.

## Setup
1. Create a new Xcode project: **iOS App**, SwiftUI, name `TindAIhan`, storage: None.
2. Delete the template `ContentView.swift` and the template `*App.swift`.
3. Drag the `TindAIhan/` folder from this repo into the project (check "Copy items if needed" and "Create groups").
4. **File > Add Package Dependencies**:
   - `https://github.com/ml-explore/mlx-swift-examples` -> add products **MLXLLM** and **MLXLMCommon**
   - `https://github.com/argmaxinc/WhisperKit` -> add product **WhisperKit**
5. Target > **Info**: add `Privacy - Microphone Usage Description` = "TindAIhan listens to log your listahan."
6. Target > **Signing & Capabilities**: add **Increased Memory Limit**.
7. Select your iPhone, then Run.

## Offline test (for judges)
1. First launch **with internet**: tap **Download & load models** (one-time, ~1 GB).
2. Turn on **Airplane Mode**.
3. Tap the mic, say *"Utang ni Aling Nena, tatlong sardinas"*, tap stop.
4. The entry appears in the ledger with no network involved.

Prefer typing? The text field runs the same LLM pipeline, which is useful in noisy rooms.

## Notes
- Model weights are **not** stored in this repo. They download once and are cached in the app sandbox.
- Prices come from `Services/PriceList.swift` (editable offline price guide).
- Swipe right on a row for **Bayad** (paid), swipe left to delete.

## License
MIT
