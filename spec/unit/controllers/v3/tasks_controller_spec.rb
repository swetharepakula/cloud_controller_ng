require 'rails_helper'

describe TasksController, type: :controller do
  describe '#show' do
    let!(:task) { VCAP::CloudController::TaskModel.make name: 'mytask'}
    let(:membership) { instance_double(VCAP::CloudController::Membership) }
    let(:space) { task.app.space }
    let(:org) { space.organization }
    let(:enabled) { true }

    before do
      @request.env.merge!(headers_for(VCAP::CloudController::User.make))
      allow(VCAP::CloudController::Membership).to receive(:new).and_return(membership)
      allow(membership).to receive(:has_any_roles?).with(
        [VCAP::CloudController::Membership::SPACE_DEVELOPER], space.guid).and_return(true)
      allow(membership).to receive(:has_any_roles?).with(
        [VCAP::CloudController::Membership::SPACE_DEVELOPER,
          VCAP::CloudController::Membership::SPACE_MANAGER,
          VCAP::CloudController::Membership::SPACE_AUDITOR,
          VCAP::CloudController::Membership::ORG_MANAGER], space.guid, org.guid).and_return(true)
    end

    it 'returns a 200 and the task' do
      get :show, task_guid: task.guid

      expect(response.status).to eq 200
      expect(JSON.parse(response.body)).to include('name' => 'mytask')
    end

    describe 'access permissions' do
      context 'when the user does not have read scope' do
        before do
          @request.env.merge!(json_headers(headers_for(VCAP::CloudController::User.make, scopes: [])))
        end

        it 'raises 403' do
          get :show, task_guid: task.guid

          expect(response.status).to eq(403)
          expect(response.body).to include 'NotAuthorized'
        end
      end

      context 'when the user does not have read permissions on the space' do
        before do
          allow(membership).to receive(:has_any_roles?).with(
            [VCAP::CloudController::Membership::SPACE_DEVELOPER,
              VCAP::CloudController::Membership::SPACE_MANAGER,
              VCAP::CloudController::Membership::SPACE_AUDITOR,
              VCAP::CloudController::Membership::ORG_MANAGER], space.guid, org.guid).and_return(false)
        end

        it 'returns a 404 ResourceNotFound' do
          get :show, task_guid: task.guid

          expect(response.status).to eq 404
          expect(response.body).to include 'ResourceNotFound'
          expect(response.body).to include 'Task not found'
        end
      end
    end

    it 'returns a 404 if the task does not exist' do
      get :show, task_guid: 'bogus'

      expect(response.status).to eq 404
      expect(response.body).to include 'ResourceNotFound'
      expect(response.body).to include 'Task not found'
    end
  end

  # describe '#index' do
  #   context 'when the user has read permissions on the space' do
  #     let(:space)
  #     let(:task_in_space) { Task.make }
  #     before do
  #       allow(membership).to receive(:has_any_roles?).with(
  #         [VCAP::CloudController::Membership::SPACE_DEVELOPER,
  #           VCAP::CloudController::Membership::SPACE_MANAGER,
  #           VCAP::CloudController::Membership::SPACE_AUDITOR,
  #           VCAP::CloudController::Membership::ORG_MANAGER], space.guid, org.guid).and_return(false)
  #     end
  #
  #     it 'should return a list of tasks on that space' do
  #       get :list
  #
  #       expect(response.status).to eq 200
  #       expect(response.body).to include
  #     end
  #   end
  # end
end
