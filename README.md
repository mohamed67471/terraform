# terraform wordpress Project 

## Project Overview

This project deploys a **highly automated WordPress environment** on AWS using Terraform. The setup follows best practices for security, scalability, and maintainability.  

**Key components and their configuration:**

1. **VPC and Subnets**
   - A single VPC (`10.0.0.0/16`) with **public** and **private subnets**.  
   - Public subnets host the **Application Load Balancer (ALB)** and **NAT Gateway**.  
   - Private subnets host the **WordPress EC2 instance** and **RDS MySQL database**.  
   - This separation ensures that sensitive resources (EC2 and RDS) are not exposed directly to the internet.

2. **Route Tables and Traffic Flow**
   - **Public route table:** Routes internet-bound traffic from public subnets to the Internet Gateway.  
   - **Private route table:** Routes internet-bound traffic from private subnets through the NAT Gateway.  
   - Web traffic from users comes through the ALB, which forwards requests to the private WordPress EC2 instance.

3. **Security Groups**
   - **ALB SG:** Allows inbound HTTP (port 80) from anywhere.  
   - **WordPress EC2 SG:** Allows inbound HTTP (port 80) **only from the ALB**.  
   - **RDS SG:** Allows inbound MySQL (port 3306) **only from the WordPress EC2 SG**.  
   - **SSH SG (demo):** Allows SSH for administrative access.

4. **EC2 WordPress Instance**
   - Runs Nginx, PHP, and WordPress.  
   - Deployed in a **private subnet** to enhance security.  
   - Uses **cloud-init (user_data)** for fully automated installation of WordPress and dependencies.  

5. **RDS MySQL Database**
   - Hosted in **private subnets** for security.
 - Secure access controlled via Security Groups.  
   - Provides a persistent backend for WordPress content.  

6. **Application Load Balancer (ALB)**
   - Deployed in **public subnets** to handle internet traffic

7. **S3 Bucket**
   - Used to store **Terraform state files**.  
   - Configured with **server-side encryption (AES256)** to secure sensitive infrastructure state.  
   - Ensures **IaC best practices**, enabling safe collaboration and state recovery.

**Type of Setup and Use Cases**
- This is a **private WordPress setup behind a public ALB**, ideal for:
  - Development and testing environments.
  - Internal company blogs or CMS that need secure backend access.
  - Scenarios where public internet access to the EC2 instance itself should be restricted.  

**Benefits**
- Fully automated deployment using Terraform.  
- Segregation of resources for improved security.  
- Easily extensible and reusable for production-grade setups.  
- State management with S3 ensures version control and safe collaboration.  

---

## Acess of wordpress from ALb 
<img width="940" height="505" alt="image" src="https://github.com/user-attachments/assets/66b06317-ec43-4da2-aed5-60e824b2ccbc" />













## Imporvements
 
1) Secure EC2 access:
Only your IP address is allowed to SSH into the EC2 instance via a variable my_ip.

2) Parameterization using Variables

3) Health check for ALB:

ALB routes traffic only to healthy EC2 instances.

4) Security improvements (future considerations):

Use AWS Secrets Manager for database credentials.

Enable HTTPS for ALB using an SSL certificate.

Multi-AZ deployment for RDS for higher availability.
