"""Model."""

from pickle import HIGHEST_PROTOCOL, dump
from typing import Callable, Dict, Optional, Sequence

from dsdk import Model as BaseModel
from dsdk import now_utc_datetime
from pandas import DataFrame, Series


class Model(BaseModel):
    """Model."""

    def __init__(  # pylint: disable=too-many-arguments
        self,
        *,
        author: str,
        key: str,  # for one-hot example
        knowns: Sequence[str],  # for one-hot example
        name: str,
        unknown: str,  # for one-hot example
        version: str,
        classifier: Callable,  # pylint: disable=redefined-outer-name
        **kwargs,
    ):
        """__init__.

        This call should and will fail if the pickled dictionary does
        not include the keyword arguments.
        This is by design, and indicates a configuration failure where
        the wrong model is given.
        The intent is to fail early to indicate an (easy)
        configuration failure instead of conflating them with
        possible (late) harder pipeline problem:
        bad data, unexpected values, etc. that also adds
        garbage to the database.
        """
        self.author = author
        self.classifier = classifier
        # assert that an appropriate model is for this module.
        assert name == "{{cookiecutter.name}}"

        # Why add these here instead of in consul configuration?
        #  - When the classifier is tightly coupled to the values
        #  - When you want the configuration versioned
        #    for debugging or improved context of past runs.
        #    - consul is convenient, but it is impossible to
        #      recover past configuration(s) once changed.
        #    - change the metadata and not the classifier, repickle
        #      with a new model version number
        # Do not add things here that must change dynamically
        #  - phone lists
        #
        self.key = key
        self.knowns = knowns
        self.unknown = unknown

        super().__init__(name=name, version=version, **kwargs)

    def __call__(self, df: DataFrame):
        """__call__."""
        return self.classifier(df)

    @classmethod
    def pickle(
        cls,
        dictionary: Optional[dict] = None,
        path: str = "./predict/model/{{cookiecutter.name}}.pkl",
    ):
        """Pickle dictionary as model."""
        if dictionary is None:
            # These keys must match the keyword
            # arguments to Model.__init__
            dictionary = {
                "author": "Predictive Medicine",
                "classifier": classifier,
                "key": "kind",
                "knowns": ["animal", "vegetable", "mineral"],
                "name": "{{cookiecutter.name}}",
                "timestamp": now_utc_datetime(),
                "unknown": "unknown",
                "version": "1.0.0",
            }
        with open(path, "wb") as handle:
            dump(dictionary, handle, protocol=HIGHEST_PROTOCOL)


def classifier(df: DataFrame) -> Series:
    """Score df."""
    return ~df["is_mineral"] * (
        (df["is_animal"] * df["greenish"])
        + (df["is_vegetable"] * (1.0 - df["greenish"]))
    )
