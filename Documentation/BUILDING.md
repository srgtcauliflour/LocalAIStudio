# Building

Install Xcode and XcodeGen, run `xcodegen generate`, then open LocalAIStudio.xcodeproj.

The simulator workflow builds the generated Xcode project without signing. A signed Ad Hoc IPA requires a valid Apple distribution certificate, provisioning profile containing the target iPhone UDID, and protected GitHub Actions secrets. Never commit certificates, profiles, private keys or tokens.

Bundle identifier: com.srgtcauliflour.LocalAIStudio
