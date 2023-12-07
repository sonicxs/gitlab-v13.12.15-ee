import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import Vuex from 'vuex';
import { BoardType, GroupByParamType, listsQuery, issuableTypes } from 'ee/boards/constants';
import actions, { gqlClient } from 'ee/boards/stores/actions';
import boardsStoreEE from 'ee/boards/stores/boards_store_ee';
import * as types from 'ee/boards/stores/mutation_types';
import mutations from 'ee/boards/stores/mutations';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import { mockMoveIssueParams, mockMoveData, mockMoveState } from 'jest/boards/mock_data';
import { formatListIssues } from '~/boards/boards_util';
import listsIssuesQuery from '~/boards/graphql/lists_issues.query.graphql';
import * as typesCE from '~/boards/stores/mutation_types';
import * as commonUtils from '~/lib/utils/common_utils';
import { mergeUrlParams, removeParams } from '~/lib/utils/url_utility';
import {
  labels,
  mockLists,
  mockIssue,
  mockIssues,
  mockEpic,
  mockEpic2,
  mockMilestones,
  mockAssignees,
} from '../mock_data';

Vue.use(Vuex);

let mock;

beforeEach(() => {
  mock = new MockAdapter(axios);
  window.gon = { features: {} };
  jest.spyOn(commonUtils, 'historyPushState');
});

afterEach(() => {
  mock.restore();
});

describe('setFilters', () => {
  it('should commit mutation SET_FILTERS, updates epicId with global id', () => {
    const state = {
      filters: {},
    };

    const filters = { labelName: 'label', epicId: 1 };
    const updatedFilters = { labelName: 'label', epicId: 'gid://gitlab/Epic/1', not: {} };

    return testAction(
      actions.setFilters,
      filters,
      state,
      [{ type: types.SET_FILTERS, payload: updatedFilters }],
      [],
    );
  });

  it('should commit mutation SET_FILTERS, updates epicWildcardId', () => {
    const state = {
      filters: {},
    };

    const filters = { labelName: 'label', epicId: 'None' };
    const updatedFilters = { labelName: 'label', epicWildcardId: 'NONE', not: {} };

    return testAction(
      actions.setFilters,
      filters,
      state,
      [{ type: types.SET_FILTERS, payload: updatedFilters }],
      [],
    );
  });

  it('should commit mutation SET_FILTERS, updates iterationWildcardId', () => {
    const state = {
      filters: {},
    };

    const filters = { labelName: 'label', iterationId: 'None' };
    const updatedFilters = { labelName: 'label', iterationWildcardId: 'NONE', not: {} };

    return testAction(
      actions.setFilters,
      filters,
      state,
      [{ type: types.SET_FILTERS, payload: updatedFilters }],
      [],
    );
  });

  it('should commit mutation SET_FILTERS, dispatches setEpicSwimlanes action if filters contain groupBy epic', () => {
    const state = {
      filters: {},
    };

    const filters = { labelName: 'label', epicId: 1, groupBy: 'epic' };
    const updatedFilters = { labelName: 'label', epicId: 'gid://gitlab/Epic/1', not: {} };

    return testAction(
      actions.setFilters,
      filters,
      state,
      [{ type: types.SET_FILTERS, payload: updatedFilters }],
      [{ type: 'setEpicSwimlanes' }],
    );
  });
});

describe('performSearch', () => {
  it('should dispatch setFilters action', (done) => {
    testAction(actions.performSearch, {}, {}, [], [{ type: 'setFilters', payload: {} }], done);
  });

  it('should dispatch setFilters, fetchLists and resetIssues action when graphqlBoardLists FF is on', async () => {
    window.gon = { features: { graphqlBoardLists: true } };
    const getters = { isSwimlanesOn: false };

    await testAction({
      action: actions.performSearch,
      state: { ...getters },
      expectedActions: [
        { type: 'setFilters', payload: {} },
        { type: 'fetchLists' },
        { type: 'resetIssues' },
      ],
    });
  });

  it('should dispatch setFilters, resetEpics, fetchEpicsSwimlanes, fetchLists and resetIssues action when isSwimlanesOn', async () => {
    const getters = { isSwimlanesOn: true };
    await testAction({
      action: actions.performSearch,
      state: { isShowingEpicsSwimlanes: true, ...getters },
      expectedActions: [
        { type: 'setFilters', payload: {} },
        { type: 'resetEpics' },
        { type: 'resetIssues' },
        { type: 'fetchEpicsSwimlanes' },
        { type: 'fetchLists' },
      ],
    });
  });
});

