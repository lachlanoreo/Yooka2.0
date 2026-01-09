import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { id: Number }

  async toggleComplete() {
    const task = this.element
    const isCompleted = task.querySelector("button svg") !== null
    const action = isCompleted ? "uncomplete" : "complete"

    try {
      const response = await fetch(`/tasks/${this.idValue}/${action}`, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "text/vnd.turbo-stream.html"
        }
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error("Error toggling task completion:", error)
    }
  }

  async moveTo(event) {
    const group = event.target.dataset.group

    try {
      const response = await fetch(`/tasks/${this.idValue}/move`, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: JSON.stringify({ group: group })
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error("Error moving task:", error)
    }
  }

  async archive() {
    if (!confirm("Are you sure you want to archive this task?")) return

    try {
      const response = await fetch(`/tasks/${this.idValue}/archive`, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "text/vnd.turbo-stream.html"
        }
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error("Error archiving task:", error)
    }
  }
}
