package com.londonbridge.ai.example;

import android.app.Application;
import android.util.Log;

import com.londonbridge.ai.memory.MemoryEntry;
import com.londonbridge.ai.memory.SecureMemoryManager;

import java.util.HashMap;
import java.util.Map;

/**
 * Example Android application demonstrating London Bridge AI integration
 */
public class ExampleApp extends Application {
    private static final String TAG = "ExampleApp";
    private SecureMemoryManager memoryManager;
    
    @Override
    public void onCreate() {
        super.onCreate();
        
        try {
            // Initialize memory manager
            memoryManager = new SecureMemoryManager(this);
            Log.i(TAG, "Memory manager initialized");
            
            // Example: Store a conversation memory
            storeConversationExample();
            
            // Example: Retrieve and use a memory
            retrieveMemoryExample();
            
            // Example: Check memory statistics
            checkStatsExample();
            
        } catch (Exception e) {
            Log.e(TAG, "Failed to initialize memory manager", e);
        }
    }
    
    private void storeConversationExample() {
        Map<String, String> metadata = new HashMap<>();
        metadata.put("type", "conversation");
        metadata.put("model", "gpt-4");
        metadata.put("user_id", "user_123");
        metadata.put("topic", "weather");
        
        String interactionId = "conversation_" + System.currentTimeMillis();
        String content = "User: What's the weather like?\n" +
                        "Assistant: I checked the forecast and it will be sunny with " +
                        "a high of 75°F today. Perfect weather for outdoor activities!";
        
        boolean success = memoryManager.storeMemory(interactionId, content, metadata);
        
        if (success) {
            Log.i(TAG, "Stored conversation memory: " + interactionId);
        } else {
            Log.e(TAG, "Failed to store conversation memory");
        }
    }
    
    private void retrieveMemoryExample() {
        // In a real app, you'd retrieve a specific interaction ID
        // For demo purposes, we'll just show the pattern
        
        String interactionId = "conversation_12345";
        MemoryEntry entry = memoryManager.retrieveMemory(interactionId);
        
        if (entry != null) {
            // Verify integrity
            if (entry.verifyIntegrity()) {
                Log.i(TAG, "Retrieved memory: " + entry.getId());
                Log.i(TAG, "Content: " + entry.getContent());
                Log.i(TAG, "Timestamp: " + entry.getTimestamp());
                
                // Use the memory to provide context to AI
                // String context = entry.getContent();
                // aiModel.setContext(context);
                
            } else {
                Log.w(TAG, "Memory integrity check failed!");
            }
        } else {
            Log.i(TAG, "Memory not found: " + interactionId);
        }
    }
    
    private void checkStatsExample() {
        SecureMemoryManager.MemoryStats stats = memoryManager.getMemoryStats();
        
        Log.i(TAG, "Memory Statistics:");
        Log.i(TAG, "  Total memories: " + stats.count);
        Log.i(TAG, "  Total size: " + (stats.totalSizeBytes / 1024) + " KB");
        
        // Alert if getting close to limit
        long maxSizeBytes = 100 * 1024 * 1024; // 100 MB
        double usagePercent = (stats.totalSizeBytes * 100.0) / maxSizeBytes;
        
        if (usagePercent > 80) {
            Log.w(TAG, "Memory usage at " + String.format("%.1f%%", usagePercent));
        }
    }
    
    /**
     * Example: Store AI learning moment
     */
    public void storeAILearning(String topic, String insight) {
        Map<String, String> metadata = new HashMap<>();
        metadata.put("type", "learning");
        metadata.put("topic", topic);
        metadata.put("timestamp", String.valueOf(System.currentTimeMillis()));
        
        String interactionId = "learning_" + topic + "_" + System.currentTimeMillis();
        memoryManager.storeMemory(interactionId, insight, metadata);
    }
    
    /**
     * Example: Retrieve recent memories for context
     */
    public void getRecentContext(long timeRangeMs) {
        long endTime = System.currentTimeMillis();
        long startTime = endTime - timeRangeMs;
        
        var memories = memoryManager.retrieveMemoriesInRange(startTime, endTime);
        
        Log.i(TAG, "Found " + memories.size() + " recent memories");
        
        // Build context from recent memories
        StringBuilder context = new StringBuilder();
        for (MemoryEntry entry : memories) {
            context.append(entry.getContent()).append("\n\n");
        }
        
        // Provide to AI model
        // aiModel.setContext(context.toString());
    }
}
