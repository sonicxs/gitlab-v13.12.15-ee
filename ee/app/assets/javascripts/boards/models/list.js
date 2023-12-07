/* eslint-disable no-param-reassign */
import ListAssignee from '~/boards/models/assignee';
import List from '~/boards/models/list';
import ListMilestone from '~/boards/models/milestone';

class ListEE extends List {
  constructor(...args) {
    super(...args);
    this.totalWeight = args[0]?.totalWeight || 0;
  }

  getIssues(...args) {
    return super.getIssues(...args).then((data) => {
      this.totalWeight = data.total_weight;
    });
  }

  addIssue(issue, ...args) {
    super.addIssue(issue, ...args);

    if (issue.weight) {
      this.totalWeight += issue.weight;
    }
  }

  removeIssue(issue, ...args) {
    if (issue.weight) {
      this.totalWeight -= issue.weight;
    }

    super.removeIssue(issue, ...args);
  }

  addWeight(weight) {
    this.totalWeight += weight;
  }

  onNewIssueResponse(issue, data) {
    issue.milestone = data.milestone ? new ListMilestone(data.milestone) : data.milestone;
    issue.assignees = Array.isArray(data.assignees)
      ? data.assignees.map((assignee) => new ListAssignee(assignee))
      : data.assignees;
    issue.labels = data.labels;

    super.onNewIssueResponse(issue, data);
  }
}

window.List = ListEE;

export default ListEE;
