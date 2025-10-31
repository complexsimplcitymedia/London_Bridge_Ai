# Architecture Overview

## System Design

London Bridge AI implements a sophisticated mobile memory retention system designed to give AI models persistent memory across sessions while maintaining enterprise-grade security.

## Core Principles

1. **Security First**: All operations protected by multiple security layers
2. **Performance**: Optimized for mobile resource constraints
3. **Reliability**: Resilient to crashes and interruptions
4. **Privacy**: Data never leaves the device without explicit user consent
5. **Simplicity**: Easy integration with minimal API surface

## Component Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Application Layer                       │
│  • AI Assistant App                                          │
│  • Chat Interface                                            │
│  • User Interactions                                         │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                  Public API Surface                          │
│  • storeMemory()                                             │
│  • retrieveMemory()                                          │
│  • getMemoryStats()                                          │
│  • clearAllMemories()                                        │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│            Memory Persistence Manager (Singleton)            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Responsibilities:                                     │  │
│  │ • Background task coordination                        │  │
│  │ • Async operation management                          │  │
│  │ • Health monitoring                                   │  │
│  │ • Emergency backup                                    │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│               Secure Memory Manager (Core)                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Responsibilities:                                     │  │
│  │ • Memory CRUD operations                              │  │
│  │ • Encryption/Decryption                               │  │
│  │ • Memory indexing                                     │  │
│  │ • Storage management                                  │  │
│  │ • Pruning logic                                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
         ↓ ↑                                    ↓ ↑
┌─────────────────────┐              ┌──────────────────────┐
│  Permission Guard   │              │   Memory Entry       │
│  ┌───────────────┐  │              │  ┌────────────────┐  │
│  │ • Access ctrl │  │              │  │ • Data struct  │  │
│  │ • Rate limit  │  │              │  │ • Serialization│  │
│  │ • Audit logs  │  │              │  │ • Integrity    │  │
│  │ • Device sec  │  │              │  │ • Metadata     │  │
│  └───────────────┘  │              │  └────────────────┘  │
└─────────────────────┘              └──────────────────────┘
         ↓ ↑                                    ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                    Platform Storage Layer                    │
│                                                               │
│  Android:                        iOS:                        │
│  • Android Keystore             • Keychain Services          │
│  • EncryptedSharedPreferences   • FileManager                │
│  • Internal Storage             • Documents Directory        │
│  • SQLite (future)              • Core Data (future)         │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Memory Persistence Manager

**Purpose**: Orchestrates background memory operations and lifecycle management

**Responsibilities**:
- Manage background task scheduling
- Coordinate async operations
- Monitor system health
- Handle app lifecycle events
- Perform periodic maintenance

**Key Methods**:
- `start()` - Initialize and start background tasks
- `stop()` - Clean shutdown
- `storeMemoryAsync()` - Async memory storage
- `retrieveMemoryAsync()` - Async memory retrieval
- `performSync()` - Periodic maintenance
- `performEmergencyBackup()` - Pre-termination backup

**Threading Model**:
- Main thread for lifecycle management
- Background thread pool for I/O operations
- Callback dispatch to main thread

### 2. Secure Memory Manager

**Purpose**: Core memory management with encryption

**Responsibilities**:
- Encrypt/decrypt memory content
- Store/retrieve memories from disk
- Manage memory index
- Implement pruning logic
- Generate and manage encryption keys

**Key Methods**:
- `storeMemory()` - Store encrypted memory
- `retrieveMemory()` - Retrieve and decrypt memory
- `retrieveMemoriesInRange()` - Range query
- `deleteMemory()` - Remove specific memory
- `clearAllMemories()` - Nuclear option
- `getMemoryStats()` - Usage statistics

**Storage Structure**:
```
/data/data/com.londonbridge.ai/files/ai_memories/
├── interaction_123.mem  (encrypted binary)
├── interaction_456.mem  (encrypted binary)
└── interaction_789.mem  (encrypted binary)

Metadata in EncryptedSharedPreferences:
- secret_key: [base64 encoded AES key]
- memory_index_*: [timestamp:size pairs]
```

