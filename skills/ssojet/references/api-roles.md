# SSOJet Roles API

> **Load for:** intent api:roles, or team-management when assigning roles

## Step 1: Fetch Documentation
**STOP. WebFetch the relevant docs for latest implementation details before proceeding.**

- [Retrieve All Roles](https://api.ssojet.com/api/v1/roles)
- [Create a New Role](https://api.ssojet.com/api/v1/roles)
- [Retrieve Role by ID](https://api.ssojet.com/api/v1/roles/{roleId})
- [Update Role](https://api.ssojet.com/api/v1/roles/{roleId})
- [Delete Role](https://api.ssojet.com/api/v1/roles/{roleId})
- [Assign Permission](https://api.ssojet.com/api/v1/roles/assignpermission)

## Operation Decision Tree
```
Need to work with roles?
├─ Creating a new role → POST /roles
├─ Fetching a single role → GET /roles/{roleId}
├─ Listing multiple roles → GET /roles (with pagination)
├─ Updating role details → PUT /roles/{roleId}
├─ Assigning/Updating permissions → PUT /roles/assignpermission
└─ Removing a role → DELETE /roles/{roleId}
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
| Method | Endpoint                  | Purpose                                      |
| ------ | ------------------------- | -------------------------------------------- |
| GET    | `/roles`                  | List all roles (paginated)                   |
| POST   | `/roles`                  | Create a new role                            |
| GET    | `/roles/{roleId}`         | Retrieve role details by ID                  |
| PUT    | `/roles/{roleId}`         | Update role attributes                       |
| DELETE | `/roles/{roleId}`         | Delete a role                                |
| PUT    | `/roles/assignpermission` | Assign specific permissions to a role        |

## Request/Response Patterns

### Create Role
**Request:**

```bash
curl -X POST "https://api.ssojet.com/api/v1/roles?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Editor",
    "description": "Can edit content but not publish",
    "is_active": true,
    "permission_ids": ["perm_12345", "perm_67890"]
  }'
```

**Response (201 Created):**

```json
{
  "id": "role_5f8d0d55b54764421b7156dd",
  "name": "Editor",
  "description": "Can edit content but not publish",
  "is_active": true,
  "permission_ids": ["perm_12345", "perm_67890"],
  "created_at": "2024-09-26T14:23:52Z",
  "modified_at": "2024-09-26T14:23:52Z"
}
```

### List Roles (Paginated)
**Request:**

```bash
curl "https://api.ssojet.com/api/v1/roles?client_id=${CLIENT_ID}&limit=10" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
  "limit": 10,
  "next_cursor": "eyJjIjogMTIzLCJpZCI6IDQ1Nn0=",
  "roles": [
    {
      "id": "role_5f8d0d55b54764421b7156dd",
      "name": "Editor",
      "description": "Can edit content but not publish",
      "is_active": true,
      "permission_ids": ["perm_12345"],
      "created_at": "2024-09-26T14:23:52Z",
      "modified_at": "2024-09-26T14:23:52Z"
    },
    {
      "id": "role_5f8d0d55b54764421b7156de",
      "name": "Viewer",
      "description": "Read-only access",
      "is_active": true,
      "permission_ids": [],
      "created_at": "2024-09-25T10:00:00Z",
      "modified_at": "2024-09-25T10:00:00Z"
    }
  ]
}
```

### Get Role by ID
**Request:**

```bash
curl "https://api.ssojet.com/api/v1/roles/role_5f8d0d55b54764421b7156dd?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
  "id": "role_5f8d0d55b54764421b7156dd",
  "name": "Editor",
  "description": "Can edit content but not publish",
  "is_active": true,
  "permission_ids": ["perm_12345"],
  "created_at": "2024-09-26T14:23:52Z",
  "modified_at": "2024-09-26T14:23:52Z"
}
```

### Update Role
**Request:**

```bash
curl -X PUT "https://api.ssojet.com/api/v1/roles/role_5f8d0d55b54764421b7156dd?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "role_5f8d0d55b54764421b7156dd",
    "name": "Senior Editor",
    "description": "Can edit and archive content",
    "is_active": true,
    "permission_ids": ["perm_12345", "perm_67890", "perm_11223"]
  }'
```

**Response (200 OK):**

```json
{
  "id": "role_5f8d0d55b54764421b7156dd",
  "name": "Senior Editor",
  "description": "Can edit and archive content",
  "is_active": true,
  "permission_ids": ["perm_12345", "perm_67890", "perm_11223"],
  "created_at": "2024-09-26T14:23:52Z",
  "modified_at": "2024-09-27T09:15:00Z"
}
```

### Assign Permission to Role
**Request:**

```bash
curl -X PUT "https://api.ssojet.com/api/v1/roles/assignpermission?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "role_5f8d0d55b54764421b7156dd",
    "permission_ids": ["perm_new_99999"]
  }'
```

**Response (200 OK):**

```json
{
  "id": "role_5f8d0d55b54764421b7156dd",
  "name": "Senior Editor",
  "permission_ids": ["perm_12345", "perm_67890", "perm_11223", "perm_new_99999"],
  "modified_at": "2024-09-27T10:00:00Z"
  // ... other fields
}
```

### Delete Role
**Request:**

```bash
curl -X DELETE "https://api.ssojet.com/api/v1/roles/role_5f8d0d55b54764421b7156dd?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
  "success": true
}
```

## Pagination Handling
The List Roles endpoint uses cursor-based pagination:

- **Initial request:** `GET /roles?limit=10`
- **Response** includes `next_cursor`
- **Next page:** `GET /roles?limit=10&cursor=eyJjIjogMTIz...`
- **Repeat** until `next_cursor` is null or empty.

**Example pagination loop:**

```bash
## First page
curl "https://api.ssojet.com/api/v1/roles?client_id=${CLIENT_ID}&limit=10" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"

