/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the file transfers.
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
