
## 2. ARCHITECTURE.md
kdown
# StartTech Infrastructure Architecture

Comprehensive documentation of the StartTech infrastructure architecture, components, and data flow.

## 📐 Architecture Overview

### High-Level Architecture

┌─────────────────────────────────────────────────────────────┐
│ Internet                                                    │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ CloudFront (CDN)                                          │
│ Global Content Delivery Network                            │
│ - SSL/TLS Termination                                     │
│ - Caching (1 hour default)                                │
│ - Geographic Distribution                                │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌───────────────────┴───────────────────┐
│                                       │
▼                                       ▼
┌───────────────┐               ┌──────────────────┐
│ S3 Bucket     │               │ ALB (Port 80)    │
│ (Frontend)   │               │ Application      │
│               │               │ Load Balancer    │
│ - Static      │               │ - Health Checks  │
│   Website     │               │ - SSL/TLS        │
│ - Public Read │               │ - Auto Scaling   │
└───────────────┘               └────────┬─────────┘
                                          │
                                          ▼
┌──────────────────────────────────────────┐
│ Auto Scaling Group (EC2 Instances)        │
│                                          │
│ ┌────────────────────┐  ┌─────────────┐ │
│ │ EC2 Instance 1     │  │ EC2 Instance│ │
│ │ - Docker           │  │ 2           │ │
│ │ - Backend API      │  │ - Docker    │ │
│ │ - Port 8080        │  │ - Backend   │ │
│ └────────────────────┘  │   API       │ │
│                           │ - Port 8080│ │
│                           └─────────────┘ │
└──────────┬───────────────────────────────┘
           │
           ▼
┌──────────────────────┐
│ MongoDB Database     │
│ (External)           │
│                      │
│ - User Data          │
│ - Application Data   │
└──────────────────────┘

## 🏗️ Component Details

### 1. Networking Layer

#### VPC (Virtual Private Cloud)
- **CIDR**: 10.0.0.0/16
- **Region**: eu-west-1
- **Availability Zones**: eu-west-1a, eu-west-1b

#### Subnets
- **Public Subnets**: 
  - 10.0.1.0/24 (eu-west-1a)
  - 10.0.2.0/24 (eu-west-1b)
  - Used for: ALB, NAT Gateway (if configured)
  
- **Private Subnets**:
  - Used for: EC2 instances in Auto Scaling Group
  - No direct internet access
  - Access via ALB only

#### Internet Gateway
- Provides internet access for public subnets
- Attached to VPC

#### Route Tables
- Public route table: Routes to Internet Gateway
- Private route table: Routes to NAT Gateway (if configured)

### 2. Compute Layer

#### Auto Scaling Group (ASG)
- **Instance Type**: t2.micro
- **Desired Capacity**: 2
- **Min Size**: 2
- **Max Size**: 4
- **Health Check Type**: ELB
- **Health Check Grace Period**: 180 seconds
- **Subnets**: Private subnets

#### EC2 Instances
- **AMI**: Ubuntu 22.04 LTS 
- **User Data Script**:
  1. Installs Docker
  2. Logs into ECR
  3. Pulls latest container image
  4. Runs container on port 8080
  5. Health check validation

#### Launch Template
- Defines instance configuration
- Includes IAM instance profile
- Security group assignment
- User data script

### 3. Load Balancing

#### Application Load Balancer (ALB)
- **Type**: Application Load Balancer
- **Scheme**: Internet-facing
- **Subnets**: Public subnets
- **Security Group**: Allows HTTP (port 80) from internet
- **Listeners**: 
  - Port 80 → Target Group

#### Target Group
- **Protocol**: HTTP
- **Port**: 8080
- **Health Check Path**: `/health`
- **Health Check Protocol**: HTTP
- **Deregistration Delay**: Default

### 4. Storage Layer

#### S3 Bucket
- **Purpose**: Frontend static website hosting
- **Configuration**:
  - Static website hosting enabled
  - Index document: `index.html`
  - Public read access
  - CloudFront Origin Access Identity for secure access

#### CloudFront Distribution
- **Origin**: S3 bucket
- **Behavior**:
  - Cache TTL: 1 hour (default)
  - Viewer Protocol Policy: Redirect HTTP to HTTPS
  - Allowed Methods: GET, HEAD
- **SSL Certificate**: CloudFront default certificate
- **Geographic Distribution**: Global edge locations

### 5. Container Registry

#### ECR (Elastic Container Registry)
- **Repository**: `starttech-backend`
- **Image Scanning**: Enabled on push
- **Tag Mutability**: Mutable
- **Access**: EC2 instances via IAM role

### 6. Security

#### Security Groups

**ALB Security Group**:
- Ingress: Port 80 from 0.0.0.0/0
- Egress: All traffic

**Backend Security Group**:
- Ingress: Port 8080 from ALB security group only
- Egress: All traffic

#### IAM Roles

**EC2 Instance Role**:
- **Permissions**:
  - ECR: Pull images
  - CloudWatch: Write logs and metrics
  - SSM: Session Manager access
- **Attached Policies**:
  - `CloudWatchAgentServerPolicy`
  - `AmazonSSMManagedInstanceCore`

### 7. Monitoring & Observability

#### CloudWatch Log Groups
- `/starttech/backend` - Backend application logs (14 days retention)
- `/starttech/frontend` - Frontend logs (14 days retention)

