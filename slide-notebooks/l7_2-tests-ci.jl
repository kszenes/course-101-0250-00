#src # This is needed to make this run as normal Julia file
using Markdown #src

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
#nb # _Lecture 7_
md"""
# Continuous Integration (CI) and GitHub Actions

Last lecture we learned how to make and run tests for a Julia project.

This lecture we will learn how to run those tests on Github automatically
after you push to it. This will make sure that
- tests are always run
- you will be alerted by email when a test fails
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
*You may start to wonder why we're doing all of these tooling shenanigans...*

One requirement for the final project will be that it contains tests, which are run via GitHub Actions CI.  Additionally, you'll have to write your project report as "documentation" for the package which will be deployed to its website, again via GitHub Actions.
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "fragment"}}
md"""
**These days it is expected of good numerical software that it is well tested and documented.**
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
### GitHub Actions

GitHub Actions are a generic way to run computations when you interact with the repository. There is extensive [documentation](https://docs.github.com/en/actions) for it (no need for you to read it).

For instance the course's [website](https://eth-vaw-glaciology.github.io/course-101-0250-00/) is generated from the markdown input files upon pushing to the repo:
- [https://github.com/eth-vaw-glaciology/course-101-0250-00/tree/main/website](https://github.com/eth-vaw-glaciology/course-101-0250-00/tree/main/website) contains the source
- the [https://github.com/eth-vaw-glaciology/course-101-0250-00/blob/main/.github/workflows/Deploy.yml](https://github.com/eth-vaw-glaciology/course-101-0250-00/blob/main/.github/workflows/Deploy.yml) is the GitHub Actions script which tells it to run Franklin.jl to
- create the website [https://eth-vaw-glaciology.github.io/course-101-0250-00/](https://eth-vaw-glaciology.github.io/course-101-0250-00/)

"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
### GitHub Actions for CI

How do we use GitHub Actions for CI?

1. create a Julia project and add some tests
2. make a suitable GitHub Actions scrip (that `.yml` file)
3. pushing to GitHub will now run the tests (maybe you need to activate Actions in `Setting` -> `Actions` -> `Allow all actions`)
"""

#nb # > 💡 note: There are other providers of CI, e.g. Travis, Appveyor, etc. Here we'll only look at GitHub actions.
#md # \note{There are other providers of CI, e.g. Travis, Appveyor, etc. Here we'll only look at GitHub actions.}

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
#### Example from last lecture continued

In the last lecture I setup a [project](https://github.com/eth-vaw-glaciology/course-101-0250-00-L6Testing.jl) to illustrate how unit-testing works.

Let's now add CI to this:

1. create a Julia project and add some tests **[done]**
2. make a suitable GitHub Actions scrip (that `.yml` file)
3. pushing to GitHub will now run the tests (maybe you need to activate Actions in `Setting` -> `Actions` -> `Allow all actions`)

For step 2 we follow the documentation on [https://github.com/julia-actions/julia-runtest](https://github.com/julia-actions/julia-runtest).
"""

#nb # > 💡 note: [PkgTemplates.jl](https://github.com/invenia/PkgTemplates.jl) is a handy package, which can generate a suitable Github Actions file..
#md # \note{[PkgTemplates.jl](https://github.com/invenia/PkgTemplates.jl) is a handy package, which can generate a suitable Github Actions file.}

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
#### Example from last lecture continued: YML magic

The `.yml` file, adapted from the `README` of [julia-runtest](https://github.com/julia-actions/julia-runtest):
```yml
name: Run tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        julia-version: ['1.8']
        julia-arch: [x64]
        os: [ubuntu-latest]

    steps:
      - uses: actions/checkout@v2
      - uses: julia-actions/setup-julia@v1
        with:
          version: ${{ matrix.julia-version }}
          arch: ${{ matrix.julia-arch }}
      - uses: julia-actions/julia-buildpkg@v1
      - uses: julia-actions/julia-runtest@v1
```
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
#### Where is my BADGE!!!

The CI will create a badge (a small picture) which reflects the status of the Action. Typically added to the `README.md`:

![ci-badge](./figures/ci-badge.png)

It can be found under
```
https://github.com/<USER>/<REPO>/actions/workflows/CI.yml/badge.svg
```
and should be added to the near the top of `README` like so:
```
[![CI action](https://github.com/<USER>/<REPO>/actions/workflows/CI.yml/badge.svg)](https://github.com/<USER>/<REPO>/actions/workflows/CI.yml)
```
(this also sets the link to the Actions which gets open upon clicking on it)

👉 _**All together**_ on [https://github.com/eth-vaw-glaciology/course-101-0250-00-L6Testing.jl](https://github.com/eth-vaw-glaciology/course-101-0250-00-L6Testing.jl)
"""

#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
#### Wait a second, we submit our homework as subfolders of our GitHub repo...

This makes the `.yml` a bit more complicated:
```yml
name: CI
on:
  [push, pull_request]
jobs:
  test:
    name: Julia ${{ matrix.julia-version }} - ${{ matrix.os }} - ${{ matrix.julia-arch }} - ${{ github.event_name }}
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        julia-version: ['1.6']
        julia-arch: [x64]
        os: [ubuntu-latest]
    steps:
      - uses: actions/checkout@v2
      - uses: julia-actions/setup-julia@v1
        with:
          version: ${{ matrix.julia-version }}
          arch: ${{ matrix.julia-arch }}
      - uses: actions/cache@v1
        env:
          cache-name: cache-artifacts
        with:
          path: ~/.julia/artifacts
          key: ${{ runner.os }}-test-${{ env.cache-name }}-${{ hashFiles('**/Project.toml') }}
          restore-keys: |
            ${{ runner.os }}-test-${{ env.cache-name }}-
            ${{ runner.os }}-test-
            ${{ runner.os }}-
      - uses: julia-actions/julia-buildpkg@v1
      - run: julia --check-bounds=yes --color=yes -e 'cd("<subfolder-of-julia-project>"); import Pkg; Pkg.activate("."); Pkg.test()'
```
Note that you have to _**adjust**_ the bit: `cd("<subfolder-of-julia-project>")`.

👉 The _**example**_ is in [course-101-0250-00-L6Testing-subfolder.jl](https://github.com/eth-vaw-glaciology/course-101-0250-00-L6Testing-subfolder.jl).
"""


#nb # %% A slide [markdown] {"slideshow": {"slide_type": "slide"}}
md"""
#### A final note

GitHub Actions are limited to 2000min per month per user for private repositories.
"""
