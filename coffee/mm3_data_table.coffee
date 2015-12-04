# Контрол таблица для момента v3
#
# Публичные функции
# Конструктор:
# new Mm3::Mm3DataTable(entity_name, meta, callbacks, target, prefix, table_type, parent_type, parent_id,
#    open_dialog_func, select_uplink_func, ret_fld_list)
#
# Построение таблицы: build()
#

class Mm3DataTable
  constructor: (entity_name, meta, callbacks, target, prefix, table_type, parent_type, parent_id,
    open_dialog_func, select_uplink_func, ret_fld_list) ->
    @entity_name = entity_name
    @meta = meta
    @opts = meta.opts[table_type]
    @callbacks = callbacks
    @target = target
    @prefix = prefix
    @table_type = table_type
    @parent_type = parent_type
    @parent_id = parent_id
    @open_dialog_func = open_dialog_func
    @select_uplink_func = select_uplink_func
    @ret_fld_list = ret_fld_list
    @clear()

  # ---------------------------------------------------------------------------
  # построение таблицы
  build: () ->
    @clear()
    @build_filters()
    @buld_button()
    @build_table()

  # ---------------------------------------------------------------------------
  # очистка временных переменных и подложки
  clear: ()->
    @target.empty()
    @wait_window = null
    @et_wrap = null
    @visible_data = []
    @col_numbers = {}
    @table = null
    @is_dlg_open = false

  # ---------------------------------------------------------------------------
  # построение фильтров
  build_filters: () ->
    filter_table = $('<table class="filter_table"/>').hide()
    tr_lab = $('<tr>')
    tr_sel = $('<tr>')
    _.each (@meta.filters or []), (f)=>
      lab = f.label
      unless lab
        col = _.find @meta.cols, (c) -> c.atr is f.atr
        lab = col.label if col
        lab ?= f.atr
      tr_lab.append "<td>#{lab}</td>"
      sel = $("<select id=\"#{@prefix}-flt-#{f.atr}\" class=\"#{@prefix}-seltag\" />")
      sel.change ()=> @filter_change f.atr, sel.val()
      tr_sel.append $('<td />').append(sel)
      clear_filters_button = $("<td id=\"#{@prefix}-entity_clear_filters\" class=\"icon icon-false\"> </td>").hide()
      clear_filters_button.click ()=> @clear_filters()
      tr_lab.append $("<td />")
      tr_sel.append clear_filters_button
      filter_table.append(tr_lab).append(tr_sel)
    if @opts.filters and @meta.filters
      @wait()
      req = $.getJSON "/data/filters/#{@entity_name}", {type: 'json', prefix: @prefix}
      req.error ()=> @ac "ERROR: Ошибка получения фильтров для сущности #{@entity_name}"
      req.success (data)=>
        _.each _.keys(data), (k)=>
          sel = tr_sel.find "##{@prefix}-flt-#{k}"
          if sel.length is 1
            _.each data[k], (s)->
              val=s[1]||s[0]
              sel.append $("<option>").val(val).text(s[0])
            sel[0].selectedIndex=0
            @callbacks.table_after_filter_setup sel if @callbacks.table_after_filter_setup
        @continue()
        filter_table.show()
      @target.append filter_table

  # ---------------------------------------------------------------------------
  filter_change: (atr, val)->
    return unless @table_update()
    show = false
    for sel in @target.find('.filter_table select')
      show = true unless $(sel).val() is ''
    if show
      @target.find("##{@prefix}-entity_clear_filters").show()
    else
      @target.find("##{@prefix}-entity_clear_filters").hide()

  # ---------------------------------------------------------------------------
  table_update: ()->
    if @table
      if @table.fnSettings
        @table.fnSettings._iDisplayStart=0;
        @table.fnDraw();
        true
      else
        @ac "ERROR: не удалось обновить таблицу #{@prefix}"
        false

  # ---------------------------------------------------------------------------
  clear_filters: ()->
    for sel in @target.find('.filter_table select')
      $(sel).val('')
    @target.find("##{@prefix}-entity_clear_filters").hide()
    @table_update()

  # ---------------------------------------------------------------------------
  # Кнопки над таблицей
  buld_button: ()->
    buttons_div = $('<div class="contextual" />')
    button_data=[
      {icon:"true", name:"select_uplink", text:"выбрать&nbsp;", hide: true, func: ()=>
        select_flds = @get_select_fld()
        @select_uplink_func select_flds if select_flds and @select_uplink_func
        false
      }
      {icon: "add", name:"create_entity", text: @meta.button_label_create||'добавить&nbsp;', hide: !@opts.create, func: ()=>
        @open_dialog_func 'new', @parent_type, @parent_id if  @open_dialog_func
        false
      }
    ]
    _.each button_data, (bd)=>
      button = $("<a id=\"#{@prefix}-#{bd.name}\" class=\"icon icon-#{bd.icon}\">#{bd.text}</a>")
      button.click bd.func
      button.hide() if bd.hide
      buttons_div.append button
    @target.append buttons_div

  build_table: ()->
    @target.append $("<h2>#{@meta.table_header}</h2>")
    @target.append $("<style>##{@prefix}-entity_table td{text-align:center;}</style>")
    et = $("<table id=\"#{@prefix}-entity_table\"></table>")
    th_s = "<thead><tr>"
    th_s = _.reduce @meta.cols, ((s, c)=> s+= "<th>#{c.label}</th>"), th_s
    th_s += "</tr></thead>"
    et.append $(th_s)
    @target.append et
    # строим хеш колонок и список невидимых
    @col_numbers[c.atr]=i for c, i in @meta.cols
    hiden_numbers = _.map @opts.hidden_cols, (c)=> @col_numbers[c]
    # инициализируем таблицу
    table_pars =
      sAjaxSource: @meta.url_table or "/data/table/#{@entity_name}"
      bPaginate: !(!@opts.paging)
      aoColumnDefs: [{bVisible: false, aTargets: hiden_numbers}]
      # параметры запроса - собираем фильтры
      fnServerParams: (aoData)=>
        # параметры запроса - собираем фильтры
        _.each (@meta.filters or []), (f)=>
          v = @target.find($("##{@prefix}-flt-#{f.atr}")).val()
          aoData.push { "name": f.atr, "value": v} if v
        # если дочерний элемент, ссылаемся на папу
        if @parent_id
          aoData.push {"name":"parent_id","value":@parent_id}
          aoData.push {"name":"parent_type","value":@parent_type}
          aoData.push {"name":"prefix","value":@prefix}
          aoData.push {"name":"parent_prefix","value":@get_parent_prefix()}
        # если есть коллбэк, отрабатываем
        @callbacks.table_server_params et, aoData if @callbacks.table_server_params
      # постобработка ряда
      fnCreatedRow: (nRow,aData,iDataIndex) =>
        # помечаем ряд
        nRow.id = @prefix + "-tr-" + iDataIndex
        # оживляем doubleclick
        $(nRow).dblclick ()=> @open_dialog_func @get_id_by_row(nRow.id), @parent_type, @parent_id
        # включаем selectable
        $(nRow).click ()=> @uplink_make_row_selection iDataIndex, $(nRow)
        # если есть коллбэк, отрабатываем
        @callbacks.table_created_row nRow, aData, iDataIndex, @prefix if @callbacks.table_created_row
      # запоминание пришедших данных
      fnDrawCallback: (oSettings)=>
        # если есть коллбэк, отрабатываем
        @callbacks.table_after_redraw et if @callbacks.table_after_redraw
        # сохраняем данные
        @visible_data = _.map oSettings.aoData, (d)-> d._aData
    @table = @make_datatable et, table_pars
    @table.fnSetFilteringDelay 3000

  # ---------------------------------------------------------------------------
  # возвращает id из выбранной строки или null, если такой нет
  get_select_fld: ()->
    rows = @table.find('.row_selected')
    return null if rows.length isnt 1
    row_num = rows.attr('id').split('-').pop()*1
    ret = {}
    _.each (@ret_fld_list or []), (fld)=>
      col_num = @col_numbers[fld]
      ret[fld] = @visible_data[row_num][col_num]
    ret

  # ---------------------------------------------------------------------------
  # выбор строки таблицы сущности в режиме выбора аплинка
  uplink_make_row_selection: (row_number, row)->
    return false unless @table_type is 'uplink'
    clear = ()=>
      @table.find('.row_selected').removeClass('row_selected')
      @table.find('._odd').addClass('odd').removeClass('_odd')
      @table.find('._even').addClass('even').removeClass('_even')
    if row.hasClass 'row_selected'
      clear()
      @target.find("##{@prefix}-select_uplink").hide()
    else
      clear()
      row.addClass('row_selected')
      row.addClass('_odd').removeClass('odd') if row.hasClass 'odd'
      row.addClass('_even').removeClass('even') if row.hasClass 'even'
      @target.find("##{@prefix}-select_uplink").show()


  # ---------------------------------------------------------------------------
  #  регистрация таблицы
  make_datatable: (target, pars)->
    default_pars =
      oLanguage:
        #  русские надписи для dataTable
        sLengthMenu: "Отображено _MENU_ записей на страницу"
        sSearch: "Поиск:"
        sZeroRecords: "Ничего не найдено - извините"
        sInfo: "Показано с _START_ по _END_ из _TOTAL_ записей"
        sInfoEmpty: "Показано с 0 по 0 из 0 записей"
        sInfoFiltered: "(отобрано из всего _MAX_ записей)"
        oPaginate:
          sFirst: "Первая"
          sLast:"Посл."
          sNext:"След."
          sPrevious:"Пред."
      aaSorting: [[0,"desc"]]
      iDisplayLength: if @table_type is 'downlink' then 10 else 25
      aLengthMenu: [[10, 25, 50, -1], [10, 25, 50, "Все"]]
      bAutoWidth: false
      bProcessing: true
      bServerSide: true
    target.dataTable $.extend({}, default_pars, pars)

  # ---------------------------------------------------------------------------
  get_id_by_row: (row_id)->
    row_number = _.last(row_id.split '-')*1
    if @col_numbers.id is null
      console.log @col_numbers.id
      @ac "ERROR: в таблице нет поля 'id'"
      return null
    @visible_data[row_number][@col_numbers.id]

  # ***************************************************************************
  # служебное и отладочное
  # ---------------------------------------------------------------------------
  ac: (msg) -> console.log "Mm3DataTable: #{msg}"
  # ---------------------------------------------------------------------------
  wait: (msg="Ожидание ответа от сервера...") ->
    @is_dlg_open = true
    # показываем с задержкой в секунду, чтобы не мельтешило
    setTimeout (()=>
      unless @wait_window
        @wait_window = $("<div  id=\"wait_window\">#{msg}</div>").hide()
        @target.append @wait_window
        @wait_window.dialog {autoOpen: false,title: "Передача данных",modal: true,width: "auto",height: "auto"}
      if @is_dlg_open
        @wait_window.text msg
        @wait_window.dialog "open"), 1000

  # ---------------------------------------------------------------------------
  continue: () ->
    @wait_window.dialog "close" if @wait_window
    @is_dlg_open = false
  # ---------------------------------------------------------------------------
  get_parent_prefix: () ->
    l = @prefix.split('-t-')
    return null if l.length is 1 and l[0] is ""
    l.pop()
    l.join '-t-'

# *****************************************************************************
Mm3::Mm3DataTable = Mm3DataTable
