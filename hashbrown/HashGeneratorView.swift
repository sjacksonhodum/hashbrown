//
//  HashGeneratorView.swift
//  hashbrown
//
//  Created by Samuel Jackson-Hodum on 7/13/25.
//

import SwiftUI
import CryptoKit
import UniformTypeIdentifiers

enum HashAlgorithm: String, CaseIterable {
    case md5 = "MD5"
    case sha1 = "SHA-1"
    case sha256 = "SHA-256"
    case sha384 = "SHA-384"
    case sha512 = "SHA-512"
    
    var icon: String {
        switch self {
        case .md5: return "number.circle"
        case .sha1: return "number.circle.fill"
        case .sha256: return "number.square"
        case .sha384: return "number.square.fill"
        case .sha512: return "number"
        }
    }
}

struct HashGeneratorView: View {
    @State private var selectedFile: URL?
    @State private var selectedAlgorithm: HashAlgorithm = .sha256
    @State private var generatedHash: String = ""
    @State private var isGenerating = false
    @State private var showingFilePicker = false
    @State private var showingCopiedAlert = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Hash Generator")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Upload a file to generate its checksum")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            // File Selection Area
            VStack(spacing: 16) {
                if let selectedFile = selectedFile {
                    FileInfoView(fileURL: selectedFile, selectedFile: $selectedFile)
                } else {
                    FileDropZone(showingFilePicker: $showingFilePicker, selectedFile: $selectedFile)
                }
            }
            .padding(.horizontal, 40)
            
            // Algorithm Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Hash Algorithm")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(HashAlgorithm.allCases, id: \.self) { algorithm in
                        AlgorithmButton(
                            algorithm: algorithm,
                            isSelected: selectedAlgorithm == algorithm,
                            action: { selectedAlgorithm = algorithm }
                        )
                    }
                }
            }
            .padding(.horizontal, 40)
            
            // Generate Button
            Button(action: generateHash) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(isGenerating ? "Generating..." : "Generate Hash")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedFile != nil ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(selectedFile == nil || isGenerating)
            .padding(.horizontal, 40)
            
            // Hash Result
            if !generatedHash.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Generated Hash")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(generatedHash)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(8)
                            .lineLimit(1)
                        
                        Button(action: copyHash) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedFile = url
                    generatedHash = ""
                }
            case .failure(let error):
                print("File selection failed: \(error.localizedDescription)")
            }
        }
        .alert("Hash Copied!", isPresented: $showingCopiedAlert) {
            Button("OK") { }
        }
    }
    
    private func generateHash() {
        guard let fileURL = selectedFile else { return }
        
        isGenerating = true
        generatedHash = ""
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: fileURL)
                let hash = generateHashForData(data, algorithm: selectedAlgorithm)
                
                DispatchQueue.main.async {
                    generatedHash = hash
                    isGenerating = false
                }
            } catch {
                DispatchQueue.main.async {
                    isGenerating = false
                    // Handle error
                }
            }
        }
    }
    
    private func generateHashForData(_ data: Data, algorithm: HashAlgorithm) -> String {
        switch algorithm {
        case .md5:
            let digest = Insecure.MD5.hash(data: data)
            return digest.map { String(format: "%02hhx", $0) }.joined()
        case .sha1:
            let digest = Insecure.SHA1.hash(data: data)
            return digest.map { String(format: "%02hhx", $0) }.joined()
        case .sha256:
            let digest = SHA256.hash(data: data)
            return digest.map { String(format: "%02hhx", $0) }.joined()
        case .sha384:
            let digest = SHA384.hash(data: data)
            return digest.map { String(format: "%02hhx", $0) }.joined()
        case .sha512:
            let digest = SHA512.hash(data: data)
            return digest.map { String(format: "%02hhx", $0) }.joined()
        }
    }
    
    private func copyHash() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generatedHash, forType: .string)
        showingCopiedAlert = true
    }
}

struct FileInfoView: View {
    let fileURL: URL
    @Binding var selectedFile: URL?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(fileURL.lastPathComponent)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(fileURL.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button(action: { selectedFile = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
            
            HStack {
                FileInfoItem(title: "Size", value: formatFileSize())
                FileInfoItem(title: "Type", value: fileURL.pathExtension.uppercased())
                FileInfoItem(title: "Modified", value: formatDate())
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    private func formatFileSize() -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            }
        } catch {
            print("Error getting file size: \(error)")
        }
        return "Unknown"
    }
    
    private func formatDate() -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let modificationDate = attributes[.modificationDate] as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return formatter.string(from: modificationDate)
            }
        } catch {
            print("Error getting file date: \(error)")
        }
        return "Unknown"
    }
}

struct FileInfoItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FileDropZone: View {
    @Binding var showingFilePicker: Bool
    @Binding var selectedFile: URL?
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Drop a file here")
                    .font(.headline)
                
                Text("or")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("Choose File") {
                    showingFilePicker = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(isTargeted ? Color.blue.opacity(0.1) : Color.gray.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isTargeted ? Color.blue : Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async {
                        selectedFile = url
                    }
                }
            }
            return true
        }
    }
}

struct AlgorithmButton: View {
    let algorithm: HashAlgorithm
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: algorithm.icon)
                    .font(.title2)
                
                Text(algorithm.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.08))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HashGeneratorView()
} 