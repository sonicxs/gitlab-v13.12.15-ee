---
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Custom instance-level project templates **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/6860) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.2.

GitLab administrators can configure the group where all the custom project
templates are sourced.

Every project directly under the group namespace will be
available to the user if they have access to them. For example:

- Public projects, in the group will be available to every signed-in user, if all enabled [project features](../project/settings/index.md#sharing-and-permissions)
  except for GitLab Pages are set to **Everyone With Access**.
- Private projects will be available only if the user is a member of the project.

Repository and database information that are copied over to each new project are
identical to the data exported with the
[GitLab Project Import/Export](../project/settings/import_export.md).

NOTE:
To set project templates at a group level,
see [Custom group-level project templates](../group/custom_project_templates.md).

## Configuring

GitLab administrators can configure a GitLab group that serves as template
source for an entire GitLab instance by:

1. Navigating to **Admin Area > Settings > Templates**.
1. Expanding **Custom project templates**.
1. Selecting a group to use.
1. Pressing **Save changes**.

NOTE:
Projects below subgroups of the template group are **not** supported.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
