# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def body_class
    "#{controller.controller_name} #{controller.controller_name}-#{controller.action_name}"
  end
  
	def render_title
    # @_title ||= yield :title
		if @_title then
			"#{t('site_name')} | #{@_title}"
		else
			"#{t('site_name')} - #{t('slogan')}"
		end
	end
	
	def title(str)
	  @_title = str
	end
	

	def javascript(name)
		content_for(:javascript) { javascript_include_tag name }
	end

	def stylesheet(name)
		content_for(:head) { stylesheet_link_tag name }
	end

end