describe('fetchLists', () => {
  const queryResponse = {
    data: {
      group: {
        board: {
          hideBacklogList: true,
          lists: {
            nodes: [mockLists[1]],
          },
        },
      },
    },
  };

  it.each`
    issuableType          | boardType          | fullBoardId                           | isGroup      | isProject
    ${issuableTypes.epic} | ${BoardType.group} | ${'gid://gitlab/Boards::EpicBoard/1'} | ${undefined} | ${undefined}
  `(
    'calls $issuableType query with correct variables',
    async ({ issuableType, boardType, fullBoardId, isGroup, isProject }) => {
      const commit = jest.fn();
      const dispatch = jest.fn();

      const state = {
        fullPath: 'gitlab-org',
        fullBoardId,
        filterParams: {},
        boardType,
        issuableType,
      };

      const variables = {
        query: listsQuery[issuableType].query,
        variables: {
          fullPath: 'gitlab-org',
          boardId: fullBoardId,
          filters: {},
          isGroup,
          isProject,
        },
      };

      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

      await actions.fetchLists({ commit, state, dispatch });

      expect(gqlClient.query).toHaveBeenCalledWith(variables);
    },
  );
});

describe('fetchEpicsSwimlanes', () => {
  const state = {
    fullPath: 'gitlab-org',
    boardId: 1,
    filterParams: {},
    boardType: 'group',
  };

  const queryResponse = {
    data: {
      group: {
        board: {
          epics: {
            edges: [{ node: mockEpic }],
            pageInfo: {},
          },
        },
      },
    },
  };

  it('should commit mutation RECEIVE_EPICS_SUCCESS and UPDATE_CACHED_EPICS on success', (done) => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    testAction(
      actions.fetchEpicsSwimlanes,
      {},
      state,
      [
        {
          type: types.RECEIVE_EPICS_SUCCESS,
          payload: { epics: [mockEpic] },
        },
        {
          type: types.UPDATE_CACHED_EPICS,
          payload: [mockEpic],
        },
      ],
      [],
      done,
    );
  });

  it('should commit mutation RECEIVE_SWIMLANES_FAILURE on failure', (done) => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(Promise.reject());

    testAction(
      actions.fetchEpicsSwimlanes,
      {},
      state,
      [{ type: types.RECEIVE_SWIMLANES_FAILURE }],
      [],
      done,
    );
  });

  it('should dispatch fetchEpicsSwimlanes when page info hasNextPage', (done) => {
    const queryResponseWithNextPage = {
      data: {
        group: {
          board: {
            epics: {
              edges: [{ node: mockEpic }],
              pageInfo: {
                hasNextPage: true,
                endCursor: 'ENDCURSOR',
              },
            },
          },
        },
      },
    };
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponseWithNextPage);

    testAction(
      actions.fetchEpicsSwimlanes,
      {},
      state,
      [
        {
          type: types.RECEIVE_EPICS_SUCCESS,
          payload: { epics: [mockEpic] },
        },
        {
          type: types.UPDATE_CACHED_EPICS,
          payload: [mockEpic],
        },
      ],
      [
        {
          type: 'fetchEpicsSwimlanes',
          payload: { endCursor: 'ENDCURSOR' },
        },
      ],
      done,
    );
  });
});

