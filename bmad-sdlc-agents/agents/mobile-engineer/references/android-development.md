# Android Development Guide

> Reference file for the BMAD Mobile Engineer agent.

### 3. Native Android Development

**Mandate:** Build high-quality, performant Android apps following Material Design.

- Use Jetpack Compose for modern UI or XML layouts for View-based approach
- Follow Material Design 3 guidelines: color, typography, elevation, spacing
- Implement MVVM with LiveData/StateFlow for reactive data
- Use Room for persistent storage
- Implement Retrofit + OkHttp for networking
- Handle app lifecycle: onCreate, onStart, onResume, onPause, onStop, onDestroy
- Implement proper dependency injection with Hilt
- Test with Android Emulator and physical devices
- Optimize for various screen sizes and densities

**Android Project Structure:**

```
Project/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/example/app/
│   │   │   │   ├── MainActivity.kt
│   │   │   │   ├── presentation/
│   │   │   │   │   ├── ui/
│   │   │   │   │   │   ├── authentication/
│   │   │   │   │   │   ├── dashboard/
│   │   │   │   │   │   └── common/
│   │   │   │   │   └── viewmodel/
│   │   │   │   ├── domain/
│   │   │   │   │   ├── model/
│   │   │   │   │   ├── usecase/
│   │   │   │   │   └── repository/
│   │   │   │   ├── data/
│   │   │   │   │   ├── api/
│   │   │   │   │   ├── local/
│   │   │   │   │   └── repository/
│   │   │   │   └── di/
│   │   │   ├── res/
│   │   │   │   ├── values/
│   │   │   │   ├── drawable/
│   │   │   │   └── layout/
│   │   │   └── AndroidManifest.xml
│   │   └── test/
│   └── build.gradle.kts
```

**Android Implementation Example:**

```kotlin
// domain/model/User.kt
data class User(
  val id: String,
  val email: String,
  val name: String,
  val createdAt: Long
)

// domain/repository/UserRepository.kt
interface UserRepository {
  suspend fun registerUser(email: String, password: String, name: String): Result<User>
  suspend fun loginUser(email: String, password: String): Result<AuthToken>
  suspend fun getCurrentUser(): Result<User?>
}

// data/api/UserApiService.kt
@Singleton
class UserApiService @Inject constructor(
  private val retrofit: Retrofit
) : UserRepository {
  private val api = retrofit.create(UserApi::class.java)

  override suspend fun registerUser(
    email: String,
    password: String,
    name: String
  ): Result<User> = try {
    val request = RegisterRequest(email, password, name)
    val response = api.register(request)
    Result.success(response)
  } catch (e: HttpException) {
    when (e.code()) {
      409 -> Result.failure(UserException.EmailAlreadyRegistered)
      422 -> Result.failure(UserException.ValidationFailed(e.message ?: "Invalid input"))
      401, 403 -> Result.failure(UserException.Unauthorized)
      else -> Result.failure(UserException.ServerError)
    }
  } catch (e: Exception) {
    Result.failure(UserException.NetworkError(e.message ?: "Unknown error"))
  }
}

interface UserApi {
  @POST("users/register")
  suspend fun register(@Body request: RegisterRequest): User
}

data class RegisterRequest(
  val email: String,
  val password: String,
  val name: String
)

// presentation/viewmodel/AuthViewModel.kt
@HiltViewModel
class AuthViewModel @Inject constructor(
  private val userRepository: UserRepository,
  private val secureStorage: SecureStorage
) : ViewModel() {
  private val _uiState = MutableStateFlow<AuthUIState>(AuthUIState.Idle)
  val uiState: StateFlow<AuthUIState> = _uiState.asStateFlow()

  fun register(email: String, password: String, name: String) {
    viewModelScope.launch {
      _uiState.value = AuthUIState.Loading

      val result = userRepository.registerUser(email, password, name)
      result.onSuccess { user ->
        secureStorage.saveToken("auth_token")
        _uiState.value = AuthUIState.Success(user)
      }.onFailure { exception ->
        val errorMessage = when (exception) {
          is UserException.EmailAlreadyRegistered -> "Email is already registered"
          is UserException.ValidationFailed -> exception.message
          is UserException.NetworkError -> "Network error: ${exception.message}"
          else -> "An unexpected error occurred"
        }
        _uiState.value = AuthUIState.Error(errorMessage)
      }
    }
  }
}

sealed class AuthUIState {
  object Idle : AuthUIState()
  object Loading : AuthUIState()
  data class Success(val user: User) : AuthUIState()
  data class Error(val message: String) : AuthUIState()
}

// presentation/ui/authentication/RegisterScreen.kt
@Composable
fun RegisterScreen(
  viewModel: AuthViewModel = hiltViewModel(),
  onSuccess: () -> Unit
) {
  var email by remember { mutableStateOf("") }
  var password by remember { mutableStateOf("") }
  var name by remember { mutableStateOf("") }
  var confirmPassword by remember { mutableStateOf("") }
  var showPassword by remember { mutableStateOf(false) }

  val uiState by viewModel.uiState.collectAsState()

  Column(
    modifier = Modifier
      .fillMaxSize()
      .padding(16.dp),
    verticalArrangement = Arrangement.Center
  ) {
    TextField(
      value = email,
      onValueChange = { email = it },
      label = { Text("Email") },
      keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
      modifier = Modifier.fillMaxWidth()
    )

    Spacer(modifier = Modifier.height(8.dp))

    TextField(
      value = name,
      onValueChange = { name = it },
      label = { Text("Full Name") },
      modifier = Modifier.fillMaxWidth()
    )

    Spacer(modifier = Modifier.height(8.dp))

    TextField(
      value = password,
      onValueChange = { password = it },
      label = { Text("Password") },
      visualTransformation = if (showPassword) VisualTransformation.None else PasswordVisualTransformation(),
      keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
      modifier = Modifier.fillMaxWidth()
    )

    Spacer(modifier = Modifier.height(8.dp))

    TextField(
      value = confirmPassword,
      onValueChange = { confirmPassword = it },
      label = { Text("Confirm Password") },
      visualTransformation = PasswordVisualTransformation(),
      modifier = Modifier.fillMaxWidth()
    )

    Spacer(modifier = Modifier.height(16.dp))

    when (val state = uiState) {
      is AuthUIState.Loading -> {
        CircularProgressIndicator(modifier = Modifier.align(Alignment.CenterHorizontally))
      }
      is AuthUIState.Error -> {
        Text(state.message, color = Color.Red)
      }
      is AuthUIState.Success -> {
        LaunchedEffect(Unit) { onSuccess() }
      }
      else -> {}
    }

    Button(
      onClick = {
        viewModel.register(email, password, name)
      },
      enabled = email.isNotEmpty() && password == confirmPassword && name.isNotEmpty() &&
          uiState !is AuthUIState.Loading,
      modifier = Modifier.fillMaxWidth()
    ) {
      Text("Create Account")
    }
  }
}
```

**Android Checklist:**
- [ ] Follows Material Design 3 guidelines
- [ ] Uses Jetpack Compose for UI or XML layouts
- [ ] Implements MVVM with LiveData/StateFlow
- [ ] Uses Hilt for dependency injection
- [ ] Handles app lifecycle correctly
- [ ] Tests on emulator and physical device
- [ ] Offline functionality implemented
- [ ] Sensitive data stored securely (EncryptedSharedPreferences)
- [ ] Memory profiling shows no leaks

