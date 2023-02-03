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
	public InputController InputController;
	[SerializeField] private Transform _SceneParent;

	public List<SceneController> Scenes;
	private Dictionary<SceneController.SceneName, SceneController> _dictScenes;

	
	public SceneController.SceneName CurrentSceneName; // can change scene in run mode :)
	private SceneController.SceneName _currentSceneName;

	private SceneController _currentSceneInstance;

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

	private void LoadScene(SceneController.SceneName sceneName) {
		if (_dictScenes.ContainsKey(sceneName)) {
			if (_currentSceneInstance != null) {
				DestroyImmediate(_currentSceneInstance.gameObject);
			}
			_currentSceneInstance = Instantiate(_dictScenes[sceneName], _SceneParent);
			_currentSceneInstance.Init(FPSController);
			_currentSceneName = sceneName;
		} else {
			throw new Exception("There is no scene with the name " + sceneName);
		}
	}

	void OnValidate() {
		if (_currentSceneName != CurrentSceneName) {
			_currentSceneName = CurrentSceneName;
			LoadScene(_currentSceneName);
		}
	}

}