describe('fetchItemsForList', () => {
  const listId = mockLists[0].id;

  const state = {
    fullPath: 'gitlab-org',
    boardId: '1',
    filterParams: {},
    boardType: 'group',
  };

  const mockIssuesNodes = mockIssues.map((issue) => ({ node: issue }));

  const pageInfo = {
    endCursor: '',
    hasNextPage: false,
  };

  const queryResponse = {
    data: {
      group: {
        board: {
          lists: {
            nodes: [
              {
                id: listId,
                issues: {
                  edges: mockIssuesNodes,
                  pageInfo,
                },
              },
            ],
          },
        },
      },
    },
  };

  const formattedIssues = formatListIssues(queryResponse.data.group.board.lists);

  const listPageInfo = {
    [listId]: pageInfo,
  };

  it('add epicWildcardId with ANY as value when forSwimlanes is true', () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    testAction(
      actions.fetchItemsForList,
      { listId, forSwimlanes: true },
      state,
      [
        {
          type: types.REQUEST_ITEMS_FOR_LIST,
          payload: { listId, fetchNext: false },
        },
        {
          type: types.RECEIVE_ITEMS_FOR_LIST_SUCCESS,
          payload: { listItems: formattedIssues, listPageInfo, listId, noEpicIssues: false },
        },
      ],
      [],
      () => {
        expect(gqlClient.query).toHaveBeenCalledWith({
          query: listsIssuesQuery,
          variables: {
            boardId: 'gid://gitlab/Board/1',
            filters: {
              epicWildcardId: 'ANY',
            },
            fullPath: 'gitlab-org',
            id: 'gid://gitlab/List/1',
            isGroup: true,
            isProject: false,
          },
          context: {
            isSingleRequest: true,
          },
        });
      },
    );
  });
});

describe('updateBoardEpicUserPreferences', () => {
  const state = {
    boardId: 1,
  };

  const queryResponse = (collapsed = false) => ({
    data: {
      updateBoardEpicUserPreferences: {
        errors: [],
        epicUserPreferences: { collapsed },
      },
    },
  });

  it('should send mutation', (done) => {
    const collapsed = true;
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue(queryResponse(collapsed));

    testAction(
      actions.updateBoardEpicUserPreferences,
      { epicId: mockEpic.id, collapsed },
      state,
      [
        {
          payload: {
            epicId: mockEpic.id,
            userPreferences: {
              collapsed,
            },
          },
          type: types.SET_BOARD_EPIC_USER_PREFERENCES,
        },
      ],
      [],
      done,
    );
  });
});

describe('setShowLabels', () => {
  it('should commit mutation SET_SHOW_LABELS', (done) => {
    const state = {
      isShowingLabels: true,
    };

    testAction(
      actions.setShowLabels,
      false,
      state,
      [{ type: types.SET_SHOW_LABELS, payload: false }],
      [],
      done,
    );
  });
});

describe('updateListWipLimit', () => {
  let storeMock;
  const getters = { shouldUseGraphQL: false };

  beforeEach(() => {
    storeMock = {
      state: { endpoints: { listsEndpoint: '/test' } },
      create: () => {},
      setCurrentBoard: () => {},
    };

    boardsStoreEE.initEESpecific(storeMock);
    jest.mock('axios');
    axios.put = jest.fn();
    axios.put.mockResolvedValue({ data: {} });
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('axios - should call the correct url', () => {
    const maxIssueCount = 0;
    const activeId = 1;

    return actions
      .updateListWipLimit({ state: { activeId }, getters }, { maxIssueCount, listId: activeId })
      .then(() => {
        expect(axios.put).toHaveBeenCalledWith(
          `${boardsStoreEE.store.state.endpoints.listsEndpoint}/${activeId}`,
          {
            list: { max_issue_count: maxIssueCount },
          },
        );
      });
  });

  it('graphql - commit UPDATE_LIST_SUCCESS mutation on success', () => {
    const maxIssueCount = 0;
    const activeId = 1;
    getters.shouldUseGraphQL = true;
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        boardListUpdateLimitMetrics: {
          list: {
            id: activeId,
          },
          errors: [],
        },
      },
    });

    return testAction(
      actions.updateListWipLimit,
      { maxIssueCount, listId: activeId },
      { isShowingEpicsSwimlanes: true, ...getters },
      [
        {
          type: types.UPDATE_LIST_SUCCESS,
          payload: {
            listId: activeId,
            list: expect.objectContaining({
              id: activeId,
            }),
          },
        },
      ],
      [],
    );
  });

  it('graphql - commit UPDATE_LIST_FAILURE mutation on failure', () => {
    const maxIssueCount = 0;
    const activeId = 1;
    getters.shouldUseGraphQL = true;
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue(Promise.reject());

    return testAction(
      actions.updateListWipLimit,
      { maxIssueCount, listId: activeId },
      { isShowingEpicsSwimlanes: true, ...getters },
      [{ type: types.UPDATE_LIST_FAILURE }],
      [],
    );
  });
});

