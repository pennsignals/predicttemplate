"""Test Service."""
from {{cookiecutter.name}} import Service


def test_service():
    """Test service."""
    _ = Service.parse(
        argv=[
            "-c",
            "./predict/local/test.yaml",
            "-e",
            "./predict/secrets/example.env",
        ],
    )
