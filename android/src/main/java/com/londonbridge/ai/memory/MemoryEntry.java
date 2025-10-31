package com.londonbridge.ai.memory;

import android.util.Log;

import androidx.annotation.NonNull;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.UUID;

/**
 * MemoryEntry - Represents a single AI interaction memory
 * Immutable data structure for storing AI conversations and interactions
 */
public class MemoryEntry {
    private static final String TAG = "MemoryEntry";
    
    private final String id;
    private final String content;
    private final Map<String, String> metadata;
    private final long timestamp;
    private final String checksum;
    
    /**
     * Creates a new memory entry
     * 
     * @param id Unique identifier
     * @param content The actual memory content
     * @param metadata Additional metadata
     */
    public MemoryEntry(@NonNull String id, @NonNull String content, @NonNull Map<String, String> metadata) {
        this.id = id;
        this.content = content;
        this.metadata = new HashMap<>(metadata);
        this.timestamp = System.currentTimeMillis();
        this.checksum = calculateChecksum(content);
    }
    
    /**
     * Private constructor for deserialization
     */
    private MemoryEntry(String id, String content, Map<String, String> metadata, 
                       long timestamp, String checksum) {
        this.id = id;
        this.content = content;
        this.metadata = metadata;
        this.timestamp = timestamp;
        this.checksum = checksum;
    }
    
    /**
     * Converts the memory entry to JSON format
     */
    public String toJson() {
        try {
            JSONObject json = new JSONObject();
            json.put("id", id);
            json.put("content", content);
            json.put("timestamp", timestamp);
            json.put("checksum", checksum);
            
            JSONObject metaJson = new JSONObject();
            for (Map.Entry<String, String> entry : metadata.entrySet()) {
                metaJson.put(entry.getKey(), entry.getValue());
            }
            json.put("metadata", metaJson);
            
            return json.toString();
        } catch (JSONException e) {
            Log.e(TAG, "Error converting to JSON", e);
            return "{}";
        }
    }
    
    /**
     * Creates a MemoryEntry from JSON string
     */
    public static MemoryEntry fromJson(@NonNull String json) {
        try {
            JSONObject jsonObj = new JSONObject(json);
            
            String id = jsonObj.getString("id");
            String content = jsonObj.getString("content");
            long timestamp = jsonObj.getLong("timestamp");
            String checksum = jsonObj.getString("checksum");
            
            Map<String, String> metadata = new HashMap<>();
            JSONObject metaJson = jsonObj.getJSONObject("metadata");
            Iterator<String> keys = metaJson.keys();
            while (keys.hasNext()) {
                String key = keys.next();
                metadata.put(key, metaJson.getString(key));
            }
            
            MemoryEntry entry = new MemoryEntry(id, content, metadata, timestamp, checksum);
            
            // Verify integrity
            if (!entry.verifyIntegrity()) {
                Log.w(TAG, "Memory integrity check failed for: " + id);
            }
            
            return entry;
            
        } catch (JSONException e) {
            Log.e(TAG, "Error parsing JSON", e);
            return null;
        }
    }
    
    /**
     * Calculates SHA-256 checksum for integrity verification
     */
    private String calculateChecksum(String content) {
        try {
            java.security.MessageDigest digest = java.security.MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(content.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (Exception e) {
            Log.e(TAG, "Error calculating checksum", e);
            return "";
        }
    }
    
    /**
     * Verifies the integrity of the memory entry
     */
    public boolean verifyIntegrity() {
        String calculatedChecksum = calculateChecksum(content);
        return calculatedChecksum.equals(checksum);
    }
    
    // Getters
    
    public String getId() {
        return id;
    }
    
    public String getContent() {
        return content;
    }
    
    public Map<String, String> getMetadata() {
        return new HashMap<>(metadata);
    }
    
    public long getTimestamp() {
        return timestamp;
    }
    
    public String getChecksum() {
        return checksum;
    }
    
    public long getSize() {
        return content.getBytes(java.nio.charset.StandardCharsets.UTF_8).length;
    }
    
    @Override
    public String toString() {
        return "MemoryEntry{id='" + id + "', timestamp=" + timestamp + 
               ", size=" + getSize() + " bytes}";
    }
}
