#!/usr/bin/env python3

from pathlib import Path
from subprocess import CalledProcessError, run

import click

SDK_ROOT = Path(__file__).parent.parent.absolute()


@click.command()
@click.option("-w", "--write", is_flag=True)
def main(write):
    if write:
        format_files()
    else:
        check_only()


def check_only():
    try:
        run(["dart", "analyze", "."], cwd=SDK_ROOT, check=True)
    except CalledProcessError as expt:
        exit(f"Issues found after running {expt.cmd} in {SDK_ROOT}.")


def format_files():
    run(["dart", "fix", "--apply", "."], cwd=SDK_ROOT, check=True)


if __name__ == "__main__":
    main()
