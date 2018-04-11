#!/usr/bin/env bash
#
# This script creates a new local issue branch for the given issue id.
# Previous changes are stashed before the issue branch is created and are reapplied after branch creation.
#
# executing new-issue-branch.sh ISSUE-42
# will create a new (local) branch issue/ISSUE-42
USAGE="$0 <issue_id>"
if [ $# -lt 1 ]; then echo -e "ERROR: issue_id required. \n$USAGE" >&2; exit 1; fi
if [ $# -gt 1 ]; then echo -e "ERROR: One argument maximum.\n$USAGE" >&2; exit 1; fi

ISSUE_ID=${1:?"ISSUE_ID Parameter is missing!"}

# Warmup the maven plugins before actually using them (avoids "Downloading" messages getting in variables)
echo "Warming up the Maven plugins..."
mvn -q org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version
mvn -q versions:help

# Now use the plugins to roll the version

echo "Looking up the current version..."
OLD_VERSION_TMP=$(mvn -o org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | grep -Ev '^\[.*')

OLD_POM_VERSION=${OLD_VERSION_TMP:?"Could not extract current project version from pom.xml"}

# Replaces BUILD in BUILD-SNAPSHOT with the given ISSUE_ID
NEW_POM_VERSION=${OLD_POM_VERSION/"BUILD"/$ISSUE_ID}
ISSUE_BRANCH="issue/$ISSUE_ID"

echo "Creating feature branch $ISSUE_ID: $OLD_POM_VERSION -> $NEW_POM_VERSION"

echo "Stashing potential intermediate changes..." && git stash\
&& git checkout -b $ISSUE_BRANCH\
&& $(mvn -o $MAVEN_FLAGS -q versions:set -DgenerateBackupPoms=false -DnewVersion=$NEW_POM_VERSION)\
&& ( \
      (\
         git commit -am "$ISSUE_ID - Prepare branch"\
         && echo "Created feature branch: $ISSUE_BRANCH"\
         && echo "Reapplying potentially stashed changes... " && git stash pop)\
  || echo "Something went wrong!")
