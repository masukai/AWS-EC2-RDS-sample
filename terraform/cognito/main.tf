# Amazon Cognito
# https://katsuya-place.com/terraform-cognito/

resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.name}-cognito-user-pool"
  auto_verified_attributes = [
    "email",
  ]
  mfa_configuration = "OFF"
  username_attributes = [
    "email",
  ]
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
  admin_create_user_config {
    allow_admin_create_user_only = true
  }
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true # 英小文字
    require_numbers                  = true # 数字
    require_symbols                  = true # 記号
    require_uppercase                = true # 英大文字
    temporary_password_validity_days = 7    # 初期登録時の一時的なパスワードの有効期限
  }
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true
    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }
  user_attribute_update_settings {
    attributes_require_verification_before_update = [
      "email",
    ]
  }
  username_configuration {
    case_sensitive = false
  }
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }
  tags = {
    Name = "${var.name}-cognito"
  }
}

resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain       = var.name
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  access_token_validity = 60
  allowed_oauth_flows = [
    "code",
  ]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = [
    "openid",
  ]
  auth_session_validity = 3
  callback_urls = [
    "https://example.com/",
  ]
  enable_propagate_additional_user_context_data = false
  enable_token_revocation                       = true
  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]
  id_token_validity             = 60
  logout_urls                   = []
  name                          = "${var.name}-cognito-client"
  prevent_user_existence_errors = "ENABLED"
  read_attributes = [
    "email",
  ]
  refresh_token_validity = 30
  supported_identity_providers = [
    "COGNITO",
  ]
  user_pool_id = aws_cognito_user_pool.user_pool.id
  write_attributes = [
    "email",
  ]
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}
