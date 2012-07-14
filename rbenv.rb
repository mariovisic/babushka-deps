dep '1.9.3-falcon.rbenv' do
  version '1.9.3'
  patchlevel 'p194'
  customise {
    falcon_patch = 'https://raw.github.com/gist/2600122/rbenv.sh'
    shell "curl '#{falcon_patch}' | git apply"
  }
end
