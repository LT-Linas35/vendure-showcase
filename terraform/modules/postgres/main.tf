module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "vendure"

  engine            = "postgres"
  engine_version    = "17.4"
  instance_class    = "db.t4g.micro"
  allocated_storage = 5

  db_name  = "vendure"
  username = "superadmin"
  password = "superadmin"
  port     = "5432"

  multi_az            = var.env == "prod" ? true : false
  skip_final_snapshot = var.env == "dev" ? true : false


  iam_database_authentication_enabled = true

  vpc_security_group_ids = [var.vpc_default_security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # Enhanced Monitoring - see example for details on how to create the role
  # by yourself, in case you don't want to create it automatically
  monitoring_interval    = "30"
  monitoring_role_name   = "MyRDSMonitoringRole"
  create_monitoring_role = true

  tags = {
    Terraform   = "true"
    Environment = var.env
  }

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids = slice(var.vpc_database_subnets,0,min(length(var.vpc_database_subnets), var.env == "prod" ? 3 : 2))

  # DB parameter group
  family = "postgres17"

  # DB option group
  major_engine_version = "17"

  # Database Deletion Protection
  deletion_protection = var.env == "prod" ? true : false



}
