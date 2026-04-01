# Chatter API 🚀
**CodeIgniter 4 · MySQL · JWT Auth**

---

## Quick Start

### 1. Install CodeIgniter 4
```bash
composer create-project codeigniter4/appstarter chatter_api
cd chatter_api
```

### 2. Copy these project files
Replace/merge the files from this zip into the CI4 project:
```
app/Config/Routes.php
app/Config/Filters.php
app/Controllers/*
app/Models/*
app/Filters/JwtFilter.php
app/Services/JwtService.php
```

### 3. Set up environment
```bash
cp env.example .env
# Edit .env with your DB credentials and JWT secret
```

### 4. Create the database
```bash
mysql -u root -p < database.sql
```

### 5. Run the server
```bash
php spark serve
# API is live at http://localhost:8080/api/v1
```

---

## Authentication

All protected routes require a JWT Bearer token in the header:
```
Authorization: Bearer <access_token>
```

Access tokens expire in 1 hour. Use the refresh endpoint to get a new one.

---

## API Endpoints

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/login` | Login |
| POST | `/api/v1/auth/refresh` | Refresh access token |
| POST | `/api/v1/auth/logout` | Logout (invalidate refresh token) |

**Register / Login request body:**
```json
{
  "name": "Alex Johnson",
  "username": "alexj",
  "email": "alex@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "user": { "id": 1, "name": "Alex Johnson", ... },
    "access_token": "eyJ...",
    "refresh_token": "abc123...",
    "expires_in": 3600
  }
}
```

---

### Users
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/users/me` | Get my profile |
| PUT | `/api/v1/users/me` | Update profile |
| PUT | `/api/v1/users/me/status` | Update online status |
| GET | `/api/v1/users/search?q=name` | Search users |
| GET | `/api/v1/users/:id` | Get user by ID |

---

### Contacts
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/contacts` | List accepted contacts |
| POST | `/api/v1/contacts` | Send contact request |
| PUT | `/api/v1/contacts/:id/accept` | Accept request |
| DELETE | `/api/v1/contacts/:id` | Remove contact |
| PUT | `/api/v1/contacts/:id/block` | Block user |

---

### Conversations
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/conversations` | List my conversations |
| POST | `/api/v1/conversations` | Create group chat |
| POST | `/api/v1/conversations/direct` | Get or create DM |
| GET | `/api/v1/conversations/:id` | Get conversation detail |
| PUT | `/api/v1/conversations/:id` | Update group info |
| DELETE | `/api/v1/conversations/:id` | Leave conversation |

**Create DM:**
```json
{ "user_id": 2 }
```

**Create Group:**
```json
{
  "name": "Work Team",
  "participant_ids": [2, 3, 4]
}
```

---

### Messages
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/conversations/:id/messages` | Get messages (paginated) |
| POST | `/api/v1/conversations/:id/messages` | Send message |
| PUT | `/api/v1/messages/:id` | Edit message |
| DELETE | `/api/v1/messages/:id` | Delete message (soft) |
| POST | `/api/v1/messages/:id/read` | Mark message read |
| POST | `/api/v1/conversations/:id/read-all` | Mark all read |

**Send message:**
```json
{
  "content": "Hello!",
  "type": "text",
  "reply_to_id": null
}
```

**Get messages query params:**
- `page` (default: 1)
- `limit` (default: 50, max: 100)

---

### Stories
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/stories` | Get active stories |
| POST | `/api/v1/stories` | Post a story |
| DELETE | `/api/v1/stories/:id` | Delete my story |
| POST | `/api/v1/stories/:id/view` | Mark story viewed |

---

## Flutter Integration

In your Flutter app, create an `ApiService`:

```dart
class ApiService {
  static const baseUrl = 'http://YOUR_SERVER_IP:8080/api/v1';
  static String? _token;

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<Map> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      _token = data['data']['access_token'];
    }
    return data;
  }

  static Future<List> getConversations() async {
    final res = await http.get(
      Uri.parse('$baseUrl/conversations'),
      headers: headers,
    );
    return jsonDecode(res.body)['data'];
  }

  static Future<Map> sendMessage(int convoId, String content) async {
    final res = await http.post(
      Uri.parse('$baseUrl/conversations/$convoId/messages'),
      headers: headers,
      body: jsonEncode({'content': content, 'type': 'text'}),
    );
    return jsonDecode(res.body);
  }
}
```

Add `http` to your Flutter `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.2.0
```

---

## Database Schema Overview

```
users
  └── auth_tokens          (JWT refresh tokens)
  └── contacts             (friend relationships)
  └── stories              └── story_views

conversations (direct or group)
  └── conversation_participants
  └── messages             └── message_reads
```

---

## Error Responses

All errors follow this format:
```json
{
  "status": "error",
  "message": "Description of error",
  "errors": { "field": "validation message" }
}
```

| Code | Meaning |
|------|---------|
| 400 | Bad Request / Validation failed |
| 401 | Unauthorized / Invalid token |
| 403 | Forbidden |
| 404 | Not Found |
| 500 | Server Error |
