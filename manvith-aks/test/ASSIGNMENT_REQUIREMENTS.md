# Assignment: Kubernetes Multi-Backend Microservices Deployment

## Project Overview

You are tasked with deploying a multi-backend microservices application to a Kubernetes cluster. The application consists of:

- **React Frontend**: A single-page application that allows users to upload images
- **Two Node.js Backends**: Backend-A and Backend-B that handle image uploads
- **PostgreSQL Database**: A shared database that stores all uploads from both backends

## Application Architecture

The application follows a microservices architecture where:

1. Users interact with the React frontend
2. The frontend routes upload requests to either Backend-A or Backend-B
3. Both backends write to the same PostgreSQL database
4. Each database entry is tagged with the backend name that processed it

## Codebase Structure

### Frontend (`frontend/`)

A React single-page application with:
- Modern UI for image upload
- Two upload sections: one for Backend-A, one for Backend-B
- Displays responses from backends including:
  - Which backend processed the request
  - Recent database entries
  - Uploaded image data

**Key Files:**
- `src/App.js` - Main React component
- `src/App.css` - Styling
- `Dockerfile` - Multi-stage build (React → Nginx)
- `nginx.conf` - Nginx configuration with API proxying

**API Endpoints Used:**
- `POST /api/a` - Upload to Backend-A
- `POST /api/b` - Upload to Backend-B

### Backend-A (`backend-a/`)

Node.js/Express microservice that:
- Receives image uploads via POST `/api/a`
- Stores images and metadata in PostgreSQL
- Returns recent database entries
- Tags all entries with `backend_name: "backend-a"`

**Key Files:**
- `index.js` - Express server with Multer for file uploads
- `package.json` - Dependencies (express, multer, pg)
- `Dockerfile` - Container image definition

**Environment Variables Required:**
- `DB_HOST` - PostgreSQL hostname
- `DB_PORT` - PostgreSQL port (default: 5432)
- `DB_USER` - Database username
- `DB_PASSWORD` - Database password
- `DB_NAME` - Database name
- `PORT` - Server port (default: 8080)

**Endpoints:**
- `POST /api/a` - Upload image
- `GET /health` - Health check endpoint

### Backend-B (`backend-b/`)

Identical to Backend-A but:
- Uses endpoint `POST /api/b`
- Tags entries with `backend_name: "backend-b"`

**Key Files:**
- Same structure as Backend-A
- `index.js` - Express server
- `package.json` - Dependencies
- `Dockerfile` - Container image definition

### Database (`db/`)

PostgreSQL database initialization script:

**Schema:**
```sql
CREATE TABLE IF NOT EXISTS requests (
  id SERIAL PRIMARY KEY,
  backend_name TEXT NOT NULL,
  ts TIMESTAMP DEFAULT NOW(),
  meta JSONB,
  image BYTEA
);
```

**Table Structure:**
- `id` - Auto-incrementing primary key
- `backend_name` - Either "backend-a" or "backend-b"
- `ts` - Timestamp of upload
- `meta` - JSON metadata (contains `uploaded: true/false`)
- `image` - Binary image data (BYTEA)

## Application Functionality

### Expected Behavior

1. **Frontend**:
   - Displays upload interface with two sections
   - Allows file selection for each backend
   - Shows response data after upload
   - Displays recent database entries

2. **Backends**:
   - Accept image uploads via multipart/form-data
   - Store image and metadata in database
   - Tag entries with backend name
   - Return JSON response with:
     - Backend identifier
     - Recent 5 database entries
     - Base64 encoded uploaded image

3. **Database**:
   - Stores all uploads from both backends
   - Maintains backend identification
   - Preserves timestamps
   - Stores binary image data

### Traffic Flow

```
Browser → Frontend → Backend-A/B → PostgreSQL Database
```

- Frontend proxies `/api/a` requests to Backend-A
- Frontend proxies `/api/b` requests to Backend-B
- Both backends connect to the same PostgreSQL instance
- Backends should NOT be directly accessible from outside the cluster

## Deliverables

You must submit the following:

### 1. Complete Source Code

The provided codebase is complete and functional. Ensure all files are present:
- `frontend/` - React application
- `backend-a/` - Backend-A microservice
- `backend-b/` - Backend-B microservice
- `db/init.sql` - Database schema



**Dockerfiles are provided:**
- `frontend/Dockerfile` - Multi-stage build
- `backend-a/Dockerfile` - Node.js Alpine
- `backend-b/Dockerfile` - Node.js Alpine

### 3. Kubernetes Manifests

Create Kubernetes manifests in a `k8s/` directory. You must include:

#### a) Namespace
- Create a dedicated namespace for the application
- Include appropriate labels

#### b) Secrets
- Store database credentials securely
- Store backend database connection credentials
- Use Kubernetes Secrets (not ConfigMaps for sensitive data)