describe('toggleEpicSwimlanes', () => {
  it('should commit mutation TOGGLE_EPICS_SWIMLANES', () => {
    const startURl = `${TEST_HOST}/groups/gitlab-org/-/boards/1?group_by=epic`;
    global.jsdom.reconfigure({
      url: startURl,
    });

    const state = {
      isShowingEpicsSwimlanes: false,
      fullPath: 'gitlab-org',
      boardId: 1,
    };

    return testAction(
      actions.toggleEpicSwimlanes,
      null,
      state,
      [{ type: types.TOGGLE_EPICS_SWIMLANES }],
      [],
      () => {
        expect(commonUtils.historyPushState).toHaveBeenCalledWith(
          removeParams(['group_by']),
          startURl,
          true,
        );
        expect(global.window.location.href).toBe(`${TEST_HOST}/groups/gitlab-org/-/boards/1`);
      },
    );
  });

  it('should dispatch fetchEpicsSwimlanes and fetchLists actions when isShowingEpicsSwimlanes is true', () => {
    global.jsdom.reconfigure({
      url: `${TEST_HOST}/groups/gitlab-org/-/boards/1`,
    });

    jest.spyOn(gqlClient, 'query').mockResolvedValue({});

    const state = {
      isShowingEpicsSwimlanes: true,
      fullPath: 'gitlab-org',
      boardId: 1,
    };

    return testAction(
      actions.toggleEpicSwimlanes,
      null,
      state,
      [{ type: types.TOGGLE_EPICS_SWIMLANES }],
      [{ type: 'fetchEpicsSwimlanes' }, { type: 'fetchLists' }],
      () => {
        expect(commonUtils.historyPushState).toHaveBeenCalledWith(
          mergeUrlParams({ group_by: GroupByParamType.epic }, window.location.href),
        );
        expect(global.window.location.href).toBe(
          `${TEST_HOST}/groups/gitlab-org/-/boards/1?group_by=epic`,
        );
      },
    );
  });
});

describe('setEpicSwimlanes', () => {
  it('should commit mutation SET_EPICS_SWIMLANES', () => {
    return testAction(
      actions.setEpicSwimlanes,
      null,
      {},
      [{ type: types.SET_EPICS_SWIMLANES }],
      [],
    );
  });
});

describe('doneLoadingSwimlanesItems', () => {
  it('should commit mutation DONE_LOADING_SWIMLANES_ITEMS', () => {
    return testAction(
      actions.doneLoadingSwimlanesItems,
      null,
      {},
      [{ type: types.DONE_LOADING_SWIMLANES_ITEMS }],
      [],
    );
  });
});

describe('resetEpics', () => {
  it('commits RESET_EPICS mutation', () => {
    return testAction(actions.resetEpics, {}, {}, [{ type: types.RESET_EPICS }], []);
  });
});

