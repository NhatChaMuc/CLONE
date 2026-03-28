# Models Documentation

## Overview
Models folder contains all data models and DTOs (Data Transfer Objects) used in the Flutter app. Each model has methods to handle serialization/deserialization and provides a clear structure for data handling.

## Available Models

### 1. **UserModel** (`user_model.dart`)
Represents a user in the application.

```dart
import 'package:mobile/models/user_model.dart';

// Create from Firestore data
UserModel user = UserModel.fromFirestore(uid, docData);

// Convert to Firestore
Map<String, dynamic> data = user.toFirestore();

// Copy with modifications
UserModel updated = user.copyWith(fullName: 'New Name');
```

**Properties:**
- `uid` - Unique user identifier (Firebase UID)
- `email` - User email
- `fullName` - User's full name
- `createdAt` - Account creation timestamp
- `lastLoginAt` - Last login timestamp
- `totalPoints` - Total learning points
- `totalMinutesLearned` - Total learning duration
- `completedTopics` - List of completed topic IDs

---

### 2. **TopicModel** (`topic_model.dart`)
Represents a learning topic from the backend API.

```dart
import 'package:mobile/models/topic_model.dart';

// Create from API JSON
TopicModel topic = TopicModel.fromJson(apiResponse);

// Convert to JSON
Map<String, dynamic> json = topic.toJson();

// Copy with modifications
TopicModel updated = topic.copyWith(difficulty: 3);
```

**Properties:**
- `id` - Topic identifier
- `title` - Topic title
- `description` - Topic description
- `imageUrl` - Topic image URL (optional)
- `difficulty` - Difficulty level (1-5)
- `totalLessons` - Number of lessons
- `keywords` - Related keywords

---

### 3. **PracticeModel** (`practice_model.dart`)
Represents a user's practice session/attempt.

```dart
import 'package:mobile/models/practice_model.dart';

// Create from Firestore
PracticeModel practice = PracticeModel.fromFirestore(docId, docData);

// Convert to Firestore
Map<String, dynamic> data = practice.toFirestore();
```

**Properties:**
- `id` - Practice session ID
- `userId` - User's UID
- `topicId` - Associated topic ID
- `practiceType` - Type: 'conversation', 'shadowing', 'transcribe', 'tongue_twister'
- `sentence` - The practice sentence
- `transcribedText` - User's transcription
- `accuracy` - Accuracy percentage (0.0 - 1.0)
- `pointsEarned` - Points earned in this session
- `createdAt` - Session start time
- `completedAt` - Session completion time
- `isCompleted` - Whether session is completed

---

### 4. **TongueTwisterModel** (`tongue_twister_model.dart`)
Represents a tongue twister challenge.

```dart
import 'package:mobile/models/tongue_twister_model.dart';

// Create from API JSON
TongueTwisterModel twister = TongueTwisterModel.fromJson(apiResponse);

// Convert to JSON
Map<String, dynamic> json = twister.toJson();
```

**Properties:**
- `id` - Twister identifier
- `text` - The tongue twister text
- `difficulty` - Difficulty: 'easy', 'medium', 'hard'
- `keywords` - Related keywords
- `audioUrl` - Audio reference URL (optional)

---

### 5. **TranscriptionResultModel** (`transcription_result_model.dart`)
Represents the result of a transcription/ASR operation.

```dart
import 'package:mobile/models/transcription_result_model.dart';

// Create from API JSON
TranscriptionResultModel result = TranscriptionResultModel.fromJson(apiResponse);

// Convert to JSON
Map<String, dynamic> json = result.toJson();
```

**Properties:**
- `id` - Result identifier
- `sentence` - Original sentence
- `transcribedText` - User's transcribed text
- `accuracy` - Accuracy percentage (0.0 - 1.0)
- `errors` - List of errors found
- `pointsEarned` - Points awarded
- `timestamp` - When transcription occurred

---

### 6. **ApiResponseModel** (`api_response_model.dart`)
Generic wrapper for API responses. Can be used with any data type.

