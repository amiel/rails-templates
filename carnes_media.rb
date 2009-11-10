app_name = File.basename(File.expand_path(@root))

def ask_with_default(q, default)
	response = ask("#{q} default: #{default}")
	response.blank? ? default : response
end

def add_stylesheets_to_application(*stylesheets)
	# gsub_file 'app/views/layouts/application.html.erb', /(stylesheet_link_tag)(.*)('application')/, "\\1\\2#{stylesheets.collect{|s| "'#{s}', " }}\\3"
	stylesheets.each do |s|
		run "echo \"@import \\\"#{s}\\\";\" >> app/stylesheets/application.less"
	end
end

def setup_960gs
	run 'curl -L http://github.com/davemerwin/960-grid-system/raw/master/code/css/reset.css > app/stylesheets/vendor/_reset.less'
	run 'curl -L http://github.com/davemerwin/960-grid-system/raw/master/code/css/960.css > app/stylesheets/vendor/_960.less'
	add_stylesheets_to_application 'vendor/_reset', 'vendor/_960'
end

def setup_resetcss
	run 'curl -L http://github.com/davemerwin/960-grid-system/raw/master/code/css/reset.css > app/stylesheets/vendor/_reset.less'
	add_stylesheets_to_application 'vendor/_reset'
end

def setup_sencss
	run 'curl -L http://sencss.googlecode.com/files/sen.0.6.min.css > app/stylesheets/vendor/_sen.less'
	gsub_file 'app/stylesheets/sen.less', /@charset "utf-8";\s*/, ''
	add_stylesheets_to_application 'vendor/_sen'
end

puts 'ok, some questions before we get started'

	options = {}

	options[:css_framework] = ask_with_default('What CSS framework would you like to start with? options are 960gs, sen, reset', 'reset')
	options[:first_controller_name] = ask_with_default('What would you like to call your first controller?', 'home')
	
	# options[:jqtools] = yes?('would you like jQuery tools?')
	
	options[:sprockets] = yes?('Would you like sprockets?')
	JS_PATH = options[:sprockets] ? 'app/javascripts' : 'public/javascripts'
	
	options[:formtastic] = yes?('Would you like a nice form builder (formtastic)?')
	
	options[:heroku] = yes?('Will you be deploying to heroku?')
	options[:capistrano] = options[:heroku] ? false : yes?('Will you be deploying with capistrano?')
	
	options[:spreadhead] = yes?('Would you like spreadhead for basic content management?')
	options[:authlogic] = yes?('Would you like authlogic setup for authentication?')
	options[:paperclip] = yes?('Would you like paperclip?')
	options[:hoptoad] = yes?('would you like the hoptoad notifier?')
	options[:hoptoad_api_key] = ask('please enter your hoptoad api key (ok to leave blank)') if options[:hoptoad]
	
	# options[:passenger] = yes?('Would you like')
	options[:git_repos] = ask('If this project will be hosted by a central git repository, enter the repos here:')
	y options

	begin; puts "ABORT"; exit; end if no?('is this all ok?')

puts "setting up git"

	git :init

	file '.gitignore' do
		<<-GITIGNORE
