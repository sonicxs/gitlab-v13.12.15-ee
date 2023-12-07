import { sortBy } from 'lodash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { urlParamsToObject } from '~/lib/utils/common_utils';
import { objectToQuery } from '~/lib/utils/url_utility';
import {
  EPIC_LANE_BASE_HEIGHT,
  IterationFilterType,
  IterationIDs,
  MilestoneFilterType,
  MilestoneIDs,
  WeightFilterType,
  WeightIDs,
} from './constants';

export function getMilestone({ milestone }) {
  return milestone || null;
}

export function fullEpicId(epicId) {
  return `gid://gitlab/Epic/${epicId}`;
}

export function fullMilestoneId(milestoneId) {
  return `gid://gitlab/Milestone/${milestoneId}`;
}

export function fullUserId(userId) {
  return `gid://gitlab/User/${userId}`;
}

export function fullEpicBoardId(epicBoardId) {
  return `gid://gitlab/Boards::EpicBoard/${epicBoardId}`;
}

export function calculateSwimlanesBufferSize(listTopCoordinate) {
  return Math.ceil((window.innerHeight - listTopCoordinate) / EPIC_LANE_BASE_HEIGHT);
}

export function formatListEpics(listEpics) {
  const boardItems = {};
  let listItemsCount;

  const listData = listEpics.nodes.reduce((map, list) => {
    listItemsCount = list.epicsCount;
    let sortedEpics = list.epics.edges.map((epicNode) => ({
      ...epicNode.node,
    }));
    sortedEpics = sortBy(sortedEpics, 'relativePosition');

    return {
      ...map,
      [list.id]: sortedEpics.map((i) => {
        const id = getIdFromGraphQLId(i.id);

        const listEpic = {
          ...i,
          id,
          labels: i.labels?.nodes || [],
          assignees: i.assignees?.nodes || [],
        };

        boardItems[id] = listEpic;

        return id;
      }),
    };
  }, {});

  return { listData, boardItems, listItemsCount };
}

export function formatEpicListsPageInfo(lists) {
  const listData = lists.nodes.reduce((map, list) => {
    return {
      ...map,
      [list.id]: list.epics.pageInfo,
    };
  }, {});
  return listData;
}

export function transformBoardConfig(boardConfig) {
  const updatedBoardConfig = {};
  const passedFilterParams = urlParamsToObject(window.location.search);
  const updateScopeObject = (key, value = '') => {
    if (value === null || value === '') return;
    // Comparing with value string because weight can be a number
    if (!passedFilterParams[key] || passedFilterParams[key] !== value.toString()) {
      updatedBoardConfig[key] = value;
    }
  };

  let { milestoneTitle } = boardConfig;
  if (boardConfig.milestoneId === MilestoneIDs.NONE) {
    milestoneTitle = MilestoneFilterType.none;
  }
  if (milestoneTitle) {
    updateScopeObject('milestone_title', milestoneTitle);
  }

  let { iterationTitle } = boardConfig;
  if (boardConfig.iterationId === IterationIDs.NONE) {
    iterationTitle = IterationFilterType.none;
  }

  if (iterationTitle) {
    updateScopeObject('iteration_id', iterationTitle);
  }

  let { weight } = boardConfig;
  if (weight !== WeightIDs.ANY) {
    if (weight === WeightIDs.NONE) {
      weight = WeightFilterType.none;
    }

    updateScopeObject('weight', weight);
  }

  updateScopeObject('assignee_username', boardConfig.assigneeUsername);

  let updatedFilterPath = objectToQuery(updatedBoardConfig);
  const filterPath = updatedFilterPath ? updatedFilterPath.split('&') : [];

  boardConfig.labels.forEach((label) => {
    const labelTitle = encodeURIComponent(label.title);
    const param = `label_name[]=${labelTitle}`;

    if (!passedFilterParams.label_name?.includes(label.title)) {
      filterPath.push(param);
    }
  });

  updatedFilterPath = filterPath.join('&');
  return updatedFilterPath;
}

export default {
  getMilestone,
  fullEpicId,
  fullMilestoneId,
  fullUserId,
  fullEpicBoardId,
  transformBoardConfig,
};
