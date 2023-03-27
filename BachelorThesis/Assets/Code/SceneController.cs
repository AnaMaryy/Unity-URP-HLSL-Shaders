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

		SAMPLE_SCENE,
		TOON_SCENE,
		SNOW_SCENE

	}

	public SceneName Name;

	public List<CameraAnchorController> CameraAnchors;
	private int _currentAchor = 0;

	public void Init(FPSController fps) {
//		fps.Teleport(CameraAnchors[_currentAchor]);
	}

	// 	public List<ModelController> Models = new List<ModelController>();
// 	//list of all shaders
// 	public List<Shader> Shaders = new List<Shader>();
// 	public ModelController CurrentModel;
// 	[Title("Create new materials from shader")]
// 	public Shader NewShader;
//
// 	// Start is called before the first frame update
// 	void Start() {
//
// 	}
//
// 	//todo: if adding a new model, create all materials for it
//
// 	/// <summary>
// 	/// Creates a new material off a specific shader for all objects
// 	/// </summary>
// 	private void CreateNewMaterials(Shader shader) {
// 		foreach (var model in Models) {
// 			model.CreateMaterial(shader);
// 		}
// 	}
//
// 	public void OnButtonPressed() {
// 		if (!Shaders.Contains(NewShader)) Shaders.Add(NewShader);
//
// 		CreateNewMaterials(NewShader);
// 		NewShader = null;
// 	}
//
// }
//
// //editor
// [CustomEditor(typeof(SceneController))]
// public class GameSceneScriptEditor : Editor {
//
// 	public override void OnInspectorGUI() {
// 		DrawDefaultInspector();
// 		SceneController myTarget = (SceneController)target;
// 		if (GUILayout.Button("Create materials") ) {
//
// 			if (myTarget.NewShader != null) {
// 				myTarget.OnButtonPressed();
// 			} else {
// 				Debug.Log("Must link a shader into 'New Shader'");
// 			}
// 		}
//
// 	}

}
