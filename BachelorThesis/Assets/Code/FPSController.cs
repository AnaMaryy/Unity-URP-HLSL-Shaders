using UnityEngine;


	public class FPSController :MonoBehaviour {

		public void Teleport(Transform dest) {
			transform.position = dest.position;
		}
		

	

}
