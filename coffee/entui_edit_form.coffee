# Контрол форма редактирования для EntUI
#
# Публичные функции
# Конструктор:
# new EntUI::EntUIEditForm(entity_name, meta, callbacks, target, prefix, entity_id, parent_type, parent_id,
#    reload_func, select_uplink_func, open_parent_func)
#
# Построение формы: build()
#

class EntUIEditForm
  constructor: (entity_name, meta, callbacks, target, prefix, entity_id, parent_type, parent_id,
    reload_func, select_uplink_func, open_parent_func) ->
    @entity_name = entity_name
    @meta = meta
    @callbacks = callbacks
    @target = target
    @prefix = prefix
    @entity_id = entity_id
    @parent_type = parent_type
    @parent_id = parent_id
    @reload_func = reload_func
    @select_uplink_func = select_uplink_func
    @open_parent_func = open_parent_func
    @clear()

  # ---------------------------------------------------------------------------
  # очистка временных переменных и подложки
  clear: ()->
    @target.empty()
    @visible_data = {}
    @objs = {}
    @fld_meta = {}
    @flds = {}

  # ---------------------------------------------------------------------------
  # Построение формы
  build: ()->
    @clear()
    if @entity_id and @entity_id isnt 'new'
      # запрашиваем данные
      req = $.getJSON "/data/form/#{@entity_name}", {entity_id: @entity_id}
      req.error ()=> @ac "ERROR: Ошибка получения данных формы для сущности #{@entity_name}"
      req.success (data)=>
        @visible_data = data
        @build_form true
    else
      @entity_id = null
      @visible_data = {}
      @build_form false


  build_form: (is_edit)->
    # строим и оживляем кнопки
    buttons_div = $("<div id=\"#{@prefix}-btn\" class=\"contextual\" />")
    button_data = if @meta.opts.form?.readonly then [] else [
      {"icon":"save","name":"save_entity","text": (if is_edit then "сохранить" else "создать"),"func": ()=> @save()}
    ]
    _.each button_data, (b)=>
      button = $("<a class=\"icon icon-#{b.icon}\" id=\"#{@prefix}-b-#{b.name}\">#{b.text}</a>")
      button.click b.func
      buttons_div.append button
    @target.append buttons_div
    if is_edit and @meta.label_template
      hdr = _.reduce _.keys(@visible_data), ((lab, k)=> lab = lab.replace('#{'+k+'}',@visible_data[k])), @meta.label_template
      @target.append "<h2 id=\"#{@prefix}-hdr\">#{hdr}</h2>"
    # строим тело формы
    ft=$("<table style=\"border-collapse: collapse;\" />")
    _.each @meta.form, (cells_lst)=>
      cells = cells_lst[0]
      tr = $("<tr />")
      @set_pars tr, cells_lst[1]
      _.each cells, (cmeta)=>
        @fld_meta[cmeta.atr] = cmeta
        kind = cmeta.kind or 'text'
        td_label = $("<td align=\"right\" />")
        td = $("<td />")
        tr.append td_label
        tr.append td
        unless _.isEmpty cmeta
          fldn = @prefix + "-" + cmeta.atr
          td_label.attr("id", fldn + "-label")
          td_label.text cmeta.label or ''
          hpars = {td: (cmeta.html?.td or {}), input: (cmeta.html?.input or {}), span: (cmeta.html?.span or {})}
          hpars.td.style ?= ''
          hpars.td.style += "white-space:nowrap;"
          @set_pars(td,hpars.td)
          if @["create_fld_#{kind}"]
            @flds[cmeta.atr] = @["create_fld_#{kind}"](td, fldn, cmeta.atr, hpars.input, @visible_data[cmeta.atr])
            @callbacks.form_after_create_field td, @visible_data[cmeta.atr], cmeta.atr, cmeta.atr if @callbacks.form_after_create_field
          else
            if @["EntUI_fld_#{kind}"]
              @objs[cmeta.atr] = new @["EntUI_fld_#{kind}"](td, fldn, cmeta.atr, cmeta, hpars.input, @visible_data[cmeta.atr], @callbacks)
              @flds[cmeta.atr] = @objs[cmeta.atr].build()
              @callbacks.form_after_create_field td, @visible_data[cmeta.atr], cmeta.atr, cmeta.atr if @callbacks.form_after_create_field
            else
              @ac "ERROR: Не найден способ создания поля типа '#{kind}' для сущности '#{@entity_name}"
        ft.append tr
    @target.append ft
    @callbacks.form_after_open @target, @visible_data, @meta.form if @callbacks.form_after_open

  # ---------------------------------------------------------------------------
  # Сохранение формы
  save: ()->
    d = {}
    _.each _.keys(@flds), (f)=> d[f] = @flds[f].val()
    d['id'] = @entity_id or ''
    jQuery.ajax (@meta.url_save or "/data/update/#{@entity_name}"),
      data: {data: d}
      type: 'POST'
      dataType: 'json'
      timeout: 20000
      success: (data)=>
        if data.errors
          @alert data.errors
        else
          @clear()
          @visible_data = data
          @build_form true
          @reload_func()
      error: ()=>
        @ac "ERROR: Ошибка получения данных формы для сущности #{@entity_name}"


  # ***************************************************************************
  # создание полей
  # ---------------------------------------------------------------------------
  create_fld_text: (td, pref, fldn, pars, value)->
    fld = $("<input type=\"text\" id=\"#{pref}\" />")
    @set_pars fld, pars
    fld.val value if value
    td.append fld
    fld

  create_fld_textarea: (td, pref, fldn, pars, value)->
    fld = $("<textarea id=\"#{pref}\" rows=\"5\" cols=\"60\">#{value or ''}</textarea>")
    @set_pars fld, pars
    td.append fld
    fld

  create_fld_date: (td, pref, fldn, pars, value)->
    fld = @create_fld_text td, pref, fldn, pars, value
    fld.datepicker dateFormat: "dd.mm.y ", showOn: "button"
    fld

  create_fld_datetime: (td, pref, fldn, pars, value)->
    fld = @create_fld_text td, pref, fldn, pars, value
    fld.datetimepicker lang:"ru", format:"d.m.y H:i", dayOfWeekStart:1, weeks:true, step:15, minTime:"7:00", maxTime:"18:00",
      onShow: (t, me)=>
        @callbacks.datetimepicker_onShow t, me if @callbacks.datetimepicker_onShow
    fld

  create_fld_frozentext: (td, pref, fldn, pars, value)->
    fld = @create_fld_text td, pref, fldn, pars, value
    fld.attr "disabled", true
    fld

  create_fld_sel: (td, pref, fldn, pars, value)->
    fld = $("<select id=\"#{pref}\" />")
    @set_pars fld, pars
    _.each (@fld_meta[fldn].selector or []), (s)->
      fld.append $("<option value=\"#{s[1] or s[0]}\">#{s[0]}</option>")
    fld.val value if value
    td.append fld
    fld

  create_fld_span: (td, pref, fldn, pars, value)->
    value ?=  ''
    fld = $("<span id=\"#{pref}\">#{value}</span>")
    td.attr "style", ""
    @set_pars fld, pars
    fld.val value
    td.append fld
    fld

  create_fld_link: (td, pref, fldn, pars, value)->
    e_name = @fld_meta[fldn].entity or fldn
    if (@entity_id is null) and @parent_type and @parent_id and (@parent_type is e_name)
      return @create_fld_hidden td, pref, fldn, {}, value or @parent_id
    name = @visible_data[fldn+"_name"] or ''
    tbl = $("<table style=\"border-collapse: collapse;\" />")
    tr = $("<tr />")
    hid = $("<input id=\"#{pref}\" type=\"hidden\" value=\"#{value}\">")
    hname = $("<span id=\"#{pref}_name\" class=\"ref_field link_selectable\">#{name}</span>")
    hsel = $("<a class=\"icon icon-edit\" id=\"#{pref}-change_uplink\" title=\"изменить ссылку\"></a>")
    hclear = $("<a class=\"icon icon-false\" id=\"#{pref}-clear_uplink\" title=\"очистить ссылку\"></a>")
    ret_fld_list = [@fld_meta[fldn].id_atr or 'id', @fld_meta[fldn].name_atr or 'name']
    hsel.click ()=>
      @select_uplink_func (@fld_meta[fldn].entity or fldn), ret_fld_list, (data)=>
        hid.val data[ret_fld_list[0]]
        hname.text data[ret_fld_list[1]]
    hclear.click ()=>
        hid.val ''
        hname.text ''
    hname.click ()=>
      unless hid.val() is null or hid.val() is 'null' or hid.val() is ''
        @open_parent_func (@fld_meta[fldn].entity or fldn), value
    tbl.append hid, tr.append($("<td />").append(hname))
    unless @fld_meta[fldn].frozen
      tbl.append tr.append($("<td />").append(hsel)), tr.append($("<td />").append(hclear))
    td.append tbl
    hid

  create_fld_hidden: (td, pref, fldn, pars, value)->
    fld = $("<input type=\"hidden\" id=\"#{pref}\" />")
    fld.val value if value isnt null
    td.append fld
    td.parent().find("##{pref}-label").text ''
    fld


  # ***************************************************************************
  # служебное и отладочное
  # ---------------------------------------------------------------------------
  ac: (msg) -> console.log "EntUIEditForm: #{msg}"
  # ---------------------------------------------------------------------------
  set_pars: (target, hash_pars={})->
    target.attr key, hash_pars[key] for key in _.keys(hash_pars)
  # ---------------------------------------------------------------------------
  alert: (msg)->
    clbk = @callbacks.entity_alert
    alert(msg) unless clbk and clbk(msg)


EntUI::EntUIEditForm = EntUIEditForm
