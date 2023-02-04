using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "CameraData", menuName = "BachelorThesis/CameraData", order = 1)]

public class CameraData : ScriptableObject {
    public Vector3 CameraRotation = Vector3.zero;
}
