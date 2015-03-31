module Parser
  class PlanAttributesParser
    include HappyMapper

    tag 'planAttributes'

    element :standardComponentID, String, tag: 'standardComponentID'
    element :planMarketingName, String, tag: 'planMarketingName'
    element :hiosProductID, String, tag: 'hiosProductID'
    element :hpid, String, tag: 'hpid'

    def to_hash
      {
         standardComponentID: standardComponentID.gsub(/\n/,'').strip,
         planMarketingName: planMarketingName.gsub(/\n/,'').strip,
         hiosProductID: hiosProductID.gsub(/\n/,'').strip,
         hpid: hpid.gsub(/\n/,'').strip
      }
    end
  end
end
