module JavascriptHelper

  def js_vars_with_scope(scope)
    @_js_var_scope = scope
    yield
    @_js_var_scope = nil
  end

  def js_var(key, value, scope = @_js_var_scope)
    content_for(:in_javascript) { "Base.reg(#{ key.to_json }, #{ value.to_json }#{ ", " + scope.to_json if scope });" }
  end

  def assign_i18n_for_javasrcipt
    js_var :I18n, I18n.backend.send(:translations)[I18n.locale.to_sym][:js]
  end

  def include_javascript_from_cdn *thems_libraries
    google_prefix = 'http://ajax.googleapis.com/ajax/libs/'
    libs = {
      :jquery    => google_prefix + 'jquery/1.4.1/jquery.min.js',
      :jqtools   => 'http://cdn.jquerytools.org/1.1.2/jquery.tools.min.js',
    }
    
    javascript_include_tag( *thems_libraries.collect{|which| libs[which] or raise ArgumentError, "I dont know about #{which}" } )
  end
end
