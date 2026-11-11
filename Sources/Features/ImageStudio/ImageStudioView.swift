import SwiftUI

struct ImageStudioView: View {
    @State private var prompt = ""
    @State private var negativePrompt = ""
    @State private var steps = 20.0
    @State private var size = "512 × 512"
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    StudioHeader(title: "Image Studio", subtitle: "Create images entirely on-device.")
                    EmptyStateCard(icon: "photo.badge.plus", title: "Your creative workspace", message: "The image runtime is being evaluated for iPhone memory, thermal and Metal performance. No cloud image service will be used.")
                    VStack(alignment: .leading, spacing: 10) {
                        Text("PROMPT").font(.caption.bold()).foregroundStyle(.secondary)
                        TextEditor(text: $prompt).frame(minHeight: 110).scrollContentBackground(.hidden).padding(8).background(Color.studioBackground, in: RoundedRectangle(cornerRadius: 12))
                        Text("NEGATIVE PROMPT").font(.caption.bold()).foregroundStyle(.secondary)
                        TextField("Optional", text: $negativePrompt).textFieldStyle(.roundedBorder)
                        HStack { Text("Steps"); Spacer(); Text("\(Int(steps))").monospacedDigit().foregroundStyle(.secondary) }
                        Slider(value: $steps, in: 10...40, step: 1)
                        Picker("Resolution", selection: $size) {
                            Text("512 × 512").tag("512 × 512")
                            Text("640 × 640").tag("640 × 640")
                            Text("768 × 768").tag("768 × 768")
                        }.pickerStyle(.segmented)
                        Button {} label: { Label("Generate (runtime not integrated)", systemImage: "sparkles").frame(maxWidth: .infinity).padding() }
                            .buttonStyle(.borderedProminent).disabled(true)
                    }.padding().background(Color.studioPanel, in: RoundedRectangle(cornerRadius: 18))
                }.padding()
            }.background(Color.studioBackground)
        }
    }
}
