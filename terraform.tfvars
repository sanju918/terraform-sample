#client_id                  = "8753fa67-624b-48f8-bb3b-510b343d2b09"
#client_secret              = "8h/Ea/8k71iOJH=qCwTK.QebtqYld7-H"
#tenant_id                  = "fcd79bf3-526c-4f6a-9c19-2690702af676"
#subscription_id            = "1b955944-01f5-4329-a14e-a86bf365cb5a"

web_server_location         = "westus2"
web_server_rg               = "web-rg"
resource_prefix             = "web-server"
web_server_address_space    = "1.0.0.0/22"
#web_server_address_prefix   = "1.0.1.0/24"
web_server_name             = "web"
environment                 = "development"
web_server_count            = 2
web_server_subnets          = ["1.0.1.0/24", "1.0.2.0/24"]
terraform_script_version      = "1.00"