# Adaptive Remote desktop component

This is an unofficial downstream integration branch of RustDesk. Upstream license, attribution and runtime behavior are retained. No desktop connection or customized binary has been validated by this branch yet.

## Scope

Keep RustDesk and its modifications in this public AGPL repository. The integration target is now an extracted remote-control engine, not the stock RustDesk UI, account system or hbbs/hbbr deployment. See ENGINE-EXTRACTION.md for the measured dependency boundary. Whether the extracted engine is linked or separately executed is a distinct distribution decision; do not assume that a module boundary exempts the containing program from AGPL. Do not copy private controller code, account credentials, device identifiers, certificates, signing material or runtime logs into this repository.

The controller must distinguish process launch from an authenticated remote session. RustDesk peer IDs are addresses, not proof of account ownership. Do not transmit persistent passwords through process arguments or URLs. Any account/device authorization bridge needs its own design and verification before enabling remote control.

Embedding RustDesk Rust/Dart code into another application is a separate architectural and licensing decision. Separate repositories or processes do not by themselves determine the scope of AGPL obligations. Preserve license notices and provide corresponding source and build instructions for covered distributed components; see the root LICENCE and the FSF FAQ on aggregates.

## Upstream maintenance

- `master`: upstream-compatible base; no product patches.
- `arc/desktop-integration`: small additive integration changes.
- `arc/upstream-<date>`: temporary candidate branch for upstream merges and validation.
- `baseline.json`: exact initial source and submodule revisions. Update only after reviewing and validating the new baseline.

Configure `origin` as the fork and `upstream` as https://github.com/rustdesk/rustdesk.git. Run `./docs/arc/upstream-status.ps1 -Fetch` to fetch upstream and report divergence without modifying the working tree or merging code. Updates are checked on demand; no unattended merge or release is configured.

To integrate an update, start from a clean integration branch, create a candidate branch, merge `upstream/master` without force-pushing shared history, and initialize the submodules at their recorded commits. Review changed licenses, dependencies, CLI/FFI interfaces and upstream CI toolchain pins. Build Windows and Android, run upstream tests and verify LAN/forced-relay/input-stop behavior on authorized machines before updating the baseline and publishing a release.

## Initial inspected boundary

At the pinned source, `src/core_main.rs` dispatches the Flutter `--connect` path; `flutter/lib/common.dart` recognizes `--request-approval` and `--relay`. These observed command-line options are not a stable SDK contract. Existing Flutter/Rust FFI and UI remain inside the open desktop component. No core option parser or networking path is modified here.

Windows/Android Flutter CI currently pins Flutter 3.24.5, while an independent controller may use a different SDK. Build this component using its own upstream toolchain rather than changing a global Flutter installation or rewriting upstream dependencies to match the controller.

References: https://www.gnu.org/licenses/gpl-faq.en.html#MereAggregation and the root LICENCE. Final distribution scope must be assessed against the actual combined product, not this directory layout alone.
