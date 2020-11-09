module CapybaraHelpers
  # Perform an action then wait for the page to reload before proceeding
  def wait_for_page_reload_until(timeout, slice_size = 0.2, &blk)
    execute_script(<<-JSCODE)
      window.document['_test_waiting_for_page_reload'] = true; 
    JSCODE
    blk.call
    wait_for_condition_until(timeout, slice_size) do
      evaluate_script(<<-JSCODE)
        !(window.document['_test_waiting_for_page_reload'] == true)
      JSCODE
    end
    execute_script(<<-JSCODE)
      delete window.document['_test_waiting_for_page_reload'];
    JSCODE
  end


  # Throw a one-time load callback on datatables so we can use it to make sure
  # it has finished loading.  Useful for clicking a filter and making sure it's
  # done reloading.
  def with_datatable_load_wait(timeout, slice_size = 0.2, &blk)
    execute_script(<<-JSCODE)
      $('.effective-datatable').DataTable().one('draw.dt', function() {
        window['ef_datatables_done_loading'] = true; 
      });
    JSCODE
    blk.call
    wait_for_condition_until(timeout, slice_size) do
      evaluate_script(<<-JSCODE)
        window['ef_datatables_done_loading'] == true
      JSCODE
    end
    execute_script(<<-JSCODE)
      delete window['ef_datatables_done_loading'];
    JSCODE
  end

  def wait_for_condition_until(timeout, slice_size = 0.2, &blk)
    test_val = blk.call
    waited_time = 0
    while((!test_val) && (waited_time < timeout)) do
      sleep slice_size
      test_val = blk.call
      waited_time = waited_time + slice_size
    end
  end

  def select_from_chosen(val, from:)
    chosen_input = find 'a.chosen-single'
    chosen_input.click
    chosen_results = find 'ul.chosen-results'
    within(chosen_results) do
      find('li', text: val).click
    end
  end

  def wait_for_ajax(delta=2, time_to_sleep=0.2)
    start_time = Time.now
    Timeout.timeout(delta) do
      until finished_all_ajax_requests? do
        sleep(0.01)
      end
    end
    end_time = Time.now
    if Time.now > start_time + delta.seconds
      fail "ajax request failed: took longer than #{delta.seconds} seconds. It waited #{end_time - start_time} seconds."
    end
    sleep(time_to_sleep)
  end

  # TODO: Not sure this is still the most current API.
  #       Recent reading indicates it might have been swapped out for
  #       "jQuery.ajax.active".
  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end

  def click_outside_datepicker(text_outside_datepicker)
    page.find(:xpath, "//*[text()='#{text_outside_datepicker}']").click
  end

  # This exists entirely to deal with the funky stuff that our
  # UI toolkit can do to radio buttons, mainly on the IVL page.
  def click_and_wait_on_stylized_radio(xpath, input_id, field_name, value)
    find_field(field_name, id: input_id, visible: :all, disabled: :all, wait: 5)
    find(:xpath, xpath, wait: 5).click
    find(:xpath, xpath, wait: 5).click
    begin
      find_field(field_name, with: value, checked: true, visible: :all, disabled: :all, wait: 10)
    rescue
      all(:xpath, "//input[@name=\"#{field_name}\"]", visible: :all).each do |ele|
        puts xpath
        puts input_id
        puts field_name
        puts ele.tag_name.inspect
        puts ele["type"].inspect
        puts ele.text.inspect
        puts ele.value.inspect
        puts ele.visible?.inspect
        puts ele.disabled?.inspect
        puts ele.selected?.inspect
        puts ele.checked?.inspect
        puts ele.obscured?.inspect
      end
      raise "Couldn't find tag.  Check output for matched elements."
    end
  end

  def l10n(translation_key, interpolated_keys={})
    begin
      I18n.t(translation_key, interpolated_keys.merge(raise: true)).html_safe
    rescue I18n::MissingTranslationData
      translation_key.gsub(/\W+/, '').titleize
    end
  end
end

World(CapybaraHelpers)
