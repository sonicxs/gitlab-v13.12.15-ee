import Vue from 'vue';
import CommitPipelinesTable from './pipelines_table.vue';

/**
 * Used in:
 *  - Project Pipelines List (projects:pipelines:index)
 *  - Commit details View > Pipelines Tab > Pipelines Table (projects:commit:pipelines)
 *  - Merge request details View > Pipelines Tab > Pipelines Table (projects:merge_requests:show)
 *  - New merge request View > Pipelines Tab > Pipelines Table (projects:merge_requests:creations:new)
 */
export default () => {
  const pipelineTableViewEl = document.querySelector('#commit-pipeline-table-view');

  if (pipelineTableViewEl) {
    // Update MR and Commits tabs
    pipelineTableViewEl.addEventListener('update-pipelines-count', (event) => {
      if (
        event.detail.pipelines &&
        event.detail.pipelines.count &&
        event.detail.pipelines.count.all
      ) {
        const badge = document.querySelector('.js-pipelines-mr-count');

        badge.textContent = event.detail.pipelines.count.all;
      }
    });

    if (pipelineTableViewEl.dataset.disableInitialization === undefined) {
      const table = new Vue({
        provide: {
          artifactsEndpoint: pipelineTableViewEl.dataset.artifactsEndpoint,
          artifactsEndpointPlaceholder: pipelineTableViewEl.dataset.artifactsEndpointPlaceholder,
        },
        render(createElement) {
          return createElement(CommitPipelinesTable, {
            props: {
              endpoint: pipelineTableViewEl.dataset.endpoint,
              emptyStateSvgPath: pipelineTableViewEl.dataset.emptyStateSvgPath,
              errorStateSvgPath: pipelineTableViewEl.dataset.errorStateSvgPath,
            },
          });
        },
      }).$mount();
      pipelineTableViewEl.appendChild(table.$el);
    }
  }
};
