class State
  include Mongoid::Document

  NAME_IDS = [
    [ "Alabama", "AL" ],
    [ "Alaska", "AK" ],
    [ "Arizona", "AZ" ],
    [ "Arkansas", "AR" ],
    [ "California", "CA" ],
    [ "Colorado", "CO" ],
    [ "Connecticut", "CT" ],
    [ "Delaware", "DE" ],
    [ "District Of Columbia", "DC" ],
    [ "Florida", "FL" ],
    [ "Georgia", "GA" ],
    [ "Hawaii", "HI" ],
    [ "Idaho", "ID" ],
    [ "Illinois", "IL" ],
    [ "Indiana", "IN" ],
    [ "Iowa", "IA" ],
    [ "Kansas", "KS" ],
    [ "Kentucky", "KY" ],
    [ "Louisiana", "LA" ],
    [ "Maine", "ME" ],
    [ "Maryland", "MD" ],
    [ "Massachusetts", "MA" ],
    [ "Michigan", "MI" ],
    [ "Minnesota", "MN" ],
    [ "Mississippi", "MS" ],
    [ "Missouri", "MO" ],
    [ "Montana", "MT" ],
    [ "Nebraska", "NE" ],
    [ "Nevada", "NV" ],
    [ "New Hampshire", "NH" ],
    [ "New Jersey", "NJ" ],
    [ "New Mexico", "NM" ],
    [ "New York", "NY" ],
    [ "North Carolina", "NC" ],
    [ "North Dakota", "ND" ],
    [ "Ohio", "OH" ],
    [ "Oklahoma", "OK" ],
    [ "Oregon", "OR" ],
    [ "Pennsylvania", "PA" ],
    [ "Rhode Island", "RI" ],
    [ "South Carolina", "SC" ],
    [ "South Dakota", "SD" ],
    [ "Tennessee", "TN" ],
    [ "Texas", "TX" ],
    [ "Utah", "UT" ],
    [ "Vermont", "VT" ],
    [ "Virginia", "VA" ],
    [ "Washington", "WA" ],
    [ "West Virginia", "WV" ],
    [ "Wisconsin", "WI" ],
    [ "Wyoming", "WY" ]
  ]
end

  # <option value="AL">Alabama</option>
  # <option value="AK">Alaska</option>
  # <option value="AZ">Arizona</option>
  # <option value="AR">Arkansas</option>
  # <option value="CA">California</option>
  # <option value="DC">District of Columbia</option>
  # <option value="FL">Florida</option>
  # <option value="IN">Indiana</option>
  # <option value="IA">Iowa</option>
  # <option value="LA">Louisiana</option>
  # <option value="MD">Maryland</option>
  # <option value="MA">Massachusetts</option>
  # <option value="MI">Michigan</option>
  # <option value="MO">Missouri</option>
  # <option value="NE">Nebraska</option>
  # <option value="NM">New Mexico</option>
  # <option value="NY">New York</option>
  # <option value="NC">North Carolina</option>
  # <option value="OK">Oklahoma</option>
  # <option value="PA">Pennsylvania</option>
  # <option value="PR">Puerto Rico</option>
  # <option value="TX">Texas</option>
  # <option value="VA">Virginia</option>
  # <option value=""> </option>
  # <option value="DE">Delaware (LEGAL)</option>
  # <option value="HI">Hawaii (LEGAL)</option>
  # <option value="ID">Idaho (LEGAL)</option>
  # <option value="KY">Kentucky (LEGAL)</option>
  # <option value="MN">Minnesota (LEGAL)</option>
  # <option value="MS">Mississippi (LEGAL)</option>
  # <option value="MT">Montana (LEGAL)</option>
  # <option value="NV">Nevada (LEGAL)</option>
  # <option value="NJ">New Jersey (LEGAL)</option>
  # <option value="RI">Rhode Island (LEGAL)</option>
  # <option value="SD">South Dakota (LEGAL)</option>
  # <option value="TN">Tennessee (LEGAL)</option>
  # <option value="UT">Utah (LEGAL)</option>
  # <option value=""> </option>
  # <option value="AS">American Samoa (BAD)</option>
  # <option value="AA">Armed Forces Americas (BAD)</option>
  # <option value="AE">Armed Forces Europe (BAD)</option>
  # <option value="AP">Armed Forces Pacific (BAD)</option>
  # <option value="CO">Colorado (BAD)</option>
  # <option value="CT">Connecticut (BAD)</option>
  # <option value="FM">Federated States of Micronesia (BAD)</option>
  # <option value="GA">Georgia (BAD)</option>
  # <option value="GU">Guam (BAD)</option>
  # <option value="IL">Illinois (BAD)</option>
  # <option value="KS">Kansas (BAD)</option>
  # <option value="ME">Maine (BAD)</option>
  # <option value="MH">Marshall Islands (BAD)</option>
  # <option value="NH">New Hampshire (BAD)</option>
  # <option value="ND">North Dakota (BAD)</option>
  # <option value="MP">Northern Mariana Islands (BAD)</option>
  # <option value="OH">Ohio (BAD)</option>
  # <option value="OR">Oregon (BAD)</option>
  # <option value="PW">Palau (BAD)</option>
  # <option value="SC">South Carolina (BAD)</option>
  # <option value="VT">Vermont (BAD)</option>
  # <option value="VI">Virgin Islands (BAD)</option>
  # <option value="WA">Washington (BAD)</option>
  # <option value="WV">West Virginia (BAD)</option>
  # <option value="WI">Wisconsin (BAD)</option>
  # <option value="WY">Wyoming (BAD)</option>
