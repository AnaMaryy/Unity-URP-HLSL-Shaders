using System;
using System.Collections.Generic;
using UnityEngine;
[ExecuteAlways]
public class SceneManager : MonoSingleton<SceneManager> {

	// public Camera WorldCamera;
	// public Camera UiCamera;
	[SerializeField] private Transform _SceneParent;
	///player links
	public PlayerCamera PlayerCamera;
	public PlayerMovement PlayerMovement;

	public SceneController.SceneName CurrentSceneName; 
	// private SceneController.SceneName _currentSceneName;
	[HideInInspector] public SceneController CurrentSceneInstance;

	public List<SceneController> Scenes;

// #if UNITY_EDITOR
// 	private void OnValidate() {
// 		//if (_currentSceneName != CurrentSceneName) {
// 			LoadScene(CurrentSceneName);
// 		//}
// 	}
// #endif
	protected override void Awake() {
		base.Awake();
		//_currentSceneName = CurrentSceneName;
		//LoadScene(_currentSceneName);
		LoadScene(CurrentSceneName);

	}
	
	public void LoadScene(SceneController.SceneName sceneName) {
		//load scene
		var scene = GetScene(sceneName);

		if (CurrentSceneInstance != null) {
			DestroyImmediate(CurrentSceneInstance.gameObject);
		}
		CurrentSceneInstance = Instantiate(scene, _SceneParent);
		//_currentSceneName = sceneName;
		RenderSettings.skybox = scene.SkyMaterial;
		
		//set the player camera rotation
		PlayerCamera.SetCameraRotation(14,-75);
		
	}

	private SceneController GetScene(SceneController.SceneName sceneName) {
		foreach (SceneController scene in Scenes) {
			if (scene.Name == sceneName) return scene;
		}
		throw new Exception("No Scene with the name of: " + sceneName);
	}

}
