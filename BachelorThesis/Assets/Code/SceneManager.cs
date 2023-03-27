using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

//loads a scene : todo: change if there will be more scenes added
public class SceneManager : MonoSingleton<SceneManager> {

	public Camera WorldCamera;
	public Camera UiCamera;
	public FPSController FPSController;
	[SerializeField] private Transform _SceneParent;

	public SceneController.SceneName CurrentSceneName; // can change scene in Editor
	private SceneController.SceneName _currentSceneName;
	[HideInInspector] public SceneController CurrentSceneInstance;

	public List<SceneController> Scenes;
	private Dictionary<SceneController.SceneName, SceneController> _dictScenes;

	protected override void Awake() {
		base.Awake();
		Init();
		_currentSceneName = CurrentSceneName;
		LoadScene(_currentSceneName);
	}

	private void Init() {
		_currentSceneName = CurrentSceneName;
		_dictScenes = new Dictionary<SceneController.SceneName, SceneController>();
		foreach (SceneController scene in Scenes) {
			_dictScenes[scene.Name] = scene;
		}
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
		CurrentSceneInstance.Init(FPSController);
		_currentSceneName = sceneName;

		//teleport player to first camera pos
		var cameraAnchor = CurrentSceneInstance.CameraAnchors[0];
		FPSController.Teleport(cameraAnchor.transform.position, cameraAnchor.CameraData);
	}

	void OnValidate() {
		if (_currentSceneName != CurrentSceneName) {
			_currentSceneName = CurrentSceneName;
			LoadScene(_currentSceneName);
		}
	}

}
