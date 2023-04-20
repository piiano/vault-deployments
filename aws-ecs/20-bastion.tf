data "aws_ami" "amazon_linux_2" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  owners = ["amazon"]
}

resource "aws_security_group" "bastion" {
  count  = var.create_bastion ? 1 : 0
  name   = "${var.deployment_id}-bastion-sg"
  vpc_id = local.vpc_id

  egress {
    description = "Allow All 443 Egress for SSM Access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow Internal 80 Egress pvault access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.allowed_cidr_blocks
  }

  tags = {
    "Name" = "${var.deployment_id}_bastion_sg"
  }
}

resource "aws_iam_role" "bastion" {
  count = var.create_bastion ? 1 : 0
  name  = "${var.deployment_id}-bastion-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion" {
  count      = var.create_bastion ? 1 : 0
  role       = one(aws_iam_role.bastion).name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  count = var.create_bastion ? 1 : 0
  name  = "${var.deployment_id}-bastion-iam-profile"
  role  = one(aws_iam_role.bastion).name
}

resource "aws_instance" "bastion" {
  count                       = var.create_bastion ? 1 : 0
  ami                         = data.aws_ami.amazon_linux_2.id
  subnet_id                   = local.private_subnet_ids[0]
  instance_type               = "t3.small"
  vpc_security_group_ids      = [one(aws_security_group.bastion).id]
  iam_instance_profile        = one(aws_iam_instance_profile.bastion).name
  user_data                   = templatefile("${path.module}/20-bastion.userdata.sh", {})
  user_data_replace_on_change = true
  tags = {
    Name = "${var.deployment_id}-bastion-instance"
    Role = "bastion"
  }
}
