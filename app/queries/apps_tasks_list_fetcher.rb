module VCAP::CloudController
  class AppsTasksListFetcher
    def fetch(app_guid, pagination_options, message)
      dataset = TaskModel.select_all(:tasks).where(app_guid: app_guid)
      filter(pagination_options, message, dataset)
    end

    private

    def filter(pagination_options, message, dataset)
      if message.requested?(:states)
        dataset = dataset.where(state: message.states)
      end

      SequelPaginator.new.get_page(dataset, pagination_options)
    end
  end
end
