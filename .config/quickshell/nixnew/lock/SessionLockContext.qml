import Quickshell
import Quickshell.Services.Pam

Scope {
	id: root
	signal unlocked();

	property LockState state: LockState {
		onTryPasswordUnlock: {
			root.state.isUnlocking = true;
			pam.start();
		}
	}

	PamContext {
		id: pam
		configDirectory: "pam"
		config: "password.conf"

		onPamMessage: {
			if (this.responseRequired) {
				this.respond(root.state.currentText);
			} else if (this.messageIsError) {
				root.state.currentText = "";
				root.state.failed = true;
				root.state.error = this.message;
			} // else ignore
		}

		onCompleted: status => {
			const success = status == PamResult.Success;

			if (!success) {
				root.state.currentText = "";
				root.state.error = "Invalid password";
			}

			root.state.failed = !success;
			root.state.isUnlocking = false;

			if (success) root.unlocked();
		}
	}
}
