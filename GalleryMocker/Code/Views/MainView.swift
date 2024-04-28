//
//  MainView.swift
//  GalleryMocker
//
//  Created by Nikolay Suvandzhiev on 20/04/2024.
//

import SwiftUI
import Photos


struct MainView: View {
    @State private var text: String = ""
    @State private var imageType: SampleImageType = .mountains
    @State private var videoType: SampleVideoType = .london
    @State private var howManyImages: Int = 1
    @State private var addText = false
    @State private var addTint = false
    @State private var isBusy = false
    @State private var isDeleteInfoSheetPresented = false
    @State private var isAppVersionShown = false

    @StateObject private var videosDownloadManager = VideosDownloadManager.sharedInstance

    @State private var isCreationDateOverriden: Bool = false
    @State private var creationDateOverride: Date = .now
    private var creationDateToUse: Date? {
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

            Button("Delete actions...") {
                log("Deleting...")
                isDeleteInfoSheetPresented = true
            }
            Divider()

            Button("Open Photos") {
                UIApplication.shared.open(URL(string:"photos-redirect://")!)
            }
            .font(.footnote)
            .onLongPressGesture {
                isAppVersionShown.toggle()
            }

            if isAppVersionShown {
                Text("Version \(Bundle.main.appVersionLong) (\(Bundle.main.appBuild)) ")
                    .font(.footnote)
                    .monospaced()
            }

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
        .sheet(isPresented: $isDeleteInfoSheetPresented) {
            makeDeleteSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }

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
    private func makeDeleteSheet() -> some View {
        VStack(spacing: 10) {
            Text("Delete actions")
            Text("Your gallery is safe, this app only removes media generated by it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            VStack {
                Button("Delete media") {
                    log("Deleting...")
                    if !ProcessInfo.isOnPreview() {
                        Task {
                            try await GalleryManager.deleteAllFromGallery()
                            log("Deleted media from gallery")
                        }
                    }
                }

                Divider()

                VStack {
                    Button(action: {
                        log("Deleting...")
                        if !ProcessInfo.isOnPreview() {
                            Task {
                                try await GalleryManager.deleteAllFromGallerySecondaApproach()
                                log("Deleted media from gallery")
                            }
                        }
                    }, label: {
                        VStack{
                            Text("Delete media")
                            Text("(alternative method)")
                                .font(.footnote)
                        }
                    })

                    Text("Usually the default method is enough. In case you uninstalled the app but did not delete the media, and then re-installed the app - the first method might miss some items. This method uses a specially saved geographical location tag to find the media to delete.")
                        .font(.footnote)
                        .opacity(0.25)
                }

                Divider()

                VStack {
                    Button("Delete downloaded videos") {
                        VideosDownloadManager.sharedInstance.deleteDownloads()
                        log("Deleted downloaded videos...")
                    }
                    .font(.footnote)
                }
            }
        }
        .padding()
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
