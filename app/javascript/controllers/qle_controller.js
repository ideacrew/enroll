import { Controller } from "stimulus"

export default class extends Controller {
  showDate(){
    document.getElementById('create-date-answers').style.display = 'block'
    // document.getElementById('custom-answer-type').remove('slow')
  } 
  showQuestion(){
    console.log('question hit')
  }
  showMc(){
    document.getElementById('create-multiple-choice-answers').style.display = 'block'
    // document.getElementById('custom-answer-type').remove('slow')
  } 
  showBoolean(){
    console.log('hit date added')
  } 
}