## Next page (use 'next_cursor' value from previous response)
curl "https://api.ssojet.com/api/v1/roles?client_id=${CLIENT_ID}&limit=10&cursor=eyJjIjogMTIz..." \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

## Error Code Mapping

| Status Code | Cause | Fix |
| :--- | :--- | :--- |
| **400 Bad Request** | Invalid request body or parameters (e.g., missing name, invalid JSON) | Validate request payload against API schema. Ensure all required fields are present. |
| **401 Unauthorized** | Missing or invalid Bearer token or Client ID | Verify `Authorization` header and `client_id` query parameter. Check if token is expired. |
| **403 Forbidden** | Insufficient permissions | Ensure the authenticated user has the necessary administrative privileges to perform the action. |
| **404 Not Found** | Role ID does not exist | Confirm the `roleId` is correct and exists in the current environment. |
| **429 Too Many Requests** | Rate limit exceeded | Implement exponential backoff. Wait before retrying. |
| **500 Internal Server Error** | SSOJet service issue | Retry with exponential backoff. Contact SSOJet support if persistent. |

## Rate Limiting
SSOJet APIs are rate-limited. If you receive a **429** status:

1. Check the `Retry-After` header (if present).
2. Implement exponential backoff starting at 1 second.
3. Log the rate limit event for monitoring.

## Runnable Verification

### Verify API Access
Test that you can authenticate and list roles.

```bash
curl "https://api.ssojet.com/api/v1/roles?client_id=${CLIENT_ID}&limit=1" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```
*Expected: 200 OK with `roles` list (may be empty).*

### Create and Retrieve Test Role
Create a temporary role to verify write access and retrieval.

```bash
## Create Role
ROLE_RESPONSE=$(curl -s -X POST "https://api.ssojet.com/api/v1/roles?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Role",
    "description": "Verification role",
    "is_active": true,
    "permission_ids": []
  }')

echo "Created Role: $ROLE_RESPONSE"
ROLE_ID=$(echo $ROLE_RESPONSE | jq -r '.id')

## Retrieve by ID
if [ "$ROLE_ID" != "null" ]; then
  curl "https://api.ssojet.com/api/v1/roles/${ROLE_ID}?client_id=${CLIENT_ID}" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}"
  
  # Cleanup (Delete)
  curl -X DELETE "https://api.ssojet.com/api/v1/roles/${ROLE_ID}?client_id=${CLIENT_ID}" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}"
fi
```
