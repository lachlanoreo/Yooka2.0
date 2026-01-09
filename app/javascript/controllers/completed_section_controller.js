import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon", "taskList"]

  connect() {
    this.expanded = false
  }

  toggle() {
    this.expanded = !this.expanded

    if (this.expanded) {
      this.contentTarget.classList.remove("hidden")
      this.iconTarget.classList.add("completed-section__icon--open")
    } else {
      this.contentTarget.classList.add("hidden")
      this.iconTarget.classList.remove("completed-section__icon--open")
    }
  }
}
