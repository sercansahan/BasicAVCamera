//
//  VideoPreviewView.swift
//  BasicAVCamera
//
//  Created by Itsuki on 2024/05/19.
//

import SwiftUI
import AVKit

struct VideoPreviewView: View {
    @State var videoFileUrl: URL

    var body: some View {
        VideoPlayer(player: AVPlayer(url: videoFileUrl))
            .background(Color.black)
            .onAppear {
                print(videoFileUrl)
            }
            .onDisappear {
                Task {
                    try? FileManager().removeItem(at: videoFileUrl)
                }
            }
    }
}
