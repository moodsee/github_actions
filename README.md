# github action WIP blocker with labels in PR


## Usage

Create file in your repository `.github/workflows/wip.yml`

```yml
name: Label WIP checker CI

on:
  pull_request:
    types: [labeled, unlabeled, edited, opened, synchronize, reopened]
  workflow_dispatch:

jobs:
  label-wip-checker-CI:
    runs-on: ubuntu-latest

    steps:
    - name: WIP blocker with labels in PR
      uses: moodsee/github_actions@v1.0.0
      env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          WIP_LABELS: "DO NOT MERGE|NEED_REINDEX"
```
