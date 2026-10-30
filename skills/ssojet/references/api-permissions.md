# SSOJet Permissions API

> **Load for:** intent api:permissions

## Step 1: Fetch Documentation
**STOP. WebFetch the relevant docs for latest implementation details before proceeding.**

- [Retrieve All Permissions](https://api.ssojet.com/api/v1/permissions)
- [Create a New Permission](https://api.ssojet.com/api/v1/permissions)
- [Retrieve Permission by ID](https://api.ssojet.com/api/v1/permissions/{permissionId})
- [Update Permission](https://api.ssojet.com/api/v1/permissions/{permissionId})

## Operation Decision Tree
```
Need to work with permissions?
├─ Creating a new permission → POST /permissions
├─ Fetching a single permission → GET /permissions/{permissionId}
├─ Listing multiple permissions → GET /permissions (with pagination)
└─ Updating permission details → PUT /permissions/{permissionId}
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
| Method | Endpoint                     | Purpose                                      |
| ------ | ---------------------------- | -------------------------------------------- |
| GET    | `/permissions`               | List all permissions (paginated)             |
| POST   | `/permissions`               | Create a new permission                      |
| GET    | `/permissions/{permissionId}`| Retrieve permission details by ID            |
| PUT    | `/permissions/{permissionId}`| Update permission attributes                 |

## Request/Response Patterns

### Create Permission
**Request:**

```bash
curl -X POST "https://api.ssojet.com/api/v1/permissions?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "read:reports",
    "description": "Allows reading reports",
    "is_active": true,
    "is_default": false
  }'
```

**Response (201 Created):**

```json
{
  "id": "perm_5f8d0d55b54764421b7156de",
  "name": "read:reports",
  "description": "Allows reading reports",
  "is_active": true,
  "created_at": "2024-09-26T14:23:52Z",
  "modified_at": "2024-09-26T14:23:52Z"
}
```

### List Permissions (Paginated)
**Request:**

```bash
curl "https://api.ssojet.com/api/v1/permissions?client_id=${CLIENT_ID}&limit=10" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
  "limit": 10,
  "next_cursor": "eyJjIjogMTIzLCJpZCI6IDQ1Nn0=",
  "permissions": [
    {
      "id": "perm_5f8d0d55b54764421b7156de",
      "name": "read:reports",
      "description": "Allows reading reports",
      "is_active": true,
      "created_at": "2024-09-26T14:23:52Z",
      "modified_at": "2024-09-26T14:23:52Z"
    },
    {
      "id": "perm_5f8d0d55b54764421b7156df",
      "name": "write:reports",
      "description": "Allows writing reports",
      "is_active": true,
      "created_at": "2024-09-25T10:00:00Z",
      "modified_at": "2024-09-25T10:00:00Z"
    }
  ]
}
```

### Get Permission by ID
**Request:**

```bash
curl "https://api.ssojet.com/api/v1/permissions/perm_5f8d0d55b54764421b7156de?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
  "id": "perm_5f8d0d55b54764421b7156de",
  "name": "read:reports",
  "description": "Allows reading reports",
  "is_active": true,
  "created_at": "2024-09-26T14:23:52Z",
  "modified_at": "2024-09-26T14:23:52Z"
}
```

### Update Permission
**Request:**

```bash
curl -X PUT "https://api.ssojet.com/api/v1/permissions/perm_5f8d0d55b54764421b7156de?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "perm_5f8d0d55b54764421b7156de",
    "name": "read:all-reports",
    "description": "Allows reading all reports",
    "is_active": true
  }'
```

**Response (200 OK):**

```json
{
  "id": "perm_5f8d0d55b54764421b7156de",
  "name": "read:all-reports",
  "description": "Allows reading all reports",
  "is_active": true,
  "created_at": "2024-09-26T14:23:52Z",
  "modified_at": "2024-09-27T09:15:00Z"
}
```

## Pagination Handling
The List Permissions endpoint uses cursor-based pagination:

- **Initial request:** `GET /permissions?limit=10`
- **Response** includes `next_cursor`
- **Next page:** `GET /permissions?limit=10&cursor=eyJjIjogMTIz...`
- **Repeat** until `next_cursor` is null or empty.

## Error Code Mapping

| Status Code | Cause | Fix |
| :--- | :--- | :--- |
| **400 Bad Request** | Invalid request body or parameters | Validate request payload against API schema. |
| **401 Unauthorized** | Missing or invalid Bearer token or Client ID | Verify `Authorization` header and `client_id`. |
| **403 Forbidden** | Insufficient permissions | Ensure user has administrative privileges. |
| **404 Not Found** | Permission ID does not exist | Confirm `permissionId` is correct. |
| **500 Internal Server Error** | SSOJet service issue | Retry with exponential backoff. |

## Runnable Verification

### Verify Creating and Listing Permissions

```bash
## Create Permission
PERM_RESPONSE=$(curl -s -X POST "https://api.ssojet.com/api/v1/permissions?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "test:permission",
    "description": "Verification permission",
    "is_active": true,
    "is_default": false
  }')

echo "Created Permission: $PERM_RESPONSE"
PERM_ID=$(echo $PERM_RESPONSE | jq -r '.id')

## Retrieve by ID
if [ "$PERM_ID" != "null" ]; then
  curl "https://api.ssojet.com/api/v1/permissions/${PERM_ID}?client_id=${CLIENT_ID}" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}"
fi
```
