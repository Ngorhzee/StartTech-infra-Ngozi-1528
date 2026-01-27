module "networking" {
  source = "./modules/networking"


}

module "compute" {
  source = "./modules/compute"

  vpc_id          = module.networking.vpc_id
  public_subnets  = module.networking.public_subnets
  private_subnets = module.networking.private_subnets
  aws_region      = var.aws_region
  project_name    = var.project_name
  mongo_uri       = var.mongo_uri
  db_name         = var.db_name
  jwt_secret      = var.jwt_secret
}

module "storage" {
  source = "./modules/storage"


}

module "monitoring" {
  source                  = "./modules/monitoring"
  project_name            = var.project_name
  asg_name                = module.compute.asg_name
  alb_arn_suffix          = module.compute.alb_arn_suffix
  target_group_arn_suffix = module.compute.target_group_arn_suffix
  aws_region              = var.aws_region

}








