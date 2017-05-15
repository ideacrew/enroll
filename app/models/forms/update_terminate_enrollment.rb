module Forms
  class UpdateTerminateEnrollment

    attr_reader :result
    attr_reader :row
    attr_reader :family_id

    def initialize(*arguments)
      params = arguments.extract_options!
      @result = {success: [], failure: []}
      @row = params[:family_actions_id]
      @family_id = params[:family_id]
      params.each do |key, value|
        if key.to_s[/terminate_hbx_.*/]
          hbx = HbxEnrollment.find(params[key.to_s])
          begin
            termination_date = Date.strptime(params["termination_date_#{value}"], "%m/%d/%Y")
            hbx.terminate_coverage!(termination_date) if hbx.may_terminate_coverage?
            @result[:success] << hbx
          rescue
            @result[:failure] << hbx
          end
        end
        set_transmit_flag(params[key.to_s]) if key.to_s[/transmit_hbx_.*/]
      end
    end

    private

    def set_transmit_flag(hbx_id)
      HbxEnrollment.find(hbx_id).update_attributes!(is_tranding_partner_transmittable: true)
    end
  end
end
