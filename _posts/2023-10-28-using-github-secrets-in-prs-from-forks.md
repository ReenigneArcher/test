---
layout: post
title: Using GitHub secrets in PRs from forks
subtitle: How to use GitHub secrets in pull requests from forks
gh-repo: reenignearcher/reenignearcher.github.io
gh-badge: [follow]
tags: [github, github-workflows, ci, cd, devopos]
thumbnail-img: /assets/img/posts/2023-10-28-environment-settings-01.png
comments: true
author: ReenigneArcher
---

## Introduction
GitHub workflows are a powerful tool for automating CI/CD pipelines. There are countless
[events](https://docs.github.com/actions/reference/events-that-trigger-workflows) that can trigger a workflow.
One of the most common is the `pull_request` event. This event can trigger a workflow when a pull request is opened,
synchronized, labeled, etc. This is a great way to run tests on a pull request before merging it into your project.

You can even provide secrets to your workflow via repository secrets, or organization secrets. This is useful if you
need to provide a token to your workflow to authenticate with an external service, for example. It's a great way to
ensure that your code works with real services.

## The Problem
But what happens when an external contributor opens a pull request on your project? Your secrets won't be available
to the workflow, and most likely it will fail. The default GitHub token will also have read-only access.

Suddenly, you may find yourself in a situation where you can't run your workflow, tests, etc. This can be frustrating,
especially if you're trying to maintain a high level of quality in your project.

## Solutions

### Skip various steps
One solution is to skip steps in your workflow, or specific tests when the workflow is triggered by a fork. This is
a common solution, but it's not the most ideal.

How to skip a step in a workflow?

{% raw %}
```yaml
steps:
  - name: Run on internal PRs
    if: github.repository != github.event.pull_request.head.repo.full_name
    run: echo "This will only run on internal PRs"
```
{% endraw %}

### Use `pull_request_target` event
Another solution is to use the `pull_request_target` event instead of the `pull_request` event. This event is similar
to the `pull_request` event, but it has a few key differences. The most important difference is that the
`pull_request_target` will default to use the code as is in the base branch and will not use the code from the fork.
You can overcome this by customizing the checkout action.

{% raw %}
```yaml
steps:
  - name: Checkout
    uses: actions/checkout@v4
    with:
      repository: ${{ github.event.pull_request.head.repo.full_name || github.repository }}
      ref: ${{ github.event.pull_request.head.sha || github.sha }}
```
{% endraw %}

The above code will checkout the code from the head branch if it's running on a pull request event, otherwise it will
checkout the code from the GitHub context.

This solution is okay, IF the workflow itself is not modified as part of the pull request. If your workflow often needs
modifications, such as installing new build dependencies, this solution will not work as it will use the workflow from
the base branch instead of from the fork.

#### Final thoughts

GitHub is very cautious about giving secret access to any external branches. Even with settings such as
`Require approval for all outside collaborators` enabled, the secrets are never provided to forks. In my opinion, this
is due to a lack of trust against developers on GitHub. Inexperienced maintainers are often approving workflow runs,
without understanding what changes are in the PR. It seems like a punishment for experienced maintainers and can be
cumbersome for many open-source projects that require secrets in CI/CD pipelines.

I've personally spent far too much time trying to work around these issues. Due to these limitations, I'm planning to
attempt to develop a tool that can provide secrets to workflows, without the need for storing the secrets in GitHub
directly. I will update this post with more details once it's available.
