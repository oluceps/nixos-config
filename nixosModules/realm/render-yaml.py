"""Apply public networking settings to an existing runtime secret configuration."""

import json
import os
import sys

import yaml


def merge(original, overlay):
    for key, value in overlay.items():
        if isinstance(value, dict) and isinstance(original.get(key), dict):
            merge(original[key], value)
        elif value is None:
            original.pop(key, None)
        else:
            original[key] = value
    return original


def main():
    source, overlay, destination = sys.argv[1:]
    try:
        with open(source) as stream:
            original = yaml.safe_load(stream)
    except yaml.YAMLError:
        sys.exit("invalid YAML in runtime secret configuration")
    with open(overlay) as stream:
        settings = json.load(stream)
    fd = os.open(destination, os.O_CREAT | os.O_TRUNC | os.O_WRONLY | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, "w") as stream:
        yaml.safe_dump(merge(original, settings), stream)


if __name__ == "__main__":
    main()
