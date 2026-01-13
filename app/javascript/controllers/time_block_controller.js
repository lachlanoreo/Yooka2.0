import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["time"]

  static values = {
    id: Number,
    start: Number,
    duration: Number,
    totalMinutes: Number,
    frozen: { type: Boolean, default: false }
  }

  // Constants
  static SNAP_INCREMENT = 5
  static DAY_START_MINUTES = 420  // 7:00 AM
  static DAY_END_MINUTES = 1200   // 8:00 PM

  connect() {
    this.isDragging = false
    this.isResizing = false
    this.startY = 0
    this.startTopPercent = 0
    this.startHeightPercent = 0

    // Bind event handlers
    this.handleMouseMove = this.handleMouseMove.bind(this)
    this.handleMouseUp = this.handleMouseUp.bind(this)

    // Add drag start listener
    this.element.addEventListener("mousedown", this.startDrag.bind(this))
  }

  get containerHeight() {
    // Find the events container (parent of timeBlocks wrapper)
    return this.element.parentElement.parentElement.offsetHeight
  }

  get totalMinutes() {
    return this.totalMinutesValue || 780 // Default: 13 hours
  }

  percentToMinutes(percent) {
    return (percent / 100) * this.totalMinutes
  }

  minutesToPercent(minutes) {
    return (minutes / this.totalMinutes) * 100
  }

  startDrag(event) {
    // Don't start drag if clicking on resize handle
    if (event.target.dataset.action?.includes("startResize")) return
    // Don't allow drag on frozen time blocks
    if (this.frozenValue) return

    this.isDragging = true
    this.startY = event.clientY
    this.startTopPercent = parseFloat(this.element.style.top) || 0

    document.addEventListener("mousemove", this.handleMouseMove)
    document.addEventListener("mouseup", this.handleMouseUp)

    event.preventDefault()
  }

  startResize(event) {
    // Don't allow resize on frozen time blocks
    if (this.frozenValue) return

    this.isResizing = true
    this.startY = event.clientY
    this.startHeightPercent = parseFloat(this.element.style.height) || this.minutesToPercent(this.durationValue)

    document.addEventListener("mousemove", this.handleMouseMove)
    document.addEventListener("mouseup", this.handleMouseUp)

    event.preventDefault()
    event.stopPropagation()
  }

  handleMouseMove(event) {
    const deltaY = event.clientY - this.startY
    const containerHeight = this.containerHeight
    const deltaPercent = (deltaY / containerHeight) * 100

    if (this.isDragging) {
      let newTopPercent = this.startTopPercent + deltaPercent

      // Convert to minutes for snapping
      let newTopMinutes = this.percentToMinutes(newTopPercent)
      // Snap to 5-minute increments
      newTopMinutes = Math.round(newTopMinutes / this.constructor.SNAP_INCREMENT) * this.constructor.SNAP_INCREMENT
      // Clamp to day bounds
      newTopMinutes = Math.max(0, newTopMinutes)
      const maxTopMinutes = this.totalMinutes - this.durationValue
      newTopMinutes = Math.min(maxTopMinutes, newTopMinutes)

      // Convert back to percent
      newTopPercent = this.minutesToPercent(newTopMinutes)
      this.element.style.top = `${newTopPercent}%`
    }

    if (this.isResizing) {
      let newHeightPercent = this.startHeightPercent + deltaPercent

      // Convert to minutes for snapping
      let newDurationMinutes = this.percentToMinutes(newHeightPercent)
      // Snap to 5-minute increments
      newDurationMinutes = Math.round(newDurationMinutes / this.constructor.SNAP_INCREMENT) * this.constructor.SNAP_INCREMENT
      // Enforce minimum (5 mins) and maximum
      newDurationMinutes = Math.max(this.constructor.SNAP_INCREMENT, newDurationMinutes)
      const currentTopMinutes = this.percentToMinutes(parseFloat(this.element.style.top) || 0)
      const maxDurationMinutes = this.totalMinutes - currentTopMinutes
      newDurationMinutes = Math.min(maxDurationMinutes, newDurationMinutes)

      // Convert back to percent
      newHeightPercent = this.minutesToPercent(newDurationMinutes)
      this.element.style.height = `${newHeightPercent}%`
    }
  }

  async handleMouseUp() {
    document.removeEventListener("mousemove", this.handleMouseMove)
    document.removeEventListener("mouseup", this.handleMouseUp)

    if (this.isDragging || this.isResizing) {
      const topPercent = parseFloat(this.element.style.top) || 0
      const heightPercent = parseFloat(this.element.style.height) || this.minutesToPercent(this.durationValue)

      // Convert percentages to minutes
      const topMinutes = this.percentToMinutes(topPercent)
      const durationMinutes = this.percentToMinutes(heightPercent)

      // Calculate absolute start time
      const newStartMinutes = this.constructor.DAY_START_MINUTES + topMinutes

      // Save to server
      await this.savePosition(newStartMinutes, durationMinutes)
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
          start_minutes: Math.round(startMinutes),
          duration_minutes: Math.round(durationMinutes)
        })
      })

      if (!response.ok) {
        console.error("Error saving time block position")
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
