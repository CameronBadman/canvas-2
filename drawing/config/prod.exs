import Config

# Configure the endpoint
config :drawing, DrawingWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  url: [host: "10.0.1.30", port: 4000],
  check_origin: false,
  server: true

# Redis configuration for WebSocket sessions
config :drawing,
  redis_host: System.get_env("REDIS_HOST") || "10.0.1.40",
  redis_port: String.to_integer(System.get_env("REDIS_PORT") || "6379")

# Logging
config :logger, level: :info
