import { Controller } from "@hotwired/stimulus"

// Dropdown controller using portal pattern to escape overflow containers
// The dropdown is moved to document.body when opened, then returned when closed
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this)
    this.closeOnScroll = this.closeOnScroll.bind(this)
    this.handleItemClick = this.handleItemClick.bind(this)
    this.isOpen = false
    this.originalParent = null
    this.taskRowElement = null
    this.justOpened = false
    this.menuElement = null  // Store direct reference to menu element
  }

  // Safe getter for menu element (works even after moving to body)
  get menu() {
    return this.menuElement || (this.hasMenuTarget ? this.menuTarget : null)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.isOpen) {
      this.close()
    } else {
      this.open(event)
    }
  }

  open(event) {
    const button = event.currentTarget
    const menu = this.menuTarget  // Get from Stimulus target while still in place

    // Store direct reference before we move it
    this.menuElement = menu

    // Store reference to the task-row element for forwarding actions
    this.taskRowElement = this.element.closest('[data-controller~="task-row"]')

    // Store original parent so we can return the menu later
    this.originalParent = menu.parentElement

    // Move menu to body to escape all overflow containers
    document.body.appendChild(menu)

    // Add click listener to menu items (since data-action won't work after move)
    menu.addEventListener("click", this.handleItemClick)

    // Remove hidden class and set up fixed positioning
    menu.classList.remove("hidden")
    menu.style.position = "fixed"
    menu.style.zIndex = "9999"

    // Calculate position based on button's viewport coordinates
    const buttonRect = button.getBoundingClientRect()
    const menuWidth = menu.offsetWidth
    const menuHeight = menu.offsetHeight

    // Position aligned to right edge of button, below it
    let left = buttonRect.right - menuWidth
    let top = buttonRect.bottom + 4

    // Ensure menu doesn't go off left edge
    if (left < 8) {
      left = 8
    }

    // Ensure menu doesn't go off right edge
    if (left + menuWidth > window.innerWidth - 8) {
      left = window.innerWidth - menuWidth - 8
    }

    // If menu would go below viewport, flip it above the button
    if (top + menuHeight > window.innerHeight - 8) {
      top = buttonRect.top - menuHeight - 4
    }

    // Ensure it doesn't go above viewport
    if (top < 8) {
      top = 8
    }

    menu.style.left = `${left}px`
    menu.style.top = `${top}px`

    // Trigger animation on next frame
    requestAnimationFrame(() => {
      menu.classList.add("open")
    })

    this.isOpen = true
    this.justOpened = true

    // Add click listener after a short delay to avoid catching the opening click
    setTimeout(() => {
      this.justOpened = false
      document.addEventListener("click", this.closeOnClickOutside, true)
    }, 100)

    window.addEventListener("scroll", this.closeOnScroll, true)
    window.addEventListener("resize", this.closeOnScroll)
  }

  close() {
    if (!this.isOpen) return

    const menu = this.menu
    if (!menu) return

    menu.classList.remove("open")
    this.isOpen = false
    this.justOpened = false

    // Remove event listeners
    document.removeEventListener("click", this.closeOnClickOutside, true)
    window.removeEventListener("scroll", this.closeOnScroll, true)
    window.removeEventListener("resize", this.closeOnScroll)
    menu.removeEventListener("click", this.handleItemClick)

    // Wait for animation, then return menu to original location
    setTimeout(() => {
      menu.classList.add("hidden")

      // Clear inline styles
      menu.style.position = ""
      menu.style.left = ""
      menu.style.top = ""
      menu.style.zIndex = ""

      // Return to original parent
      if (this.originalParent && menu.parentElement === document.body) {
        this.originalParent.appendChild(menu)
      }

      // Clear menu reference after returning it
      this.menuElement = null
    }, 200)
  }

  handleItemClick(event) {
    const button = event.target.closest("button")
    if (!button) return

    // Prevent event from propagating
    event.preventDefault()
    event.stopPropagation()

    // Try to execute the action
    const action = button.dataset.action
    if (action && this.taskRowElement) {
      const match = action.match(/click->task-row#(\w+)/)
      if (match) {
        const methodName = match[1]
        const taskRowController = this.application.getControllerForElementAndIdentifier(
          this.taskRowElement,
          "task-row"
        )
        if (taskRowController && typeof taskRowController[methodName] === "function") {
          const syntheticEvent = {
            target: button,
            currentTarget: button,
            preventDefault: () => {},
            stopPropagation: () => {}
          }
          taskRowController[methodName](syntheticEvent)
        }
      }
    }

    // ALWAYS close the dropdown after clicking any item
    this.close()
  }

  closeOnClickOutside(event) {
    // Ignore if we just opened
    if (this.justOpened) return

    const menu = this.menu
    if (!menu) return

    // Close if click is outside the menu
    if (!menu.contains(event.target)) {
      this.close()
    }
  }

  closeOnScroll() {
    this.close()
  }

  disconnect() {
    // Clean up: return menu to original parent if still open
    if (this.isOpen) {
      const menu = this.menu
      if (menu) {
        menu.classList.remove("open")
        menu.classList.add("hidden")
        menu.style.position = ""
        menu.style.left = ""
        menu.style.top = ""
        menu.style.zIndex = ""
        menu.removeEventListener("click", this.handleItemClick)

        if (this.originalParent && menu.parentElement === document.body) {
          this.originalParent.appendChild(menu)
        }
      }
    }

    document.removeEventListener("click", this.closeOnClickOutside, true)
    window.removeEventListener("scroll", this.closeOnScroll, true)
    window.removeEventListener("resize", this.closeOnScroll)
  }
}
