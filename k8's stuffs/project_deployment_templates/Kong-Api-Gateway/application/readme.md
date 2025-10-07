## 🚀 Step 1: Configure Kong Data Plane Service

First, ensure your Kong Data Plane is properly exposed:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kong-dp-proxy
  namespace: kong
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  selector:
    app: kong-dp
  ports:
  - name: proxy-http
    port: 80
    targetPort: 8000
  - name: proxy-https
    port: 443
    targetPort: 8443
  type: LoadBalancer
```

## 📋 Step 2: Configure Services in Konnect

### 2.1 Backend Service Configuration

In Konnect, create a service for your backend:

1. Navigate to **Gateway Manager** → **Your Runtime Group** → **Services**
2. Click **+ New Service**
3. Configure the backend service:

```yaml
Service Configuration:
- Name: expense-tracker-backend
- URL: http://expense-tracker-be-service.expense-tracker.svc.cluster.local:7070
- Retries: 3
- Connect Timeout: 60000
- Write Timeout: 60000
- Read Timeout: 60000
```

### 2.2 Backend Route Configuration

Create a route for the backend API:

```yaml
Route Configuration:
- Name: expense-tracker-backend-route
- Service: expense-tracker-backend
- Paths: 
  - /api
  - /api/~
- Methods: [GET, POST, PUT, DELETE, OPTIONS]
- Strip Path: false
```

### Final Snippet
```yaml
_format_version: "3.0"
services:
  - name: expense-tracker-backend
    url: http://expense-tracker-be-service.expense-tracker.svc.cluster.local:7070
    routes:
      - name: expense-tracker-backend-route
        paths:
          - /api/~
        protocols:
          - http
          - https
        strip_path: true
```


### 2.3 Frontend Service Configuration

Create a service for your frontend:

```yaml
Service Configuration:
- Name: expense-tracker-frontend
- URL: http://expense-tracker-fe-service.expense-tracker.svc.cluster.local:80
- Retries: 3
- Connect Timeout: 60000
- Write Timeout: 60000
- Read Timeout: 60000
```

### 2.4 Frontend Route Configuration

Create a route for the frontend:

```yaml
Route Configuration:
- Name: expense-tracker-frontend-route
- Service: expense-tracker-frontend
- Paths: 
  - /
  - /~
- Methods: [GET, OPTIONS]
- Strip Path: false
```
### Final Snippet

```yaml
_format_version: "3.0"
services:
  - name: expense-tracker-frontend
    url: http://expense-tracker-fe-service.expense-tracker.svc.cluster.local:80
    routes:
      - name: expense-tracker-frontend-route
        paths:
          - /~
        protocols:
          - http
          - https
        strip_path: true
```


## 🔧 Step 3: Add Essential Plugins

### 3.1 CORS Plugin (for Backend Service)

```yaml
Plugin Configuration:
- Plugin: cors
- Service: expense-tracker-backend
- Config:
  origins:
    - "*"
  methods:
    - GET
    - POST
    - PUT
    - DELETE
    - OPTIONS
  headers:
    - Accept
    - Content-Type
    - Authorization
  credentials: true
  max_age: 3600
```

### 3.2 Rate Limiting Plugin

```yaml
Plugin Configuration:
- Plugin: rate-limiting
- Service: expense-tracker-backend
- Config:
  minute: 100
  hour: 1000
  policy: local
```

### 3.3 Request Size Limiting Plugin

```yaml
Plugin Configuration:
- Plugin: request-size-limiting
- Service: expense-tracker-backend
- Config:
  allowed_payload_size: 10
```

## 🌐 Step 4: Frontend Configuration Update

Update your frontend configuration to make API calls through Kong:

```yaml
# Update your frontend ConfigMap or environment variables
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
  namespace: expense-tracker
data:
  API_BASE_URL: "https://your-kong-domain.com/api"
  # or if using IP: https://YOUR-KONG-IP/api
```

Update your frontend deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: expense-tracker-fe
  namespace: expense-tracker
spec:
  replicas: 1
  selector:
    matchLabels:
      app: expense-tracker-fe
  template:
    metadata:
      labels:
        app: expense-tracker-fe
    spec:
      imagePullSecrets:
      - name: docker-registry-secret
      securityContext:
        runAsNonRoot: true
        runAsUser: 101
        runAsGroup: 101
        fsGroup: 101
      containers:
      - name: frontend
        image: docker.io/kaderdevops/expense-tracker-fe:v1.2
        ports:
        - containerPort: 8000
        env:
        - name: REACT_APP_API_URL
          value: "https://your-kong-domain.com/api"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
        volumeMounts:
        - name: nginx-cache
          mountPath: /var/cache/nginx
        - name: nginx-pid
          mountPath: /var/run
        livenessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 15
        readinessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: nginx-cache
        emptyDir: {}
      - name: nginx-pid
        emptyDir: {}
```

## 🔍 Step 5: Network Configuration

### 5.1 Network Policy (Optional but Recommended)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: expense-tracker-netpol
  namespace: expense-tracker
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: kong
    ports:
    - protocol: TCP
      port: 7070
    - protocol: TCP
      port: 8000
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kong
    ports:
    - protocol: TCP
      port: 8000
    - protocol: TCP
      port: 8443
```

## ✅ Step 6: Testing the Setup

### 6.1 Get Kong External IP

```bash
# Get the external IP of Kong
KONG_IP=$(kubectl get svc kong-dp-proxy -n kong -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
KONG_HOSTNAME=$(kubectl get svc kong-dp-proxy -n kong -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "Kong IP: $KONG_IP"
echo "Kong Hostname: $KONG_HOSTNAME"
```

### 6.2 Test Backend API

```bash
# Test backend health endpoint
curl https://$KONG_HOSTNAME/api/health

# Test backend API endpoints
curl -X GET https://$KONG_HOSTNAME/api/expenses
curl -X POST https://$KONG_HOSTNAME/api/expenses \
  -H "Content-Type: application/json" \
  -d '{"amount": 100, "description": "Test expense"}'
```

### 6.3 Test Frontend

```bash
# Test frontend
curl https://$KONG_HOSTNAME/

# Or open in browser
echo "Access your app at: https://$KONG_HOSTNAME"
```

## 📊 Step 7: Monitoring and Logging

### 7.1 Check Kong Logs

```bash
# Check Kong data plane logs
kubectl logs -n kong -l app=kong-dp -f

# Check specific service logs
kubectl logs -n kong -l app=kong-dp | grep "expense-tracker"
```

### 7.2 Monitor in Konnect

1. Navigate to **Gateway Manager** → **Runtime Groups**
2. Check **Data Plane Nodes** status
3. Monitor **Service Metrics** and **Request Logs**
4. Set up **Alerts** for error rates and latency

## 🔧 Step 8: Advanced Configuration

### 8.1 SSL/TLS Configuration

```yaml
# Add SSL certificate to Kong
apiVersion: v1
kind: Secret
metadata:
  name: kong-ssl-cert
  namespace: kong
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-cert>
  tls.key: <base64-encoded-key>
```

### 8.2 Custom Domain Configuration

```yaml
# Update Kong service with annotations
apiVersion: v1
kind: Service
metadata:
  name: kong-dp-proxy
  namespace: kong
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "arn:aws:acm:us-east-1:account:certificate/cert-id"
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443"
spec:
  selector:
    app: kong-dp
  ports:
  - name: proxy-http
    port: 80
    targetPort: 8000
  - name: proxy-https
    port: 443
    targetPort: 8443
  type: LoadBalancer
```