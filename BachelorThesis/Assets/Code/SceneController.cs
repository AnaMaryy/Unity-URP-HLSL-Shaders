using System.Collections;
using System.Collections.Generic;
using Code;
using Sirenix.OdinInspector;
using UnityEditor;
using UnityEditor.PackageManager;
using UnityEngine;
using UnityEngine.Profiling;

public class SceneController : MonoBehaviour {

	
	public enum SceneName {

		SampleScene,
		ToonScene,
		SnowScene

	}
	[Title("Links")]
	public Transform CameraAnchor;
	[Title("Parameters")]
	public SceneName Name;
	public Material SkyMaterial;


}
