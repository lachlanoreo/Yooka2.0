import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["button", "buttonText", "spinner"]

  connect() {
    this.subscription = null
  }

  disconnect() {
    this.unsubscribe()
  }

  sync(event) {
    event.preventDefault()

    // Show loading state immediately
    this.showSyncing()

    // Subscribe to channel before triggering sync
    this.subscribe()

    // Trigger the sync via POST
    fetch("/basecamp/sync", {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      }
    }).then(response => {
      if (!response.ok) {
        throw new Error("Failed to start sync")
      }
      return response.json()
    }).catch(error => {
      this.handleError(error.message)
    })
  }

  subscribe() {
    if (this.subscription) return

    this.subscription = consumer.subscriptions.create(
      { channel: "BasecampSyncChannel" },
      {
        received: (data) => this.handleMessage(data),
        connected: () => console.log("Connected to BasecampSyncChannel"),
        disconnected: () => console.log("Disconnected from BasecampSyncChannel")
      }
    )
  }

  unsubscribe() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }

  handleMessage(data) {
    switch (data.type) {
      case "sync_started":
        this.buttonTextTarget.textContent = "Starting..."
        break
      case "project_progress":
        this.buttonTextTarget.textContent = `Syncing ${data.current_index} of ${data.total_projects}`
        break
      case "sync_completed":
        this.handleSyncCompleted(data)
        break
      case "sync_failed":
        this.handleError(data.message || "Sync failed")
        break
    }
  }

  handleSyncCompleted(data) {
    this.buttonTextTarget.textContent = "Synced!"

    this.unsubscribe()

    // Refresh page after short delay to show updated tasks
    setTimeout(() => {
      window.location.reload()
    }, 1000)
  }

  showSyncing() {
    this.buttonTarget.disabled = true
    this.buttonTextTarget.textContent = "Starting..."

    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.remove("hidden")
    }
  }

  handleError(message) {
    this.buttonTarget.disabled = false
    this.buttonTextTarget.textContent = "Sync Now"

    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add("hidden")
    }

    this.unsubscribe()

    // Show error briefly in console
    console.error("Sync error:", message)
  }
}
