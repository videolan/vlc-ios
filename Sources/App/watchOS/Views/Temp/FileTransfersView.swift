/*
     File: FileTransfersView.swift
 Abstract: A SwiftUI view that shows the file transfers.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.

Copyright (C) 2024 Apple Inc.
(https://developer.apple.com/documentation/WatchConnectivity/transferring-data-with-watch-connectivity)

 */

import SwiftUI
import WatchConnectivity

struct FileTransfersView: View {
    let command: Command
    @State private var fileTransferObservers = FileTransferObservers()

    var body: some View {
        NavigationStack {
            VStack {
                fileTransferList()
                    .overlay {
                        if fileTransferObservers.fileTransfers.isEmpty {
                            Text("No outstanding transfer")
                        }
                    }
            }
            .navigationTitle("Transfers")
        }
        .onAppear {
            fileTransferObservers.observe(WCSession.default.outstandingFileTransfers)
        }
        .onReceive(NotificationCenter.default.dataDidFlowPublisher) { notification in
            dataDidFlow(notification)
        }
    }

    @ViewBuilder
    private func fileTransferList() -> some View {
        List(fileTransferObservers.fileTransfers, id: \.self) { transfer in
            VStack {
                HStack {
                    Text(transfer.timedColor?.timeStamp ?? "TimedColor missing")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .foregroundColor(Color(uiColor: transfer.timedColor?.color ?? .red))

                    Spacer()

                    Button(role: .destructive, action: {
                        transfer.cancel(notifying: command)
                    }) {
                        Label("Delete", systemImage: "trash")
                            .labelStyle(.iconOnly)
                    }
                }
                Text(fileTransferObservers.progresssDescriptions[transfer] ?? "No progress")
                    .foregroundColor(Color(uiColor: transfer.timedColor?.color ?? .red))
            }
        }
    }
}

/**
 Notification handler.
 Update the UI when getting a .dataDidFlow notification.
 */
extension FileTransfersView {
    private func dataDidFlow(_ notification: Notification) {
        guard let commandStatus = notification.object as? VLCWatchMessage else { return }
        guard commandStatus.command == command, commandStatus.phrase != .failed else { return }

        fileTransferObservers.reset()
        fileTransferObservers.observe(WCSession.default.outstandingFileTransfers)
    }
}
