import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    id: Number,
    start: Number,
    duration: Number
  }

  // Constants matching the server-side values
  static PIXELS_PER_MINUTE = 1
  static SNAP_INCREMENT = 5
  static DAY_START_MINUTES = 420  // 7:00 AM
  static DAY_END_MINUTES = 1200   // 8:00 PM

  connect() {
    this.isDragging = false
    this.isResizing = false
    this.startY = 0
    this.startTop = 0
    this.startHeight = 0

    // Bind event handlers
    this.handleMouseMove = this.handleMouseMove.bind(this)
    this.handleMouseUp = this.handleMouseUp.bind(this)

    // Add drag start listener
    this.element.addEventListener("mousedown", this.startDrag.bind(this))
  }

  startDrag(event) {
    // Don't start drag if clicking on resize handle
    if (event.target.dataset.action?.includes("startResize")) return

    this.isDragging = true
    this.startY = event.clientY
    this.startTop = parseInt(this.element.style.top) || 0

    document.addEventListener("mousemove", this.handleMouseMove)
    document.addEventListener("mouseup", this.handleMouseUp)

    event.preventDefault()
  }

  startResize(event) {
    this.isResizing = true
    this.startY = event.clientY
    this.startHeight = parseInt(this.element.style.height) || this.durationValue

    document.addEventListener("mousemove", this.handleMouseMove)
    document.addEventListener("mouseup", this.handleMouseUp)

    event.preventDefault()
    event.stopPropagation()
  }

  handleMouseMove(event) {
    const deltaY = event.clientY - this.startY

    if (this.isDragging) {
      let newTop = this.startTop + deltaY
      // Snap to 5-minute increments
      newTop = Math.round(newTop / this.constructor.SNAP_INCREMENT) * this.constructor.SNAP_INCREMENT
      // Clamp to day bounds
      newTop = Math.max(0, newTop)
      const maxTop = (this.constructor.DAY_END_MINUTES - this.constructor.DAY_START_MINUTES - this.durationValue)
      newTop = Math.min(maxTop, newTop)

      this.element.style.top = `${newTop}px`
    }

    if (this.isResizing) {
      let newHeight = this.startHeight + deltaY
      // Snap to 5-minute increments
      newHeight = Math.round(newHeight / this.constructor.SNAP_INCREMENT) * this.constructor.SNAP_INCREMENT
      // Enforce minimum and maximum
      newHeight = Math.max(this.constructor.SNAP_INCREMENT, newHeight)
      const currentTop = parseInt(this.element.style.top) || 0
      const maxHeight = (this.constructor.DAY_END_MINUTES - this.constructor.DAY_START_MINUTES) - currentTop
      newHeight = Math.min(maxHeight, newHeight)

      this.element.style.height = `${newHeight}px`
    }
  }

  async handleMouseUp() {
    document.removeEventListener("mousemove", this.handleMouseMove)
    document.removeEventListener("mouseup", this.handleMouseUp)

    if (this.isDragging || this.isResizing) {
      const newTop = parseInt(this.element.style.top) || 0
      const newHeight = parseInt(this.element.style.height) || this.durationValue

      // Convert back to minutes
      const newStartMinutes = this.constructor.DAY_START_MINUTES + newTop
      const newDuration = newHeight

      // Save to server
      await this.savePosition(newStartMinutes, newDuration)
    }

    this.isDragging = false
    this.isResizing = false
  }

  async savePosition(startMinutes, durationMinutes) {
    try {
      const response = await fetch(`/time_blocks/${this.idValue}`, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          start_minutes: startMinutes,
          duration_minutes: durationMinutes
        })
      })

      if (!response.ok) {
        console.error("Error saving time block position")
        // Could add error handling / reverting here
      }
    } catch (error) {
      console.error("Error saving time block:", error)
    }
  }

  disconnect() {
    document.removeEventListener("mousemove", this.handleMouseMove)
    document.removeEventListener("mouseup", this.handleMouseUp)
  }
}
