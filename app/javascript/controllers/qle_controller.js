import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "question" ]

  addQuestion(e) {
    var newQuestion = document.importNode(this.questionTarget, true)
    newQuestion.classList.remove('hidden')

    this.uniqueInputs(newQuestion);
    var addButtonRow = e.currentTarget.parentNode.parentNode;
    addButtonRow.parentNode.insertBefore(newQuestion, addButtonRow);
  }

  addDateResponse(e) {
    var answer = e.currentTarget.closest('.js-answer');
    var newResponse = document.importNode(answer.querySelector('.js-new-date-response'), true);

    newResponse.classList.remove('hidden', 'js-new-date-response');
    newResponse.classList.add('js-response');
    this.uniqueInputs(newResponse);
    answer.querySelector('.js-date-responses').appendChild(newResponse);
  }

  addMultipleChoiceResponse(e) {
    var answer = e.currentTarget.closest('.js-answer');
    var newResponse = document.importNode(answer.querySelector('.js-new-multiple-choice-response'), true);

    newResponse.classList.remove('hidden', 'js-new-date-response');
    newResponse.classList.add('js-response');
    this.uniqueInputs(newResponse);
    answer.querySelector('.js-multiple-choice-responses').appendChild(newResponse);
  }

  removeResponse(e) {
    var response = e.currentTarget.closest('.js-response');
    response.remove();
  }

  showAnswer(e){
    var question = e.currentTarget.closest('.js-question')
    question.querySelectorAll('.js-answer').forEach(function(element) {
      if (element.dataset.answerType == e.currentTarget.value)
        element.classList.remove('hidden')
      else
        element.classList.add('hidden')
    });
    // document.getElementById('custom-answer-type').remove('slow')
  }

  uniqueInputs(node) {
    node.querySelectorAll('input').forEach(function(input) {
      var name = input.getAttribute('name')
      if (name) {
        name.replace(/\[\d+\]/, `[${Date.now()}]`);
        input.setAttribute('name', name)
      }
    });
  }
}
