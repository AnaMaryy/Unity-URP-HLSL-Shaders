using System;
using System.Collections.Generic;
using UnityEngine;
public class SceneManager : MonoSingleton<SceneManager> {

	// public Camera WorldCamera;
	// public Camera UiCamera;
	[SerializeField] private Transform _SceneParent;
	//todo switch to urp
	///player links
	public PlayerCamera PlayerCamera;
	public PlayerMovement PlayerMovement;

	public SceneController.SceneName CurrentSceneName; 
	private SceneController.SceneName _currentSceneName;
	[HideInInspector] public SceneController CurrentSceneInstance;

	public List<SceneController> Scenes;

	protected override void Awake() {
		base.Awake();
		Init();
		_currentSceneName = CurrentSceneName;
		LoadScene(_currentSceneName);
	}

	private void Init() {
		_currentSceneName = CurrentSceneName;
	}

	private SceneController GetScene(SceneController.SceneName sceneName) {
		foreach (SceneController scene in Scenes) {
			if (scene.Name == sceneName) return scene;
		}
		throw new Exception("No Scene with the name of: " + sceneName);
	}

	public void LoadScene(SceneController.SceneName sceneName) {
		//load scene
		var scene = GetScene(sceneName);

		if (CurrentSceneInstance != null) {
			DestroyImmediate(CurrentSceneInstance.gameObject);
		}
		CurrentSceneInstance = Instantiate(scene, _SceneParent);
		_currentSceneName = sceneName;
		RenderSettings.skybox = scene.SkyMaterial;
		
		//set the player camera rotation
		PlayerCamera.SetCameraRotation(14,-75);


		//teleport player to first camera pos
		//FPSController.Teleport(cameraAnchor.transform.position, cameraAnchor.CameraData);
	}

}
