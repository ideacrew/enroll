import { sleep, group } from 'k6'
import http from 'k6/http'
import { URLSearchParams } from 'https://jslib.k6.io/url/1.0.0/index.js'
import { FormData } from 'https://jslib.k6.io/formdata/0.0.2/index.js'

export const options = {
  ext: {
    loadimpact: {
      distribution: { 'amazon:us:ashburn': { loadZone: 'amazon:us:ashburn', percent: 100 } },
      apm: [],
    },
  },
  thresholds: {},
  scenarios: {
    Scenario_1: {
      executor: 'ramping-vus',
      gracefulStop: '30s',
      stages: [
        { target: 20, duration: '5m' },
        { target: 20, duration: '3m30s' },
        { target: 10, duration: '1m' },
      ],
      gracefulRampDown: '30s',
      exec: 'scenario_1',
    },
  },
}

export function scenario_1() {
  let formData, response

  const vars = {}

  group('page_1 - https://perf-test-enroll.cme.openhbx.org/', function () {
    response = http.get('https://perf-test-enroll.cme.openhbx.org/', {
      headers: {
        'upgrade-insecure-requests': '1',
        'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"macOS"',
      },
    })
    sleep(2.1)
  })

  group(
    'page_2 - https://perf-test-enroll.cme.openhbx.org/insured/consumer_role/privacy?uqhp=true',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/insured/consumer_role/privacy?uqhp=true',
        {
          headers: {
            accept: 'text/html, application/xhtml+xml',
            'turbolinks-referrer': 'https://perf-test-enroll.cme.openhbx.org/',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )

      vars['utf81'] = response.html().find('input[name=utf8]').first().attr('value')

      vars['authenticity_token1'] = response
        .html()
        .find('input[name=authenticity_token]')
        .first()
        .attr('value')

      vars['user[referer]1'] = response
        .html()
        .find('input[name=user[referer]]')
        .first()
        .attr('value')

      sleep(14.3)
    }
  )

  group('page_4 - https://perf-test-enroll.cme.openhbx.org/users', function () {
    response = http.post(
      'https://perf-test-enroll.cme.openhbx.org/users',
      {
        utf8: `${vars['utf81']}`,
        authenticity_token: `${vars['authenticity_token1']}`,
        'user[referer]': `${vars['user[referer]1']}`,
        'user[oim_id]': 'karacon1@gmail.com',
        'user[password]': 'Test!123',
        'user[password_confirmation]': 'Test!123',
        'user[email]': '',
        'user[invitation_id]': '',
        commit: 'Create Account',
      },
      {
        headers: {
          'content-type': 'application/x-www-form-urlencoded',
          origin: 'https://perf-test-enroll.cme.openhbx.org',
          'upgrade-insecure-requests': '1',
          'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
          'sec-ch-ua-mobile': '?0',
          'sec-ch-ua-platform': '"macOS"',
        },
      }
    )
    sleep(3.5)
  })

  group(
    'page_5 - https://perf-test-enroll.cme.openhbx.org/insured/consumer_role/search?uqhp=true',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/insured/consumer_role/search?uqhp=true',
        {
          headers: {
            accept: 'text/html, application/xhtml+xml',
            'turbolinks-referrer':
              'https://perf-test-enroll.cme.openhbx.org/insured/consumer_role/privacy?uqhp=true',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )

      vars['utf82'] = response.html().find('input[name=utf8]').first().attr('value')

      vars['authenticity_token2'] = response
        .html()
        .find('input[name=authenticity_token]')
        .first()
        .attr('value')

      vars['person[no_ssn]1'] = response
        .html()
        .find('input[name=person[no_ssn]]')
        .first()
        .attr('value')

      sleep(27.4)
    }
  )

  group(
    'page_6 - https://perf-test-enroll.cme.openhbx.org/insured/consumer_role/match',
    function () {
      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/insured/consumer_role/match',
        {
          utf8: `${vars['utf82']}`,
          authenticity_token: `${vars['authenticity_token2']}`,
          'people[id]': '',
          'person[dob_check]': '',
          'person[first_name]': 'kara',
          'person[middle_name]': '',
          'person[last_name]': 'con1',
          'person[name_sfx]': '',
          'person[is_applying_coverage]': 'true',
          'person[dob]': '1987-12-11',
          'jq_datepicker_ignore_person[dob]': '12/11/1987',
          'person[ssn]': '721-92-8922',
          'person[no_ssn]': `${vars['person[no_ssn]1']}`,
          'person[gender]': 'female',
        },
        {
          headers: {
            'content-type': 'application/x-www-form-urlencoded',
            origin: 'https://perf-test-enroll.cme.openhbx.org',
            'upgrade-insecure-requests': '1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(5.3)
    }
  )

  group(
    'page_7 - https://perf-test-enroll.cme.openhbx.org/insured/consumer_role?person%5Bdob%5D=QEVuQwEAoKQsNeidc7uAOh9WgqYN%2FQ%3D%3D&person%5Bdob_check%5D=&person%5Bfirst_name%5D=QEVuQwEA605Y7eFR171noFAknMIUzQ%3D%3D&person%5Bgender%5D=QEVuQwEANyNlXe1Lsje7FlR99UMdZw%3D%3D&person%5Bis_applying_coverage%5D=true&person%5Blast_name%5D=QEVuQwEA1HG%2BEF3CArogXbpREHHQVQ%3D%3D&person%5Bmiddle_name%5D=&person%5Bname_sfx%5D=&person%5Bno_ssn%5D=0&person%5Bssn%5D=QEVuQwEAhvZhvKJL8wiBlSQwyN3PnQ%3D%3D&person%5Buser_id%5D=QEVuQwEAnZU%2Bb%2Bt2qpM6CSI24HwzPQb65f%2FOIVU2d%2FifcJHdUnY%3D',
    function () {
      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/insured/consumer_role?person%5Bdob%5D=QEVuQwEAoKQsNeidc7uAOh9WgqYN%2FQ%3D%3D&person%5Bdob_check%5D=&person%5Bfirst_name%5D=QEVuQwEA605Y7eFR171noFAknMIUzQ%3D%3D&person%5Bgender%5D=QEVuQwEANyNlXe1Lsje7FlR99UMdZw%3D%3D&person%5Bis_applying_coverage%5D=true&person%5Blast_name%5D=QEVuQwEA1HG%2BEF3CArogXbpREHHQVQ%3D%3D&person%5Bmiddle_name%5D=&person%5Bname_sfx%5D=&person%5Bno_ssn%5D=0&person%5Bssn%5D=QEVuQwEAhvZhvKJL8wiBlSQwyN3PnQ%3D%3D&person%5Buser_id%5D=QEVuQwEAnZU%2Bb%2Bt2qpM6CSI24HwzPQb65f%2FOIVU2d%2FifcJHdUnY%3D',
        {
          _method: 'post',
          authenticity_token:
            '7r22SkM3BiSG6tKfMoRdpAAl4mzpSVfWbIbcrJmZHFp39s03vjqGYgOijWxU8X8ZLMguPNUhzGB4BWtIwc0P5Q==',
        },
        {
          headers: {
            'content-type': 'application/x-www-form-urlencoded',
            origin: 'https://perf-test-enroll.cme.openhbx.org',
            'upgrade-insecure-requests': '1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )

      vars['utf83'] = response.html().find('input[name=utf8]').first().attr('value')

      vars['_method1'] = response.html().find('input[name=_method]').first().attr('value')

      vars['person[tribe_codes][]1'] = response
        .html()
        .find('input[name=person[tribe_codes][]]')
        .first()
        .attr('value')

      vars['person[emails_attributes][1][kind]1'] = response
        .html()
        .find('input[name=person[emails_attributes][1][kind]]')
        .first()
        .attr('value')

      sleep(23)

      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/benefit_sponsors/profiles/registrations/counties_for_zip_code',
        '{"zip_code":"04330"}',
        {
          headers: {
            accept: 'application/json, text/plain, */*',
            'content-type': 'application/json; charset=UTF-8',
            'x-csrf-token':
              'SfBZ4UfupLBqgTIkcPbHzE+vkbgeItwYnH8k+3zVWlrQuyKcuuMk9u/JbdcWg+VxY0Jd6CJKR66I/JMfJIFJ5Q==',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(13.1)
    }
  )

  group(
    'page_8 - https://perf-test-enroll.cme.openhbx.org/insured/consumer_role/653abfd2c8a486000f8f40b1',
    function () {
      formData = new FormData()
      formData.boundary = '----WebKitFormBoundary9LJleKpFb9CBZ9jv'
      formData.append('utf8', '✓')
      formData.append('_method', 'put')
      formData.append(
        'authenticity_token',
        'SfBZ4UfupLBqgTIkcPbHzE+vkbgeItwYnH8k+3zVWlrQuyKcuuMk9u/JbdcWg+VxY0Jd6CJKR66I/JMfJIFJ5Q=='
      )
      formData.append('exit_after_method', 'false')
      formData.append('people[id]', '')
      formData.append('person[dob_check]', '')
      formData.append('person[first_name]', 'kara')
      formData.append('person[middle_name]', '')
      formData.append('person[last_name]', 'con1')
      formData.append('person[name_sfx]', '')
      formData.append('person[is_applying_coverage]', 'true')
      formData.append('person[no_ssn]', '0')
      formData.append('person[gender]', 'female')
      formData.append('person[us_citizen]', 'true')
      formData.append('person[naturalized_citizen]', 'false')
      formData.append('person[eligible_immigration_status]', 'false')
      formData.append('immigration_doc_type', '')
      formData.append('naturalization_doc_type', '')
      formData.append('person[indian_tribe_member]', 'false')
      formData.append('person[tribal_state]', '')
      formData.append('person[tribe_codes][]', '')
      formData.append('person[tribal_name]', '')
      formData.append('person[is_incarcerated]', 'false')
      formData.append('person[ethnicity][]', '')
      formData.append('person[ethnicity][]', '')
      formData.append('person[ethnicity][]', '')
      formData.append('person[ethnicity][]', '')
      formData.append('person[ethnicity][]', '')
      formData.append('person[ethnicity][]', '')
      formData.append('person[ethnicity][]', '')
      formData.append('form_for_consumer_role', 'true')
      formData.append('person[is_consumer_role]', 'true')
      formData.append('person[addresses_attributes][0][kind]', 'home')
      formData.append('person[addresses_attributes][0][_destroy]', 'false')
      formData.append('person[addresses_attributes][0][address_1]', '12 mani')
      formData.append('person[addresses_attributes][0][address_2]', '')
      formData.append('person[addresses_attributes][0][city]', 'wash')
      formData.append('person[addresses_attributes][0][state]', 'ME')
      formData.append('person[addresses_attributes][0][zip]', '04330')
      formData.append('person[addresses_attributes][0][county]', 'Kennebec')
      formData.append('person[is_homeless]', '0')
      formData.append('person[addresses_attributes][1][kind]', 'mailing')
      formData.append('person[addresses_attributes][1][_destroy]', 'false')
      formData.append('person[addresses_attributes][1][address_1]', '')
      formData.append('person[addresses_attributes][1][address_2]', '')
      formData.append('person[addresses_attributes][1][city]', '')
      formData.append('person[addresses_attributes][1][state]', '')
      formData.append('person[addresses_attributes][1][zip]', '')
      formData.append('person[addresses_attributes][1][county]', 'Please provide a zip code')
      formData.append('person[phones_attributes][0][kind]', 'home')
      formData.append('person[phones_attributes][0][_destroy]', 'false')
      formData.append('person[phones_attributes][0][full_phone_number]', '')
      formData.append('person[phones_attributes][1][kind]', 'mobile')
      formData.append('person[phones_attributes][1][_destroy]', 'false')
      formData.append('person[phones_attributes][1][full_phone_number]', '')
      formData.append('person[emails_attributes][0][kind]', 'home')
      formData.append('person[emails_attributes][0][_destroy]', 'false')
      formData.append('person[emails_attributes][0][address]', 'karacon1@gmail.com')
      formData.append('person[emails_attributes][0][id]', '653abfd2c8a486000f8f40a7')
      formData.append('person[emails_attributes][1][kind]', 'work')
      formData.append('person[emails_attributes][1][_destroy]', 'false')
      formData.append('person[emails_attributes][1][address]', '')
      formData.append('person[consumer_role_attributes][contact_method][]', 'Mail')
      formData.append('person[consumer_role_attributes][language_preference]', 'English')
      formData.append('person[consumer_role_attributes][id]', '653abfd2c8a486000f8f40b1')

      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/insured/consumer_role/653abfd2c8a486000f8f40b1',
        formData.body(),
        {
          headers: {
            'content-type': 'multipart/form-data; boundary=----WebKitFormBoundary9LJleKpFb9CBZ9jv',
            origin: 'https://perf-test-enroll.cme.openhbx.org',
            'upgrade-insecure-requests': '1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(3.5)
    }
  )

  group(
    'page_9 - https://perf-test-enroll.cme.openhbx.org/insured/interactive_identity_verifications/new',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/insured/interactive_identity_verifications/new',
        {
          headers: {
            accept: 'text/html, application/xhtml+xml',
            'turbolinks-referrer':
              'https://perf-test-enroll.cme.openhbx.org/insured/consumer_role/ridp_agreement',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(6.8)
    }
  )

  group(
    'page_10 - https://perf-test-enroll.cme.openhbx.org/insured/interactive_identity_verifications',
    function () {
      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/insured/interactive_identity_verifications',
        {
          utf8: `${vars['utf83']}`,
          authenticity_token:
            'gFETamlkBVrialcL2VZppWaqz35q1/jle/OQnf36M70ZGmgXlGmFHGciCPi/I0sYSkcDLla/Y1NvcCd5pa4gAg==',
          'interactive_verification[session_id]': 'session id for reference',
          'interactive_verification[transaction_id]': 'transaction id for reference',
          'interactive_verification[questions_attributes][0][question_id]': 'First Question',
          'interactive_verification[questions_attributes][0][question_text]':
            'If you had to answer a question',
          'interactive_verification[questions_attributes][0][responses_attributes][0][response_id]':
            'A',
          'interactive_verification[questions_attributes][0][responses_attributes][0][response_text]':
            'pick answer A',
          'interactive_verification[questions_attributes][0][responses_attributes][1][response_id]':
            'B',
          'interactive_verification[questions_attributes][0][responses_attributes][1][response_text]':
            'pick answer B',
          'interactive_verification[questions_attributes][0][response_id]': 'B',
          'interactive_verification[questions_attributes][1][question_id]': 'Second Question',
          'interactive_verification[questions_attributes][1][question_text]':
            'If somehow there was another question',
          'interactive_verification[questions_attributes][1][responses_attributes][0][response_id]':
            'C',
          'interactive_verification[questions_attributes][1][responses_attributes][0][response_text]':
            'pick answer C',
          'interactive_verification[questions_attributes][1][responses_attributes][1][response_id]':
            'D',
          'interactive_verification[questions_attributes][1][responses_attributes][1][response_text]':
            'pick answer D',
          'interactive_verification[questions_attributes][1][response_id]': 'C',
          commit: 'Submit',
        },
        {
          headers: {
            'content-type': 'application/x-www-form-urlencoded',
            origin: 'https://perf-test-enroll.cme.openhbx.org',
            'upgrade-insecure-requests': '1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(6.1)
    }
  )

  group(
    'page_11 - https://perf-test-enroll.cme.openhbx.org/insured/interactive_identity_verifications/WhateverRefNumberHere',
    function () {
      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/insured/interactive_identity_verifications/WhateverRefNumberHere',
        {
          _method: `${vars['_method1']}`,
          authenticity_token:
            'TI+gbhsLjiIa30kIOdEb8/QS0SwhVv856dshXfp9PErVxNsT5gYOZJ+XFvtfpDlO2P8dfB0+ZI/9WJa5oikv9Q==',
        },
        {
          headers: {
            'content-type': 'application/x-www-form-urlencoded',
            origin: 'https://perf-test-enroll.cme.openhbx.org',
            'upgrade-insecure-requests': '1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(14.3)
    }
  )

  group(
    'page_12 - https://perf-test-enroll.cme.openhbx.org/insured/consumer_role/help_paying_coverage_response?utf8=%E2%9C%93&exit_after_method=false&is_applying_for_assistance=true',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/insured/consumer_role/help_paying_coverage_response?utf8=%E2%9C%93&exit_after_method=false&is_applying_for_assistance=true',
        {
          headers: {
            'upgrade-insecure-requests': '1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(5.4)
    }
  )

  group(
    'page_13 - https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/update_application_year?id=653ac015c8a486000f8f40c7',
    function () {
      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/update_application_year?id=653ac015c8a486000f8f40c7',
        {
          utf8: `${vars['utf83']}`,
          _method: 'patch',
          authenticity_token:
            '8eXPf331r/Fq0Te7aXTNACHbxCOOmAf7hVT9eaCUrqRorrQCgPgvt++ZaEgPAe+9DTYIc7LwnE2R10qd+MC9Gw==',
          'application[assistance_year]': '2023',
          commit: 'Continue',
        },
        {
          headers: {
            'content-type': 'application/x-www-form-urlencoded',
            origin: 'https://perf-test-enroll.cme.openhbx.org',
            'upgrade-insecure-requests': '1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )

      vars['exit_after_method1'] = response
        .html()
        .find('input[name=exit_after_method]')
        .first()
        .attr('value')

      sleep(6.4)
    }
  )

  group(
    'page_14 - https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/edit',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/edit',
        {
          headers: {
            accept: 'text/html, application/xhtml+xml',
            'turbolinks-referrer':
              'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/application_checklist',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(2.7)
    }
  )

  group(
    'page_15 - https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/step/1',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/step/1',
        {
          headers: {
            accept: 'text/html, application/xhtml+xml',
            'turbolinks-referrer':
              'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/edit',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )

      vars['utf84'] = response.html().find('input[name=utf8]').first().attr('value')

      vars['_method2'] = response.html().find('input[name=_method]').first().attr('value')

      vars['authenticity_token3'] = response
        .html()
        .find('input[name=authenticity_token]')
        .first()
        .attr('value')

      vars['last_step1'] = response.html().find('input[name=last_step]').first().attr('value')

      sleep(2.5)

      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/applicant_is_eligible_for_joint_filing',
        {
          headers: {
            accept: '*/*',
            'x-csrf-token':
              'OriIZra48cwAjXBf51qgklV8hwpvVl5V2Mxq9UyqRMOj8/MbS7VxioXFL6yBL4IveZFLWlM+xePMT90RFP5XfA==',
            'x-requested-with': 'XMLHttpRequest',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(3.6)
    }
  )

  group(
    'page_16 - https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/step',
    function () {
      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/step',
        {
          utf8: `${vars['utf84']}`,
          _method: `${vars['_method2']}`,
          authenticity_token: `${vars['authenticity_token3']}`,
          'applicant[is_required_to_file_taxes]': `${vars['last_step1']}`,
          'applicant[is_claimed_as_tax_dependent]': `${vars['exit_after_method1']}`,
          'applicant[claimed_as_tax_dependent_by]': `${vars['person[tribe_codes][]1']}`,
          last_step: `${vars['last_step1']}`,
          commit: 'CONTINUE',
        },
        {
          headers: {
            'content-type': 'application/x-www-form-urlencoded',
            origin: 'https://perf-test-enroll.cme.openhbx.org',
            'upgrade-insecure-requests': '1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(2.8)

      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4',
        {
          'financial_assistance_applicant[has_job_income]': `${vars['last_step1']}`,
        },
        {
          headers: {
            accept: '*/*',
            'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'x-csrf-token':
              'LtP06tsXs/KdFejcX176v+1yKsEb54AeygkrXqEipnq3mI+XJhoztBhdty85K9gCwZ/mkSePG6jeipy6+Xa1xQ==',
            'x-requested-with': 'XMLHttpRequest',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(49.1)

      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/incomes',
        {
          utf8: `${vars['utf84']}`,
          'income[kind]': 'wages_and_salaries',
          'income[employer_name]': 'test',
          'income[amount]': '$50000',
          'income[frequency_kind]': 'yearly',
          'income[start_on]': '10/01/2019',
          'income[end_on]': `${vars['person[tribe_codes][]1']}`,
          'income[employer_phone][kind]': `${vars['person[emails_attributes][1][kind]1']}`,
          'income[employer_phone][full_phone_number]': '(394) 834-3422',
          commit: 'Save',
        },
        {
          headers: {
            accept:
              '*/*;q=0.5, text/javascript, application/javascript, application/ecmascript, application/x-ecmascript',
            'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'x-csrf-token':
              'LtP06tsXs/KdFejcX176v+1yKsEb54AeygkrXqEipnq3mI+XJhoztBhdty85K9gCwZ/mkSePG6jeipy6+Xa1xQ==',
            'x-requested-with': 'XMLHttpRequest',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(2.7)

      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4',
        {
          'financial_assistance_applicant[has_self_employment_income]': `${vars['exit_after_method1']}`,
        },
        {
          headers: {
            accept: '*/*',
            'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'x-csrf-token':
              'LtP06tsXs/KdFejcX176v+1yKsEb54AeygkrXqEipnq3mI+XJhoztBhdty85K9gCwZ/mkSePG6jeipy6+Xa1xQ==',
            'x-requested-with': 'XMLHttpRequest',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(2.5)
    }
  )

  group(
    'page_17 - https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/incomes/other',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/incomes/other',
        {
          headers: {
            accept: 'text/html, application/xhtml+xml',
            'turbolinks-referrer':
              'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/incomes',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(4.5)

      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4',
        {
          'financial_assistance_applicant[has_unemployment_income]': `${vars['exit_after_method1']}`,
        },
        {
          headers: {
            accept: '*/*',
            'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'x-csrf-token':
              'B2/pznLik1/G4VJlBWWLxfR2qH447WFJKxbG7yBSnTieJJKzj+8TGUOpDZZjEKl42JtkLgSF+v8/lXELeAaOhw==',
            'x-requested-with': 'XMLHttpRequest',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(0.8)

      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4',
        {
          'financial_assistance_applicant[has_other_income]': `${vars['exit_after_method1']}`,
        },
        {
          headers: {
            accept: '*/*',
            'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'x-csrf-token':
              'B2/pznLik1/G4VJlBWWLxfR2qH447WFJKxbG7yBSnTieJJKzj+8TGUOpDZZjEKl42JtkLgSF+v8/lXELeAaOhw==',
            'x-requested-with': 'XMLHttpRequest',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(0.9)
    }
  )

  group(
    'page_18 - https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/deductions',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/deductions',
        {
          headers: {
            accept: 'text/html, application/xhtml+xml',
            'turbolinks-referrer':
              'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/incomes/other',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(2.6)

      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4',
        {
          'financial_assistance_applicant[has_deductions]': `${vars['exit_after_method1']}`,
        },
        {
          headers: {
            accept: '*/*',
            'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'x-csrf-token':
              'xb//vpf+Pvj+PZAB4osSQvBExUlCa5biTGS/d3g85yFc9ITDavO+vnt1z/KE/jD/3KkJGX4DDVRY5wiTIGj0ng==',
            'x-requested-with': 'XMLHttpRequest',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(1)
    }
  )

  group(
    'page_19 - https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/benefits',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/benefits',
        {
          headers: {
            accept: 'text/html, application/xhtml+xml',
            'turbolinks-referrer':
              'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/deductions',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(2.8)

      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4',
        {
          'financial_assistance_applicant[has_enrolled_health_coverage]': `${vars['exit_after_method1']}`,
        },
        {
          headers: {
            accept: '*/*',
            'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'x-csrf-token':
              '0GaPrwP/fWLhlNcom27BGjm+gR8Gfc97ODjU7MSaVIxJLfTS/vL9JGTciNv9G+OnFVNNTzoVVM0su2MInM5HMw==',
            'x-requested-with': 'XMLHttpRequest',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(1.4)

      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4',
        {
          'financial_assistance_applicant[has_eligible_health_coverage]': `${vars['exit_after_method1']}`,
        },
        {
          headers: {
            accept: '*/*',
            'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'x-csrf-token':
              '0GaPrwP/fWLhlNcom27BGjm+gR8Gfc97ODjU7MSaVIxJLfTS/vL9JGTciNv9G+OnFVNNTzoVVM0su2MInM5HMw==',
            'x-requested-with': 'XMLHttpRequest',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(0.8)

      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4',
        {
          'financial_assistance_applicant[medicaid_cubcare_due_on]': ' ',
          'financial_assistance_applicant[has_eligible_medicaid_cubcare]': `${vars['exit_after_method1']}`,
        },
        {
          headers: {
            accept: '*/*',
            'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'x-csrf-token':
              '0GaPrwP/fWLhlNcom27BGjm+gR8Gfc97ODjU7MSaVIxJLfTS/vL9JGTciNv9G+OnFVNNTzoVVM0su2MInM5HMw==',
            'x-requested-with': 'XMLHttpRequest',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(2.7)

      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4',
        {
          'financial_assistance_applicant[has_eligibility_changed]': `${vars['exit_after_method1']}`,
        },
        {
          headers: {
            accept: '*/*',
            'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'x-csrf-token':
              '0GaPrwP/fWLhlNcom27BGjm+gR8Gfc97ODjU7MSaVIxJLfTS/vL9JGTciNv9G+OnFVNNTzoVVM0su2MInM5HMw==',
            'x-requested-with': 'XMLHttpRequest',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(1.5)
    }
  )

  group(
    'page_20 - https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/other_questions',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/other_questions',
        {
          headers: {
            accept: 'text/html, application/xhtml+xml',
            'turbolinks-referrer':
              'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/benefits',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )

      vars['utf85'] = response.html().find('input[name=utf8]').first().attr('value')

      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/age_of_applicant',
        {
          headers: {
            accept: '*/*',
            'x-csrf-token':
              'kwVyfA/W8Bze9S3idO//eSE3w2PQQrfi0CngerR4/RAKTgkB8ttwWlu9chESmt3EDdoPM+wqLFTEqlee7Czurw==',
            'x-requested-with': 'XMLHttpRequest',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(8.8)
    }
  )

  group(
    'page_21 - https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/save_questions?utf8=%E2%9C%93&applicant%5Bis_pregnant%5D=false&applicant%5Bpregnancy_due_on%5D=&applicant%5Bchildren_expected_count%5D=&applicant%5Bis_post_partum_period%5D=false&applicant%5Bpregnancy_end_on%5D=&applicant%5Bfoster_care_us_state%5D=&applicant%5Bage_left_foster_care%5D=&applicant%5Bis_self_attested_blind%5D=false&applicant%5Bhas_daily_living_help%5D=false&applicant%5Bneed_help_paying_bills%5D=false&applicant%5Bis_physically_disabled%5D=false&applicant%5Bis_primary_caregiver%5D=false&applicant%5Bis_primary_caregiver_for%5D%5B%5D=&applicant%5Bis_primary_caregiver_for%5D%5B%5D=&commit=CONTINUE',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/applicants/653ac015c8a486000f8f40c4/save_questions?utf8=%E2%9C%93&applicant%5Bis_pregnant%5D=false&applicant%5Bpregnancy_due_on%5D=&applicant%5Bchildren_expected_count%5D=&applicant%5Bis_post_partum_period%5D=false&applicant%5Bpregnancy_end_on%5D=&applicant%5Bfoster_care_us_state%5D=&applicant%5Bage_left_foster_care%5D=&applicant%5Bis_self_attested_blind%5D=false&applicant%5Bhas_daily_living_help%5D=false&applicant%5Bneed_help_paying_bills%5D=false&applicant%5Bis_physically_disabled%5D=false&applicant%5Bis_primary_caregiver%5D=false&applicant%5Bis_primary_caregiver_for%5D%5B%5D=&applicant%5Bis_primary_caregiver_for%5D%5B%5D=&commit=CONTINUE',
        {
          headers: {
            'upgrade-insecure-requests': '1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(4)
    }
  )

  group(
    'page_22 - https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/review_and_submit',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/review_and_submit',
        {
          headers: {
            accept: 'text/html, application/xhtml+xml',
            'turbolinks-referrer':
              'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/edit',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(6.3)
    }
  )

  group(
    'page_23 - https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/step/1',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/step/1',
        {
          headers: {
            accept: 'text/html, application/xhtml+xml',
            'turbolinks-referrer':
              'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/review_and_submit',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(3.1)
    }
  )

  group(
    'page_24 - https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/step',
    function () {
      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/step',
        {
          utf8: `${vars['utf85']}`,
          _method: `${vars['_method2']}`,
          authenticity_token:
            'x8iJvC7LbckODn2Ta6WhDHdkG+nOjBJCrfB0/Spt5G1eg/LB08btj4tGImAN0IOxW4nXufLkifS5c8MZcjn30g==',
          'application[is_renewal_authorized]': `${vars['last_step1']}`,
          commit: 'CONTINUE',
        },
        {
          headers: {
            'content-type': 'application/x-www-form-urlencoded',
            origin: 'https://perf-test-enroll.cme.openhbx.org',
            'upgrade-insecure-requests': '1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(25.5)

      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/step',
        new URLSearchParams({
          utf8: `${vars['utf85']}`,
          _method: `${vars['_method2']}`,
          authenticity_token:
            '+lSwTWZyv0HQL5KUFSEPv0N9JVbxDoMqmJ/rdVwgkidjH8swm38/B1VnzWdzVC0Cb5DpBs1mGJyMHFyRBHSBmA==',
          'application[medicaid_terms]': 'yes',
          'application[report_change_terms]': 'yes',
          'application[medicaid_insurance_collection_terms]': 'yes',
          'application[parent_living_out_of_home_terms]': `${vars['exit_after_method1']}`,
          'application[submission_terms]': 'yes',
          first_name_thank_you: 'kara',
          subscriber_first_name: ['kara', 'kara', 'kara'],
          subscriber_last_name: ['con1', 'con1', 'con1'],
          middle_name_thank_you: `${vars['person[tribe_codes][]1']}`,
          last_name_thank_you: 'con1',
          commit: 'Submit Application',
        }).toString(),
        {
          headers: {
            'content-type': 'application/x-www-form-urlencoded',
            origin: 'https://perf-test-enroll.cme.openhbx.org',
            'upgrade-insecure-requests': '1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(2.9)

      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/check_eligibility_results_received',
        {
          headers: {
            accept: '*/*',
            'x-csrf-token':
              '6qgRIKJ5Y0uZcbW5aLOaIz93AKLEIDEKicKcnxxplG5z42pdX3TjDRw56koOxrieE5rM8vhIqrydQSt7RD2H0Q==',
            'x-requested-with': 'XMLHttpRequest',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
    }
  )

  group(
    'page_25 - https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/eligibility_results?cur=1',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/eligibility_results?cur=1',
        {
          headers: {
            'upgrade-insecure-requests': '1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(15.2)
    }
  )

  group(
    'page_26 - https://perf-test-enroll.cme.openhbx.org/insured/group_selections/new?consumer_role_id=653abfd2c8a486000f8f40b1&person_id=653abfd2c8a486000f8f40a4',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/insured/group_selections/new?consumer_role_id=653abfd2c8a486000f8f40b1&person_id=653abfd2c8a486000f8f40a4',
        {
          headers: {
            accept: 'text/html, application/xhtml+xml',
            'turbolinks-referrer':
              'https://perf-test-enroll.cme.openhbx.org/financial_assistance/applications/653ac015c8a486000f8f40c7/eligibility_results?cur=1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(21.5)
    }
  )

  group('page_27 - https://perf-test-enroll.cme.openhbx.org/insured/group_selections', function () {
    response = http.post(
      'https://perf-test-enroll.cme.openhbx.org/insured/group_selections',
      {
        utf8: `${vars['utf85']}`,
        authenticity_token:
          'YjXn3fsqFTdBqlMW0DwSLJkgkJpSGfIomoCovu/kchD7fpygBieVccTiDOW2STCRtc1cym5xaZ6OAx9at7Bhrw==',
        waiver_reason: `${vars['person[tribe_codes][]1']}`,
        is_waiving: `${vars['person[tribe_codes][]1']}`,
        person_id: '653abfd2c8a486000f8f40a4',
        coverage_household_id: `${vars['person[tribe_codes][]1']}`,
        enrollment_kind: `${vars['person[tribe_codes][]1']}`,
        'family_member_ids[0]': '653abfd2c8a486000f8f40ae',
        is_tobacco_user_653abfd2c8a486000f8f40ae: 'N',
        market_kind: 'individual',
        coverage_kind: 'health',
      },
      {
        headers: {
          'content-type': 'application/x-www-form-urlencoded',
          origin: 'https://perf-test-enroll.cme.openhbx.org',
          'upgrade-insecure-requests': '1',
          'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
          'sec-ch-ua-mobile': '?0',
          'sec-ch-ua-platform': '"macOS"',
        },
      }
    )
    sleep(14.8)
  })

  group(
    'page_28 - https://perf-test-enroll.cme.openhbx.org/insured/plan_shoppings/653ac0cdc8a486000f8f40db/thankyou?change_plan=&coverage_kind=health&enrollment_kind=&market_kind=individual&plan_id=65219d55efa7a301c093afa0',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/insured/plan_shoppings/653ac0cdc8a486000f8f40db/thankyou?change_plan=&coverage_kind=health&enrollment_kind=&market_kind=individual&plan_id=65219d55efa7a301c093afa0',
        {
          headers: {
            'upgrade-insecure-requests': '1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(11.8)
    }
  )

  group(
    'page_29 - https://perf-test-enroll.cme.openhbx.org/insured/plan_shoppings/653ac0cdc8a486000f8f40db/checkout?coverage_kind=health&market_kind=individual&plan_id=65219d55efa7a301c093afa0',
    function () {
      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/insured/plan_shoppings/653ac0cdc8a486000f8f40db/checkout?coverage_kind=health&market_kind=individual&plan_id=65219d55efa7a301c093afa0',
        {
          _method: 'post',
          authenticity_token:
            '6hjW0sAC4grwcRKRRk2OOq2DnRnjV/S+Fg4d02H5VOxzU62vPQ9iTHU5TWIgOKyHgW5RSd8/bwgCjao3Oa1HUw==',
        },
        {
          headers: {
            'content-type': 'application/x-www-form-urlencoded',
            origin: 'https://perf-test-enroll.cme.openhbx.org',
            'upgrade-insecure-requests': '1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(4.2)
    }
  )

  group('page_30 - https://perf-test-enroll.cme.openhbx.org/families/home', function () {
    response = http.get('https://perf-test-enroll.cme.openhbx.org/families/home', {
      headers: {
        accept: 'text/html, application/xhtml+xml',
        'turbolinks-referrer':
          'https://perf-test-enroll.cme.openhbx.org/insured/plan_shoppings/653ac0cdc8a486000f8f40db/receipt',
        'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"macOS"',
      },
    })
    response = http.get('https://perf-test-enroll.cme.openhbx.org/families/home', {
      headers: {
        'upgrade-insecure-requests': '1',
        'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"macOS"',
      },
    })
    sleep(9.3)
  })

  group(
    'page_31 - https://perf-test-enroll.cme.openhbx.org/insured/group_selections/new?change_plan=change_plan&person_id=653abfd2c8a486000f8f40a4&shop_for_plan=shop_for_plan',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/insured/group_selections/new?change_plan=change_plan&person_id=653abfd2c8a486000f8f40a4&shop_for_plan=shop_for_plan',
        {
          headers: {
            accept: 'text/html, application/xhtml+xml',
            'turbolinks-referrer': 'https://perf-test-enroll.cme.openhbx.org/families/home',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/insured/group_selections/new?change_plan=change_plan&person_id=653abfd2c8a486000f8f40a4&shop_for_plan=shop_for_plan',
        {
          headers: {
            'upgrade-insecure-requests': '1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(6)
    }
  )

  group('page_32 - https://perf-test-enroll.cme.openhbx.org/insured/group_selections', function () {
    response = http.post(
      'https://perf-test-enroll.cme.openhbx.org/insured/group_selections',
      {
        utf8: `${vars['utf85']}`,
        authenticity_token:
          'huv/5FTXE5WRW2CCwhZpveOl6/7/CUYS/tIujQXLjKQfoISZqdqT0xQTP3GkY0sAz0gnrsNh3aTqUZlpXZ+fGw==',
        waiver_reason: `${vars['person[tribe_codes][]1']}`,
        is_waiving: `${vars['person[tribe_codes][]1']}`,
        person_id: '653abfd2c8a486000f8f40a4',
        coverage_household_id: `${vars['person[tribe_codes][]1']}`,
        enrollment_kind: `${vars['person[tribe_codes][]1']}`,
        'family_member_ids[0]': '653abfd2c8a486000f8f40ae',
        is_tobacco_user_653abfd2c8a486000f8f40ae: 'N',
        market_kind: 'individual',
        coverage_kind: 'dental',
        change_plan: 'change_plan',
        commit: 'Shop for new plan',
      },
      {
        headers: {
          'content-type': 'application/x-www-form-urlencoded',
          origin: 'https://perf-test-enroll.cme.openhbx.org',
          'upgrade-insecure-requests': '1',
          'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
          'sec-ch-ua-mobile': '?0',
          'sec-ch-ua-platform': '"macOS"',
        },
      }
    )
    sleep(5.3)
  })

  group(
    'page_33 - https://perf-test-enroll.cme.openhbx.org/insured/plan_shoppings/653ac0fcc8a486000f8f40e0/thankyou?change_plan=change_plan&coverage_kind=dental&enrollment_kind=&market_kind=individual&plan_id=65219d62efa7a301c093fdd6',
    function () {
      response = http.get(
        'https://perf-test-enroll.cme.openhbx.org/insured/plan_shoppings/653ac0fcc8a486000f8f40e0/thankyou?change_plan=change_plan&coverage_kind=dental&enrollment_kind=&market_kind=individual&plan_id=65219d62efa7a301c093fdd6',
        {
          headers: {
            'upgrade-insecure-requests': '1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(12.2)
    }
  )

  group(
    'page_34 - https://perf-test-enroll.cme.openhbx.org/insured/plan_shoppings/653ac0fcc8a486000f8f40e0/checkout?change_plan=change_plan&coverage_kind=dental&market_kind=individual&plan_id=65219d62efa7a301c093fdd6',
    function () {
      response = http.post(
        'https://perf-test-enroll.cme.openhbx.org/insured/plan_shoppings/653ac0fcc8a486000f8f40e0/checkout?change_plan=change_plan&coverage_kind=dental&market_kind=individual&plan_id=65219d62efa7a301c093fdd6',
        {
          _method: 'post',
          authenticity_token:
            'h32s3/6WjNQUX5dbdExTJkNvlB3Uhvx7Y7bc9UlMNykeNteiA5sMkpEXyKgSOXGbb4JYTejuZ813NWsRERgklg==',
        },
        {
          headers: {
            'content-type': 'application/x-www-form-urlencoded',
            origin: 'https://perf-test-enroll.cme.openhbx.org',
            'upgrade-insecure-requests': '1',
            'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        }
      )
      sleep(2.4)
    }
  )

  group('page_35 - https://perf-test-enroll.cme.openhbx.org/families/home', function () {
    response = http.get('https://perf-test-enroll.cme.openhbx.org/families/home', {
      headers: {
        accept: 'text/html, application/xhtml+xml',
        'turbolinks-referrer':
          'https://perf-test-enroll.cme.openhbx.org/insured/plan_shoppings/653ac0fcc8a486000f8f40e0/receipt?change_plan=change_plan',
        'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"macOS"',
      },
    })
    response = http.get('https://perf-test-enroll.cme.openhbx.org/families/home', {
      headers: {
        'upgrade-insecure-requests': '1',
        'sec-ch-ua': '"Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"macOS"',
      },
    })
  })
}
