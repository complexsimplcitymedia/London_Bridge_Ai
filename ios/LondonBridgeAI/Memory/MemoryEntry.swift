//
//  MemoryEntry.swift
//  LondonBridgeAI
//
//  Represents a single AI interaction memory
//

import Foundation
import CryptoKit

/// MemoryEntry - Represents a single AI interaction memory
/// Immutable data structure for storing AI conversations and interactions
public struct MemoryEntry: Codable {
    
    // MARK: - Properties
    
    public let id: String
    public let content: String
    public let metadata: [String: String]
    public let timestamp: TimeInterval
    public let checksum: String
    
    // MARK: - Initialization
    
    /// Creates a new memory entry
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - content: The actual memory content
    ///   - metadata: Additional metadata
    public init(id: String, content: String, metadata: [String: String]) {
        self.id = id
        self.content = content
        self.metadata = metadata
        self.timestamp = Date().timeIntervalSince1970
        self.checksum = MemoryEntry.calculateChecksum(for: content)
    }
    
    /// Private initializer for decoding
    private init(id: String, content: String, metadata: [String: String], 
                timestamp: TimeInterval, checksum: String) {
        self.id = id
        self.content = content
        self.metadata = metadata
        self.timestamp = timestamp
        self.checksum = checksum
    }
    
    // MARK: - JSON Conversion
    
    /// Converts the memory entry to JSON string
    /// - Returns: JSON string representation
    public func toJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            NSLog("[MemoryEntry] Error converting to JSON: \(error)")
            return "{}"
        }
    }
    
    /// Creates a MemoryEntry from JSON string
    /// - Parameter json: JSON string
    /// - Returns: MemoryEntry object or nil if parsing fails
    public static func fromJSON(_ json: String) -> MemoryEntry? {
        guard let data = json.data(using: .utf8) else {
            NSLog("[MemoryEntry] Could not convert JSON string to data")
            return nil
        }
        
        let decoder = JSONDecoder()
        
        do {
            let entry = try decoder.decode(MemoryEntry.self, from: data)
            
            // Verify integrity
            if !entry.verifyIntegrity() {
                NSLog("[MemoryEntry] Memory integrity check failed for: \(entry.id)")
            }
            
            return entry
            
        } catch {
            NSLog("[MemoryEntry] Error parsing JSON: \(error)")
            return nil
        }
    }
    
    // MARK: - Integrity Verification
    
    /// Calculates SHA-256 checksum for integrity verification
    /// - Parameter content: The content to hash
    /// - Returns: Hexadecimal checksum string
    private static func calculateChecksum(for content: String) -> String {
        guard let data = content.data(using: .utf8) else {
            return ""
        }
        
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Verifies the integrity of the memory entry
    /// - Returns: true if integrity check passes
    public func verifyIntegrity() -> Bool {
        let calculatedChecksum = MemoryEntry.calculateChecksum(for: content)
        return calculatedChecksum == checksum
    }
    
    // MARK: - Computed Properties
    
    /// Size of the memory content in bytes
    public var size: Int {
        return content.data(using: .utf8)?.count ?? 0
    }
    
    /// Human-readable description
    public var description: String {
        return "MemoryEntry(id: '\(id)', timestamp: \(timestamp), size: \(size) bytes)"
    }
}
