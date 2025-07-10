# JumpingFox API - Postman Testing Guide

This guide walks you through testing the JumpingFox API using Postman, including both direct backend testing and APIM-protected endpoints.

## 🚀 Quick Start

### Step 1: Install Postman
1. Download and install [Postman](https://www.postman.com/downloads/)
2. Create a free account or sign in

### Step 2: API Configuration
From your `config.json` file, you'll need:
- **APIM Gateway URL**: `https://jumpingfox-apim-20250709.azure-api.net`
- **Subscription Key**: `9612af95b175494a90156d864d8c6b65`
- **Backend URL**: `http://134.33.206.69` (direct access)

## 📋 API Endpoints Available

### Health Check Endpoint
- **URL**: `/api/health`
- **Method**: `GET`
- **APIM URL**: `https://jumpingfox-apim-20250709.azure-api.net/api/health`
- **Description**: Simple health check (rate limited to 3 requests/minute via APIM)

### Fox Controller Endpoints
- **GET** `/api/api/Fox` - Get all foxes
- **GET** `/api/api/Fox/{id}` - Get specific fox by ID
- **POST** `/api/api/Fox` - Create a new fox
- **PUT** `/api/api/Fox/{id}` - Update existing fox
- **DELETE** `/api/api/Fox/{id}` - Delete fox

### Jump Controller Endpoints
- **GET** `/api/api/Jump` - Get all jump records
- **GET** `/api/api/Jump/fox/{foxId}` - Get jumps for specific fox
- **POST** `/api/api/Jump` - Create new jump record
- **GET** `/api/api/Jump/stats` - Get jump statistics

### Test Controller Endpoints
- **GET** `/api/api/Test/fast` - Fast response endpoint
- **GET** `/api/api/Test/slow` - Slow response endpoint (includes delay)
- **GET** `/api/api/Test/error/{errorType}` - Error testing endpoint
- **GET** `/api/api/Test/load` - Load testing endpoint

## 🔍 IMPORTANT: URL Structure
**APIM uses a double `/api/` prefix for most endpoints!**
- Health: `/api/health` (exception)
- All others: `/api/api/ControllerName` (note the double /api/)
- Controllers are capitalized: `Fox`, `Jump`, `Test`

## 🔧 Setting Up Postman

### Method 1: Testing via APIM (Recommended)
This tests the production-like setup with rate limiting.

1. **Create New Request**
   - Click `New` → `HTTP Request`
   - Name it: `JumpingFox Health Check (APIM)`

2. **Configure Request**
   - **Method**: `GET`
   - **URL**: `https://jumpingfox-apim-20250709.azure-api.net/api/health`

3. **Add Headers**
   - Click `Headers` tab
   - Add header:
     - **Key**: `Ocp-Apim-Subscription-Key`
     - **Value**: `9612af95b175494a90156d864d8c6b65`

4. **Send Request**
   - Click `Send`
   - You should see a `200 OK` response

### Method 2: Testing Backend Directly
This bypasses APIM and tests the backend directly.

1. **Create New Request**
   - Click `New` → `HTTP Request`
   - Name it: `JumpingFox Health Check (Direct)`

2. **Configure Request**
   - **Method**: `GET`
   - **URL**: `http://134.33.206.69/api/health`

3. **Send Request**
   - Click `Send`
   - You should see a `200 OK` response

## 📊 Testing Different Endpoints

### 1. Health Check (Rate Limited)
```
GET https://jumpingfox-apim-20250709.azure-api.net/api/health
Headers: Ocp-Apim-Subscription-Key: 9612af95b175494a90156d864d8c6b65
```
**Expected**: 200 OK for first 3 requests, then 429 (rate limited)

### 2. Get All Foxes ✅ FIXED!
```
GET https://jumpingfox-apim-20250709.azure-api.net/api/api/Fox
Headers: Ocp-Apim-Subscription-Key: 9612af95b175494a90156d864d8c6b65
```
**Expected**: 200 OK with JSON array of foxes

### 3. Get Specific Fox
```
GET https://jumpingfox-apim-20250709.azure-api.net/api/api/Fox/1
Headers: Ocp-Apim-Subscription-Key: 9612af95b175494a90156d864d8c6b65
```
**Expected**: 200 OK with fox details or 404 if not found

### 4. Create New Fox (POST)
```
POST https://jumpingfox-apim-20250709.azure-api.net/api/api/Fox
Headers: 
  - Ocp-Apim-Subscription-Key: 9612af95b175494a90156d864d8c6b65
  - Content-Type: application/json

Body (JSON):
{
  "name": "Rusty",
  "age": 3,
  "color": "Red",
  "jumpHeight": 1.5
}
```
**Expected**: 201 Created with the new fox details

### 5. Fast Test Endpoint ✅ FIXED!
```
GET https://jumpingfox-apim-20250709.azure-api.net/api/api/Test/fast
Headers: Ocp-Apim-Subscription-Key: 9612af95b175494a90156d864d8c6b65
```
**Expected**: 200 OK with fast response

### 6. Slow Test Endpoint ✅ FIXED!
```
GET https://jumpingfox-apim-20250709.azure-api.net/api/api/Test/slow
Headers: Ocp-Apim-Subscription-Key: 9612af95b175494a90156d864d8c6b65
```
**Expected**: 200 OK with delayed response (includes processing time)

## 🧪 Testing Rate Limiting

### Test Rate Limit Behavior
1. **Setup Collection Runner**
   - Create a collection named "Rate Limit Test"
   - Add the health check request to the collection
   - Go to `Collections` → `Rate Limit Test` → `Run`

2. **Configure Runner**
   - **Iterations**: 10
   - **Delay**: 100ms
   - Click `Run Rate Limit Test`

3. **Expected Results**
   - First 3 requests: `200 OK`
   - Remaining requests: `429 Too Many Requests`
   - Rate limit resets after 1 minute

## 🔍 Response Examples

### Successful Health Check
```json
{
  "success": true,
  "data": {
    "status": "Healthy",
    "timestamp": "2025-07-10T10:30:00Z",
    "version": "1.0.0",
    "environment": "Production"
  },
  "message": "Service is healthy"
}
```

### Rate Limited Response
```json
{
  "statusCode": 429,
  "message": "Rate limit exceeded"
}
```

### Fox Data Example
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Rusty",
      "age": 3,
      "color": "Red",
      "jumpHeight": 1.5,
      "createdAt": "2025-07-10T10:00:00Z"
    }
  ],
  "message": "Retrieved 1 foxes"
}
```

## 🚨 Troubleshooting

### Common Issues

1. **404 Not Found**
   - Check if the endpoint is correctly mapped in APIM
   - Try testing the backend directly: `http://134.33.206.69/api/endpoint`

