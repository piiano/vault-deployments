# module "client_vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "3.19.0"

#   name             = "client-vpc"
#   cidr             = "10.1.0.0/16"
#   azs              = slice(data.aws_availability_zones.available.names, 0, 2)
#   public_subnets   = ["10.1.1.0/24", "10.1.2.0/24"]
#   private_subnets  = ["10.1.11.0/24", "10.1.12.0/24"]
#   database_subnets = ["10.1.21.0/24", "10.1.22.0/24"]

#   create_database_subnet_group = true
#   enable_nat_gateway           = true
#   single_nat_gateway           = true
#   enable_dns_hostnames         = true
# }

# resource "aws_security_group" "client_bastion" {
#   name   = "client-bastion-sg"
#   vpc_id = module.client_vpc.vpc_id

#   egress {
#     description = "Allow All 443 Egress"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     "Name" = "bastion2_sg"
#   }
# }

# resource "aws_instance" "client_bastion" {
#   count                       = var.create_client_bastion ? 1 : 0
#   ami                         = data.aws_ami.amazon_linux_2.id
#   subnet_id                   = module.client_vpc.private_subnets[0]
#   instance_type               = "t3.small"
#   vpc_security_group_ids      = [aws_security_group.client_bastion.id]
#   iam_instance_profile        = aws_iam_instance_profile.bastion.name
#   user_data                   = templatefile("${path.module}/bastion.userdata.sh", {})
#   user_data_replace_on_change = true
#   tags = {
#     Name = "client-bastion-instance"
#   }
# }


# # Peering and routing 
# resource "aws_vpc_peering_connection" "client_to_vault" {
#   vpc_id      = module.client_vpc.vpc_id
#   peer_vpc_id = module.vpc.vpc_id
#   auto_accept = true
#   tags = {
#     "Name" = "client_to_vault"
#   }
# }

# resource "aws_route" "vault_to_client" {
#   route_table_id            = module.vpc.private_route_table_ids[0]
#   destination_cidr_block    = module.client_vpc.vpc_cidr_block
#   vpc_peering_connection_id = aws_vpc_peering_connection.client_to_vault.id
# }

# resource "aws_route" "client_to_vault" {
#   route_table_id            = module.client_vpc.private_route_table_ids[0]
#   destination_cidr_block    = module.vpc.vpc_cidr_block
#   vpc_peering_connection_id = aws_vpc_peering_connection.client_to_vault.id
# }