.DS_Store
log/*.log
tmp/**/*
db/*.sqlite3
public/system
public/stylesheets
		GITIGNORE
	end
	
	in_root do
		run 'echo "public/javascripts" >> .gitignore' if options[:sprockets]
		run "mkdir -p #{JS_PATH}" if options[:sprockets] # it will be empty, but we'll be adding files soon enough
		
		run 'touch tmp/.keep log/.keep vendor/.keep'
		run 'rm public/index.html'
		run 'rm public/images/rails.png'
		run 'rm -f public/javascripts/*'
	end

	git :add => '.'
	git :commit => '-a -m "Initial commit"'




puts "copying basic templates"
	in_root do
		run 'git clone git://github.com/amiel/rails-templates.git'
		run 'cp rails-templates/lib/helpers/* app/helpers'
		run "cp rails-templates/lib/javascripts/* #{JS_PATH}"
		run 'cp rails-templates/lib/layouts/* app/views/layouts'
		run 'cp rails-templates/README.rdoc TEMPLATE_README.rdoc'
		run 'rm -rf rails-templates'
	end
	
	git :add => '.'
	git :commit => '-m"Add files from template lib"'


puts "setting up gems"
	msg = ["gems and plugins\n"]
	gems = []
	
	gems << 'will_paginate'
	gem 'will_paginate'
	msg << "* will_paginate"
	
	gems << 'less'
	gem 'less'
	msg << "* less css"


	if options[:hoptoad] then
		plugin 'hoptoad_notifier', :git => 'git://github.com/thoughtbot/hoptoad_notifier.git'
		msg << "* hoptoad notifier\n"
	end
	
	if options[:paperclip] then
	  gems << 'paperclip'
	  gem 'paperclip'
	  msg << "* paperclip"
  end

	if options[:authlogic] then
	  gems << 'authlogic'
		gem 'authlogic'
		plugin 'authlogic_generator', :git => 'git://github.com/masone/authlogic_generator.git'
		
		msg << "* authlogic and authlogic_generator"
	end
	
	if options[:formtastic] then
	  gems << 'justinfrench-formtastic --source=http://gems.github.com'
		gem "justinfrench-formtastic", :lib => 'formtastic', :source => 'http://gems.github.com'
		plugin 'validation_reflection', :git => 'git://github.com/redinger/validation_reflection.git'
		
		msg << "* formtastic and validation_reflection"
	end

	if options[:sprockets] then
	  gems << 'sprockets'
		gem "sprockets"
		msg << "* sprockets and sprockets-rails"
	end
	
	if options[:spreadhead] then
	  gems << 'jeffrafter-spreadhead --source=http://gems.github.com'
		gem "jeffrafter-spreadhead", :lib => 'spreadhead', :source => 'http://gems.github.com'
		
		msg << "* spreadhead"
	end

  file '.gems', gems.join("\n") if options[:heroku]
  
  if system('rake gems|grep "\[ \]"') then
  	puts "Please enter your sudo password to install gems"
  	rake 'gems:install', :sudo => true
	end

	# these plugins make rake gems:install fail if their corresponding gem is not already installed
	plugin 'less_on_rails', :git => 'git://github.com/cloudhead/more.git'
	plugin 'sprockets-rails', :git => 'git://github.com/amiel/sprockets-rails.git' if options[:sprockets]
	msg << "* more (less plugin for rails)\n"
	

	git :add => '.'
	git :commit => "-m'#{msg.join("\n")}'"


if options[:authlogic]
	puts "setting up authlogic\n"
	
	# generate :session, 'user_session'
	generate :authlogic
	git :add => '.'
	git :commit => "-m'Authlogic generator'"
end

puts "setting up javascripts and stylesheets"
	msg = ["Add javascripts and stylesheets\n"]
	
	in_root do
		run "mkdir #{JS_PATH}/vendor"
		run "mkdir -p app/stylesheets/vendor"

		run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.3.2.min.js > #{JS_PATH}/vendor/jquery.js"
		msg << "* jquery-latest"

		if options[:sprockets] then
			file 'app/javascripts/application.js', "//= require <jquery>\n//= require \"base\"\n"
			msg << "* a basic application.js for sprockets"
		end
		
		run "touch app/stylesheets/application.less"
		run "touch app/stylesheets/print.less"
		msg << "* blank application.less and print.less"

		case options[:css_framework]
		when /960/
			setup_960gs
			msg << "* 960gs"
		when /sen/
			setup_sencss
			msg << "* sencss"
		else # reset
			setup_resetcss
			msg << "* resetcss"
		end
		
		if options[:spreadhead] then
			run 'curl -L http://github.com/amiel/rails-templates/raw/master/lib/stylesheets/spreadhead.css > app/stylesheets/vendor/_spreadhead.less'
			add_stylesheets_to_application 'vendor/_spreadhead'
		end
	end

	git :add => '.'
	git :commit => "-m'#{msg.join("\n")}'"


puts "setting up test libraries"
	msg = ["setup test libraries\n"]

	if options[:authlogic] then
		gsub_file 'test/test_helper.rb', /(require 'test_help')/, "\\1\nrequire 'authlogic/test_case'"
		msg << "* require authlogic test helpers in test_helper"	
	end
	
	gsub_file 'test/test_helper.rb', /(require 'test_help')/, "\\1\nrequire 'shoulda'\nrequire 'mocha'"
	msg << "* require shoulda and mocha in test_helper"
	
	gem 'cucumber', :env => 'test'
	gem 'mocha', :env => 'test'
	gem "thoughtbot-shoulda", :lib => "shoulda", :source => "http://gems.github.com", :env => 'test'
	gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com', :env => 'test'
	msg << "* add gems to test.rb"

	# this will fail if the cucumber gem is not already installed. thats fine though
	generate :cucumber, '--testunit'
	msg << "* generate cucumber"

	git :add => '.'
	git :commit => "-m'#{msg.join("\n")}'"
	

puts "other misc changes"
	msg = ["A few other misc changes from the template\n"]
	
  environment 'config.action_mailer.delivery_method = :sendmail', :env => :development
	msg << '* action_mailer uses sendmail for development'
	
	if options[:paperclip] and options[:heroku] do
    file 'config/s3.yml', "development:\n  access_key_id: abc\n  secret_access_key: abc/efg\n \ntest:\n  access_key_id: abc\n  secret_access_key: abc/efg\n \nproduction:\n  access_key_id: abc\n  secret_access_key: abc/efg\n"
    msg << '* s3 config scaffold for use with paperclip'
	end
	

	
	if options[:paperclip] then
    environment %q(ENV['PATH'] = "#{ENV['PATH']}:/opt/local/bin" # for macports), :env => :development
    msg << '* setup PATH for macports to give paperclip access to identify and convert'
  end
	
	if options[:capistrano] then
  	capify!
  	msg << "* capify!"
	end
	
	generate :controller, options[:first_controller_name], 'index'
	route "map.root :controller => '#{options[:first_controller_name]}'"
	msg << "* first controller #{options[:first_controller_name]}"
	
	time_zone = `rake time:zones:local|grep '\* UTC' -A 1|tail -1`.chomp
	gsub_file 'config/environment.rb', /(config.time_zone =) 'UTC'/, "\\1 '#{time_zone}'"
	msg << "* time zone: #{time_zone}"
	
  gsub_file 'config/environment.rb', /# (config.i18n.default_locale =) :\w+/, "\\1 :en"
	msg << "* default locale"
	
	gsub_file 'config/locales/en.yml', /(\s+)hello:.*/, "\\1site_name: #{app_name.titleize}\\1slogan: One awesomely cool site"
	msg << "* a couple of i18n strings that are used in application_helper"

	if options[:sprockets] then
		gsub_file 'app/views/layouts/_javascript.html.erb', /javascript(_include_tag ).*,( 'application')/, "sprockets\\1\\2"
		gsub_file 'app/helpers/layout_helper.rb', /javascript(_include_tag)/, "sprockets\\1"
		gsub_file 'config/sprockets.yml', /(\s+)(- app\/javascripts)$/, "\\1\\2\\1- app/javascripts/vendor"
		route "SprocketsApplication.routes(map)"
		msg << "* some basic sprockets setup"
	end
	
	if options[:hoptoad] then
		initializer('hoptoad.rb') do
			<<-RUBY
