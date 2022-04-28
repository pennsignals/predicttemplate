{% raw %}
job "[[ .project ]]_predict" {
  datacenters = ["dc1"]

  meta {
    NAMESPACE = "[[ .deploy ]]"
  }

  type="batch"

  periodic = {
    cron             = "[[ .services.predict.periodic.cron ]]"
    prohibit_overlap = true
    time_zone        = "America/New_York"
  }

  group "default" {
    vault {
      policies = ["[[ .project ]]"]
    }

    restart {
      attempts = 24
      delay    = "5m"
      interval = "24h"
      mode     = "fail"
    }

    task "predict" {
      driver = "docker"
      config = {
        image = "[[ .services.predict.image.registry ]]/[[ .services.predict.image.name ]]:[[ or (.TAG) .services.predict.image.version ]]"

        volumes = [
          "/share/models/[[ .project ]]:/model:ro"
        ]

      }


      resources {
        cpu    = [[ .services.predict.resources.cpu ]]
        memory = [[ .services.predict.resources.memory ]]
      }

      template {
        data = <<EOH
{{ key "[[ .organization ]]/[[ .project ]]/predict/[[ .services.predict.configuration.name ]]" }}
EOH
        destination = "${NOMAD_TASK_DIR}/config.yaml"
      }

      # *templating and vault policy* require the additional '/data' and '.data' seen here:
      template {
        data = <<EOH
{{ with secret "kv/data/[[ .organization ]]/[[ .project ]]/predict/[[ .services.predict.secrets.name ]]" }}
mssql-database: {{ index .Data.data "mssql-database" }}
mssql-host: {{ index .Data.data "mssql-host" }}
mssql-password: {{ index .Data.data "mssql-password" }}
mssql-port: {{ index .Data.data "mssql-port" }}
mssql-username: {{ index .Data.data "mssql-username" }}
postgres-database: {{ index .Data.data "postgres-database" }}
postgres-host: {{ index .Data.data "postgres-host" }}
postgres-password: {{ index .Data.data "postgres-password" }}
postgres-port: {{ index .Data.data "postgres-port" }}
postgres-username: {{ index .Data.data "postgres-username" }}
postgres-ssl-mode: {{ index .Data.data "postgres-ssl-mode" }}
mongo-uri: {{ index .Data.data "mongo-uri" }}
{{ end }}
EOH
        destination = "${NOMAD_SECRETS_DIR}/config.yaml"
      }
    }
  }
}
{% endraw %}
