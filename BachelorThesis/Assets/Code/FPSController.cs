using System.Threading;
using Code;
using UnityEngine;
using UnityEngine.InputSystem;

public class FPSController : MonoBehaviour {

	public float Speed = 12f;
	public float UpDownSpeed = 12f;

	public CharacterController CharacterController;
	public MouseLook MouseLook;

	private bool _canMove = true;

	void Update() {
		// input controller
		if (Input.GetKey("1")) {
			var cameraAnchor = SceneManager.Instance.CurrentSceneInstance.CameraAnchors[0];
			Teleport(cameraAnchor.transform.position, cameraAnchor.CameraData);
			LockInPlace(false);
			return;
		}
		if (Input.GetKey("2")) {
			var cameraAnchor = SceneManager.Instance.CurrentSceneInstance.CameraAnchors[1];
			Teleport(cameraAnchor.transform.position, cameraAnchor.CameraData);
			LockInPlace(false);
			return;
		}
		if (Input.GetKey("3")) {
			var cameraAnchor = SceneManager.Instance.CurrentSceneInstance.CameraAnchors[2];
			Teleport(cameraAnchor.transform.position, cameraAnchor.CameraData);
			LockInPlace(false);
			return;
		}

		//locks in place if teleported (for picture taking)
		if (!_canMove) {
			if (Input.GetKey(KeyCode.Escape)) {
				LockInPlace(true);
			}
			return;
		}

		//fps controller
		float x = Input.GetAxis("Horizontal");
		float z = Input.GetAxis("Vertical");

		Vector3 direction = transform.right * x + transform.forward * z;
		if (Input.GetKey("space")) {
			direction += transform.up;
		}
		if (Input.GetKey(KeyCode.LeftShift)) {

			direction -= transform.up;

		}
		CharacterController.Move(direction * Speed * Time.deltaTime);
	}

	private void LockInPlace(bool canMove) {
		_canMove = canMove;
		MouseLook.LockInPlace(_canMove);
	}

	private void Teleport(Vector3 endPos, CameraData cameraData) {
		transform.position = endPos;
		MouseLook.Teleport(cameraData);
	}

}
