import SwiftUI

/// Sidebar with the registered sections, content on the right (AC-7, AC-10, AC-21, AC-23).
struct SettingsWindowView: View {
    let registry: SettingsRegistry
    let problems: ProblemCenter
    @Bindable var navigation: SettingsNavigation

    var body: some View {
        NavigationSplitView {
            List(registry.availableSections, selection: $navigation.selection) { section in
                Label(section.title, systemImage: section.symbolName)
                    .symbolRenderingMode(.hierarchical)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 260)
        } detail: {
            detail(for: navigation.selection)
        }
        // NSHostingController derives the window's min/max size from these
        // SwiftUI limits and overrides `contentMaxSize` set on the window.
        .frame(
            minWidth: SettingsWindowController.minimumSize.width,
            maxWidth: SettingsWindowController.maximumWidth,
            minHeight: SettingsWindowController.minimumSize.height,
            maxHeight: .infinity
        )
        .onChange(of: navigation.selection, initial: true) { _, section in
            registry.rememberSelection(section)
        }
    }

    @ViewBuilder
    private func detail(for section: SettingsSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            let sectionProblems = problems.problems(in: section)
            if !sectionProblems.isEmpty {
                VStack(spacing: 8) {
                    ForEach(sectionProblems) { ProblemBanner(problem: $0) }
                }
                .padding([.horizontal, .top], 20)
            }
            if let pane = registry.panes[section] {
                pane.content()
            } else {
                ContentUnavailableView(
                    "Bereich nicht verfügbar",
                    systemImage: section.symbolName,
                    description: Text("Wähle links einen anderen Bereich.")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(section.title)
    }
}
