# Плагин поля типа checkbox для момента v3
#
# Публичные функции
# Конструктор:
# new EntUI::EntUIEditForm::EntUI_fld_check(target, prefix, fld_name, meta, html_pars, value, callbacks)
# Где:
#   target - место на форме, где располагать контрол
#   prefix - уникальный html id
#   fld_name - имя поля
#   meta - мета по этому полю (вся)
#   html_pars - опции html для checkbox (могут уже содержатся в meta)
#   value - начальное значение
#   callbacks - ссылка на общие каллбакии системы
#
# build() - строит и показывает контрол
# возвращает this или объект для котлрого определено val(value)
#
# val(value) - если value==null, то возвращает значение контрола, иначе - устанавливает
# disabled(is_disabled) - устанавливает или снимает свойство read only
#


class EntUIFldCheck
  constructor: (target, prefix, fld_name, meta, html_pars, value, callbacks) ->
    @target = target
    @prefix = prefix
    @fld_name = fld_name
    @meta = meta
    @html_pars = html_pars
    @set_val value or @meta.default
    @fld = null

  build: ()->
    @target.empty()
    @target.parent().find("##{@prefix}-label").text ''
    @fld=$("<input type=\"checkbox\" id=\"#{@prefix}\" />")
    @set_pars @fld, @html_pars
    @target.append @fld, @html_pars
    @target.append (@meta.label or '')
    @fld.prop("checked", @value)
    this

  val: (value)->
    if value is null
      @value = @fld.prop("checked")
    else
      @set_val value
      @fld.prop("checked", @value)
    @value

  disabled: (is_disabled)->
    @fld.prop("disabled", is_disabled)

  # ***************************************************************************
  set_val: (value)->
    @value = value and (value isnt '') and (value isnt '0') and (value isnt 'false') and (value isnt 0)
  # ---------------------------------------------------------------------------
  set_pars: (target, hash_pars={})->
    target.attr key, hash_pars[key] for key in _.keys(hash_pars)


# *****************************************************************************
EntUI::EntUIEditForm::EntUI_fld_check = EntUIFldCheck