describe('fetchEpicForActiveIssue', () => {
  const assignedEpic = {
    ...mockIssue.epic,
  };

  describe("when active issue doesn't have an assigned epic", () => {
    const getters = { activeBoardItem: { ...mockIssue, epic: null } };

    it('should not fetch any epic', async () => {
      await testAction(actions.fetchEpicForActiveIssue, undefined, { ...getters }, [], []);
    });
  });

  describe("when active issue doesn't have the full epic information", () => {
    // Edge Case: when user drops/moves a card onto an epic swimlane,
    // until IssueMoveList request is completed, the issue item only has epic id.
    // This causes a problem when user also has the sidebar open because
    // board_sidebar_epic_select watches for the issue item's `epic` field
    // and tries to extract epic id, epic iid and fullpath to request for detailed epic info.
    const getters = { activeBoardItem: { ...mockIssue, epic: { id: 'something' } } };

    it('should not fetch any epic', async () => {
      await testAction(actions.fetchEpicForActiveIssue, undefined, { ...getters }, [], []);
    });
  });

  describe('when the assigned epic for active issue is found in state.epicsCacheById', () => {
    const getters = { activeBoardItem: { ...mockIssue, epic: assignedEpic } };
    const state = { epicsCacheById: { [assignedEpic.id]: assignedEpic } };

    it('should not fetch any epic', async () => {
      await testAction(
        actions.fetchEpicForActiveIssue,
        undefined,
        { ...state, ...getters },
        [],
        [],
      );
    });
  });

  describe('when fetching fails', () => {
    const getters = { activeBoardItem: { ...mockIssue, epic: assignedEpic } };
    const state = { epicsCacheById: {} };

    it('should not commit UPDATE_CACHED_EPICS mutation and should throw an error', () => {
      const mockError = new Error('mayday');
      jest.spyOn(gqlClient, 'query').mockRejectedValue(mockError);

      return testAction(
        actions.fetchEpicForActiveIssue,
        undefined,
        { ...state, ...getters },
        [
          {
            type: types.SET_EPIC_FETCH_IN_PROGRESS,
            payload: true,
          },
          {
            type: types.SET_EPIC_FETCH_IN_PROGRESS,
            payload: false,
          },
        ],
        [],
      ).catch((e) => {
        expect(e).toEqual(mockError);
      });
    });
  });

  describe("when the assigned epic for active issue isn't found in state.epicsCacheById", () => {
    const getters = { activeBoardItem: { ...mockIssue, epic: assignedEpic } };
    const state = { epicsCacheById: {} };

    it('should commit mutation SET_EPIC_FETCH_IN_PROGRESS before and after committing mutation UPDATE_CACHED_EPICS', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue({ data: { group: { epic: mockEpic } } });

      await testAction(
        actions.fetchEpicForActiveIssue,
        undefined,
        { ...state, ...getters },
        [
          {
            type: types.SET_EPIC_FETCH_IN_PROGRESS,
            payload: true,
          },
          {
            type: types.UPDATE_CACHED_EPICS,
            payload: [mockEpic],
          },
          {
            type: types.SET_EPIC_FETCH_IN_PROGRESS,
            payload: false,
          },
        ],
        [],
      );
    });
  });
});

describe('setActiveIssueEpic', () => {
  const state = {
    epics: [{ id: 'gid://gitlab/Epic/422', iid: 99, title: 'existing epic' }],
  };
  const getters = { activeBoardItem: { ...mockIssue, projectPath: 'h/b' } };

  describe('when the updated issue has an assigned epic', () => {
    it('should commit mutation RECEIVE_EPICS_SUCCESS, UPDATE_CACHED_EPICS and UPDATE_BOARD_ITEM_BY_ID on success', async () => {
      jest
        .spyOn(gqlClient, 'mutate')
        .mockResolvedValue({ data: { issueSetEpic: { issue: { epic: mockEpic2 } } } });

      await testAction(
        actions.setActiveIssueEpic,
        mockEpic2.id,
        { ...state, ...getters },
        [
          {
            type: types.SET_EPIC_FETCH_IN_PROGRESS,
            payload: true,
          },
          {
            type: types.RECEIVE_EPICS_SUCCESS,
            payload: { epics: [mockEpic2, ...state.epics] },
          },
          {
            type: types.UPDATE_CACHED_EPICS,
            payload: [mockEpic2],
          },
          {
            type: typesCE.UPDATE_BOARD_ITEM_BY_ID,
            payload: {
              itemId: mockIssue.id,
              prop: 'epic',
              value: { id: mockEpic2.id, iid: mockEpic2.iid, group: mockEpic2.group },
            },
          },
          {
            type: types.SET_EPIC_FETCH_IN_PROGRESS,
            payload: false,
          },
        ],
        [],
      );
    });
  });

  describe('when the updated issue does not have an epic (unassigned)', () => {
    it('should only commit UPDATE_BOARD_ITEM_BY_ID on success', async () => {
      jest
        .spyOn(gqlClient, 'mutate')
        .mockResolvedValue({ data: { issueSetEpic: { issue: { epic: null } } } });

      await testAction(
        actions.setActiveIssueEpic,
        null,
        { ...state, ...getters },
        [
          {
            type: types.SET_EPIC_FETCH_IN_PROGRESS,
            payload: true,
          },
          {
            type: typesCE.UPDATE_BOARD_ITEM_BY_ID,
            payload: { itemId: mockIssue.id, prop: 'epic', value: null },
          },
          {
            type: types.SET_EPIC_FETCH_IN_PROGRESS,
            payload: false,
          },
        ],
        [],
      );
    });
  });

  it('throws error if fails', async () => {
    jest
      .spyOn(gqlClient, 'mutate')
      .mockResolvedValue({ data: { issueSetEpic: { errors: ['failed mutation'] } } });

    await expect(actions.setActiveIssueEpic({ getters }, mockEpic2.id)).rejects.toThrow(Error);
  });
});

