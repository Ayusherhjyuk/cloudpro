# AWS Data Pipeline with Minikube + LocalStack


⚡ **Note:** Due to AWS Free Tier limitations, my previous account had already exhausted its quota.
When I created a new AWS account, the verification process required 1–2 days before access to services could be granted.
Since I was working against strict time constraints, directly using AWS was not feasible for this task.


## ⚡ Local AWS-Equivalent Setup

To overcome this limitation, I implemented the entire pipeline on local infrastructure using LocalStack and Minikube.

**LocalStack S3 → Equivalent to Amazon S3 for raw and processed data storage.**

**Minikube (Kubernetes cluster) → Equivalent to Amazon EKS for container orchestration.**

**Kubernetes CronJob → Equivalent to AWS Batch Scheduled Jobs for recurring data processing tasks.**

This architecture mirrors a production-ready AWS environment but runs entirely on local resources.
It allows seamless migration to AWS with minimal changes, while still enabling end-to-end testing, CI/CD integration, and validation of the workflow.

---

## 🚀 Steps to Deploy the Solution

Run the following commands in order:

```bash
# 1. Start Minikube
minikube start

# 2. Point Docker to Minikube (for local image build)
minikube docker-env --shell powershell | Invoke-Expression

# 3. Deploy LocalStack (S3 mock)
kubectl apply -f k8s/localstack-deployment.yaml
kubectl apply -f k8s/localstack-service.yaml

# 4. Verify pods
kubectl get pods -o wide 

# 5. Create S3 buckets (equivalent to AWS S3 bucket creation)
kubectl exec -it localstack-<pod-id> -- awslocal s3 mb s3://raw-data
kubectl exec -it localstack-<pod-id> -- awslocal s3 mb s3://processed-data

# 6. Upload input file (equivalent to aws s3 cp input.csv s3://raw-data/input.csv)
kubectl cp data\sample_input_data.csv localstack-<pod-id>:/tmp/sample_input_data.csv
kubectl exec -it localstack-<pod-id> -- awslocal s3 cp /tmp/sample_input_data.csv s3://raw-data/input.csv

# 7. Deploy CronJob (equivalent to AWS Batch/CronJob)
kubectl apply -f k8s/cronjob.yaml

# 8. Run Job manually for testing
kubectl delete job test-job --ignore-not-found
kubectl create job --from=cronjob/s3-processor-cron test-job

# 9. Port-forward LocalStack for AWS CLI access
kubectl port-forward svc/localstack 4567:4566

# 10. Download processed output (equivalent to aws s3 cp s3://processed-data/output.csv)
aws --endpoint-url=http://localhost:4567 s3 cp s3://processed-data/output.csv output.csv

# Output:
# download: s3://processed-data/output.csv to .\output.csv
```

---

## 🔐 Security and IAM Decisions

Instead of real IAM roles & AWS credentials, I used credentials:

```
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
```

Because LocalStack does not validate them.

In a real AWS environment:

- We would assign least-privilege IAM roles to the pod via IRSA (IAM Roles for Service Accounts).
- The job would only have S3 read/write access to the specific buckets (`raw-data` and `processed-data`).

---

## ⚖️ Trade-offs and Assumptions

- Minikube is acting as a local EKS cluster. In real AWS, this would be Amazon EKS.
- Kubernetes CronJob is equivalent to AWS Batch Scheduled Job.
- LocalStack S3 is equivalent to Amazon S3 for input/output storage.
- IAM is simplified locally with dummy credentials.
- We chose this setup due to time constraints and AWS Free Tier limitation.

---

## 🔄 CI/CD Pipeline

CI/CD is implemented using GitHub Actions.

The pipeline does the following:

1. Starts Minikube inside the GitHub Actions runner.  
2. Builds the Docker image (`s3-processor:latest`) directly into Minikube’s Docker daemon.  
3. Deploys LocalStack (mock AWS).  
4. Creates S3 buckets (`raw-data` and `processed-data`).  
5. Uploads a sample input file into the raw-data bucket.  
6. Deploys the CronJob.  
7. Triggers the job manually for testing.  
8. Waits for the job to complete and collects logs.  
9. Verifies that the processed file appears in the processed-data bucket.  

This workflow mimics a real AWS CI/CD pipeline where you would deploy to **EKS, S3, and Batch**, but entirely on local infrastructure.
