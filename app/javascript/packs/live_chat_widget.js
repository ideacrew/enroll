document.addEventListener("DOMContentLoaded", function() {
  var qna_bot_open_click_buttons = document.getElementsByClassName("qna-bot-open-click-button");
  if (qna_bot_open_click_buttons != null) {
    for (var i = 0; i < qna_bot_open_click_buttons.length; i++) {
      var qa_open_button = qna_bot_open_click_buttons[i];
      qa_open_button.addEventListener("click", function() {
        openQnaBot();
      });
    }
  }
  var live_webchat_open_click_buttons = document.getElementsByClassName("live-webchat-open-click-button");
  if (live_webchat_open_click_buttons != null) {
    for (var i = 0; i < live_webchat_open_click_buttons.length; i++) {
      var live_webchat_open_button = live_webchat_open_click_buttons[i];
      live_webchat_open_button.addEventListener("click", function() {
        customPlugin.command('WebChat.open', getAdvancedConfig());
      });
    }
  }
});