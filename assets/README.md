# Assets

Place generated media and supporting files here.

- `assets/videos/<language>/<letter>.mp4`: generated Higgsfield avatar videos
- `assets/metadata/<language>/<letter>.json`: sidecar metadata written by the generator
- `assets/images/...`: avatar and example-word imagery referenced by the language JSON
- `assets/audio/...`: example-word pronunciation clips and optional generated speech

The SwiftUI app bundles this folder as a resource directory, so any media added here becomes available in-app without changing code.

