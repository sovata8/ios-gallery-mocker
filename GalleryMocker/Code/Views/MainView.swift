//
//  MainView.swift
//  GalleryMocker
//
//  Created by Nikolay Suvandzhiev on 20/04/2024.
//

import SwiftUI
import Photos


enum SampleImageType: String, CaseIterable, Identifiable {
    var id: Self { self }

    case mountains
    case deers
    case forest
    case trees

    var isLarge: Bool {
        switch self {
        case .mountains, .deers: false
        case .forest, .trees: true
        }
    }
}


enum SampleVideoType: String, CaseIterable, Identifiable {
    var id: Self { self }

    case london
    case new_york

    var webURL: URL {
        switch self {
        case .london:
            URL(string: "https://videos.pexels.com/video-files/13986779/13986779-uhd_2160_3840_60fps.mp4")!
        case .new_york:
            URL(string: "https://videos.pexels.com/video-files/5796436/5796436-uhd_3840_2160_30fps.mp4")!
        }
    }

    var sizeMB: Int {
        switch self {
        case .london: 97
        case .new_york: 193
        }
    }

    var localURL: URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent(webURL.lastPathComponent)
    }
}

struct MainView: View {
    @State var text: String = ""
    @State var imageType: SampleImageType = .mountains
    @State var videoType: SampleVideoType = .london
    @State var howManyImages: Int = 1
    @State var addText = false
    @State var addTint = false
    @State var isBusy = false
    @State var useAlternativeDeletionMethod = false

    @StateObject var videosDownloadManager = VideosDownloadManager.sharedInstance

    @State var isCreationDateOverriden: Bool = false
    @State var creationDateOverride: Date = .now
    var creationDateToUse: Date? {
        isCreationDateOverriden ? creationDateOverride : nil
    }

    var body: some View {
        VStack {
            ViewThatFits {
                HStack {
                    makeImageContols()
                    makeVideoContols()
                }
                VStack {
                    makeImageContols()
                    makeVideoContols()
                }
            }

            makeCreationDatePicker()

            makeDeleteButton()

            Divider()

            Button("Open Photos") {
                UIApplication.shared.open(URL(string:"photos-redirect://")!)
            }
            .font(.footnote)

            Divider()

            makeLogConsole()
                .overlay {
                    if isBusy {
                        ActivityIndicator(isAnimating: true)
                    }
                }
        }
        .disabled(isBusy)
        .padding()
    }

    private func log(_ message: String) {
        let textAdd = "[\(dateFormatter.string(from: .now))] \(message)\n"
        self.text = textAdd + text
    }

