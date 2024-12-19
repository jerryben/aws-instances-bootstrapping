# AWS DevOps Environment Setup

This repository contains Terraform configurations to set up a DevOps-ready infrastructure on AWS. The setup includes a VPC, subnets, security groups, key pairs, and EC2 instances pre-configured for Jenkins, SonarQube, and Tomcat. Additionally, the configurations support Datadog integration for monitoring. This setup is designed to allow developers to deploy and manage DevOps tools seamlessly in a secure and scalable environment.

---

## Features

- **Custom VPC**: A dedicated VPC with DNS support and hostname resolution enabled.
- **Subnet**: A public subnet for hosting instances with internet access.
- **Security Groups**: Fine-grained access control for services like SSH, Jenkins, SonarQube, Tomcat, and monitoring tools such as Datadog.
- **Key Pair**: Secure SSH access with a pre-configured key pair.
- **Internet Gateway and Route Table**: Seamless internet connectivity pfor resources in the public subnet.
- **Dynamic Role-Based Instance Configuration**: Automatically provisions EC2 instances with role-specific configurations using custom scripts.
- **Datadog Integration**: Supports monitoring of instances with Datadog agents.

---

## Prerequisites

1. **AWS Account**: Ensure you have an active AWS account.
2. **Terraform Installed**: Install Terraform (>= 1.0.0) on your local machine.
3. **AWS CLI Configured**: Configure the AWS CLI with appropriate access credentials.
4. **SSH Key Pair**: Generate an SSH key pair named `devops_key` and place the public key at `~/.ssh/devops_key.pem.pub`.
5. **Datadog API Key**: Obtain a valid API key for Datadog.

---

## Setup Instructions

### Step 1: Clone the Repository

```bash
git clone https://github.com/jerryben/aws-instances-bootstrapping.git
cd your-repo
```

### Step 2: Configure Variables

Create a `terraform.tfvars` file in the root directory and populate it with your variables:

```hcl
region          = "us-east-1"         # Replace with your desired AWS region
ami_id          = "ami-0abcdef1234567890"  # Replace with your AMI ID
instance_type   = "t2.medium"         # Replace with your desired instance type
datadog_api_key = "your-datadog-api-key"  # Replace with your Datadog API key
```

### Step 3: Initialize Terraform

Run the following command to download the required provider plugins:

```bash
terraform init
```

### Step 4: Plan the Infrastructure

Review the resources that will be created by Terraform:

```bash
terraform plan
```

### Step 5: Apply the Configuration

Provision the infrastructure:

```bash
terraform apply
```

---

## Project Structure

```plaintext
.
├── main.tf                 # Core Terraform configurations
├── variables.tf            # Input variables for the project
├── outputs.tf              # Outputs for accessing deployed resources
├── scripts/                # User data scripts for configuring instances
│   ├── jenkins.sh          # Jenkins setup script
│   ├── sonarqube.sh        # SonarQube setup script
│   └── tomcat.sh           # Tomcat setup script
├── terraform.tfvars        # Variable values (not included in the repo for security)
└── README.md               # Project documentation
```

---

## Security Group Rules

Note that in real cases, the source here must be limited to an IP or a IP range.

### Ingress Rules

| Protocol | Port Range | Purpose            | Source    |
| -------- | ---------- | ------------------ | --------- |
| TCP      | 22         | SSH Access         | 0.0.0.0/0 |
| TCP      | 80         | HTTP (Web Access)  | 0.0.0.0/0 |
| TCP      | 443        | HTTPS (Secure Web) | 0.0.0.0/0 |
| TCP      | 8080       | Jenkins Access     | 0.0.0.0/0 |
| TCP      | 9090       | Cockpit Access     | 0.0.0.0/0 |
| UDP      | 8125       | Datadog Metrics    | 0.0.0.0/0 |

### Egress Rules

| Protocol | Port Range | Purpose         | Destination |
| -------- | ---------- | --------------- | ----------- |
| All      | All        | Internet Access | 0.0.0.0/0   |

---

## Custom Scripts

The `scripts/` directory contains user data scripts for provisioning each EC2 instance:

- **jenkins.sh**: Installs Jenkins and required dependencies.
- **sonarqube.sh**: Installs SonarQube and sets up its environment.
- **tomcat.sh**: Deploys Tomcat and configures it for web applications.

### Example: `jenkins.sh`

```bash
#!/bin/bash
apt-get update && apt-get install -y openjdk-11-jdk jenkins
systemctl enable jenkins && systemctl start jenkins
```

---

## Outputs

After applying the Terraform configuration, you can view the outputs:

- **VPC ID**: The ID of the created VPC.
- **Subnet ID**: The ID of the created subnet.
- **Instance Public IPs**: The public IPs of the provisioned instances.

---

## Cleanup

To destroy the created infrastructure:

```bash
terraform destroy
```

---

## Future Enhancements

- Add support for additional roles and tools (e.g., Nexus, Prometheus).
- Automate backups for persistent volumes.
- Introduce scaling policies for instances.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## Contributing

Contributions are welcome! Please fork this repository and create a pull request for any feature enhancements or bug fixes.
