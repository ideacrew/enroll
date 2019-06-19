import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "question", "questionContainer" ]

  addQuestion(e) {
    var newQuestion = document.importNode(this.questionTarget, true)
    newQuestion.classList.remove('hidden')
    newQuestion.classList.add('js-question')
    document.getElementById('question-container').classList.remove('hidden')
  

    this.uniqueInputs(newQuestion);
    var addButtonRow = e.currentTarget.parentNode.parentNode;
    addButtonRow.parentNode.insertBefore(newQuestion, addButtonRow);
  }

  changeDateOperator(e){
    console.log("hit change date")
  }

  showQuestion(e){
    e.currentTarget.classList.add('hidden')
    var question = e.currentTarget.closest('.js-question')
    question.querySelector('.js-question-text span').innerHTML = e.currentTarget.value
    question.querySelector('.js-question-text').classList.remove('hidden')
    question.querySelector('.js-question-type').classList.remove('hidden')
  }
  addDateResponse(e) {
    var answer = e.currentTarget.closest('.js-answer');
    var newResponse = document.importNode(answer.querySelector('.js-new-date-response'), true);

    newResponse.classList.remove('hidden', 'js-new-date-response');
    newResponse.classList.add('js-response');
    this.uniqueInputs(newResponse);
    answer.querySelector('.js-date-responses').appendChild(newResponse);
  }
  changeMultipleChoiceResult(e){

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

  showQuestions(e){
    this.questionContainerTarget.classList.remove('hidden')
    this.addQuestion({currentTarget: this.questionContainerTarget.querySelector("#create-question-text a")})

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
