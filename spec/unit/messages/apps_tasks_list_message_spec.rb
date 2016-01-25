require 'spec_helper'
require 'messages/apps_tasks_list_message'

module VCAP::CloudController
  describe AppsTasksListMessage do
    describe '.from_params' do
      let(:params) do
        {
          'page'      => 1,
          'per_page'  => 5,
        }
      end

      it 'returns the correct AppCreateMessage' do
        message = AppsTasksListMessage.from_params(params)

        expect(message).to be_a(AppsTasksListMessage)
        expect(message.page).to eq(1)
        expect(message.per_page).to eq(5)
      end

      it 'converts requested keys to symbols' do
        message = AppsTasksListMessage.from_params(params)

        expect(message.requested?(:page)).to be_truthy
        expect(message.requested?(:per_page)).to be_truthy
      end
    end

    describe '#to_param_hash' do
      let(:opts) do
        {
          page:      1,
          per_page:  5,
        }
      end

      it 'excludes the pagination keys' do
        expected_params = []
        expect(AppsTasksListMessage.new(opts).to_param_hash.keys).to match_array(expected_params)
      end
    end

    describe 'fields' do
      it 'accepts a set of fields' do
        message = AppsTasksListMessage.new({
          page: 1,
          per_page: 5,
        })
        expect(message).to be_valid
      end

      it 'accepts an empty set' do
        message = AppsTasksListMessage.new
        expect(message).to be_valid
      end

      it 'does not accept a field not in this set' do
        message = AppsTasksListMessage.new({ foobar: 'pants' })

        expect(message).not_to be_valid
        expect(message.errors[:base]).to include("Unknown query parameter(s): 'foobar'")
      end

      describe 'validations' do
        describe 'page' do
          it 'validates it is a number' do
            message = AppsTasksListMessage.new page: 'not number'
            expect(message).to be_invalid
            expect(message.errors[:page].length).to eq 1
          end

          it 'is invalid if page is 0' do
            message = AppsTasksListMessage.new page: 0
            expect(message).to be_invalid
            expect(message.errors[:page].length).to eq 1
          end

          it 'is invalid if page is negative' do
            message = AppsTasksListMessage.new page: -1
            expect(message).to be_invalid
            expect(message.errors[:page].length).to eq 1
          end

          it 'is invalid if page is not an integer' do
            message = AppsTasksListMessage.new page: 1.1
            expect(message).to be_invalid
            expect(message.errors[:page].length).to eq 1
          end
        end

        describe 'per_page' do
          it 'validates it is a number' do
            message = AppsTasksListMessage.new per_page: 'not number'
            expect(message).to be_invalid
            expect(message.errors[:per_page].length).to eq 1
          end

          it 'is invalid if per_page is 0' do
            message = AppsTasksListMessage.new per_page: 0
            expect(message).to be_invalid
            expect(message.errors[:per_page].length).to eq 1
          end

          it 'is invalid if per_page is negative' do
            message = AppsTasksListMessage.new per_page: -1
            expect(message).to be_invalid
            expect(message.errors[:per_page].length).to eq 1
          end

          it 'is invalid if per_page is not an integer' do
            message = AppsTasksListMessage.new per_page: 1.1
            expect(message).to be_invalid
            expect(message.errors[:per_page].length).to eq 1
          end
        end
      end
    end
  end
end
