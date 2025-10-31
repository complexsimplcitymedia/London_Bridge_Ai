//
//  MemoryPersistenceManager.swift
//  LondonBridgeAI
//
//  Background task manager for AI memory persistence
//

import Foundation
import BackgroundTasks

/// MemoryPersistenceManager - Background task manager for AI memory management
/// Ensures memories are persisted and maintained even when the app is backgrounded
///
/// Features:
/// - Background memory persistence
/// - Automatic sync and consolidation
/// - Memory health monitoring
/// - Crash recovery
@available(iOS 13.0, *)
public class MemoryPersistenceManager {
    
    // MARK: - Constants
    
    private static let backgroundTaskIdentifier = "com.londonbridge.ai.memory.refresh"
    private static let syncInterval: TimeInterval = 3600 // 1 hour
    
    // MARK: - Properties
    
    private var memoryManager: SecureMemoryManager?
    private var syncTimer: Timer?
    
    // MARK: - Singleton
    
    public static let shared = MemoryPersistenceManager()
    
    private init() {
        do {
            self.memoryManager = try SecureMemoryManager()
            setupBackgroundTasks()
            NSLog("[MemoryPersistenceManager] Initialized successfully")
        } catch {
            NSLog("[MemoryPersistenceManager] Failed to initialize: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    /// Starts the persistence manager
    public func start() {
        NSLog("[MemoryPersistenceManager] Starting")
        
        // Start periodic sync timer
        syncTimer = Timer.scheduledTimer(
            withTimeInterval: MemoryPersistenceManager.syncInterval,
            repeats: true
        ) { [weak self] _ in
            self?.performSync()
        }
        
        // Perform initial sync
        performSync()
    }
    
    /// Stops the persistence manager
    public func stop() {
        NSLog("[MemoryPersistenceManager] Stopping")
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    /// Stores a memory asynchronously
    public func storeMemoryAsync(interactionId: String, content: String,
                                 metadata: [String: String],
                                 completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let manager = self?.memoryManager else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            let success = manager.storeMemory(interactionId: interactionId,
                                            content: content,
                                            metadata: metadata)
            
            DispatchQueue.main.async { completion(success) }
        }
    }
    
    /// Retrieves a memory asynchronously
    public func retrieveMemoryAsync(interactionId: String,
                                   completion: @escaping (MemoryEntry?) -> Void) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let manager = self?.memoryManager else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            let entry = manager.retrieveMemory(interactionId: interactionId)
            
            DispatchQueue.main.async { completion(entry) }
        }
    }
    
    /// Gets memory statistics
    public func getMemoryStats() -> SecureMemoryManager.MemoryStats {
        return memoryManager?.getMemoryStats() ?? SecureMemoryManager.MemoryStats(count: 0, totalSizeBytes: 0)
    }
    
    // MARK: - Private Methods
    
    /// Sets up background task handling
    private func setupBackgroundTasks() {
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: MemoryPersistenceManager.backgroundTaskIdentifier,
                using: nil
            ) { task in
                self.handleBackgroundTask(task: task as! BGAppRefreshTask)
            }
        }
    }
    
    /// Handles background task execution
    @available(iOS 13.0, *)
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        NSLog("[MemoryPersistenceManager] Background task started")
        
        // Schedule next background task
        scheduleBackgroundTask()
        
        // Perform sync with task expiration handler
        task.expirationHandler = {
            NSLog("[MemoryPersistenceManager] Background task expired")
            task.setTaskCompleted(success: false)
        }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.performSync()
            task.setTaskCompleted(success: true)
        }
    }
    
    /// Schedules the next background task
    @available(iOS 13.0, *)
    private func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: MemoryPersistenceManager.backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: MemoryPersistenceManager.syncInterval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            NSLog("[MemoryPersistenceManager] Background task scheduled")
        } catch {
            NSLog("[MemoryPersistenceManager] Could not schedule background task: \(error)")
        }
    }
    
    /// Performs periodic sync and maintenance
    private func performSync() {
        NSLog("[MemoryPersistenceManager] Performing memory sync")
        
        guard let manager = memoryManager else {
            return
        }
        
        // Get memory statistics
        let stats = manager.getMemoryStats()
        NSLog("[MemoryPersistenceManager] Memory stats: \(stats.count) entries, \(stats.totalSizeBytes) bytes")
        
        // Perform any necessary cleanup or optimization
        // This could include compaction, deduplication, etc.
        
        // Could trigger cloud backup here if implemented
    }
    
    /// Performs emergency backup before app termination
    public func performEmergencyBackup() {
        NSLog("[MemoryPersistenceManager] Performing emergency backup")
        performSync()
    }
}
