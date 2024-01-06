terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.29.0"
    }
  }

  backend "local" {}
}

provider "aws" {
  profile                  = "fogefoge"
  region                   = "ap-northeast-1"
  shared_credentials_files = ["~/.aws/credentials"]
}

module "network" {
  source = "./network"

  name                        = local.name
  vpc_cidr_block              = local.vpc_cidr_block
  vpc_cidr_block_public_1a    = local.vpc_cidr_block_public_1a
  vpc_cidr_block_public_dummy = local.vpc_cidr_block_public_dummy
  vpc_cidr_block_private_1a   = local.vpc_cidr_block_private_1a
  vpc_cidr_block_private_1c   = local.vpc_cidr_block_private_1c
}

module "alb" {
  source = "./alb"

  name              = local.name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
}

module "ec2" {
  source = "./ec2"

  name                 = local.name
  key_name             = local.key_name
  vpc_id               = module.network.vpc_id
  alb_listener_arn     = module.alb.alb_listener_arn
  private_subnet_1a_id = module.network.private_subnet_1a_id
}

module "database" {
  source = "./database"

  name               = local.name
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
}

module "waf" {
  source = "./waf"

  name         = local.name
  alb_main_arn = module.alb.alb_main_arn
}

module "cognito" {
  source = "./cognito"

  name = local.name
}
