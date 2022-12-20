using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class ModelController : MonoBehaviour {

	public List<MeshRenderer> Renderers;
	public List<Material> Materials;
	private int MatCount = -1; // counter on which material is choosen
	private string MaterialPathName = "Assets/Materials/";

	public void CreateMaterial(Shader shader) {
		Material material = new Material(shader);
		string shaderName = shader.name.Split("/")[1];
		string newAssetName = MaterialPathName + this.name + "_" + shaderName + ".mat";
		AssetDatabase.CreateAsset(material, newAssetName);
		AssetDatabase.SaveAssets();
		Materials.Add(material);
		SwitchMaterial();
	}

	public void SwitchMaterial() {
		//choose Index
		if (MatCount + 1 == Materials.Count - 1) {
			MatCount = 0;
		} else {
			MatCount++;
		}

		//switch material
		foreach (MeshRenderer meshRenderer in Renderers) {
			meshRenderer.material = Materials[MatCount];
		}
	}

}
