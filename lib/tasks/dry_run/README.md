### Set the Environment Variables
- Update the dependent filing threshold for the given year
- Update the affordability percentage
- update slcsp tool
### Clear out all the existing data for the given year
- Service Areas (`::BenefitMarkets::Locations::ServiceArea`)
- Rating Areas (`::BenefitMarkets::Locations::RatingArea`)
- Actuarial Factors (Rate) Factors
  - Participation Rate Actuarial Factors (`::BenefitMarkets::Products::ActuarialFactors::ParticipationRateActuarialFactor`)
  - Group Size Actuarial Factors (`::BenefitMarkets::Products::ActuarialFactors::GroupSizeActuarialFactor`)
- Products (`::BenefitMarkets::Products::Product`)
- IVL Benefit Coverage Period (`HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods`)
- Benefit Market Catalogs (`BenefitMarkets::BenefitMarket`)
### Create new data for the given year
- Service Areas 
- Rating Areas 
- Actuarial Factors (Rate) Factors 
  - Participation Rate Actuarial Factors 
  - Group Size Actuarial Factors 
- Products, Plans, and Rates
- Map this and previous year Products and Plans and together
  - Given years `sbc_documents` => Previous years `sbc_documents`
  - Previous years Plans `renewal_plan_id`  => A Given years Plan `hios_id` 
  - Previous years Products `renewal_product_id` => A Given years Product `hios_id`
- IVL Benefit Coverage Period, Packages, and Products 
- Benefit Market Catalogs with Product Packages
### Run the renewal process
### Run the determination process
### Run the notice triggers
### Run the renewal report
### Run the determination report
### Run the notice report
