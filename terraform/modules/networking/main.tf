module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~>6.0"
  name = "main"
  cidr = "10.0.0.0/16"
  azs = ["eu-west-1a", "eu-west-1b",]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24",]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24",]

  map_public_ip_on_launch = true
  enable_nat_gateway = true
  
  enable_vpn_gateway = false

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
