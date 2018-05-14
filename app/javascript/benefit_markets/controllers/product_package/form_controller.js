import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ['endOn']

  startChange(event) {
    const yearLater = new Date(event.currentTarget.value)
    yearLater.setFullYear(yearLater.getFullYear() + 1)
    this.endOnTarget.value = yearLater.toISOString().replace(/T.*$/, '')
  }
}
