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
      config = {
        image = "[[ .services.predict.image.registry ]]/[[ .services.predict.image.name ]]:[[ or (.TAG) .services.predict.image.version ]]"

        volumes = [
          "/share/models/[[ .project ]]:/model:ro"
        ]
      }

      driver = "docker"

      env {
        CONFIG = "${NOMAD_TASK_DIR}/configuration.yaml"
        ENV = "${NOMAD_SECRETS_DIR}/secrets.env"
      }

      resources {
        cpu    = [[ .services.predict.resources.cpu ]]
        memory = [[ .services.predict.resources.memory ]]
      }

      template {
        data = <<EOH
{{ key "[[ .organization ]]/[[ .project ]]/predict/[[ .services.predict.configuration.name ]]" }}
EOH
        destination = "${NOMAD_TASK_DIR}/configuration.yaml"
      }

      # *templating and vault policy* require the additional '/data' and '.data' seen here:
      template {
        data = <<EOH
{{ with secret "kv/data/[[ .organization ]]/[[ .project ]]/predict/[[ .services.predict.secrets.name ]]" }}
{{ range $k, $v := .Data.data }}{{ $k }}={{ $v }}
{{ end }}{{ end }}
EOH
        destination = "${NOMAD_SECRETS_DIR}/secrets.env"
      }
    }
  }
}{% endraw %}
