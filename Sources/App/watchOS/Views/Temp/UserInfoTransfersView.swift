/*
     File: UserInfoTransfersView.swift
 Abstract: A SwiftUI view that shows the user info transfers.

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
