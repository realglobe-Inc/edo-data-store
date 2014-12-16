# ログを取る時は、以下のように使用する。
#
# class MyClass
#   include DebugLogger
#
#   def my_method
#     debug_message { "ブロックの返り値がログに残る" }
#     debug_message do
#       "do ... end のブロックで書く場合はこう"
#     end
#     debug_message(:foo, :bar) { "引数は渡しても無視される" }
#     debug_message do
#       [
#        "返り値として配列を返すと",
#        "複数行のログを出力できる"
#       ]
#     end
#     debug_message do
#       raise
#       "例外が発生した場合、それがログに残る"
#     end
#   end
# end
#
# あるいは以下のように、モジュール関数をそのまま呼び出しても良い。
#
# DebugLogger.debug_message { "ログに残すメッセージ" }
#

module DebugLogger
  module_function

  def debug_log_file_path
    "#{Rails.root}/log/#{Rails.env}_debug.log"
  end

  def debug_logger
    @@debug_logger ||= ActiveSupport::Logger.new(debug_log_file_path)
  end

  def debug_message_string(message)
    debug_logger.debug(message)
    Rails.logger.debug(message)
  rescue
  end

  def debug_message(*_)
    begin
      messages = yield
    rescue => e
      debug_message_string("*** debug_message yield error ***")
      messages = e.inspect
    end
    messages = [messages].flatten
    now = Time.now.strftime("%Y/%m/%d %H:%M:%S.%N")
    messages.each do |message|
      message = "#{now} : #{message}"
      debug_message_string(message)
    end
  end
end

ActiveSupport.on_load(:action_controller) do
  ActionController::Base.class_eval do
    include DebugLogger
  end
end
ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.class_eval do
    include DebugLogger
    extend DebugLogger
  end
end
