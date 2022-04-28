# dsdk_cookie
This repo should be used as a template for new data science project at Penn Medicine, especially for any project that is expected to push data back into the EMR

## Instructions

### Cruft

To use this repo you first need a python enviroment with [cruft](https://github.com/cruft/cruft#readme) installed. To install cruft run

```sh
pip install cruft
```

or the equivalent for your environment.

### Creating a new project

Once cruft is installed you can run the following to create your new project:

```sh
cruft create https://github.com/pennsignals/dsdk_cookie
```

### Updating an existing project

Occasionally updates will be made to dsdk_cookie which should be rolled into your project to keep it up to date. To check if your project is up to date run the following:

```sh
cruft check
```

If your project is out of date you can run the following to update it:

```sh
cruft update
```

# TODO
* Add `cruft check` to CICD in ` {{cookiecutter.name}}/.github/workflows`. Maybe as part of test.yml? Maybe it's own thing?
* Add `.github/test.yml` to root of this repo and have it run `cookiecutter .` to ensure that the template isn't broken when updates are made