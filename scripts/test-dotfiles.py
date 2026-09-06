#!/usr/bin/env python3
"""Run isolated regression checks; never apply to the user's home or unlock rbw."""
import pathlib
import unittest

if __name__ == "__main__":
    suite = unittest.defaultTestLoader.discover(str(pathlib.Path(__file__).parent / "tests"))
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    raise SystemExit(not result.wasSuccessful())
