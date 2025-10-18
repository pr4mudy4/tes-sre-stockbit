# tes-sre-stockbit by setha

Scaling considerations for 10k concurrent users

ECS tasks: size tasks and set target concurrency per task. For example if your Go app can handle ~500 concurrent connections per task (tune and load test), you need 20 tasks. Use ALB + ECS autoscaling (scale by CPU or request latency).

ALB: can scale automatically; tune idle timeouts and keep-alives.

RDS: separate read traffic to replicas; scale read replica count and size accordingly.

Network: ensure enough ENIs and IPs in private subnets for Fargate tasks (Fargate v1.4+ has improvements but still plan subnet IPs).

How to adapt to GCP quickly

Replace AWS modules with:

VPC → google_compute_network, subnets

ECR → GCR or Artifact Registry

ECS Fargate → Cloud Run (managed) or GKE Autopilot

RDS → Cloud SQL (Postgres / MySQL) with read replicas

Terraform provider: google

Cloud Run + Cloud SQL is easiest: deploy container directly to Cloud Run and configure Cloud SQL connection via serverless VPC or IAM DB auth.

Extra operational suggestions

Use ACM for TLS cert on ALB (or AWS Certificate Manager) and reference the certificate ARN via variable.

Use Secrets Manager / Parameter Store for DB password — do not put DB passwords in Terraform code or git.

Enable CloudWatch logs for ECS and set retention policy.

Add WAF in front of ALB if you need web filtering.

Set health checks and a proper maxSurge rolling deployment strategy (ECS handles it via new task set).

Recap & next steps I can do for you

What I included:

Architecture diagram (Mermaid),

Tech stack + DB replication + network + SG design,

Modular Terraform modules (vpc, ecr, rds, ecs) with sample root manifests,

Full Go API and Alpine Dockerfile,

GitLab CI pipeline to provision infra, build & push image, and apply deployment.
