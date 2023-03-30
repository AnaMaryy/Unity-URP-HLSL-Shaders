using UnityEngine;

namespace Code.Player {

	public class MoveCamera : MonoBehaviour {

		public Transform cameraPosition;
		private void Update() {
			transform.position = cameraPosition.position;
		}

	}

}
