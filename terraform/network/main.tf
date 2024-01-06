# VPC
# https://www.terraform.io/docs/providers/aws/r/vpc.html
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = "true" # VPC内でDNSによる名前解決を有効化するかを指定
  enable_dns_hostnames = "true" # VPC内インスタンスがDNSホスト名を取得するかを指定

  tags = {
    Name = "${var.name}-vpc"
  }
}

# Subnet
# https://www.terraform.io/docs/providers/aws/r/subnet.html
resource "aws_subnet" "public_1a" {
  # 先程作成したVPCを参照し、そのVPC内にSubnetを立てる
  vpc_id = aws_vpc.main.id

  # Subnetを作成するAZ
  availability_zone = "ap-northeast-1a"

  cidr_block = var.vpc_cidr_block_public_1a

  tags = {
    Name = "${var.name}-public-1a"
  }
}

resource "aws_subnet" "public_dummy" {
  # 先程作成したVPCを参照し、そのVPC内にSubnetを立てる
  vpc_id = aws_vpc.main.id

  # Subnetを作成するAZ
  availability_zone = "ap-northeast-1c"

  cidr_block = var.vpc_cidr_block_public_dummy

  tags = {
    Name = "${var.name}-public-dummy"
  }
}

# Private Subnets
resource "aws_subnet" "private_1a" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1a"
  cidr_block        = var.vpc_cidr_block_private_1a

  tags = {
    Name = "${var.name}-private-1a"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1c"
  cidr_block        = var.vpc_cidr_block_private_1c

  tags = {
    Name = "${var.name}-private-1c"
  }
}

# Internet Gateway
# https://www.terraform.io/docs/providers/aws/r/internet_gateway.html
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-internet-gateway"
  }
}

# Elastic IP
# https://www.terraform.io/docs/providers/aws/r/eip.html
resource "aws_eip" "nat_1a" {
  domain = "vpc"

  tags = {
    Name = "${var.name}-eip-1a"
  }
}

# NAT Gateway
# https://www.terraform.io/docs/providers/aws/r/nat_gateway.html
resource "aws_nat_gateway" "nat_1a" {
  subnet_id     = aws_subnet.public_1a.id # NAT Gatewayを配置するSubnetを指定
  allocation_id = aws_eip.nat_1a.id       # 紐付けるElasti IP

  tags = {
    Name = "${var.name}-natgw-1a"
  }
}

# Route Table
# https://www.terraform.io/docs/providers/aws/r/route_table.html
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-public-route-table"
  }
}

# Route
# https://www.terraform.io/docs/providers/aws/r/route.html
resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
}

# Association
# https://www.terraform.io/docs/providers/aws/r/route_table_association.html
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_dummy" {
  subnet_id      = aws_subnet.public_dummy.id
  route_table_id = aws_route_table.public.id
}

# Route Table (Private)
# https://www.terraform.io/docs/providers/aws/r/route_table.html
resource "aws_route_table" "private_1a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-private-1a-route-table"
  }
}

resource "aws_route_table" "private_1c" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-private-1c-route-table"
  }
}

# Route (Private)
# https://www.terraform.io/docs/providers/aws/r/route.html
resource "aws_route" "private_1a" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1a.id
  nat_gateway_id         = aws_nat_gateway.nat_1a.id
}

resource "aws_route" "private_1c" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1c.id
  nat_gateway_id         = aws_nat_gateway.nat_1a.id
}

# Association (Private)
# https://www.terraform.io/docs/providers/aws/r/route_table_association.html
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_1a.id
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private_1c.id
}

# Endpoint
# https://dev.classmethod.jp/articles/ec2-instance-connect-endpoint-by-terraform/
# https://qiita.com/TaishiOikawa/items/2690c1c5c8c00685fd01
resource "aws_vpc_endpoint" "private_ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_1a.id]           # 必須
  security_group_ids  = [aws_security_group.vpc_endpoint.id] # オブション
  depends_on          = [aws_vpc.main, aws_subnet.private_1a]

  tags = { # オブション
    Name = "${var.name}-ssm-endpoint"
  }
}

resource "aws_vpc_endpoint" "private_ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_1a.id]           # 必須
  security_group_ids  = [aws_security_group.vpc_endpoint.id] # オブション
  depends_on          = [aws_vpc.main, aws_subnet.private_1a]

  tags = { # オブション
    Name = "${var.name}-ssmmessages-endpoint"
  }
}

resource "aws_vpc_endpoint" "private_ec2" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_1a.id]           # 必須
  security_group_ids  = [aws_security_group.vpc_endpoint.id] # オブション
  depends_on          = [aws_vpc.main, aws_subnet.private_1a]

  tags = { # オブション
    Name = "${var.name}-ec2-endpoint"
  }
}

resource "aws_vpc_endpoint" "private_ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_1a.id]           # 必須
  security_group_ids  = [aws_security_group.vpc_endpoint.id] # オブション
  depends_on          = [aws_vpc.main, aws_subnet.private_1a]

  tags = { # オブション
    Name = "${var.name}-ec2messages-endpoint"
  }
}

# SecurityGroup
resource "aws_security_group" "vpc_endpoint" {
  name        = "${var.name}-endpoint-sg"
  description = "${var.name} endpoint sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"] # ハードコード
  }

  tags = {
    Name = "${var.name}-endpoint-sg"
  }
}
