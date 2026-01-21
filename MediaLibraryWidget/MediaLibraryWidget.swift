/*****************************************************************************
 * MediaLibraryWidget.swift
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entries: [SimpleEntry] = [SimpleEntry(date: Date(), configuration: configuration)]
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent

    var decodedData: MLWidgetBridge? = {
        guard let groupIdentifier = Bundle.main.object(forInfoDictionaryKey: "MLKitGroupIdentifier") as? String,
              let encodedData = UserDefaults(suiteName: groupIdentifier)?.object(forKey: "media") as? Data,
              let decodedData = try? JSONDecoder().decode(MLWidgetBridge.self, from: encodedData) else {
            return nil
        }

        return decodedData
    }()

    func backgroundColor() -> Color {
        guard let decodedData = decodedData else {
            return .orange
        }

        let codableColor = decodedData.color
        let uiColor = UIColor(red: codableColor.red,
                              green: codableColor.green,
                              blue: codableColor.blue,
                              alpha: codableColor.alpha)
        return Color(uiColor)
    }
}

struct MediaLibraryWidgetEntryView: View {
    var entry: SimpleEntry

    @Environment(\.widgetFamily) var widgetFamily

    private static let urlScheme: String = "ml-widget:///"

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(entry.backgroundColor())
                .ignoresSafeArea(.all)
            switch widgetFamily {
            case .systemSmall:
                createSmallStack()
            case .systemMedium:
                createMediumStack()
            default:
                VStack {}
            }
        }
        .widgetURL(URL(string: MediaLibraryWidgetEntryView.urlScheme + (entry.decodedData?.mediaURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")))
    }

    func createSmallStack() -> some View {
        var image = UIImage(named: "vlc")

        if let decodedData = entry.decodedData {
            let imageData = Data(base64Encoded: decodedData.imageData, options: .ignoreUnknownCharacters)
            image = UIImage(data: imageData!)
        }

        return VStack {
            Image(uiImage: image ?? UIImage(named: "vlc")!)
                .resizable()
                .clipShape(.containerRelative)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    func createMediumStack() -> some View {
        var albumName: String = "Album Name"
        var artistName: String = "Artist"
        var imageData: String = ""

        if let decodedData = entry.decodedData {
            albumName = decodedData.albumName
            artistName = decodedData.artistName
            imageData = decodedData.imageData
        }

        return HStack {
            let data = Data(base64Encoded: imageData, options: .ignoreUnknownCharacters)
            Image(uiImage: UIImage(data: data!) ?? UIImage(named: "vlc")!)
                .resizable()
                .clipShape(.containerRelative)
                .frame(width: 120, height: 120)
            VStack(alignment: .leading, spacing: 3) {
                Text("Last played")
                    .italic()
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .padding(.leading)
                Text(albumName)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .bold()
                    .padding(.leading)
                Text(artistName)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .padding(.leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct MediaLibraryWidget: Widget {
    let kind: String = "MediaLibraryWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            MediaLibraryWidgetEntryView(entry: entry)
                .containerBackground(entry.backgroundColor(), for: .widget)
        }
        .configurationDisplayName("VLC")
        .description("Display your recent tracks")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
