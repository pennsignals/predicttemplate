job "{{ cookiecutter.name }}_backfill" {
  datacenters = ["dc1"]

  type="batch"

  periodic = {
    cron             = "0 0 0 1 1 0 1970"
    prohibit_overlap = true
    time_zone        = "America/New_York"
  }

  group "default" {
    vault {
      policies = ["{{ cookiecutter.name }}"]
    }

    restart {
      attempts = 24
      delay    = "5m"
      interval = "24h"
      mode     = "fail"
    }

    task "predict" {
      config = {
        image = "{{ cookiecutter.registry }}/{{ cookiecutter.name }}.predict:[[ (.version) ]]"
        dns_servers = ["127.0.0.1", "170.212.249.133", "170.212.24.5"]
        dns_search_domains = ["uphs.upenn.edu", "infoblox-master.uphs.upenn.edu", "root.uphs.upenn.edu"]

        volumes = [
          "/deploy/models/{{ cookiecutter.name }}:/model:ro"
        ]
      }

      driver = "docker"

      env {
        CONFIG = "${NOMAD_TASK_DIR}/configuration.yaml"
        ENV = "${NOMAD_SECRETS_DIR}/secrets.env"
      }

      resources {
        cpu    = {{ cookiecutter.predict_cpu }}
        memory = {{ cookiecutter.predict_memory }}
      }

      template {
        data = <<EOH
{{ '{{' }} key "{{ cookiecutter.organization }}/{{ cookiecutter.name }}/predict/configuration.yaml" {{ '}}' }}
as_of: 1970-01-01 7:00:00+00
EOH
        destination = "${NOMAD_TASK_DIR}/configuration.yaml"
      }

      template {
        data = <<EOH
{{ '{{' }} with secret "kv/data/{{ cookiecutter.organization }}/{{ cookiecutter.name }}/predict/secrets.env" {{ '}}' }}
{{ '{{' }} range $k, $v := .Data.data {{ '}}{{' }} $k {{ '}}={{' }} $v {{ '}}' }}
{{ '{{' }} end {{ '}}{{' }} end {{ '}}' }}
EOH
        destination = "${NOMAD_SECRETS_DIR}/secrets.env"
      }
    }
  }
}
