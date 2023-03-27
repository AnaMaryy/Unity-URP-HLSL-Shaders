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

	public SceneName Name;

	public List<CameraAnchorController> CameraAnchors;
	private int _currentAchor = 0;

	public void Init(FPSController fps) {
//		fps.Teleport(CameraAnchors[_currentAchor]);
	}

}
