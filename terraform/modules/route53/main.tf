module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 3.0"

  zone_name = "linasm.click"

  records = [

    {
      name = "db"
      type = "CNAME"
      ttl  = 3600
      records = [
        var.db_db_instance_endpoint,
      ]
    },
  ]

  #  depends_on = [module.zones]
}