### 3. Permission Guard

**Purpose**: Multi-layered access control and security enforcement

**Responsibilities**:
- Validate access permissions
- Enforce rate limiting
- Log audit trails
- Check device security state
- Verify app signatures

**Security Checks**:
1. Context validation (same package)
2. Storage permission check
3. Rate limit enforcement (100ms cooldown)
4. Device security state validation
5. Audit logging

**Protection Against**:
- Unauthorized access
- Brute force attacks
- Compromised device states
- Malicious apps

### 4. Memory Entry

**Purpose**: Immutable data structure for memory storage

**Structure**:
```json
{
  "id": "interaction_123",
  "content": "Actual conversation or interaction content",
  "metadata": {
    "type": "conversation",
    "model": "gpt-4",
    "user_id": "user_456",
    "context": "weather_query"
  },
  "timestamp": 1698765432123,
  "checksum": "sha256_hash_of_content"
}
```

**Features**:
- SHA-256 integrity verification
- JSON serialization/deserialization
- Immutable design pattern
- Rich metadata support

## Data Flow

### Store Memory Flow

```
User/AI → storeMemoryAsync()
              ↓
    [Permission Check]
              ↓
    [Create MemoryEntry]
              ↓
    [Calculate Checksum]
              ↓
    [Serialize to JSON]
              ↓
    [Encrypt with AES-256-GCM]
              ↓
    [Write to file system]
              ↓
    [Update memory index]
              ↓
    [Check pruning needed]
              ↓
    [Audit log]
              ↓
    Callback(success)
```

### Retrieve Memory Flow

```
User/AI → retrieveMemoryAsync(id)
              ↓
    [Permission Check]
              ↓
    [Check file exists]
              ↓
    [Read encrypted file]
              ↓
    [Decrypt with AES-256-GCM]
              ↓
    [Parse JSON]
              ↓
    [Verify checksum]
              ↓
    [Create MemoryEntry]
              ↓
    [Audit log]
              ↓
    Callback(entry)
```

## Encryption Architecture

### Key Hierarchy

```
Device Hardware Security
        ↓
Android Keystore / iOS Keychain
        ↓
Master Key (AES-256)
        ↓
Memory Encryption Keys (derived or rotated)
        ↓
Individual Memory Files (AES-256-GCM)
```

### Encryption Process

**Android**:
1. Generate 256-bit AES key
2. Store in Android Keystore (hardware-backed)
3. Use AES-GCM for encryption (provides authentication)
4. IV generated per encryption operation
5. Store IV + ciphertext + auth tag

**iOS**:
1. Generate SymmetricKey (256-bit) using CryptoKit
2. Store in Keychain with kSecAttrAccessibleAfterFirstUnlock
3. Use AES.GCM.seal() for encryption
4. Nonce automatically generated
5. Combined format (nonce + ciphertext + tag)

### Key Management

- Keys generated on first use
- Stored in secure hardware when available
- Never transmitted or logged
- Automatic cleanup on app uninstall
- Rotation capability (future enhancement)

## Background Operations

### Android Service

**Service Type**: Bound + Started (START_STICKY)

**Lifecycle**:
1. `onCreate()` - Initialize SecureMemoryManager
2. `onStartCommand()` - Begin background sync
3. `onBind()` - Allow activity binding
4. Periodic sync every 60 seconds
5. `onDestroy()` - Cleanup and final sync

**Thread Pool**: Single-thread executor for serialized I/O

### iOS Background Tasks

**Task Type**: BGAppRefreshTask

**Lifecycle**:
1. Register task identifier in Info.plist
2. Register handler in app launch
3. Schedule tasks with earliest begin date
4. Execute sync on background thread
5. Complete task before expiration
6. Reschedule next task

