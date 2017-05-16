require 'rails_helper'
require 'sic_concern'
class SicConverter
  extend SicConcern
end

describe SicConverter do
  let!(:industry_code) { create(:sic_code,
                                division_code: 'A',
                                division_label: 'Industry',
                                major_group_code: '10',
                                major_group_label: 'Machinery',
                                industry_group_code: '101',
                                industry_group_label: 'Manufacturing',
                                sic_code: '1010',
                                sic_label: 'Heavy Construction Machinery Manufacturing'
                          )}
  let!(:another_industry_code) { create(:sic_code,
                                        division_code: 'A',
                                        division_label: 'Industry',
                                        major_group_code: '10',
                                        major_group_label: 'Machinery',
                                        industry_group_code: '105',
                                        industry_group_label: 'Repair',
                                        sic_code: '1055',
                                        sic_label: 'Heavy Construction Machinery Repair'
                              )}
  let!(:agriculture_code) { create(:sic_code,
                                    division_code: 'B',
                                    division_label: 'Agriculture',
                                    major_group_code: '20',
                                    major_group_label: 'Machinery',
                                    industry_group_code: '201',
                                    industry_group_label: 'Wheat Harvesting',
                                    sic_code: '2010',
                                    sic_label: 'Wheat Production'
                            )}
  let!(:services_code) { create(:sic_code,
                                division_code: 'C',
                                division_label: 'Services',
                                major_group_code: '30',
                                major_group_label: 'Software',
                                industry_group_code: '305',
                                industry_group_label: 'Custom Software Development',
                                sic_code: '3055',
                                sic_label: 'Custom Software Development Consulting'
                        )}

  it "returns a nested object" do
    expect(SicConverter.generate_sic_array).to eq([
    {
      text: "Industry",
      selectable: false,
        nodes: [
          {
            text: "Machinery",
            selectable: false,
            nodes: [
              {
                text: "Manufacturing",
                selectable: false,
                nodes: [
                  { text: 'Heavy Construction Machinery Manufacturing - 1010', sic_code: '1010', selectable: true }
                ]
              },
              {
                text: "Repair",
                selectable: false,
                nodes: [
                  { text: 'Heavy Construction Machinery Repair - 1055', sic_code: '1055', selectable: true }
                ]
              }
            ]
          }
        ]
      },
      {
        text: "Agriculture",
        selectable: false,
        nodes: [
          text: "Machinery",
          selectable: false,
          nodes: [
            {
              text: 'Wheat Harvesting',
              selectable: false,
              nodes: [
                  { text: 'Wheat Production - 2010', sic_code: '2010', selectable: true }
                ]
            }
          ]
        ]
      },
      {
        text: "Services",
        selectable: false,
        nodes: [
          {
            text: "Software",
            selectable: false,
            nodes: [
              {
                text: "Custom Software Development",
                selectable: false,
                nodes: [
                  { text: 'Custom Software Development Consulting - 3055', sic_code: '3055', selectable: true}
                ]
              }
            ]
          }
        ]
      }
      ])
  end
end