import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this)
  }

  toggle() {
    if (this.menuTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    // Trigger reflow for animation
    this.menuTarget.offsetHeight
    this.menuTarget.classList.add("open")
    document.addEventListener("click", this.closeOnClickOutside)
  }

  close() {
    this.menuTarget.classList.remove("open")
    // Wait for animation to finish before hiding
    setTimeout(() => {
      this.menuTarget.classList.add("hidden")
    }, 200)
    document.removeEventListener("click", this.closeOnClickOutside)
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside)
  }
}
