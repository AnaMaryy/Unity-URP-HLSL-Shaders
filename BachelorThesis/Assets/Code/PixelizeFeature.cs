using Code.Utilities;

namespace Code {


	using UnityEngine;
	using UnityEngine.Rendering;
	using UnityEngine.Rendering.Universal;

	public class PixelizeFeature : ScriptableRendererFeature {

		[System.Serializable]
		public class CustomPassSettings { //this is not a required thing

			//when the effect is applied
			public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
			public int screenHeight = 144; //just the resolution 

		}

		[SerializeField] private CustomPassSettings settings;
		private PixelizePass customPass;

		public override void Create() {
			customPass = new PixelizePass(settings); //initialize the custom pass
		}

		//it adds the pass to the queue of passes that are executed each frame
		public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {

			if (renderingData.cameraData.isSceneViewCamera) return;
			renderer.EnqueuePass(customPass);
		}

	}


}
