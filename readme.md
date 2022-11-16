# Rust FFI

Boilerplate project to make:

- iOS / MacOS:

  `xcframework`/`Swift Package` of Rust crate for apple platform

- Android: ( Not yet implemented - **PR is welcomed** )

## Prerequisites

### iOS / Darwin

- Rust (confirmed with 1.65.0)

  - targets (all has been set in `build.sh`)
    - aarch64-apple-darwin
    - x86_64-apple-darwin
    - x86_64-apple-ios
    - aarch64-apple-ios
    - aarch64-apple-ios-sim

- Xcode (confirmed with 14.1)
- uniffi_bindgen

  ```
  $ cargo install uniffi_bindgen
  ```

## Compose UDL file

Compose your own `lib.udl` file.

## Build

```bash
# debug build
bash build.sh debug

# release build
bash build.sh
```

## Integrations

### Use in Xcode

1. Package Dependencies -> Add -> Add Local -> ( Select package folder under generated `iOS` directory )
2. Targets -> General -> Frameworks, Libraries, and Embeded Content -> ( Select your framework )
3. ( Import in your Swift code )

## Repository Tree Memo

```
.
├── Cargo.toml
├── generate (generated target folder)
│         └── iOS/Mac
│               └── MyPkg (generated Swift package)
├── build.rs
├── build.sh (build script)
├── misc (required files to create xcframework)
│         ├── Info.plist
│         └── Package.swift (Swift package descriptor template)
└── src (sources written in Rust)
    ├── lib.rs
    └── lib.udl (udl file. see uniffi-rs)
```
