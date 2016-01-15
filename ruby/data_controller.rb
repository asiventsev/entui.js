class DataController < ApplicationController
  before_filter :get_entity

  def table
    if @cls.methods.include?(:custom_request)
       render json: @cls.send(:custom_request, params, session)
       return
    end
    count = nil
    if params[:parent_id].blank? && (!params[:parent_type].blank?)
      lst = []
    else
      lst = nil
      flds=@cls.entity_meta[:cols].map{|f| f[:atr]}
      att = @cls.new.attributes.keys
      req = @cls.methods.include?(:get_request) ?  @cls.send(:get_request, params, session) : @cls
      req =  req.includes(*@cls.entity_meta[:includes]) unless @cls.entity_meta[:includes].blank?
      unless params[:parent_id].blank?
        ret = @cls.methods.include?(:custom_parent) ? @cls.send(:custom_parent, req, params[:parent_type], params[:parent_id]) : nil
        req = ret ? ret : req.where((params[:foreign_key] ? params[:foreign_key].to_s : "#{params[:parent_type]}_id") => params[:parent_id])
      end
      if params[:iDisplayLength].to_i > 0
        count = req.count
        req = req.offset(params[:iDisplayStart].to_i).limit(params[:iDisplayLength].to_i)
      end
      # сортировки
      f = flds[params[:iSortCol_0].to_i]
      if @cls.methods.include?(:custom_order) && ret=@cls.send(:custom_order, req, f, params[:sSortDir_0])
        req = ret
      elsif att.include? f
        req = req.order("#{f} #{params[:sSortDir_0]}")
      end
      # фильтры
      unless @cls.entity_meta[:filters].blank?
        @cls.entity_meta[:filters].each do |flt|
          flt = flt[:atr]
          unless params[flt].blank?
            ret = @cls.send(:custom_filters, req, flt, params[flt]) if @cls.methods.include?(:custom_filters)
            if ret
              req = ret
            elsif att.include?(flt)
              req = req.where(flt => params[flt])
            end
          end
        end
      end
      # поиски
      unless params[:sSearch].blank?
        lst_s = att.reduce([]) {|l, f| l.append "#{f}::varchar LIKE '%#{params[:sSearch]}%'"}
        req = req.where(lst_s*' OR ')
      end
      lst = req.all
      lst = lst.as_json(methods: flds, only: [])
      lst = lst.map{|rec| flds.map {|f| rec[f] } }
    end
    count = lst.size unless count
    render json: { data: lst, iTotalDisplayRecords: count, iTotalRecords: count, sEcho: params[:sEcho]}
  end

  def update
    fields = get_form_fields true
    h = params[:data]
    if h['id'].blank?
      obj = @cls.new
    else
      obj = @cls.find_by_id h['id']
      unless obj
        render json: {errors: "ОШИБКА: не найдена сущность id = #{h['id']}"}
        return
      end
    end
    new_attr = h.permit(*fields)
    new_attr.each {|k,v| new_attr[k]=nil if v=='null' || v=='NULL' || v== 'undefined'}
    new_attr = @cls.send(:custom_data, new_attr, params, session) if @cls.methods.include?(:custom_data)
    obj.assign_attributes new_attr
    obj.save if obj.errors.size==0
    fields = ["id"].concat get_form_fields
    ret = obj.as_json( methods: fields, only: [] ).as_json
    unless obj.errors.size==0
      errs = ["ОШИБКА: "].concat obj.errors.full_messages
      ret[:errors] = errs*"\n"
    end
    render json: ret
  end

  def form
    obj = @cls.find_by_id params[:entity_id]
    flds = ["id"].concat get_form_fields
    render text: obj.as_json( methods: flds, only: [] ).to_json
  end

  def filters
    att = @cls.new.attributes.keys
    ret = {}
    unless @cls.entity_meta[:filters].blank?
      ret = @cls.entity_meta[:filters].reduce({}) do |r, f|
        f = f[:atr]
        lst = nil
        lst = @cls.send(:filters, f) if @cls.methods.include?(:filters)
        lst = ['','']+@cls.select("distinct #{f}").all.map {|rec| v = rec.attributes[f].to_s; [v, v]} if lst.nil? && att.include?(f)
        r[f] = lst if lst
        r
      end
    end
    if params[:type]=='json'
      render json: ret
    else
      render text: ret.to_json
    end
  end

  private

  def get_form_fields is_save=false
    flds = @cls.entity_meta[:form].map do |row|
      row[0].map do |col|
        if col[:kind]=='link'
          is_save ? col[:atr] : [col[:atr], col[:atr]+'_name']
        else
          col[:atr]
        end
      end
    end
    flds.flatten.compact
  end

  def get_entity
    @cls = nil
    @cls = @entities[params[:id]] if params[:id]
  end

end