#### c) ConfigMaps
- Store non-sensitive configuration
- Database connection settings (host, port)
- Database initialization script

#### d) PersistentVolumeClaim (PVC)
- For PostgreSQL database storage
- Minimum 10GB
- Appropriate access mode

#### e) StatefulSet
- For PostgreSQL database
- Use the PVC for persistent storage
- Include health checks (liveness and readiness probes)
- Mount database initialization script

#### f) Services
- **PostgreSQL Service**: ClusterIP (internal only)
- **Backend-A Service**: ClusterIP (internal only)
- **Backend-B Service**: ClusterIP (internal only)
- **Frontend Service**: LoadBalancer or NodePort (external access)

#### g) Deployments
- **Backend-A Deployment**: Minimum 2 replicas
- **Backend-B Deployment**: Minimum 2 replicas
- **Frontend Deployment**: Minimum 2 replicas
- Include:
  - Resource requests and limits
  - Health checks (liveness and readiness probes)
  - Environment variables from Secrets and ConfigMaps
  - Proper labels and selectors

#### h) NetworkPolicy
- Restrict pod-to-pod communication
- Only allow:
  - Frontend → Backend-A/B
  - Backend-A/B → PostgreSQL
  - External → Frontend
- Deny all other traffic

#### i) ResourceQuota
- Set namespace resource limits
- Prevent resource exhaustion

#### j) HorizontalPodAutoscaler (HPA)
- Auto-scale Backend-A based on CPU/memory
- Auto-scale Backend-B based on CPU/memory
- Auto-scale Frontend based on CPU/memory
- Minimum 2 replicas, maximum 5 replicas

### 4. Documentation

#### a) README.md
Include:
- Project description
- Architecture overview
- Prerequisites
- **How to build Docker images**
- **How to deploy to Kubernetes** (step-by-step)
- How to access the application
- How to verify deployment
- Troubleshooting guide

#### b) Verification Steps
Document how to:
- Verify all pods are running
- Verify services are accessible
- Test image upload functionality
- Verify database entries
- Check backend identification in database
- Verify NetworkPolicy is working
- Verify HPA is functioning

### 5. Testing Evidence

Provide evidence of:
- Successful image uploads through both backends
- Database entries showing correct backend names
- All pods running and healthy
- Services accessible
- NetworkPolicy restrictions working
- HPA scaling (if load testing performed)


## Requirements & Best Practices

### Security Requirements

1. **Secrets Management**
   - Use Kubernetes Secrets for passwords
   - Never hardcode credentials
   - Use ConfigMaps only for non-sensitive data

2. **Network Security**
   - Implement NetworkPolicy
   - Backends should NOT be accessible from outside cluster
   - Only frontend should be externally accessible

3. **Resource Security**
   - Set resource limits on all containers
   - Implement ResourceQuota
   - Prevent resource exhaustion

### Best Practices

1. **High Availability**
   - Multiple replicas for all services
   - Health checks for reliability
   - Proper startup ordering

2. **Scalability**
   - Implement HPA for auto-scaling
   - Resource requests for scheduling
   - Resource limits for protection

3. **Observability**
   - Health check endpoints
   - Proper logging
   - Resource monitoring

4. **Persistence**
   - Use StatefulSet for database
   - Persistent storage for data
   - Data survives pod restarts

5. **Configuration Management**
   - Use ConfigMaps for configuration
   - Use Secrets for sensitive data
   - Environment-specific settings

## Evaluation Criteria

Your submission will be evaluated on:

1. **Completeness** (25%)
   - All required Kubernetes resources present
   - All manifests properly configured
   - Documentation complete

2. **Correctness** (30%)
   - Application functions correctly
   - All services communicate properly
   - Database stores entries correctly
   - Backend identification works

3. **Best Practices** (25%)
   - Proper use of Secrets and ConfigMaps
   - Resource limits and requests
   - Health checks implemented
   - NetworkPolicy configured correctly
   - HPA configured

4. **Security** (10%)
   - Secrets used for sensitive data
   - NetworkPolicy restricts traffic
   - Backends not externally accessible
   - ResourceQuota implemented

5. **Documentation** (10%)
   - Clear deployment instructions
   - Verification steps documented
   - Troubleshooting guide
   - Code comments where appropriate

## Important Notes

1. **Do NOT modify the application code** - The provided code is complete and functional. Focus on Kubernetes deployment.


## Questions to Consider

While implementing, consider:

1. How do services discover each other in Kubernetes?
2. How do you ensure the database is ready before backends start?
3. How do you handle secrets securely?
4. How do you ensure high availability?
5. How do you scale the application?
6. How do you secure network traffic?
7. How do you persist database data?
8. How do you monitor application health?


1. Review the codebase structure
2. Understand the application flow
3. Build and test Docker images locally
4. Plan your Kubernetes architecture
5. Create Kubernetes manifests
6. Test deployment
7. Document everything
8. Verify all requirements

Good luck!

