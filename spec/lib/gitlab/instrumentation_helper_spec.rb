# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::InstrumentationHelper do
  using RSpec::Parameterized::TableSyntax

  describe '.add_instrumentation_data', :request_store do
    let(:payload) { {} }

    subject { described_class.add_instrumentation_data(payload) }

    before do
      described_class.init_instrumentation_data
    end

    it 'includes DB counts' do
      subject

      expect(payload).to include(db_count: 0, db_cached_count: 0, db_write_count: 0)
    end

    context 'when Gitaly calls are made' do
      it 'adds Gitaly data and omits Redis data' do
        project = create(:project)
        RequestStore.clear!
        project.repository.exists?

        subject

        expect(payload[:gitaly_calls]).to eq(1)
        expect(payload[:gitaly_duration_s]).to be >= 0
        expect(payload[:redis_calls]).to be_nil
        expect(payload[:redis_duration_ms]).to be_nil
      end
    end

    context 'when Redis calls are made' do
      it 'adds Redis data and omits Gitaly data' do
        Gitlab::Redis::Cache.with { |redis| redis.set('test-cache', 123) }
        Gitlab::Redis::Queues.with { |redis| redis.set('test-queues', 321) }

        subject

        # Aggregated payload
        expect(payload[:redis_calls]).to eq(2)
        expect(payload[:redis_duration_s]).to be >= 0
        expect(payload[:redis_read_bytes]).to be >= 0
        expect(payload[:redis_write_bytes]).to be >= 0

        # Shared state payload
        expect(payload[:redis_queues_calls]).to eq(1)
        expect(payload[:redis_queues_duration_s]).to be >= 0
        expect(payload[:redis_queues_read_bytes]).to be >= 0
        expect(payload[:redis_queues_write_bytes]).to be >= 0

        # Cache payload
        expect(payload[:redis_cache_calls]).to eq(1)
        expect(payload[:redis_cache_duration_s]).to be >= 0
        expect(payload[:redis_cache_read_bytes]).to be >= 0
        expect(payload[:redis_cache_write_bytes]).to be >= 0

        # Gitaly
        expect(payload[:gitaly_calls]).to be_nil
        expect(payload[:gitaly_duration]).to be_nil
      end
    end

    context 'when the request matched a Rack::Attack safelist' do
      it 'logs the safelist name' do
        Gitlab::Instrumentation::Throttle.safelist = 'foobar'

        subject

        expect(payload[:throttle_safelist]).to eq('foobar')
      end
    end

    it 'logs cpu_s duration' do
      subject

      expect(payload).to include(:cpu_s)
    end

    context 'when logging memory allocations' do
      include MemoryInstrumentationHelper

      before do
        skip_memory_instrumentation!
      end

      it 'logs memory usage metrics' do
        subject

        expect(payload).to include(
          :mem_objects,
          :mem_bytes,
          :mem_mallocs
        )
      end

      context 'when trace_memory_allocations is disabled' do
        before do
          stub_feature_flags(trace_memory_allocations: false)
          Gitlab::Memory::Instrumentation.ensure_feature_flag!
        end

        it 'does not log memory usage metrics' do
          subject

          expect(payload).not_to include(
            :mem_objects,
            :mem_bytes,
            :mem_mallocs
          )
        end
      end
    end
  end

  describe '.queue_duration_for_job' do
    where(:enqueued_at, :created_at, :time_now, :expected_duration) do
      "2019-06-01T00:00:00.000+0000" | nil                            | "2019-06-01T02:00:00.000+0000" | 2.hours.to_f
      "2019-06-01T02:00:00.000+0000" | nil                            | "2019-06-01T02:00:00.001+0000" | 0.001
      "2019-06-01T02:00:00.000+0000" | "2019-05-01T02:00:00.000+0000" | "2019-06-01T02:00:01.000+0000" | 1
      nil                            | "2019-06-01T02:00:00.000+0000" | "2019-06-01T02:00:00.001+0000" | 0.001
      nil                            | nil                            | "2019-06-01T02:00:00.001+0000" | nil
      "2019-06-01T02:00:00.000+0200" | nil                            | "2019-06-01T02:00:00.000-0200" | 4.hours.to_f
      1571825569.998168              | nil                            | "2019-10-23T12:13:16.000+0200" | 26.001832
      1571825569                     | nil                            | "2019-10-23T12:13:16.000+0200" | 27
      "invalid_date"                 | nil                            | "2019-10-23T12:13:16.000+0200" | nil
      ""                             | nil                            | "2019-10-23T12:13:16.000+0200" | nil
      0                              | nil                            | "2019-10-23T12:13:16.000+0200" | nil
      -1                             | nil                            | "2019-10-23T12:13:16.000+0200" | nil
      "2019-06-01T02:00:00.000+0000" | nil                            | "2019-06-01T00:00:00.000+0000" | 0
      Time.at(1571999233)            | nil                            | "2019-10-25T12:29:16.000+0200" | 123
    end

    with_them do
      let(:job) { { 'enqueued_at' => enqueued_at, 'created_at' => created_at } }

      it "returns the correct duration" do
        Timecop.freeze(Time.iso8601(time_now)) do
          expect(described_class.queue_duration_for_job(job)).to eq(expected_duration)
        end
      end
    end
  end
end
