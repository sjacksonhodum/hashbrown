//
//  ContentView.swift
//  hashbrown
//
//  Created by Samuel Jackson-Hodum on 7/13/25.
//

import SwiftUI
import CryptoKit
import UniformTypeIdentifiers

struct ContentView: View {
    var body: some View {
        TabView {
            ScrollView {
                HashGeneratorView()
            }
            .tabItem {
                Image(systemName: "doc.badge.plus")
                Text("Generate Hash")
            }
            
            ScrollView {
                FileComparisonView()
            }
            .tabItem {
                Image(systemName: "doc.on.doc")
                Text("Compare Files")
            }
        }
        .frame(minWidth: 600, idealWidth: 800, maxWidth: .infinity, minHeight: 500, idealHeight: 700, maxHeight: .infinity)
        .navigationTitle("hashbrown")
    }
}

#Preview {
    ContentView()
}
