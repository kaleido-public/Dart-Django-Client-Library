#!/usr/bin/env python3
from subprocess import run


def install_dart_sdk():
    if run(["which", "dart"]).returncode != 0:
        cmds = """
            apt-get update
            apt-get install apt-transport-https
            sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
            sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
            apt-get update
            apt-get install dart
            """
        for ln in cmds.splitlines():
            run(ln, shell=True, check=True)


if __name__ == "__main__":
    install_dart_sdk()
