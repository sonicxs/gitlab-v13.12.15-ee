import * as getters from 'ee/geo_nodes_beta/store/getters';
import createState from 'ee/geo_nodes_beta/store/state';
import {
  MOCK_PRIMARY_VERSION,
  MOCK_REPLICABLE_TYPES,
  MOCK_NODES,
  MOCK_PRIMARY_VERIFICATION_INFO,
  MOCK_SECONDARY_VERIFICATION_INFO,
  MOCK_SECONDARY_SYNC_INFO,
} from '../mock_data';

describe('GeoNodesBeta Store Getters', () => {
  let state;

  beforeEach(() => {
    state = createState({
      primaryVersion: MOCK_PRIMARY_VERSION.version,
      primaryRevision: MOCK_PRIMARY_VERSION.revision,
      replicableTypes: MOCK_REPLICABLE_TYPES,
    });
  });

  describe('verificationInfo', () => {
    beforeEach(() => {
      state.nodes = MOCK_NODES;
    });

    describe('on primary node', () => {
      it('returns only replicable types that have checksum data', () => {
        expect(getters.verificationInfo(state)(MOCK_NODES[0].id)).toStrictEqual(
          MOCK_PRIMARY_VERIFICATION_INFO,
        );
      });
    });

    describe('on secondary node', () => {
      it('returns only replicable types that have verification data', () => {
        expect(getters.verificationInfo(state)(MOCK_NODES[1].id)).toStrictEqual(
          MOCK_SECONDARY_VERIFICATION_INFO,
        );
      });
    });
  });

  describe('syncInfo', () => {
    beforeEach(() => {
      state.nodes = MOCK_NODES;
    });

    it('returns the nodes sync information', () => {
      expect(getters.syncInfo(state)(MOCK_NODES[1].id)).toStrictEqual(MOCK_SECONDARY_SYNC_INFO);
    });
  });
});
