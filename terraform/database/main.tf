# RDS

# SecurityGroup
# https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "${var.name} rds sg"

  # セキュリティグループを配置するVPC
  vpc_id = var.vpc_id

  # セキュリティグループ内のリソースからインターネットへのアクセス許可設定
  # 今回の場合DockerHubへのPullに使用する。
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-rds-sg"
  }
}

# SecurityGroup Rule
# https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group_rule" "rds" {
  security_group_id = aws_security_group.rds.id

  # インターネットからセキュリティグループ内のリソースへのアクセス許可設定
  type = "ingress"

  from_port = 3306
  to_port   = 3306
  protocol  = "tcp"

  # 同一VPC内からのアクセスのみ許可
  cidr_blocks = ["10.1.0.0/16"] # ハードコード
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
resource "aws_db_instance" "rds" {
  allocated_storage     = 50 # 可変
  max_allocated_storage = 100
  apply_immediately     = true
  storage_type          = "gp2"         # 可変
  engine                = "mysql"       # 可変
  engine_version        = "8.0.33"      # 可変
  instance_class        = "db.t2.micro" # 可変
  identifier            = "${var.name}-rds-db"
  username              = "admin"
  password              = "YxUv9WxcuFPP" # 参考
  skip_final_snapshot   = true
  # storage_encrypted      = true
  deletion_protection    = false
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name

  depends_on = [
    aws_db_subnet_group.db_subnet_group
  ]
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "${var.name}-db-subnet-group"
  description = "${var.name} db subnet group"

  subnet_ids = var.private_subnet_ids
  tags       = {}

  tags_all = {}
}
