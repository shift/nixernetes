resource "nixernetes_config" "simple" {
  name          = "example-config"
  configuration = file("${path.module}/config.nix")
  environment   = "development"
}

resource "nixernetes_module" "api" {
  name      = "api-service"
  image     = "myregistry/api:latest"
  replicas  = 2
  namespace = "default"

  depends_on = [nixernetes_config.simple]
}

resource "nixernetes_module" "worker" {
  name      = "worker-service"
  image     = "myregistry/worker:latest"
  replicas  = 1
  namespace = "default"

  depends_on = [nixernetes_config.simple]
}

resource "nixernetes_project" "production" {
  name        = "production"
  description = "Production environment deployment"
}

output "config_id" {
  value = nixernetes_config.simple.id
}

output "api_module_id" {
  value = nixernetes_module.api.id
}

output "project_id" {
  value = nixernetes_project.production.id
}
