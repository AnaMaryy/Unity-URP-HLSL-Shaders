using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;
using Cursor = UnityEngine.Cursor;

/// <summary>
/// Rotate the player camera based on the mouse rotation
/// </summary>
public class MouseLook : MonoBehaviour
{
    public Camera Camera;
    public float MouseSensitivity = 100f;
    public float MouseScrollSensitivity = 50f;
    public float MouseScrollSpeed = 5f;
    public Transform PlayerBody;
    private float XRotation =0f; // start by looking up

    private float BaseCameraFov;
    private float CurrentCameraFov;
    // Start is called before the first frame update
    void Start()
    {
        //XRotation = PlayerBody.rotation.x;
        Cursor.lockState = CursorLockMode.Locked;
        BaseCameraFov = Camera.fieldOfView;
        CurrentCameraFov = BaseCameraFov;
    }

    void Update()

    {
        //change fov on mouse scroll
        CurrentCameraFov -= Input.GetAxis("Mouse ScrollWheel") * MouseScrollSensitivity;
        CurrentCameraFov = Mathf.Clamp(CurrentCameraFov, 40, 90);
        Camera.fieldOfView = Mathf.Lerp(Camera.fieldOfView, CurrentCameraFov, Time.deltaTime * MouseScrollSpeed);
        
        //change orientation on mouse move
        float mouseX = Input.GetAxis("Mouse X") * MouseSensitivity * Time.deltaTime;
        float mouseY = Input.GetAxis("Mouse Y") * MouseSensitivity * Time.deltaTime;
        XRotation -= mouseY;
        XRotation = Mathf.Clamp(XRotation, -90f, 90f);

        //Camera.fieldOfView *= scrollWheel;
        transform.localRotation = Quaternion.Euler(XRotation, 0f, 0f);
        //PlayerBody.rotation = Quaternion.Euler(XRotation, 0f, 0f);
        PlayerBody.Rotate(Vector3.up *mouseX); // look around
        
    }
}
