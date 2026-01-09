import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static values = { group: String }

  connect() {
    this.sortable = Sortable.create(this.element, {
      group: "tasks",
      animation: 150,
      handle: "[data-drag-handle]",
      ghostClass: "opacity-50",
      dragClass: "shadow-lg",
      onEnd: this.onEnd.bind(this)
    })
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
    }
  }

  async onEnd(event) {
    const taskId = event.item.dataset.taskId
    const fromGroup = event.from.dataset.sortableGroupValue
    const toGroup = event.to.dataset.sortableGroupValue
    const newIndex = event.newIndex

    if (fromGroup !== toGroup) {
      // Moving between groups
      await this.moveToGroup(taskId, toGroup, newIndex)
    } else {
      // Reordering within same group
      await this.reorder(taskId, newIndex)
    }
  }

  async moveToGroup(taskId, group, position) {
    try {
      // First move to the new group
      const moveResponse = await fetch(`/tasks/${taskId}/move`, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: JSON.stringify({ group: group })
      })

      if (!moveResponse.ok) {
        console.error("Failed to move task")
        window.location.reload()
        return
      }

      // Then reorder to the correct position
      await this.reorder(taskId, position)
    } catch (error) {
      console.error("Error moving task:", error)
      window.location.reload()
    }
  }

  async reorder(taskId, position) {
    try {
      const response = await fetch(`/tasks/${taskId}/reorder`, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: JSON.stringify({ position: position })
      })

      if (!response.ok) {
        console.error("Failed to reorder task")
      }
    } catch (error) {
      console.error("Error reordering task:", error)
    }
  }
}
