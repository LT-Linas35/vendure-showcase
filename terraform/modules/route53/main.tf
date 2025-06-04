/*
resource "aws_route53_zone" "dev" {
  name = "vendure.linasm.click"

  tags = {
    Environment = "dev"
  }
}
*/

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 3.0"


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
}
