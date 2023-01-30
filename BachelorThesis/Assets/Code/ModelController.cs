using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class ModelController : MonoBehaviour {

	public List<MeshRenderer> Renderers;
	public List<Material> Materials = new List<Material>();
	public int MatCount = -1; // which material is chosen
	private string MaterialPathName = "Assets/Materials";

	public void CreateMaterial(Shader shader) {
		//todo: create material for each renderer of the model : can have different colors etc. for things ! 
		Material material = new Material(shader);
		if (!AssetDatabase.IsValidFolder(MaterialPathName + this.name)) {
			AssetDatabase.CreateFolder(MaterialPathName, this.name);
		}
		string shaderName = shader.name.Split("/")[1];
		string newAssetName = MaterialPathName + "/" + this.name + "/" + this.name + "_" + shaderName + ".mat";

		var tuple = AlreadyContainsMat(material);
		if (tuple.isInside) {
			Materials.RemoveAt(tuple.index);
		}
		Materials.Add(material);

		AssetDatabase.CreateAsset(material, newAssetName);
		AssetDatabase.SaveAssets();

		SwitchMaterial();
	}

	private (bool isInside, int index) AlreadyContainsMat(Material mat) {
		for (var index = 0; index < Materials.Count; index++) {
			Material material = Materials[index];
			if (material.name == mat.name) return (true, index);
		}
		return (false, -1);
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
