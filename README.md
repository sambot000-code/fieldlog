# FieldLog 📋

A field inspection app for capturing events on-site — photos, voice notes, and AI-assisted summaries.

## Concept

When you're in the field (mine site, dam inspection, infrastructure check), you need to log what you see — fast. FieldLog lets you:

- **Capture an event** — one tap to start
- **Take a photo** — attach visual evidence
- **Describe it** — type or speak, AI summarizes
- **Log it** — timestamped, geotagged, ready to link to assets

## Event Model

An `Event` is the core unit:
- ID + timestamp + location (GPS)
- Photo(s)
- Voice memo / transcript
- AI-generated summary
- Status (draft → submitted)
- Tags / asset links (future)

## Tech Stack

- **iOS:** SwiftUI
- **Shared layer:** BasecampKit (networking, models)
- **AI:** OpenAI Whisper (voice → text) + GPT-4 (summarization)
- **Storage:** Local (Core Data or SQLite) + sync to backend later

## Project Structure

```
fieldlog-ios/
├── FieldLogApp/           # Xcode project
│   └── FieldLogApp/
│       ├── Models/        # Event, Photo, VoiceMemo
│       ├── Views/         # EventListView, CaptureView, SummaryView
│       └── Services/      # CameraService, TranscriptionService, AIService
└── README.md
```

## Roadmap

- [ ] Phase 1: Event capture (photo + text/voice)
- [ ] Phase 2: AI transcription + summary
- [ ] Phase 3: GPS tagging + site/asset linking
- [ ] Phase 4: Sync to backend + reporting