describe('setActiveIssueWeight', () => {
  const state = { boardItems: { [mockIssue.id]: mockIssue } };
  const getters = { activeBoardItem: mockIssue };
  const testWeight = mockIssue.weight + 1;
  const input = {
    weight: testWeight,
    projectPath: 'h/b',
  };

  it('should commit weight after setting the issue', (done) => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        issueSetWeight: {
          issue: {
            weight: testWeight,
          },
          errors: [],
        },
      },
    });

    const payload = {
      itemId: getters.activeBoardItem.id,
      prop: 'weight',
      value: testWeight,
    };

    testAction(
      actions.setActiveIssueWeight,
      input,
      { ...state, ...getters },
      [
        {
          type: typesCE.UPDATE_BOARD_ITEM_BY_ID,
          payload,
        },
      ],
      [],
      done,
    );
  });

  it('throws error if fails', async () => {
    jest
      .spyOn(gqlClient, 'mutate')
      .mockResolvedValue({ data: { issueSetWeight: { errors: ['failed mutation'] } } });

    await expect(actions.setActiveIssueWeight({ getters }, input)).rejects.toThrow(Error);
  });
});

describe.each`
  isEpicBoard | issuableType             | dispatchedAction
  ${false}    | ${'issuableTypes.issue'} | ${'moveIssue'}
  ${true}     | ${'issuableTypes.epic'}  | ${'moveEpic'}
`('moveItem', ({ isEpicBoard, issuableType, dispatchedAction }) => {
  it(`should dispatch ${dispatchedAction}  action when isEpicBoard is ${isEpicBoard}`, async () => {
    await testAction({
      action: actions.moveItem,
      payload: { itemId: 1 },
      state: { isEpicBoard, issuableType },
      expectedActions: [{ type: dispatchedAction, payload: { itemId: 1 } }],
    });
  });
});

describe('moveIssue', () => {
  it('should dispatch a correct set of actions with epic id', () => {
    const params = mockMoveIssueParams;

    const moveData = {
      ...mockMoveData,
      epicId: 'some-epic-id',
    };

    testAction({
      action: actions.moveIssue,
      payload: {
        ...params,
        epicId: 'some-epic-id',
      },
      state: mockMoveState,
      expectedActions: [
        { type: 'moveIssueCard', payload: moveData },
        { type: 'updateMovedIssue', payload: moveData },
        { type: 'updateEpicForIssue', payload: { itemId: params.itemId, epicId: 'some-epic-id' } },
        {
          type: 'updateIssueOrder',
          payload: {
            moveData,
            mutationVariables: {
              epicId: 'some-epic-id',
            },
          },
        },
      ],
    });
  });
});

describe('updateEpicForIssue', () => {
  let commonState;

  beforeEach(() => {
    commonState = {
      boardItems: {
        itemId: {
          id: 'issueId',
        },
      },
    };
  });

  it.each([
    [
      'with epic id',
      {
        payload: {
          itemId: 'itemId',
          epicId: 'epicId',
        },
        expectedMutations: [
          {
            type: types.UPDATE_BOARD_ITEM_BY_ID,
            payload: { itemId: 'issueId', prop: 'epic', value: { id: 'epicId' } },
          },
        ],
      },
    ],
    [
      'with null as epic id',
      {
        payload: {
          itemId: 'itemId',
          epicId: null,
        },
        expectedMutations: [
          {
            type: types.UPDATE_BOARD_ITEM_BY_ID,
            payload: { itemId: 'issueId', prop: 'epic', value: null },
          },
        ],
      },
    ],
  ])(`commits UPDATE_BOARD_ITEM_BY_ID mutation %s`, (_, { payload, expectedMutations }) => {
    testAction({
      action: actions.updateEpicForIssue,
      payload,
      state: commonState,
      expectedMutations,
    });
  });
});

