using System.Collections;
using System.Collections.Generic;
using UnityEngine;
//loads a scene : todo: change if there will be more scenes added
public class SceneManager : MonoSingleton<SceneManager> {

	public GameSceneController GameSceneController;
	[HideInInspector] public GameSceneController CurrentScene;

	// Start is called before the first frame update
	protected override void Awake() {
		base.Awake();
		LoadScene();
	}
	private void LoadScene() {
		CurrentScene = Instantiate(GameSceneController, transform);
	}

}
