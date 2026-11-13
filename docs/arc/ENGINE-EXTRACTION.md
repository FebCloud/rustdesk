# Engine extraction boundary

Source baseline: a7468d0df356bc7eedf9cec22dd97384306880c7.

Target: reuse remote-control internals while implementing a separate product UI, account/control plane and connection infrastructure. The stock UI, account pages and hbbs/hbbr binaries are not integration deliverables. The extraction is not implemented yet; this is the source-verified cut plan.

## Observed modules

| Concern | Source | Extraction issue |
| --- | --- | --- |
| Capture / video codec plumbing | libs/scrap | Existing crate; depends on base and hbb_common, plus native codec/build dependencies |
| Input injection | libs/enigo, src/keyboard.rs, src/server/input_service.rs | enigo alone is not the session input pipeline; coordinate conversion, permission and key release remain required |
| Host video lifecycle | src/server/video_service.rs | Depends on shared server state/platform/configuration |
| Viewer decode/session | src/client.rs | Imports ui_interface, ui_session_interface::Session and InvokeUiSession; not UI independent |
| Authorization and host sessions | src/server.rs, src/server/connection.rs | Config/key/password/permission and connection-manager callbacks are coupled; do not remove authorization with the account UI |
| Protocol/common code | libs/base, libs/hbb_common | Protocol and config dependencies need separating; shared submodule pinned independently |
| Rendezvous/relay client | src/rendezvous_mediator.rs, src/client.rs | Coupled to protocol and endpoint/key configuration; replacing server binaries requires a compatible client-side transport/handshake change |
| Existing native library | Cargo.toml, src/lib.rs | cdylib/staticlib/rlib targets exist, but still compile application modules including UI/session interfaces, updater, tray and account HTTP integration |

`cargo metadata --no-deps --format-version 1 --offline` succeeded after initializing hbb_common. The inspected workspace has ten packages and no independent remote-desktop-engine package. This command validates manifests, not compilation or runtime behavior. Both scrap and enigo declare MIT in their manifests, but depend on base/hbb_common; manifest labels do not settle the license of a copied dependency closure or RustDesk modifications. The root session implementation is covered by the root AGPL license; perform per-file and dependency provenance review before selecting any alternative licensing path.

## Proposed cut sequence

1. Introduce an optional engine-facing event/config boundary in this open fork while preserving existing default paths. Replace dependencies on dialogs and application settings with narrow injected implementations. Do not remove permission checks or identity verification.
2. Produce a headless Windows host engine and a native viewer engine. Do not include stock Flutter pages, tray/updater/account workflows. Keep capture/codec/input source in its upstream locations initially to minimize merge conflicts.
3. Define explicit session lifecycle and capability contracts: create, authenticate, grant/revoke view/input permission, subscribe to frames/cursor, submit input, close. No input before authentication/grant. Closing or losing transport releases pressed keys/buttons and stops capture.
4. Provide an injected connection layer for direct LAN sessions first. Own-account login is control-plane identity, not sufficient cryptographic proof of a desktop peer. Require validated peer identity, short-lived session authorization, and an encrypted channel; do not silently fall back to public RustDesk endpoints.
5. Connect the product's UDP traversal and relay infrastructure after the LAN session passes. A custom UDP relay is not automatically compatible with RustDesk's protocol. Keep NAT negotiation/relay routing separate from video/input, while preserving encryption and peer identity through relay.
6. Add a thin Flutter-native bridge and render/input integration only after deciding the combined client's licensing scope. Provide public corresponding source and build instructions for the covered binaries. Do not promise a proprietary Flutter executable solely because AGPL code is in a different crate or DLL.

Not in the initial engine scope: file transfer, clipboard sync, remote terminal, printer, account UI, auto-update, stock window management or public relay defaults. Audio and multi-monitor support follow a working video/input session.

## Acceptance

- Builds as host and viewer without stock UI/account workflows; dependency graph records what remains.
- Synthetic lifecycle/input tests plus authorized two-machine video/input tests.
- Invalid identity, expired/revoked grants and disconnected sessions cannot accept input.
- LAN then forced relay; record latency, reconnect behavior and codec constraints.
- Original RustDesk behavior remains unchanged with extraction disabled; upstream regressions and native builds pass before claiming compatibility.

Current change surface: documentation and a read-only source inventory script only. No existing Rust, Dart, networking, input, capture or build path was changed. No engine extraction or remote session has been tested yet.
