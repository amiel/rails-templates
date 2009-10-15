
def ask_with_default(q, default)
	response = ask("#{q} default: #{default}")
	response.blank? ? default : response
end


def setup_960gs
	run 'git clone git://github.com/davemerwin/960-grid-system.git'
	run 'mkdir app/stylesheets/960gs'
	run 'cp 960-grid-system/code/css/*.css app/stylesheets/960gs'
	run 'rm -rf 960-grid-system'
	
	# TODO add to application.html.erb
end

def setup_resetcss
	
end

def setup_senscss
	
end

puts 'ok, some questions before we get started'

	options = {}

	options[:css_framework] = ask_with_default('What CSS framework would you like to start with? options are 960gs, sens, reset', 'reset')
	options[:jqtools] = yes?('would you like jQuery tools?')
	options[:sprockets] = yes?('would you like sprockets?')
	
	JS_PATH = options[:sprockets] ? 'app/javascripts' : 'public/javascripts'
	
	options[:first_controller_name] = ask_with_default('What would you like to call your first base controller?', 'static')
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
	gem 'less'
	plugin 'less_on_rails', :git => 'git://github.com/cloudhead/more.git'
	msg << "* less and more\n"


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

	puts "Please enter your sudo password to install gems"
	rake 'gems:install', :sudo => true

	git :add => '.'
	git :commit => "-m'#{msg}'"


puts "setting up javascripts and stylesheets"
	msg = "Add javascripts and stylesheets\n\n"
	
	msg << "* jquery-latest\n"
	msg << "* blank screen.less and print.less\n"
	in_root do
		run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.3.2.min.js > #{JS_PATH}/jquery.js"
		run "touch app/stylesheets/screen.less"
		run "touch app/stylesheets/print.less"
	end

	case options[:css_framework]
	when /960gs/
		msg << "* 960gs\n"
		setup_960gs
	when /sens/
		msg << "* senscss\n"
		setup_senscss
	else # reset
		msg << "* resetcss\n"
		setup_resetcss
	end

	git :add => '.'
	git :commit => "-m'#{msg}'"


puts "setting up test libraries"
	msg = "setup test libraries\n\n"

	if options[:authlogic] then
		msg << "* require authlogic test helpers in test_helper\n"	
		gsub_file 'test/test_helper.rb', /(require 'test_help')/, "\\1\nrequire 'authlogic/test_case'"
	end
	
	msg << "* require shoulda and mocha in test_helper\n"
	gsub_file 'test/test_helper.rb', /(require 'test_help')/, "\\1\nrequire 'shoulda'\nrequire 'mocha'"
	
	msg << "* add gems to test.rb"
	gem 'cucumber', :env => 'test'
	gem 'mocha', :env => 'test'
	gem "thoughtbot-shoulda", :lib => "shoulda", :source => "http://gems.github.com", :env => 'test'
	gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com', :env => 'test'
	
 	# TODO, run cucumber generator

	git :add => '.'
	git :commit => "-m'#{msg}'"
	


puts ""