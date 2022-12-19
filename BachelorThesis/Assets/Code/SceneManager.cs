using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SceneManager : MonoSingleton<SceneManager>
{
    public GameSceneController GameSceneController;
    [HideInInspector] public GameSceneController CurrentScene;
    // Start is called before the first frame update
    void Start()
    {
        
    }
    public void LoadScene(){


    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
