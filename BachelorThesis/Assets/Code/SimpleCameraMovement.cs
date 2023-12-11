using UnityEngine;

namespace Code {

	public class SimpleCameraMovement : MonoBehaviour {

		public float speed = 5.0f;
		public float sensitivity = 5.0f;
		private float finalSpeed;

		void Start() {
			Cursor.visible = false;
		}

		void Update() {
			var deltaTime = Time.deltaTime;
			var position = transform.position;

			finalSpeed = speed;
			if (Input.GetKey(KeyCode.LeftShift)) {
				position -= transform.up * (finalSpeed * deltaTime);
			}

			if (Input.GetKey(KeyCode.Space)) {
				position += transform.up * (finalSpeed * deltaTime);
			}

			// Move the camera
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
