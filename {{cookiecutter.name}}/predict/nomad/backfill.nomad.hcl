{% raw %}
job "[[ .project ]]_backfill" {
  datacenters = ["dc1"]

  meta {
    NAMESPACE = "[[ .deploy ]]"
  }

  type="batch"

  periodic = {
    cron             = "0 0 0 1 1 0 1970"
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
        dns_servers = ["127.0.0.1", "170.212.249.133", "170.212.24.5"]
        dns_search_domains = ["uphs.upenn.edu", "infoblox-master.uphs.upenn.edu", "root.uphs.upenn.edu"]

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
as_of: 1970-01-01 7:00:00+00
EOH
        destination = "${NOMAD_TASK_DIR}/configuration.yaml"
      }

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
