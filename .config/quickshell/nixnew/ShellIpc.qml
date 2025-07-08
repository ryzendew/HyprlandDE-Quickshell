pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
	signal screenshot();

	IpcHandler {
		target: "screenshot"
		function takeScreenshot() { screenshot(); }
	}
}
