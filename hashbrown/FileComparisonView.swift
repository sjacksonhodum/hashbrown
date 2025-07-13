//
//  FileComparisonView.swift
//  hashbrown
//
//  Created by Samuel Jackson-Hodum on 7/13/25.
//

import SwiftUI
import CryptoKit
import UniformTypeIdentifiers

struct FileComparisonView: View {
    @State private var file1: URL?
    @State private var file2: URL?
    @State private var selectedAlgorithm: HashAlgorithm = .sha256
    @State private var hash1: String = ""
    @State private var hash2: String = ""
    @State private var isComparing = false
    @State private var showingFile1Picker = false
    @State private var showingFile2Picker = false
    @State private var comparisonResult: ComparisonResult?
    
    enum ComparisonResult {
        case identical
        case different
        case error(String)
        
        var color: Color {
            switch self {
            case .identical: return .green
            case .different: return .red
            case .error: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .identical: return "checkmark.circle.fill"
            case .different: return "xmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
        
        var message: String {
            switch self {
            case .identical: return "Files are identical"
            case .different: return "Files are different"
            case .error(let message): return "Error: \(message)"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("File Comparison")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Compare two files to check if they are identical")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            // File Selection
            HStack(spacing: 20) {
                // File 1
                VStack(spacing: 12) {
                    Text("File 1")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let file1 = file1 {
                        FileComparisonCard(
                            fileURL: file1,
                            hash: hash1,
                            onRemove: { self.file1 = nil }
                        )
                    } else {
                        FileSelectionCard(
                            title: "Select First File",
                            systemImage: "doc.badge.plus",
                            action: { showingFile1Picker = true },
                            selectedFile: $file1
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Comparison Icon
                VStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title)
                        .foregroundColor(.blue)
                        .padding(.top, 40)
                }
                
                // File 2
                VStack(spacing: 12) {
                    Text("File 2")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let file2 = file2 {
                        FileComparisonCard(
                            fileURL: file2,
                            hash: hash2,
                            onRemove: { self.file2 = nil }
                        )
                    } else {
                        FileSelectionCard(
                            title: "Select Second File",
                            systemImage: "doc.badge.plus",
                            action: { showingFile2Picker = true },
                            selectedFile: $file2
                        )
                    }
                }
                .frame(maxWidth: .infinity)
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
            
            // Compare Button
            Button(action: compareFiles) {
                HStack {
                    if isComparing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.left.arrow.right")
                    }
                    Text(isComparing ? "Comparing..." : "Compare Files")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canCompare ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!canCompare || isComparing)
            .padding(.horizontal, 40)
            
            // Comparison Result
            if let result = comparisonResult {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: result.icon)
                            .foregroundColor(result.color)
                            .font(.title2)
                        
                        Text(result.message)
                            .font(.headline)
                            .foregroundColor(result.color)
                    }
                    .padding()
                    .background(result.color.opacity(0.1))
                    .cornerRadius(12)
                    
                    if case .different = result {
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("File 1 Hash")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(hash1)
                                    .font(.system(.caption, design: .monospaced))
                                    .lineLimit(1)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("File 2 Hash")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(hash2)
                                    .font(.system(.caption, design: .monospaced))
                                    .lineLimit(1)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .fileImporter(
            isPresented: $showingFile1Picker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result, for: &file1)
        }
        .fileImporter(
            isPresented: $showingFile2Picker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result, for: &file2)
        }
    }
    
    private var canCompare: Bool {
        file1 != nil && file2 != nil && file1 != file2
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>, for fileBinding: inout URL?) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                fileBinding = url
                comparisonResult = nil
                hash1 = ""
                hash2 = ""
            }
        case .failure(let error):
            print("File selection failed: \(error.localizedDescription)")
        }
    }
    
    private func compareFiles() {
        guard let file1 = file1, let file2 = file2 else { return }
        
        isComparing = true
        comparisonResult = nil
        hash1 = ""
        hash2 = ""
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data1 = try Data(contentsOf: file1)
                let data2 = try Data(contentsOf: file2)
                
                let hash1Result = generateHashForData(data1, algorithm: selectedAlgorithm)
                let hash2Result = generateHashForData(data2, algorithm: selectedAlgorithm)
                
                DispatchQueue.main.async {
                    hash1 = hash1Result
                    hash2 = hash2Result
                    
                    if hash1Result == hash2Result {
                        comparisonResult = .identical
                    } else {
                        comparisonResult = .different
                    }
                    
                    isComparing = false
                }
            } catch {
                DispatchQueue.main.async {
                    comparisonResult = .error(error.localizedDescription)
                    isComparing = false
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
}

struct FileComparisonCard: View {
    let fileURL: URL
    let hash: String
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(fileURL.lastPathComponent)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(formatFileSize())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if !hash.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(hash)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(1)
                }
            }
        }
        .padding()
                                            .background(Color.gray.opacity(0.15))
        .cornerRadius(8)
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
}

struct FileSelectionCard: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    @State private var isTargeted = false
    @Binding var selectedFile: URL?
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
                                                    .background(isTargeted ? Color.blue.opacity(0.1) : Color.gray.opacity(0.15))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isTargeted ? Color.blue : Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
        .buttonStyle(PlainButtonStyle())
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

#Preview {
    FileComparisonView()
} 