    @ViewBuilder
    private func makeImageContols() -> some View {
        VStack {
            Button("Add image") {
                log("Saving...")
                Log.main.info("Button tap")
                isBusy = true

                let url = Bundle.main.url(forResource: imageType.rawValue, withExtension: "jpg")!

                if !ProcessInfo.isOnPreview() {
                    for _ in 0..<howManyImages {
                        Task {
                            try await GalleryManager.writeToGallery(
                                imageURL: url,
                                addText: addText,
                                addRandomTint: addTint, 
                                creationDate: creationDateToUse
                            )

                            isBusy = false
                            log("Saved to gallery")
                        }
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .font(.title)

            VStack {
                Picker(selection: $imageType) {
                    ForEach(SampleImageType.allCases) {
                        Text($0.rawValue)
                    }
                } label: { Text("Image type") }
                .pickerStyle(.segmented)
                .fixedSize()

                if imageType.isLarge {
                    Text("Large image chosen. Might be very slow")
                        .font(.footnote)
                        .opacity(0.25)
                        .transition(.opacity.animation(.default))
                }
            }

            Divider()

            HStack(spacing: 2) {
                VStack {
                    Text("Count").opacity(0.5)
                    Picker(selection: $howManyImages) {
                        ForEach(
                            [1, 5, 10, 20],
                            id: \.self
                        ) { count in
                            Text(String(describing: count))
                                .monospaced()
                        }
                    } label: { Text("How many") }
                        .pickerStyle(.segmented)
                        .fixedSize()
                }

                Divider()

                VStack(spacing: 2) {
                    VStack(alignment: .leading, spacing: 2) {
                        Toggle(isOn: $addText) {
                            Label("Overlay text", systemImage: addText ? "checkmark.circle" : "x.circle")
                                .font(.callout)
                        }
                        .toggleStyle(.button)

                        Toggle(isOn: $addTint) {
                            Label("Tint", systemImage: addTint ? "checkmark.circle" : "x.circle")
                                .font(.callout)
                        }
                        .toggleStyle(.button)
                    }

                    Text("Slows things down")
                        .font(.footnote)
                        .opacity(0.25)
                }
                .fixedSize()
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.quinary))
    }

    @ViewBuilder
    private func makeVideoContols() -> some View {
        VStack(spacing: 10) {
            HStack {
                Button("Add video") {
                    log("Saving...")
                    isBusy = true

                    if statusForCurrentVideoType().isDownloaded {
                        if !ProcessInfo.isOnPreview() {
                            Task {
                                try await GalleryManager.writeToGallery(
                                    videoURL: videoType.localURL,
                                    creationDate: creationDateToUse
                                )

                                isBusy = false
                                log("Saved to gallery")
                            }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .font(.title)
                .disabled(!statusForCurrentVideoType().isDownloaded)

                Picker(selection: $videoType) {
                    ForEach(SampleVideoType.allCases) {
                        Text($0.rawValue)
                    }
                } label: { Text("Video type") }
                    .pickerStyle(.segmented)
                    .fixedSize()
            }

            if !statusForCurrentVideoType().isDownloaded {
                HStack(spacing: 5) {
                    Text("⚠️ Needs to be downloaded (\(videoType.sizeMB) MB)")
                        .font(.footnote)
                        .opacity(0.5)
                        .transition(.opacity.animation(.default))

                    ZStack {
                        CircularProgressView(progress: statusForCurrentVideoType().progress ?? 0)
                            .frame(width: 20, height: 20)
                            .opacity(statusForCurrentVideoType().isInProgress ? 1 : 0)

                        Button {
                            if statusForCurrentVideoType().isInProgress {
                                videosDownloadManager.cancel()
                            } else {
                                videosDownloadManager.status[videoType] = .inProgress(progress: 0)
                                videosDownloadManager.downloadVideo(videoType)
                            }
                        } label: {
                            Image(systemName: statusForCurrentVideoType().isInProgress ? "xmark.circle.fill" : "arrowshape.down.circle")
                        }
                    }
                    .fixedSize()
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.quinary))
        .transition(.opacity.animation(.default))
        .animation(.default, value: videosDownloadManager.status)
    }

    @ViewBuilder
    private func makeCreationDatePicker() -> some View {
        VStack {
            Text("Creation date").opacity(0.5)

            HStack {
                Picker(selection: $isCreationDateOverriden ) {
                    ForEach(["now", "custom"], id: \.self) {
                        Text($0)
                            .tag($0 != "now")
                    }
                } label: { Text("Creation date") }
                .pickerStyle(.segmented)
                .fixedSize()

                if isCreationDateOverriden {
                    DatePicker("", selection: $creationDateOverride)
                        .fixedSize()
                        .transition(.opacity.animation(.default))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 20).fill(.quinary))
    }

    @ViewBuilder
    private func makeDeleteButton() -> some View {
        VStack(spacing: 5) {
            VStack(spacing: 0) {
                Button("Delete media") {
                    log("Deleting...")
                    if !ProcessInfo.isOnPreview() {
                        Task {
                            if useAlternativeDeletionMethod {
                                try await GalleryManager.deleteAllFromGallerySecondaApproach()
                            } else {
                                try await GalleryManager.deleteAllFromGallery()
                            }
                            log("Deleted from gallery")
                        }
                    }

                }
                .font(.body)
                .onLongPressGesture {
                    VideosDownloadManager.sharedInstance.deleteDownloads()
                }

                Text("Items generated by this app")
                    .font(.footnote)
                    .opacity(0.25)
            }

            VStack(spacing: 0) {
                Toggle(isOn: $useAlternativeDeletionMethod) {
                    Label("Use alternative method", systemImage: useAlternativeDeletionMethod ? "checkmark.circle" : "x.circle")
                }
                .toggleStyle(.button)
                .font(.footnote)

                ViewThatFits {
                    Text("Uses a specially saved geographical location tag")
                        .font(.footnote)
                        .opacity(0.25)

                    EmptyView()
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.quinary))
    }

    @ViewBuilder
    private func makeLogConsole() -> some View {
        ScrollView(.vertical) {
            Group {
                Text(text)
                    .monospaced()
                    .font(.footnote)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.quinary)
    }

    private func statusForCurrentVideoType() -> VideosDownloadManager.Status {
        videosDownloadManager.status[videoType]!
    }
}


#Preview {
    MainView()
        .preferredColorScheme(.dark)
}
