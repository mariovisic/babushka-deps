require_relative 'remote_helpers'

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
  as(app_user) { remote_babushka 'dudemeister:node.src' }
end

# Frontend rails server setup
dep 'provision web', :host, :env, :public_key, :app_user do
  requires [
    'provision base'.with(host, public_key, app_user),
    'provision app'.with(host, public_key, app_user)
  ]
end
