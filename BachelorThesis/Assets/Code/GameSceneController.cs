using System.Collections;
using System.Collections.Generic;
using Sirenix.OdinInspector;
using UnityEditor;
using UnityEngine;
using UnityEngine.Profiling;

public class GameSceneController : MonoSingleton<GameSceneController>
{
    public List<ModelController> Models = new List<ModelController>();
    //list of all shaders
    public List<Shader> Shaders = new List<Shader>();
    public ModelController CurrentModel;
    [Title("Create new materials from shader")]
    public Shader NewShader;

    // Start is called before the first frame update
    void Start()
    {
        
    }
    
/// <summary>
/// Adds a shader to the list of shader if it is not there and returns bool
/// </summary>
/// <param name="shader"></param>
/// <returns></returns>
    private bool AddNewShader(Shader shader)
    {
        if (Shaders.Contains(shader)) return false;
        Shaders.Add(shader);
        return true;
    }

    /// <summary>
    /// Creates a new material off a specific shader for all objects
    /// </summary>
    private void CreateNewMaterials(Shader shader)
    {
        foreach (var model in Models)
        {
            model.CreateMaterial(shader);
        }
    }
    
    public void OnButtonPressed()
    {
        if (!AddNewShader(NewShader)) return;
        CreateNewMaterials(NewShader);
        NewShader = null;
    }

}
//editor
[CustomEditor(typeof(GameSceneController))]
public class GameSceneScriptEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();
        GameSceneController myTarget = (GameSceneController)target;
        if(GUILayout.Button("Create materials") && myTarget.NewShader!= null)
            {
                myTarget.OnButtonPressed();
            }
        

    }
}

