# Backend Engineer Implementation Workflow

> Load this reference when starting implementation of a story — covers the 5-step process from reading the story through documenting implementation notes.

### Step 1: Read the Story
```markdown
**Story:** Build User Registration API

**Description:** Allow users to register with email and password.

**Acceptance Criteria:**
- POST /users/register accepts {email, password, name}
- Password validation: >=8 chars, mixed case, at least one number
- Returns 201 with new user object {id, email, name, created_at}
- Returns 409 if email already registered
- Returns 422 if validation fails with detailed error messages

**Acceptance Criteria:** [Story details from docs/stories/...]
```

### Step 2: Check Technical Specifications
- Review `docs/tech-specs/api-spec.md` for endpoint contract
- Review `docs/tech-specs/data-model.md` for User entity schema
- Check `docs/architecture/solution-architecture.md` for service topology
- Read any relevant ADRs (e.g., "Decision on password hashing algorithm")

### Step 3: Implement the Feature

**File structure:**
```
src/
├── api/
│   └── handlers/user_handler.go        # HTTP handlers
├── service/
│   └── user_service.go                 # Business logic
├── repository/
│   └── user_repository.go              # Data access
├── model/
│   └── user.go                         # Domain model
└── middleware/
    └── auth_middleware.go              # Authentication
```

**Example implementation (Go pseudocode):**

```go
// api/handlers/user_handler.go
type UserHandler struct {
  service UserService
  logger  Logger
}

func (h *UserHandler) Register(w http.ResponseWriter, r *http.Request) {
  ctx := r.Context()
  correlationID := r.Header.Get("X-Correlation-ID")

  h.logger.Info("user.register.start", Log{
    "correlation_id": correlationID,
  })

  var req RegisterRequest
  if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
    h.logger.Error("user.register.validation_failed", Log{
      "error": err.Error(),
      "correlation_id": correlationID,
    })
    w.WriteHeader(http.StatusUnprocessableEntity)
    json.NewEncoder(w).Encode(ErrorResponse{
      Type: "https://api.example.com/problems/validation-error",
      Title: "Validation Failed",
      Detail: "Invalid request body",
      Status: 422,
    })
    return
  }

  user, err := h.service.RegisterUser(ctx, req.Email, req.Password, req.Name)
  if err != nil {
    if errors.Is(err, ErrEmailAlreadyRegistered) {
      h.logger.Warn("user.register.duplicate_email", Log{
        "email": req.Email,
        "correlation_id": correlationID,
      })
      w.WriteHeader(http.StatusConflict)
      json.NewEncoder(w).Encode(ErrorResponse{
        Type: "https://api.example.com/problems/duplicate-email",
        Title: "Email Already Registered",
        Status: 409,
      })
      return
    }

    h.logger.Error("user.register.service_error", Log{
      "error": err.Error(),
      "correlation_id": correlationID,
    })
    w.WriteHeader(http.StatusInternalServerError)
    json.NewEncoder(w).Encode(ErrorResponse{
      Type: "https://api.example.com/problems/internal-error",
      Title: "Internal Server Error",
      Status: 500,
    })
    return
  }

  h.logger.Info("user.register.success", Log{
    "user_id": user.ID,
    "correlation_id": correlationID,
  })

  w.WriteHeader(http.StatusCreated)
  json.NewEncoder(w).Encode(user)
}

// service/user_service.go
type UserService interface {
  RegisterUser(ctx context.Context, email, password, name string) (*User, error)
}

type userService struct {
  repo   UserRepository
  logger Logger
}

func (s *userService) RegisterUser(ctx context.Context, email, password, name string) (*User, error) {
  // Validate password strength
  if err := ValidatePassword(password); err != nil {
    return nil, fmt.Errorf("invalid password: %w", err)
  }

  // Hash password
  hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
  if err != nil {
    return nil, fmt.Errorf("failed to hash password: %w", err)
  }

  // Create user entity
  user := &User{
    ID:       uuid.New().String(),
    Email:    email,
    Password: string(hashedPassword),
    Name:     name,
    CreatedAt: time.Now(),
  }

  // Persist to database
  if err := s.repo.Create(ctx, user); err != nil {
    if errors.Is(err, ErrDuplicateEmail) {
      return nil, ErrEmailAlreadyRegistered
    }
    return nil, fmt.Errorf("failed to create user: %w", err)
  }

  // Return user without password
  return &User{
    ID:        user.ID,
    Email:     user.Email,
    Name:      user.Name,
    CreatedAt: user.CreatedAt,
  }, nil
}

// repository/user_repository.go
type UserRepository interface {
  Create(ctx context.Context, user *User) error
  GetByEmail(ctx context.Context, email string) (*User, error)
}

type userRepository struct {
  db *sql.DB
}

func (r *userRepository) Create(ctx context.Context, user *User) error {
  query := `
    INSERT INTO users (id, email, password, name, created_at)
    VALUES ($1, $2, $3, $4, $5)
  `

  _, err := r.db.ExecContext(ctx, query, user.ID, user.Email, user.Password, user.Name, user.CreatedAt)
  if err != nil {
    // Check for unique constraint violation
    if strings.Contains(err.Error(), "duplicate key") {
      return ErrDuplicateEmail
    }
    return fmt.Errorf("database insert failed: %w", err)
  }

  return nil
}
```

