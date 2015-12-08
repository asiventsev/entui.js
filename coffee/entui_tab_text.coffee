# Плагин таба со статическим текстом типа text для EntUI
# ПРИВЕДЕН ДЛЯ ПРИМЕРА
#
# Публичные функции
# Конструктор:
# new EntUITabText(target, prefix, meta, callbacks, parent_type, parent_id)
# Где:
#   target - таб, где располагать данные
#   prefix - уникальный html id
#   meta - мета по этому табу (вся)
#   callbacks - ссылка на общие каллбакии системы
#   parent_type - имя сущности, на карточке которой находятся табы
#   parent_id - Id сущности, на карточке которой находятся табы
#
# build() - строит и показывает контрол
# возвращает this или объект для котлрого определено val(value)

class EntUITabText
  constructor: (target, prefix, meta, callbacks, parent_type, parent_id) ->
    @target = target
    @prefix = prefix
    @meta = meta
    @callbacks = callbacks
    @parent_type = parent_type
    @parent_id = parent_id

  # ---------------------------------------------------------------------------
  build: () ->
    @target.empty()
    if @meta.text
      @target.text @meta.text

# *****************************************************************************
EntUI::EntUI_tab_text = EntUITabText

