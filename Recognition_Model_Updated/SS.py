import pyautogui
import time
import keyboard

# Flag to track whether the loop is running or paused
is_running = False

def take_screenshot():
    """Take a screenshot and save it with a timestamp"""
    timestamp = time.strftime("%Y%m%d_%H%M%S")
    screenshot = pyautogui.screenshot()
    screenshot.save(f"screenshot_{timestamp}.png")
    print(f"Screenshot taken: screenshot_{timestamp}.png")

def start_stop():
    """Start/stop the screenshot loop"""
    global is_running
    if is_running:
        is_running = False
        print("Screenshot loop stopped.")
    else:
        is_running = True
        print("Screenshot loop started.")
        while is_running:
            take_screenshot()
            time.sleep(1)

def listen_for_keypress():
    """Listen for the 'q' key to start/stop the screenshot loop"""
    while True:
        if keyboard.is_pressed('q'):  # If the 'q' key is pressed
            start_stop()
            time.sleep(1)  # Delay to prevent multiple activations in a short time

# Start listening for key presses
listen_for_keypress()
