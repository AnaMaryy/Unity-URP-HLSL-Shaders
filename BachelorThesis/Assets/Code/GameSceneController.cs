using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameSceneController : MonoSingleton<GameSceneController>
{
    public List<ModelController> Models = new List<ModelController>();
    public List<Shader> Shaders;
    public ModelController CurrentModel;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}

