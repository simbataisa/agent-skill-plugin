# Mobile Platform Features: Offline, Push & Security

> Reference file for the BMAD Mobile Engineer agent.

### 5. Offline-First Architecture

**Mandate:** Design apps that work seamlessly offline and sync when online.

**Strategy:**
1. **Local Database:** Store data in SQLite (native) or Realm for fast access
2. **Sync Engine:** Track changes locally, batch requests when online
3. **Conflict Resolution:** Handle conflicts when device data diverges from server
4. **Change Tracking:** Maintain operation queue (INSERT, UPDATE, DELETE)

**Example - Offline-First Sync:**

```swift
// iOS - Sync implementation
class SyncEngine {
  let operationQueue: OperationQueue
  let networkMonitor: NetworkMonitor
  let localRepository: LocalRepository
  let apiRepository: APIRepository

  func enqueueOperation(_ operation: DatabaseOperation) {
    localRepository.save(operation)
    trySync()
  }

  func trySync() {
    guard networkMonitor.isConnected else { return }

    let pendingOperations = localRepository.getPendingOperations()
    for operation in pendingOperations {
      executeOperation(operation)
    }
  }

  private func executeOperation(_ operation: DatabaseOperation) {
    switch operation.type {
    case .create:
      apiRepository.create(operation.entity) { result in
        if case .success = result {
          self.localRepository.markSynced(operation.id)
        }
      }
    case .update:
      apiRepository.update(operation.entity) { result in
        if case .success = result {
          self.localRepository.markSynced(operation.id)
        }
      }
    case .delete:
      apiRepository.delete(operation.entityId) { result in
        if case .success = result {
          self.localRepository.markSynced(operation.id)
        }
      }
    }
  }
}
```

### 6. Push Notifications

**Mandate:** Implement reliable push notification delivery and handling.

**iOS Implementation:**
```swift
// Push notification request
func requestUserNotificationPermission() {
  UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
    if granted {
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }
}

// Handle notification reception
func userNotificationCenter(
  _ center: UNUserNotificationCenter,
  willPresent notification: UNNotification,
  withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
) {
  let userInfo = notification.request.content.userInfo

  // Parse notification payload
  if let eventType = userInfo["event_type"] as? String {
    handleNotificationEvent(eventType, payload: userInfo)
  }

  completionHandler([.banner, .sound, .badge])
}
```

**Android Implementation:**
```kotlin
// Firebase Cloud Messaging
class MyFirebaseMessagingService : FirebaseMessagingService() {
  override fun onMessageReceived(remoteMessage: RemoteMessage) {
    val data = remoteMessage.data
    val eventType = data["event_type"]

    if (eventType != null) {
      handleNotificationEvent(eventType, data)
    }
  }

  private fun handleNotificationEvent(eventType: String, data: Map<String, String>) {
    val notification = NotificationCompat.Builder(this, CHANNEL_ID)
      .setSmallIcon(R.drawable.ic_notification)
      .setContentTitle(data["title"])
      .setContentText(data["body"])
      .setContentIntent(
        PendingIntent.getActivity(
          this, 0,
          Intent(this, MainActivity::class.java).apply {
            putExtra("event_type", eventType)
          },
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
      )
      .build()

    NotificationManagerCompat.from(this).notify(1, notification)
  }
}
```

### 7. Mobile Security

**Mandate:** Implement robust security practices for mobile apps.

**Security Checklist:**
- [ ] API communication uses HTTPS with certificate pinning
- [ ] Authentication tokens stored in secure storage (Keychain/Keystore)
- [ ] Passwords hashed before storage (never store plaintext)
- [ ] Deep links validated to prevent deep link attacks
- [ ] Sensitive data not logged (no PII in logs)
- [ ] App implements jailbreak/root detection
- [ ] Biometric authentication implemented where available
- [ ] Local database encrypted (SQLCipher)
- [ ] Third-party dependencies scanned for vulnerabilities
- [ ] Secrets not hardcoded; use configuration management

**Certificate Pinning Example:**

```swift
// iOS - Certificate Pinning
func configureURLSession() -> URLSession {
  let config = URLSessionConfiguration.default
  let delegate = CertificatePinningDelegate()
  return URLSession(configuration: config, delegate: delegate, delegateQueue: .main)
}

class CertificatePinningDelegate: NSObject, URLSessionDelegate {
  private let pinnedCertificates: [SecCertificate] = {
    guard let certData = NSData(contentsOfFile: Bundle.main.path(forResource: "certificate", ofType: "cer") ?? "") as Data? else {
      return []
    }
    return [SecCertificateCreateWithData(nil, certData as CFData)!]
  }()

  func urlSession(
    _ session: URLSession,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  ) {
    guard let serverTrust = challenge.protectionSpace.serverTrust else {
      completionHandler(.cancelAuthenticationChallenge, nil)
      return
    }

    // Verify certificate chain
    var secResult = SecTrustResultType.invalid
    SecTrustEvaluate(serverTrust, &secResult)

    if secResult == .unspecified || secResult == .proceed {
      // Check if pinned certificate matches
      let certificateCount = SecTrustGetCertificateCount(serverTrust)
      for i in 0..<certificateCount {
        if let certificate = SecTrustGetCertificateAtIndex(serverTrust, i) {
          for pinnedCert in pinnedCertificates {
            if certificate == pinnedCert {
              completionHandler(.useCredential, URLCredential(trust: serverTrust))
              return
            }
          }
        }
      }
    }

    completionHandler(.cancelAuthenticationChallenge, nil)
  }
}
```

