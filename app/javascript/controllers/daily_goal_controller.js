import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "status"]
  static values = { date: String }

  connect() {
    this.saveTimeout = null
  }

  save() {
    // Debounce the save
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout)
    }

    this.statusTarget.textContent = "Saving..."

    this.saveTimeout = setTimeout(async () => {
      try {
        const response = await fetch(`/daily_goals/${this.dateValue}`, {
          method: "PATCH",
          headers: {
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({ content: this.inputTarget.value })
        })

        if (response.ok) {
          this.statusTarget.textContent = "Saved"
          setTimeout(() => {
            this.statusTarget.textContent = ""
          }, 2000)
        } else {
          this.statusTarget.textContent = "Error saving"
        }
      } catch (error) {
        console.error("Error saving daily goal:", error)
        this.statusTarget.textContent = "Error saving"
      }
    }, 500)
  }

  disconnect() {
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout)
    }
  }
}
