require 'controllers/v3/mixins/app_subresource'

class TasksController < ApplicationController
  include AppSubresource

  def show
    task = TaskModel.where(guid: params[:task_guid]).eager(:space, space: :organization).first

    task_not_found! unless task && can_read?(task.space.guid, task.space.organization.guid)
    render status: :ok, json: TaskPresenter.new.present_json(task)
  end

  private

  def task_not_found!
    resource_not_found!(:task)
  end

  def can_create?(space_guid)
    roles.admin? || membership.has_any_roles?([Membership::SPACE_DEVELOPER], space_guid)
  end
end
