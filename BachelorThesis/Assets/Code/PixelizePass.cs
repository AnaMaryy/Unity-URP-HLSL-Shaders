namespace Code.Utilities {

	using UnityEngine;
	using UnityEngine.Rendering;
	using UnityEngine.Rendering.Universal;

	public class PixelizePass : ScriptableRenderPass {

		private PixelizeFeature.CustomPassSettings settings;

		private RenderTargetIdentifier colorBuffer, pixelBuffer;
		private int pixelBufferID = Shader.PropertyToID("_PixelBuffer");

		//private RenderTargetIdentifier pointBuffer;
		//private int pointBufferID = Shader.PropertyToID("_PointBuffer");

		private Material material;
		private int pixelScreenHeight, pixelScreenWidth;

		public PixelizePass(PixelizeFeature.CustomPassSettings settings) { //here we pass the settings object
			this.settings = settings;
			this.renderPassEvent = settings.renderPassEvent;
			if (material == null) material = CoreUtils.CreateEngineMaterial("Thesis/PixelTest");
		}

		public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData) {
			colorBuffer = renderingData.cameraData.renderer.cameraColorTarget;
			RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;

			//cmd.GetTemporaryRT(pointBufferID, descriptor.width, descriptor.height, 0, FilterMode.Point);
			//pointBuffer = new RenderTargetIdentifier(pointBufferID);

			pixelScreenHeight = settings.screenHeight;
			pixelScreenWidth = (int)(pixelScreenHeight * renderingData.cameraData.camera.aspect + 0.5f); //calculate based on the camera aspect ratio

			material.SetVector("_BlockCount", new Vector2(pixelScreenWidth, pixelScreenHeight));
			material.SetVector("_BlockSize", new Vector2(1.0f / pixelScreenWidth, 1.0f / pixelScreenHeight));
			material.SetVector("_HalfBlockSize", new Vector2(0.5f / pixelScreenWidth, 0.5f / pixelScreenHeight)); //this one doesnt have to be set

			material.SetFloat("_Width", pixelScreenWidth);
			material.SetFloat("_Heigth", pixelScreenHeight);

			descriptor.height = pixelScreenHeight;
			descriptor.width = pixelScreenWidth;

			cmd.GetTemporaryRT(pixelBufferID, descriptor, FilterMode.Point); //point so its not blurry
			pixelBuffer = new RenderTargetIdentifier(pixelBufferID);
		}

		public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) {
			CommandBuffer cmd = CommandBufferPool.Get();
			using (new ProfilingScope(cmd, new ProfilingSampler("Pixelize Pass"))) {
				// No-shader variant
				//Blit(cmd, colorBuffer, pointBuffer);
				//Blit(cmd, pointBuffer, pixelBuffer);
				//Blit(cmd, pixelBuffer, colorBuffer);

				Blit(cmd, colorBuffer, pixelBuffer, material); //takes the buffers...
				Blit(cmd, pixelBuffer, colorBuffer);
			}

			context.ExecuteCommandBuffer(cmd);
			CommandBufferPool.Release(cmd);
		}

		public override void OnCameraCleanup(CommandBuffer cmd) {
			if (cmd == null) throw new System.ArgumentNullException("cmd");
			cmd.ReleaseTemporaryRT(pixelBufferID); //on each frame release the render textures
			//cmd.ReleaseTemporaryRT(pointBufferID);
		}

	}

}
