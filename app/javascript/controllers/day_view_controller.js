import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["googleEvents", "timeBlocks"]

  connect() {
    // Day view controller for managing the calendar layout
    // Google Calendar events will be loaded here when OAuth is set up
  }
}
