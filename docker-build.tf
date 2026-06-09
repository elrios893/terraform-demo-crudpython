resource "null_resource" "docker_build_and_push" {
  depends_on = [aws_instance.mysql, data.aws_ecr_repository.app]

  triggers = {
    app_hash        = filesha256("${path.module}/crud-python/app.py")
    dockerfile_hash = filesha256("${path.module}/crud-python/dockerfile")
    reqs_hash       = filesha256("${path.module}/crud-python/requirements.txt")
    index_hash      = filesha256("${path.module}/crud-python/templates/index.html")
    ignore_hash     = filesha256("${path.module}/crud-python/.dockerignore")
  }

  provisioner "local-exec" {
    command = <<-CMD
      $REPO_URL = "${data.aws_ecr_repository.app.repository_url}"
      Set-Location "${path.module}/crud-python"
      Write-Output "=== Build imagen ==="
      docker build -t iue-repo .
      Write-Output "=== Tag y push ==="
      docker tag iue-repo:latest "$${REPO_URL}:latest"
      docker push "$${REPO_URL}:latest"
    CMD
    interpreter = ["PowerShell", "-Command"]
  }
}
