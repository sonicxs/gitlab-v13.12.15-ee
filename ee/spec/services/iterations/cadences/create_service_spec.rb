# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iterations::Cadences::CreateService do
  let_it_be(:group, refind: true) { create(:group) }
  let_it_be(:user) { create(:user) }

  before do
    group.add_developer(user)
  end

  context 'iterations feature enabled' do
    before do
      stub_licensed_features(iterations: true)
    end

    describe '#execute' do
      let(:params) do
        {
          title: 'My iteration cadence',
          start_date: Time.current.to_s,
          duration_in_weeks: 1,
          iterations_in_advance: 1,
          roll_over: true,
          description: 'Iteration cadence description'
        }
      end

      let(:response) { described_class.new(group, user, params).execute }
      let(:iteration_cadence) { response.payload[:iteration_cadence] }
      let(:errors) { response.errors }

      context 'valid params' do
        it 'creates an iteration cadence' do
          expect(response.success?).to be_truthy
          expect(iteration_cadence).to be_persisted
          expect(iteration_cadence.title).to eq('My iteration cadence')
          expect(iteration_cadence.duration_in_weeks).to eq(1)
          expect(iteration_cadence.iterations_in_advance).to eq(1)
          expect(iteration_cadence.active).to eq(true)
          expect(iteration_cadence.automatic).to eq(true)
        end
      end

      context 'invalid params' do
        let(:params) do
          {
            title: 'My iteration cadence'
          }
        end

        it 'does not create an iteration cadence but returns errors' do
          expect(response.error?).to be_truthy
          expect(errors).to match([
            "Start date can't be blank",
            "Duration in weeks can't be blank",
            "Iterations in advance can't be blank"
          ])
        end
      end

      context 'no permissions' do
        before do
          group.add_reporter(user)
        end

        it 'is not allowed' do
          expect(response.error?).to be_truthy
          expect(response.message).to eq('Operation not allowed')
        end
      end

      context 'when a single iteration cadence is allowed' do
        let_it_be(:existing_iteration_cadence) { create(:iterations_cadence, group: group) }

        before do
          stub_licensed_features(multiple_iteration_cadences: false)
        end

        it 'fails to create multiple iteration cadences in same group' do
          expect { response }.not_to change { Iterations::Cadence.count }
        end
      end

      context 'when multiple iteration cadences are allowed' do
        let_it_be(:existing_iteration_cadence) { create(:iterations_cadence, group: group) }

        before do
          stub_licensed_features(multiple_iteration_cadences: true)
        end

        it 'creates new iteration cadence' do
          expect { response }.to change { Iterations::Cadence.count }.by(1)
        end
      end
    end
  end

  context 'iterations feature disabled' do
    before do
      stub_licensed_features(iterations: false)
    end

    describe '#execute' do
      let(:params) { { title: 'a' } }
      let(:response) { described_class.new(group, user, params).execute }

      it 'is not allowed' do
        expect(response.error?).to be_truthy
        expect(response.message).to eq('Operation not allowed')
      end
    end
  end

  context 'iteration cadences feature flag disabled' do
    before do
      stub_licensed_features(iterations: true)
      stub_feature_flags(iteration_cadences: false)
    end

    describe '#execute' do
      let(:params) { { title: 'a' } }
      let(:response) { described_class.new(group, user, params).execute }

      it 'is not allowed' do
        expect(response.error?).to be_truthy
        expect(response.message).to eq('Operation not allowed')
      end
    end
  end
end
