terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.52.0"
    }
  }
}

variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "ssh_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "git_repo_url" {
  description = "Git repository URL for the application"
  type        = string
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "deploy_key" {
  name       = "drawing-app-key"
  public_key = file(var.ssh_key_path)
}

resource "hcloud_network" "private" {
  name     = "drawing-app-network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "private_subnet" {
  network_id   = hcloud_network.private.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_server" "frontend" {
  name        = "frontend-server"
  image       = "ubuntu-22.04"
  server_type = "cpx11"
  location    = "fsn1"
  ssh_keys    = [hcloud_ssh_key.deploy_key.id]
  
  network {
    network_id = hcloud_network.private.id
    ip         = "10.0.1.10"
  }

  user_data = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - docker.io
      - docker-compose
      - nginx
      - git
    
    runcmd:
      - systemctl enable docker
      - systemctl start docker
      - usermod -aG docker root
      - git clone ${var.git_repo_url} /app
      - mkdir -p /app/frontend
    EOF

  depends_on = [hcloud_network_subnet.private_subnet]
}

resource "hcloud_server" "backend_go" {
  name        = "backend-go-server"
  image       = "ubuntu-22.04"
  server_type = "cpx11"
  location    = "fsn1"
  ssh_keys    = [hcloud_ssh_key.deploy_key.id]
  
  network {
    network_id = hcloud_network.private.id
    ip         = "10.0.1.20"
  }

  user_data = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - docker.io
      - docker-compose
      - git
    
    runcmd:
      - systemctl enable docker
      - systemctl start docker
      - usermod -aG docker root
      - git clone ${var.git_repo_url} /app
      - mkdir -p /app/backend-go
    EOF

  depends_on = [hcloud_network_subnet.private_subnet]
}

resource "hcloud_server" "backend_elixir" {
  name        = "backend-elixir-server"
  image       = "ubuntu-22.04"
  server_type = "cpx11"
  location    = "fsn1"
  ssh_keys    = [hcloud_ssh_key.deploy_key.id]
  
  network {
    network_id = hcloud_network.private.id
    ip         = "10.0.1.30"
  }

  user_data = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - docker.io
      - docker-compose
      - git
    
    runcmd:
      - systemctl enable docker
      - systemctl start docker
      - usermod -aG docker root
      - git clone ${var.git_repo_url} /app
      - mkdir -p /app/backend-elixir
    EOF

  depends_on = [hcloud_network_subnet.private_subnet]
}

resource "hcloud_server" "database" {
  name        = "database-server"
  image       = "ubuntu-22.04"
  server_type = "cpx21"
  location    = "fsn1"
  ssh_keys    = [hcloud_ssh_key.deploy_key.id]
  
  network {
    network_id = hcloud_network.private.id
    ip         = "10.0.1.40"
  }

  user_data = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - docker.io
      - docker-compose
      - git
    
    runcmd:
      - systemctl enable docker
      - systemctl start docker
      - usermod -aG docker root
      - mkdir -p /data/postgres /data/redis
      - chown -R 999:999 /data/postgres
      
      # Create docker-compose for databases
      - |
        cat > /app/docker-compose.yml << 'EOL'
        version: '3.8'
        services:
          postgres:
            image: postgres:15
            environment:
              POSTGRES_DB: drawing_app
              POSTGRES_USER: app_user
              POSTGRES_PASSWORD: secure_password_123
            ports:
              - "5432:5432"
            volumes:
              - /data/postgres:/var/lib/postgresql/data
            restart: unless-stopped
          
          redis:
            image: redis:7-alpine
            ports:
              - "6379:6379"
            volumes:
              - /data/redis:/data
            restart: unless-stopped
            command: redis-server --appendonly yes
        EOL
      
      - cd /app && docker-compose up -d
    EOF

  depends_on = [hcloud_network_subnet.private_subnet]
}

resource "hcloud_firewall" "web_firewall" {
  name = "web-firewall"
  
  rule {
    direction = "in"
    port      = "22"
    protocol  = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  
  rule {
    direction = "in"
    port      = "80"
    protocol  = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  
  rule {
    direction = "in"
    port      = "443"
    protocol  = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_firewall_attachment" "all_servers_firewall" {
  firewall_id = hcloud_firewall.web_firewall.id
  server_ids  = [
    hcloud_server.frontend.id,
    hcloud_server.backend_go.id, 
    hcloud_server.backend_elixir.id,
    hcloud_server.database.id
  ]
}

output "frontend_ip" {
  value = hcloud_server.frontend.ipv4_address
}

output "backend_go_ip" {
  value = hcloud_server.backend_go.ipv4_address
}

output "backend_elixir_ip" {
  value = hcloud_server.backend_elixir.ipv4_address
}

output "database_ip" {
  value = hcloud_server.database.ipv4_address
}

output "private_network_info" {
  value = {
    frontend_private_ip = "10.0.1.10"
    backend_go_private_ip = "10.0.1.20"
    backend_elixir_private_ip = "10.0.1.30"
    database_private_ip = "10.0.1.40"
  }
}

output "database_connection_info" {
  value = {
    postgres_host = "10.0.1.40"
    postgres_port = "5432"
    postgres_db   = "drawing_app"
    postgres_user = "app_user"
    redis_host    = "10.0.1.40"
    redis_port    = "6379"
  }
  sensitive = true
}
