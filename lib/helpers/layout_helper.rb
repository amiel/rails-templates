module LayoutHelper
  
  def body_class
    "#{controller.controller_name} #{controller.controller_name}-#{controller.action_name}"
  end
  
	def render_title(section = :site_name)
		title = @_title || @content_for_title
		if title then
			"#{title} - #{t(section)}"
		else
			"#{t(section)} - #{t(:slogan)}"
		end
	end
	
	# examples:
	#   <% title 'foobar' %> # => set the <title> to 'foobar'
	#   <%= title %> # => set the <title> from I18n and output an <h1> with the same string
	def title(str = t(:'.title'))
	  @_title = str
	  content_tag :h1, str
	end
	

	def javascript(name)
		content_for(:javascript) { javascript_include_tag name }
	end

	def stylesheet(name)
		content_for(:head) { stylesheet_link_tag name }
	end

end
