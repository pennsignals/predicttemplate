# dsdk_cookie
This repo should be used as a template for new data science projects at Penn Medicine, especially for any project that is expected to push data back into the EMR

## Instructions

### Cruft

To use this repo you first need a python enviroment with [cruft](https://github.com/cruft/cruft#readme) installed. To install cruft run

```sh
pip install cruft
```

or the equivalent for your environment.

### Creating a new project

The project name must be a valid postgres schema name, python module name, and nomad task name.

Choose a project / repo name:

1. Short but does not abbreviate words
3. All lower case
4. No hyphens
5. No underscores

Once cruft is installed you can run the following to create your new project:

```sh
cruft create https://github.com/pennsignals/dsdk_cookie
```

### Push to github
Once your project is created you should push it to github by [making a new private repo](https://github.com/organizations/pennsignals/repositories/new) and pushing it like:

```sh
cd {your-project-name}
git init
git add -A
git commit -m "first commit"
git branch -M main
git remote add origin git@github.com:pennsignals/{name}.git
git push -u origin main
```

### Updating an existing project

Occasionally updates will be made to `dsdk_cookie` which should be rolled into your project to keep it up to date. To check if your project is up to date run the following:

```sh
cruft check
```

If your project is out of date you can run the following to update it:

```sh
cruft update
```

### Further instructions
For further instructions on how to use your project can be found in the `readme.md` for your project at https://github.com/pennsignals/{your-repo-name}#readme

# TODO
* Add `cruft check` to CICD in `{{cookiecutter.name}}/.github/workflows`. Maybe as part of test.yml? Maybe it's own thing?
* Add `.github/test.yml` to root of this repo and have it run `cookiecutter .` to ensure that the template isn't broken when updates are made.
* Update `{{cookiecutter.name}}/readme.md` with instructions on how to use `cruft update`.
