/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the user info transfers.
*/

import SwiftUI
import WatchConnectivity

struct UserInfoTransfersView: View {
    let command: Command
    @State private var transfers = WCSession.default.outstandingUserInfoTransfers

    var body: some View {
        NavigationStack {
            VStack {
                userInfoTransferList()
                    .overlay {
                        if transfers.isEmpty {
                            Text("No outstanding transfer")
                        }
                    }
            }
            .navigationTitle("Transfers")
        }
        .onReceive(NotificationCenter.default.dataDidFlowPublisher) { notification in
            dataDidFlow(notification)
        }
    }

    @ViewBuilder
    private func userInfoTransferList() -> some View {
        List(transfers, id: \.self) { transfer in
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
        }
    }
}

/**
 Notification handler.
 Update the UI when getting a .dataDidFlow notification.
 */
extension UserInfoTransfersView {
    private func dataDidFlow(_ notification: Notification) {
        guard let commandStatus = notification.object as? VLCWatchMessage else { return }
        guard commandStatus.command == command, commandStatus.phrase != .failed else { return }

        transfers = WCSession.default.outstandingUserInfoTransfers
    }
}
