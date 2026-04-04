# Cross-Platform Development Guide (React Native / Flutter)

> Reference file for the BMAD Mobile Engineer agent.

### 4. Cross-Platform Development (React Native / Flutter)

**Mandate:** Build iOS and Android apps with shared codebase while maintaining native performance.

**React Native:**
```javascript
// navigation/RootNavigator.tsx
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { RegisterScreen } from '../screens/RegisterScreen';
import { DashboardScreen } from '../screens/DashboardScreen';

const Stack = createNativeStackNavigator();

export const RootNavigator = () => {
  const { isAuthenticated } = useAuth();

  return (
    <NavigationContainer>
      <Stack.Navigator>
        {!isAuthenticated ? (
          <Stack.Screen
            name="Auth"
            component={RegisterScreen}
            options={{ headerShown: false }}
          />
        ) : (
          <Stack.Screen
            name="Dashboard"
            component={DashboardScreen}
            options={{ headerTitle: 'Home' }}
          />
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
};

// screens/RegisterScreen.tsx
import React, { useState } from 'react';
import {
  View,
  TextInput,
  TouchableOpacity,
  Text,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { useAuth } from '../hooks/useAuth';

export const RegisterScreen: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const { register, isLoading, error } = useAuth();

  const handleRegister = async () => {
    await register(email, password, name);
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Create Account</Text>

      <TextInput
        style={styles.input}
        placeholder="Email"
        value={email}
        onChangeText={setEmail}
        keyboardType="email-address"
        autoCapitalize="none"
      />

      <TextInput
        style={styles.input}
        placeholder="Full Name"
        value={name}
        onChangeText={setName}
      />

      <TextInput
        style={styles.input}
        placeholder="Password"
        value={password}
        onChangeText={setPassword}
        secureTextEntry
      />

      {error && <Text style={styles.error}>{error}</Text>}

      <TouchableOpacity
        style={[styles.button, isLoading && styles.buttonDisabled]}
        onPress={handleRegister}
        disabled={isLoading}
      >
        {isLoading ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.buttonText}>Create Account</Text>
        )}
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    justifyContent: 'center',
    backgroundColor: '#fff',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 16,
    textAlign: 'center',
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    marginBottom: 12,
    fontSize: 16,
  },
  button: {
    backgroundColor: '#007AFF',
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
  },
  buttonDisabled: {
    opacity: 0.5,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  error: {
    color: 'red',
    marginBottom: 12,
    fontSize: 14,
  },
});
```

**Flutter:**
```dart
// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Account')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Consumer<AuthViewModel>(
          builder: (context, authVm, _) {
            return ListView(
              children: [
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 12),
                if (authVm.error != null)
                  Text(
                    authVm.error!,
                    style: TextStyle(color: Colors.red),
                  ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: authVm.isLoading
                      ? null
                      : () {
                          authVm.register(
                            _emailController.text,
                            _passwordController.text,
                            _nameController.text,
                          );
                        },
                  child: authVm.isLoading
                      ? CircularProgressIndicator()
                      : Text('Create Account'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// lib/viewmodels/auth_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../repositories/user_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  bool _isLoading = false;
  String? _error;
  User? _user;

  AuthViewModel(this._userRepository);

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;

  Future<void> register(String email, String password, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _userRepository.registerUser(email, password, name);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

