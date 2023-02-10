using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class DropdownController : MonoBehaviour {

    public TMP_Dropdown Dropdown;
    // Start is called before the first frame update
    void Start()
    {
        Init();
        Dropdown.onValueChanged.AddListener(delegate(int arg0) { OnValueChanged(Dropdown);
            
        });
    }

    public void Init() {

        Dropdown.ClearOptions();
        //generate options from scenes
        List<string> dropDownOptions = new List<string>();
        foreach (SceneController scenes in SceneManager.Instance.Scenes) {
            dropDownOptions.Add(scenes.Name.ToString());
        }
        Dropdown.AddOptions(dropDownOptions);
        Dropdown.value = Dropdown.options.FindIndex(option => option.text == SceneManager.Instance.CurrentSceneName.ToString());
    }

    private void OnValueChanged(TMP_Dropdown change) {
        if(Enum.TryParse(Dropdown.options[change.value].text, out SceneController.SceneName sceneName))
        {
            SceneManager.Instance.LoadScene(sceneName);
        } else {
            throw new Exception("Scene with this name does not Exist");
        }
      
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
