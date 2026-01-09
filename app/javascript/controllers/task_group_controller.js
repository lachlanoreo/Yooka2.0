import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["newTaskForm", "newTaskInput", "taskList"]
  static values = { name: String }

  showNewTaskForm() {
    this.newTaskFormTarget.classList.remove("hidden")
    this.newTaskInputTarget.focus()
  }

  hideNewTaskForm() {
    this.newTaskFormTarget.classList.add("hidden")
    this.newTaskInputTarget.value = ""
  }

  async createTask(event) {
    event.preventDefault()
    const form = event.target
    const formData = new FormData(form)

    try {
      const response = await fetch(form.action, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: formData
      })

      if (response.ok) {
        this.hideNewTaskForm()
        // Turbo Stream will handle the DOM update
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error("Error creating task:", error)
    }
  }
}