2. **401 Unauthorized**
   - Verify the subscription key is correct
   - Check the header name: `Ocp-Apim-Subscription-Key`

3. **429 Rate Limited**
   - Wait 1 minute for rate limit to reset
   - This is expected behavior for the health endpoint

4. **500 Internal Server Error**
   - Check backend service status
   - Review application logs

### Testing Backend Directly
If APIM endpoints aren't working, test the backend directly:
- Replace `https://jumpingfox-apim-20250709.azure-api.net` with `http://134.33.206.69`
- Remove the `Ocp-Apim-Subscription-Key` header
- This bypasses APIM and rate limiting

## 📈 Advanced Testing

### Environment Variables
Create Postman environment variables:
- `apim_base_url`: `https://jumpingfox-apim-20250709.azure-api.net`
- `backend_base_url`: `http://134.33.206.69`
- `subscription_key`: `9612af95b175494a90156d864d8c6b65`

Use them in requests: `{{apim_base_url}}/api/health`

### Collection Tests
Add tests to your requests:
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has success field", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.success).to.be.true;
});
```

## 🎯 Next Steps

1. **Test all endpoints** listed above
2. **Verify rate limiting** works as expected
3. **Test error scenarios** (invalid IDs, malformed JSON)
4. **Monitor APIM analytics** in Azure Portal
5. **Test with different subscription keys** if available

## 📞 Support

If you encounter issues:
1. Check the backend service is running
2. Verify APIM configuration in Azure Portal
3. Review application logs
4. Test endpoints directly against the backend

Happy testing! 🦊
