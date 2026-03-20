provider "aws" {
  region = "us-east-1"
}

# ----------------------
# VPC
# ----------------------
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "trend-vpc"
  }
}

# ----------------------
# Public Subnet
# ----------------------
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "trend-public-subnet"
  }
}

# ----------------------
# Internet Gateway
# ----------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "trend-igw"
  }
}

# ----------------------
# Route Table
# ----------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "trend-public-rt"
  }
}

# ----------------------
# Route Table Association
# ----------------------
resource "aws_route_table_association" "rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ----------------------
# Security Group
# ----------------------
resource "aws_security_group" "web_sg" {
  name        = "trend-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App Port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP (optional)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ----------------------
# IAM Role for EC2
# ----------------------
resource "aws_iam_role" "ec2_role" {
  name = "trend-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach policies (EKS + basic access)
resource "aws_iam_role_policy_attachment" "ec2_policy1" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_policy2" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_policy3" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "trend-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# ----------------------
# EC2 Instance
# ----------------------
resource "aws_instance" "jenkins_server" {
  ami           = "ami-0ec10929233384c7f"
  instance_type = "m7i-flex.large"
  subnet_id     = aws_subnet.public_subnet.id

  key_name = "aws-n.virginia-kp1"

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  associate_public_ip_address = true

  tags = {
    Name = "trend-jenkins-server"
  }
}