### Step 4: Write Tests

```go
// handlers/user_handler_test.go
func TestUserHandlerRegister(t *testing.T) {
  tests := []struct {
    name           string
    req            RegisterRequest
    mockService    func(m *MockUserService)
    expectedStatus int
    expectedBody   interface{}
  }{
    {
      name: "successful registration",
      req:  RegisterRequest{Email: "john@example.com", Password: "SecurePass123", Name: "John"},
      mockService: func(m *MockUserService) {
        m.On("RegisterUser", mock.Anything, "john@example.com", "SecurePass123", "John").
          Return(&User{ID: "123", Email: "john@example.com"}, nil)
      },
      expectedStatus: 201,
    },
    {
      name: "duplicate email returns 409",
      req:  RegisterRequest{Email: "existing@example.com", Password: "SecurePass123", Name: "John"},
      mockService: func(m *MockUserService) {
        m.On("RegisterUser", mock.Anything, "existing@example.com", "SecurePass123", "John").
          Return(nil, ErrEmailAlreadyRegistered)
      },
      expectedStatus: 409,
    },
  }

  for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
      // Arrange
      mockService := new(MockUserService)
      tt.mockService(mockService)
      handler := &UserHandler{service: mockService}

      body, _ := json.Marshal(tt.req)
      req := httptest.NewRequest("POST", "/users/register", bytes.NewReader(body))
      w := httptest.NewRecorder()

      // Act
      handler.Register(w, req)

      // Assert
      assert.Equal(t, tt.expectedStatus, w.Code)
    })
  }
}
```

### Step 5: Document Implementation Notes

Create `docs/implementation-notes/user-registration.md`:

```markdown
## User Registration Service Implementation Notes

### Design Decisions
- **Password Hashing:** Used bcrypt with default cost (10 rounds) per ADR-003
- **Email Uniqueness:** Database constraint + service-level check for race condition handling
- **Correlation IDs:** Required on all requests for distributed tracing

### Performance Considerations
- Email lookup uses indexed query on users.email (UNIQUE INDEX)
- No N+1 issues; single INSERT operation
- Password hashing is CPU-bound (~100ms); consider async registration in future for high-volume

### Security Notes
- Passwords are hashed with bcrypt; never logged or returned
- Rate limiting on /register endpoint: 5 requests/minute per IP
- Email verification not implemented in this phase

### API Contract
- See docs/tech-specs/api-spec.md for full OpenAPI definition
- Error responses follow RFC 7807 problem statement format
- All timestamps are ISO 8601 UTC

### Testing
- 8 unit tests covering happy path, validation failures, duplicate email
- Integration tests with real PostgreSQL database
- No external service calls (fully testable in isolation)
```

