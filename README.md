# VPC Creation Using Terraform

[![Build Status](https://travis-ci.org/joemccann/dillinger.svg?branch=master)](https://travis-ci.org/joemccann/dillinger)

Here is a project that met the requirement which is for the creation of VPC in a completely automated way. VPC creation includes 3 public subnets and 3 private subnets configured via NAT. Here it is configured in 3 AZ for each of the subnets, moreover, the Availability zones are automatically fetched via the data source. This makes the complex VPC creation much simpler and in lesser time.

## Resources Created 

- 3 Public Subnet
- 3 Private Subnet
- Internet Gateway
- 2 Route Tables (Private and Public)
- 1 Elastic IP
- NAT Gateway

## Features

- Fully Automated creation of VPC 
- It can be deployed in any region and will be fetching the available zones in that region automatically using data source AZ. 
- Public and private subnets will be deployed in each AZ in an automated way.
- Every subnet CIDR block has been calculated automatically using cidrsubnet function
- Whole project can be managed from a single file (terraform.tfvars) which means selecting the region, changing the whole project name, selecting VPC, and subnetting.

## Prerequisites

- Knowledge in AWS services, especially VPC, subnetting
- IAM user with necessary privileges. 

## Terraform Code Explanation 

- Initially created the variable file for the project which includes the following - region for the creation, access key, secret key, VPC CIDR, subnet, and the name for the whole project creation. The varaibles are declared in the variables.tf and vlaues for the same in terraform.tfvars

Here is the variable.tf file with the list of variables for the creation of VPC

```sh
variable "region"     {}

variable "access_key" {}

variable "secret_key" {}

variable "vpc_cidr"   {}

variable "project"    {}

variable "subnetcidr" {}
```

And for the above-mentioned variables, values are provided in the below-mentioned file terraform.tfvars, Here I have provided the VPC CIDR as 172.16.0.0/16 and subnetcidr as 3 for my project, for the creation of a total of 6 subnets (3 - public and private). According to the requirements, you can update the same.

```sh
region      = "us-east-1"

access_key  = "Mention-Your-Access-Key"

secret_key  = "Mention-Your-Secret-Key"

vpc_cidr    = "172.16.0.0/16"

project     = "example"

subnetcidr  = "3"
```

- Next proceeds with the creation of the provider file with passing  variables from "variables.tf" and the file name here is that provider.tf

```sh
provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}
```

Further moves forward with the creation of the VPC and configurations. Initially proceeds with the creation of VPC

- VPC Creation

 ```sh
resource "aws_vpc" "main" {
  cidr_block            = var.vpc_cidr
  instance_tenancy      = "default"
  enable_dns_support    = "true"
  enable_dns_hostnames  = "true"

  tags                  = {
    Name                = "${var.project}-vpc"
  }
}
 ```
 
 Next proceeds with the creation of Internet Gateway for the VPC.
 
 - Internet GateWay

```sh
resource "aws_internet_gateway" "igw" {
  vpc_id    = aws_vpc.main.id

  tags      = {
    Name    = "${var.project}-igw"
  }
}
```

In the subnet part as mentioned above, here I have configured 3 public Subnet and 3 private Subnet

- Public Subnet -1

```sh
resource "aws_subnet" "public1" {
  vpc_id                            = aws_vpc.main.id
  cidr_block                        = cidrsubnet(var.vpc_cidr,var.subnetcidr,0)
  availability_zone                 = data.aws_availability_zones.az.names[0]
  map_public_ip_on_launch           = true 
  tags                              = {
    Name                            = "${var.project}-public1"
  }
}
```

- Public Subnet -2

```sh
resource "aws_subnet" "public2" {
  vpc_id                            = aws_vpc.main.id
  cidr_block                        = cidrsubnet(var.vpc_cidr,var.subnetcidr,1)
  availability_zone                 = data.aws_availability_zones.az.names[1]
  map_public_ip_on_launch           = true 
  tags                              = {
    Name                            = "${var.project}-public2"
  }
}
```

- Public Subnet -3

```sh
resource "aws_subnet" "public3" {
  vpc_id                            = aws_vpc.main.id
  cidr_block                        = cidrsubnet(var.vpc_cidr,var.subnetcidr,2)
  availability_zone                 = data.aws_availability_zones.az.names[2]
  map_public_ip_on_launch           = true 
  tags                              = {
    Name                            = "${var.project}-public2"
  }
}
```

- Private Subnet -1

```sh
resource "aws_subnet" "private1" {
  vpc_id                            = aws_vpc.main.id
  cidr_block                        = cidrsubnet(var.vpc_cidr,var.subnetcidr,0)
  availability_zone                 = data.aws_availability_zones.az.names[0]
  tags                              = {
    Name                            = "${var.project}-private1"
  }
}
```

- Private Subnet -2 

```sh
resource "aws_subnet" "private2" {
  vpc_id                            = aws_vpc.main.id
  cidr_block                        = cidrsubnet(var.vpc_cidr,var.subnetcidr,1)
  availability_zone                 = data.aws_availability_zones.az.names[1]
  tags                              = {
    Name                            = "${var.project}-private2"
  }
}
```

- Private Subnet -3

```sh
resource "aws_subnet" "private3" {
  vpc_id                            = aws_vpc.main.id
  cidr_block                        = cidrsubnet(var.vpc_cidr,var.subnetcidr,2)
  availability_zone                 = data.aws_availability_zones.az.names[2]
  tags                              = {
    Name                            = "${var.project}-private3"
  }
}
```

After the subnet creation, it needs to be routed. For the same creates the route table and the association. 

- Route Table - Public

```sh
resource "aws_route_table" "route-public" {
  vpc_id            = aws_vpc.main.id
  route {
      cidr_block    = "0.0.0.0/0"
      gateway_id    = aws_internet_gateway.igw.id
  }
  tags = {
      Name          = "${var.project}-public"
  }
  }
```

- Public Route table Association

```sh
  resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.route-public.id
}

  resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.route-public.id
}

  resource "aws_route_table_association" "public3" {
  subnet_id      = aws_subnet.public3.id
  route_table_id = aws_route_table.route-public.id
}
```
For configuring the private route table, Elastic IP and NAT gateway are required. Initailly cretaing the same.

- Elastic IP For NAT GateWay

```sh
resource "aws_eip" "ip" {
  vpc           = true
  tags          = {
      Name      = "${var.project}-eip"
  }
}
```

- NAT Gateway

```sh
resource "aws_nat_gateway" "nat" {

  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public3.id

  tags = {
    Name = "${var.project}-nat"
  }
}
```

- Private Route Table

```sh
resource "aws_route_table" "route-private" {
  vpc_id            = aws_vpc.main.id
  route {
      cidr_block    = "0.0.0.0/0"
      gateway_id    = aws_nat_gateway.nat.id
  }
  tags = {
      Name          = "${var.project}-private"
  }
  }
```

- Private Route Table Association

```sh
 resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.route-private.id
   }
   resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.route-private.id
   }
   resource "aws_route_table_association" "private3" {
  subnet_id      = aws_subnet.private3.id
  route_table_id = aws_route_table.route-private.id
   }
```

Currently, the whole creation part completes, and here I have configured an output file (output.tf) to list out the created resource details. 

```sh
output "vpc" {
  value = aws_vpc.my_vpc.id
}

output "IGW" {
  value = aws_internet_gateway.igw.id
}

output "Route_Public" {
  value = aws_route_table.route-public.id
}

output "EIP" {
  value = aws_eip.ip.id
}

output "NAT" {
  value = aws_nat_gateway.nat.id
}

output "Route_Private" {
  value = aws_route_table.route-private.id
}
```

## User Instructions 

### Terraform Installation 

-  Clone the git repo and proceeds with the installation of the terraform first.  Here the installation script is provided for Linux OS. Change the permission of the script - install.sh to executable and execute the bash script for the installation. The bash script will be downloading the terraform from the official terraform website. Further unzipping and copying it to the /usr/bin directory. It will list out the installed version and will remove the downloaded zip files after the installation. The output is shown below.

![
alt_txt
](https://i.ibb.co/QbB5dfF/install.jpg)

-  For Manual Proccedure 
    -  For Downloading -  [Terraform](https://www.terraform.io/downloads.html) 
    -  Installation Steps -  [Installation](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started)

#### User Customization 

-  Here for the user customization can be done in a single file. It means they need to update variables in a file named "terraform.tfvars". Which includes all the details for the VPC creation as mentioned earlier. 
-  
```sh
region      = "Mention-Your_region"

access_key  = "Mention-Your-Access-Key"

secret_key  = "Mention-Your-Secret-Key"

vpc_cidr    = "Mention-Your-CIDR-For-VPC"

project     = "Mention-Your-Project-Name"

subnetcidr  = "3"
```
- The last 4 commands to complete the architecture build are given below. 

- After completing these,  initialize the working directory for Terraform configuration using the below command

```sh
terraform init
```
- Validate the terraform file using the command given below.

```sh
 terraform validate
```
- After successful validation, plan the build architecture and confirm the changes

```sh
 terraform plan
```
- Apply the changes to the AWS architecture

```sh
 terraform apply
```

## Conclusion

Here I have built an architecture for the VPC using the terraform as IaC, which makes the whole process automates. At the same time easy to customize, as customization is required only in a single file.
