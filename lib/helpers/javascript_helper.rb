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

  def include_javascript_from_google *thems_libraries
    thems_libraries.collect do |which|
      javascript_include_tag( 'http://ajax.googleapis.com/ajax/libs/' +
        case which
          when :jquery    : 'jquery/1.3.2/jquery.min.js'
          when :jqueryui  : 'jqueryui/1.7.2/jquery-ui.min.js'
          else raise ArgumentError, "I dont know about #{which}"
        end
      )
    end
  end
end
