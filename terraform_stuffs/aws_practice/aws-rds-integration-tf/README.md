🌐 Seamless Web App Integration with RDS MySQL & Automated Deployment 🤖
```markdown
# Automating EC2 and RDS Integration with Terraform

## Introduction

In the ever-evolving landscape of cloud computing, efficiency and automation are the keys to success. Imagine a seamless integration between Amazon Elastic Compute Cloud (EC2) instances and Amazon Relational Database Service (RDS) using the powerful tool, Terraform. This journey embarks on an exciting exploration of how to effortlessly bring these two fundamental AWS services together, streamlining your infrastructure deployment process while minimizing manual configuration steps. Let's delve into this automation adventure step by step, unlocking the full potential of your AWS resources! 🌐🛠️💼

## Objective

The objective of this post is to bring and spread knowledge about #aws cloud services, how to, and where to consume the #aws services to solve real-world business challenges.

## Use Case

Imagine seamlessly integrating your web application with an RDS MySQL database while automating the entire deployment process. In a real-time use case scenario, this means that when your web application needs to access or store data, it can do so effortlessly with the RDS MySQL database. This integration ensures your application can quickly and efficiently manage user data, transactions, or any other data-related functions without manual intervention.

Moreover, by automating the deployment process, you eliminate the need for manual configuration and setup. When your web application needs to scale, recover from failures, or adapt to changes, it can do so automatically. This ensures that your application remains responsive, available, and resilient, providing a seamless experience for both users and administrators.

This real-time use case exemplifies how combining RDS MySQL with automated deployment can streamline your web application's data management, making it more robust and adaptable to the demands of a dynamic online environment.

## Challenge: Automating RDS Endpoint and MySQL Connection String

### Objective

Can you automate the generation of an RDS endpoint and MySQL connection string using Terraform?

### Scenario

You're managing a dynamic cloud environment, and part of your task involves setting up an RDS database. To ensure the applications running on your EC2 instances can seamlessly connect to the database, you need an automated way to retrieve the RDS endpoint and construct the MySQL connection string.

### Challenge

Create a Terraform solution that automatically fetches the RDS endpoint and uses it to construct the MySQL connection string in the user_data section of an EC2 instance.

### Solution

In your Terraform configuration, you can use the `templatefile` function to automatically generate the MySQL connection string with the RDS endpoint and other database credentials. Here's an example of how this can be achieved in Terraform:

```hcl
user_data = templatefile("user_data.tfpl", {
  rds_endpoint = aws_db_instance.rds.endpoint
  user = var.database_user
  password = var.database_password
  dbname = var.database_name
})
```

This code automatically fetches the RDS endpoint (`aws_db_instance.rds.endpoint`) and uses it to construct the MySQL connection string in the user_data section of your EC2 instance.

With this solution, you've automated the process of setting up the MySQL connection, ensuring that your EC2 instances can seamlessly connect to the RDS database without manual intervention. 🚀🔗🤖

## Tools & Technologies Covered in Our AWS Cloud Infrastructure Journey 🛠️🌐

1. **AWS Cloud ☁️**: Our foundation for this journey, the AWS Cloud, provides limitless possibilities for building and deploying applications.

2. **VPC 🏞️**: The Virtual Private Cloud gives us control over our network environment.

   - Subnets 🌐: These segments of the VPC help us organize and secure resources effectively.

   - Internet Gateway 🚪: The gateway to the internet, enabling external access and communication.

   - Route Tables 🚦: These are like roadmaps for network traffic within the VPC, ensuring data flows where it should.

   - Security Groups 🔒: Acting as virtual bouncers, security groups manage inbound and outbound traffic to keep our resources safe.

3. **EC2 Machine 💻**: Elastic Compute Cloud instances are like virtual Swiss Army knives, ready to handle various computing tasks.

4. **RDS Database - MySQL 🗄️**: Amazon RDS provides us with a managed MySQL database to store and manage our data securely.

5. **Mobaxterm SSH Client 🚀**: Mobaxterm gives us the keys to securely access and manage our EC2 instances using SSH.

6. **Terraform ⛏️**: This Infrastructure as Code tool automates the provisioning of cloud resources with elegance.

7. **Shell Script 🐚**: Good ol' shell scripts, our trusty sidekicks for automating tasks and configurations.

## Solution Diagram

![Solution Diagram](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/j51ys7fvw2dleljsaaby.png)

## Description

### Amazon Elastic Compute Cloud (Amazon EC2) ⚙️

Amazon Elastic Compute Cloud (Amazon EC2) provides on-demand, scalable computing capacity in the Amazon Web Services (AWS) Cloud ☁️. Using Amazon EC2 reduces hardware costs 💰, allowing you to develop and deploy applications faster ⏩. You can use Amazon EC2 to launch as many or as few virtual servers as you need, configure security 🔐 and networking 🌐, and manage storage 📂. You can add capacity (scale up) to handle compute-heavy tasks, such as monthly or yearly processes 📅, or spikes in website traffic 🚀. When usage decreases, you can reduce capacity (scale down) again ⬇️.

**Features of EC2:**

- Instances
- Amazon Machine Images (AMIs)
- Instance types
- Key pairs
- Instance store volumes
- Amazon EBS volumes
- Regions, Availability Zones, Local Zones, AWS Outposts, and Wavelength Zones
- Security groups
- Elastic IP addresses
- Tags
- Virtual private clouds (VPCs)

### AWS RDS - Relational Database Service 🦉

**What is Amazon RDS?**

Amazon Relational Database Service (Amazon RDS) is a web service that makes it easier to set up, operate, and scale a relational database in the AWS Cloud. It provides cost-efficient

, resizable capacity for an industry-standard relational database and manages common database administration tasks.

**DB instances**

A DB instance is an isolated database environment in the AWS Cloud. The basic building block of Amazon RDS is the DB instance.

**DB engines**

A DB engine is the specific relational database software that runs on your DB instance. Amazon RDS currently supports the following engines:

- MariaDB
- Microsoft SQL Server
- MySQL
- Oracle
- PostgreSQL

## Solution

The challenge of seamlessly integrating a web application with an RDS MySQL database and automating the deployment process demands an effective solution. This is where Terraform automation comes into play, providing a powerful toolset to address these challenges.

Using Terraform, we can define and provision the necessary infrastructure, including the RDS MySQL instance, security groups, and other components. This infrastructure is described in code, making it easy to manage, version, and replicate. By automating this process, we ensure that our RDS MySQL database and the associated resources are consistently deployed according to our specifications.

Terraform's automation capabilities further extend to the web application's deployment. We can define the deployment process as code, specifying how the application should be packaged, configured, and launched. This eliminates the need for manual intervention, reducing the risk of human errors and ensuring a more predictable and reliable deployment process.

By integrating our web application with the RDS MySQL database and automating the deployment with Terraform, we create a robust and efficient solution. This approach enables the web application to seamlessly connect with the database, allowing for data storage and retrieval. Moreover, the automation ensures that the entire process is repeatable and can be scaled as needed, making it a cost-effective and time-saving solution for real-time use cases.

In summary, Terraform automation solves the challenges of integrating a web application with an RDS MySQL database and streamlining the deployment process. It empowers us to efficiently manage our infrastructure and application deployments, ultimately resulting in a more agile and responsive system.

### Implementation Steps 🛠️

#### Phase 1: Setting the Stage 🏗️

To get started, we'll establish the groundwork for this automation project. We'll create the necessary Terraform files that define the infrastructure components, including `main.tf`, `variables.tf`, and `outputs.tf`. These files serve as the blueprints for our EC2 and RDS instances.

#### Phase 2: Preparing EC2 for Integration 🛠️

The first step towards complete automation is configuring the EC2 instance. We'll set up the server, ensuring it's ready to host Praful's Portfolio web application. This includes installing any required software and dependencies to support the dynamic web page.

#### Phase 3: RDS Database Creation 🗄️

The heart of this project is the AWS RDS MySQL database. We'll automate the process of creating the database, specifying the necessary parameters such as the database engine, version, and security settings. Terraform's power will shine as it orchestrates the creation of a robust and secure database environment.

#### Phase 4: Database-EC2 Integration 📊

This is where the magic happens. We'll automate the integration of the EC2 instance and the RDS MySQL database, ensuring they communicate seamlessly. Terraform will handle the network configurations, security groups, and database access permissions. This phase ensures that the web application can efficiently interact with the database.

#### Phase 5: Dynamic Web Page and Data Flow 💼

Praful's Portfolio web application features a dynamic employee (Emp) page. With this automation, we'll allow users to input employee details, such as name and location, directly on the web page. The data entered by users will be automatically saved into the RDS MySQL database, creating a smooth data flow from the web application to the database. This phase showcases the full potential of automation in keeping data up-to-date and synchronized.

### Pre-requisite

- AWS Free Tier
- Web Application source code
- Webserver installation script file
- SSH Client

### Terraform File Structure

![Terraform File Structure](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/15wztm86vx3jtg228qdt.png)

#### `user_data.tfpl`

![user_data.tfpl](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/twtwznxldzc3kti3hyso.png)

### Write all AWS services Terraform Configurations

- Configure VPC
- Configure Subnets
- Configure Internet Gateway
- Configure Security Group
- Configure Route Tables for webserver and RDS Db server
- Configure EC2 Machine with userdata script
- Configure RDS DB MySQL Server
- Configure AWS Provider

![Terraform Configurations](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/j7scrbuukrrhk41jumje.png)

#### `main.tf`

![main.tf](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/zdx6zthhj886a86yr8ji.png)

#### `variables.tf`

![variables.tf](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/e4647mx0hc0aikiosnea.png)

#### `outputs.tf`

![outputs.tf](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/5cx2wj8oje9k6oqzvnn0.png)

### Let's Automate the Infrastructure

```shell
terraform init
```

![terraform init](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/rr1gaf6xxo52f6lthfg6.png)

```shell
terraform fmt
terraform validate
```

![terraform fmt & validate](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/q8zmaywu6qmqs3d1juot.png)

```shell
terraform plan
```

![terraform plan](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/3hfj7gv838r6g4zf1pdj.png)

```shell
terraform apply -auto-approve
```

![terraform apply](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/hlvfolz0ulyy76g0zae6.png)

**Terraform Apply Complete**

![Terraform Apply Complete](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/opv9yz3eb7h2olmubfzn.png)

**Let's validate in the AWS console that the services are created.**

- VPC created

![VPC created](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/8vn8dcnmniatrhyqwlw5.png)

- EC2

 web server is running

![EC2 web server is running](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/hayd36qat5d93knqz7u8.png)

- RDS MySQL instances created

![RDS MySQL instances created](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/8vvkzi9n8t8g15m6pk7f.png)

**Let's copy the IP address in the browser to access the web application**

**Web application accessed successfully**

![Web application accessed successfully](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/r3ha502kmd5i17m25pf3.png)

**Access `emp.php` page**

![Access `emp.php` page](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/i8n8gh5o5qe00cvt00w8.png)

**Insert some test data into the web app and validate that it is inserted successfully**

![Insert test data](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/6efezolyqfkyuc0t9sdc.png)

**Let's login to the RDS MySQL database and validate from the backend that data is present in the database**

**Login to MySQL through the web server as a jump host**

**Copy the RDS endpoint**

![Copy the RDS endpoint](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/iqagfpdr3zqxvmv58ukn.png)

**RDS Endpoint:**

```
terraform-20231025010716744900000001.c5xf4htadaog.us-east-1.rds.amazonaws.com
```

**Connect to the EC2 server**

![Connect to EC2](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ktx7gudkx8qz9w38s4zj.png)

**Provide MySQL connection string to log in**

```shell
mysql -h <rdsendpoint> -u <username> -p
```

![Provide MySQL connection string](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/u2czy5fx064657c1yijl.png)

**Login successfully to MySQL**

![Login successfully to MySQL](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/l9jhpcomywkmrwp9mxia.png)

**Verify that "empdb" database is created and exists in the database**

```sql
show databases;
```

![Show databases](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/5a2hlb6b6rumdo5ptjrl.png)

```sql
use empdb;
```

![Use empdb](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/4o82ut1bd5p5k3wfajil.png)

**Verify that "EMPLOYEE" table exists in the database**

```sql
show tables;
```

![Show tables](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/hhehm2c88kas0luxbty0.png)

**Query table "Employees" to validate that data entered from the web app exists in the database**

```sql
select * from EMPLOYEES;
```

![Query table "Employees"](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/3nawmcohl3eneygfshki.png)

![Query table "Employees"](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/dloustp9qllt9lycx2zd.png)

![Query table "Employees"](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/7w7fov0q5ivsc9keizr9.png)

**Congratulations: we have done it.**

Now, let's destroy all the resources from AWS to avoid unnecessary billing.

```shell
terraform destroy -auto-approve
```

![Terraform destroy](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/vfug6v2lfenr956hcai6.png)

![Terraform destroy](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/bhwfvrjg3p6xl85lk55i.png)

## Conclusion

This automation project demonstrates the power of Terraform in streamlining complex infrastructure setups. By integrating Praful's Portfolio web application with an AWS RDS MySQL database, we've created a dynamic and efficient data management system. This blog post serves as your guide through this exciting journey, providing insights and expertise to help you master automation in the AWS cloud.

Get ready to explore the beauty of complete automation as we dive into the integration of EC2 and AWS RDS! 🔗✨

Happy automating! 🚀
