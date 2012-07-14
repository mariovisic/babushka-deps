module RemoteHelpers
  def as user, &block
    previous_user, @user = @user, user
    yield
  ensure
    @user = previous_user
  end

  def remote_shell *cmd
    host_spec = "#{@user || 'root'}@#{host}"
    opening_message = [
      host_spec.colorize("on grey"), # user@host spec
      cmd.map {|i| i.sub(/^(.{50})(.{3}).*/m, '\1...') }.join(' ') # the command, with long args truncated
    ].join(' $ ')
    log opening_message, :closing_status => opening_message do
      shell "ssh -A #{host_spec} #{cmd.map{|i| "'#{i}'" }.join(' ')}", :log => true
    end
  end

  def remote_babushka dep_spec, args = {}
    remote_args = [
      '--defaults',
      ('--update' if Babushka::Base.task.opt(:update)),
      ('--debug'  if Babushka::Base.task.opt(:debug)),
      ('--colour' if $stdin.tty?),
      '--show-args'
    ].compact

    remote_args.concat args.keys.map {|k| "#{k}=#{args[k]}" }

    remote_shell(
      'babushka',
      dep_spec,
      *remote_args
    ).tap {|result|
      unmeetable! "The remote babushka reported an error." unless result
    }
  end
end

include RemoteHelpers

# General setup for a machine
dep 'provision base', :host, :public_key, :app_user  do
  public_key.default!((dependency.load_path.parent / 'config/authorized_public_key').read)

  requires_when_unmet 'conversation:public key in place'.with(host, public_key)
  requires_when_unmet 'conversation:babushka bootstrapped'.with(host)

  remote_babushka 'benhoskings:set.locale', :locale_name => 'en_AU'
  remote_babushka '"benhoskings:libssl headers.managed"'
  remote_babushka 'benhoskings:utc'
  remote_babushka '"benhoskings:lamp stack removed"'
  remote_babushka '"benhoskings:postfix removed"'
  remote_babushka '"benhoskings:user setup for provisioning"', :username => app_user, :key => public_key
  remote_babushka 'benhoskings:system'
end

# General rails app setup
dep 'provision app', :host, :public_key, :app_user do
  as(app_user) { remote_babushka 'mariovisic:node.src' }
end

# Frontend rails server setup
dep 'provision web', :host, :env, :public_key, :app_user do
  requires [
    'provision base'.with(host, public_key, app_user),
    'provision app'.with(host, public_key, app_user)
  ]
end
