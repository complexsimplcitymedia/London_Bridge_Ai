//
//  ExampleApp.swift
//  LondonBridgeAI Example
//
//  Example iOS application demonstrating London Bridge AI integration
//

import UIKit

@available(iOS 13.0, *)
@main
class ExampleApp: UIApplication {
    
    private var memoryManager: SecureMemoryManager?
    
    override init() {
        super.init()
        
        do {
            // Initialize memory manager
            memoryManager = try SecureMemoryManager()
            print("[ExampleApp] Memory manager initialized")
            
            // Example: Store a conversation memory
            storeConversationExample()
            
            // Example: Retrieve and use a memory
            retrieveMemoryExample()
            
            // Example: Check memory statistics
            checkStatsExample()
            
        } catch {
            print("[ExampleApp] Failed to initialize memory manager: \(error)")
        }
    }
    
    private func storeConversationExample() {
        guard let manager = memoryManager else { return }
        
        let metadata = [
            "type": "conversation",
            "model": "gpt-4",
            "user_id": "user_123",
            "topic": "weather"
        ]
        
        let interactionId = "conversation_\(Int(Date().timeIntervalSince1970))"
        let content = """
        User: What's the weather like?
        Assistant: I checked the forecast and it will be sunny with a high of 75°F today. Perfect weather for outdoor activities!
        """
        
        let success = manager.storeMemory(
            interactionId: interactionId,
            content: content,
            metadata: metadata
        )
        
        if success {
            print("[ExampleApp] Stored conversation memory: \(interactionId)")
        } else {
            print("[ExampleApp] Failed to store conversation memory")
        }
    }
    
    private func retrieveMemoryExample() {
        guard let manager = memoryManager else { return }
        
        // In a real app, you'd retrieve a specific interaction ID
        // For demo purposes, we'll just show the pattern
        
        let interactionId = "conversation_12345"
        
        if let entry = manager.retrieveMemory(interactionId: interactionId) {
            // Verify integrity
            if entry.verifyIntegrity() {
                print("[ExampleApp] Retrieved memory: \(entry.id)")
                print("[ExampleApp] Content: \(entry.content)")
                print("[ExampleApp] Timestamp: \(entry.timestamp)")
                
                // Use the memory to provide context to AI
                // let context = entry.content
                // aiModel.setContext(context)
                
            } else {
                print("[ExampleApp] Memory integrity check failed!")
            }
        } else {
            print("[ExampleApp] Memory not found: \(interactionId)")
        }
    }
    
    private func checkStatsExample() {
        guard let manager = memoryManager else { return }
        
        let stats = manager.getMemoryStats()
        
        print("[ExampleApp] Memory Statistics:")
        print("[ExampleApp]   Total memories: \(stats.count)")
        print("[ExampleApp]   Total size: \(stats.totalSizeBytes / 1024) KB")
        
        // Alert if getting close to limit
        let maxSizeBytes: Int64 = 100 * 1024 * 1024 // 100 MB
        let usagePercent = Double(stats.totalSizeBytes) * 100.0 / Double(maxSizeBytes)
        
        if usagePercent > 80 {
            print("[ExampleApp] Memory usage at \(String(format: "%.1f%%", usagePercent))")
        }
    }
    
    /// Example: Store AI learning moment
    func storeAILearning(topic: String, insight: String) {
        guard let manager = memoryManager else { return }
        
        let metadata = [
            "type": "learning",
            "topic": topic,
            "timestamp": String(Int(Date().timeIntervalSince1970))
        ]
        
        let interactionId = "learning_\(topic)_\(Int(Date().timeIntervalSince1970))"
        _ = manager.storeMemory(interactionId: interactionId, content: insight, metadata: metadata)
    }
    
    /// Example: Retrieve recent memories for context
    func getRecentContext(timeRangeSeconds: TimeInterval) {
        guard let manager = memoryManager else { return }
        
        let endTime = Date().timeIntervalSince1970
        let startTime = endTime - timeRangeSeconds
        
        let memories = manager.retrieveMemories(inRange: startTime, endTime: endTime)
        
        print("[ExampleApp] Found \(memories.count) recent memories")
        
        // Build context from recent memories
        var context = ""
        for entry in memories {
            context += entry.content + "\n\n"
        }
        
        // Provide to AI model
        // aiModel.setContext(context)
    }
}

@available(iOS 13.0, *)
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Start persistence manager
        let persistenceManager = MemoryPersistenceManager.shared
        persistenceManager.start()
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Perform emergency backup
        let persistenceManager = MemoryPersistenceManager.shared
        persistenceManager.performEmergencyBackup()
    }
}
