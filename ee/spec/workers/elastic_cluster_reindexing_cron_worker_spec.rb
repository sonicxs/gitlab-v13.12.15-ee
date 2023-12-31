# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticClusterReindexingCronWorker do
  subject { described_class.new }

  describe '#perform' do
    it 'calls execute method' do
      expect(Elastic::ReindexingTask).to receive(:current).and_return(build(:elastic_reindexing_task))

      expect_next_instance_of(Elastic::ClusterReindexingService) do |service|
        expect(service).to receive(:execute).and_return(false)
      end

      subject.perform
    end

    it 'removes old indices if no task is found' do
      expect(Elastic::ReindexingTask).to receive(:current).and_return(nil)
      expect(Elastic::ReindexingTask).to receive(:drop_old_indices!)

      expect(subject.perform).to eq(false)
    end

    # support currently running reindexing processes during an upgrade
    it 'calls the legacy service if subtask has elastic_task populated' do
      task = create(:elastic_reindexing_task)
      create(:elastic_reindexing_subtask, elastic_reindexing_task: task, elastic_task: 'test')
      expect(Elastic::ReindexingTask).to receive(:current).and_return(task)

      expect_next_instance_of(Elastic::LegacyReindexingService) do |service|
        expect(service).to receive(:execute).and_return(false)
      end

      subject.perform
    end
  end
end
