module Chewy
  class Error < StandardError
  end

  class UndefinedIndex < Error
  end

  class UndefinedType < Error
  end

  class UnderivableType < Error
  end

  class UndefinedUpdateStrategy < Error
    def initialize type
      super <<-MESSAGE
Index update strategy is undefined in current context.
Please wrap your code with `Chewy.strategy(:strategy_name) block.`
      MESSAGE
    end
  end

  class DocumentNotFound < Error
  end

  class ImportFailed < Error
    def initialize type, errors
      message = "Import failed for `#{type}` with:\n"
      errors.each do |action, errors|
        message << "    #{action.to_s.humanize} errors:\n"
        errors.each do |error, documents|
          anonymous_error = anonymize_with_placeholders(error)
          anonymous_documents = ['?']
          message << "      `#{anonymous_error}`\n"
          message << "        on #{anonymous_documents.count} documents: #{anonymous_documents}\n"
        end
      end
      super message
    end

    # Replace IDs and other specific data for placeholder '?'
    # to anonymize the error and make it easier to group in the exception tracker
    #
    # Example input:
    #   rejected execution of org.elasticsearch...Service$4@553f9b39 on EsThreadPoolExecutor[
    #     ...capacity = 50, org.elasticsearch...EsThreadPoolExecutor@2134b86a[
    #       ...pool size = 2, active threads = 2, queued tasks = 50, completed tasks = 6635921]]
    #
    # Example output:
    #   rejected execution of org.elasticsearch...Service$? on EsThreadPoolExecutor[
    #     ...capacity = ?, org.elasticsearch...EsThreadPoolExecutor@?[
    #       ...pool size = 2, active threads = 2, queued tasks = ?, completed tasks = ?]]
    def anonymize_with_placeholders(input)
      input.to_s.gsub(/\b\d[@\w]+\b/, '?')
    end
  end

  class RemovedFeature < Error
  end

  class PluginMissing < Error
  end
end