#### CloudWatch Alarms
- High CPU utilization (70%, 90%)
- Unhealthy targets
- High response times
- Error rate monitoring

#### CloudWatch Dashboard
- Real-time metrics visualization
- EC2, ALB, CloudFront metrics
- Log insights integration

#### SNS Topic
- `starttech-alarms` - Centralized alerting
- Email subscriptions for notifications

## 🔄 Data Flow

### Frontend Request Flow

1. **User Request** → CloudFront
2. **CloudFront** checks cache
   - Cache hit → Return cached content
   - Cache miss → Fetch from S3
3. **S3** returns static files
4. **CloudFront** caches and serves to user

### Backend API Request Flow

1. **User Request** → CloudFront (if configured) or directly to ALB
2. **ALB** receives request on port 80
3. **ALB** routes to healthy target in Target Group
4. **EC2 Instance** receives request on port 8080
5. **Docker Container** processes request
6. **Backend Application**:
   - Validates request
   - Queries MongoDB (if needed)
   - Processes business logic
   - Returns response
7. **Response** flows back through ALB to user

### Health Check Flow

1. **ALB** sends health check to `/health` endpoint
2. **EC2 Instance** responds with health status
3. **ALB** marks instance as healthy/unhealthy
4. **ASG** replaces unhealthy instances automatically

## 🔐 Security Architecture

### Network Security
- **Public/Private Subnet Separation**: Backend instances in private subnets
- **Security Groups**: Least privilege access
- **No Direct Internet Access**: EC2 instances accessed only via ALB

### Application Security
- **HTTPS**: CloudFront enforces HTTPS
- **JWT Authentication**: Backend validates JWT tokens
- **Environment Variables**: Sensitive data via environment variables
- **Container Security**: Non-root user in containers

### Access Control
- **IAM Roles**: Instance-based authentication
- **ECR Access**: IAM-based image pulling
- **S3 Access**: CloudFront OAI for secure access

## 📊 Scalability

### Horizontal Scaling
- **Auto Scaling Group**: Automatically scales based on demand
- **Load Balancer**: Distributes traffic across instances
- **CloudFront**: Global distribution reduces origin load

### Vertical Scaling
- **Instance Type**: Can be upgraded (t2.micro → t2.small, etc.)
- **Container Resources**: Configurable CPU/memory limits

### Scaling Triggers
- **Manual**: Adjust desired capacity
- **Scheduled**: Based on time patterns
- **Dynamic**: Based on CloudWatch metrics (CPU, network, etc.)

## 🔄 High Availability

### Multi-AZ Deployment
- **Subnets**: Across 2 availability zones
- **ASG**: Instances distributed across AZs
- **ALB**: Health checks across all AZs

### Fault Tolerance
- **Health Checks**: Automatic unhealthy instance replacement
- **Auto Scaling**: Maintains desired capacity
- **Load Balancing**: Traffic routed to healthy instances only

## 📈 Performance Optimization

### Caching
- **CloudFront**: Edge caching for frontend assets
- **Cache TTL**: Configurable per resource type

### Connection Pooling
- **MongoDB**: Connection pooling in application
- **ALB**: Connection keep-alive

### Compression
- **CloudFront**: Automatic compression for supported content types

## 🔍 Monitoring Points

### Key Metrics
- **EC2**: CPU, Memory, Network In/Out
- **ALB**: Request count, Response time, Error rates
- **CloudFront**: Requests, Cache hit rate, Error rates
- **ASG**: Desired vs Actual capacity

### Log Aggregation
- **CloudWatch Logs**: Centralized logging
- **Log Insights**: Query and analyze logs
- **Structured Logging**: JSON format for easy parsing

## 🛠️ Technology Stack

| Component | Technology |
|-----------|-----------|
| Infrastructure | Terraform |
| Cloud Provider | AWS |
| Compute | EC2 (Ubuntu 22.04) |
| Containers | Docker |
| Container Registry | ECR |
| Load Balancer | Application Load Balancer |
| Storage | S3 |
| CDN | CloudFront |
| Monitoring | CloudWatch |
| Notifications | SNS |
| Database | MongoDB (External) |

## 📝 Design Decisions

### Why Auto Scaling Group?
- Automatic instance replacement
- Cost optimization (scale down during low traffic)
- High availability

### Why ALB over Classic LB?
- Layer 7 routing capabilities
- Better integration with containers
- Advanced health checks
- Path-based routing (future expansion)

### Why Private Subnets for EC2?
- Security: No direct internet exposure
- Compliance: Follows security best practices
- Control: All traffic through ALB

### Why CloudFront?
- Global content delivery
- Reduced latency
- DDoS protection
- Cost optimization (reduced S3 requests)

### Why ECR?
- Integrated with AWS services
- Image scanning
- Cost-effective for container storage
- IAM-based access control

## 🔮 Future Enhancements

### Planned Improvements
- [ ] WAF (Web Application Firewall) integration
- [ ] Custom domain with SSL certificate
- [ ] Multi-region deployment
- [ ] Redis caching layer
- [ ] Database migration to RDS
- [ ] Blue/Green deployments
- [ ] Canary deployments
- [ ] Enhanced monitoring with X-Ray

---

**Last Updated**: [Current Date]
**Architecture Version**: 1.0