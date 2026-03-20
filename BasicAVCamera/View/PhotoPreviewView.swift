//
//  PhotoPreviewView.swift
//  BasicAVCamera
//
//  Created by Itsuki on 2024/05/19.
//

import SwiftUI

struct PhotoPreviewView: View {
    @State var photoData: PhotoData

    var body: some View {
        if let uiImage = UIImage(data: photoData.imageData) {
            GeometryReader { geometry in
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                    .clipped()
                    .background(Color.black)
            }
        } else {
            Spacer()
        }
    }
}