HoptoadNotifier.configure do |config|
	config.api_key = '#{options[:hoptoad_api_key]}'
end
			RUBY
		end

		msg << "* hoptoad notifier api_key"
	end
	
	if options[:formtastic] then
		generate :formtastic
		in_root do
			run "mv public/stylesheets/formtastic.css app/stylesheets/vendor/_formtastic.less"
			run "mv public/stylesheets/formtastic_changes.css app/stylesheets/_formtastic_changes.less"
		end
		
		add_stylesheets_to_application 'vendor/_formtastic', '_formtastic_changes'
		initializer('formtastic.rb', 'Formtastic::SemanticFormBuilder.i18n_lookups_by_default = true')
		
		msg << "* formtastic setup"
	end
	
	if options[:spreadhead] then
		generate :spreadhead
		file "app/views/#{options[:first_controller_name]}/index.html.erb", '<%= spreadhead "home" %>'
		
		spreadhead_filter = options[:authlogic] ? "controller.send(:redirect_to, '/') unless controller.send(:current_user)" : true
		gsub_file 'config/initializers/spreadhead.rb', /controller\.send\(:head, 403\)/, spreadhead_filter
		
		msg << "* spreadhead setup"
	end

	git :add => '.'
	git :commit => "-m'#{msg.join("\n")}'"





puts "\n\n\n"
puts "Sorry, but... one more question..."
if yes?('would you like to run migrations right now?') then
	rake :'db:migrate'
	
	if options[:spreadhead] then
		# it may be bad style to put db stuff here in the template, but it does help get a working app up quick.
		
		in_root do
			home_page_text = %{%Q{h1. Home page\\n\\nHere be the home page, go to "/pages":/pages to edit it.\\n\\n#{'You may need to "Sign Up":/signup for an account first.' if options[:authlogic]}}}
			run %{./script/runner 'Page.create :title => "Home", :published => true, :text => #{home_page_text}, :formatting => "textile"'}
		end
	end
	
	git :add => '.'
	git :commit => '-m"initial migration"'
	
end

git :remote => "add origin #{options[:git_repos]}" unless options[:git_repos].blank?

puts "\n\n"
puts "*. Change site_name and slogan in config/locales/en.yml"
puts "*. check your default_locale and time_zone"
puts "*. setup spreadhead filter at config/initializers/spreadhead.rb" if options[:spreadhead]
puts "*. use this for has_attached_file options: :storage => :s3, :s3_credentials => \"\#{Rails.root}/config/s3.yml\", :path => \":attachment/:id/:style.:extension\", :bucket => \"projectname\#{Rails.env}\"" if options[:paperclip] and options[:heroku]
puts "\n\n"