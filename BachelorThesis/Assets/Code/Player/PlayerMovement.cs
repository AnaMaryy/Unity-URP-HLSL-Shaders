
using TMPro;
using UnityEditor.Experimental.GraphView;
using UnityEngine;

public class PlayerMovement : MonoBehaviour {

	[Header("Movement")] public float MoveSpeed;
	public float Drag;
	public Transform Orientation;
	public Rigidbody Rb;

	private float HorizontalInput;
	private float VerticalInput;
	private float JumpInput;
	private float DownInput;

	private Vector3 MoveDirection;

	private void Start() {
		Rb.freezeRotation = true;
	}

	private void Update() {
		ProcessInput();
		Move();
	}

	private void ProcessInput() {
		//teleport to the camera anchor of the scene
		if (Input.GetKey(KeyCode.T)) {
			Teleport(SceneManager.Instance.CurrentSceneInstance.CameraAnchor);
		}
		
		HorizontalInput = Input.GetAxisRaw("Horizontal");
		VerticalInput = Input.GetAxisRaw("Vertical");
		JumpInput =Input.GetAxisRaw("Jump");
		DownInput = Input.GetKey(KeyCode.LeftShift)? -1:0;


	}

	private void Move() {
		//left right movement
		MoveDirection = Orientation.forward * VerticalInput + Orientation.right * HorizontalInput + Orientation.up *JumpInput + Orientation.up *DownInput;
		Rb.AddForce(MoveDirection.normalized * (MoveSpeed *10f), ForceMode.Force);
		
		LimitSpeed();
		Rb.drag = Drag;
	}

	public void Teleport(Transform tr) {
		//todo: rotation and teleport
		transform.position = tr.position;
		Orientation.rotation = tr.rotation;
	}

	private void LimitSpeed() {
		Vector3 flatVel = new Vector3(Rb.velocity.x, Rb.velocity.y, Rb.velocity.z);
		
		//limit velocity
		if (flatVel.magnitude > MoveSpeed) {
			Vector3 limitedVelocity = flatVel.normalized * MoveSpeed;
			Rb.velocity = limitedVelocity;
		}
	}
}


