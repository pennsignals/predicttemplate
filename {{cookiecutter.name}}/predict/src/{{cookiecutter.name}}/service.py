"""Service."""

from collections.abc import Sequence
from datetime import datetime, timedelta
from typing import Any, Generator

from dateutil.parser import parse
from dsdk import (
    CompositeTask,
    FlowsheetMixin,
    Interval,
    ModelMixin,
    PostgresPredictionMixin,
)
from dsdk import Service as BaseService
from dsdk import Task, configure_logger
from pandas import DataFrame, merge
from pkg_resources import DistributionNotFound, get_distribution

from .model import Model

try:
    __version__ = get_distribution("{{cookiecutter.name}}").version
except DistributionNotFound:
    __version__ = "0.0.0.dev+dirty." + str(datetime.utcnow().timestamp())


logger = configure_logger(__name__)


class Service(  # pylint: disable=too-many-ancestors
    FlowsheetMixin,
    PostgresPredictionMixin,
    ModelMixin,
    BaseService,
):
    """Service."""

    VERSION = __version__
    YAML = "!{{cookiecutter.name}}"

    @classmethod
    def yaml_types(cls) -> None:
        """As yaml type."""
        super().yaml_types()
        Model.as_yaml_type()

    def __init__(self, **kwargs):
        """__init__."""
        pipeline = (
            Extract(),
            Predict(),
        )
        self.days = 1
        super().__init__(pipeline=pipeline, **kwargs)

    def publish(self) -> Generator[Any, None, None]:
        """Publish."""
        yield from self.flowsheets.publish(self.postgres)



class Extract(CompositeTask):  # pylint: disable=too-few-public-methods
    """Extract."""

    def __init__(self):
        """__init__."""
        super().__init__(
            pipeline=(
                Cohort(),  # Get cohort
                Greenish(),  # Then load an attribute
            )
        )


class Cohort(Task):
    """Cohort."""

    def __call__(self, run, service):
        """__call__."""
        interval = run.evidence["interval"] = Interval(
            on=service.as_of - timedelta(days=service.days),
            end=service.as_of,
        )
        cohort = self.extract(interval)
        service.postgres.store_evidence(run, "cohorts", cohort)

    def extract(
        self,
        interval,
        data=(
            (0, "Zombie", "animal", parse("2020-12-31 00:00:00Z")),
            (1, "John Doe", "animal", parse("2020-12-31 00:00:00Z")),
            (2, "Spinach", "vegetable", parse("2020-12-31 00:00:00Z")),
            (3, "Parsnips", "vegetable", parse("2020-12-31 00:00:00Z")),
            (4, "Jade", "mineral", parse("2020-12-31 00:00:00Z")),
            (5, "Salt", "mineral", parse("2020-12-31 00:00:00Z")),
            # outside of interval
            # AS_OF is the end of an open-closed interval, end is not included!
            (6, "Soylent", "animal", parse("2021-01-01 00:00:00Z")),
            # no join
            (7, "Mystery", "mysterious", parse("2020-12-31 00:00:00Z")),
        ),
        columns=(
            "subject_id",
            "description",
            "kind",
            "at",
        ),
    ):
        """Extract."""
        # DataFrame example shows intent.
        # However, do NOT load the entire table and trim in python.
        # Instead, select only what is needed on the database to keep
        # the network payload small, and the application more resilient
        # to timeouts and latency
        df = DataFrame(data=list(data), columns=columns)
        # Add these condtions to sql instead.
        df = df[df["at"] >= interval.on]
        df = df[df["at"] < interval.end]
        return df


class Greenish(Task):
    """Greenish."""

    def __call__(self, run, service):
        """__call__."""
        evidence = run.evidence
        greenish = self.extract(
            ids=evidence["cohorts"]["subject_id"],
            interval=evidence["interval"],
        )
        service.postgres.store_evidence(run, "greenishes", greenish)

    def extract(
        self,
        ids: Sequence[int],
        interval: Interval,
        data=(
            # condition is worse over time
            (0, 0.25, parse("2020-12-31 00:00:00Z")),
            (0, 0.75, parse("2020-12-31 12:00:00Z")),
            # condition is better,
            # then worse over time,
            # but worse is outside of interval
            # AS_OF is the end of an open-closed interval, end is not included!
            (1, 0.75, parse("2020-12-31 00:00:00Z")),
            (1, 0.25, parse("2020-12-31 12:00:00Z")),
            (1, 1.0, parse("2020-01-01 00:00:00Z")),
            (2, 0.75, parse("2020-12-31 00:00:00Z")),
            (3, 0.25, parse("2020-12-31 00:00:00Z")),
            (4, 1.0, parse("2020-12-31 00:00:00Z")),
            (5, 0.0, parse("2020-12-31 00:00:00Z")),
            # outside of interval
            (6, 1.0, parse("2020-01-01 00:00:00Z")),
            # no join
            (8, 1.0, parse("2020-12-31 00:00:00Z")),
        ),
        columns=(
            "subject_id",
            "normal",
            "at",
        ),
    ):
        """Get."""
        # DataFrame example shows intent.
        # However, do NOT load the entire table and trim in python.
        df = DataFrame(data=list(data), columns=columns)
        # Add these condtions to extract sql instead.
        df = df[df["subject_id"].isin(ids)]
        df = df[df["at"] >= interval.on]
        df = df[df["at"] < interval.end]
        return df


class Predict(Task):
    """Predict."""

    def __call__(self, run, service):
        """__call__."""
        evidence = run.evidence
        model = service.model

        # you may use metadata stored along side the classifier in the model
        # see notes in predict/src/{{cookiecutter.name}}/model.py
        cohort = self.one_hot(
            df=self.last(evidence["cohorts"].copy()),
            key=model.key,
            knowns=model.knowns,
            unknown=model.unknown,
        )
        logger.debug("cohort: %s", cohort.to_string())

        greenish = self.last(evidence["greenishes"].copy()).rename(
            columns={"normal": "greenish"}
        )
        logger.debug("greenish: %s", greenish.to_string())

        df = merge(
            cohort,
            greenish,
            on="subject_id",
            how="inner",
            suffixes=(None, "_"),
            sort=True,
            validate="one_to_one",
        )

        logger.debug("join: %s", df.to_string())

        # include the transformed feature vector with the prediction
        df["score"] = service.model(df)

        logger.debug("predictions: %s", df.to_string())
        run.predictions = df

    def last(
        self,
        df,
        key="subject_id",
        at="at",
    ):
        """Latest."""
        df.sort_values([key, at], inplace=True)
        df.drop_duplicates(subset=[key], keep="last", inplace=True)
        df.drop(columns=[at], axis=1, inplace=True)
        return df

    def one_hot(
        self,
        df,
        key="kind",
        knowns=("animal", "vegetable", "mineral"),
        unknown="unknown",
    ):
        """One hot encode key with values."""
        values = set(knowns)
        for value in values:
            df[f"is_{value}"] = df[key] == value
        df[f"is_{unknown}"] = ~df[key].isin(values)
        df.drop(columns=[key], axis=1, inplace=True)
        return df
