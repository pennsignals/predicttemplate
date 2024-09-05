"""Predict module."""

from .model import Model
from .service import Service, __version__

__all__ = ("Model", "Service", "__version__")
