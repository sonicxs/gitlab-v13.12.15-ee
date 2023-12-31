# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::DataCollector do
  let_it_be(:user) { create(:user) }

  let(:current_time) { Time.new(2019, 6, 1) }

  around do |example|
    Timecop.freeze(current_time) { example.run }
  end

  def round_to_days(seconds)
    seconds.fdiv(1.day.to_i).round
  end

  # Setting up test data for a stage depends on the `start_event_identifier` and
  # `end_event_identifier` attributes. Since stages can be customized, the test
  # uses two methods for the data preparaton: `create_data_for_start_event` and
  # `create_data_for_end_event`. For each stage we create 3 records with a fixed
  # durations (10, 5, 15 days) in order to easily generalize the test cases.
  shared_examples 'custom Value Stream Analytics Stage' do
    let(:params) { { from: Time.new(2019), to: Time.new(2020), current_user: user } }
    let(:data_collector) { described_class.new(stage: stage, params: params) }
    let_it_be(:resource_1_end_time) { Time.new(2019, 3, 15) }
    let_it_be(:resource_2_end_time) { Time.new(2019, 3, 10) }
    let_it_be(:resource_3_end_time) { Time.new(2019, 3, 20) }

    let_it_be(:resource1) do
      # takes 10 days
      resource = travel_to(Time.new(2019, 3, 5)) do
        create_data_for_start_event(self)
      end

      travel_to(resource_1_end_time) do
        create_data_for_end_event(resource, self)
      end

      resource
    end

    let_it_be(:resource2) do
      # takes 5 days
      resource = travel_to(Time.new(2019, 3, 5)) do
        create_data_for_start_event(self)
      end

      travel_to(resource_2_end_time) do
        create_data_for_end_event(resource, self)
      end

      resource
    end

    let_it_be(:resource3) do
      # takes 15 days
      resource = travel_to(Time.new(2019, 3, 5)) do
        create_data_for_start_event(self)
      end

      travel_to(resource_3_end_time) do
        create_data_for_end_event(resource, self)
      end

      resource
    end

    let_it_be(:unfinished_resource_1_start_time) { Time.new(2019, 3, 5) }
    let_it_be(:unfinished_resource_2_start_time) { Time.new(2019, 5, 10) }

    let_it_be(:unfinished_resource_1) do
      travel_to(unfinished_resource_1_start_time) do
        create_data_for_start_event(self)
      end
    end

    let_it_be(:unfinished_resource_2) do
      travel_to(unfinished_resource_2_start_time) do
        create_data_for_start_event(self)
      end
    end

    it 'loads serialized records' do
      items = data_collector.serialized_records
      expect(items.size).to eq(3)
    end

    context 'when sorting by duration' do
      before do
        params[:sort] = :duration
        params[:direction] = :desc
      end

      it 'returns serialized records sorted by duration DESC' do
        expected_ordered_iids = [resource3.iid, resource1.iid, resource2.iid]

        iids = data_collector.serialized_records.map { |record| record[:iid].to_i }
        expect(iids).to eq(expected_ordered_iids)
      end
    end

    it 'calculates median' do
      expect(round_to_days(data_collector.median.seconds)).to eq(10)
    end

    describe '#duration_chart_data' do
      subject { data_collector.duration_chart_data }

      it 'loads data ordered by event time' do
        days = subject.map { |item| round_to_days(item.duration_in_seconds) }

        expect(days).to eq([15, 10, 5])
      end
    end

    describe '#duration_chart_average_data' do
      subject { data_collector.duration_chart_average_data }

      it 'loads data ordered by event time' do
        data = subject.map { |item| [item.date, round_to_days(item.average_duration_in_seconds)] }

        expect(Hash[data]).to eq({
          resource_1_end_time.utc.to_date => 10,
          resource_2_end_time.utc.to_date => 5,
          resource_3_end_time.utc.to_date => 15
        })
      end
    end

    describe '#count' do
      subject(:count) { data_collector.count }

      it { is_expected.to eq(3) }
    end

    context 'when filtering in progress items' do
      before do
        params[:end_event_filter] = :in_progress
      end

      describe '#count' do
        subject(:count) { data_collector.count }

        it { is_expected.to eq(2) }
      end

      it 'calculates median' do
        duration_1 = current_time - unfinished_resource_1_start_time
        duration_2 = current_time - unfinished_resource_2_start_time

        expected_median = (duration_1 + duration_2).fdiv(2)

        expect(round_to_days(data_collector.median.seconds)).to eq(round_to_days(expected_median))
      end

      it 'loads serialized records' do
        items = data_collector.serialized_records
        expect(items.size).to eq(2)
      end
    end
  end

  shared_examples 'test various start and end event combinations' do
    context 'when `Issue` based stage is given' do
      context 'between issue creation time and issue first mentioned in commit time' do
        let(:start_event_identifier) { :issue_created }
        let(:end_event_identifier) { :issue_first_mentioned_in_commit }

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project)
        end

        def create_data_for_end_event(issue, example_class)
          issue.metrics.update!(first_mentioned_in_commit_at: Time.now)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between issue creation time and closing time' do
        let(:start_event_identifier) { :issue_created }
        let(:end_event_identifier) { :issue_closed }

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project)
        end

        def create_data_for_end_event(resource, example_class)
          resource.close!
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between issue first mentioned in commit and first associated with milestone time' do
        let(:start_event_identifier) { :issue_first_mentioned_in_commit }
        let(:end_event_identifier) { :issue_first_associated_with_milestone }

        def create_data_for_start_event(example_class)
          issue = create(:issue, :opened, project: example_class.project)
          issue.metrics.update!(first_mentioned_in_commit_at: Time.now)
          issue
        end

        def create_data_for_end_event(resource, example_class)
          resource.metrics.update!(first_associated_with_milestone_at: Time.now)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between issue creation time and first added to board time' do
        let(:start_event_identifier) { :issue_created }
        let(:end_event_identifier) { :issue_first_added_to_board }

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project)
        end

        def create_data_for_end_event(resource, example_class)
          resource.metrics.update!(first_added_to_board_at: Time.now)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between issue creation time and last edit time' do
        let(:start_event_identifier) { :issue_created }
        let(:end_event_identifier) { :issue_last_edited }

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project)
        end

        def create_data_for_end_event(resource, example_class)
          resource.update!(last_edited_at: Time.now)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between issue label added time and label removed time' do
        let(:start_event_identifier) { :issue_label_added }
        let(:end_event_identifier) { :issue_label_removed }

        before do
          stage.start_event_label = label
          stage.end_event_label = label
        end

        def create_data_for_start_event(example_class)
          issue = create(:issue, :opened, project: example_class.project)

          Sidekiq::Worker.skipping_transaction_check do
            Issues::UpdateService.new(
              project: example_class.project,
              current_user: user,
              params: { label_ids: [example_class.label.id] }
            ).execute(issue)
          end

          issue
        end

        def create_data_for_end_event(resource, example_class)
          Issues::UpdateService.new(
            project: example_class.project,
            current_user: user,
            params: { label_ids: [] }
          ).execute(resource)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between issue label added time and another issue label added time' do
        let(:start_event_identifier) { :issue_label_added }
        let(:end_event_identifier) { :issue_label_added }

        before do
          stage.start_event_label = label
          stage.end_event_label = other_label
        end

        def create_data_for_start_event(example_class)
          issue = create(:issue, :opened, project: example_class.project)

          Sidekiq::Worker.skipping_transaction_check do
            Issues::UpdateService.new(
              project: example_class.project,
              current_user: user,
              params: { label_ids: [example_class.label.id] }
            ).execute(issue)
          end

          issue
        end

        def create_data_for_end_event(issue, example_class)
          Sidekiq::Worker.skipping_transaction_check do
            Issues::UpdateService.new(
              project: example_class.project,
              current_user: user,
              params: { label_ids: [example_class.label.id, example_class.other_label.id] }
            ).execute(issue)
          end
        end

        it_behaves_like 'custom Value Stream Analytics Stage' do
          context 'when filtering for two labels' do
            let(:params) do
              {
                from: Time.new(2019),
                to: Time.new(2020),
                current_user: user,
                label_name: [label.name, other_label.name]
              }
            end

            subject { described_class.new(stage: stage, params: params) }

            it 'does not raise query syntax error' do
              expect { subject.records_fetcher.serialized_records }.not_to raise_error(ActiveRecord::StatementInvalid)
            end
          end
        end
      end

      context 'between issue creation time and issue label added time' do
        let(:start_event_identifier) { :issue_created }
        let(:end_event_identifier) { :issue_label_added }

        before do
          stage.end_event_label = label
        end

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project)
        end

        def create_data_for_end_event(issue, example_class)
          Sidekiq::Worker.skipping_transaction_check do
            Issues::UpdateService.new(
              project: example_class.project,
              current_user: user,
              params: { label_ids: [example_class.label.id] }
            ).execute(issue)
          end
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end
    end

    context 'when `MergeRequest` based stage is given' do
      context 'between merge request creation time and merged at time' do
        let(:start_event_identifier) { :merge_request_created }
        let(:end_event_identifier) { :merge_request_merged }

        def create_data_for_start_event(example_class)
          create(:merge_request, :unique_branches, :opened, source_project: example_class.project)
        end

        def create_data_for_end_event(mr, example_class)
          mr.metrics.update!(merged_at: Time.now)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between merge request merrged time and first deployed to production at time' do
        let(:start_event_identifier) { :merge_request_merged }
        let(:end_event_identifier) { :merge_request_first_deployed_to_production }

        def create_data_for_start_event(example_class)
          create(:merge_request, :unique_branches, :opened, source_project: example_class.project).tap do |mr|
            mr.metrics.update!(merged_at: Time.now)
          end
        end

        def create_data_for_end_event(mr, example_class)
          mr.metrics.update!(first_deployed_to_production_at: Time.now)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between first commit at and merge request merged time' do
        let(:start_event_identifier) { :merge_request_first_commit_at }
        let(:end_event_identifier) { :merge_request_merged }

        def create_data_for_start_event(example_class)
          create(:merge_request, :unique_branches, :opened, source_project: example_class.project).tap do |mr|
            mr.metrics.update!(first_commit_at: Time.now)
          end
        end

        def create_data_for_end_event(mr, example_class)
          mr.metrics.update!(merged_at: Time.now)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between merge request build started time and build finished time' do
        let(:start_event_identifier) { :merge_request_last_build_started }
        let(:end_event_identifier) { :merge_request_last_build_finished }

        def create_data_for_start_event(example_class)
          create(:merge_request, :unique_branches, :opened, source_project: example_class.project).tap do |mr|
            mr.metrics.update!(latest_build_started_at: Time.now)
          end
        end

        def create_data_for_end_event(mr, example_class)
          mr.metrics.update!(latest_build_finished_at: Time.now)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between merge request creation time and close time' do
        let(:start_event_identifier) { :merge_request_created }
        let(:end_event_identifier) { :merge_request_closed }

        def create_data_for_start_event(example_class)
          create(:merge_request, source_project: example_class.project, allow_broken: true)
        end

        def create_data_for_end_event(resource, example_class)
          resource.metrics.update!(latest_closed_at: Time.now)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between merge request creation time and last edit time' do
        let(:start_event_identifier) { :merge_request_created }
        let(:end_event_identifier) { :merge_request_last_edited }

        def create_data_for_start_event(example_class)
          create(:merge_request, source_project: example_class.project, allow_broken: true)
        end

        def create_data_for_end_event(resource, example_class)
          resource.update!(last_edited_at: Time.now)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between merge request label added time and label removed time' do
        let(:start_event_identifier) { :merge_request_label_added }
        let(:end_event_identifier) { :merge_request_label_removed }

        before do
          stage.start_event_label = label
          stage.end_event_label = label
        end

        def create_data_for_start_event(example_class)
          mr = create(:merge_request, source_project: example_class.project, allow_broken: true)

          Sidekiq::Worker.skipping_transaction_check do
            MergeRequests::UpdateService.new(
              project: example_class.project,
              current_user: user,
              params: { label_ids: [label.id] }
            ).execute(mr)
          end

          mr
        end

        def create_data_for_end_event(mr, example_class)
          Sidekiq::Worker.skipping_transaction_check do
            MergeRequests::UpdateService.new(
              project: example_class.project,
              current_user: user,
              params: { label_ids: [] }
            ).execute(mr)
          end
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between code stage start time and merge request closed time' do
        let(:start_event_identifier) { :code_stage_start }
        let(:end_event_identifier) { :merge_request_closed }

        context 'when issue is referenced in the commit message' do
          def create_data_for_start_event(example_class)
            issue = create(:issue, project: example_class.project)

            mr = create(:merge_request, {
              source_project: example_class.project,
              target_branch: example_class.project.default_branch,
              description: "Description\n\nclosing #{issue.to_reference}",
              allow_broken: true
            })

            Sidekiq::Worker.skipping_transaction_check do
              MergeRequests::UpdateService.new(
                project: example_class.project,
                current_user: user,
                params: { assignees: [user] }
              ).execute(mr)
            end

            mr.metrics.update!(first_commit_at: Time.zone.now)
            mr
          end

          def create_data_for_end_event(mr, example_class)
            mr.metrics.update!(latest_closed_at: Time.zone.now)
          end

          it_behaves_like 'custom Value Stream Analytics Stage'
        end

        context 'when `first_commit_at` is present' do
          def create_data_for_start_event(example_class)
            mr = create(:merge_request, { source_project: example_class.project, target_branch: example_class.project.default_branch, allow_broken: true })
            mr.metrics.update!(first_commit_at: Time.zone.now)
            mr
          end

          def create_data_for_end_event(mr, example_class)
            mr.metrics.update!(latest_closed_at: Time.zone.now)
          end

          it_behaves_like 'custom Value Stream Analytics Stage'
        end

        context 'label filter' do
          before do
            params[:label_name] = [label.name, other_label.name]
          end

          def create_data_for_start_event(example_class)
            issue = create(:issue, project: example_class.project)
            issue.metrics.update!(first_mentioned_in_commit_at: Time.zone.now)

            mr = create(:merge_request, {
              source_project: example_class.project,
              target_branch: example_class.project.default_branch,
              description: "Description\n\nclosing #{issue.to_reference}",
              allow_broken: true
            })

            Sidekiq::Worker.skipping_transaction_check do
              MergeRequests::UpdateService.new(
                project: example_class.project,
                current_user: user,
                params: { label_ids: [label.id, other_label.id] }
              ).execute(mr)
            end

            mr
          end

          def create_data_for_end_event(mr, example_class)
            mr.metrics.update!(latest_closed_at: Time.zone.now)
          end

          it_behaves_like 'custom Value Stream Analytics Stage'
        end
      end
    end
  end

  context 'when `Analytics::CycleAnalytics::ProjectStage` is given' do
    it_behaves_like 'test various start and end event combinations' do
      let_it_be(:project) { create(:project, :repository, group: create(:group)) }
      let_it_be(:label) { create(:group_label, group: project.group) }
      let_it_be(:other_label) { create(:group_label, group: project.group) }

      let(:stage) do
        Analytics::CycleAnalytics::ProjectStage.new(
          name: 'My Stage',
          project: project,
          start_event_identifier: start_event_identifier,
          end_event_identifier: end_event_identifier
        )
      end

      before_all do
        project.add_user(user, Gitlab::Access::DEVELOPER)
      end
    end
  end

  context 'when `Analytics::CycleAnalytics::GroupStage` is given' do
    it_behaves_like 'test various start and end event combinations' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, :repository, group: group) }
      let_it_be(:label) { create(:group_label, group: group) }
      let_it_be(:other_label) { create(:group_label, group: group) }

      let(:stage) do
        Analytics::CycleAnalytics::GroupStage.new(
          name: 'My Stage',
          group: group,
          start_event_identifier: start_event_identifier,
          end_event_identifier: end_event_identifier
        )
      end

      before_all do
        group.add_user(user, GroupMember::MAINTAINER)
      end
    end

    context 'when filter parameters are given' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project1) { create(:project, :repository, group: group) }
      let_it_be(:project2) { create(:project, :repository, group: group) }

      let(:merge_request) { project2.merge_requests.first }

      let(:stage) do
        Analytics::CycleAnalytics::GroupStage.new(
          name: 'My Stage',
          group: group,
          start_event_identifier: :merge_request_created,
          end_event_identifier: :merge_request_merged
        )
      end

      let(:data_collector_params) do
        {
          created_after: Time.new(2019, 1, 1),
          current_user: user
        }
      end

      subject do
        params = Gitlab::Analytics::CycleAnalytics::RequestParams.new(data_collector_params).to_data_collector_params

        described_class.new(stage: stage, params: params).records_fetcher.serialized_records
      end

      before do
        group.add_user(user, GroupMember::MAINTAINER)

        travel_to(Time.new(2019, 6, 1)) do
          mr = create(:merge_request, source_project: project1)
          mr.metrics.update!(merged_at: 1.hour.from_now)

          mr = create(:merge_request, source_project: project2)
          mr.metrics.update!(merged_at: 1.hour.from_now)
        end
      end

      shared_examples 'filter examples' do
        it 'provides filtered results' do
          expect(subject.size).to eq(1)

          expect(subject.first[:title]).to eq(merge_request.title)
          expect(subject.first[:iid]).to eq(merge_request.iid.to_s)
        end
      end

      context 'when `project_ids` parameter is given' do
        before do
          data_collector_params[:project_ids] = [project2.id]
        end

        it_behaves_like 'filter examples'
      end

      context 'when `assignee_username` is given' do
        let(:assignee) { create(:user) }

        before do
          merge_request.assignees << assignee

          data_collector_params[:assignee_username] = [assignee.username]
        end

        it_behaves_like 'filter examples'
      end

      context 'when `author_username` is given' do
        let(:author) { create(:user) }

        before do
          merge_request.update!(author: author)

          data_collector_params[:author_username] = author.username
        end

        it_behaves_like 'filter examples'
      end

      context 'when `label_name` is given' do
        let(:label) { create(:group_label, group: group) }

        before do
          MergeRequests::UpdateService.new(
            project: merge_request.project,
            current_user: user,
            params: { label_ids: [label.id] }
          ).execute(merge_request)

          data_collector_params[:label_name] = [label.name]
        end

        it_behaves_like 'filter examples'
      end

      context 'when `Any` `label_name` is given' do
        let(:label) { create(:group_label, group: group) }

        before do
          MergeRequests::UpdateService.new(
            project: merge_request.project,
            current_user: user,
            params: { label_ids: [label.id] }
          ).execute(merge_request)

          data_collector_params[:label_name] = ['Any']
        end

        it_behaves_like 'filter examples'
      end

      context 'when two labels are given' do
        let(:label1) { create(:group_label, group: group) }
        let(:label2) { create(:group_label, group: group) }

        before do
          MergeRequests::UpdateService.new(
            project: merge_request.project,
            current_user: user,
            params: { label_ids: [label1.id, label2.id] }
          ).execute(merge_request)

          data_collector_params[:label_name] = [label1.name, label2.name]
        end

        it_behaves_like 'filter examples'
      end

      context 'when `milestone_title` is given' do
        let(:milestone) { create(:milestone, group: group) }

        before do
          merge_request.update!(milestone: milestone)

          data_collector_params[:milestone_title] = milestone.title
        end

        it_behaves_like 'filter examples'
      end
    end
  end

  describe 'limit count' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :repository, group: group) }

    let(:merge_request) { merge_requests.first }

    let(:stage) do
      Analytics::CycleAnalytics::GroupStage.new(
        name: 'My Stage',
        group: group,
        start_event_identifier: :merge_request_created,
        end_event_identifier: :merge_request_merged
      )
    end

    before do
      merge_requests = create_list(:merge_request, 3, :unique_branches, target_project: project, source_project: project)
      merge_requests.each { |mr| mr.metrics.update!(merged_at: 10.days.from_now) }

      project.add_user(user, Gitlab::Access::DEVELOPER)
    end

    subject(:count) do
      described_class.new(stage: stage, params: {
        from: 5.months.ago,
        to: 5.months.from_now,
        current_user: user
      }).count
    end

    context 'when limit is reached' do
      before do
        stub_const('Gitlab::Analytics::CycleAnalytics::DataCollector::MAX_COUNT', 2)
      end

      it 'shows the MAX COUNT' do
        is_expected.to eq(2)
      end
    end

    context 'when limit is not reached' do
      it 'shows the actual count' do
        is_expected.to eq(3)
      end
    end
  end
end
