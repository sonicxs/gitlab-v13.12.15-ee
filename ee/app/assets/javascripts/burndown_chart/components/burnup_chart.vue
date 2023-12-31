<script>
import { GlResizeObserverDirective as GlResizeObserver } from '@gitlab/ui';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import dateFormat from 'dateformat';
import { merge } from 'lodash';
import { __, n__, sprintf } from '~/locale';
import commonChartOptions from './common_chart_options';

export default {
  directives: {
    GlResizeObserver,
  },
  components: {
    GlLineChart,
  },
  props: {
    startDate: {
      type: String,
      required: true,
    },
    dueDate: {
      type: String,
      required: true,
    },
    issuesSelected: {
      type: Boolean,
      required: false,
      default: true,
    },
    burnupData: {
      type: Array,
      required: false,
      default: () => [],
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      tooltip: {
        title: '',
        content: '',
      },
    };
  },
  computed: {
    scopeCount() {
      return this.transform('scopeCount');
    },
    completedCount() {
      return this.transform('completedCount');
    },
    scopeWeight() {
      return this.transform('scopeWeight');
    },
    completedWeight() {
      return this.transform('completedWeight');
    },
    dataSeries() {
      const series = [
        {
          name: __('Total'),
          data: this.issuesSelected ? this.scopeCount : this.scopeWeight,
        },
        {
          name: __('Completed'),
          data: this.issuesSelected ? this.completedCount : this.completedWeight,
        },
      ];

      return series;
    },
    options() {
      return merge({}, commonChartOptions, {
        xAxis: {
          min: this.startDate,
          max: this.dueDate,
        },
        yAxis: {
          name: __('Total issues'),
        },
      });
    },
  },

  methods: {
    setChart(chart) {
      this.chart = chart;
    },
    onResize() {
      this.chart?.resize();
    },
    // transform the object to a chart-friendly array of date + value
    transform(key) {
      return this.burnupData.map((val) => [val.date, val[key]]);
    },
    formatTooltipText(params) {
      const [total, completed] = params.seriesData;
      if (!total || !completed) {
        return;
      }

      this.tooltip.title = dateFormat(params.value, 'dd mmm yyyy');

      const count = total.value[1];
      const completedCount = completed.value[1];

      let totalText = n__('%d open issue', '%d open issues', count);
      let completedText = n__('%d completed issue', '%d completed issues', completedCount);

      if (!this.issuesSelected) {
        totalText = sprintf(__('%{count} total weight'), { count });
        completedText = sprintf(__('%{completedCount} completed weight'), { completedCount });
      }

      this.tooltip.total = totalText;
      this.tooltip.completed = completedText;
    },
  },
};
</script>

<template>
  <div data-qa-selector="burnup_chart">
    <div class="burndown-header d-flex align-items-center">
      <h3>{{ __('Burnup chart') }}</h3>
    </div>
    <gl-line-chart
      v-if="!loading"
      v-gl-resize-observer="onResize"
      class="js-burnup-chart"
      :data="dataSeries"
      :option="options"
      :format-tooltip-text="formatTooltipText"
      :include-legend-avg-max="false"
      @created="setChart"
    >
      <template slot="tooltip-title">{{ tooltip.title }}</template>
      <template slot="tooltip-content">
        <div>{{ tooltip.total }}</div>
        <div>{{ tooltip.completed }}</div>
      </template>
    </gl-line-chart>
  </div>
</template>
