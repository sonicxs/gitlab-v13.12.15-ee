---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# DevOps Report

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/30469) in GitLab 9.3.
> - [Renamed from Conversational Development Index](https://gitlab.com/gitlab-org/gitlab/-/issues/20976) in GitLab 12.6.

The DevOps Report gives you an overview of your entire instance's adoption of
[Concurrent DevOps](https://about.gitlab.com/topics/concurrent-devops/)
from planning to monitoring.

To see DevOps Report, go to **Admin Area > Analytics > DevOps Report**.

## DevOps Score **(FREE)**

NOTE:
Your GitLab instance's [usage ping](../settings/usage_statistics.md#usage-ping) must be activated in order to use this feature.

The DevOps Score tab displays the usage of major GitLab features on your instance over
the last 30 days, averaged over the number of billable users in that time period. It also
provides a Lead score per feature, which is calculated based on GitLab analysis
of top-performing instances based on [usage ping data](../settings/usage_statistics.md#usage-ping) that GitLab has
collected. Your score is compared to the lead score of each feature and then expressed as a percentage at the bottom of said feature.
Your overall **DevOps Score** is an average of your feature scores. You can use this score to compare your DevOps status to other organizations.

The page also provides helpful links to articles and GitLab docs, to help you
improve your scores.

Usage ping data is aggregated on GitLab servers for analysis. Your usage
information is **not sent** to any other GitLab instances. If you have just started using GitLab, it may take a few weeks for data to be
collected before this feature is available.

## DevOps Adoption **(ULTIMATE)**

[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/247112) in GitLab 13.7 as a [Beta feature](https://about.gitlab.com/handbook/product/gitlab-the-product/#beta).

The DevOps Adoption tab shows you which groups within your organization are using the most essential features of GitLab:

- Issues
- Merge Requests
- Approvals
- Runners
- Pipelines
- Deploys
- Scanning

Buttons to manage your groups appear in the DevOps Adoption section of the page.

DevOps Adoption allows you to:

- Verify whether you are getting the return on investment that you expected from GitLab.
- Identify specific groups that are lagging in their adoption of GitLab so you can help them along in their DevOps journey.
- Find the groups that have adopted certain features and can provide guidance to other groups on how to use those features.

### Disable or enable DevOps Adoption

DevOps Adoption is deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can opt to enable it.

To enable it:

```ruby
Feature.enable(:devops_adoption_feature)
```

To disable it:

```ruby
Feature.disable(:devops_adoption_feature)
```
