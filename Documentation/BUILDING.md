# Building

## Unsigned device build

The GitHub Actions workflow `.github/workflows/tests.yml` generates the Xcode project with XcodeGen and compiles for a generic iOS device using the Xcode 27 toolchain. The bundled llama.cpp binary currently targets physical iOS devices, so the workflow intentionally does not use an iOS Simulator destination.

For a local build, install Xcode 27 and XcodeGen, run `xcodegen generate`, then open `LocalAIStudio.xcodeproj`.

## Signed Ad Hoc IPA

Run **Actions → Build signed IPA → Run workflow**. The workflow exports an Ad Hoc IPA and uploads it as the `LocalAIStudio-AdHoc-IPA` artifact for 14 days.

Configure these repository Actions secrets first:

- `IOS_CERTIFICATE_BASE64`: Base64-encoded Apple Distribution `.p12`
- `IOS_CERTIFICATE_PASSWORD`: Password protecting that `.p12`
- `IOS_PROVISIONING_PROFILE_BASE64`: Base64-encoded Ad Hoc provisioning profile
- `IOS_TEAM_ID`: Apple Developer Team ID

The provisioning profile must use bundle identifier `com.srgtcauliflour.LocalAIStudio` and include the target iPhone's registered UDID. The workflow checks for missing secrets before attempting to sign.

Never commit certificates, profiles, private keys or tokens. Store signing material only in GitHub Actions secrets.

## Bundle identifier

`com.srgtcauliflour.LocalAIStudio`
