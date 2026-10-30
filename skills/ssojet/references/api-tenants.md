# SSOJet Tenants API

> **Load for:** intent api:tenants, or team-management when creating or listing tenants

## Step 1: Fetch Documentation
**STOP. WebFetch the relevant docs for latest implementation details before proceeding.**

- [List All Tenants](https://api.ssojet.com/api/v1/tenants)
- [Create New Tenant](https://api.ssojet.com/api/v1/tenants)
- [Get Tenant Details](https://api.ssojet.com/api/v1/tenants/{tenantid})
- [Update Tenant Configuration](https://api.ssojet.com/api/v1/tenants/{tenantid})
- [Delete Tenant](https://api.ssojet.com/api/v1/tenants/{tenantid})
- [List Tenant Members](https://api.ssojet.com/api/v1/tenants/{tenantid}/users)
- [Add Users to Tenant](https://api.ssojet.com/api/v1/tenants/{tenantid}/users)
- [Remove Users from Tenant](https://api.ssojet.com/api/v1/tenants/{tenantid}/users)

## Operation Decision Tree
```
Need to work with tenants?
├─ Creating a new tenant → POST /tenants
├─ Fetching a single tenant → GET /tenants/{tenantid}
├─ Listing multiple tenants → GET /tenants (with pagination & search)
├─ Updating tenant details → PUT /tenants/{tenantid}
├─ Updating tenant details → PUT /tenants/{tenantid}
├─ Removing a tenant → DELETE /tenants/{tenantid}
├─ Listing tenant members → GET /tenants/{tenantid}/users
├─ Adding users to tenant → POST /tenants/{tenantid}/users
├─ Assigning roles to user → POST /tenants/{tenantid}/users/{userid}/roles
└─ Removing users from tenant → DELETE /tenants/{tenantid}/users
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
| Method | Endpoint                 | Purpose                                      |
| ------ | ------------------------ | -------------------------------------------- |
| GET    | `/tenants`               | List and search all tenants (paginated)      |
| POST   | `/tenants`               | Create a new tenant workspace                |
| GET    | `/tenants/{tenantid}`    | Retrieve detailed tenant information         |
| PUT    | `/tenants/{tenantid}`    | Update tenant configuration (name, domains)  |
| DELETE | `/tenants/{tenantid}`    | Permanently delete a tenant                  |
| GET    | `/tenants/{tenantid}/users` | List all users in a tenant                   |
| POST   | `/tenants/{tenantid}/users` | Add existing users to a tenant               |
| POST   | `/tenants/{tenantid}/users/{userid}/roles` | Assign roles to a user in a tenant |
| DELETE | `/tenants/{tenantid}/users` | Remove users from a tenant                   |

## Request/Response Patterns

### Create Tenant
**Request:**

```bash
curl -X POST "https://api.ssojet.com/api/v1/tenants?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "acme-corp",
    "display_name": "Acme Corporation",
    "domains": ["acme.com", "acme.org"]
  }'
```

**Response (201 Created):**

```json
{
  "id": "612e14a1e4b0b2a0871f514c",
  "name": "acme-corp",
  "display_name": "Acme Corporation",
  "domains": ["acme.com", "acme.org"],
  "external_id": "ext_12345",
  "metadata": {}
}
```

### List Tenants (Paginated)
**Request:**

```bash
curl "https://api.ssojet.com/api/v1/tenants?client_id=${CLIENT_ID}&limit=10&search=Acme&search_field=display_name" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
  "limit": 10,
  "next_cursor": "eyJjIjogMTIzLCJpZCI6IDQ1Nn0=",
  "tenants": [
    {
      "id": "612e14a1e4b0b2a0871f514c",
      "name": "acme-corp",
      "display_name": "Acme Corporation",
      "status": "active"
    }
  ]
}
```

### Get Tenant by ID
**Request:**

```bash
curl "https://api.ssojet.com/api/v1/tenants/612e14a1e4b0b2a0871f514c?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
  "id": "612e14a1e4b0b2a0871f514c",
  "name": "acme-corp",
  "display_name": "Acme Corporation",
  "domains": ["acme.com", "acme.org"],
  "external_id": "ext_12345"
}
```

### Update Tenant
**Request:**

```bash
curl -X PUT "https://api.ssojet.com/api/v1/tenants/612e14a1e4b0b2a0871f514c?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "Acme Global",
    "domains": ["acme.com", "acme.global"]
  }'
```

**Response (200 OK):**

```json
{
  "is_updated": true
}
```

### Delete Tenant
**Request:**

```bash
curl -X DELETE "https://api.ssojet.com/api/v1/tenants/612e14a1e4b0b2a0871f514c?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Response (200 OK):**

{
  "success": true
}
```

### List Tenant Members
**Request:**

```bash
curl "https://api.ssojet.com/api/v1/tenants/612e14a1e4b0b2a0871f514c/users?client_id=${CLIENT_ID}&limit=10" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Response (200 OK):**

```json
{
  "limit": 10,
  "next_cursor": "eyJ...",
  "users": [
    {
      "id": "user_123",
      "email": "user@acme.com",
      "first_name": "John",
      "last_name": "Doe"
    }
  ]
}
```

### Add Users to Tenant
**Request:**

```bash
curl -X POST "https://api.ssojet.com/api/v1/tenants/612e14a1e4b0b2a0871f514c/users?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "user_ids": ["user_123", "user_456"]
  }'
```

**Response (200 OK):**

```json
{
  "is_added": true
}
```

### Assign User Roles
**Request:**

```bash
curl -X POST "https://api.ssojet.com/api/v1/tenants/612e14a1e4b0b2a0871f514c/users/user_123/roles?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "role_ids": ["role_admin_id", "role_editor_id"]
  }'
```

**Response (200 OK):**

```json
{
  "is_updated": true
}
```

### Remove Users from Tenant
**Request:**

```bash
curl -X DELETE "https://api.ssojet.com/api/v1/tenants/612e14a1e4b0b2a0871f514c/users?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "users": ["user_123"]
  }'
```

**Response (200 OK):**

```json
{
  "success": true
}
```

## Pagination Handling
The List Tenants endpoint uses cursor-based pagination:

- **Initial request:** `GET /tenants?limit=10`
- **Response** includes `next_cursor`
- **Next page:** `GET /tenants?limit=10&cursor=eyJjIjogMTIz...`
- **Repeat** until `next_cursor` is null or empty.

## Error Code Mapping

| Status Code | Cause | Fix |
| :--- | :--- | :--- |
| **400 Bad Request** | Invalid request parameters (e.g., malformed limit) | Check `limit` is between 1-500. Ensure JSON payload is valid. |
| **401 Unauthorized** | Missing or invalid authentication token | Verify `Authorization` header and access token validity. |
| **404 Not Found** | Tenant ID does not exist | Confirm `tenantid` is a valid ObjectID and exists. |
| **409 Conflict** | Tenant name or domain already exists | Choose a unique `name` or `external_id`. Check domain ownership. |
| **500 Internal Server Error** | Server-side processing error | Retry with exponential backoff. Contact support. |

## Runnable Verification

### Create and Retrieve Test Tenant
```bash
## Create Tenant
TENANT_RESPONSE=$(curl -s -X POST "https://api.ssojet.com/api/v1/tenants?client_id=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "test-tenant-verify",
    "display_name": "Test Tenant Verification",
    "domains": ["test-verify.local"]
  }')

echo "Created Tenant: $TENANT_RESPONSE"
TENANT_ID=$(echo $TENANT_RESPONSE | jq -r '.id')

## Retrieve by ID
if [ "$TENANT_ID" != "null" ] && [ "$TENANT_ID" != "" ]; then
  curl "https://api.ssojet.com/api/v1/tenants/${TENANT_ID}?client_id=${CLIENT_ID}" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}"
  
  # Cleanup (Delete)
  curl -X DELETE "https://api.ssojet.com/api/v1/tenants/${TENANT_ID}?client_id=${CLIENT_ID}" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}"
fi
```
