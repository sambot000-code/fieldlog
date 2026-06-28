import SwiftUI

struct ProjectListView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @State private var showAdd = false

    var body: some View {
        ZStack {
            Color.flBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    if projectStore.projects.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "building.2")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.flAccent.opacity(0.6))
                            Text("No Sites Yet")
                                .font(.title3.weight(.semibold))
                            Text("Add a site or project to get started.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 80)
                    } else {
                        ForEach(projectStore.projects) { project in
                            ProjectCard(project: project)
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 100)
            }

            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button { showAdd = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Add Site")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.flAccent)
                        .clipShape(Capsule())
                        .shadow(color: Color.flAccent.opacity(0.45), radius: 12, x: 0, y: 6)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Sites & Projects")
        .sheet(isPresented: $showAdd) {
            AddProjectView()
                .environmentObject(projectStore)
        }
    }
}

// MARK: - Project Card

struct ProjectCard: View {
    @EnvironmentObject var projectStore: ProjectStore
    let project: Project
    var isActive: Bool { projectStore.activeProject?.id == project.id }

    var body: some View {
        HStack(spacing: 14) {
            // Colour dot
            Circle()
                .fill(Color(hex: project.color) ?? Color.flAccent)
                .frame(width: 14, height: 14)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(project.name)
                        .font(.system(size: 16, weight: .semibold))
                    if let code = project.siteCode {
                        PillBadge(label: code, color: Color(hex: project.color) ?? .flAccent)
                    }
                }
                if let desc = project.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Active toggle
            Button {
                if isActive {
                    projectStore.deactivate()
                } else {
                    projectStore.activate(project)
                }
            } label: {
                if isActive {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Active")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.flSuccess)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.flSuccess.opacity(0.12))
                    .clipShape(Capsule())
                } else {
                    Text("Set Active")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Add Project Sheet

struct AddProjectView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var siteCode = ""
    @State private var description = ""
    @State private var selectedColor = "#15B0C1"
    @State private var makeActive = true

    let colorOptions = ["#15B0C1","#E05252","#E88C2A","#3BAE72","#7B61FF","#E54D8A"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.flBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {

                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Site Name")
                            TextField("e.g. Malartic Dam — North Inspection", text: $name)
                                .padding(14)
                                .cardStyle()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Site Code (optional)")
                            TextField("e.g. AGK-01", text: $siteCode)
                                .font(.system(.body, design: .monospaced))
                                .padding(14)
                                .cardStyle()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Description (optional)")
                            TextField("What's being inspected?", text: $description)
                                .padding(14)
                                .cardStyle()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Colour")
                            HStack(spacing: 12) {
                                ForEach(colorOptions, id: \.self) { hex in
                                    Circle()
                                        .fill(Color(hex: hex) ?? .flAccent)
                                        .frame(width: 32, height: 32)
                                        .overlay {
                                            if selectedColor == hex {
                                                Image(systemName: "checkmark")
                                                    .font(.caption.weight(.bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .onTapGesture { selectedColor = hex }
                                }
                            }
                            .padding(14)
                            .cardStyle()
                        }

                        Toggle(isOn: $makeActive) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Set as active site")
                                    .font(.subheadline.weight(.medium))
                                Text("New events will be logged against this site")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(Color.flAccent)
                        .padding(14)
                        .cardStyle()

                        Button {
                            let project = Project(
                                name: name,
                                siteCode: siteCode.isEmpty ? nil : siteCode,
                                description: description.isEmpty ? nil : description,
                                color: selectedColor
                            )
                            projectStore.add(project)
                            if makeActive { projectStore.activate(project) }
                            dismiss()
                        } label: {
                            Text("Save Site")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(name.isEmpty ? Color.secondary : Color.flAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(name.isEmpty)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Site")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.flAccent)
                }
            }
        }
    }
}

// MARK: - Color hex extension

extension Color {
    init?(hex: String) {
        var h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard h.count == 6, let val = UInt64(h, radix: 16) else { return nil }
        self.init(
            red:   Double((val >> 16) & 0xFF) / 255,
            green: Double((val >> 8)  & 0xFF) / 255,
            blue:  Double( val        & 0xFF) / 255
        )
    }
}
