using UnityEngine;

namespace Code {

	public class SimpleCameraMovement : MonoBehaviour {

		public float speed = 5.0f;
		public float sensitivity = 5.0f;
		public float shiftSpeedUp = 5f;

		private float finalSpeed;

		void Start() {
			Cursor.visible = false;
		}

		void Update() {
			var deltaTime = Time.deltaTime;

			finalSpeed = speed;
			if (Input.GetKey(KeyCode.LeftShift)) {
				finalSpeed += shiftSpeedUp;
			}

			// Move the camera
			var position = transform.position;
			position += transform.forward * (Input.GetAxis("Vertical") * finalSpeed * deltaTime);
			position += transform.right * (Input.GetAxis("Horizontal") * finalSpeed * deltaTime);
			transform.position = position;

			// Rotate the camera 
			float mouseX = Input.GetAxis("Mouse X");
			float mouseY = Input.GetAxis("Mouse Y");
			transform.eulerAngles += new Vector3(-mouseY * sensitivity, mouseX * sensitivity, 0);

		}

	}

}
