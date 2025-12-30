//
//  FullDetailView.swift
//  NASAPhoto
//
//  Created by AJAY KADWAL on 30/12/25.
//

import SwiftUI

struct FullDetailView: View {
    let imageURL: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            Color.black.ignoresSafeArea()
            
            if let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(scale)
                        .ignoresSafeArea()
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = value
                                }
                                .onEnded { _ in
                                    scale = min(max(scale, 1.0), 4.0)
                                }
                        )
                        .animation(.easeInOut, value: scale)
                        .onTapGesture(count: 2) {
                            scale = 1.0
                        }
                } placeholder: {
                    ProgressView()
                }
            }
            
            // Dismiss Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .padding(.top, 20)
            }
        }
        .padding()
    }
}

#Preview {
    FullDetailView(imageURL: "")
}
