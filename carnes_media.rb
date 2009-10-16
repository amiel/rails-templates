app_name = File.basename(File.expand_path(@root))

def ask_with_default(q, default)
	response = ask("#{q} default: #{default}")
	response.blank? ? default : response
end

def add_stylesheets_to_application_layout(*stylesheets)
	gsub_file 'app/views/layouts/application.html.erb', /(stylesheet_link_tag)(.*)('screen')/, "\\1\\2#{stylesheets.collect{|s| "'#{s}', " }}\\3"
end

def setup_960gs
	run 'curl -L http://github.com/davemerwin/960-grid-system/raw/master/code/css/reset.css > app/stylesheets/reset.less'
	run 'curl -L http://github.com/davemerwin/960-grid-system/raw/master/code/css/960.css > app/stylesheets/960.less'
	add_stylesheets_to_application_layout 'reset', '960'
end

def setup_resetcss
	run 'curl -L http://github.com/davemerwin/960-grid-system/raw/master/code/css/reset.css > app/stylesheets/reset.less'
	add_stylesheets_to_application_layout 'reset'
end

def setup_sencss
	run 'curl -L http://sencss.googlecode.com/files/sen.0.6.min.css > app/stylesheets/sen.less'
	add_stylesheets_to_application_layout 'sen'
end

puts 'ok, some questions before we get started'

	options = {}

	options[:css_framework] = ask_with_default('What CSS framework would you like to start with? options are 960gs, sen, reset', 'reset')
	# options[:jqtools] = yes?('would you like jQuery tools?')
	options[:sprockets] = yes?('would you like sprockets?')
	
	JS_PATH = options[:sprockets] ? 'app/javascripts' : 'public/javascripts'
	
	options[:first_controller_name] = ask_with_default('What would you like to call your first controller?', 'static')
	options[:authlogic] = yes?('would you like authlogic setup for authentication?')
	options[:paperclip] = yes?('would you like paperclip?')
	options[:hoptoad] = yes?('would you like the hoptoad notifier?')
	options[:hoptoad_api_key] = ask('please enter your hoptoad api key (ok to leave blank)') if options[:hoptoad]
	
	y options

	begin; puts "ABORT"; exit; end if no?('is this all ok?')

puts "setting up git"

	git :init

	file'.gitignore' do
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
	msg = "gems and plugins\n\n"
	
	gem 'will_paginate'
	msg << "* will_paginate\n"
	
	gem 'less'
	msg << "* less css\n"


	if options[:hoptoad] then
		plugin 'hoptoad_notifier', :git => 'git://github.com/thoughtbot/hoptoad_notifier.git'

		initializer('hoptoad.rb') do
			<<-RUBY
HoptoadNotifier.configure do |config|
	config.api_key = '#{options[:hoptoad_api_key]}'
end
			RUBY
		end
		
		msg << "* hoptoad notifier\n"
	end

	if options[:authlogic] then
		gem 'authlogic'
		plugin 'authlogic_generator', :git => 'git://github.com/masone/authlogic_generator.git'
		
		msg << "* authlogic and authlogic_generator\n"
	end


	if options[:sprockets] then
		gem "sprockets"
		plugin 'sprockets-rails', :git => 'git://github.com/amiel/sprockets-rails.git'
		msg << "* sprockets and sprockets-rails\n"
	end

	puts "Please enter your sudo password to install gems"
	rake 'gems:install', :sudo => true

	# install more plugin after gems have been installed because the plugin doesn't allow you to run rake without the gem installed
	plugin 'less_on_rails', :git => 'git://github.com/cloudhead/more.git'
	msg << "* more (less plugin for rails)\n"
	

	git :add => '.'
	git :commit => "-m'#{msg}'"


puts "setting up javascripts and stylesheets"
	msg = "Add javascripts and stylesheets\n\n"
	
	in_root do
		run "mkdir #{JS_PATH}/vendor"
		run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.3.2.min.js > #{JS_PATH}/vendor/jquery.js"
		msg << "* jquery-latest\n"

		if options[:sprockets] then
			file 'app/javascripts/application.js', "//= require <jquery>\n//= require \"base\"\n"
			msg << "* a basic application.js for sprockets\n"
		end
		
		run "touch app/stylesheets/screen.less"
		run "touch app/stylesheets/print.less"
		msg << "* blank screen.less and print.less\n"

		case options[:css_framework]
		when /960/
			setup_960gs
			msg << "* 960gs\n"
		when /sen/
			setup_sencss
			msg << "* sencss\n"
		else # reset
			setup_resetcss
			msg << "* resetcss\n"
		end
	end

	git :add => '.'
	git :commit => "-m'#{msg}'"


puts "setting up test libraries"
	msg = "setup test libraries\n\n"

	if options[:authlogic] then
		gsub_file 'test/test_helper.rb', /(require 'test_help')/, "\\1\nrequire 'authlogic/test_case'"
		msg << "* require authlogic test helpers in test_helper\n"	
	end
	
	gsub_file 'test/test_helper.rb', /(require 'test_help')/, "\\1\nrequire 'shoulda'\nrequire 'mocha'"
	msg << "* require shoulda and mocha in test_helper\n"
	
	gem 'cucumber', :env => 'test'
	gem 'mocha', :env => 'test'
	gem "thoughtbot-shoulda", :lib => "shoulda", :source => "http://gems.github.com", :env => 'test'
	gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com', :env => 'test'
	msg << "* add gems to test.rb\n"
	
 	# TODO, run cucumber generator

	git :add => '.'
	git :commit => "-m'#{msg}'"
	

puts "other misc changes"
	msg = "A few other misc changes from the template\n\n"
	
	generate :controller, options[:first_controller_name]
	route "map.root :controller => '#{options[:first_controller_name]}'"
	msg << "* first controller #{options[:first_controller_name]}"
	
	time_zone = `rake time:zones:local|grep '\* UTC' -A 1|tail -1`.chomp
	gsub_file 'config/environment.rb', /(config.time_zone =) 'UTC'/, "\\1 '#{time_zone}'"
	msg << "* time zone: #{time_zone}\n"
	
  gsub_file 'config/environment.rb', /# (config.i18n.default_locale =) :\w+/, "\\1 :en"
	msg << "* default locale\n"
	
	gsub_file 'config/locales/en.yml', /\s+hello:.*/, "\n\tsite_name: #{app_name.titleize}\n\tslogan: One awesomely cool site"
	msg << "* a couple of i18n strings that are used in application_helper\n"

	if options[:sprockets] then
		gsub_file 'app/views/layouts/_javascript.html.erb', /javascript(_include_tag ).*,( 'application')/, "sprockets\\1\\2"
		route "SprocketsApplication.routes(map)"
		msg << "* some basic sprockets setup\n"
	end

	# TODO generate authlogic codes

	git :add => '.'
	git :commit => "-m'#{msg}'"


puts ""
puts "1. Change site_name and slogan in config/locales/en.yml"
puts "2. check your default_locale and time_zone"