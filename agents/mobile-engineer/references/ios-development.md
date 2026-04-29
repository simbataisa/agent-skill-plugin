# iOS Development Guide

> Reference file for the BMAD Mobile Engineer agent.

### 1. Mobile Architecture and Platform Selection

**Mandate:** Choose the right technology stack and architect scalable mobile solutions.

- Review **Solution Architecture** (`docs/architecture/solution-architecture.md`) for mobile requirements
- Evaluate platform selection: native (iOS/Android) vs. cross-platform (React Native, Flutter)
- Document architecture decisions in Architecture Decision Records (ADRs)
- Design separation of concerns: UI Layer, Business Logic, Data Layer, Integration Layer

**Platform Selection Criteria:**

| Criterion | Native iOS | Native Android | React Native | Flutter |
|-----------|------------|----------------|--------------|---------|
| **Performance** | Excellent | Excellent | Good | Very Good |
| **Platform APIs** | Full access | Full access | Bridge-based | Comprehensive bindings |
| **Code Reuse** | Swift (iOS only) | Kotlin (Android only) | JavaScript/TypeScript | Dart |
| **Time to Market** | Longer | Longer | Faster (shared code) | Faster (shared code) |
| **UI Control** | Maximum | Maximum | Good (native components) | Excellent (custom rendering) |
| **Learning Curve** | Steep (Swift/ObjC) | Steep (Kotlin/Java) | Moderate | Moderate |
| **Team Requirement** | iOS specialist | Android specialist | Full-stack JavaScript | Full-stack Flutter |

**Architecture Pattern:**

```
┌─────────────────────────────┐
│      UI Layer               │ ← SwiftUI (iOS), Jetpack Compose (Android), React Native, Flutter
├─────────────────────────────┤
│  View Model / State         │ ← MVVM pattern, reactive state management
├─────────────────────────────┤
│  Domain Layer / Use Cases   │ ← Business logic, independent of platform
├─────────────────────────────┤
│  Data Layer / Repository    │ ← Abstract data sources (API, local DB, cache)
├─────────────────────────────┤
│  Integration Layer          │ ← API client, local storage, push notifications
└─────────────────────────────┘
```

### 2. Native iOS Development

**Mandate:** Build high-quality, performant iOS apps following Apple guidelines.

- Use SwiftUI for modern UI (iOS 15+) or UIKit for older versions
- Follow Apple's Human Interface Guidelines (HIG): spacing, colors, typography, interactions
- Implement MVVM or Clean Architecture pattern
- Use Core Data or Realm for persistent storage
- Implement network layer with URLSession or Alamofire
- Handle app lifecycle: launch, suspend, resume, terminate
- Implement proper memory management (avoid retain cycles with `[weak self]`)
- Test with Xcode Simulator and physical devices
- Optimize for different screen sizes (iPhone, iPad)

**iOS Project Structure:**

```
Project/
├── App/
│   ├── App.swift                      # App entry point
│   ├── SceneDelegate.swift            # Scene management
│   └── AppDelegate.swift              # App initialization
├── Presentation/
│   ├── Views/
│   │   ├── Authentication/
│   │   ├── Dashboard/
│   │   └── Common/
│   ├── ViewModels/
│   │   └── ...
│   └── Modifiers/                     # SwiftUI view modifiers
├── Domain/
│   ├── Models/
│   │   └── User.swift
│   ├── UseCases/
│   │   └── LoginUseCase.swift
│   └── Repositories/
│       └── UserRepository.swift
├── Data/
│   ├── API/
│   │   └── APIClient.swift
│   ├── Persistence/
│   │   └── CoreDataStack.swift
│   └── Cache/
│       └── CacheManager.swift
├── Infrastructure/
│   ├── Logging/
│   ├── Analytics/
│   └── Push Notifications/
└── Resources/
    ├── Localizable.strings
    └── Assets/
```

**iOS Implementation Example:**

```swift
// Domain/Models/User.swift
struct User: Codable, Identifiable {
  let id: String
  let email: String
  let name: String
  let createdAt: Date
}

// Domain/Repositories/UserRepository.swift
protocol UserRepository {
  func registerUser(email: String, password: String, name: String) async throws -> User
  func loginUser(email: String, password: String) async throws -> AuthToken
  func getCurrentUser() async throws -> User?
}

// Data/API/APIClient.swift
class APIClient: UserRepository {
  let baseURL = URL(string: "https://api.example.com")!
  let session: URLSession

  func registerUser(email: String, password: String, name: String) async throws -> User {
    let endpoint = baseURL.appendingPathComponent("/users/register")

    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = RegisterRequest(email: email, password: password, name: name)
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try JSONDecoder().decode(User.self, from: data)
    case 409:
      throw APIError.emailAlreadyRegistered
    case 422:
      let error = try JSONDecoder().decode(ValidationError.self, from: data)
      throw APIError.validationFailed(error)
    case 401, 403:
      throw APIError.unauthorized
    default:
      throw APIError.serverError(httpResponse.statusCode)
    }
  }
}

// Presentation/ViewModels/AuthViewModel.swift
@MainActor
class AuthViewModel: ObservableObject {
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var user: User?
  @Published var isAuthenticated = false

  private let userRepository: UserRepository
  private let keychainService: KeychainService

  init(userRepository: UserRepository, keychainService: KeychainService) {
    self.userRepository = userRepository
    self.keychainService = keychainService
  }

  func register(email: String, password: String, name: String) async {
    isLoading = true
    errorMessage = nil

    do {
      let user = try await userRepository.registerUser(email: email, password: password, name: name)
      self.user = user
      self.isAuthenticated = true
      try keychainService.saveToken("auth_token") // Store auth token
      isLoading = false
    } catch let error as APIError {
      isLoading = false
      errorMessage = error.userMessage
    } catch {
      isLoading = false
      errorMessage = "An unexpected error occurred"
    }
  }
}

// Presentation/Views/RegisterView.swift
struct RegisterView: View {
  @StateObject var viewModel: AuthViewModel
  @State var email = ""
  @State var password = ""
  @State var name = ""
  @State var confirmPassword = ""
  @State var showPassword = false

  var body: some View {
    NavigationStack {
      Form {
        Section("Account Information") {
          TextField("Email", text: $email)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocorrectionDisabled()

          TextField("Full Name", text: $name)
            .textContentType(.name)

          SecureField("Password", text: $password)

          SecureField("Confirm Password", text: $confirmPassword)
        }

        Section {
          if viewModel.isLoading {
            HStack {
              Spacer()
              ProgressView()
              Spacer()
            }
          } else {
            Button(action: { register() }) {
              Text("Create Account")
                .frame(maxWidth: .infinity)
            }
            .disabled(!isFormValid)
          }
        }

        if let errorMessage = viewModel.errorMessage {
          Section {
            Text(errorMessage)
              .foregroundColor(.red)
          }
        }
      }
      .navigationTitle("Create Account")
    }
  }

  private func register() {
    Task {
      await viewModel.register(email: email, password: password, name: name)
    }
  }

  private var isFormValid: Bool {
    !email.isEmpty && !password.isEmpty && password == confirmPassword && !name.isEmpty
  }
}
```

**iOS Checklist:**
- [ ] Follows Apple Human Interface Guidelines
- [ ] Uses SwiftUI for UI (or UIKit if required)
- [ ] Implements MVVM or Clean Architecture
- [ ] Handles all device orientations and sizes
- [ ] Tests on physical device and simulator
- [ ] Memory profiling shows no leaks
- [ ] Network calls have proper error handling
- [ ] Sensitive data stored in Keychain
- [ ] Supports offline functionality where needed

