require 'spec_helper'

module VCAP::CloudController
  describe TaskListFetcher do
    let(:app_in_space) { AppModel.make }
    let(:desired_space) { app_in_space.space }
    let!(:desired_task) { TaskModel.make(app_guid: app_in_space.guid) }
    let!(:desired_task2) { TaskModel.make(app_guid: app_in_space.guid) }
    let(:pagination_options) { PaginationOptions.new({}) }
    let(:fetcher) { described_class.new }
    let(:message) { DropletsListMessage.new(filters) }
    let(:filters) { {} }

    describe '#fetch_all' do
      it 'returns a PaginatedResult' do
        results = fetcher.fetch_all(pagination_options, message)
        expect(results).to be_a(PaginatedResult)
      end

      it 'returns all of the tasks' do
        results = fetcher.fetch_all(pagination_options, message).records

        expect(results.length).to eq(4)
        expect(results).to match_array([desired_droplet, desired_droplet2, sad_droplet_in_space, undesirable_droplet])
      end
    end

    describe '#fetch' do
      it 'returns a PaginatedResult' do
        results = fetcher.fetch(pagination_options, space_guids, message)
        expect(results).to be_a(PaginatedResult)
      end

      it 'returns all of the desired tasks in the requested spaces' do
        results = fetcher.fetch(pagination_options, space_guids, message).records

        expect(results.length).to eq 3
        expect(results).to match_array([desired_droplet, desired_droplet2, sad_droplet_in_space])
      end
    end
  end
end
