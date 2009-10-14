
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

		run 'touch tmp/.keep log/.keep vendor/.keep'
		run 'rm public/index.html'
		run 'rm -f public/javascripts/*'
	end

	git :add => '.'
	git :commit => "-a -m 'Initial commit'"




puts "copying basic helper files"
	# TODO: copy basic helper files

	


puts "setting up gems"
	gem 'less'
	plugin 'less_on_rails', :git => 'git://github.com/cloudhead/more.git'


	if options[:hoptoad] then
		plugin 'hoptoad_notifier', :git => 'git://github.com/thoughtbot/hoptoad_notifier.git'

		initializer('hoptoad.rb') do
			<<-RUBY
HoptoadNotifier.configure do |config|
	config.api_key = '#{options[:hoptoad_api_key]}'
end
			RUBY
		end
	end

	if options[:authlogic] then
		gem 'authlogic'
		plugin 'authlogic_generator', :git => 'git://github.com/masone/authlogic_generator.git'
	end

	rake 'gems:install', :sudo => true



puts "setting up javascripts and stylesheets"

	in_root do
		run "curl -L http://jqueryjs.googlecode.com/files/jquery-latest.min.js > #{JS_PATH}/jquery.js"
		run "touch app/stylesheets/screen.less"
		run "touch app/stylesheets/print.less"
	end

	case options[:css_framework]
	when /960gs/
		setup_960gs
	when /sens/
		setup_senscss
	else # reset
		setup_resetcss
	end



puts "setting up test stuffs"
 	# TODO, run cucumber generator
	gsub_file 'test/test_helper.rb', /(require 'test_help')/, "\\1\nrequire 'authlogic/test_case'" if options[:authlogic]
	gsub_file 'test/test_helper.rb', /(require 'test_help')/, "\\1\nrequire 'shoulda'"

	gem 'cucumber', :env => 'test'
	gem 'mocha', :env => 'test'
	gem "thoughtbot-shoulda", :lib => "shoulda", :source => "http://gems.github.com", :env => 'test'
	gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com', :env => 'test'
