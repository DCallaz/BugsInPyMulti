# BugsInPy Multi-fault
A multifault version of the [BugsInPy](https://github.com/soarsmu/BugsInPy) dataset.
## Description
This repository includes all the necessary scripts and files needed to create a
multi-fault dataset from the original BugsInPy single-fault dataset. This is
done using a test case transplantation and fault location translation process
for bug exposure and identification respectively.

The test case transplantation process is based on the ideas from [An et.
al.](https://github.com/coinse/Defects4J-multifault), and is included in this
repository (see [version search replication](#replication-of-version-searching)).
For details on the fault location translation process, see the
[bug-backtracker](https://github.com/DCallaz/bug-backtracker).

## Setup
### Requirements
* python3 >= 3.8
* virtualenv
* The project specific dependencies contained in `dependencies.txt`[^1]

OR

* Docker (see [Docker setup section](#docker))

[^1]: These dependencies are listed for Debian-based systems; for other
systems please find equivalent packages, or consider using the docker
container.

### Steps
This repository contains a standalone clone of the BugsInPy dataset. In order to
set up this dataset, simply run the following line:
```
export PATH="$PATH:/path/to/bugsinpy/framework/bin"
```
Add the above command to your bashrc (or similar) for loading upon startup.

You can then test your installation by running:
```
bugsinpy-multi-checkout -h
```
which should print the help message of the multi-fault checkout command.

### Docker

Alternatively, this dataset may be used from within a Docker container. To set
up the dataset's Docker container, navigate to the `docker` directory:
```
cd docker/
```
and run the following (you may need to prefix each command with `sudo`):
```bash
# build the docker image
docker build --tag bip-mf .
# create the docker container from the image
docker run -dt --name bip-mf bip-mf:latest
# execute an interactive bash shell for the container
docker exec -it bip-mf bash
```

The dataset repository should then be available at `/defects4j-mf/` inside the
Docker container.

## Usage
The following commands are available for use within the dataset:

Command | Description
--- | ---
info | Get information of a specific project or a specific bug. Includes multi-fault info
checkout	| Checkout a buggy or fixed version of a project from the dataset
multi-checkout | Checkout a multi-fault version of a project from the dataset
compile	| Compile sources from the project that has been checked out
test	| Run a single-test case from input user, test cases relevant to the bug, or all test cases from a project
coverage |	Run code coverage analysis of a single-test case from input user, test cases relevant to the bug, or all test cases. Also produces an SBFL-compatible TCM file
to-tcm | (Optional) Create or update a code coverage TCM file from the collected coverage
identify | Mark each of the faults identified in a multi-fault version in the created TCM
mutation |	Run mutation analysis from user input or test cases relevant to the bug
fuzz | Run test input generation from a specific bug

Any of the above commands can be run as: `bugsinpy-<command>`, for example:
```
bugsinpy-info -p PySnooper
```
will print project specific information for the PySnooper project. All of the
commands will print help information when supplied with the `-h` option.
## Usage example
A common use case for the BugsInPy multi-fault dataset is for use in evaluation
for debugging techniques. In order to achieve this, the following process can be
done:
1. Checkout a particular project version (this command may take a while):
  ```
  bugsinpy-multi-checkout -p black -i 4 -w $PWD/black-4
  ```
2. Change to the checked out directory:
  ```
  cd black-4/black
  ```
3. Compile the project
  ```
  bugsinpy-compile
  ```
4. Collect coverage for the version
  ```
  bugsinpy-coverage -a
  ```
5. Mark each of the identified faults in the TCM
  ```
  bugsinpy-identify
  ```
  A TCM file called `coverage.tcm` will then be available for this version.
## Replication of version searching
In order to replicate the experiments and verify which bugs are exposable in
each version, the `version_search.sh` script has been provided. The script can
be run as follows:
```
./version_search [-l <log dir>] <project>
```
which will generate the versions that each bug is found to be exposable in, and
store these in the `log dir` (default `versions/`).

To ensure maximum reproducibility, ensure that you have the dependencies described
in `dependencies.txt` before running the version search. All other dependencies
are downloaded automatically, including necessary python versions, which are
stored in the automatically created `python_versions` directory.
