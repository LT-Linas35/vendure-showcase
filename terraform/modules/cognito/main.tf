resource "aws_cognito_user_pool" "main" {
  name = "vendure-infra-admins"

  username_attributes = ["email"]
  auto_verified_attributes = ["email"]

  mfa_configuration = "OFF"
  password_policy {
    minimum_length    = 8
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
    require_lowercase = true
  }
}

resource "aws_cognito_user_pool_client" "jenkins" {
  name         = "jenkins-app"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret             = true
  allowed_oauth_flows         = ["code"]
  allowed_oauth_scopes        = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true

  callback_urls = ["https://jenkins.linasm.click/securityRealm/finishLogin"]
  logout_urls   = ["https://jenkins.linasm.click/OicLogout"]
  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_user_pool_client" "argocd" {
  name         = "argocd-app"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret             = true
  allowed_oauth_flows         = ["code"]
  allowed_oauth_scopes        = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true

  callback_urls = ["https://argocd.linasm.click/auth/callback"]
  logout_urls   = ["https://argocd.linasm.click"]
  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "vendure-infra-admins"
  user_pool_id = aws_cognito_user_pool.main.id
}


resource "aws_cognito_user" "example_user" {
  username     = "lincasm@gmail.com"
  user_pool_id = aws_cognito_user_pool.main.id
  temporary_password = "Labas123!"
  force_alias_creation = false

  attributes = {
    email          = "lincasm@gmail.com"
    email_verified = "true"
  }

  lifecycle {
    ignore_changes = [temporary_password] # kad netrigerintų pakeitimų vėliau
  }
}
