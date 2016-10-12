guard :rspec, cmd: "bundle exec rspec", all_on_start:true do
  watch(%r{^spec/.+_spec\.rb$})                       { "spec" }
  watch('spec/spec_helper.rb')                        { "spec" }
  watch('spec/shared.rb')                             { "spec" }

  watch(%r{^app/(.+)\.rb$})                           { "spec" }
  watch(%r{^app/assets/javascripts/(.+)\.js$})        { "spec" }
  watch(%r{^app/assets/stylesheets/(.+)\.css$})       { "spec" }
  watch(%r{^app/controllers/(.+)_controller\.rb$})    { "spec" }
  watch(%r{^app/views/.+/.+\.erb$})                   { "spec" }
  watch(%r{^spec/factories/(.+)\.rb$})                { "spec" }
  watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
  watch('config/routes.rb')                           { "spec" }
  watch(%r{^config/initializers/.*.rb})               { "spec" }
  watch('app/controllers/application_controller.rb')  { "spec" }
  watch('spec/rails_helper.rb')                       { "spec" }
end
