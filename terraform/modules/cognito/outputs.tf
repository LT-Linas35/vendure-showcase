##############################################################################

output "jenkins_cognito_cliend_id" {
  value = aws_cognito_user_pool_client.jenkins.id
  sensitive   = true
}

output "jenkins_cognito_secret" {
  value = aws_cognito_user_pool_client.jenkins.client_secret
  sensitive   = true
}

##############################################################################

output "argocd_cognito_client_id" {
  value = aws_cognito_user_pool_client.argocd.id
  sensitive   = true
}

output "argocd_cognito_secret" {
  value = aws_cognito_user_pool_client.argocd.client_secret
  sensitive   = true
}

##############################################################################

output "cognito_user_pool_id" {
  description = "Cognito user pool ID"
  value       = aws_cognito_user_pool.main.id
  sensitive   = true
}
