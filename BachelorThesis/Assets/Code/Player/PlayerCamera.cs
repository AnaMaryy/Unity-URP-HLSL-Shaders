using UnityEngine;
using UnityEngine.EventSystems;

public class PlayerCamera : MonoBehaviour {

	public float sensX;
	public float sensY;

	public Transform orientation;

	private float xRotation;
	private float yRotation;

	private bool isFirstChange = false;

	private void Start() {
		// Cursor.lockState = CursorLockMode.Locked;
		// Cursor.visible = false;

	}

	public void SetCameraRotation(float x, float y) {
		xRotation = x;
		yRotation = y;
	}

	private void Update() {

		if (!EventSystem.current.IsPointerOverGameObject()) {
			//get mouse input
			var mouseX = Input.GetAxis("Mouse X") * sensX * Time.deltaTime;
			float mouseY = Input.GetAxis("Mouse Y") * sensY * Time.deltaTime;
			yRotation += mouseX;
			xRotation -= mouseY;
			xRotation = Mathf.Clamp(xRotation, -90f, 90f);

			// hack for camera moving the first frame 
			if (!isFirstChange && 0 != mouseX) {
				isFirstChange = true;
				xRotation = transform.localRotation.eulerAngles.x;
				yRotation = transform.localRotation.eulerAngles.y;
			}
		}

		//rotate camera
		transform.localRotation = Quaternion.Euler(xRotation, yRotation, 0);
		orientation.localRotation = Quaternion.Euler(0, yRotation, 0);
	}

}