describe.each`
  isEpicBoard | issuableType             | dispatchedAction
  ${false}    | ${'issuableTypes.issue'} | ${'createIssueList'}
  ${true}     | ${'issuableTypes.epic'}  | ${'createEpicList'}
`('createList', ({ isEpicBoard, issuableType, dispatchedAction }) => {
  it(`should dispatch ${dispatchedAction}  action when isEpicBoard is ${isEpicBoard}`, async () => {
    await testAction({
      action: actions.createList,
      payload: { backlog: true },
      state: { isEpicBoard, issuableType },
      expectedActions: [{ type: dispatchedAction, payload: { backlog: true } }],
    });
  });
});

describe('createEpicList', () => {
  let commit;
  let dispatch;
  let getters;

  const state = {
    fullPath: 'gitlab-org',
    boardId: 1,
    boardType: 'group',
    disabled: false,
    boardLists: mockLists,
  };

  beforeEach(() => {
    commit = jest.fn();
    dispatch = jest.fn();
    getters = {
      getListByLabelId: jest.fn(),
    };
  });

  it('should dispatch addList action when creating backlog list', async () => {
    const backlogList = {
      id: 'gid://gitlab/List/1',
      listType: 'backlog',
      title: 'Open',
      position: 0,
    };

    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        epicBoardListCreate: {
          list: backlogList,
          errors: [],
        },
      },
    });

    await actions.createEpicList({ getters, state, commit, dispatch }, { backlog: true });

    expect(dispatch).toHaveBeenCalledWith('addList', backlogList);
  });

  it('dispatches highlightList after addList has succeeded', async () => {
    const list = {
      id: 'gid://gitlab/List/1',
      listType: 'label',
      title: 'Open',
      labelId: '4',
    };

    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        epicBoardListCreate: {
          list,
          errors: [],
        },
      },
    });

    await actions.createEpicList({ getters, state, commit, dispatch }, { labelId: '4' });

    expect(dispatch).toHaveBeenCalledWith('addList', list);
    expect(dispatch).toHaveBeenCalledWith('highlightList', list.id);
  });

  it('should commit CREATE_LIST_FAILURE mutation when API returns an error', async () => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        epicBoardListCreate: {
          list: {},
          errors: ['foo'],
        },
      },
    });

    await actions.createEpicList({ getters, state, commit, dispatch }, { backlog: true });

    expect(commit).toHaveBeenCalledWith(types.CREATE_LIST_FAILURE, 'foo');
  });

  it('highlights list and does not re-query if it already exists', async () => {
    const existingList = {
      id: 'gid://gitlab/List/1',
      listType: 'label',
      title: 'Some label',
      position: 1,
    };

    getters = {
      getListByLabelId: jest.fn().mockReturnValue(existingList),
    };

    await actions.createEpicList({ getters, state, commit, dispatch }, { backlog: true });

    expect(dispatch).toHaveBeenCalledWith('highlightList', existingList.id);
    expect(dispatch).toHaveBeenCalledTimes(1);
    expect(commit).not.toHaveBeenCalled();
  });
});

describe('fetchMilestones', () => {
  const queryResponse = {
    data: {
      project: {
        milestones: {
          nodes: mockMilestones,
        },
      },
    },
  };

  const queryErrors = {
    data: {
      project: {
        errors: ['You cannot view these milestones'],
        milestones: {},
      },
    },
  };

  function createStore({
    state = {
      boardType: 'project',
      fullPath: 'gitlab-org/gitlab',
      milestones: [],
      milestonesLoading: false,
    },
  } = {}) {
    return new Vuex.Store({
      state,
      mutations,
    });
  }

  it('throws error if state.boardType is not group or project', () => {
    const store = createStore({
      state: {
        boardType: 'invalid',
      },
    });

    expect(() => actions.fetchMilestones(store)).toThrow(new Error('Unknown board type'));
  });

  it('sets milestonesLoading to true', async () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    const store = createStore();

    actions.fetchMilestones(store);

    expect(store.state.milestonesLoading).toBe(true);
  });

  describe('success', () => {
    it('sets state.milestones from query result', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

      const store = createStore();

      await actions.fetchMilestones(store);

      expect(store.state.milestonesLoading).toBe(false);
      expect(store.state.milestones).toBe(mockMilestones);
    });
  });

  describe('failure', () => {
    it('sets state.milestones from query result', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryErrors);

      const store = createStore();

      await expect(actions.fetchMilestones(store)).rejects.toThrow();

      expect(store.state.milestonesLoading).toBe(false);
      expect(store.state.error).toBe('Failed to load milestones.');
    });
  });
});

