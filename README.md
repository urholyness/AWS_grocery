# GroceryMate — AWS Cloud Deployment

[![Python](https://img.shields.io/badge/Python-3.9-blue)](https://www.python.org/)
[![Flask](https://img.shields.io/badge/Flask-3.0.3-lightgrey)](https://flask.palletsprojects.com/)
[![React](https://img.shields.io/badge/React-16.14-61DAFB)](https://reactjs.org/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-orange)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC)](https://www.terraform.io/)
[![Docker](https://img.shields.io/badge/Container-Docker-2496ED)](https://www.docker.com/)
[![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL%2013-336791)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](#license)

GroceryMate is a full-stack online grocery shopping platform built as part of the Masterschool Cloud Engineering program. The application is fully deployed on AWS using EC2, RDS, and S3 — with all infrastructure defined and automated through Terraform.

---

## Table of Contents

- [Cloud Architecture](#cloud-architecture)
  - [Architecture Diagram](#architecture-diagram)
  - [AWS Services Used](#aws-services-used)
- [Infrastructure as Code — Terraform](#infrastructure-as-code--terraform)
- [Environment Variables](#environment-variables)
- [Requirements](#requirements)
- [Running with Docker](#running-with-docker)
- [Database Setup](#database-setup)
- [Getting Started Locally](#getting-started-locally)
- [Troubleshooting](#troubleshooting)
- [Screenshots](#screenshots)
- [License](#license)

---

## Cloud Architecture

### Architecture Diagram

```mermaid
flowchart LR
    User(["👤 User\n(Browser)"])

    subgraph AWS["☁️ AWS Cloud — eu-north-1 (Stockholm)"]

        IGW["🌐 Internet\nGateway"]

        subgraph VPC["VPC  10.0.0.0/16"]

            subgraph PubSub["Public Subnet  10.0.1.0/24  (AZ-a)"]
                subgraph EC2Box["🖥️ EC2  t3.micro"]
                    React["⚛️ React\nFrontend"]
                    Docker["🐳 Docker Container\n🐍 Flask API"]
                end
            end

            subgraph PrivSub1["Private Subnet  10.0.2.0/24  (AZ-b)"]
                RDS[("🗄️ RDS\nPostgreSQL 13\ndb.t3.micro")]
            end

            subgraph PrivSub2["Private Subnet  10.0.3.0/24  (AZ-c)"]
                RDS2[("🗄️ RDS Subnet\nGroup (AZ-c)")]
            end

        end

        S3["📦 S3 Bucket\nAvatar Storage\n(Private)"]
        IAM["🔑 IAM Role\n+ Instance Profile"]

    end

    User -->|"HTTP :80"| IGW
    IGW --> EC2Box
    Docker -->|"Port 5432"| RDS
    RDS -.->|"DB Subnet Group"| RDS2
    Docker <-->|"boto3 SDK"| S3
    IAM -->|"Grants S3\naccess to EC2"| EC2Box
```

> **Note:** S3 is a global AWS managed service — it sits outside the VPC. The EC2 instance accesses it over the internet using an IAM role (no hardcoded keys needed).

---

### AWS Services Used

| Service | What it does in this project | Why we chose it |
|---|---|---|
| **VPC** | Isolated private network (`10.0.0.0/16`) containing all resources | Every AWS deployment needs a VPC to control networking. It lets us separate public and private resources and control exactly what traffic is allowed in or out. |
| **Internet Gateway (IGW)** | Entry point connecting the public subnet to the internet | Without an IGW, nothing in the VPC is reachable from the internet. It acts as the "front door" for the EC2 instance. |
| **Public Subnet** | Hosts the EC2 web server (`10.0.1.0/24`, AZ-a) | The EC2 needs a public IP so users can reach it. A public subnet routes outbound traffic through the IGW. |
| **Private Subnets** | Host the RDS database (`10.0.2.0/24` AZ-b, `10.0.3.0/24` AZ-c) | The database should never be directly reachable from the internet. Private subnets have no route to the IGW, so only the EC2 instance can talk to RDS (via its security group). |
| **Security Groups** | Firewall rules for EC2 (ports 80, 22, 5000) and RDS (port 5432 from EC2 only) | Act as virtual firewalls. The RDS security group only allows inbound PostgreSQL connections from the EC2 security group — nothing else can reach the database. |
| **EC2 (t3.micro)** | Runs the Flask API and serves the React frontend inside a Docker container | A general-purpose virtual server. `t3.micro` is cost-efficient for a development/demo workload and falls within the AWS Free Tier. |
| **RDS PostgreSQL 13 (db.t3.micro)** | Managed relational database storing all users, products, baskets, reviews | Running a database on EC2 means you manage backups, patching, and availability yourself. RDS handles all of that automatically. It also survives EC2 restarts since it runs independently. |
| **S3** | Stores user profile avatar images outside of EC2 | Files stored directly on EC2 are lost if the instance is replaced. S3 gives permanent, durable object storage that any EC2 instance can access regardless of restarts. |
| **IAM Role + Instance Profile** | Grants the EC2 instance permission to read/write the S3 bucket | The correct way to give EC2 access to S3. Instead of embedding AWS credentials in the app or `.env` file, the EC2 instance "is" the IAM role and can authenticate to S3 automatically. |

---

## Infrastructure as Code — Terraform

All AWS resources are defined in code inside the `infrastructure/` directory. This means the entire cloud environment can be created, updated, or destroyed with a few commands — no clicking around in the AWS console.

### File structure

```
infrastructure/
├── main.tf         # VPC, subnets, IGW, route tables, security groups, EC2, RDS
├── s3_aim.tf       # S3 bucket, IAM policy, IAM role, instance profile
└── variables.tf    # Input variables (region, project name, DB credentials)
```

### Commands

```bash
cd infrastructure

# 1. Download required Terraform providers (run once)
terraform init

# 2. Preview what will be created/changed before applying
terraform plan \
  -var="db_username=grocery_user" \
  -var="db_password=your_secure_password"

# 3. Create all AWS resources
terraform apply \
  -var="db_username=grocery_user" \
  -var="db_password=your_secure_password"

# 4. Tear down everything (stops all AWS charges)
terraform destroy \
  -var="db_username=grocery_user" \
  -var="db_password=your_secure_password"
```

After `terraform apply` completes, it prints two outputs you will need:

```
s3_bucket_for_docker = "terraform-grocerymate-avatars-xxxx"
s3_region_for_docker = "eu-north-1"
```

Add these values to your `.env` file (see [Environment Variables](#environment-variables) below).

### Terraform variables

| Variable | Default | Sensitive | Description |
|---|---|---|---|
| `aws_region` | `eu-north-1` | No | AWS region to deploy into |
| `project_name` | `terraform-grocerymate` | No | Prefix used for all resource names |
| `db_username` | — | **Yes** | RDS master username |
| `db_password` | — | **Yes** | RDS master password |
| `aws_profile` | `AdministratorAccess-941781854407` | No | AWS CLI profile name |

> Never hardcode `db_username` or `db_password` in any file. Pass them as `-var` flags or use a `terraform.tfvars` file that is listed in `.gitignore`.

---

## Environment Variables

Create a `.env` file inside the `backend/` directory before running the app.

```bash
# macOS / Linux
touch backend/.env

# Windows
ni backend/.env -Force
```

Generate a secure JWT secret key:

```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

Fill in `backend/.env`:

```ini
# ── Authentication ──────────────────────────────────────
JWT_SECRET_KEY=<paste your generated key here>

# ── Database (local) ────────────────────────────────────
POSTGRES_USER=grocery_user
POSTGRES_PASSWORD=your_password
POSTGRES_DB=grocerymate_db
POSTGRES_HOST=localhost
POSTGRES_URI=postgresql://grocery_user:your_password@localhost:5432/grocerymate_db

# ── AWS S3 (fill in after terraform apply) ───────────────
AWS_S3_BUCKET=terraform-grocerymate-avatars-xxxx
AWS_REGION=eu-north-1
```

When deploying to AWS, replace `POSTGRES_HOST=localhost` with the **RDS endpoint** from the AWS console (looks like `xxxxx.eu-north-1.rds.amazonaws.com`).

---

## Requirements

### Backend

| Requirement | Version |
|---|---|
| Python | >= 3.9 |
| Flask | 3.0.3 |
| Flask-SQLAlchemy | 3.1.1 |
| Flask-JWT-Extended | 4.6.0 |
| Flask-Migrate | 4.0.7 |
| Flask-CORS | 4.0.1 |
| SQLAlchemy | 2.0.34 |
| psycopg2-binary | 2.9.9 |
| gunicorn | 22.0.0 |
| boto3 (AWS SDK) | 1.34.158 |
| python-dotenv | 1.0.1 |
| pydantic | 2.8.2 |

Install all backend dependencies:

```bash
cd backend
pip install -r requirements.txt
```

### Frontend

| Requirement | Version |
|---|---|
| Node.js | >= 16 |
| npm | >= 8 |
| React | 16.14.0 |
| React Router | 6.25.1 |
| Axios | 1.7.2 |
| Tailwind CSS | 3.3.0 |

Install all frontend dependencies:

```bash
cd frontend
npm install
```

### Infrastructure / Deployment

| Tool | Version |
|---|---|
| Terraform | >= 1.0 |
| AWS CLI | >= 2.0 |
| Docker | >= 20.0 |

---

## Running with Docker

The Flask backend is containerised so it runs the same way locally and on EC2.

**Build the image:**

```bash
cd backend
docker build -t grocerymate-backend .
```

**Run the container locally:**

```bash
docker run -d \
  -p 5000:5000 \
  --env-file .env \
  grocerymate-backend
```

**Check if it's running:**

```bash
docker ps
docker logs <container_id>
```

**The Dockerfile (`backend/Dockerfile`):**

```dockerfile
FROM python:3.9
WORKDIR /app
COPY . .
COPY .env .env
RUN pip install -r requirements.txt
CMD ["python", "run.py"]
```

---

## Database Setup

The application uses PostgreSQL. A SQL dump file with all initial product and user data is included at `backend/app/sqlite_dump_clean.sql`.

### Local setup

```bash
# Create the database and user
psql -U postgres -c "CREATE DATABASE grocerymate_db;"
psql -U postgres -c "CREATE USER grocery_user WITH ENCRYPTED PASSWORD 'your_password';"
psql -U postgres -c "ALTER USER grocery_user WITH SUPERUSER;"

# Load the initial data
psql -U grocery_user -d grocerymate_db -f backend/app/sqlite_dump_clean.sql

# Verify the data loaded
psql -U grocery_user -d grocerymate_db -c "SELECT COUNT(*) FROM products;"
psql -U grocery_user -d grocerymate_db -c "SELECT COUNT(*) FROM users;"
```

### On AWS (RDS)

After running `terraform apply`, get the RDS endpoint from the AWS console or Terraform output, then run the same `psql` commands but with `-h <RDS_ENDPOINT>` instead of connecting locally:

```bash
psql -h <your-rds-endpoint>.eu-north-1.rds.amazonaws.com \
     -U grocery_user \
     -d grocerymate_db \
     -f backend/app/sqlite_dump_clean.sql
```

---

## Getting Started Locally

```bash
# 1. Clone the repo
git clone https://github.com/AlejandroRomanIbanez/AWS_grocery.git
cd AWS_grocery

# 2. Set up database (see Database Setup above)

# 3. Run the backend
cd backend
pip install -r requirements.txt
# create .env file first (see Environment Variables above)
python run.py

# 4. Run the frontend (new terminal)
cd frontend
npm install
npm start
```

- Frontend: `http://localhost:3000`
- Backend API: `http://localhost:5000`

---

## Troubleshooting

These are real issues that came up while building this project.

**`psycopg2.OperationalError: could not connect to server`**
The Flask app can't reach PostgreSQL. Check that:
- PostgreSQL is running locally (`pg_isready`)
- `POSTGRES_HOST` in `.env` is `localhost` for local dev and the RDS endpoint for AWS
- The RDS security group allows port 5432 **only from the EC2 security group**, not from your local IP

**`botocore.exceptions.NoCredentialsError` when uploading an avatar**
The app can't authenticate to S3. On EC2 this shouldn't happen if the IAM instance profile is attached correctly via Terraform. Locally, you need valid AWS credentials configured (`aws configure`). Double check that `AWS_S3_BUCKET` and `AWS_REGION` are set in `.env`.

**Docker container exits immediately after starting**
Usually a missing or malformed `.env` file. Run `docker logs <container_id>` to see the actual error. The Dockerfile copies `.env` at build time, so make sure it exists in the `backend/` directory before building.

**Terraform `Error: InvalidAMIID.NotFound`**
The AMI ID in `main.tf` is region-specific. The ID `ami-00329fcfb4c23f789` is only valid in `eu-north-1`. If you change the region in `variables.tf`, you need to find the correct Amazon Linux 2 AMI ID for that region from the AWS console.

**RDS connection works locally but not from EC2**
The `POSTGRES_HOST` in your `.env` on EC2 must point to the RDS endpoint, not `localhost`. Also make sure the RDS security group ingress rule references the EC2 **security group ID**, not a CIDR block.

**`terraform apply` fails with `Error acquiring the state lock`**
A previous Terraform run may have crashed. Run `terraform force-unlock <LOCK_ID>` using the lock ID shown in the error message.

---

## Screenshots

![Home Page](https://github.com/user-attachments/assets/ea039195-67a2-4bf2-9613-2ee1e666231a)
![Product Store](https://github.com/user-attachments/assets/a87e5c50-5a9e-45b8-ad16-2dbff41acd00)
![Product Detail](https://github.com/user-attachments/assets/589aae62-67ef-4496-bd3b-772cd32ca386)
![Checkout](https://github.com/user-attachments/assets/2772b85e-81f7-446a-9296-4fdc2b652cb7)

https://github.com/user-attachments/assets/d1c5c8e4-5b16-486a-b709-4cf6e6cce6bc

---

## License

This project is licensed under the MIT License.