```dart
import 'package:mobile/models/api_response_model.dart';

// Generic usage
ApiResponseModel<String> response = ApiResponseModel<String>.success(
  data: 'Some data',
  message: 'Operation successful',
);

// Check result
if (response.success) {
  print(response.data);
} else {
  print(response.error);
}

// With custom type
ApiResponseModel<UserModel> userResponse = ApiResponseModel.success(
  data: user,
);
```

**Properties:**
- `success` - Whether operation succeeded
- `data` - Response data (generic type)
- `message` - Success message
- `error` - Error message
- `statusCode` - HTTP status code

**Helper Methods:**
- `success()` - Create successful response
- `error()` - Create error response
- `hasData` - Check if has data
- `hasError` - Check if has error

---

### 7. **Exception Models** (`exception_model.dart`)
Custom exception classes for error handling.

```dart
import 'package:mobile/models/exception_model.dart';

try {
  // Some operation
} on AuthException catch (e) {
  print(e.message);
} on NetworkException catch (e) {
  print('Status: ${e.statusCode}');
} on AppException catch (e) {
  print(e);
}
```

**Available Exceptions:**
- `AuthException` - Authentication/login errors
- `NetworkException` - Network/API errors
- `NotFoundException` - Data not found
- `DataException` - Data parsing/validation errors
- `AudioException` - Recording/audio errors
- `UnknownException` - Unknown errors

---

## Importing Models

### Import All Models
```dart
import 'package:mobile/models/models.dart';
```

### Import Specific Model
```dart
import 'package:mobile/models/user_model.dart';
import 'package:mobile/models/api_response_model.dart';
```

---

## Usage Examples

### Example 1: Working with User Data
```dart
// Create new user
UserModel newUser = UserModel(
  uid: 'user123',
  email: 'user@example.com',
  fullName: 'John Doe',
  createdAt: DateTime.now(),
);

// Save to Firestore
await FirebaseFirestore.instance
    .collection('users')
    .doc(newUser.uid)
    .set(newUser.toFirestore());

// Load from Firestore
final doc = await FirebaseFirestore.instance
    .collection('users')
    .doc('user123')
    .get();
final user = UserModel.fromFirestore(doc.id, doc.data()!);
```

### Example 2: Handling API Responses
```dart
try {
  final response = await http.get(uri);
  
  if (response.statusCode == 200) {
    final topicData = json.decode(response.body);
    final topic = TopicModel.fromJson(topicData);
    
    return ApiResponseModel<TopicModel>.success(data: topic);
  } else {
    return ApiResponseModel<TopicModel>.error(
      error: 'Failed to load topic',
      statusCode: response.statusCode,
    );
  }
} catch (e) {
  throw NetworkException(
    message: 'Network error: $e',
    originalException: e,
  );
}
```

### Example 3: Storing Practice Results
```dart
final result = PracticeModel(
  id: 'practice_123',
  userId: currentUser.uid,
  topicId: 'topic_456',
  practiceType: 'transcribe',
  sentence: 'Hello, how are you?',
  transcribedText: 'Hello, how are you?',
  accuracy: 0.95,
  pointsEarned: 100,
  createdAt: DateTime.now(),
  isCompleted: true,
  completedAt: DateTime.now(),
);

// Save to Firestore
await FirebaseFirestore.instance
    .collection('practices')
    .doc(result.id)
    .set(result.toFirestore());
```

---

## Best Practices

1. **Always use models** - Don't use raw Maps, use typed models
2. **Use copyWith()** - For immutable updates instead of modifying objects
3. **Handle exceptions** - Use custom exception classes
4. **Validate data** - Check nullability before accessing properties
5. **Use factories** - Use `fromJson()` and `fromFirestore()` factories
6. **Export from models.dart** - Use barrel export for cleaner imports

---

## Future Improvements

- [ ] Add JSON serialization using `json_serializable` package
- [ ] Add Freezed immutability
- [ ] Add validation in models
- [ ] Add model testing
