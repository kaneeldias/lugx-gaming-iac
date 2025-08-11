provider "aws" {
  region = "eu-west-1"
}

resource "aws_vpc" "lugx_gaming_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Project = "lugx-gaming"
    Name = "eks-vpc"
  }
}

resource "aws_subnet" "lugx_gaming_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.lugx_gaming_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.lugx_gaming_vpc.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    "kubernetes.io/cluster/lugx-gaming-cluster" = "shared"
    "kubernetes.io/role/elb" = "1"

    Project = "lugx-gaming"
    Name = "lugx-gaming-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "lugx_gaming_igw" {
  vpc_id = aws_vpc.lugx_gaming_vpc.id

  tags = {
    Project = "lugx-gaming"
    Name    = "lugx-gaming-igw"
  }
}

resource "aws_eip" "lugx_gaming_nat_eip" {
  tags = {
    Project = "lugx-gaming"
    Name    = "lugx-gaming-nat-eip"
  }
}

resource "aws_nat_gateway" "lugx_gaming_nat_gw" {
  allocation_id = aws_eip.lugx_gaming_nat_eip.id
  subnet_id     = aws_subnet.lugx_gaming_subnet[0].id

  tags = {
    Project = "lugx-gaming"
    Name    = "lugx-gaming-nat-gw"
  }
}

resource "aws_route_table" "lugx_gaming_public_rt" {
  vpc_id = aws_vpc.lugx_gaming_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lugx_gaming_igw.id
  }

  tags = {
    Project = "lugx-gaming"
    Name    = "lugx-gaming-public-rt"
  }
}

resource "aws_route_table_association" "lugx_gaming_public_rta" {
  count          = 1
  subnet_id      = aws_subnet.lugx_gaming_subnet[count.index].id
  route_table_id = aws_route_table.lugx_gaming_public_rt.id
}

resource "aws_route_table" "lugx_gaming_private_rt" {
  vpc_id = aws_vpc.lugx_gaming_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lugx_gaming_nat_gw.id
  }

  tags = {
    Project = "lugx-gaming"
    Name    = "lugx-gaming-private-rt"
  }
}

resource "aws_route_table_association" "lugx_gaming_private_rta" {
  count          = 1
  subnet_id      = aws_subnet.lugx_gaming_subnet[count.index + 1].id
  route_table_id = aws_route_table.lugx_gaming_private_rt.id
}

data "aws_availability_zones" "available" {}

resource "aws_eks_cluster" "lugx_gaming_cluster" {
  name     = "lugx-gaming-cluster"
  role_arn = aws_iam_role.lugx_gaming_cluster_role.arn

  vpc_config {
    subnet_ids = aws_subnet.lugx_gaming_subnet[*].id
  }

  depends_on = [aws_iam_role_policy_attachment.lugx_gaming_cluster_policy]

  tags = {
    Project = "lugx-gaming"
    Name = "lugx-gaming-cluster"
  }
}

resource "aws_iam_role" "lugx_gaming_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = "lugx-gaming"
    Name = "lugx-gaming-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "lugx_gaming_cluster_policy" {
  role       = aws_iam_role.lugx_gaming_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.lugx_gaming_cluster.name
  node_group_name = "lugx-gaming-node-group"
  node_role_arn   = aws_iam_role.lugx_gaming_node_role.arn
  subnet_ids      = aws_subnet.lugx_gaming_subnet[*].id

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }

  depends_on = [aws_iam_role_policy_attachment.lugx_gaming_worker_node_policy]

  tags = {
    Project = "lugx-gaming"
    Name = "lugx-gaming-cluster-node-group"
  }
}

resource "aws_iam_role" "lugx_gaming_node_role" {
  name = "lugx-gaming-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = "lugx-gaming"
    Name = "lugx-gaming-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "lugx_gaming_worker_node_policy" {
  role       = aws_iam_role.lugx_gaming_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "lugx_gaming_ecr_policy" {
  role       = aws_iam_role.lugx_gaming_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "lugx_gaming_cni_policy" {
  role       = aws_iam_role.lugx_gaming_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_policy" "lugx_gaming_describe_instances_policy" {
  name        = "lugx-gaming-describe-instances-policy"
  description = "Policy to allow ec2:DescribeInstances for node role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ec2:DescribeInstances"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lugx_gaming_describe_instances_policy" {
  role       = aws_iam_role.lugx_gaming_node_role.name
  policy_arn = aws_iam_policy.lugx_gaming_describe_instances_policy.arn
}

