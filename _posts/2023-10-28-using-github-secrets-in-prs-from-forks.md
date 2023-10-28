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
But, what happens when an external contributor opens a pull request on your project? Your secrets won't be available
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

### Use GitHub Environments
Using GitHub environments is another way to solve this problem. GitHub environments are a way to provide a set of
secrets that are only available for that environment. One common use case of environments is to deploy to a qa
environment for some conditions, and to a production environment for other conditions.

Let's use that logic to solve the problem of not having secrets available for pull requests from forks. We will create
an `internal` environment that will not require approval to run. Then we will create an `external` environment that
will require approval to run.

{% raw %}
```yaml
jobs:
  build:
    environment:
      ${{ github.event_name == 'pull_request' &&
      github.event.pull_request.head.repo.full_name != github.repository &&
      'external' || 'internal' }}
```
{% endraw %}

Now create the environments in your repository settings. The `internal` environment should not require approval, and
the `external` environment should require approval.

![Environment Settings](/assets/img/posts/2023-10-28-environment-settings-01.png)

Be sure to add your required secrets to each environment.

![Environment Secrets](/assets/img/posts/2023-10-28-environment-settings-02.png)

Now, when a pull request is opened from a fork, the workflow will run in the `external` environment. If the pull
request is opened from within the repository, the workflow will run in the `internal` environment. In both cases,
the workflow will have access to the secrets that are defined for that environment.

#### Final thoughts

I use this logic in my [create-release-action](https://github.com/LizardByte/create-release-action) repository. This is
because when a PR is opened from dependabot or a fork, I want to ensure that the action works as expected. Check the
[workflow](https://github.com/LizardByte/create-release-action/blob/361a8a8ef88735b64ac29db047c8622ba4ab1196/.github/workflows/ci.yml)
for a complete example.

{: .box-warning}
You must be very cautious when exposing secrets to external contributors. A bad actor could use the secrets for
malicious purposes. In addition to the `external` environment approval, I also require workflow approval for all
outside collaborators as a secondary measure. Be sure to fully review the code of any pull requests before approving
the workflows or deployment.
