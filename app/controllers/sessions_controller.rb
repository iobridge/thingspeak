class SessionsController < Devise::SessionsController
  after_filter :log_failed_login, :only => :new

  # don't modify default devise controllers
  def create; super; end
  def new; super; end

  private

    # logs failed login attempts
    def log_failed_login
      if failed_login?
        # log to failedlogins
        failed = Failedlogin.new
        failed.login = params['user']['login']
        failed.password = params['user']['password']
        failed.ip_address = get_header_value('X_REAL_IP')
        failed.save

        # prevent timing and brute force password attacks
        sleep 1
      end
    end

    # true if a login fails
    def failed_login?
      options = env["warden.options"]
      return (options.present? && options[:action] == "unauthenticated")
    end

end

