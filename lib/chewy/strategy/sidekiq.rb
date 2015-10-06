module Chewy
  class Strategy
    # The strategy works the same way as atomic, but performs
    # async index update driven by sidekiq
    #
    #   Chewy.strategy(:sidekiq) do
    #     User.all.map(&:save) # Does nothing here
    #     Post.all.map(&:save) # And here
    #     # It imports all the changed users and posts right here
    #   end
    #
    class Sidekiq < Atomic
      class Worker
        include ::Sidekiq::Worker
        sidekiq_options queue: 'chewy'
        # tried to set sidekiq_options dinamically (Chewy.configuration[:sidekiq])
        # but it didn't work since this runs before the YAML file is loaded

        def perform(type, ids)
          type.constantize.import!(ids)
        end
      end

      def leave
        @stash.all? do |type, ids|
          ids.sort.each_slice(10) do |ids_chunk|
            Chewy::Strategy::Sidekiq::Worker.perform_async(type.name, ids_chunk)
          end
        end
      end
    end
  end
end
