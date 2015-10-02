class CasyncController < ApplicationController

  def index
  end

  def show
    start_date = params[:start_date]
    end_date = params[:end_date]
    chamado = params[:chamado]
    @start_date = start_date.to_datetime
    @end_date = end_date.to_datetime + 1

    if chamado.blank?
      @syncs = CasyncInstance.where(:created_on => (@start_date..@end_date))
    else
      search_string = "%" + chamado + "%"
      @syncs = CasyncInstance.where(:created_on => (@start_date..@end_date)).
                              where("calls_inserted LIKE ? OR calls_updated LIKE ?", search_string, search_string)
    end
  end
end
