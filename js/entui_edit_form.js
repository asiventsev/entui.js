// Generated by CoffeeScript 1.9.0
(function() {
  var EntUIEditForm;

  EntUIEditForm = (function() {
    function EntUIEditForm(entity_name, meta, callbacks, target, prefix, entity_id, parent_type, parent_id, reload_func, select_uplink_func, open_parent_func) {
      this.entity_name = entity_name;
      this.meta = meta;
      this.callbacks = callbacks;
      this.target = target;
      this.prefix = prefix;
      this.entity_id = entity_id;
      this.parent_type = parent_type;
      this.parent_id = parent_id;
      this.reload_func = reload_func;
      this.select_uplink_func = select_uplink_func;
      this.open_parent_func = open_parent_func;
      this.clear();
    }

    EntUIEditForm.prototype.clear = function() {
      this.target.empty();
      this.visible_data = {};
      this.objs = {};
      this.fld_meta = {};
      return this.flds = {};
    };

    EntUIEditForm.prototype.build = function() {
      var req;
      this.clear();
      if (this.entity_id && this.entity_id !== 'new') {
        req = $.getJSON("/data/form/" + this.entity_name, {
          entity_id: this.entity_id
        });
        req.error((function(_this) {
          return function() {
            return _this.ac("ERROR: Ошибка получения данных формы для сущности " + _this.entity_name);
          };
        })(this));
        return req.success((function(_this) {
          return function(data) {
            _this.visible_data = data;
            return _this.build_form(true);
          };
        })(this));
      } else {
        this.entity_id = null;
        this.visible_data = {};
        return this.build_form(false);
      }
    };

    EntUIEditForm.prototype.build_form = function(is_edit) {
      var button_data, buttons_div, ft, hdr, _ref;
      buttons_div = $("<div id=\"" + this.prefix + "-btn\" class=\"contextual\" />");
      button_data = ((_ref = this.meta.opts.form) != null ? _ref.readonly : void 0) ? [] : [
        {
          "icon": "save",
          "name": "save_entity",
          "text": (is_edit ? "сохранить" : "создать"),
          "func": (function(_this) {
            return function() {
              return _this.save();
            };
          })(this)
        }
      ];
      _.each(button_data, (function(_this) {
        return function(b) {
          var button;
          button = $("<a class=\"icon icon-" + b.icon + "\" id=\"" + _this.prefix + "-b-" + b.name + "\">" + b.text + "</a>");
          button.click(b.func);
          return buttons_div.append(button);
        };
      })(this));
      this.target.append(buttons_div);
      if (is_edit && this.meta.label_template) {
        hdr = _.reduce(_.keys(this.visible_data), ((function(_this) {
          return function(lab, k) {
            return lab = lab.replace('#{' + k + '}', _this.visible_data[k]);
          };
        })(this)), this.meta.label_template);
      } else {
        hdr = '__ № __ ';
      }
      this.target.append("<h2 id=\"" + this.prefix + "-hdr\">" + hdr + "</h2>");
      ft = $("<table style=\"border-collapse: collapse;\" />");
      _.each(this.meta.form, (function(_this) {
        return function(cells_lst) {
          var cells, tr;
          cells = cells_lst[0];
          tr = $("<tr />");
          _this.set_pars(tr, cells_lst[1]);
          return _.each(cells, function(cmeta) {
            var fldn, hpars, kind, td, td_label, _base, _ref1, _ref2, _ref3;
            _this.fld_meta[cmeta.atr] = cmeta;
            kind = cmeta.kind || 'text';
            td_label = $("<td align=\"right\" />");
            td = $("<td />");
            tr.append(td_label);
            tr.append(td);
            if (!_.isEmpty(cmeta)) {
              fldn = _this.prefix + "-" + cmeta.atr;
              td_label.attr("id", fldn + "-label");
              td_label.text(cmeta.label || '');
              hpars = {
                td: ((_ref1 = cmeta.html) != null ? _ref1.td : void 0) || {},
                input: ((_ref2 = cmeta.html) != null ? _ref2.input : void 0) || {},
                span: ((_ref3 = cmeta.html) != null ? _ref3.span : void 0) || {}
              };
              if ((_base = hpars.td).style == null) {
                _base.style = '';
              }
              hpars.td.style += "white-space:nowrap;";
              _this.set_pars(td, hpars.td);
              if (_this["create_fld_" + kind]) {
                _this.flds[cmeta.atr] = _this["create_fld_" + kind](td, fldn, cmeta.atr, hpars.input, _this.visible_data[cmeta.atr]);
                if (_this.callbacks.form_after_create_field) {
                  _this.callbacks.form_after_create_field(td, _this.visible_data[cmeta.atr], cmeta.atr, cmeta.atr);
                }
              } else {
                if (_this["EntUI_fld_" + kind]) {
                  _this.objs[cmeta.atr] = new _this["EntUI_fld_" + kind](td, fldn, cmeta.atr, cmeta, hpars.input, _this.visible_data[cmeta.atr], _this.callbacks);
                  _this.flds[cmeta.atr] = _this.objs[cmeta.atr].build();
                  if (_this.callbacks.form_after_create_field) {
                    _this.callbacks.form_after_create_field(td, _this.visible_data[cmeta.atr], cmeta.atr, cmeta.atr);
                  }
                } else {
                  _this.ac("ERROR: Не найден способ создания поля типа '" + kind + "' для сущности '" + _this.entity_name);
                }
              }
            }
            return ft.append(tr);
          });
        };
      })(this));
      this.target.append(ft);
      if (this.callbacks.form_after_open) {
        return this.callbacks.form_after_open(this.target, this.visible_data, this.meta.form);
      }
    };

    EntUIEditForm.prototype.save = function() {
      var d;
      d = {};
      _.each(_.keys(this.flds), (function(_this) {
        return function(f) {
          return d[f] = _this.flds[f].val();
        };
      })(this));
      d['id'] = this.entity_id || '';
      return jQuery.ajax(this.meta.url_save || ("/data/update/" + this.entity_name), {
        data: {
          data: d
        },
        type: 'POST',
        dataType: 'json',
        success: (function(_this) {
          return function(data) {
            if (data.errors) {
              return _this.alert(data.errors);
            } else {
              _this.clear();
              _this.visible_data = data;
              _this.build_form(true);
              return _this.reload_func();
            }
          };
        })(this),
        error: (function(_this) {
          return function() {
            return _this.ac("ERROR: Ошибка получения данных формы для сущности " + _this.entity_name);
          };
        })(this)
      });
    };

    EntUIEditForm.prototype.create_fld_text = function(td, pref, fldn, pars, value) {
      var fld;
      fld = $("<input type=\"text\" id=\"" + pref + "\" />");
      this.set_pars(fld, pars);
      if (value) {
        fld.val(value);
      }
      td.append(fld);
      return fld;
    };

    EntUIEditForm.prototype.create_fld_textarea = function(td, pref, fldn, pars, value) {
      var fld;
      fld = $("<textarea id=\"" + pref + "\" rows=\"5\" cols=\"60\">" + (value || '') + "</textarea>");
      this.set_pars(fld, pars);
      td.append(fld);
      return fld;
    };

    EntUIEditForm.prototype.create_fld_date = function(td, pref, fldn, pars, value) {
      var fld;
      fld = this.create_fld_text(td, pref, fldn, pars, value);
      fld.datepicker({
        dateFormat: "dd.mm.y ",
        showOn: "button"
      });
      return fld;
    };

    EntUIEditForm.prototype.create_fld_datetime = function(td, pref, fldn, pars, value) {
      var fld;
      fld = this.create_fld_text(td, pref, fldn, pars, value);
      fld.datetimepicker({
        lang: "ru",
        format: "d.m.y H:i",
        dayOfWeekStart: 1,
        weeks: true,
        step: 15,
        minTime: "7:00",
        maxTime: "18:00"
      }, {
        onShow: (function(_this) {
          return function(t, me) {
            if (_this.callbacks.datetimepicker_onShow) {
              return _this.callbacks.datetimepicker_onShow(t, me);
            }
          };
        })(this)
      });
      return fld;
    };

    EntUIEditForm.prototype.create_fld_frozentext = function(td, pref, fldn, pars, value) {
      var fld;
      fld = this.create_fld_text(td, pref, fldn, pars, value);
      fld.attr("disabled", true);
      return fld;
    };

    EntUIEditForm.prototype.create_fld_sel = function(td, pref, fldn, pars, value) {
      var fld;
      fld = $("<select id=\"" + pref + "\" />");
      this.set_pars(fld, pars);
      _.each(this.fld_meta[fldn].selector || [], function(s) {
        return fld.append($("<option value=\"" + (s[1] || s[0]) + "\">" + s[0] + "</option>"));
      });
      if (value) {
        fld.val(value);
      }
      td.append(fld);
      return fld;
    };

    EntUIEditForm.prototype.create_fld_span = function(td, pref, fldn, pars, value) {
      var fld;
      if (value == null) {
        value = '';
      }
      fld = $("<span id=\"" + pref + "\">" + value + "</span>");
      td.attr("style", "");
      this.set_pars(fld, pars);
      fld.val(value);
      td.append(fld);
      return fld;
    };

    EntUIEditForm.prototype.create_fld_link = function(td, pref, fldn, pars, value) {
      var e_name, hclear, hid, hname, hsel, name, ret_fld_list, tbl, tr;
      e_name = this.fld_meta[fldn].entity || fldn;
      if ((this.entity_id === null) && this.parent_type && this.parent_id && (this.parent_type === e_name)) {
        return this.create_fld_hidden(td, pref, fldn, {}, value || this.parent_id);
      }
      name = this.visible_data[fldn + "_name"] || '';
      tbl = $("<table style=\"border-collapse: collapse;\" />");
      tr = $("<tr />");
      hid = $("<input id=\"" + pref + "\" type=\"hidden\" value=\"" + value + "\">");
      hname = $("<span id=\"" + pref + "_name\" class=\"ref_field link_selectable\">" + name + "</span>");
      hsel = $("<a class=\"icon icon-edit\" id=\"" + pref + "-change_uplink\" title=\"изменить ссылку\"></a>");
      hclear = $("<a class=\"icon icon-false\" id=\"" + pref + "-clear_uplink\" title=\"очистить ссылку\"></a>");
      ret_fld_list = [this.fld_meta[fldn].id_atr || 'id', this.fld_meta[fldn].name_atr || 'name'];
      hsel.click((function(_this) {
        return function() {
          return _this.select_uplink_func(_this.fld_meta[fldn].entity || fldn, ret_fld_list, function(data) {
            hid.val(data[ret_fld_list[0]]);
            return hname.text(data[ret_fld_list[1]]);
          });
        };
      })(this));
      hclear.click((function(_this) {
        return function() {
          hid.val('');
          return hname.text('');
        };
      })(this));
      hname.click((function(_this) {
        return function() {
          if (!(hid.val() === null || hid.val() === 'null' || hid.val() === '')) {
            return _this.open_parent_func(_this.fld_meta[fldn].entity || fldn, value);
          }
        };
      })(this));
      tbl.append(hid, tr.append($("<td />").append(hname)));
      if (!this.fld_meta[fldn].frozen) {
        tbl.append(tr.append($("<td />").append(hsel)), tr.append($("<td />").append(hclear)));
      }
      td.append(tbl);
      return hid;
    };

    EntUIEditForm.prototype.create_fld_hidden = function(td, pref, fldn, pars, value) {
      var fld;
      fld = $("<input type=\"hidden\" id=\"" + pref + "\" />");
      if (value) {
        fld.val(value);
      }
      td.append(fld);
      td.parent().find("#" + pref + "-label").text('');
      return fld;
    };

    EntUIEditForm.prototype.ac = function(msg) {
      return console.log("EntUIEditForm: " + msg);
    };

    EntUIEditForm.prototype.set_pars = function(target, hash_pars) {
      var key, _i, _len, _ref, _results;
      if (hash_pars == null) {
        hash_pars = {};
      }
      _ref = _.keys(hash_pars);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        key = _ref[_i];
        _results.push(target.attr(key, hash_pars[key]));
      }
      return _results;
    };

    EntUIEditForm.prototype.alert = function(msg) {
      var clbk;
      clbk = this.callbacks.entity_alert;
      if (!(clbk && clbk(msg))) {
        return alert(msg);
      }
    };

    return EntUIEditForm;

  })();

  EntUI.prototype.EntUIEditForm = EntUIEditForm;

}).call(this);
