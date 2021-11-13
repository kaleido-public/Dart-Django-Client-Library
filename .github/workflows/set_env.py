#!/usr/bin/env python3

import os
from pathlib import Path
from subprocess import CalledProcessError, run
from typing import Dict, List, Union

import click

__dir__ = Path(__file__).parent.absolute()


def github_repo_name() -> str:
    if repo_full := os.environ.get("GITHUB_REPOSITORY"):
        return repo_full.split("/")[1]
    else:
        return ""


def git_list_changes() -> List[str]:
    return run(
        ["git", "log", "-1", "--name-only", "--pretty="],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.splitlines()


def git_branch_name() -> str:
    if fullref := os.environ.get("GITHUB_REF", ""):
        return fullref[len("refs/heads/") :]
    else:
        return ""


def target_branch() -> str:
    if git_branch_name() == "staging":
        return "release"
    else:
        return "staging"


def git_commit_title() -> str:
    return run(
        ["git", "log", "-1", r"--pretty=format:%s"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.splitlines()[0]


def git_short_sha() -> str:
    if fullsha := os.environ.get("GITHUB_SHA", ""):
        return fullsha[:7]
    else:
        return ""


def is_dev_branch() -> bool:
    return git_branch_name() not in ["release", "staging"]


def ci_yaml_changed() -> bool:
    return ".github/workflows/ci.yml" in git_list_changes()


def docker_tag() -> str:
    return f"{git_branch_name()}-{git_short_sha()}"


def docker_stack_name() -> str:
    return f"{github_repo_name()}-{git_branch_name()}-{git_short_sha()}"


def should_upload_package() -> bool:
    return git_branch_name() == "release"


def should_upload_image() -> bool:
    return git_branch_name() in ["release", "staging"]


def pr_body() -> str:
    if target_branch() == "staging":
        return 'To merge into the staging branch, please use "Rebase and merge", or "Squash and merge".'
    elif target_branch == "release":
        return 'To merge into the release branch, please use "Create a merge commit".'
    return ""


def overwrite_path() -> str:
    return ":".join(
        [
            str(__dir__),
            os.environ["PATH"],
        ]
    )


def get_env() -> Dict[str, Union[str, bool]]:
    return {
        "PROJECT_NAME": github_repo_name(),
        "DOCKER_TAG": docker_tag(),
        "CI_YAML_CHANGED": ci_yaml_changed(),
        "IS_DEV_BRANCH": is_dev_branch(),
        "BRANCH_NAME": git_branch_name(),
        "TARGET_BRANCH": target_branch(),
        "COMMIT_TITLE": git_commit_title(),
        "SHOULD_UPLOAD_PACKAGE": should_upload_package(),
        "SHOULD_UPLOAD_IMAGE": should_upload_image(),
        "PATH": overwrite_path(),
        "PR_BODY": pr_body(),
    }


@click.command()
@click.option("-w", "--write", is_flag=True)
def main(write):
    content = ""
    for key, val in get_env().items():
        if write:
            content += f"{key}={val}\n"
        else:
            content += f"{key}={val.__repr__()}\n"
    if write:
        with open(os.environ["GITHUB_ENV"], "a") as env_file:
            env_file.write(content)
    else:
        print(content, end="")


if __name__ == "__main__":
    try:
        main()
    except CalledProcessError as err:
        exit(err.stdout + err.stderr)
