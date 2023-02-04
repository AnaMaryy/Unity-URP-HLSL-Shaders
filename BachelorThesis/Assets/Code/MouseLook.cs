using UnityEngine;
using UnityEngine.PlayerLoop;

public class MouseLook : MonoBehaviour {

	public float MouseSensitivity = 100f;
	public Transform PlayerBody;

	private float xRotation = 0f;
	private bool _canMove;

	private void Start() {
		//Cursor.lockState = CursorLockMode.Locked;
	}

	public void Teleport(CameraData cameraData) {
		transform.localRotation = Quaternion.Euler(cameraData.CameraRotation);
	}

	public void LockInPlace(bool canMove) {
		_canMove = canMove;
	}

	void Update() {
		if (!_canMove) return;
		
		float mouseX = Input.GetAxis("Mouse X") * MouseSensitivity * Time.deltaTime;
		float mouseY = Input.GetAxis("Mouse Y") * MouseSensitivity * Time.deltaTime;

		xRotation -= mouseY;
		xRotation = Mathf.Clamp(xRotation, -90, 90f);
		transform.localRotation = Quaternion.Euler(xRotation,0f,0f);
		PlayerBody.Rotate(Vector3.up * mouseX);
		

	}
	

}

