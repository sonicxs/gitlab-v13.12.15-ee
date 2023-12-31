---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Due dates

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/3614) in GitLab 8.7.

Please read through the [GitLab Issue Documentation](index.md) for an overview on GitLab Issues.

Due dates can be used in issues to keep track of deadlines and make sure features are
shipped on time. Users need at least [Reporter permissions](../../permissions.md)
to be able to edit the due date. All users with permission to view
the issue can view the due date.

## Setting a due date

When creating an issue, select the **Due date** field to make a calendar
appear for choosing the date. To remove the date, select the date
text and delete it. The date is related to the server's timezone, not the timezone of
the user setting the due date.

![Create a due date](img/due_dates_create.png)

You can also set a due date via the issue sidebar. Expand the
sidebar and click **Edit** to pick a due date or remove the existing one.
Changes are saved immediately.

![Edit a due date via the sidebar](img/due_dates_edit_sidebar.png)

The last way to set a due date is by using [quick actions](../quick_actions.md), directly in an issue's description or comment:

- `/due <date>`: set due date. Examples of valid `<date>` include `in 2 days`, `this Friday`, and `December 31st`.
- `/remove_due_date`: remove due date.

## Making use of due dates

You can see issues with their due dates in the issues list.
Overdue issues have their icon and date colored red.
To sort issues by their due dates, select **Due date** from the dropdown menu on the right.
Issues are then sorted from the earliest due date to the latest.
To display issues with the latest due dates at the top, select **Sort direction** (**{sort-lowest}**).

Due dates also appear in your [to-do list](../../todos.md).

![Issues with due dates in the to dos](img/due_dates_todos.png)

The day before an open issue is due, an email is sent to all participants
of the issue. Like the due date, the "day before the due date" is determined by the
server's timezone.

Issues with due dates can also be exported as an iCalendar feed. The URL of the
feed can be added to calendar applications. The feed is accessible by clicking
on the **Subscribe to calendar** button on the following pages:

- on the **Assigned Issues** page that is linked on the right-hand side of the GitLab header
- on the **Project Issues** page
- on the **Group Issues** page
