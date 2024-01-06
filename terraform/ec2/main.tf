# EC2
# AMIをまとめて設定
data "aws_ami" "latest_windows" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "windows-2022-ec2"
    values = ["Windows_Server-2022-Japanese-Full-Base-*"]
  }
}

resource "aws_instance" "main" {
  ami           = data.aws_ami.latest_windows.id
  instance_type = "t2.xlarge"

  # インスタンスプロファイルの指定
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  subnet_id              = var.private_subnet_1a_id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  key_name = aws_key_pair.key_pair.id

  # EBS最適化を有効
  ebs_optimized = "true"

  # EBSのルートボリューム設定
  root_block_device {
    # ボリュームサイズ(GiB)
    volume_size = 300
    # ボリュームタイプ
    volume_type = "st1"
    # EC2終了時に削除
    delete_on_termination = true # 変更確認

    # EBSのNameタグ
    tags = {
      Name = "${var.name}-ebs-hdd"
    }
  }

  tags = {
    Name = "${var.name}-ec2"
  }

  # lifecycle { # lifecycle blockを追加
  #   prevent_destroy = true
  # }
}

# ELB Target Group
# https://www.terraform.io/docs/providers/aws/r/lb_target_group.html
resource "aws_lb_target_group" "main" {
  name = "${var.name}-target-group"

  # ターゲットグループを作成するVPC
  vpc_id = var.vpc_id

  # ALBからECSタスクのコンテナへトラフィックを振り分ける設定
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
}

# ALB Listener Rule
# https://www.terraform.io/docs/providers/aws/r/lb_listener_rule.html
resource "aws_lb_listener_rule" "main" {
  # ルールを追加するリスナー
  listener_arn = var.alb_listener_arn
  priority     = 100

  # 受け取ったトラフィックをターゲットグループへ受け渡す
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.id
  }

  # ターゲットグループへ受け渡すトラフィックの条件
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

# EC2にアタッチする用のキーペア作成
resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.keygen.public_key_openssh
}

# SecurityGroup
# https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group" "ec2" {
  name        = "${var.name}-ec2-sg"
  description = "${var.name} ec2 sg"

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
    Name = "${var.name}-ec2-sg"
  }
}

# SecurityGroup Rule
# https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group_rule" "ec2_inbound_http" {
  security_group_id = aws_security_group.ec2.id

  # インターネットからセキュリティグループ内のリソースへのアクセス許可設定
  type = "ingress"

  # TCPでの80ポートへのアクセスを許可する
  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  # 同一VPC内からのアクセスのみ許可
  cidr_blocks = ["10.1.0.0/16"] # ハードコード
}

# resource "aws_security_group_rule" "ec2_inbound_https" {
#   security_group_id = aws_security_group.ec2.id

#   # インターネットからセキュリティグループ内のリソースへのアクセス許可設定
#   type = "ingress"

#   from_port = 443
#   to_port   = 443
#   protocol  = "tcp"

#   # 同一VPC内からのアクセスのみ許可
#   cidr_blocks = ["10.1.0.0/16"] # ハードコード
# }

# resource "aws_security_group_rule" "ec2_inbound_rdp" {
#   security_group_id = aws_security_group.ec2.id

#   # インターネットからセキュリティグループ内のリソースへのアクセス許可設定
#   type = "ingress"

#   # TCPでの3389ポートへのアクセスを許可する
#   from_port = 3389
#   to_port   = 3389
#   protocol  = "tcp"

#   # 同一VPC内からのアクセスのみ許可
#   cidr_blocks = ["0.0.0.0/0"] # 後ほど編集すべき
# }