**Task Identifier**: `com.londonbridge.ai.memory.refresh`

## Performance Characteristics

### Memory Operations

| Operation | Typical Time | Max Time |
|-----------|-------------|----------|
| Store Memory | 50-80ms | 200ms |
| Retrieve Memory | 30-50ms | 100ms |
| Encrypt (1KB) | 1-2ms | 5ms |
| Decrypt (1KB) | 1-2ms | 5ms |
| Integrity Check | 1-2ms | 5ms |

### Resource Usage

| Resource | Idle | Active | Peak |
|----------|------|--------|------|
| RAM | ~2MB | ~5MB | ~10MB |
| CPU | ~0% | ~5% | ~15% |
| Storage | Variable | Variable | 100MB max |
| Battery | Negligible | Low | Low |

### Scalability

- **Max Memories**: Limited by storage (default 100MB)
- **Single Memory Size**: No hard limit, but recommend < 1MB
- **Concurrent Operations**: Serialized via executor
- **Indexing**: O(1) for direct access, O(n) for range queries

## Error Handling

### Graceful Degradation

```
Error Level       Action                    User Impact
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Permission Denied → Return false/null    → Operation fails
Encryption Failed → Log & return error   → Operation fails
Storage Full      → Trigger pruning      → Oldest deleted
File Corrupt      → Log warning          → Skip memory
Integrity Fail    → Log warning          → Return anyway
Key Missing       → Regenerate key       → Transparent
Service Crash     → Auto-restart (Android)→ Delay only
```

### Recovery Mechanisms

1. **Auto-restart**: Android service uses START_STICKY
2. **Emergency backup**: Pre-termination sync
3. **Key regeneration**: Create new key if missing
4. **Integrity warnings**: Log but don't fail
5. **Pruning**: Automatic when storage full

## Testing Strategy

### Unit Tests
- Encryption/decryption correctness
- Memory entry serialization
- Checksum calculation
- Permission guard logic
- Key generation

### Integration Tests
- End-to-end store/retrieve
- Background service lifecycle
- Concurrent operations
- Storage limits
- Error scenarios

### Security Tests
- Unauthorized access attempts
- Rate limiting effectiveness
- Integrity tamper detection
- Key storage security
- Device state validation

## Future Enhancements

### Phase 2
- [ ] Vector embeddings for semantic search
- [ ] Memory compression (LZ4/Zstd)
- [ ] Advanced indexing (SQLite FTS)
- [ ] Cloud backup with E2E encryption

### Phase 3
- [ ] Cross-device sync
- [ ] Memory deduplication
- [ ] AI-powered summarization
- [ ] Federated learning integration

### Phase 4
- [ ] Homomorphic encryption (query encrypted data)
- [ ] Zero-knowledge proofs
- [ ] Blockchain audit trail
- [ ] Decentralized storage options

## Platform Differences

| Feature | Android | iOS |
|---------|---------|-----|
| Key Storage | Keystore | Keychain |
| Background | Service | BGTaskScheduler |
| Encryption | Security Crypto | CryptoKit |
| Min Version | API 23 (6.0) | iOS 13.0 |
| Biometric | BiometricPrompt | LAContext |
| File System | Internal Storage | Documents Dir |

## Dependencies

**Android**:
- androidx.security:security-crypto (encryption)
- androidx.appcompat (compatibility)
- org.json (JSON parsing)

**iOS**:
- CryptoKit (encryption)
- LocalAuthentication (biometrics)
- BackgroundTasks (background processing)

## Migration Path

For apps adopting London Bridge AI:

1. **Integrate**: Add library to project
2. **Initialize**: Create SecureMemoryManager instance
3. **Migrate**: Port existing memory storage
4. **Test**: Verify encryption and retrieval
5. **Deploy**: Roll out to users
6. **Monitor**: Track memory usage and errors

---

**Architecture designed for the future, secured for today.** 🏗️
