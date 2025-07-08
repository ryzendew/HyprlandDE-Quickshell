import QtQuick
import Quickshell
import Quickshell.Services.Greetd

Scope {
	id: root
	signal launch();

	property LockState state: LockState {
		onTryPasswordUnlock: {
			this.isUnlocking = true;
			Greetd.createSession("admin");
		}
	}

	Connections {
		target: Greetd

		function onAuthMessage(message: string, error: bool, responseRequired: bool, echoResponse: bool) {
			if (responseRequired) {
				Greetd.respond(root.state.currentText);
			} // else ignore - only supporting passwords
		}

		function onAuthFailure() {
			root.state.currentText = "";
			root.state.error = "Invalid password";
			root.state.failed = true;
			root.state.isUnlocking = false;
		}

		function onReadyToLaunch() {
			root.state.isUnlocking = false;
			root.launch();
		}
	}
}
