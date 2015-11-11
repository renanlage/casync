class CasyncController < ApplicationController
  helper_method :correspondig_issue

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

  def corresponding_issue(chamado)
    # Check for call custom field
    call_custom_field = IssueCustomField.where(:name => 'Chamado').first

    # Check if there's any issue with the same value for the 'Chamado' custom field as the call
    call_custom_value = CustomValue.where(:custom_field_id => call_custom_field.id, :value => chamado).first

    # Get corresponding issue or nil if there's none
    if call_custom_value then Issue.find(call_custom_value.customized_id) else nil end
  end
end