describe('fetchIterations', () => {
  const queryResponse = {
    data: {
      group: {
        iterations: {
          nodes: mockMilestones,
        },
      },
    },
  };

  const queryErrors = {
    data: {
      group: {
        errors: ['You cannot view these iterations'],
        iterations: {},
      },
    },
  };

  function createStore({
    state = {
      boardType: 'group',
      fullPath: 'gitlab-org/gitlab',
      iterations: [],
      iterationsLoading: false,
    },
  } = {}) {
    return new Vuex.Store({
      state,
      mutations,
    });
  }

  it('sets iterationsLoading to true', () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    const store = createStore();

    actions.fetchIterations(store);

    expect(store.state.iterationsLoading).toBe(true);
  });

  describe('success', () => {
    it('sets state.iterations from query result', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

      const store = createStore();

      await actions.fetchIterations(store);

      expect(store.state.iterationsLoading).toBe(false);
      expect(store.state.iterations).toBe(mockMilestones);
    });
  });

  describe('failure', () => {
    it('throws an error and displays an error message', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryErrors);

      const store = createStore();

      await expect(actions.fetchIterations(store)).rejects.toThrow();

      expect(store.state.iterationsLoading).toBe(false);
      expect(store.state.error).toBe('Failed to load iterations.');
    });
  });
});

describe('fetchAssignees', () => {
  const queryResponse = {
    data: {
      workspace: {
        assignees: {
          nodes: mockAssignees.map((assignee) => ({ user: assignee })),
        },
      },
    },
  };

  const queryErrors = {
    data: {
      project: {
        errors: ['You cannot view these assignees'],
        assignees: {},
      },
    },
  };

  function createStore({
    state = {
      boardType: 'project',
      fullPath: 'gitlab-org/gitlab',
      assignees: [],
      assigneesLoading: false,
    },
  } = {}) {
    return new Vuex.Store({
      state,
      mutations,
    });
  }

  it('throws error if state.boardType is not group or project', () => {
    const store = createStore({
      state: {
        boardType: 'invalid',
      },
    });

    expect(() => actions.fetchAssignees(store)).toThrow(new Error('Unknown board type'));
  });

  it('sets assigneesLoading to true', async () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    const store = createStore();

    actions.fetchAssignees(store);

    expect(store.state.assigneesLoading).toBe(true);
  });

  describe('success', () => {
    it('sets state.assignees from query result', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

      const store = createStore();

      await actions.fetchAssignees(store);

      expect(store.state.assigneesLoading).toBe(false);
      expect(store.state.assignees).toEqual(expect.objectContaining(mockAssignees));
    });
  });

  describe('failure', () => {
    it('throws an error and displays an error message', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryErrors);

      const store = createStore();

      await expect(actions.fetchAssignees(store)).rejects.toThrow();

      expect(store.state.assigneesLoading).toBe(false);
      expect(store.state.error).toBe('Failed to load assignees.');
    });
  });
});

describe('setActiveEpicLabels', () => {
  const state = { boardItems: { [mockEpic.id]: mockEpic } };
  const getters = { activeBoardItem: mockEpic };
  const testLabelIds = labels.map((label) => label.id);
  const input = {
    addLabelIds: testLabelIds,
    removeLabelIds: [],
    groupPath: 'h/b',
  };

  it('should assign labels on success', (done) => {
    jest
      .spyOn(gqlClient, 'mutate')
      .mockResolvedValue({ data: { updateEpic: { epic: { labels: { nodes: labels } } } } });

    const payload = {
      itemId: getters.activeBoardItem.id,
      prop: 'labels',
      value: labels,
    };

    testAction(
      actions.setActiveEpicLabels,
      input,
      { ...state, ...getters },
      [
        {
          type: typesCE.UPDATE_BOARD_ITEM_BY_ID,
          payload,
        },
      ],
      [],
      done,
    );
  });

  it('throws error if fails', async () => {
    jest
      .spyOn(gqlClient, 'mutate')
      .mockResolvedValue({ data: { updateEpic: { errors: ['failed mutation'] } } });

    await expect(actions.setActiveEpicLabels({ getters }, input)).rejects.toThrow(Error);
  });
});
