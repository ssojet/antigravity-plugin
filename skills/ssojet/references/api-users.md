# SSOJet Users API

> **Load for:** intent api:users, or team-management when touching users

## Step 1: Fetch Documentation
**STOP. WebFetch the relevant docs for latest implementation details before proceeding.**

- [List All Users](https://api.ssojet.com/api/v1/users)
- [Create New User](https://api.ssojet.com/api/v1/users)
- [Get User Profile](https://api.ssojet.com/api/v1/users/{userid})
- [Update User Profile](https://api.ssojet.com/api/v1/users/{userid})
- [Delete User Account](https://api.ssojet.com/api/v1/users/{userid})
- [List User Tenants](https://api.ssojet.com/api/v1/users/{userid}/tenants)

## Operation Decision Tree
```
Need to work with users?
├─ Creating a new user → POST /users
├─ Fetching a single user → GET /users/{userid}
├─ Listing multiple users → GET /users (with pagination & search)
├─ Updating user details → PUT /users/{userid}
├─ Removing a user → DELETE /users/{userid}
└─ Listing user's tenants → GET /users/{userid}/tenants
```

## Authentication Setup
All API requests require a Bearer token and a Client ID.

**Headers:**
```bash
Authorization: Bearer <your_access_token>
```

**Query Parameters:**
```bash
client_id=<your_client_id>
```

## Endpoint Catalog
| Method | Endpoint             | Purpose                                      |
| ------ | -------------------- | -------------------------------------------- |
| GET    | `/users`             | List and search users (paginated)            |
| POST   | `/users`             | Create a new user account                    |
| GET    | `/users/{userid}`    | Retrieve detailed user profile               |
| PUT    | `/users/{userid}`    | Update user profile (name, metadata)         |
| DELETE | `/users/{userid}`    | Permanently delete a user account            |
| GET    | `/users/{userid}/tenants` | List all tenants a user belongs to       |

## Request/Response Patterns

### Create User
**Request:**

```bash
curl -X POST "https://api.ssojet.com/api/v1/users?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "jane.doe@example.com",
    "first_name": "Jane",
    "last_name": "Doe",
    "is_active": true,
    "user_metadata": {
      "department": "Engineering"
    }
  }'
```

**Response (201 Created):**

```json
{
  "id": "612e14a1e4b0b2a0871f514d",
  "email": "jane.doe@example.com",
  "first_name": "Jane",
  "last_name": "Doe",
  "is_active": true,
  "created_at": "2024-01-01T12:00:00Z"
}
```

### List Users (Paginated)
**Request:**

```bash
curl "https://api.ssojet.com/api/v1/users?client_id=${CLIENT_ID}&limit=10&email=jane.doe@example.com" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
  "limit": 10,
  "next_cursor": "eyJjIjogMTIzLCJpZCI6IDQ1Nn0=",
  "users": [
    {
      "id": "612e14a1e4b0b2a0871f514d",
      "email": "jane.doe@example.com",
      "first_name": "Jane",
      "last_name": "Doe",
      "is_active": true
    }
  ]
}
```

### Get User by ID
**Request:**

```bash
curl "https://api.ssojet.com/api/v1/users/612e14a1e4b0b2a0871f514d?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
  "id": "612e14a1e4b0b2a0871f514d",
  "email": "jane.doe@example.com",
  "first_name": "Jane",
  "last_name": "Doe",
  "is_active": true,
  "user_metadata": {
    "department": "Engineering"
  }
}
```

### Update User
**Request:**

```bash
curl -X PUT "https://api.ssojet.com/api/v1/users/612e14a1e4b0b2a0871f514d?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Janet",
    "user_metadata": {
      "department": "Product"
    }
  }'
```

**Response (200 OK):**

```json
{
  "id": "612e14a1e4b0b2a0871f514d",
  "first_name": "Janet",
  "modified_at": "2024-01-02T12:00:00Z"
}
```

### Delete User
**Request:**

```bash
curl -X DELETE "https://api.ssojet.com/api/v1/users/612e14a1e4b0b2a0871f514d?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
  "success": true
}
```

### List User Tenants
**Request:**

```bash
curl "https://api.ssojet.com/api/v1/users/612e14a1e4b0b2a0871f514d/tenants?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
  "tenants": [
    {
      "tenant_id": "tenant_123",
      "tenant_name": "Acme Corp",
      "status": "active",
      "roles": [
        { "id": "role_admin", "name": "Admin" }
      ]
    }
  ]
}
```

## Pagination Handling
The List Users endpoint uses cursor-based pagination:

- **Initial request:** `GET /users?limit=10`
- **Response** includes `next_cursor`
- **Next page:** `GET /users?limit=10&cursor=eyJjIjogMTIz...`
- **Repeat** until `next_cursor` is null or empty.

## Error Code Mapping

| Status Code | Cause | Fix |
| :--- | :--- | :--- |
| **400 Bad Request** | Invalid request parameters (e.g., invalid email) | Validate `email` format and check required fields. |
| **401 Unauthorized** | Missing or invalid authentication token | Verify `Authorization` header and access token validity. |
| **404 Not Found** | User ID does not exist | Confirm `userid` is a valid ObjectID and exists. |
| **403 Forbidden** | Insufficient permissions | Ensure client/user has "Users" management permissions. |
| **500 Internal Server Error** | Server-side processing error | Retry with exponential backoff. Contact support. |

## Runnable Verification

### Create and Retrieve Test User
```bash
## Create User
USER_RESPONSE=$(curl -s -X POST "https://api.ssojet.com/api/v1/users?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "verify.'$(date +%s)'@example.com",
    "first_name": "Verify",
    "last_name": "User",
    "is_active": true
  }')

echo "Created User: $USER_RESPONSE"
USER_ID=$(echo $USER_RESPONSE | jq -r '.id')

## Retrieve by ID
if [ "$USER_ID" != "null" ] && [ "$USER_ID" != "" ]; then
  curl "https://api.ssojet.com/api/v1/users/${USER_ID}?client_id=${CLIENT_ID}" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}"
  
  # Cleanup (Delete)
  curl -X DELETE "https://api.ssojet.com/api/v1/users/${USER_ID}?client_id=${CLIENT_ID}" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}"
fi
```
