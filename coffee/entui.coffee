# Класс Moment v3.1
# Создавать как: obj = new EntUI
#
# Регистрация меты сущностей:
#   EntUI_add_entity entity_name, entity_meta
#
# Регистрация каллбаков:
#   EntUI_add_callback entity_name, callback_name, func
#
# Запуск работы:
#   obj.start target, entity_name [,entity_id]
#
# ****************************************************************************

class EntUI
  constructor: ->
    @entity_ok = {}
    @prefs = []
    @tables = {}
    @objs = {}
  meta: {}
  callbacks: {}

  # ---------------------------------------------------------------------------
  # запуск момента
  start: (target, entity_name, entity_id) ->
    if entity_id
      @form target, entity_name, entity_id
    else
      @table target, entity_name

  # ---------------------------------------------------------------------------
  # Построение лайота для таблицы
  table: (target, entity_name, parent_prefix="", parent_type, parent_id, foreign_key, parent_atr, ret_func_uplink, ret_fld_list) ->
    return false unless @verify_meta entity_name
    met = @meta[entity_name]
    prefix = parent_prefix + '-t-' + entity_name
    @add_prefix prefix, entity_name
    table_place = $ "<div class=\"table-place\" id=\"#{prefix}\"/>"
    # Построение таблицы
    table_type = if ret_func_uplink then 'uplink' else (if _.isEmpty(parent_prefix) then 'root' else 'downlink')
    is_window = table_type is 'uplink' and met.opts.uplink.window
    table_interface = met.opts[table_type].interface
    reload_func = ()-> # резервирование переменной
    # выбор строки в таблице
    open_dialog_func = (entity_id, p_type, p_id) => @form target, entity_name, entity_id, p_type, p_id, prefix, reload_func
    select_uplink_func = (data) =>
        if ret_func_uplink
          ret_func_uplink data
          @dialog_close table_place, prefix if is_window
    # создание таблицы в плагине
    @objs[prefix] = new @[table_interface](entity_name, met, @callbacks[entity_name],
      table_place, prefix, table_type, parent_type, parent_id, foreign_key, parent_atr, open_dialog_func, select_uplink_func, ret_fld_list)
    @objs[prefix].build()
    # обновление таблицы по внешней команде
    reload_func = ()=> @objs[prefix].build()
    $(target).append table_place
    if is_window
      @make_dialog table_place, {title: (met.window_header or 'Диалог выбора')}
    true

  # ---------------------------------------------------------------------------
  # Показ карточки сущности
  form: (target, entity_name, entity_id, parent_type, parent_id, parent_prefix="", reload_func) ->
    return false unless @verify_meta entity_name
    met = @meta[entity_name]
    prefix = parent_prefix + '-f-' + entity_name
    @add_prefix prefix, entity_name
    # Построение карточки
    show_place  = $ "<div class=\"show-place\" id=\"#{prefix}\" />"
    # Построение формы
    form_place  = $ "<div class=\"form-place\" id=\"#{prefix}-f\"/>"
    form_interface = met.opts['form'].interface
    # связь между плагинами формы и таблицы, которые друг о друге не знают и взаимодействуют через общую часть
    proxy_uplink_func = (uplink_entity_name, ret_fld_list, ret_func_uplink) =>
      @table form_place, uplink_entity_name, prefix, null, null, null, null, ret_func_uplink, ret_fld_list
    open_parent_func = (p_type, p_id) =>
      @form(form_place, p_type, p_id, parent_type, parent_id, prefix, ()=> @objs[prefix].build())
    @objs[prefix] = new @[form_interface](entity_name, met, @callbacks[entity_name],
      form_place, prefix, entity_id, parent_type, parent_id, reload_func, proxy_uplink_func, open_parent_func)
    @objs[prefix].build()
    show_place.append form_place
    # Построение табов
    tabs_place = $ "<div class=\"tabs-place\" id=\"#{prefix}-tabs\" />"
    show_place.append tabs_place
    ul = $("<ul />")
    tabs_place.append ul
    _.each (met.form_tabs or []), (tab) =>
      tab_pref = "-#{prefix}-tab-#{tab.name}"
      ul.append $("<li><a href=\"##{tab_pref}\">#{tab.label||tab.name}</a></li>")
      tab_pls = $("<div id=\"#{tab_pref}\"></div>")
      tabs_place.append tab_pls
      if tab.kind is 'downlink'
        @table tab_pls, (tab.entity or tab.name), prefix, entity_name, entity_id, tab.foreign_key, tab.atr
      else
        if @["EntUI_tab_#{tab.kind}"]
          @add_prefix tab_pref, entity_name
          @objs[tab_pref] = new @["EntUI_tab_#{tab.kind}"](tab_pls, tab_pref, tab, @callbacks, entity_name, entity_id)
          @objs[tab_pref].build()
        else
          @ac "ERROR: Не найден способ создания таба '#{tab.kind}' для сущности '#{entity_name}"
    # построение диалога
    $(target).append show_place
    ttl = if entity_id is 'new'
      met.form_header_new or 'Новый объект'
    else
      met.link?.form_header or met.form_header or 'Карточка'
    @make_dialog show_place, {title: ttl}
    # строим табы, блокируем клавиатурную навигацию по табам
    tabs_place.tabs activate: (event, ui)->
      ui.newTab.blur()
    tabs_place.find('a').click ()->
      $(this).blur()
    true

  # ---------------------------------------------------------------------------
  # Проверка коректности меты
  verify_meta: (entity_name) ->
    return true if @entity_ok[entity_name]
    unless met = @meta[entity_name]
      @ac "ERROR Не найдена мета для сущности '#{entity_name}'"
      return false
    if _.isEmpty met.cols
      @ac "ERROR Для сущности '#{entity_name}' не указаны колонки таблицы"
      return false
    # Делаем в мете полный комплект опций
    met.opts ?= {}
    default_opts =
      root: {window: false, create: true, edit: true, paging: true, filters: true, hidden_cols:[], interface: 'EntUIDataTable'}
      uplink: {window: true, create: true, edit: false, paging: true, filters: true, hidden_cols:[], interface: 'EntUIDataTable'}
      downlink: {window: false, create: true, edit: true, paging: true, filters: false, hidden_cols:[], interface: 'EntUIDataTable'}
      form: {readonly: false, hidden_cols:[], interface: 'EntUIEditForm'}
    is_interface_err = null
    _.each _.keys(default_opts), (k) =>
      m = met.opts?[k] or {}
      met.opts[k] = m = $.extend {}, default_opts[k], m
      met.opts[k].hidden_cols = met[k].hidden_cols if met[k]?.hidden_cols
      is_interface_err = k unless @[m.interface]
    # проверка наличия всех подключаемых интерфейсов
    if is_interface_err
      @ac "ERROR Для сущности '#{entity_name}' не найден класс #{met.opts[is_interface_err].interface} указанный в #{is_interface_err} "
      return false
    o = met.opts
    if o.root.create or o.downlink.create or o.uplink.create or o.root.edit or o.downlink.edit or o.uplink.edit
      unless met.form
        @ac "ERROR Для сущности '#{entity_name}' не задана форма"
        return false
    @ac "OK Проверена мета для сущности '#{entity_name}'"
    @entity_ok[entity_name] = true
    return true

  # ---------------------------------------------------------------------------
  make_dialog: (target,pars) ->
    deflt = {"autoOpen": true,"modal": true,"width": "auto","height": "auto"}
    target.dialog ($.extend {}, deflt, pars)
    target.on "dialogclose", ()=> @del_prefix(target.attr('id'))

  # ---------------------------------------------------------------------------
  # Новый префикс в стеке
  add_prefix: (prefix, entity_name)->
    if _.indexOf(@prefs, prefix)<0
      @prefs.push prefix
    else
      @ac "ERROR Для сущности '#{entity_name}' появился дублирующийся префикс #{prefix}"

  # ---------------------------------------------------------------------------
  # Удаление префикса и всех, что выше
  del_prefix: (prefix) ->
    if _.indexOf(@prefs, prefix)>=0
      while pr = @prefs.pop()
        delete @objs[pr] if @objs[pr]
        return if pr is prefix

  # ---------------------------------------------------------------------------
  # закрытие диалога и чистка всех данных выше указанного префикса
  dialog_close: (targrt, prefix) ->
    targrt.dialog "close"

  # ***************************************************************************
  # служебное и отладочное
  # ---------------------------------------------------------------------------
  ac: (msg) -> console.log msg

# *****************************************************************************
# Методы вне класса
window.EntUI = EntUI
# -----------------------------------------------------------------------------
# Добавление сущности
# должна выполняться после загрузки Moment но до создания экземпляра
window.EntUI_add_entity = (entity_name, entity_meta) ->
  EntUI::meta[entity_name] = entity_meta
  EntUI::callbacks[entity_name] = EntUI::callbacks[entity_name] or {}

# -----------------------------------------------------------------------------
# Регистрация коллбаков
#  должна выполняться после загрузки Moment но до создания экземпляра
window.EntUI_add_callback = (entity_name, callback_name, func) ->
  return null unless typeof func is "function"
  EntUI::callbacks[entity_name] = EntUI::callbacks[entity_name] or {}
  EntUI::callbacks[entity_name][callback_name] = func


# -----------------------------------------------------------------------------
jQuery.fn.EntUI = (entity_name, entity_id) ->
  if entity_name
    obj = new EntUI()
    obj.start $(@[0]), entity_name, entity_id
    jQuery.data $(@[0]), "EntUI", obj
    obj
  else
    jQuery.data $(@[0]), "EntUI"
