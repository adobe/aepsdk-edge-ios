#!/bin/bash
# run this script to setup a git hook to run the code formatter before committing changes

GIT_HOOKS_DIR=$(dirname $0)
GIT_DIR=$(git rev-parse --git-dir)
cp $GIT_HOOKS_DIR/pre-commit $GIT_DIR/hooks
chmod +x $GIT_DIR/hooks/pre-commit
