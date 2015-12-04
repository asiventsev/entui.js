class DataController < ApplicationController
  before_filter :get_entity

  def table
    count = nil
    if params[:parent_id].blank? && (!params[:parent_type].blank?)
      lst = []
    else
      lst = nil
      flds=@cls.entity_meta[:cols].map{|f| f[:atr]}
      att = @cls.new.attributes.keys
      req = @cls
      req =  req.includes(*@cls.entity_meta[:includes]) unless @cls.entity_meta[:includes].blank?
      unless params[:parent_id].blank?
        ret = @cls.methods.include?(:custom_parent) ? @cls.send(:custom_parent, req, params[:parent_type], params[:parent_id]) : nil
        req = ret ? ret : req.where("#{params[:parent_type]}_id" => params[:parent_id])
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

  def save
    # вариант для момента v2
    fields = get_form_fields true
    h = JSON.load params[:data]
    if h['id'].blank?
      obj = @cls.new
    else
      obj = @cls.find_by_id h['id']
      unless obj
        render text: "ОШИБКА: не найдена сущность id = #{h['id']}"
        return
      end
    end
    obj.assign_attributes h.slice(*fields)
    obj.save if obj.errors.size==0
    if obj.errors.size==0
      render text: "#{params[:id]} #{obj.id} created"
    else
      errs = ["ОШИБКА: "].concat obj.errors.full_messages
      render text: errs*"\n"
    end
  end

  def update
    # вариант для момента v3
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
    obj.assign_attributes h.slice(*fields).permit!
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
